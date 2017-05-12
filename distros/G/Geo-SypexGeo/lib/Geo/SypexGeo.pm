package Geo::SypexGeo;

our $VERSION = '0.8';

use strict;
use warnings;
use utf8;
use v5.10;

use Carp qw( croak );
use Encode;
use Socket;
use POSIX;
use Text::Trim;
use Geo::SypexGeo::Info;

use fields qw(
  db_file b_idx_str m_idx_str range b_idx_len m_idx_len db_items id_len
  block_len max_region max_city db_begin regions_begin cities_begin
  max_country country_size pack
);

use constant {
  HEADER_LENGTH => 40,
};

my @COUNTRY_ISO_MAP = (
  '',   'ap', 'eu', 'ad', 'ae', 'af', 'ag', 'ai', 'al', 'am', 'cw', 'ao',
  'aq', 'ar', 'as', 'at', 'au', 'aw', 'az', 'ba', 'bb', 'bd', 'be', 'bf',
  'bg', 'bh', 'bi', 'bj', 'bm', 'bn', 'bo', 'br', 'bs', 'bt', 'bv', 'bw',
  'by', 'bz', 'ca', 'cc', 'cd', 'cf', 'cg', 'ch', 'ci', 'ck', 'cl', 'cm',
  'cn', 'co', 'cr', 'cu', 'cv', 'cx', 'cy', 'cz', 'de', 'dj', 'dk', 'dm',
  'do', 'dz', 'ec', 'ee', 'eg', 'eh', 'er', 'es', 'et', 'fi', 'fj', 'fk',
  'fm', 'fo', 'fr', 'sx', 'ga', 'gb', 'gd', 'ge', 'gf', 'gh', 'gi', 'gl',
  'gm', 'gn', 'gp', 'gq', 'gr', 'gs', 'gt', 'gu', 'gw', 'gy', 'hk', 'hm',
  'hn', 'hr', 'ht', 'hu', 'id', 'ie', 'il', 'in', 'io', 'iq', 'ir', 'is',
  'it', 'jm', 'jo', 'jp', 'ke', 'kg', 'kh', 'ki', 'km', 'kn', 'kp', 'kr',
  'kw', 'ky', 'kz', 'la', 'lb', 'lc', 'li', 'lk', 'lr', 'ls', 'lt', 'lu',
  'lv', 'ly', 'ma', 'mc', 'md', 'mg', 'mh', 'mk', 'ml', 'mm', 'mn', 'mo',
  'mp', 'mq', 'mr', 'ms', 'mt', 'mu', 'mv', 'mw', 'mx', 'my', 'mz', 'na',
  'nc', 'ne', 'nf', 'ng', 'ni', 'nl', 'no', 'np', 'nr', 'nu', 'nz', 'om',
  'pa', 'pe', 'pf', 'pg', 'ph', 'pk', 'pl', 'pm', 'pn', 'pr', 'ps', 'pt',
  'pw', 'py', 'qa', 're', 'ro', 'ru', 'rw', 'sa', 'sb', 'sc', 'sd', 'se',
  'sg', 'sh', 'si', 'sj', 'sk', 'sl', 'sm', 'sn', 'so', 'sr', 'st', 'sv',
  'sy', 'sz', 'tc', 'td', 'tf', 'tg', 'th', 'tj', 'tk', 'tm', 'tn', 'to',
  'tl', 'tr', 'tt', 'tv', 'tw', 'tz', 'ua', 'ug', 'um', 'us', 'uy', 'uz',
  'va', 'vc', 've', 'vg', 'vi', 'vn', 'vu', 'wf', 'ws', 'ye', 'yt', 'rs',
  'za', 'zm', 'me', 'zw', 'a1', 'xk', 'o1', 'ax', 'gg', 'im', 'je', 'bl',
  'mf', 'bq', 'ss'
);

