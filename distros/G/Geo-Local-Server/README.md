# NAME

Geo::Local::Server - Returns the configured coordinates of the local server

# SYNOPSIS

    use Geo::Local::Server;
    my $gls         = Geo::Local::Server->new;
    my ($lat, $lon) = $gls->latlon;

# DESCRIPTION

Reads coordinates from either the user environment variable COORDINATES\_WGS84\_LON\_LAT\_HAE or the file /etc/local.coordinates or C:\\Windows\\local.coordinates.

# USAGE

## Scripts

Typical use is with the provided scripts

    is_nighttime && power-outlet WeMo on  host mylamp
    is_daytime   && power-outlet WeMo off host mylamp
    echo "power-outlet WeMo on  host mylamp" | at `sunset_time`
    echo "power-outlet WeMo off host mylamp" | at `sunrise_time`

## One Liner

    $ perl -MGeo::Local::Server -e 'printf "Lat: %s, Lon: %s\n", Geo::Local::Server->new->latlon'
    Lat: 38.7803, Lon: -77.3867

# METHODS

## latlon, latlong

Returns a list of latitude, longitude

## lat

Returns the latitude.

## lon

Returns the longitude

## hae

Returns the configured height of above the ellipsoid

## lonlathae

Returns a list of longitude, latitude and height above the ellipsoid

# PROPERTIES

## envname

Sets and returns the name of the environment variable.

    my $var=$gls->envname; #default COORDINATES_WGS84_LON_LAT_HAE
    $gls->envname("");     #disable environment lookup
    $gls->envname(undef);  #reset to default

## configfile

Sets and returns the location of the local.coordinates filename.

    my $var=$gls->configfile; #default /etc/local.coordinates or C:\Windows\local.coordinates
    $gls->configfile("");     #disable file-based lookup
    $gls->configfile(undef);  #reset to default

# CONFIGURATION

## File

I recommend building and installing an RPM from the included SPEC file which installs /etc/local.coorindates.

    rpmbuild -ta Geo-Local-Server-?.??.tar.gz

Outerwise copy the example etc/local.coorindates file to either /etc/ or C:\\Windows\\ and then update the coordinates to match your server location.

## Environment

I recommend building and installing an RPM with the included SPEC file which installs /etc/profile.d/local.coordinates.sh which correctly sets the COORDINATES\_WGS84\_LON\_LAT\_HAE environment variable.

Otherwise you can export the COORDINATES\_WGS84\_LON\_LAT\_HAE variable or add it to your .bashrc file.

    export COORDINATES_WGS84_LON_LAT_HAE="-77.3867 38.7803 63"

## Format

The /etc/local.coordinates file is an INI file. The \[wgs84\] section is required for this package to function.

    [main]
    version=1

    [wgs84]
    latitude=38.7803
    longitude=-77.3867
    hae=63

# OBJECT ACCESSORS

## ci

Returns the [Config::IniFiles](https://metacpan.org/pod/Config%3A%3AIniFiles) object so that you can read additional information from the INI file.

    my $config=$gls->ci; #isa Config::IniFiles

Example

    my $version=$gls->ci->val("main", "version");

# BUGS

Please log on GitHub

# AUTHOR

    Michael R. Davis

# COPYRIGHT

MIT

# SEE ALSO

[DateTime::Event::Sunrise](https://metacpan.org/pod/DateTime%3A%3AEvent%3A%3ASunrise), [Power::Outlet](https://metacpan.org/pod/Power%3A%3AOutlet), [Geo::Point](https://metacpan.org/pod/Geo%3A%3APoint), [URL::geo](https://metacpan.org/pod/URL%3A%3Ageo)
