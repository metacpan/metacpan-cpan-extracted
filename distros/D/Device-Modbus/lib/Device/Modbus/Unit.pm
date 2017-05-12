package Device::Modbus::Unit;

use Device::Modbus::Unit::Route;
use Carp;
use strict;
use warnings;


sub new {
    my ($class, %args) = @_;
    croak "Missing required parameter: id"
        unless defined $args{id};
    my %routes = (
        'discrete_coils:read'     => [],
        'discrete_coils:write'    => [],
        'discrete_inputs:read'    => [],
        'input_registers:read'    => [],
        'holding_registers:read'  => [],
        'holding_registers:write' => [],
    );
    return bless { %args, routes => \%routes }, $class;
}

sub id {
    my $self = shift;
    return $self->{id};
}

sub routes {
    my $self = shift;
    return $self->{routes};
}

sub init_unit {
    croak "Device::Modbus::Unit subclasses must implement init_unit";
}

sub put {
    my ($self, $zone, $address, $qty, $method) = @_;
    if (!ref $method) {
        $method = $self->can($method); # returns a ref to method
    }
    croak "'put' could not resolve a code reference for address $address in zone $zone"
        unless ref $method && ref $method eq 'CODE';

    my $addr = Device::Modbus::Unit::Route->new(
        address    => $address,
        zone       => $zone,
        quantity   => $qty,
        read_write => 'write',
        routine    => $method
    );
    
    push @{$self->{routes}->{"$zone:write"}}, $addr;
}

sub get {
    my ($self, $zone, $address, $qty, $method) = @_;
    if (!ref $method) {
        $method = $self->can($method); # returns a ref to method
    }
    croak "'get' could not resolve a code reference for address $address in zone $zone"
        unless ref $method && ref $method eq 'CODE';

    my $route = Device::Modbus::Unit::Route->new(
        address    => $address,
        zone       => $zone,
        quantity   => $qty,
        read_write => 'read',
        routine    => $method
    );
    
    push @{$self->{routes}->{"$zone:read"}}, $route;
}

# Tests a requested zone, address, qty against existing addresses.
# Returns the first successful match. Returns the Modbus error number
# otherwise (3 for invalid qty and 2 for invalid address)
sub route {
    my ($self, $zone, $mode, $addr, $qty) = @_;
    my $addresses = $self->{routes}->{"$zone:$mode"};
    return 1 unless @$addresses;

    my $match;
    foreach my $address (@$addresses) {
        next unless $address->test_route($addr);
        $match = $address;
        return $match if $match->test_quantity($qty);
    }

#    return 3 if defined $match; # Address matched, not quantity # INCORRECT
    return 2;                   # Did not match
}

1;
