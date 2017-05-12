package Linux::Prctl::CapabilitySet;

use strict;
use warnings;

use Linux::Prctl;
use Tie::Hash;
use Carp qw(croak);

use vars qw(@ISA);
@ISA = qw(Tie::StdHash);

sub TIEHASH {
    my ($class, $error, $flag) = @_;
    if ($error) { croak $error; }
    my $self = {__flag => $flag};
    return bless($self, $class);
}

sub cap {
    my ($self, $cap) = @_;
    croak("Unknown capability: $cap") unless grep { $_ eq 'CAP_' . uc($cap) } @Linux::Prctl::EXPORT_OK;
    my ($error, $val) =  Linux::Prctl::constant('CAP_' . uc($cap));
    if ($error) { croak $error; }
    return $val
}

sub set_cap {
    shift;
    return Linux::Prctl->can('set_cap')->(@_);
}

sub get_cap {
    shift;
    return Linux::Prctl->can('get_cap')->(@_);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $key = $self->cap($key);
    $self->set_cap($self->{__flag}, $key, $value);
}

sub FETCH {
    my ($self, $key) = @_;
    $key = $self->cap($key);
    return $self->get_cap($self->{__flag}, $key);
}

1;

