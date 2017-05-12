package Megaport;

use 5.10.0;
use strict;
use warnings;

our $VERSION = "1.00";

use Carp qw(croak);
use Megaport::Client;
use Megaport::Session;

use Class::Tiny qw(token username password client errstr), {
  uri => sub { $ENV{MEGAPORT_URI} // 'https://api.megaport.com/v2' },
  debug => 0,
  no_verify => 0,

  session => sub { Megaport::Session->new(client => shift->client) }
};

sub BUILD {
  my ($self, $args) = @_;

  $self->client(
    Megaport::Client->new(
      uri => $self->uri,
      no_verify => $self->no_verify,
      debug => $self->debug
    )
  );

  if (!$self->client->login($args)) {
    croak 'Error logging in to Megaport: ' . $self->client->errstr;
  }
}

1;
__END__
=encoding utf-8
=head1 NAME

Megaport - Simple access to the L<Megaport|https://www.megaport.com> API

=head1 SYNOPSIS

    use Megaport;

    # Using an existing session token
    my $mp = Megaport->new(token => 'your-session-token');

    # Using a username/password combo
    my $mp = Megaport->new(username => 'me@example.com', password => 's3cr3t');

    # Get a list of locations (on-net datacentres)
    my @locations = $mp->session->locations->list;

    # Get a partial list
    my @locations = $mp->session->locations->list(country => 'Australia');
    my @locations = $mp->session->locations->list(name => qr/^Digital Realty/);

    # Get a single entry
    my $global_switch = $mp->session->locations->get(id => 3);

    # Services
    my $services = $mp->session->services;
    $services->list(...);
    $services->get(...);

    # Other Megaports on the network
    my $ports = $mp->session->ports;
    $ports->list(...);


=head1 DESCRIPTION

This module provides a Perl interface to the L<Megaport|https://www.megaport.com> API. This is largely to fill my own requirements and for now is read only. Read/write functionality will be added over time to support service modification.

=head1 METHODS

=head2 new

    my $mp = Megaport->new(
      token => 'your-session-token',
      uri => 'https://api.megaport.com/v2',
      debug => 0,
      no_verify => 0
    );

The fields C<token>, C<username> and C<password> are all auth relatated and should be fairly self explanatory. If you're unsure about token, take a look at the L<Megaport docs|https://dev.megaport.com/#security>.

C<debug> enables extra output to STDERR during API calls. L<Megaport::Client> by default will validate the token or user credentials by making a POST call to the Megaport API, set C<no_verify> to stop this and speed things up.

As at this writing, the production Megaport API is at https://api.megaport.com with a test environment mentioned in the documentation at https://api-staging.megaport.com. If you wish to change environments, set C<uri>.

=head2 session

    my $session = $mp->session;

Returns a L<Megaport::Session> object which contains an authenticated client ready to start making calls.

=head1 TODO

=over

=item *

Module/helper for per-service type to make data access easier

=over

=item *

Dig into VXCs/IX from top level service

=item *

Access pricing/cost estimate info per service

=back

=item *

Simple service modification, speed/VLAN etc

=item *

Helper method to link partner ports and location to make searching by city/country/region easier

=item *

Company object with access to users, invoices and outstanding balance

=back

=head1 AUTHOR

Cameron Daniel E<lt>cdaniel@cpan.orgE<gt>

=cut
