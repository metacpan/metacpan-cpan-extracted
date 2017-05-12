# $Id: fail.t 501 2014-05-14 22:19:48Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :mthd :file :diag |;
use File::AptFetch;
use Test::More;

my( $arena, $stderr, $fsrc, $ftrg, $mthd );
my( $faf, $rv, $serr );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 22 );

$arena = FAFTS_tempdir nick => q|dtag843c|;
File::AptFetch::ConfigData->set_config( lib_method => $arena );

unless( !$ENV{FAFTS_NO_LIB} && $Apt_Lib )                             {
    t::TestSuite::FAFTS_diag q|missing APT: workarounds enabled|;
    my $cfg = FAFTS_tempfile nick => q|config|, dir => $arena;
    FAFTS_prepare_method $cfg, q|y-method|, q|/dev/null|,
      qq|Dir "$arena";|,
      qq|Dir::Etc "$arena";|,
      qq|Dir::Bin::methods "$arena";|,
      qq|APT::Architecture "archc355";|;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]) }

File::AptFetch::ConfigData->set_config( timeout => 25 );
File::AptFetch::ConfigData->set_config( tick    =>  5 );

$stderr = FAFTS_tempfile nick => q|stderr|;
$fsrc = FAFTS_tempfile nick => q|ftagd5da|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag7b36|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagb935|, dir => $arena ),
  q|v-method|,               $stderr,               10,
  q|200 URI Start|,   qq|Uri: +++$fsrc|,    q|Size: 0|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+459f [init]|;
is $serr, '', q|tag+7d9f {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply [ $rv, $serr ], [ '', '' ], q|tag+0225 [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{\Q(0): died}, q|[gain] timeouts -- no separator|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+66f6 {STDERR} is empty|;

$stderr = FAFTS_tempfile nick => q|stderr|;
$fsrc = FAFTS_tempfile nick => q|ftage705|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftagcf43|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag3976|, dir => $arena ),
  q|v-method|,               $stderr,               10,
  q|200 URI Start|, qq|Uri: +++$fsrc|,  q|Size: 0|, '';
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+443f [init]|;
is $serr, '', q|tag+d5b3 {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply [ $rv, $serr ], [ '', '' ], q|tag+3633 [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
is_deeply [ $rv, $serr, $faf->{Status} ], [ '', '', 200 ], q|tag+5675 [gain]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{\Q(0): died}, q|[gain] timeouts -- separator|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+439a {STDERR} is empty|;

$stderr = FAFTS_tempfile nick => q|stderr|;
$fsrc = FAFTS_tempfile nick => q|ftag1ca6|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag7689|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtage69f|, dir => $arena ),
  q|v-method|,           $stderr,            q|10:250|,
  q|200 URI Start|,    qq|Uri: +++$fsrc|,   q|Size: 0|;
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+de27 [init]|;
is $serr, '', q|tag+14cd {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply [ $rv, $serr ], [ '', '' ], q|tag+0a36 [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{\Q(64000): died}, q|[gain] timeouts -- no separator, dies|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+226f {STDERR} is empty|;

$stderr = FAFTS_tempfile nick => q|stderr|;
$fsrc = FAFTS_tempfile nick => q|ftagf67e|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag1c66|, dir => $arena;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagc948|, dir => $arena ),
  q|v-method|,           $stderr,            q|10:251|,
  q|200 URI Start|, qq|Uri: +++$fsrc|,  q|Size: 0|, '';
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|tag+1285 [init]|;
is $serr, '', q|tag+e3db {STDERR} is empty|;
( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply [ $rv, $serr ], [ '', '' ], q|tag+3b8a [request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
is_deeply [ $rv, $serr, $faf->{Status} ], [ '', '', 200 ], q|tag+1940 [gain]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{\Q(64256): died}, q|[gain] timeouts -- separator, dies|;
undef $faf;
like FAFTS_get_file $stderr, qr{600 URI Acquire},
  q|tag+b292 {STDERR} is empty|;

# vim: syntax=perl
