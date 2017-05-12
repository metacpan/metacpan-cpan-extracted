package Geo::Distance::Google;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dumper qw( Dumper );
use Encode;
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use Params::Validate;
use URI;

sub new {
    my($class, %param) = @_;

    my $ua       = delete $param{ua}       || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
    my $host     = delete $param{host}     || 'maps.googleapis.com';

    my $language = delete $param{language} || delete $param{hl};
    my $region   = delete $param{region}   || delete $param{gl};
    my $oe       = delete $param{oe}       || 'utf8';
    my $sensor   = delete $param{sensor}   || 0;
    my $client   = delete $param{client}   || '';
    my $key      = delete $param{key}      || '';
    my $units    = delete $param{units}    || '';
    my $mode     = delete $param{mode};
    my $avoid    = delete $param{avoid};
    my $https    = delete $param{https}    || 0;
    my $debug    = delete $param{debug}    || 0;
   
    bless { 
        ua => $ua, 
        host => $host, 
        language => $language, 
        region => $region, 
        oe => $oe, 
        sensor => $sensor,
        client => $client, 
        key => $key, 
        units  => $units,
        mode => $mode,
        avoid => $avoid,
        https => $https,
        __debug__ => $debug
    }, $class;
}

sub debug_level {
    my $self = shift;

    if ( @_ ) { $self->{__debug__} = shift; }

    return $self->{__debug__};
}

sub ua {
    my $self = shift;
    if (@_) {
        $self->{ua} = shift;
    }
    $self->{ua};
}

sub raw_distance {
    my $self = shift;

    $self->{__raw_response__} = shift if @_;

    return $self->{__raw_response__};
}

sub distance {
    my $self = shift;
    my %p    = validate @_, { 
        origins      => 1, 
        destinations => 1, 
        mode         => 0,
        avoid        => 0,
        units        => 0
    };

    my $origins;
    my $destinations;

    # both can be array refs or single items
    foreach my $k ( qw( origins destinations ) ) {
        # convert to google format

        # TODO: in future allow seperate lat & long in hash ref
        if ( ref $p{$k} ne 'ARRAY' ) {
            $p{$k} = [ $p{$k} ];
        }
    }

    $origins      = join '|', @{ $p{origins} };
    $destinations = join '|', @{ $p{destinations} };


    $origins      = Encode::is_utf8( $origins ) ? Encode::encode_utf8( $origins ) : $origins;
    $destinations = Encode::is_utf8( $destinations ) ? Encode::encode_utf8( $destinations ) : $destinations;

    my $url = sprintf "%s://%s/maps/api/distancematrix/json",
        ( $self->{https} ? 'https' : 'http' ), $self->{host};

    my $uri = URI->new($url);

    # build query
    my %query_parameters = (
        origins      => $origins,
        destinations => $destinations,
        oe           => $self->{oe},
        sensor       => ( $self->{sensor} ? 'true' : 'false' ),
        # optional parameters
        ( $self->{units} ? ( units => $self->{units} ) : () ),
        ( $p{mode}       ? ( mode => $p{mode} ) 
            : defined $self->{mode} ? ( mode => $self->{mode} ) : ()),
        # TODO: add support for avoid as list ref process too
        ( $p{avoid} ? ( avoid => $p{avoid} )
            : defined $self->{avoid} ? ( avoid => $self->{avoid} ) : () )
    );

    # not sure about these
    $query_parameters{language} = $self->{language} if defined $self->{language};
    $query_parameters{region}   = $self->{region}   if defined $self->{region};

    $uri->query_form(%query_parameters);

    # setup request
    $url = $uri->as_string;

    # Process Maps Premier account info
    if ($self->{client} and $self->{key}) {
        $query_parameters{client} = $self->{client};
        $uri->query_form(%query_parameters);

        my $signature = $self->make_signature($uri);
        # signature must be last parameter in query string or you get 403's
        $url = $uri->as_string;
        $url .= '&signature='.$signature if $signature;
    }

    $self->debug( "Sending request: $url" );

    my $res = $self->{ua}->get($url);

    if ($res->is_error) {
        Carp::croak("Google Maps API returned error: " . $res->status_line);
    }

    if ( $res->headers->content_type !~ /json/ ) {
        my $ct = $res->headers->content_type;
        croak "Invalid content-type '$ct' returned from webserver";
    }

    my $json = JSON->new->utf8;
    my $data = $json->decode($res->content);

    $self->raw_distance( $data );

    $self->debug( "data: " . Dumper( $data ) );

    if ( ! defined $data->{status} || $data->{status} ne 'OK' ) {
        croak "Google Maps API status error: " . ( $data->{status} || 'Invalid status' );
    }

    # reprocess to make more friendly (IMO)
    my $distance = [];

    # origins[0] correspond to rows[0]
    # destinations[0] correspond to rows->[x]->elements[0]
    for ( my $oid = 0; $oid < scalar( @{ $p{origins} } ); $oid++ ) {

        # verify origin information
        next unless defined $data->{origin_addresses} &&
            defined $data->{origin_addresses}->[$oid];

        # missing return data
        next unless defined $data->{rows} && $data->{rows}->[$oid];

        $distance->[$oid]->{origin_address} = $data->{origin_addresses}->[$oid];

        my $elements = $data->{rows}->[$oid]->{elements};

        # loop through each destination address
        foreach ( my $did = 0; $did < scalar( @{ $p{destinations} } ); $did++ ) {
            next unless defined $elements->[$did];

            # reformat it to be a bit nicer for the consumer
            $distance->[$oid]->{destinations}->[$did] = {
                address  => $data->{destination_addresses}->[$did],
                distance => $elements->[$did]->{distance}, 
                duration => $elements->[$did]->{duration}, 
                status   => $elements->[$did]->{status}
            };
        }

    }

    $self->debug( "distance: " . Dumper($distance) );

    return $distance;
}

