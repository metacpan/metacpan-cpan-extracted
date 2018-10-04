package Meetup::API::v3;
use strict;
use Carp qw(croak);
use Future::HTTP;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use URI::URL;
use URI::Escape;

our $VERSION = '0.02';

=head1 NAME

Meetup::API::v3 - Meetup API

=head1 SYNOPSIS

  my $meetup = Meetup::API->new(
      version => 'v3',
  );

  $meetup->read_credentials;

  print Dumper $meetup->group('Perl-User-Groups-Rhein-Main')->get;

=head1 METHODS

=head2 C<< ->new >>

  my $m = Meetup::API->new();
  $m->read_credentials();

Creates a new instance of the Meetup API.

The accessors can be set in the call to new.

=cut

our $API_BASE = 'https://api.meetup.com';

=head2 C<< ->API_BASE >>

Used to set/get the base hostname used for requests.

The default value is taken from C<$Meetup::API::API_BASE> and is
L<https://api.meetup.com>.

=cut

has 'API_BASE' => (
    is => 'lazy',
    default => sub { $API_BASE },
);

=head2 C<< ->user_agent >>

Used to set/get the L<Future::HTTP> user agent

=cut

has 'user_agent' => (
    is => 'lazy',
    default => sub {
        Future::HTTP->new()
    },
);

=head2 C<< ->json >>

Used to set/get the L<JSON::XS> JSON decoder

=cut

has 'json' => (
    is => 'lazy',
    default => sub {
        require JSON::XS;
        JSON::XS->new()->utf8
    },
);

=head2 C<< ->url_map >>

Used to set/get the hashref mapping functions to API urls

=cut

has 'url_map' => (
    is => 'lazy',
    default => sub { {
        boards      => '/{groupname}/boards',
        categories  => '/2/categories',
        cities      => '/2/cities',
        concierge   => '/2/concierge',
        dashboard   => '/2/dashboard',
        discussions => '/{groupname}/boards/{bid}/discussions',
        events      => '/find/events',
        #groups      => '/find/groups',
        group       => '/{urlname}',
        group_events => '/{urlname}/events',
        self_groups => '/self/groups',
    } },
);

=head2 C<< ->api_key >>

The getter for the API key. See L<Meetup::API> for how to obtain it
and C<< ->read_credentials >> for how to initialize it.

=cut

has 'api_key' => (
    is => 'ro',
);

=head2 C<< ->url_for( $items, %options ) >>

  my $url = $m->url_for( 'group', foo => 'bar );

Creates and returns an URLfor the function C<group> from C<url_map>, interpolates
the URL parameters and appends the remaining parameters to the URL.

=cut

sub url_for( $self, $item, %options ) {
    (my $url = $self->url_map->{$item} )
      =~ s/\{(\w+)\}/exists $options{$1}? uri_escape delete $options{$1}:$1/ge;
    $url = URI->new( $self->API_BASE . $url );
    $url->query_form( key => $self->api_key, sign => 'true', %options );
    $url
}

=head2 C<< ->read_credentials( %options ) >>

  $m->read_credentials();

Looks for a file named C<meetup.credentials>, parses it as JSON and reads
the value C<applicationKey> from it.

The following options are recognized:

=over 4

=item C<filename>

The full path and filename to use instead of searching for
C<meetup.credentials>.

=item C<config_dirs>

Arrayref of directories which to search.
The default directories are C<.>, C<$ENV{HOME}> and C<$ENV{USERPROFILE}>,
in that order.

=back

=cut

sub read_credentials($self,%options) {
    if( ! $options{filename}) {
        my $fn = 'meetup.credentials';
        $options{ config_dirs } ||= [grep { defined $_ && -d $_ } ".",$ENV{HOME},$ENV{USERPROFILE}];
        ($options{ filename }) = map { -f "$_/$fn" ? "$_/$fn" : () } (@{ $options{config_dirs}});
    };
    open my $fh, '<:utf8', $options{ filename }
        or croak "Couldn't read API key from '$options{ filename }' : $!";
    local $/; # /
    my $cfg = $self->json->decode(<$fh>);
    $self->{api_key} = $cfg->{applicationKey}
}

=head2 C<< ->request( $method, $url, %params ) >>

  my $r = $meetup->request(...);

Helper to create a L<Future::HTTP> which returns decoded JSON.

=cut

sub request( $self, $method, $url, %params ) {
    $self->user_agent->http_request(
        $method => $url,
        headers => {
            'Content-Type'  => 'application/x-www-form-urlencoded', # ???
        },
    )->then(sub($body,$headers) {
        Future->done(
            $self->parse_response($body,$headers)
        );
    });
}

# We also allow to simply fetch a signed URL
# yet still handle it through our framework, even if we don't have
# the appropriate api_key.
sub fetch_signed_url( $self, $url, %options ) {
    $self->user_agent->http_request(
        'GET' => $url,
        headers => {
            'Content-Type'  => 'application/x-www-form-urlencoded', # ???
        },
    )->then(sub($body,$headers) {
        Future->done(
            $self->parse_response($body,$headers)
        );
    });
}

=head2 C<< ->parse_response( $body, $headers ) >>

Helper to parse the data structure out of a JSON response from the API.

=cut

sub parse_response($self, $body, $headers) {
    return $self->json->decode($body)
}

sub find_events( $self, %options ) {

}

=head2 C<< ->group( $urlname ) >>

  my $info = $meetup->group('Perl-User-Groups-Rhein-Main');
  print $info->{name};
  print $info->{descriptions};
  print $info->{next_event}->{time};

Returns information about a meetup group given its name in the URL.

=cut

sub group( $self, $urlname ) {
    $self->request( GET => $self->url_for('group', urlname => $urlname ))
}

=head2 C<< ->group_events( $urlname ) >>

  my $info = $meetup->group_events('Perl-User-Groups-Rhein-Main');
  print $info->[0]->{name};
  print $info->[0]->{venue};

Returns information about events of a meetup group given its name in the URL.

=cut

sub group_events( $self, $urlname ) {
    $self->request( GET => $self->url_for('group_events', urlname => $urlname ))
}

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Meetup-API>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut


1;