sub new {
  my $class = shift;
  my $file  = shift;

  my $self = fields::new( $class );

  open( my $fl, $file ) || croak( 'Could not open db file' );
  binmode $fl, ':bytes';

  read $fl, my $header, HEADER_LENGTH;
  croak 'File format is wrong' if substr( $header, 0, 3 ) ne 'SxG';

  my $info_str = substr( $header, 3, HEADER_LENGTH - 3 );
  my @info = unpack 'CNCCCnnNCnnNNnNn', $info_str;
  croak 'File header format is wrong' if $info[4] * $info[5] * $info[6] * $info[7] * $info[1] * $info[8] == 0;

  if ( $info[15] ) {
    read $fl, my $pack, $info[15];
    $self->{pack} = [ split "\0", $pack ];
  }

  read $fl, $self->{b_idx_str}, $info[4] * 4;
  read $fl, $self->{m_idx_str}, $info[5] * 4;

  $self->{range}        = $info[6];
  $self->{b_idx_len}    = $info[4];
  $self->{m_idx_len}    = $info[5];
  $self->{db_items}     = $info[7];
  $self->{id_len}       = $info[8];
  $self->{block_len}    = 3 + $self->{id_len};
  $self->{max_region}   = $info[9];
  $self->{max_city}     = $info[10];
  $self->{max_country}  = $info[13];
  $self->{country_size} = $info[14];

  $self->{db_begin} = tell $fl;

  $self->{regions_begin} = $self->{db_begin} + $self->{db_items} * $self->{block_len};
  $self->{cities_begin}  = $self->{regions_begin} + $info[11];

  $self->{db_file} = $file;

  close $fl;

  return $self;
}

sub get_city {
  my __PACKAGE__ $self = shift;
  my $ip               = shift;
  my $lang             = shift;

  my $seek = $self->get_num($ip);
  return unless $seek;

  my $info = $self->parse_info( $seek, $lang );
  return unless $info;

  my $city;
  if ( $lang && $lang eq 'en' ) {
    $city = $info->[6];
  }
  else {
    $city = $info->[5];
  }
  return unless $city;

  return decode_utf8($city);
}

sub get_country {
  my __PACKAGE__ $self = shift;
  my $ip = shift;

  my $seek = $self->get_num($ip);
  return unless $seek;

  my $info = $self->parse_info($seek);
  return unless $info;

  my $country;
  if ( $info->[1] =~ /\D/ ) {
    $country = $info->[1];
  }
  else {
    $country = $COUNTRY_ISO_MAP[ $info->[1] ];
  }

  return $country;
}

sub parse {
  my __PACKAGE__ $self = shift;
  my $ip = shift;
  my $lang = shift;
  my $seek = $self->get_num($ip);
  return unless $seek;

  my $info = $self->parse_info($seek, $lang);
  return Geo::SypexGeo::Info->new($info, $lang);
}

sub get_num {
  my __PACKAGE__ $self = shift;
  my $ip = shift;

  my $ip1n;
  {
    no warnings;
    $ip1n = int $ip;
  }

  return undef if !$ip1n || $ip1n == 10 || $ip1n == 127 || $ip1n >= $self->{b_idx_len};
  my $ipn = ip2long( $ip );
  $ipn = pack( 'N', $ipn );

  my @blocks = unpack "NN", substr( $self->{b_idx_str} , ( $ip1n - 1 ) * 4, 8 );

  my $min;
  my $max;

  if ( $blocks[1] - $blocks[0] > $self->{range} ) {
    my $part = $self->search_idx(
      $ipn,
      floor( $blocks[0] / $self->{'range'} ),
      floor( $blocks[1] / $self->{'range'} ) - 1
    );

    $min = $part > 0 ? $part * $self->{range} : 0;
    $max = $part > $self->{m_idx_len} ? $self->{db_items} : ( $part + 1 ) * $self->{range};

    $min = $blocks[0] if $min < $blocks[0];
    $max = $blocks[1] if $max > $blocks[1];
  }
  else {
    $min = $blocks[0];
    $max = $blocks[1];
  }

  my $len = $max - $min;

  open( my $fl, $self->{ 'db_file' } ) || croak( 'Could not open db file' );
  binmode $fl, ':bytes';
  seek $fl, $self->{db_begin} + $min * $self->{block_len}, 0;
  read $fl, my $buf, $len * $self->{block_len};
  close $fl;

  return $self->search_db( $buf, $ipn, 0, $len - 1 );
}

