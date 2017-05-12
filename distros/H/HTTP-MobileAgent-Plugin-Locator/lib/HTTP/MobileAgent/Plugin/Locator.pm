package HTTP::MobileAgent::Plugin::Locator;

use warnings;
use strict;
use HTTP::MobileAgent;
use Carp;
use UNIVERSAL::require;
use UNIVERSAL::can;

use base qw( Exporter );
our @EXPORT_OK = qw( $LOCATOR_AUTO_FROM_COMPLIANT $LOCATOR_AUTO $LOCATOR_GPS $LOCATOR_BASIC );
our %EXPORT_TAGS = (locator => [@EXPORT_OK]);

our $VERSION = '0.04';

our $LOCATOR_AUTO_FROM_COMPLIANT = 1;
our $LOCATOR_AUTO                = 2;
our $LOCATOR_GPS                 = 3;
our $LOCATOR_BASIC               = 4;


sub import {
    my ( $class ) = @_;
    no strict 'refs';
    *HTTP::MobileAgent::locator       = sub { $class->new( @_ ) };
    *HTTP::MobileAgent::get_location  = sub {
        my ( $self, $stuff, $option_ref ) = @_;
        my $params = _prepare_params( $stuff );
        $self->locator( $params, $option_ref )->get_location( $params );
    };
    $class->export_to_level( 1, @_ );
}

sub new {
    my ( $class, $agent, $params, $option_ref ) = @_;
    my $carrier_locator = _get_carrier_locator( $agent, $params, $option_ref );
    my $locator_class = "HTTP::MobileAgent::Plugin::Locator::$carrier_locator";
    $locator_class->require or die $!;
    return bless {}, $locator_class;
}

sub get_location { die "ABSTRACT METHOD" }

sub _get_carrier_locator {
    my ( $agent, $params, $option_ref ) = @_;

    my $carrier = $agent->is_docomo     ? 'DoCoMo'
                : $agent->is_ezweb      ? 'EZweb'
                : $agent->is_softbank   ? 'SoftBank'
                : $agent->is_airh_phone ? 'Willcom'
                : undef;
    croak( "Invalid mobile user agent: " . $agent->user_agent ) if !$carrier;

    my $locator;
    if ( !defined $option_ref
         || !defined $option_ref->{locator}
         || $option_ref->{locator} eq $LOCATOR_AUTO_FROM_COMPLIANT ) {
        $locator = $agent->gps_compliant ? 'GPS' : 'BasicLocation';
    }
    elsif ( $option_ref->{locator} eq $LOCATOR_AUTO ) {
        $locator = _is_gps_parameter( $agent, $params ) ? 'GPS' : 'BasicLocation';
    }
    elsif ( $option_ref->{locator} eq $LOCATOR_GPS ) {
        $locator = 'GPS';
    }
    elsif ( $option_ref->{locator} eq $LOCATOR_BASIC ) {
        $locator = 'BasicLocation';
    }
    else {
        croak( "Invalid locator: " . $option_ref->{locator} );
    }

    return $carrier . '::' . $locator;
}

# to check whether parameter is gps or basic
sub _is_gps_parameter {
    my ( $agent, $stuff ) = @_;
    my $params = _prepare_params( $stuff );
    if ( $agent->is_docomo ) {
        return !defined $params->{ AREACODE };
    }
    elsif ( $agent->is_ezweb ) {
        return defined $params->{ datum } && $params->{ datum } =~ /^\d+$/
    }
    elsif ( $agent->is_softbank ) {
        return defined $params->{ pos };
    }
    elsif ( $agent->is_airh_phone ) {
        return;
    }
    else {
        croak( "Invalid mobile user agent: " . $agent->user_agent );
    }
}

sub _prepare_params {
    my $stuff = shift;
    if ( ref $stuff && eval { $stuff->can( 'param' ) } ) {
        return +{ map {
            $_ => ( scalar(@{[$stuff->param($_)]}) > 1 ) ? [ $stuff->param( $_ ) ]
                                                         : $stuff->param( $_ )
        } $stuff->param };
    }
    else {
        return $stuff;
    }
}

