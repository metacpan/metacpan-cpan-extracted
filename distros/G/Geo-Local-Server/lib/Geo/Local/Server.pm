package Geo::Local::Server;
use strict;
use warnings;
use base qw{Package::New};
use Config::IniFiles qw{};
use Path::Class qw{file};
#runtime use Win32 if Windows
#runtime use Sys::Config unless Windows

our $VERSION = '0.09';

=head1 NAME

Geo::Local::Server - Returns the configured coordinates of the local server

=head1 SYNOPSIS

  use Geo::Local::Server;
  my $gls=Geo::Local::Server->new;
  my ($lat, $lon)=$gls->latlon;

=head1 DESCRIPTION

Reads coordinates from either the user environment variable COORDINATES_WGS84_LON_LAT_HAE or the file /etc/local.coordinates or C:\Windows\local.coordinates.

=head1 USAGE

=head2 Scripts

Typical use is with the provided scripts

  is_nighttime && power-outlet WeMo on  host mylamp
  is_daytime   && power-outlet WeMo off host mylamp
  echo "power-outlet WeMo on  host mylamp" | at `sunset_time`
  echo "power-outlet WeMo off host mylamp" | at `sunrise_time`

=head2 One Liner

  $ perl -MGeo::Local::Server -e 'printf "Lat: %s, Lon: %s\n", Geo::Local::Server->new->latlon'
  Lat: 38.780276, Lon: -77.386706

=head1 METHODS

=head2 latlon, latlong

Returns a list of latitude, longitude

=cut

sub latlon {(shift->lonlathae)[1,0]};

sub latlong {(shift->lonlathae)[1,0]};

=head2 lat

Returns the latitude.

=cut

sub lat {(shift->lonlathae)[1]};

=head2 lon

Returns the longitude

=cut

sub lon {(shift->lonlathae)[0]};

=head2 hae

Returns the configured height of above the ellipsoid

=cut

sub hae {(shift->lonlathae)[2]};

=head2 lonlathae

Returns a list of longitude, latitude and height above the ellipsoid

=cut

sub lonlathae {
  my $self=shift;
  unless ($self->{"lonlathae"}) {
    my $coordinates="";
    my $envname=$self->envname;
    my $file="";
    if ($envname) {
      $coordinates=$ENV{$envname} || "";
      $coordinates=~s/^\s*//; #trim white space from beginning
      $coordinates=~s/\s*$//; #trim white space from end
    }
    if ($coordinates) {
      #First Step Pull from environment which can be configured by user
      my ($lon, $lat, $hae)=split(/\s+/, $coordinates);
      $self->{"lonlathae"}=[$lon, $lat, $hae];
    } elsif (defined($file=$self->configfile) and -r $file and defined($self->ci) and $self->ci->SectionExists("wgs84")) {
      #We assign the config filename inside the elsif to not load runtime requires if we hit the ENV above.
      #Second Step Pull from file system which can be configured by system
      my $lat=$self->ci->val(wgs84 => "latitude");
      my $lon=$self->ci->val(wgs84 => "longitude");
      my $hae=$self->ci->val(wgs84 => "hae");
      $self->{"lonlathae"}=[$lon, $lat, $hae];
    } else {
      #TODO: GeoIP
      #TODO: gpsd
      #TODO: some kind of memory block transfer
      my $error=qq{Error: None of the following supported coordinate standards are configured.\n\n};
      $error.=$envname  ? qq{  - Environment variable "$envname" is not set\n} : qq{  - Environment variable is disabled\n};
      $error.=$file     ? qq{  - Config file "$file" is not readable.\n}       : qq{  - Config file is disabled\n};
      die("$error ");
    }
  }
  return @{$self->{"lonlathae"}};
}

=head1 PROPERTIES

=head2 envname

Sets and returns the name of the environment variable.

  my $var=$gls->envname; #default COORDINATES_WGS84_LON_LAT_HAE
  $gls->envname("");     #disable environment lookup
  $gls->envname(undef);  #reset to default

=cut

sub envname {
  my $self=shift;
  $self->{"envname"}=shift if $_;
  $self->{"envname"}="COORDINATES_WGS84_LON_LAT_HAE" unless defined $self->{"envname"};
  return $self->{"envname"};
}

=head2 configfile

Sets and returns the location of the local.coordinates filename.

  my $var=$gls->configfile; #default /etc/local.coordinates or C:\Windows\local.coordinates
  $gls->configfile("");     #disable file-based lookup
  $gls->configfile(undef);  #reset to default

=cut

sub configfile {
  my $self=shift;
  $self->{"configfile"}=shift if @_;
  unless (defined $self->{"configfile"}) {
    my $file="local.coordinates";
    my $path="/etc"; #default is unix-like systems
    if ($^O eq "MSWin32") {
      eval("use Win32");
      $path=eval("Win32::GetFolderPath(Win32::CSIDL_WINDOWS)") unless $@;
    } else {
      eval("use Sys::Path");
      $path=eval("Sys::Path->sysconfdir") unless $@;
    }
    $self->{"configfile"}=file($path => $file); #isa Path::Class::File
  }
  return $self->{"configfile"};
}

=head1 CONFIGURATION

=head2 File

I recommend building and installing an RPM from the included SPEC file which installs /etc/local.coorindates.

  rpmbuild -ta Geo-Local-Server-?.??.tar.gz

Outerwise copy the example etc/local.coorindates file to either /etc/ or C:\Windows\ and then update the coordinates to match your server location.

=head2 Environment

I recommend building and installing an RPM with the included SPEC file which installs /etc/profile.d/local.coordinates.sh which correctly sets the COORDINATES_WGS84_LON_LAT_HAE environment variable.

Otherwise you can export the COORDINATES_WGS84_LON_LAT_HAE variable or add it to your .bashrc file.

  export COORDINATES_WGS84_LON_LAT_HAE="-77.386706 38.780276 63"

=head2 Format

The /etc/local.coordinates file is an INI file. The [wgs84] section is required for this package to function.

  [main]
  version=1

  [wgs84]
  latitude=38.780276
  longitude=-77.386706
  hae=63

=head1 OBJECT ACCESSORS

=head2 ci

Returns the L<Config::IniFiles> object so that you can read additional information from the INI file.

  my $config=$gls->ci; #isa Config::IniFiles

Example

  my $version=$gls->ci->val("main", "version");

=cut

sub ci {
  my $self=shift;
  my $file=$self->configfile; #support for objects that can stringify paths.
  $self->{'ci'}=Config::IniFiles->new(-file=>"$file")
    unless ref($self->{'ci'}) eq "Config::IniFiles";
  return $self->{'ci'};
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<DateTime::Event::Sunrise>, L<Power::Outlet>, L<Geo::Point>, L<URL::geo>

=cut

1;
