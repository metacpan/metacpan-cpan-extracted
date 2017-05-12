package Geo::Coder::Yahoo;
BEGIN {
  $Geo::Coder::Yahoo::VERSION = '0.50';
}

use warnings;
use strict;

use Carp qw(croak);
use Encode qw(decode);
use URI 1.36;
use URI::QueryParam;
use LWP::UserAgent;
use Yahoo::Search::XML 20100612;

sub ua {
    my $self = shift;
    $self->{ua} = shift if @_;
    return $self->{ua};
}

sub new {
    my $class = shift;
    my %args = @_;
    return bless {
        appid => $args{appid},
        on_error => $args{on_error} || sub { undef },
        ua => $args{ua} || do {
            my $ua = LWP::UserAgent->new;
            $ua->agent(__PACKAGE__ . '/' . ($Geo::Coder::Yahoo::VERSION || 'git'));
            $ua->env_proxy;
            $ua;
        },
    }, $class;
}

sub geocode {
    my $self = shift;
    my %args = @_;

    my $appid = $args{appid};
    $appid = $self->{appid} if !$appid and ref $self;
    croak "appid parameter required" unless $appid;

    my $u = URI->new('http://api.local.yahoo.com/MapsService/V1/geocode');
    $u->query_param(appid => $self->{appid});
    $u->query_param($_ => $args{$_}) for keys %args;

    my $resp = $self->ua->get($u->as_string);

    return $self->{on_error}->($self, $resp)
        if not $resp->is_success;

    my $parsed = Yahoo::Search::XML::Parse($resp->content);
    return undef unless $parsed and $parsed->{Result};

    my $results = $parsed->{Result};
    $results = [ $parsed->{Result} ] if ref $parsed->{Result} eq 'HASH';

    for my $d (@$results) {
        for my $k (keys %$d) {
            $d->{lc $k} = delete $d->{$k};
        }
    }

    $results;
}

1;

__END__

=encoding utf-8

=head1 NAME

Geo::Coder::Yahoo - Geocode addresses with the Yahoo! API 

=head1 SYNOPSIS

Provides a thin Perl interface to the Yahoo! Geocoding API.

    use Geo::Coder::Yahoo;

    my $geocoder = Geo::Coder::Yahoo->new(appid => 'my_app' );
    my $location = $geocoder->geocode( location => 'Hollywood and Highland, Los Angeles, CA' );

=head1 OFFICIAL API DOCUMENTATION

Read more about the API at
L<http://developer.yahoo.net/maps/rest/V1/geocode.html>.

Yahoo! says that this API is deprecated and suggest using the
placefinder API instead.  There's a module for that in
L<Geo::Coder::Placefinder>.

See also L<Geo::Coder::Many>.

=head1 PROXY SETTINGS

We use the standard proxy setting environment variables via LWP.  See
the LWP documentation for more information.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Yahoo->new(appid => $appid)

    $geocoder = Geo::Coder::Yahoo->new(
        appid => $appid,
        on_error => sub { ... },
        ua => LWP::UserAgent->new,
    )

Instantiates a new object.

appid specifies your Yahoo Application ID.  You can register at
L<http://api.search.yahoo.com/webservices/register_application>.

If you don't specify it here you must specify it when calling geocode.

on_error specifies an error handler to be called if the HTTP response code does
not indicate success. The subroutine is called with the geocode object as the
first argument and the HTTP::Response object as the second. The return value
from the subroutine is used as the return value from L</geocode>.

ua specifies the user agent object to use. If not set then a new L<LWP::UserAgent>
will be instanciated.

=head2 geocode( location => $location )

Parameters are the URI arguments documented on the Yahoo API page
(location, street, city, state, zip).  You usually just need one of
them to get results.

C<geocode> returns a reference to an array of results (an arrayref).
More than one result may be returned if the given address is
ambiguous.

Each result in the arrayref is a hashref with data like the following example:

    {
     'country' => 'US',
     'longitude' => '-118.3387',
     'state' => 'CA',
     'zip' => '90028',
     'city' => 'LOS ANGELES',
     'latitude' => '34.1016',
     'warning' => 'The exact location could not be found, here is the closest match: Hollywood Blvd At N Highland Ave, Los Angeles, CA 90028',
     'address' => 'HOLLYWOOD BLVD AT N HIGHLAND AVE',
     'precision' => 'address'
     }

=over 4

=item precision

The precision of the address used for geocoding, from specific street
address all the way up to country, depending on the precision of the
address that could be extracted. Possible values, from most specific
to most general are:

=over 4

=item address

=item street

=item zip+4

=item zip+2

=item zip

=item city

=item state

=item country

=back

=item warning

If the exact address was not found, the closest available match will be noted here.

=item latitude

The latitude of the location.

=item longitude

The longitude of the location.

=item address

Street address of the result, if a specific location could be determined.

=item city

City in which the result is located.

=item state

State in which the result is located.

=item zip 

Zip code, if known.

=item country

Country in which the result is located.

=back

=head2 ua

    $ua = $geocoder->ua;

    $geocoder->ua( $new_ua );

Sets the user agent object to be used, if one is passed.
Returns the user agent object.

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-coder-yahoo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-Yahoo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Yahoo

You can also look for information at:

=over 4

=item * Git Repository

The latest code is available from the git repository at
L<git://git.develooper.com/Geo-Coder-Yahoo.git>.  You can browse it at 
L<http://git.develooper.com/?p=Geo-Coder-Yahoo.git;a=summary>.

It is also at L<http://github.com/abh/geo-coder-yahoo/tree/master>. 

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Yahoo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Yahoo>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Yahoo>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Yahoo for providing this free API.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Ask Bjoern Hansen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

