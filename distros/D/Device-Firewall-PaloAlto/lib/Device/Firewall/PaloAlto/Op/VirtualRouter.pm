package Device::Firewall::PaloAlto::Op::VirtualRouter;
$Device::Firewall::PaloAlto::Op::VirtualRouter::VERSION = '0.1.2';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: new module

use Device::Firewall::PaloAlto::Op::Route;

use parent qw(Device::Firewall::PaloAlto::JSON);


sub _new {
    my $class = shift;
    my ($api_return) = @_;
    my %virtual_router;

    my @routes = @{$api_return->{result}{entry}};

    # We have all of the routes - however due to ECMP we may have two or more routes with the same destination.
    # We key our routes by destination, so there should be only one 'Route' object.
    # All the properties of the route are the same except for 'interface', 'nexthop' and 'age'. Thus these
    # become arrays. 

    for my $route (@routes) {
        my $dst = $route->{destination};

        $virtual_router{$dst}{num_routes}++;

        # Create the nexthop structure and clean up null values.
        my %next_hop;
        foreach (qw(interface nexthop age)) {
            $next_hop{$_} = ref $route ->{$_} eq 'HASH' ? '' : ${$route}{$_};
            delete $route->{$_};
        }

        # Push the structure on to the object.
        push @{$virtual_router{$dst}{next_hops}}, \%next_hop;

        # Copy the remaining keys across.
        @{$virtual_router{$dst}}{keys %{$route}} = values %{$route};
    }

    %virtual_router = map { $_->{destination} => Device::Firewall::PaloAlto::Op::Route->_new($_) } values %virtual_router;

    return bless \%virtual_router, $class;
}


sub route { 
    my $self = shift;
    my ($prefix) = @_;
    return $self->{$prefix};
}


sub to_array { return values %{$_[0]} };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::VirtualRouter - new module

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represetns a Palo Alto's

=head1 ERRORS 

=head1 METHODS

=head2 route

    my $default_route = $fw->op->virtual_router('default')->route('0.0.0.0/0');

Returns a L<Device::Firewall::PaloAlto::Op::Route> object if the route exists in the routing table.

Returns 'undef' if the route does not exist in the routing table;

=head2 to_array

Returns an array of L<Device::Firewall::PaloAlto::Op::Route> objects. 

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
