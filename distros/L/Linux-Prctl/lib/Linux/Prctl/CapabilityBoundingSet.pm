package Linux::Prctl::CapabilityBoundingSet;
use Linux::Prctl;

use strict;
use warnings;

use Tie::Hash;
use Carp qw(croak);

use vars qw(@ISA);
@ISA = qw(Tie::StdHash);

sub TIEHASH {
    my ($class) = @_;
    my $self = {};
    return bless($self, $class);
}

sub cap {
    my ($self, $cap) = @_;
    croak("Unknown capability: $cap") unless grep { $_ eq 'CAP_' . uc($cap) } @Linux::Prctl::EXPORT_OK;
    my ($error, $val) =  Linux::Prctl::constant('CAP_' . uc($cap));
    if ($error) { croak $error; }
    return $val
}

# Use ->can as the function may not be defined
sub capbset_drop {
    shift;
    return Linux::Prctl->can('capbset_drop')->(@_);
}

sub capbset_read {
    shift;
    return Linux::Prctl->can('capbset_read')->(@_);
}

sub STORE {
    my ($self, $key, $value) = @_;
    $key = $self->cap($key);
    croak("Can only drop capabilities from the bounding set, not add them") if $value;
    $self->capbset_drop($key);
}

sub FETCH {
    my ($self, $key) = @_;
    $key = $self->cap($key);
    return $self->capbset_read($key) ? 1 : 0;
}

1;

