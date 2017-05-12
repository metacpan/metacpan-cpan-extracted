package JSPL::SM::ByteCode;
use 5.010;
use strict;
use warnings;

use JSPL::SM::Opcode qw(:jof @Opcodes);

sub prolog {
    my ($proto, $script) = @_;

    my $bc = { sc => $script, bc => $script->_prolog, pc => 0 };
    return bless $bc, $proto;
}

sub main {
    my ($proto, $script) = @_;

    my $bc = { sc => $script, bc => $script->_main, pc => 0 };
    return bless $bc, $proto;
}

sub _uint8 {
    my ($self) = @_;
    my $off = $self->{pc} + 1;
    unpack "\@!$off". 'C', $self->{bc};
}

sub _int8 {
    my ($self) = @_;
    my $off = $self->{pc} + 1;
    unpack "\@!$off". 'c', $self->{bc};
}

sub _uint16 {
    my ($self, $off) = @_;
    $off += $self->{pc} + 1;
    unpack "\@!$off". 'n', $self->{bc};
}

sub _int16 {
    my ($self, $off) = @_;
    $off += $self->{pc} + 1;
    unpack "\@!$off". 'n!', $self->{bc};
}

sub _int32 {
    my ($self) = @_;
    my $off = $self->{pc} + 1;
    unpack "\@!$off". 'N!', $self->{bc};
}

my @_tdecoders;
$_tdecoders[JOF_BYTE] = sub {};
$_tdecoders[JOF_JUMP] = sub {
    my $self = shift;
    $self->_int16;
};

$_tdecoders[JOF_ATOM] = sub {
    my $self = shift;
    $self->{sc}->_getatom($self->_uint16);
};

$_tdecoders[JOF_UINT16] = sub {
    my $self = shift;
    $self->_uint16;
};

$_tdecoders[JOF_INT32] = sub {
    my $self = shift;
    $self->_int32;
} if eval "JOF_INT32";

$_tdecoders[JOF_OBJECT] = sub {
    my $self = shift;
    $self->{sc}->_getobject($self->_uint16);
} if eval "JOF_OBJECT";

$_tdecoders[JOF_UINT16PAIR] = sub {
    my $self = shift;
    ($self->_uint16, $self->_uint16(2));
} if eval "JOF_UINT16PAIR";

$_tdecoders[JOF_UINT8] = sub {
    my $self = shift;
    $self->_uint8;
} if eval "JOF_UINT8";

$_tdecoders[JOF_INT8] = sub {
    my $self = shift;
    $self->_int8;
} if eval "JOF_INT8";

sub decode {
    my $self = shift;
    return if $self->{pc} >= length $self->{bc};
    my $op = $Opcodes[ord substr $self->{bc}, $self->{pc}];
    my $type = $op->format & JOF_TYPEMASK;
    my $decoder = $_tdecoders[$type];
    my @res = ( $op );
    if($decoder) {
	push @res, $decoder->($self);
    } else {
	warn "No decoder for $type yet for ", $op->id, "!\n";
    }
    $self->{pc} += ($op->len == -1) 
	? $op->_var_len(substr $self->{bc}, $self->{pc})
	: $op->len;
    @res;
}

sub length { length $_[0]->{bc}; }
sub pc { $_[0]->{pc} }

1;

__END__

=head1 NAME

JSPL::SM::ByteCode - A class for inspect SpiderMonkey's bytecode

=head1 DESCRIPTION

TBD

=head1 CONSTRUCTORS

=over 4

=item prolog( I<$script> );

Returns an instance with the bytecode of the prologue of the C<JSPL::Script>
instance I<$script>.

=item main( I<$script> );

Returns an instance with the main bytecode of the C<JSPL::Script>
instance I<$script>.

=back

=head1 INSTANCE METHODS

=over 4

=item decode

TBD

=item length

Returns the bytecode length in bytes.

=item pc

TBD

=back

=cut
