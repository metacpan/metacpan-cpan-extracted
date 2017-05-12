#!/usr/bin/perl
package Geo::CountryFlags::I2C;

################################################################
# WARNING! this module is automatically generated DO NOT EDIT! #
#            see Geo::CountryFlags::Util instead               #
#                                                              #
# creation date:  Sat Sep 16 07:05:44 2006 GMT	               #
################################################################

use strict;
use vars qw($VERSION);
$VERSION = '2006258.002';

my $I2C = {
    'AD' => q|an|,
    'AE' => q|ae|,
    'AF' => q|af|,
    'AG' => q|ac|,
    'AI' => q|av|,
    'AL' => q|al|,
    'AM' => q|am|,
    'AN' => q|nt|,
    'AO' => q|ao|,
    'AQ' => q|ay|,
    'AR' => q|ar|,
    'AS' => q|aq|,
    'AT' => q|au|,
    'AU' => q|as|,
    'AW' => q|aa|,
    'AZ' => q|aj|,
    'BA' => q|bk|,
    'BB' => q|bb|,
    'BD' => q|bg|,
    'BE' => q|be|,
    'BF' => q|uv|,
    'BG' => q|bu|,
    'BH' => q|ba|,
    'BI' => q|by|,
    'BJ' => q|bn|,
    'BM' => q|bd|,
    'BN' => q|bx|,
    'BO' => q|bl|,
    'BR' => q|br|,
    'BS' => q|bf|,
    'BT' => q|bt|,
    'BV' => q|bv|,
    'BW' => q|bc|,
    'BY' => q|bo|,
    'BZ' => q|bh|,
    'CA' => q|ca|,
    'CC' => q|ck|,
    'CD' => q|cg|,
    'CF' => q|ct|,
    'CG' => q|cf|,
    'CH' => q|sz|,
    'CI' => q|iv|,
    'CK' => q|cw|,
    'CL' => q|ci|,
    'CM' => q|cm|,
    'CN' => q|ch|,
    'CO' => q|co|,
    'CR' => q|cs|,
    'CS' => q|rb|,
    'CU' => q|cu|,
    'CV' => q|cv|,
    'CX' => q|kt|,
    'CY' => q|cy|,
    'CZ' => q|ez|,
    'DE' => q|gm|,
    'DJ' => q|dj|,
    'DK' => q|da|,
    'DM' => q|do|,
    'DO' => q|dr|,
    'DZ' => q|ag|,
    'EC' => q|ec|,
    'EE' => q|en|,
    'EG' => q|eg|,
    'EH' => q|wi|,
    'ER' => q|er|,
    'ES' => q|sp|,
    'ET' => q|et|,
    'FI' => q|fi|,
    'FJ' => q|fj|,
    'FK' => q|fk|,
    'FM' => q|fm|,
    'FO' => q|fo|,
    'FR' => q|fr|,
    'GA' => q|gb|,
    'GB' => q|uk|,
    'GD' => q|gj|,
    'GE' => q|gg|,
    'GF' => q|fg|,
    'GG' => q|gk|,
    'GH' => q|gh|,
    'GI' => q|gi|,
    'GL' => q|gl|,
    'GM' => q|ga|,
    'GN' => q|gv|,
    'GP' => q|gp|,
    'GQ' => q|ek|,
    'GR' => q|gr|,
    'GS' => q|sx|,
    'GT' => q|gt|,
    'GU' => q|gq|,
    'GW' => q|pu|,
    'GY' => q|gy|,
    'HK' => q|hk|,
    'HM' => q|hm|,
    'HN' => q|ho|,
    'HR' => q|hr|,
    'HT' => q|ha|,
    'HU' => q|hu|,
    'ID' => q|id|,
    'IE' => q|ei|,
    'IL' => q|is|,
    'IM' => q|im|,
    'IN' => q|in|,
    'IO' => q|io|,
    'IQ' => q|iz|,
    'IR' => q|ir|,
    'IS' => q|ic|,
    'IT' => q|it|,
    'JE' => q|je|,
    'JM' => q|jm|,
    'JO' => q|jo|,
    'JP' => q|ja|,
    'KE' => q|ke|,
    'KG' => q|kg|,
    'KH' => q|cb|,
    'KI' => q|kr|,
    'KM' => q|cn|,
    'KN' => q|sc|,
    'KP' => q|kn|,
    'KR' => q|ks|,
    'KW' => q|ku|,
    'KY' => q|cj|,
    'KZ' => q|kz|,
    'LA' => q|la|,
    'LB' => q|le|,
    'LC' => q|st|,
    'LI' => q|ls|,
    'LK' => q|ce|,
    'LR' => q|li|,
    'LS' => q|lt|,
    'LT' => q|lh|,
    'LU' => q|lu|,
    'LV' => q|lg|,
    'LY' => q|ly|,
    'MA' => q|mo|,
    'MC' => q|mn|,
    'MD' => q|md|,
    'MG' => q|ma|,
    'MH' => q|rm|,
    'MK' => q|mk|,
    'ML' => q|ml|,
    'MM' => q|bm|,
    'MN' => q|mg|,
    'MO' => q|mc|,
    'MP' => q|cq|,
    'MQ' => q|mb|,
    'MR' => q|mr|,
    'MS' => q|mh|,
    'MT' => q|mt|,
    'MU' => q|mp|,
    'MV' => q|mv|,
    'MW' => q|mi|,
    'MX' => q|mx|,
    'MY' => q|my|,
    'MZ' => q|mz|,
    'NA' => q|wa|,
    'NC' => q|nc|,
    'NE' => q|ng|,
    'NF' => q|nf|,
    'NG' => q|ni|,
    'NI' => q|nu|,
    'NL' => q|nl|,
    'NO' => q|no|,
    'NP' => q|np|,
    'NR' => q|nr|,
    'NU' => q|ne|,
    'NZ' => q|nz|,
    'OM' => q|mu|,
    'PA' => q|pm|,
    'PE' => q|pe|,
    'PF' => q|fp|,
    'PG' => q|pp|,
    'PH' => q|rp|,
    'PK' => q|pk|,
    'PL' => q|pl|,
    'PM' => q|sb|,
    'PN' => q|pc|,
    'PR' => q|rq|,
    'PS' => q|we|,
    'PT' => q|po|,
    'PW' => q|ps|,
    'PY' => q|pa|,
    'QA' => q|qa|,
    'RE' => q|re|,
    'RO' => q|ro|,
    'RU' => q|rs|,
    'RW' => q|rw|,
    'SA' => q|sa|,
    'SB' => q|bp|,
    'SC' => q|se|,
    'SD' => q|su|,
    'SE' => q|sw|,
    'SG' => q|sn|,
    'SH' => q|sh|,
    'SI' => q|si|,
    'SJ' => q|sv|,
    'SK' => q|lo|,
    'SL' => q|sl|,
    'SM' => q|sm|,
    'SN' => q|sg|,
    'SO' => q|so|,
    'SR' => q|ns|,
    'ST' => q|tp|,
    'SV' => q|es|,
    'SY' => q|sy|,
    'SZ' => q|wz|,
    'TC' => q|tk|,
    'TD' => q|cd|,
    'TF' => q|fs|,
    'TG' => q|to|,
    'TH' => q|th|,
    'TJ' => q|ti|,
    'TK' => q|tl|,
    'TL' => q|tt|,
    'TM' => q|tx|,
    'TN' => q|ts|,
    'TO' => q|tn|,
    'TR' => q|tu|,
    'TT' => q|td|,
    'TV' => q|tv|,
    'TW' => q|tw|,
    'TZ' => q|tz|,
    'UA' => q|up|,
    'UG' => q|ug|,
    'UM' => q|um|,
    'US' => q|us|,
    'UY' => q|uy|,
    'UZ' => q|uz|,
    'VA' => q|vt|,
    'VC' => q|vc|,
    'VE' => q|ve|,
    'VG' => q|vi|,
    'VI' => q|vq|,
    'VN' => q|vm|,
    'VU' => q|nh|,
    'WF' => q|wf|,
    'WS' => q|ws|,
    'YE' => q|ym|,
    'YT' => q|mf|,
    'ZA' => q|sf|,
    'ZM' => q|za|,
    'ZW' => q|zi|,
};

