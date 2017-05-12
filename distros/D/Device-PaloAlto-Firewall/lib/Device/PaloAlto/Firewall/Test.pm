package Device::PaloAlto::Firewall::Test;

use 5.006;
use strict;
use warnings;

use Moose;
use Modern::Perl;
use Carp;
#use List::Util qw( any );
#use List::MoreUtils qw( uniq );
#use Array::Utils qw{ array_minus };
use Params::Validate qw( :all );

use Data::Dumper;

=head1 NAME

Device::PaloAlto::Firewall::Test- Run a suite of tests against Palo Alto firewalls.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module contains a set of methods that run tests against an Palo Alto firewall.
The functions take arguments and return 1 or 0 depending on the current runtime state of the firewall.

These methods should be used in conjunction with the B<ok()> function provided by B<Test::More>.

    use Device::PaloAlto::Firewall
    use Test::More;

=cut

has 'firewall'      => ( is => 'ro', isa => 'Device::PaloAlto::Firewall', default => sub { });

=head1 SUBROUTINES

=cut

=head2 interfaces_up

    ok( $fw_test->interfaces_up(interfaces => ['ethernet1/1', 'ethernet./(2|3)']) );

C<interfaces_up> takes an ARRAYREF which specifies interface match criteria. Returns 0 if B<any> of the interfaces matched are down.
Internally the sub uses a case insensitive regex to create  an array of all interfaces that match, which has some implications.
Consider the following values of the 'interfaces' parameter:

=over

=item *
[ ] - will warn that the ARRAYREF is empty, however the sub will return 1 as no interfaces matches are 'down'.

=item *
['ethrnt1/1'] - a typo or any criteria that causes no interfaces to be matched will warn, however the sub will return 1 as no interfaces matched are 'down'.

=item *

['ethrnt1/1', 'ethernet1/2'] - if 'ethrnt1/1' matches no interfaces, and 'ethernet1/2' does, the return value will depend on whether 'ethernet1/2' is 'up' or 'down'.

=back

=cut

sub interfaces_up {
    my $self = shift;
    my %args = validate(@_, 
        {   
            interfaces => { type => ARRAYREF },
        }   
    );

    if (!@{ $args{interfaces} }) {
        carp "Warning: no interfaces specified - test returns true";
        return 1;
    }

    my @testable_interfaces = $self->_get_and_filter_interfaces( $args{interfaces} );
    return 0 if grep { $_->{state} eq 'down' } @testable_interfaces;

    return 1;
}

=head2 interfaces_duplex

=cut

sub interfaces_duplex {
    my $self = shift;
    my %args = validate(@_, 
        {   
            interfaces => { type => ARRAYREF },
        }   
    );

    if (!@{ $args{interfaces} }) {
            carp "Warning: no interfaces specified - test returns true";
            return 1;
    }

    # Get the interfaces - we only care about ones that are in the up state
    my @testable_interfaces = $self->_get_and_filter_interfaces( $args{interfaces} );

    return 0 if grep { _half_duplex_search($_) } @testable_interfaces;

    return 1;

}


# _half_duplex_search( $interface_structure_ref )
#
# Takes a "hw" interace array member returned from a firewall
# Returns 0 if the interface is:
#   * Not up
#   * A probable virtual machine interface (also warns)
#   * Is in full duplex mode
# Returns 1 for everything else. Most likely 'duplex' == 'half', but could be 'duplex' == '[n/a]'

sub _half_duplex_search {
    my $interface_ref = shift;

    return 0 if $interface_ref->{state} ne 'up';
    
    if ($interface_ref->{duplex} eq 'auto') {
        carp "Warning: detected 'auto' duplex, probable VM? Test may still succeed";
        return 0;
    }

    return 0 if $interface_ref->{duplex} eq 'full'; 

    return 1;
}


    

# _get_and_filter_interfaces( $self, $interface_filter_arrayref )
#
# Utility function which retrieves the response from the firewall, and 
# returns the interfaces specified in the filter.
 
sub _get_and_filter_interfaces {
    my $self = shift;
    my $interface_filters_ref  = shift; # Array of interface filters
    my @complete_filtered_interfaces;

    my $fw_response = $self->firewall->interfaces();

    for my $interface_filter (@{ $interface_filters_ref }) {
        my $int_filter_regex = qr{$interface_filter}i; 

        my @filtered_interfaces = grep { $_->{name} =~ m{$int_filter_regex} } @{ $fw_response->{hw}->{entry} };
        # Warn if our search matched no interfaces. However the following grep won't fail;
        carp "Warning: '$interface_filter' matched no interfaces. Test may still succeed" if !@filtered_interfaces;

        push @complete_filtered_interfaces, @filtered_interfaces;
    }
    return @complete_filtered_interfaces;
}



=head2 routes_exist 

=cut
sub routes_exist {
    my $self = shift;
    my %args = @_;
    my $route_search_ref = delete $args{routes};

    my $routing_table = $self->firewall->routing_table(%args);

    for my $route (@{ $route_search_ref }) {
        if (!grep { $route eq $_->{destination} } @{ $routing_table->{entry} }) {
            return 0;
        }
    }

    return 1;
}


=head2 bgp_peers_up

=cut

sub bgp_peers_up {
    my $self = shift;
    my %args = validate(@_,
        {
            peer_ips    => { type => ARRAYREF },
            vrouter     => { default => 'default', type => SCALAR | UNDEF },
        }
    );

    my $peer_ip_search_ref = delete $args{peer_ips};

    

    my $bgp_peers = $self->firewall->bgp_peers(%args);

    my @up_peers = grep { $_->{status} eq 'Established' } @{ $bgp_peers->{entry} };

    # Iterate through the peer IPs passed to us and determine whether they're up.
    # If the peer is up, 'peer-address' is host:port, so we split and match against 
    # the first array member
    for my $peer_search (@{ $peer_ip_search_ref }) {
        if (!grep { $peer_search eq (split(':', $_->{'peer-address'}))[0] } @up_peers ) {
                return 0;
        }
    }

    return 1;
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