# methods below adapted from 
# http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/urlsigner.pl
sub decode_urlsafe_base64 {
  my ($self, $content) = @_;

  $content =~ tr/-/\+/;
  $content =~ tr/_/\//;

  return MIME::Base64::decode_base64($content);
}

sub encode_urlsafe{
  my ($self, $content) = @_;
  $content =~ tr/\+/\-/;
  $content =~ tr/\//\_/;

  return $content;
}

sub make_signature {
  my ($self, $uri) = @_;

  require Digest::HMAC_SHA1;
  require MIME::Base64;

  my $key = $self->decode_urlsafe_base64($self->{key});
  my $to_sign = $uri->path_query;

  my $digest = Digest::HMAC_SHA1->new($key);
  $digest->add($to_sign);
  my $signature = $digest->b64digest;

  return $self->encode_urlsafe($signature);
}

# search input hash ref, then self for defined parameter or
# return empty list
sub _get_multiple {
    my $self = shift;
    my $p    = shift || return (); # params
    my $key  = shift || return (); # key

    return () unless ref $p eq 'HASH';

    return defined $p->{$key} ? ( $key => $p->{$key} ) 
        : defined $self->{$key} ? ( $key => $self->{$key} ) : ();
}

sub debug {
    my $self = shift;
    my $f = (caller(1))[3];

    return unless $self->debug_level;

    printf STDERR "%s [%s] %s\n", scalar( localtime ), $f, shift;
}


1;

__END__

=head1 NAME

Geo::Distance::Google - Google Maps Distance API

=head1 SYNOPSIS

  use Geo::Distance::Google;

  my $geo = Geo::Distance::Google->new; 

  my $distance = $geo->distance(
    # sears tower... wacker tower whatever
    origins      => '233 S. Wacker Drive Chicago, Illinois 60606',
    destinations => '1600 Amphitheatre Parkway, Mountain View, CA'
  );

  printf "The distance between: %s and %s is %s\n",
     $distance->[0]->{origin_address},
     $distance->[0]->{destinations}->[0]->{address},
     $distance->[0]->{destinations}->[0]->{distance}->{text};

=head1 DESCRIPTION

Geo::Distance::Google provides a distance and duration functionality using Google Maps API.

=head1 METHODS

=head2 new

Create new geo distance object.

  $geo = Geo::Distance::Google->new( https => 1 );
  $geo = Geo::Distance::Google->new( language => 'ru' );
  $geo = Geo::Distance::Google->new( gl => 'ca' );

=head3 Parameters (all are optional)

