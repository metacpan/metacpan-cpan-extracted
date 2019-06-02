package Linux::PacketFilter;

use strict;
use warnings;

our $VERSION = '0.01';

=encoding utf-8

=head1 NAME

Linux::PacketFilter - Simple interface to Linux packet filtering

=head1 SYNOPSIS

    # Reject any packet that starts with a period:
    my $filter = Linux::PacketFilter->new(

        # Load the accumulator with the 1st byte in the packet:
        [ 'ld b abs', 0 ],

        # If the accumulator value is an ASCII period, continue;
        # otherwise, skip a line.
        [ 'jmp jeq k', ord('.'), 0, 1 ],

        # If we continued, we’ll get here and thus reject the packet.
        [ ret => 0 ],

        # If we get here, we skipped a line above. That means
        # the packet’s first byte wasn’t an ASCII period,
        # so we'll return the full packet.
        [ ret => 0xffffffff ],
    );

    $filter->apply( $socket );

=head1 DESCRIPTION

This module is a simple, small, pure-Perl compiler for Linux’s
“classic” Berkeley Packet Filter (BPF) implementation.

=head1 HOW TO USE THIS MODULE

If you’re familiar with BPF already, the SYNOPSIS above should mostly make
sense “out-of-the-box”. If you’re new to BPF, though, take heart; it’s
fairly straightforward.

The best source I have found for learning about BPF itself is
L<bpf(4) in the BSD man pages|https://man.openbsd.org/bpf.4#Filter_machine>;
see the section entitled B<FILTER MACHINE>.

Linux-specific implementation notes are available in the kernel
source tree at L</Documentation/networking/filter.txt|https://www.kernel.org/doc/Documentation/networking/filter.txt>. This contains a lot of detail
about uses for BPF that don't pertain to packet filtering, though.

L<Here is another helpful guide.|https://web.archive.org/web/20130125231050/http://netsplit.com/2011/02/09/the-proc-connector-and-socket-filters/> Take
especial note of the need to convert between network and host byte order.
(See below for a convenience that this module provides for this conversion.)

You might also take interest in L<the original BPF white paper|http://www.tcpdump.org/papers/bpf-usenix93.pdf>.

B<NOTE:> This module works with Linux’s I<“classic”> BPF, not the
much more powerful (and complex) “extended” BPF.

=cut

my %BPF;

sub _populate_BPF {
    %BPF = (
        w => 0x00,      # 32-bit word
        h => 0x08,      # 16-bit half-word
        b => 0x10,      # 8-bit byte
        # dw => 0x18,     # 64-bit double word

        k => 0x00,      # given constant
        x => 0x08,      # index register

        # Conveniences:
        k_n => 0x00,
        k_N => 0x00,
    );

    # ld = to accumulator
    # ldx = to index
    # st = accumulator to scratch[k]
    # stx = index to scratch[k]
    my @inst = qw( ld ldx st stx alu jmp ret misc );
    for my $i ( 0 .. $#inst ) {
        $BPF{ $inst[$i] } = $i;
    }

    # Load accumulator:
    # imm = k
    # abs = offset into packet
    # ind = index + k
    # mem = scratch[k]
    # len = packet length
    # msh = IP header length (hack ..)
    my @code = qw( imm abs ind mem len msh );
    for my $i ( 0 .. $#code ) {
        $BPF{ $code[$i] } = ( $i << 5 );
    }

    my @alu = qw( add sub mul div or and lsh rsh neg mod xor );
    for my $i ( 0 .. $#alu ) {
        $BPF{ $alu[$i] } = ( $i << 4 );
    }

    # ja = move forward k
    # jeq = move (A == k) ? jt : jf
    # jset = (A & k)
    my @j = qw( ja jeq jgt jge jset );
    for my $i ( 0 .. $#j ) {
        $BPF{ $j[$i] } = ( $i << 4 );
    }

    return;
}

=head1 METHODS

=head2 $obj = I<CLASS>->new( @filters )

Creates an object that represents an array of instructions for
the BPF filter machine. Each @filters member is an array reference
that represents a single instruction and has either 2 or 4 members,
which correspond with the BPF_STMT and BPF_JUMP macros, respectively.

