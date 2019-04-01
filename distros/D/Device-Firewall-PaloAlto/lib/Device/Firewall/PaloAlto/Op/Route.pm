package Device::Firewall::PaloAlto::Op::Route;
$Device::Firewall::PaloAlto::Op::Route::VERSION = '0.1.3';
use strict;
use warnings;
use 5.010;

# VERSION
# PODNAME
# ABSTRACT: Palto Alto firewall route

use parent qw(Device::Firewall::PaloAlto::JSON);

use Regexp::Common qw(net);


sub _new {
    my $class = shift;
    my ($api_return) = @_;
    my %route = %{$api_return};

    my %protocol_flags = (
        H => 'host',
        C => 'connected',
        S => 'static',
        R => 'rip',
        O => 'ospf',
        B => 'bgp'
    );

    my %protocol_specific_flags = (
        i => 'intra-area',
        o => 'inter-area',
        1 => 'external type-1',
        2 => 'external type-2',
        '?' => 'loose',
        '~' => 'internal'
    );

    foreach (@{$route{next_hops}}) {
        my %next_hop;

        @next_hop{qw(discard ip vr)} = 
        map { !defined $_ ? '' : $_ }
        $_->{nexthop} =~ m{(discard)|($RE{net}{IPv4})|vr\s+([-\w+]+)}xms;

        @{$_}{keys %next_hop} = values %next_hop;
        delete $_->{nexthop};
    }
        

    # No metric (connected or host route) is changed to -1
    $route{metric} = -1 if ref $route{metric};
    # Tun the metric into an integer rather than a string.
    $route{metric} = $route{metric} + 0;

    # Split out the route flags, then extract them out into their own fields.
    my %route_flags = map { $_ => 1} split('', delete $route{flags});
    $route{ecmp} = $route_flags{E} ? 1 : 0;
    $route{active} = $route_flags{A} ? 1 : 0;
    $route{protocol} = ( grep { defined } @protocol_flags{ keys %route_flags } )[0];
    $route{protocol_flags} = [grep { defined } @protocol_specific_flags{ keys %route_flags }];

    return bless \%route, $class;
}


sub destination { return $_[0]->{destination} }


sub next_hops { return @{$_[0]->{next_hops}} }



sub protocol { return $_[0]->{protocol} }


sub protocol_flags { return @{$_[0]->{protocol_flags}} }


sub active { return $_[0]->{active} }


sub ecmp { return $_[0]->{ecmp} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::Firewall::PaloAlto::Op::Route - Palto Alto firewall route

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

    my $default_route = $fw->op->virtual_router('vr_guest')->route('0.0.0.0/0');
    say "Protocol: ".$default_route->protocol;

=head1 DESCRIPTION

This object represents a route from a Palo Alto's virtual route table.

=head1 METHODS

=head2 destination

Returns the destination subnet of the route.

=head2 next_hops

Returns a list of hashrefs, one for each next-hop. There will more than one next-hop if the route is an ECMP route.

The below is an example HASHREF 

    {
        'ip' => '1.1.5.2',
        'age' => '8008',
        'vr' => '',
        'discard' => '',
        'interface' => 'ethernet1/1'
    }

The next-hop of the route can either be an IP address, another virtual router on the firewall, or a discard route. Only 
one of these keys in the hash will be set, the others will be set to the empty string.

=head2 protocol

Returns the protocol that the route was learnt through. Can be one of 'host', 'connected', 'static', 'rip', 'ospf' or 'bgp'

=head2 protocol_flags

Returns a list of routing protocol flags for the route. Examples include OSPF inter- or intra-area routes, or BGP internal routes.

If there are no flags, an empty list is returned.

The flags set are dependent on the routing protocol that the route was learnt from.

=head2 active

Returns 1 if the route is active, or 0 if the route is not active.

=head2 ecmp

Returns 1 if the route is ECMP, or 0 if it is not.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
