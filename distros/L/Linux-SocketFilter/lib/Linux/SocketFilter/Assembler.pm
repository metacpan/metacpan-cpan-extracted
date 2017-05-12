#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Linux::SocketFilter::Assembler;

use strict;
use warnings;

our $VERSION = '0.04';

use Linux::SocketFilter qw( :bpf :skf pack_sock_filter );

use Exporter 'import';
our @EXPORT_OK = qw(
   assemble
);

=head1 NAME

C<Linux::SocketFilter::Assembler> - assemble BPF programs from textual code

=head1 SYNOPSIS

 use Linux::SocketFilter;
 use Linux::SocketFilter::Assembler qw( assemble );
 use IO::Socket::Packet;
 use Socket qw( SOCK_DGRAM );

 my $sock = IO::Socket::Packet->new(
    IfIndex => 0,
    Type    => SOCK_DGRAM,
 ) or die "Cannot socket - $!";

 $sock->attach_filter( assemble( <<"EOF" ) );
    LD AD[PROTOCOL]

    JEQ 0x0800, 0, 1
    RET 20

    JEQ 0x86dd, 0, 1
    RET 40

    RET 0
 EOF

 while( my $addr = $sock->recv( my $buffer, 40 ) ) {
    printf "Packet: %v02x\n", $buffer;
 }

=head1 DESCRIPTION

Linux sockets allow a filter to be attached, which determines which packets
will be allowed through, and which to block. They are most often used on
C<PF_PACKET> sockets when used to capture network traffic, as a filter to
determine the traffic of interest to the capturing application. By running
directly in the kernel, the filter can discard all, or most, of the traffic
that is not interesting to the application, allowing higher performance due
to reduced context switches between kernel and userland.

This module allows filter programs to be written in textual code, and
assembled into a binary filter, to attach to the socket using the
C<SO_ATTACH_FILTER> socket option.

=cut

=head1 FILTER MACHINE

The virtual machine on which these programs run is a simple load/store
register machine operating on 32-bit words. It has one general-purpose
accumulator register (C<A>) and one special purpose index register (C<X>).
It has a number of temporary storage locations, called scratchpads (C<M[]>).
It is given read access to the contents of the packet to be filtered in 8-bit
(C<BYTE[]>), 16-bit (C<HALF[]>) or 32-bit (C<WORD[]>) sized quantities. It
also has an implicit program counter, though direct access to it is not
provided.

The filter program is run by the kernel on every packet captured by the socket
to which it is attached. It can inspect data in the packet and certain other
items of metadata concerning the packet, and decide if this packet should be
accepted by the capture socket. It returns the number of bytes to capture if
it should be captured, or zero to indicate this packet should be ignored. It
starts on the first instruction, and proceeds forwards, unless the flow is
modified by a jump instruction. The program terminates on a C<RET>
instruction, which informs the kernel of the required fate of the packet. The
last instruction in the filter must therefore be a C<RET> instruction; though
others may appear at earlier points.

In order to guarantee termination of the program in all circumstances, the
virtual machine is not fully Turing-powerful. All jumps, conditional or
unconditional, may only jump forwards in the program. It is not possible to
construct a loop of instructions that executes repeatedly.

=cut

=head1 FUNCTIONS

=cut

=head2 $filter = assemble( $text )

Takes a program (fragment) in text form and returns a binary string
representing the instructions packed ready for C<attach_filter()>.

The program consists of C<\n>-separated lines of instructions or comments.
Leading whitespace is ignored. Blank lines are ignored. Lines beginning with
a C<;> (after whitespace) are ignored as comments.

=cut

sub assemble
{
   my $self = __PACKAGE__;
   my ( $text ) = @_;

   my $ret = "";

   foreach ( split m/\n/, $text ) {
      s/^\s+//;      # trim whitespace
      next if m/^$/; # skip blanks
      next if m/^;/; # skip comments

      my ( $op, $args ) = split ' ', $_, 2;
      my @args = defined $args ? split m/,\s*/, $args : ();

      $self->can( "assemble_$op" ) or
         die "Can't compile $_ - unrecognised op '$op'\n";

      $ret .= $self->${\"assemble_$op"}( @args );
   }

   return $ret;
}

=head1 INSTRUCTION FORMAT

Each instruction in the program is formed of an opcode followed by its
operands. Where numeric literals are involved, they may be given in decimal,
hexadecimal, or octal form. Literals will be notated as C<lit> in the
following descriptions.

=cut

