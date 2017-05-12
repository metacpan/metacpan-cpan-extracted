package Linux::Prctl::Securebits;

use strict;
use warnings;

use Linux::Prctl;
use Tie::Hash;
use Carp qw(croak);

use vars qw(@ISA);
@ISA = qw(Tie::StdHash);

sub TIEHASH {
    my ($class) = @_;
    my $self = {};
    return bless($self, $class);
}

sub bit {
    my ($self, $bit) = @_;
    croak("Unknown secbit: $bit") unless $bit =~ /^(keep_caps|noroot|no_setuid_fixup)(_locked)?/;
    my ($error, $val) =  Linux::Prctl::constant('SECBIT_' . uc($bit));
    if ($error) { croak $error; }
    return $val
}

sub set_securebits {
    shift;
    return Linux::Prctl->can('set_securebits')->(@_);
}

sub get_securebits {
    shift;
    return Linux::Prctl->can('get_securebits')->(@_);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $key = $self->bit($key);
    my $nbits = $self->get_securebits();
    $nbits |= $key if $value;
    $nbits ^= $key if (($nbits & $key) && !$value);
    $self->set_securebits($nbits);
}

sub FETCH {
    my ($self, $key) = @_;
    $key = $self->bit($key);
    return ($self->get_securebits() & $key) ? 1 : 0;
}

1;

