# $Id: handshake.t 501 2014-05-14 22:19:48Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.2 );

use t::TestSuite qw| :temp :mthd |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan !defined $Apt_Lib                        ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 7 );

my $arena = FAFTS_tempdir nick => q|arena|;
my $stderr = FAFTS_tempfile nick => q|stderr|, dir => $arena;

my( $rv, $serr );
unless( !$ENV{FAFTS_NO_LIB} && $Apt_Lib)                              {
    t::TestSuite::FAFTS_diag q|missing APT: workarounds enabled|;
    my $cfg = FAFTS_tempfile nick => q|config|, dir => $arena;
    FAFTS_prepare_method
        $cfg, q|y-method|, $stderr, qq|Dir::Bin::methods "$arena";|;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]) }

$rv = File::AptFetch->init;
like $rv, qr{^\(\$method\) is unspecified$}sm,
  q|F::AF->init fails with empty CL|;

File::AptFetch::ConfigData->set_config( lib_method => q|/dev/null| );
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( q|void| ) };
like $rv, qr{^\Q(void): (\E\d+\): died without handshake}sm,
  q|F::AF->init fails with broken I<lib_method>|;

File::AptFetch::ConfigData->set_config(lib_method => $arena );
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( q|void| ) };
like $rv, qr{^\Q(void): (\E\d+\): died without handshake}sm,
  q|F::AF->init fails with empty I<lib_method>|;

my $method =
( split m{/}, FAFTS_tempfile nick => q|mtag163b|, dir => $arena )[-1];
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
like $rv, qr{^\Q($method): (\E\d+\): died without handshake}sm,
  q|F::AF->init fails with unexecutable method|;

$method = FAFTS_tempfile nick => q|mtag6d9d|, dir => $arena;
chmod 0755, $method;
$method = ( split m{/}, $method )[-1];
$rv = FAFTS_wrap { File::AptFetch->init( $method ) };
like $rv, qr{^\Q($method): (0): died without handshake}sm,
  q|F::AF->init fails with empty executable|;

FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag798e|, dir => $arena ),
  q|x-method|, $stderr, q|25|;
$method = ( split qr{/}, $method )[-1];
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
like $rv, qr{^\Q($method): (0): died without handshake}sm,
  q|F::AF->init fails with bogus executable|;

File::AptFetch::_uncache_configuration;
File::AptFetch::ConfigData->set_config( lib_method => undef );
$method = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagef40|, dir => $arena ),
  q|x-method|, $stderr, q|3|;
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
ok +File::AptFetch::ConfigData->config( q|lib_method| ),
  q|F::AF->init sets I<lib_method>|;

# vim: syntax=perl