my $match_literal = qr/-?(?:\d+|0x[0-9a-f]+)/;
sub _parse_literal
{
   my ( $lit ) = @_;

   my $sign = ( $lit =~ s/^-// ) ? -1 : 1;

   return $sign * oct( $lit ) if $lit =~ m/^0x?/; # oct can manage octal or hex
   return $sign * int( $lit ) if $lit =~ m/\d+/;

   die "Cannot parse literal $lit\n";
}

=pod

 LD BYTE[addr]
 LD HALF[addr]
 LD WORD[addr]

Load the C<A> register from the 8, 16, or 32-bit quantity in the packet buffer
at the address. The address may be given in the forms

 lit
 X+lit
 NET+lit
 NET+X+lit

To load from an immediate or C<X>-index address, starting from either the
beginning of the buffer, or the beginning of the network header, respectively.

 LD len

Load the C<A> register with the length of the packet.

 LD lit

Load the C<A> register with a literal value

 LD M[lit]

Load the C<A> register with the value from the given scratchpad cell

 LD X
 TXA

Load the C<A> register with the value from the C<X> register. (These two
instructions are synonymous)

 LD AD[name]

Load the C<A> register with a value from the packet auxiliary data area. The
following data points are available.

=over 4

=over 4

=item PROTOCOL

The ethertype protocol number of the packet

=item PKTTYPE

The type of the packet; see the C<PACKET_*> constants defined in
L<Socket::Packet>.

=item IFINDEX

The index of the interface the packet was received on or transmitted from.

=back

=back

=cut

my %auxdata_offsets = (
   PROTOCOL => SKF_AD_PROTOCOL,
   PKTTYPE  => SKF_AD_PKTTYPE,
   IFINDEX  => SKF_AD_IFINDEX,
);

sub assemble_LD
{
   my ( undef, $src ) = @_;

   my $code = BPF_LD;

   if( $src =~ m/^(BYTE|HALF|WORD)\[(NET\+)?(X\+)?($match_literal)]$/ ) {
      my ( $size, $net, $x, $offs ) = ( $1, $2, $3, _parse_literal($4) );

      $code |= ( $size eq "BYTE" ) ? BPF_B :
               ( $size eq "HALF" ) ? BPF_H :
                                     BPF_W;
      $code |= ( $x ) ? BPF_IND :
                        BPF_ABS;

      $offs += SKF_NET_OFF if $net;

      pack_sock_filter( $code, 0, 0, $offs );
   }
   elsif( $src eq "len" ) {
      pack_sock_filter( $code|BPF_W|BPF_LEN, 0, 0, 0 );
   }
   elsif( $src =~ m/^$match_literal$/ ) {
      pack_sock_filter( $code|BPF_IMM, 0, 0, _parse_literal($src) );
   }
   elsif( $src =~ m/^M\[($match_literal)\]$/ ) {
      pack_sock_filter( $code|BPF_MEM, 0, 0, _parse_literal($1) );
   }
   elsif( $src eq "X" ) {
      pack_sock_filter( BPF_MISC|BPF_TXA, 0, 0, 0 );
   }
   elsif( $src =~ m/^AD\[(.*)\]$/ and exists $auxdata_offsets{$1} ) {
      pack_sock_filter( $code|BPF_W|BPF_ABS, 0, 0, SKF_AD_OFF + $auxdata_offsets{$1} );
   }
   else {
      die "Unrecognised instruction LD $src\n";
   }
}

sub assemble_TXA { pack_sock_filter( BPF_MISC|BPF_TXA, 0, 0, 0 ) }

=pod

 LDX lit

Load the C<X> register with a literal value

 LDX M[lit]

Load the C<X> register with the value from the given scratchpad cell

 LDX A
 TAX

Load the C<X> register with the value from the C<A> register. (These two
instructions are synonymous)

=cut

sub assemble_LDX
{
   my ( undef, $src ) = @_;

   my $code = BPF_LDX;

   if( $src =~ m/^$match_literal$/ ) {
      pack_sock_filter( $code|BPF_IMM, 0, 0, _parse_literal($src) );
   }
   elsif( $src =~ m/^M\[($match_literal)\]$/ ) {
      pack_sock_filter( $code|BPF_MEM, 0, 0, _parse_literal($1) );
   }
   elsif( $src eq "A" ) {
      pack_sock_filter( BPF_MISC|BPF_TAX, 0, 0, 0 );
   }
   else {
      die "Unrecognised instruction LDX $src\n";
   }
}

sub assemble_TAX { pack_sock_filter( BPF_MISC|BPF_TAX, 0, 0, 0 ) }

=pod

 LDMSHX BYTE[lit]

Load the C<X> register with a value obtained from a byte in the packet masked
and shifted (hence the name). The byte at the literal address is masked by
C<0x0f> to obtain the lower 4 bits, then shifted 2 bits upwards. This
special-purpose instruction loads the C<X> register with the size, in bytes,
of an IPv4 header beginning at the given literal address.

=cut

sub assemble_LDMSHX
{
   my ( undef, $src ) = @_;

   if( $src =~ m/^BYTE\[($match_literal)\]$/ ) {
      pack_sock_filter( BPF_LDX|BPF_MSH|BPF_B, 0, 0, _parse_literal($1) );
   }
   else {
      die "Unrecognised instruction LDMSHX $src\n";
   }
}

=pod

 ST M[lit]

Store the value of the C<A> register into the given scratchpad cell

 STX M[lit]

Store the value of the C<X> register into the given scratchpad cell

=cut

sub assemble_ST  { shift->assemble_store( BPF_ST,  @_ ) }
sub assemble_STX { shift->assemble_store( BPF_STX, @_ ) }
sub assemble_store
{
   my ( undef, $code, $dest ) = @_;

   if( $dest =~ m/^M\[($match_literal)\]$/ ) {
      pack_sock_filter( $code, 0, 0, _parse_literal($1) );
   }
   else {
      die "Unrecognised instruction ST(X?) $dest\n";
   }
}

=pod

 ADD src   # A = A + src
 SUB src   # A = A - src
 MUL src   # A = A * src
 DIV src   # A = A / src
 AND src   # A = A & src
 OR src    # A = A | src
 LSH src   # A = A << src
 RSH src   # A = A >> src

Perform arithmetic or bitwise operations. In each case, the operands are the
C<A> register and the given source, which can be either the C<X> register or
a literal. The result is stored in the C<A> register.

=cut

sub assemble_ADD { shift->assemble_alu( BPF_ADD, @_ ) }
sub assemble_SUB { shift->assemble_alu( BPF_SUB, @_ ) }
sub assemble_MUL { shift->assemble_alu( BPF_MUL, @_ ) }
sub assemble_DIV { shift->assemble_alu( BPF_DIV, @_ ) }
sub assemble_AND { shift->assemble_alu( BPF_AND, @_ ) }
sub assemble_OR  { shift->assemble_alu( BPF_OR,  @_ ) }
sub assemble_LSH { shift->assemble_alu( BPF_LSH, @_ ) }
sub assemble_RSH { shift->assemble_alu( BPF_RSH, @_ ) }
sub assemble_alu
{
   my ( undef, $code, $val ) = @_;

   $code |= BPF_ALU;
   if( $val eq "X" ) {
      pack_sock_filter( $code|BPF_X, 0, 0, 0 );
   }
   elsif( $val =~ m/^$match_literal$/ ) {
      pack_sock_filter( $code|BPF_K, 0, 0, _parse_literal($val) );
   }
   else {
      die "Unrecognised alu instruction on $val\n";
   }
}

=pod

 JGT src, jt, jf   # test if A > src
 JGE src, jt, jf   # test if A >= src
 JEQ src, jt, jf   # test if A == src
 JSET src, jt, jf  # test if A & src is non-zero

Jump conditionally based on comparisons between the C<A> register and the
given source, which is either the C<X> register or a literal. If the
comparison is true, the C<jt> branch is taken; if false the C<jf>. Each branch
is a numeric count of the number of instructions to skip forwards.

=cut

sub assemble_JGT  { shift->assemble_jmp( BPF_JGT,  @_ ) }
sub assemble_JGE  { shift->assemble_jmp( BPF_JGE,  @_ ) }
sub assemble_JSET { shift->assemble_jmp( BPF_JSET, @_ ) }
sub assemble_JEQ  { shift->assemble_jmp( BPF_JEQ,  @_ ) }
sub assemble_jmp
{
   my ( undef, $code, $val, $jt, $jf ) = @_;

   $code |= BPF_JMP;
   if( $val eq "X" ) {
      pack_sock_filter( $code|BPF_X, $jt, $jf, 0 );
   }
   elsif( $val =~ m/^$match_literal$/ ) {
      pack_sock_filter( $code|BPF_K, $jt, $jf, _parse_literal($val) );
   }
   else {
      die "Unrecognised jmp instruction on $val\n";
   }
}

=pod

 JA jmp

Jump unconditionally forward by the given number of instructions.

=cut

sub assemble_JA
{
   my ( undef, $target ) = @_;
   pack_sock_filter( BPF_JMP, 0, 0, $target+0 );
}

=pod

 RET lit

Terminate the filter program and return the literal value to the kernel.

 RET A

Terminate the filter program and return the value of the C<A> register to the
kernel.

=cut

sub assemble_RET
{
   my ( undef, $val ) = @_;

   my $code = BPF_RET;

   if( $val =~ m/^$match_literal$/ ) {
      pack_sock_filter( $code|BPF_K, 0, 0, _parse_literal($val) );
   }
   elsif( $val eq "A" ) {
      pack_sock_filter( $code|BPF_A, 0, 0, 0 );
   }
   else {
      die "Unrecognised instruction RET $val\n";
   }
}

# Keep perl happy; keep Britain tidy
1;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