=over 4

=item * ua - L<LWP::UserAgent> object or compatiable 

=item * host - url of api host

=item * language - Google's response will be in this language (when possible by google)

=item * region - region for usage 

=item * sensor - true (1) when pulling data from GPS sensor

=item * mode - mode of transport (default: driving)

=item * avoid - restrictions applied to directions (supports 'tolls' or 'highways')

=item * https - set to true will make requests with https

=item * debug - true will output internal debugging info

=back 

You can optionally use your Maps Premier Client ID, by passing your client
code as the C<client> parameter and your private key as the C<key> parameter.
The URL signing for Premier Client IDs requires the I<Digest::HMAC_SHA1>
and I<MIME::Base64> modules. To test your client, set the environment
variables GMAP_CLIENT and GMAP_KEY before running 02_v3_live.t

  GMAP_CLIENT=your_id GMAP_KEY='your_key' make test

=head2 distance 

  $distance = $geo->distance( 
    origins      => '233 S. Wacker Drive Chicago, Illinois 60606',
    destinations => '1600 Amphitheatre Parkway, Mountain View, CA'
  )

  # multiple origins
  $distance = $geo->distance( 
    origins      => [ 
      'One MetLife Stadium Drive, East Rutherford, New Jersey 07073, United States',
      '602 Jamestown Avenue, San Francisco, California 94124'
    ],
    destinations => '1265 Lombardi Avenue, Green Bay, Wisconsin 54304'
  );

  # lat and lng
  $distance => $geo->distance( 
    origins      => '34.101063,-118.3385319',
    destinations => '34.1613743,118.1676149'
  );

Queries I<$geo> to Google Maps distance API and returns list
reference that contains each origin to destination mapping.

Data returned from second example above looks like:

  [
    {
      'origin_address' => 'MetLife Stadium, 102 Stadium Rd, East Rutherford, NJ 07073, USA',
      'destinations' => [
        {
          'distance' => {
             'value' => 1587392,
              'text' => '1,587 km'
           },
           'status'   => 'OK',
           'duration' => {
             'value' => 60332,
             'text'  => '16 hours 46 mins'
           },
           'address' => '1265 Lombardi Ave, Green Bay, WI 54304, USA'
         }
       ]
     },
     {
       'origin_address' => '602 Jamestown Ave, San Francisco, CA 94124, USA',
       'destinations' => [
         {
           'distance' => {
             'value' => 3615562,
             'text'  => '3,616 km'
           },
           'status' => 'OK',
           'duration' => {
             'value' => 127697,
             'text'  => '1 day 11 hours'
           },
           'address' => '1265 Lombardi Ave, Green Bay, WI 54304, USA'
         }
       ]
     }
  ]

When you'd like to pass non-ascii string as a location, you should
pass it as either UTF-8 bytes or Unicode flagged string.

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

  $coder->ua->env_proxy;

You can also set your own User-Agent object:

  $coder->ua( LWPx::ParanoidAgent->new );

=head2 debug_level

Set to true to get extra debugging information

=head2 encode_urlsafe

Encodes url 

=head2 decode_urlsafe_base64 

Decodes url 

=head2 make_signature

Creates google friendly signature

=head2 raw_distance

Returns raw json response from google API request


=head1 ACKNOWLEDGEMENTS

I borrowed much of this inital code from C<Geo::Coder::Google>, it sped up much of 
my work and was a great help. Thanks.

=head1 AUTHOR

Lee Carmichael, C<< <lcarmich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-distance-google at rt.cpan.org>, 
or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Distance-Google>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Distance::Google

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://github.com/lecar-red/Geo-Distance-Google/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Distance-Google>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Distance-Google>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Distance-Google/>

=back

=head1 TODO

=over 4

=item * Add support to distance method for explicit latitude and longtitude parameters (support by hand encoding as 'lat|lng'

=item * Add tests for method based changes to attributes L<avoid>, L<mode> and L<units>

=item * Add tests for API keys

=item * Add tests for imperial units

=back

=head1 SEE ALSO

L<Geo::Distance>, L<Geo::Coder::Google>

List of supported languages: L<http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1>

API Docs: L<http://code.google.com/apis/maps/documentation/distancematrix/>,

=cut