sub search_idx {
  my __PACKAGE__ $self = shift;
  my $ipn              = shift;
  my $min              = shift;
  my $max              = shift;

  my $offset;
  while ( $max - $min > 8 ) {
    $offset = ( $min + $max ) >> 1;

    if ( encode_utf8($ipn) gt encode_utf8( substr( ( $self->{m_idx_str} ), $offset * 4, 4 ) ) ) {
      $min = $offset;
    }
    else {
      $max = $offset;
    }
  }

  while ( encode_utf8($ipn) gt encode_utf8( substr( $self->{m_idx_str}, $min * 4, 4 ) ) && $min++ < $max ) {
  }

  return  $min;
}

sub search_db {
  my __PACKAGE__ $self = shift;
  my $str              = shift;
  my $ipn              = shift;
  my $min              = shift;
  my $max              = shift;

  if( $max - $min > 1 ) {
    $ipn = substr( $ipn, 1 );
    my $offset;
    while ( $max - $min > 8 ){
      $offset = ( $min + $max ) >> 1;

      if ( encode_utf8( $ipn ) gt encode_utf8( substr( $str, $offset * $self->{block_len}, 3 ) ) ) {
        $min = $offset;
      }
      else {
        $max = $offset;
      }
    }

    while ( encode_utf8( $ipn ) ge encode_utf8( substr( $str, $min * $self->{block_len}, 3 ) ) && $min++ < $max ){}
  }
  else {
    return hex( bin2hex( substr( $str, $min * $self->{block_len} + 3 , 3 ) ) );
  }

  return hex( bin2hex( substr( $str, $min * $self->{block_len} - $self->{id_len}, $self->{id_len} ) ) );
}

sub bin2hex {
  my $str = shift;

  my $res = '';
  for my $i ( 0 .. length( $str ) - 1 ) {
    $res .= sprintf( '%02s', sprintf( '%x', ord( substr( $str, $i, 1 ) ) ) );
  }

  return $res;
}

sub ip2long {
  return unpack( 'l*', pack( 'l*', unpack( 'N*', inet_aton( shift ) ) ) );
}

sub parse_info {
  my __PACKAGE__ $self = shift;
  my $seek = shift;

  my $info;

  if ( $seek < $self->{country_size} ) {
    open( my $fl, $self->{db_file} ) || croak('Could not open db file');
    binmode $fl, ':bytes';
    seek $fl, $seek + $self->{cities_begin}, 0;
    read $fl, my $buf, $self->{max_country};
    close $fl;

    $info = extended_unpack( $self->{pack}[0], $buf );
  }
  else {
    open( my $fl, $self->{db_file} ) || croak('Could not open db file');
    binmode $fl, ':bytes';
    seek $fl, $seek + $self->{cities_begin}, 0;
    read $fl, my $buf, $self->{max_city};
    close $fl;

    $info = extended_unpack( $self->{pack}[2], $buf );
  }

  if ($info) {
    return $info;
  }
  else {
    return;
  }
}

