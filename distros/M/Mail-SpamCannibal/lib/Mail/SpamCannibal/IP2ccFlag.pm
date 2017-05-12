#!/usr/bin/perl
package Mail::SpamCannibal::IP2ccFlag;
#
use strict;
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Mail::SpamCannibal::IP2ccFlag - by IP, get Country Code & flag.gif

=head1 SYNOPSIS

  use Mail::SpamCannibal::IP2ccFlag;

  ($cc,$flag_file,$ctry_name)=&Mail::SpamCannibal::IP2ccFlag::get($ipaddy,$flag_path);

=head1 DESCRIPTION get

This function fetches the 2 character Country Code, the relative pathname
for the country flag.gif, and the country name. The function returns an empty array if the country
can not be determined or if the dependent modules are not present or the
flags directory is not present. 

The flags directory must be writable by the caller if you plan to allow
Geo::CountryFlags to automatically fetch flags on demand (normal mode).

* ($cc,$flag_file,$ctry_name)=get($ipaddy,$flag_path);

  input:	IPv4 dot quad address,
		[optional] flag directory
  returns:	CC, path2flagfile.gif, countryname
	    or	()

The default flag directory is "./flags"

This function will retrieve a copy of the requested flag gif from the CIA
web site if it is not present in the "flags" directory.

=cut

sub get {
  my($ip,$fp) = @_;
  $fp = './flags' unless $fp;
  return () unless -d $fp;
  return () unless $ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;
  $ip = $&;
  eval {
	require Geo::IP::PurePerl;
	require Geo::CountryFlags;
  };
  return () if $@;	# punt if errors

  (my $cc = Geo::IP::PurePerl->new()->country_code_by_addr($ip))
	or return ();
  (my $flag = Geo::CountryFlags->new()->get_flag($cc,$fp))
	or return ();
  my $ctry = '';
  if (eval {require Geo::CountryFlags::ISO}) {
    $ctry = Geo::CountryFlags::ISO::value($cc) || '';
  }
  return ($cc,$flag,$ctry);
}

=head1 DEPENDENCIES

  Geo::IP::PurePerl
  Geo::CountryFlags
  GeoIP.dat

=head1 EXPORT

  none

=head1 COPYRIGHT

Copyright 2003 - 2008, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

L<Geo::IP::PurePerl>, L<Geo::CountryFlags>,
http://www.maxmind.com/download/geoip/database/

=cut

1;
