package Megaport::Session;

use 5.10.0;
use strict;
use warnings;

use Carp qw(croak);
use Megaport::Ports;
use Megaport::Services;
use Megaport::Locations;

use Class::Tiny qw(client errstr), {
  ports => sub { Megaport::Ports->new(client => shift->client) },
  services => sub { Megaport::Services->new(client => shift->client) },
  locations => sub { Megaport::Locations->new(client => shift->client) }
};

sub BUILD {
  croak __PACKAGE__ . '->new: client not passed to constructor' unless shift->client;
}

1;
__END__
=encoding utf-8
=head1 NAME

Megaport::Session

=head1 DESCRIPTION

A C<Megaport::Session> objects is generally only instantiated via a L<Megaport> object as it needs to be passed a valid and authenticated L<Megaport::Client> object. This class contains shortcuts to the various resources available.

=head1 METHODS

=head2 ports

    my $ports = $session->ports;

Returns a L<Megaport::Ports> object which contains a list of what Megaport calls "partner ports". A partner port is effectively a Megaport on the network which is available to order a Virtual Cross Connect (VXC) to.

=head2 services

    my $services = $session->services;

Returns a L<Megaport::Services> object containing a list of services owned by the currently logged in user.

=head2 locations

    my $locations = $session->locations;

Returns a L<Megaport::Locations> object containing a list of on-net datacentres for Megaport.

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