1;
__END__

=head1 NAME

HTTP::MobileAgent::Plugin::Locator - Handling mobile location information plugin for HTTP::MobileAgent

=head1 SYNOPSIS

    use CGI;
    use HTTP::MobileAgent;
    use HTTP::MobileAgent::Plugin::Locator;

    $q = CGI->new;
    $agent = HTTP::MobileAgent->new;

    # get location is Geo::Coordinates::Converter::Point instance formatted wgs84
    # ./t/* has many examples.
    $location = $agent->get_location( $q );
    # or
    $location = $agent->get_location( { lat => '35.21.03.342',
                                        lon => '138.34.45.725',
                                        geo => 'wgs84' } );
    # or
    $location = $agent->get_location( $q, { locator => $LOCATOR_GPS } );

    # get latitude and longitude
    print "lat is " . $location->lat;
    print "lng is " . $location->lng;

=head1 METHODS

=head2 get_location([params], $option_ref);

return Geo::Coordinates::Converter::Point instance formatted if specify gps or basic location parameters sent from carrier. The parameters are different by each carrier.

This method accepts a CGI-ish object (an object with 'param' method, e.g. CGI.pm, Apache::Request, Plack::Request) or a hashref of query parameters.

=over

=item $option_ref->{locator}

select locator class algorithm option.

$LOCATOR_AUTO_FROM_COMPLIANT
 auto detect locator from gps compliant. This is I<default>.

$LOCATOR_AUTO
 auto detect locator class from params.

$LOCATOR_GPS
 select GPS class.

$LOCATOR_BASIC
 select BasicLocation class.

=back

=head2 gps_compliant()

returns if the agent is GPS compliant.

=head1 CLASSES

=over

=item HTTP::MobileAgent::Plugin::Locator::DoCoMo::BasicLocation

for iArea data support.

=item HTTP::MobileAgent::Plugin::Locator::DoCoMo::GPS

for GPS data support.

=item HTTP::MobileAgent::Plugin::Locator::EZweb::BasicLocation

for basic location information data support.

=item HTTP::MobileAgent::Plugin::Locator::EZweb::GPS

for EZnavi data support.

=item HTTP::MobileAgent::Plugin::Locator::SoftBank::BasicLocation

for basic location information data support.

=item HTTP::MobileAgent::Plugin::Locator::SoftBank::GPS

for GPS data support.

=item HTTP::MobileAgent::Plugin::Locator::Willcom::BasicLocation

for basic location information data support.

=back

=head1 EXAMPLES

There is request template using C<Template> in eg directory and mod_rewrite configuration for ezweb extraordinary parameter handling.

=head1 COOK BOOK

=over 4

=item HOW DO I GET iArea area code.

    use Geo::Coordinates::Converter::iArea;
    my $areacode = $agent->get_location($q)->converter('iarea')->areacode;

=item HOW DO I GET geohash.

    use Geo::Coordinates::Converter::Format::GeoHash;
    my $geohash = $ma->get_location(
        { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' },
    )->converter('wgs84', 'geohash')->geohash;

=item 

=back

=head1 AUTHOR

Yoshiki Kurihara  E<lt>kurihara __at__ cpan.orgE<gt> with many feedbacks and changes from:

  Tokuhiro Matsuno E<lt>tokuhirom __at__ gmail.comE<gt>
  Masahiro Chiba E<lt>chiba __at__ geminium.comE<gt>

=head1 SEE ALSO

C<HTTP::MobileAgent>, C<Geo::Coordinates::Converter>, C<Geo::Coordinates::Converter::Point>, C<Geo::Coordinates::Converter::iArea>, C<http://coderepos.org/share/log/lang/perl/HTTP-MobileAgent-Plugin-Locator/>

=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