sub extended_unpack {
  my $flags = shift;
  my $val   = shift;

  my $pos = 0;
  my $result = [];

  my @flags_arr = split '/', $flags;

  foreach my $flag_str ( @flags_arr ) {
    my ( $type, $name ) = split ':', $flag_str;

    my $flag = substr $type, 0, 1;
    my $num  = substr $type, 1, 1;

    my $len;

    if ( $flag eq 't' ) {
    }
    elsif ( $flag eq 'T' ) {
      $len = 1;
    }
    elsif ( $flag eq 's' ) {
    }
    elsif ( $flag eq 'n' ) {
      $len = $num;
    }
    elsif ( $flag eq 'S' ) {
      $len = 2;
    }
    elsif ( $flag eq 'm' ) {
    }
    elsif ( $flag eq 'M' ) {
      $len = 3;
    }
    elsif ( $flag eq 'd' ) {
      $len = 8;
    }
    elsif ( $flag eq 'c' ) {
      $len = $num;
    }
    elsif ( $flag eq 'b' ) {
      $len = index( $val, "\0", $pos ) - $pos;
    }
    else {
      $len = 4;
    }

    my $subval = substr( $val, $pos, $len );

    my $res;

    if ( $flag eq 't' ) {
      $res = ( unpack 'c', $subval )[0];
    }
    elsif ( $flag eq 'T' ) {
      $res = ( unpack 'C', $subval )[0];
    }
    elsif ( $flag eq 's' ) {
      $res = ( unpack 's', $subval )[0];
    }
    elsif ( $flag eq 'S' ) {
      $res = ( unpack 'S', $subval )[0];
    }
    elsif ( $flag eq 'm' ) {
      $res = ( unpack 'l', $subval . ( ord( substr( $subval, 2, 1 ) ) >> 7 ? "\xff" : "\0" ) )[0];
    }
    elsif ( $flag eq 'M' ) {
      $res = ( unpack 'L', $subval . "\0" )[0];
    }
    elsif ( $flag eq 'i' ) {
      $res = ( unpack 'l', $subval )[0];
    }
    elsif ( $flag eq 'I' ) {
      $res = ( unpack 'L', $subval )[0];
    }
    elsif ( $flag eq 'f' ) {
      $res = ( unpack 'f', $subval )[0];
    }
    elsif ( $flag eq 'd' ) {
      $res = ( unpack 'd', $subval )[0];
    }
    elsif ( $flag eq 'n' ) {
      $res = ( unpack 's', $subval )[0] / ( 10 ** $num );
    }
    elsif ( $flag eq 'N' ) {
      $res = ( unpack 'l', $subval )[0] / ( 10 ** $num );
    }
    elsif ( $flag eq 'c' ) {
      $res = rtrim $subval;
    }
    elsif ( $flag eq 'b' ) {
      $res = $subval;
      $len++;
    }

    $pos += $len;

    push @$result, $res;
  }

  return $result;
}

1;

=head1 NAME

Geo::SypexGeo - API to detect cities by IP thru Sypex Geo database v.2

=head1 SYNOPSIS

  use Geo::SypexGeo;
  my $geo = Geo::SypexGeo->new( './SxGeoCity.dat' );

  # Method parse return Geo::SypexGeo::Info object
  $info = $geo->parse( '87.250.250.203', 'en' )
    or die "Cant parse 87.250.250.203";
  say $info->city();

  $info = $geo->parse('93.191.14.81') or die "Cant parse 93.191.14.81";
  say $info->city();
  say $info->country();

  my ( $latitude, $longitude ) = $info->coordinates();
  say "Latitude: $latitude Longitude: $longitude";

  ## deprecated method (will be removed in future versions)
  say $geo->get_city( '87.250.250.203', 'en' );

  ## deprecated method (will be removed in future versions)
  say $geo->get_city('93.191.14.81');

  ## deprecated method (will be removed in future versions)
  say $geo->get_country('93.191.14.81');

=head1 DESCRIPTION

L<Sypex Geo|http://sypexgeo.net/> is a database to detect cities by IP.

The database of IPs is included into distribution, but it is better to download latest version at L<download page|http://sypexgeo.net/ru/download/>.

The database is availible with a names of the cities in Russian and English languages.

This module now is detect only city name and don't use any features to speed up of detection. In the future I plan to add more functionality.

=head1 SOURCE AVAILABILITY

The source code for this module is available from Github
at https://github.com/kak-tus/Geo-SypexGeo

=head1 AUTHOR

Andrey Kuzmin, E<lt>kak-tus@mail.ruE<gt>

=head1 CREDITS

vrag86
dimonchik-com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Andrey Kuzmin

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