sub AUTOLOAD {
  no strict;
  $AUTOLOAD =~ /[^:]+$/;
  value($&);
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $self = {};
  bless $self, $class;
}

sub hashptr {
  my($proto,$class) = @_;
  $proto = $class if $class;
  $class = ref $proto || $proto;
  my $rv = {};
  %$rv = %$I2C;
  bless $rv, $class;
}

sub value {
  return (exists $I2C->{$_[0]}) ? $I2C->{$_[0]} : undef;
}

sub subref {
  return \&value;
}

1;
__END__

=pod

Geo::CountryFlags::I2C is autogenerated by Makefile.PL

Last updated Sat Sep 16 07:05:44 2006 GMT

=head1 NAME

Geo::CountryFlags::I2C::I2C - hash to map values

=head1 SYNOPSIS

Geo::CountryFlags::I2C provides a variety of methods and functions to lookup values
either as hash-like constants (recommended) or directly from a hash array.

    require $Geo::CountryFlags::I2C;
    my $gci = new Geo::CountryFlags::I2C;
    $value = $gci->KEY;

  Perl 5.6 or greater can use syntax
    $value = $gci->$key;

  or
    $subref = subref Geo::CountryFlags::I2C;
    $value = $subref->($key);
    $value = &$subref($key);

  or
    $value = value Geo::CountryFlags::I2C($key);
    Geo::CountryFlags::I2C->value($key);

  to return a reference to the map directly

  $hashref = hashptr Geo::CountryFlags::I2C($class);
  $value = $hashref->{$key};

