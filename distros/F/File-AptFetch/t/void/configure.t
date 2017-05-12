# $Id: configure.t 526 2017-04-15 01:52:05Z sync $
# Copyright 2009, 2010, 2014, 2017 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.1.2|;

use t::TestSuite qw| :temp :mthd :file |;
use Test::More;
use File::AptFetch;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan !defined $Apt_Lib                        ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 34 );

my $arena = FAFTS_tempdir nick => q|arena|;
File::AptFetch::ConfigData->set_config( lib_method => $arena );
my $stderr = FAFTS_tempfile nick => q|stderr|, dir => $arena;

my( $method, $rv, $serr );

unless( !$ENV{FAFTS_NO_LIB} && $Apt_Lib)                              {
    t::TestSuite::FAFTS_diag q|missing APT: workarounds enabled|;
    my $cfg = FAFTS_tempfile nick => q|config|, dir => $arena;
    FAFTS_prepare_method $cfg, q|y-method|, $stderr,
      qq|Dir "$arena";|,
      qq|Dir::Etc "$arena";|,
      qq|Dir::Bin::methods "$arena";|,
      qq|APT::Architecture "foobar";|;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]) }

$method = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag1e90|, dir => $arena ),
  q|x-method|, $stderr, 5;
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
ok !$serr, q|tag+e11f {STDERR} is empty|;
$rv = FAFTS_get_file $stderr;
ok
# XXX:201704150447:whynot: Praise cpan-testers!
# http://www.cpantesters.org/cpan/report/72b48a54-1722-11e7-b6a2-8616650bbeca
  $rv =~ m(^\{Config-Item: Dir=\S+\}$)m      &&
  $rv =~ m(^\{Config-Item: Dir::Etc=\S+\}$)m &&
  $rv =~ m(^\{Config-Item: APT::Architecture=\S+\}$)m,
  q|F::AF->init feeds a method with APT's configuration|;

my %samples =
( tag2f90 => [ q|greeting|,                      q|abc xyz|,   q|| ],
  tag35a6 => [ q|greeting|,                      q|1000 xyz|,  q|| ],
  tag7e5d => [ q|greeting|,                      q|10 xyz|,    q|| ],
  tag5171 => [ q|greeting|,                      q|!@#$ xyz|,  q|| ],
  tagc72c => [ q|greeting|,                      q|$self xyz|, q|| ],
  tage55c => [ q|message|, q|100 Capabilities|, q|: xyz|,      q|| ],
  tage74b => [ q|message|, q|100 Capabilities|, q| : xyz|,     q|| ],
  tagb63e => [ q|message|, q|100 Capabilities|, q|!@#$: xyz|,  q|| ],
  tagbf69 => [ q|message|, q|100 Capabilities|, q|$self: xyz|, q|| ],
  tag1824 => [ q|message|, q|100 Capabilities|, q| abc: xyz|,  q|| ],
  tag3f06 => [ q|message|, q|100 Capabilities|, q|abc : xyz|,  q|| ],
  tagc6e3 => [ q|message|, q|100 Capabilities|, q|abc:: xyz|,  q|| ],
  tag2671 => [ q|message|, q|100 Capabilities|, q|abc xyz|,    q|| ],
  tag67c5 => [ q|message|, q|100 Capabilities|, q|abc:|,       q|| ],
  tagc936 => [ q|message|, q|100 Capabilities|, q|abc: |,      q|| ],
  tag35dd => [ q|message|, q|100 Capabilities|, q|abc:  |,     q|| ] );

while( my( $tag, $sample ) = each %samples )            {
    my $turn = shift @$sample;
    $method = FAFTS_prepare_method
      FAFTS_tempfile( nick => qq|m$tag|, dir => $arena ),
      q|z-method|, $stderr, @$sample;
    ( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
    ok !$serr, qq|$tag {STDERR} is empty|;
    if( $turn eq q|greeting|   )                       {
        like $rv,
          qr{^\Q($method): ($sample->[0]): that's not a Status Code\E$},
          qq|$tag F::AF->init fails at broken greeting| }
    elsif( $turn eq q|message| )                       {
        like $rv,
          qr{^\Q($method): ($sample->[1]): that's not a Message\E$},
          qq|$tag F::AF->init fails at broken message|  }
    else                                               {
                                      die qq|$tag fsck| }};

# vim: syntax=perl
