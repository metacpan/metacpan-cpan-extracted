package Google::Directions::Client;
use Carp;
use Digest::SHA qw/sha256_hex/;
use Encode qw/encode_utf8/;
use Google::Directions::Response;
use JSON qw/decode_json/;
use LWP::UserAgent;
use Moose;
use MooseX::Params::Validate;
use MooseX::WithCache;
use Try::Tiny;
use URL::Encode qw/url_encode/;

with 'MooseX::WithCache' => {
    backend => 'Cache::FastMmap',
    };


=head1 NAME

Google::Directions - Query directions from the google maps directions API

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 DESCRIPTION

An interface to Google Maps Directions API V3.

More details about what the API can do can be found on the L<API website|http://code.google.com/apis/maps/documentation/directions/>

=head1 SYNOPSIS

    use Google::Directions::Client;

    my $goog = Google::Directions::Client->new();
    my $response = $goog->directions(
        origin      => '25 Thompson Street, New York, NY, United States',
        destination => '34 Lafayette Street, New York, NY, United States',
        );

=head1 ATTRIBUTES

=over 4

=item I<keep_alive> Enable keep_alive for the user agent.

B<Warning:> This causes occasional errors due to partial content being returned... I'm not sure
what the root cause for this is... :(

=item I<user_agent> Define a custom L<LWP::UserAgent> if you like.

=item I<cache> Define a Cache::FastMmap if you would like to have results cached for better performance

=item I<base_url> Default: C<https://maps.googleapis.com>

=item I<api_path> Default: C</maps/api/directions/json>

=item I<limit_path_length> limit is documented at 2048, but errors occur at 2047.. Default: 2046


=back

=cut

has 'keep_alive'            => ( is => 'ro', isa => 'Int',  required => 1, default => 0              );

has 'user_agent'            => ( 
    is          => 'ro', 
    isa         => 'LWP::UserAgent',
    writer      => '_set_user_agent',
    predicate   => '_has_user_agent',
    );

has 'base_url'              => ( is => 'ro', isa => 'Str', 
    default => 'https://maps.googleapis.com' );

has 'api_path'              => ( is => 'ro', isa => 'Str',
    default => '/maps/api/directions/json' );

has 'limit_path_length'      => ( is => 'ro', isa => 'Int', default => 2046 );

# Create a LWP::UserAgent if necessary
around 'user_agent' => sub {
    my $orig = shift;
    my $self = shift;
    unless( $self->_has_user_agent ){
	if( $self->keep_alive and not $ENV{NO_WARN_KEEPALIVE} ){
	    carp( "Warning - keep_alive gives unreliable results - partial JSON returned\n" .
                "Set the enviroment variable NO_WARN_KEEPALIVE to hide this warning\n" );
	}
	my $ua = LWP::UserAgent->new(
	    'keep_alive' => $self->keep_alive,
	    );
        $self->_set_user_agent( $ua );
    }
    return $self->$orig;
};

=head1 METHODS

=head2 directions 

Returns a L<Google::Directions::Response>

=head3 params

See the API documentation L<here|http://code.google.com/apis/maps/documentation/directions/#RequestParameters> for details

=over 4 

=item I<origin> $string

=item I<destination> $string

=item I<mode> $string (Default: 'driving')

=item I<waypoints> ArrayRef[$string] (optional)

=item I<alternatives> $boolean (Default: 0)

=item I<avoid> ArrayRef[$string] (optional)

=item I<region> $string (optional)

=item I<sensor> $boolean (Default: 0)

=back

=cut

sub directions {
    my ( $self, %params ) = validated_hash(
        \@_,
        origin              => { isa => 'Str' },
        destination         => { isa => 'Str' },
        mode                => { isa => 'Str', default => 'driving' },
        waypoints           => { isa => 'ArrayRef[Str]', optional => 1 },
        alternatives        => { isa => 'Bool', optional => 1 },
        avoid               => { isa => 'ArrayRef[Str]', optional => 1 },
        #units               => { isa => 'Str', default => 'metric' }, # value is always in meters, only affects text, so irrelevant for exact computation
        region              => { isa => 'Str', optional => 1 },
        sensor              => { isa => 'Bool', default => 0 },
    );

    my @query_params;
    foreach( qw/origin destination mode units region/ ){
        if( defined( $params{$_} ) ){
            push( @query_params, sprintf( "%s=%s",
                $_, url_encode( $params{$_} ) ) );
        }
    }

    foreach( qw/alternatives sensor/ ){
        if( $params{$_} ){
            push( @query_params, sprintf( "%s=true", $_ ) );
        }else{
            push( @query_params, sprintf( "%s=false", $_ ) );
        }
    }

    foreach my $key( qw/waypoints avoid/ ){
        if( defined( $params{$key} ) ){
            my $joined = join( '|', @{ $params{$key} } );
            push( @query_params, sprintf( "%s=%s", $key, url_encode( $joined ) ) );
        }
    }

    my $path = $self->api_path . '?' . join( '&', @query_params );
    
    # Make sure path is not too long
    if( length( $path ) > $self->limit_path_length ){
        croak( printf( "Path may not be more than %u characters but is %u\n",
                $self->limit_path_length,
                length( $path ),
                ) );
    }

    my $url = $self->base_url . $path;
    my $cache_key = sha256_hex( $url );
    my $google_response = $self->cache_get( $cache_key );
    if( $google_response ){
        $google_response->set_cached( 1 );
    }

    if( not $google_response ){
        my $response = $self->user_agent->get( $url );

        if( not $response->is_success ){
            croak( "Query failed: " . $response->status_line );
        }

        my $data = try{
            return decode_json( encode_utf8( $response->decoded_content ) );
        }catch{
            croak( $_ );
        };
        $google_response = Google::Directions::Response->new( $data );
        if( $self->cache and not $self->cache_set( $cache_key, $google_response ) ){
            carp( "Response not saved in cache - too big\n" );
        }
    }

    return $google_response;
}


=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-directions at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Directions>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Directions::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Directions>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Directions>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Google-Directions>

=item * Search CPAN

L<http://search.cpan.org/dist/Google-Directions/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Google::Directions
