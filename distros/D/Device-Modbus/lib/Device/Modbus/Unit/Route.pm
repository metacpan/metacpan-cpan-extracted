package Device::Modbus::Unit::Route;

use Carp;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    
    my %valid_zone = (
        discrete_coils    => 'rw',
        discrete_inputs   => 'ro',
        input_registers   => 'ro',
        holding_registers => 'rw',
    );

    foreach my $field (qw/address quantity zone read_write routine/) {
        croak "Missing required arguments: $field"
            unless exists $args{$field};
    }
    croak "Invalid Modbus model type: zone '$args{zone}' does not exist"
        unless exists $valid_zone{$args{zone}};
    croak "Modbus zone '$args{zone}' is read-only"
        if $args{read_write} eq 'write' && $valid_zone{$args{zone}} eq 'ro';
    croak "Parameter read_write must be either 'read' or 'write'"
        unless $args{read_write} =~ /^read|write$/;
    croak "The routine for an address must be a code reference"
        unless ref $args{routine} && ref $args{routine} eq 'CODE';

    $args{route_tests} = _build_tests($args{address});
    $args{qty_tests}   = _build_tests($args{quantity});

    my $self = bless \%args, $class;
}

sub routine {
    my $self = shift;
    return $self->{routine};
}

# Receives a route string and converts it into an array reference of
# anonymous subroutines. Each subroutine will test if a given value
# matches a part of the route.    
sub _build_tests {
    my $route = shift;

    # Star matches always
    return [ sub { 1 } ] if $route =~ /\*/;

    $route    =~ s/\s+//g;
    my @atoms = split /,/, $route;
    my @tests;
    foreach my $atom (@atoms) {
        # Range test
        if ($atom =~ /^(\d+)\-(\d+)$/) {
            my ($min, $max) = ($1, $2);
            push @tests, sub { my $val = shift; return $val >= $min && $val <= $max; };
        }
        # Equality test
        else {
            push @tests, sub { return shift == $atom; };
        }
    }

    return \@tests;
}

# Tests an address
sub test_route {
    my ($self, $value) = @_;
    foreach my $test (@{$self->{route_tests}}) {
        return 1 if $test->($value);
    }
    return 0;
}

# Tests a quantity
sub test_quantity {
    my ($self, $value) = @_;
    foreach my $test (@{$self->{qty_tests}}) {
        return 1 if $test->($value);
    }
    return 0;
}

1;
