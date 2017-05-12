package Geo::Coder::Cloudmade;

our $VERSION = '0.7';

use strict;

use Carp qw(croak);
use Encode;
use JSON::Syck;
use HTTP::Request;
use LWP::UserAgent;
use URI;


sub new {
    my $class = shift;
    my $args = ref( $_[0] ) ? $_[0] : { @_ };

    my $ua = $args->{ua} || LWP::UserAgent->new( agent => __PACKAGE__ . "/$VERSION" );
    my $host = $args->{host} || 'geocoding.cloudmade.com';

	unless( exists($args->{apikey}) )
	{
		croak "Required parameter 'apikey' not specified";
	};

    my $self = {
        apikey  => $args->{apikey},
        ua      => $ua,
        host    => $host,
    };
    bless $self, $class;

    return( $self );
};


sub geocode {
    my $self = shift;
    my $args = ref( $_[0] ) ? $_[0] : { @_ };

    my $location = $args->{location};

	$location = Encode::encode_utf8($location);

    my $url_string = 'http://'. $self->{host} .'/'. $self->{apikey} .'/geocoding/v2/find.js';

    my $uri = URI->new( $url_string );
    $uri->query_form( query => $location );

    my $res = $self->{ua}->get( $uri );

    if ($res->is_error) {
        die "Cloudmade API returned error: " . $res->status_line;
    }

    local $JSON::Syck::ImplicitUnicode = 1;
    my $data = JSON::Syck::Load( $res->content );

    my $results = [];

    foreach my $point ( @{$data->{features}} ) {
        my $tmp = {
            lat     => $point->{centroid}->{coordinates}->[0],
            long    => $point->{centroid}->{coordinates}->[1],
        };
        push @{$results}, $tmp;
    };

    wantarray ? @{$results} : $results->[0];
}

1;

__END__

=head1 NAME

Geo::Coder::Cloudmade - Geocode addresses with the Cloudmade API 

=head1 VERSION

Version 0.2

=head1 SYNOPSIS

Provides a thin Perl interface to the Cloudmade Geocoding API.

    use Geo::Coder::Cloudmade;

    my $geocoder = Geo::Coder::Cloudmade->new( apikey => 'my_app' );
    my $location = $geocoder->geocode( { location => '1370 Willow Road, 2nd Floor, Menlo Park, CA 94025 USA' } );

=head1 OFFICIAL API DOCUMENTATION

Read more about the API at
L<http://developers.cloudmade.com/>.

=head1 METHOD

=over 4

=head2 new   

Constructs a new C<Geo::Coder::Cloudmade> object and returns it. Requires a 
Cloudmade api key as an argument.

  KEY                   VALUE
  -----------           --------------------
  apikey                Cloudmade API key


=head2 geocode

Takes a location in a hashref as an argument and returns the list of matching
coordinates for the specified location.

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