The first member of each array reference is, rather than a number,
a space-separated string of options, lower-cased and without the
leading C<BPF_>. So where in C you would write:

    BPF_LD | BPF_W | BPF_ABS

… in this module you write:

    'ld w abs'

The full list of options for a single instruction is:

=over

=item * C<b>, C<h>, C<w>

=item * C<x>, C<k>, C<k_n>, C<k_N> (See below for
an explanation of the last two.)

=item * C<ld>, C<ldx>, C<st>, C<stx>, C<alu>, C<jmp>, C<ret>, C<misc>

=item * C<imm>, C<abs>, C<ind>, C<mem>, C<len>, C<msh>

=item * C<add>, C<sub>, C<mul>, C<div>, C<or>, C<and>, C<lsh>, C<rsh>,
C<neg>, C<mod>, C<xor>

=item * C<ja>, C<jeq>, C<jgt>, C<jge>, C<jset>

=back

=head3 Byte order conversion

Since it’s common to need to do byte order conversions with
packet filtering, Linux::PacketFilter adds a convenience for this:
the codes C<k_n> and C<k_N> indicate to encode the given constant value
in 16-bit or 32-bit network byte order, respectively. These have the same
effect as calling C<htons(3)> and C<htonl(3)> in C.

B<NOTE:> Linux’s exact behavior regarding byte order in BPF isn’t
always clear, and this module is only tested thus far on little-endian
systems. It seems that only certain operations, like C<jeq>, require the
conversion.

=cut

use constant _is_big_endian => pack('n', 1) eq pack('S', 1);

use constant {
    _INSTR_PACK => 'S CC L',

    _NETWORK_INSTR_PACK => {
        'k_n' => _is_big_endian ? 'S CC N' : 'S CC n x2',
        'k_N' => 'S CC N',
    },

    _ARRAY_PACK => 'S x![P] P',
};

use constant _INSTR_LEN => length( pack _INSTR_PACK() );

sub new {
    my $class = shift;

    _populate_BPF() if !%BPF;

    my $buf = ("\0" x (_INSTR_LEN() * @_));

    my $f = 0;

    for my $filter (@_) {
        my $code = 0;

        my $tmpl;

        for my $piece ( split m<\s+>, $filter->[0] ) {
            $code |= ($BPF{$piece} // die "Unknown BPF option: “$piece”");

            $tmpl ||= _NETWORK_INSTR_PACK()->{$piece};
        }

        substr(
            $buf, $f, _INSTR_LEN(),
            pack(
                ( $tmpl || _INSTR_PACK() ),
                $code,
                (@$filter == 2) ? (0, 0, $filter->[1]) : @{$filter}[2, 3, 1],
            ),
        );

        $f += _INSTR_LEN();
    }

    return bless [ pack(_ARRAY_PACK(), 0 + @_, $buf), $buf ], $class;
}

=head2 $ok = I<OBJ>->attach( $SOCKET )

Attaches the filter instructions to the given $SOCKET.

Note that this class purposely omits public access to the value that
is given to the underlying L<setsockopt(2)> system call. This is because
that value contains a pointer to a Perl string. That pointer is only valid
during this object’s lifetime, and bad stuff (e.g., segmentation faults)
can happen when you give the kernel pointers to strings that Perl has
already garbage-collected.

The return is the same as the underlying call to Perl’s
L<perlfunc/setsockopt> built-in. C<$!> is set as that function leaves it.

=cut

sub attach {
    my ($self, $socket) = @_;

    # For no good reason, Perl require() clobbers $@ and $!.
    do {
        local ($@, $!);
        require Socket;
    };

    return setsockopt $socket, Socket::SOL_SOCKET(), Socket::SO_ATTACH_FILTER(), $self->[0];
}

#----------------------------------------------------------------------

1;

=head1 AUTHOR

Copyright 2019 Gasper Software Consulting (L<http://gaspersoftware.com>)

=head1 SEE ALSO

L<Linux::SocketFilter::Assembler> suits a similar purpose to this
module’s but appears to be geared solely toward PF_PACKET sockets.
It also defines its own language for specifying the filters, which I find
less helpful than this module’s approach of “porting” the C macros
to Perl, thus better capitalizing on existing documention.
