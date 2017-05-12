package Device::Cisco::NXAPI::Test;

use 5.020;
use strict;
use warnings;

use Moose;
use Modern::Perl;
use Data::Dumper;
use Carp;
use List::Util qw( any );
use List::MoreUtils qw( uniq );
use Array::Utils qw{ array_minus };
use Params::Validate qw( :all );

=head1 NAME

Device::Cisco::NXAPI::Test - Run a suite of tests on switches that support NXAPI.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module contains a set of methods that run tests against an NXAPI compatible switch.
The functions take arguments and return 1 or 0 depending on the current runtime state of the switch.

These methods should be used in conjunction with the B<ok()> function provided by B<Test::More>.

    use Device::Cisco::NXAPI;
    use Test::More;

    # The Device::Cisco::NXAPI module provides a method that returns a Device::Cisco::NXAPI::Test object.
    my $tests = Device::Cisco::NXAPI->new(uri => 'http://hostname', username => 'admin', password => 'admin')->tester();

    # Test whether interfaces are up
    ok( $tests->interfaces_up(interfaces => ['Ethernet1/1', 'Ethernet1/2']), "Interfaces are up" );

    # Test for the presence of routes
    ok( $tests->routes(routes => ['192.168.1.0/24', '10.0.0.0/8']), 'Routes in routing table' );
    
=cut

has 'switch'      => ( is => 'ro', isa => 'Device::Cisco::NXAPI', default => sub { });

=head1 SUBROUTINES

=cut

=head2 routes(%options)

    ok( 
        $tests->routes(
            vrf => '',
            af => 'ipv4' | 'ipv6',
            routes => [],
        )
    );

Returns 1 is all of the routes specified in the ARRAYREF are present in the routing table.
Returns 0 if any of the routes are not int the routing table.

B<vrf =>> defaults to the global routing table if not specified, B<af =>> defaults to 'ipv4'.

=cut

sub routes {
    my $self = shift;
    my %args = validate(@_, 
        {   
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af  => { default => 'ipv4', type => SCALAR | UNDEF },
			routes => { type => ARRAYREF },
        }   
    );
    my @returned_prefixes = ();

    my @test_routes = @{ delete $args{routes} };

    # Let the routes() method call validate the arguments
    my @retrieved_routes = map { $_->{prefix} } $self->switch()->routes(%args);

    return !array_minus(@test_routes, @retrieved_routes);
}

=head2 arp_entries(%options)

    ok( 
        $tests->arp_entries(
            vrf => '',
            ips => [ ]
        )
    );

Returns 1 if all of the IPs specified by B<ips =>> have valid entries in the ARP table of the specified VRF, otherwise returns 0.
B<vrf =>> defaults to the global routing table if not specified.

=cut

sub arp_entries {
    my $self = shift;
    my %args = validate(@_,
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
			ips => { type => ARRAYREF },
        }   
    );  

	my @test_arp_entries = @{ delete $args{ips} };

    my @retrieved_arp = map { $_->{ip} } $self->switch()->arp();

    return scalar !array_minus(@test_arp_entries, @retrieved_arp);
}


=head2 interfaces_up(%options)

    ok(
        $tests->interfaces_up(
            interfaces => [ ]
        )
    );

Returns 1 if all of the interfaces specified are in the 'up' operational state, otherwise returns 0.
Interfaces must be written exactly as they would appear in the CLI, and are case sensitive. 
e.g. [ 'Ethernet1/4', 'mgmt0' ]

=cut

sub interfaces_up {
    my $self = shift;
    my %args = validate(@_,
        {
            interfaces => { type => ARRAYREF },
        }
    );

    my @test_interfaces = @{ $args{interfaces} };

    my @retrieved_up_interfaces = map { $_->{name} if $_->{op_state} eq 'up' } $self->switch()->physical_interfaces();
    
    return scalar !array_minus(@test_interfaces, @retrieved_up_interfaces);
}


=head2 bgp_peers_up(%options)

    ok(
        $tests->bgp_peers_up(
            vrf => '',
            af => 'ipv4 | ipv6',
            peers => [ ]
        )
    );

Returns 1 if all of the peers specified are in the 'up' operational state, otherwise returns 0.
BGP peers are specified by upon their IP address.

B<vrf =>> defaults to the global routing table if not specified, B<af =>> defaults to 'ipv4'.

=cut

sub bgp_peers_up {
    my $self = shift;
    my %args = validate(@_,
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af => { default => 'ipv4', type => SCALAR | UNDEF, regex => qr{(ipv4|ipv6)} },
			peers => { type => ARRAYREF },
        }   
    );

	my @test_peers = @{ delete $args{peers} };

    my @retrieved_up_peers = map{ $_->{neighbor} if $_->{up} eq 'true' } $self->switch()->bgp_peers(%args);

    return scalar !array_minus(@test_peers, @retrieved_up_peers);
}

=head2 bgp_rib_prefixes(%options)

    ok(
        $tests->bgp_rib_prefixes(
            vrf => '',
            af => 'ipv4 | ipv6',
            prefixes => [ ]
        )
    );

Searches for the prefixes within the BGP RIB. All of the prefixes must be present in the
RIB for the function to return 'true', otherwise the function returns false.

B<vrf =>> defaults to the global routing table if not specified, B<af =>> defaults to 'ipv4'.

=cut

sub bgp_rib_prefixes {
    my $self = shift;
    my %args = validate(@_, 
        {   
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af => { default => 'ipv4', type => SCALAR | UNDEF, regex => qr{(ipv4|ipv6)} },
			prefixes => { type => ARRAYREF },
        }   
    ); 

    my @test_prefixes = @{ delete $args{prefixes} };
    my @retrieved_prefixes = map { $_->{prefix} } $self->switch()->bgp_rib(%args);

    return !array_minus(@test_prefixes, @retrieved_prefixes);
}


=head1 AUTHOR

Greg Foletta, C<< <greg at foletta.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-switch-nxapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Switch-NXAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Cisco::NXAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Switch-NXAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Switch-NXAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Switch-NXAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/Switch-NXAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Greg Foletta.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Device::Cisco::NXAPI