=head1 DESCRIPTION

Geo::CountryFlags::I2C maps I2C values.

Values may be returned directly by designating the KEY as a method or
subroutine of the form:

    $value = Geo::CountryFlags::I2C::KEY;
    $value = Geo::CountryFlags::I2C->KEY;
  or in Perl 5.6 and above
    $value = Geo::CountryFlags::I2C->$key;
  or
    $gci = new Geo::CountryFlags::I2C;
    $value = $gci->KEY;
  or in Perl 5.6 and above
    $value= =  $gci->$key;

=over 4

=item * $gci = new Geo::CountryFlags::I2C;

Return a reference to the modules in this package.

=item * $hashptr = hashptr Geo::CountryFlags::I2C($class);

Return a blessed reference to a copy of the hash in this package.

  input:	[optional] class or class ref
  returns:	a reference blessed into $class
		if $class is present otherwise
		blessed into Geo::CountryFlags::I2C

=item * $value = value Geo::CountryFlags::I2C($key);

=item * $value = $gci->value($key);

Return the value in the map hash or undef if it does not exist.

=item * $subref = subref Geo::CountryFlags::I2C;

=item * $subref = $gci->subref;

Return a subroutine reference that will return the value of a key or undef
if the key is not present.

  $value = $subref->($key);
  $value = &$subref($key);

=back

=head1 EXPORTs

Nothing

=head1 AUTHOR 

Michael Robinton michael@bizsystems.com

=head1 COPYRIGHT and LICENSE

  Copyright 2006 Michael Robinton, michael@bizsystems.com

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free Software 
Foundation; either version 1, or (at your option) any later version,

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of  
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 SEE ALSO

L<Geo::CountryFlags::Util>

=cut

1;
