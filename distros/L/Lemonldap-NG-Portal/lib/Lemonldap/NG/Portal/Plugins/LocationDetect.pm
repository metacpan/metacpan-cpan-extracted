package Lemonldap::NG::Portal::Plugins::LocationDetect;

use Mouse;
use List::MoreUtils qw/uniq/;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR);
extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::SMTP
);

has reader   => ( is => 'rw' );
has ipDetail => ( is => 'rw' );
has uaDetail => ( is => 'rw' );
use constant betweenAuthAndData => 'storeEnvironment';

sub init {
    my ($self) = @_;

    eval { use HTTP::BrowserDetect; };
    if ($@) {
        $self->logger->error("Can't load HTTP::BrowserDetect: $@");
        return 0;
    }

    eval { use GeoIP2::Database::Reader; };
    if ($@) {
        $self->logger->error("Can't load use GeoIP2::Database::Reader: $@");
        return 0;
    }
    $self->addSessionDataToRemember( {
            # This field will be hidden from the user
            _location_detect_env => '__hidden__',
        }
    );

    my @languages = split( /,\s*/,
             $self->conf->{locationDetectGeoIpLanguages}
          || $self->conf->{languages} );

    $self->reader(
        GeoIP2::Database::Reader->new(
            file    => $self->conf->{locationDetectGeoIpDatabase},
            locales => \@languages
        )
    );
    $self->ipDetail( $self->conf->{locationDetectIpDetail} || "city" );
    $self->uaDetail( $self->conf->{locationDetectUaDetail} || "browser" );
    return 1;
}

sub _get_localized {
    my ( $self, $req, $record ) = @_;
    my $lang  = $req->cookies->{llnglanguage} || 'en';
    my $names = $record->names;
    if ( $names->{$lang} ) {
        return $names->{$lang};
    }
    else {
        return $names->{en};
    }
}

sub getUaInfo {
    my ( $self, $req ) = @_;

    my $ua         = HTTP::BrowserDetect->new( $req->user_agent );
    my $os         = $ua->os;
    my $os_display = $ua->os_string;
    if ( !$os ) {
        $os         = "unknown";
        $os_display = "Unknown";
    }
    my $browser         = $ua->browser;
    my $browser_display = $ua->browser_string;
    if ( !$browser ) {
        $browser         = "unknown";
        $browser_display = "Unknown";
    }

    # Select the correct amount of detail to store/display
    my ( $uaraw, $uadisplay );

    if ( $self->uaDetail eq "browser" ) {
        $uaraw     = "$browser/$os";
        $uadisplay = "$browser_display ($os_display)";
    }
    else {
        $uaraw     = "$os";
        $uadisplay = "$os_display";
    }

    $self->logger->debug(
"[LocationDetect] getUaInfo returns uaraw $uaraw and uadisplay $uadisplay"
    );
    return ( $uaraw, $uadisplay );
}

sub getIpInfo {
    my ( $self, $req ) = @_;

    # Try to detect type of GeoIP database
    my $type = $self->reader->metadata->database_type;
    if ( $type =~ /City/ ) {
        $type = "city";
    }
    else {
        $type = "country";
    }

    my $city_display;
    my $city_code;
    my $city =
      eval { $self->reader->$type( ip => $req->address )->city() };
    if ($@) {
        $self->logger->warn( "[LocationDetect] Could not resolve city for IP "
              . $req->address . ": "
              . $@ );
        $city_code    = "unknown";
        $city_display = "Unknown";
    }
    else {
        $city_code    = $city->geoname_id                    || "unknown";
        $city_display = $self->_get_localized( $req, $city ) || "Unknown";
    }

    my $country_display;
    my $country_code;
    my $country =
      eval { $self->reader->$type( ip => $req->address )->country() };
    if ($@) {
        $self->logger->warn(
                "[LocationDetect] Could not resolve country for IP "
              . $req->address . ": "
              . $@ );
        $country_code    = "unknown";
        $country_display = "Unknown";
    }
    else {
        $country_code    = $country->iso_code                      || "unknown";
        $country_display = $self->_get_localized( $req, $country ) || "Unknown";
    }

    my ( $ipraw, $ipdisplay );
    if ( $self->ipDetail eq "city" ) {
        $ipraw     = "$city_code/$country_code";
        $ipdisplay = "$city_display ($country_display)";
    }
    else {
        $ipraw     = "$country_code";
        $ipdisplay = "$country_display";
    }

    $self->logger->debug(
"[LocationDetect] getIpInfo returns ipraw $ipraw and ipdisplay $ipdisplay"
    );
    return ( $ipraw, $ipdisplay );
}

sub storeEnvironment {
    my ( $self, $req ) = @_;

    my ( $uaraw, $uadisplay ) = $self->getUaInfo($req);
    my ( $ipraw, $ipdisplay ) = $self->getIpInfo($req);

    # This is the value we store in history for comparison
    $req->sessionInfo->{_location_detect_env} = "$uaraw/$ipraw";

    # This value is just for display
    $req->sessionInfo->{_location_detect_env_display} =
      "$uadisplay - $ipdisplay";
    $req->sessionInfo->{_location_detect_env_ua} = $uadisplay;
    $req->sessionInfo->{_location_detect_env_ip} = $ipdisplay;

    return PE_OK;
}

1;
