# $Id: aptconfig.t 491 2014-01-31 22:59:49Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.1.2|;

use t::TestSuite qw| :temp :mthd |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan !defined $Apt_Lib                        ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 31 );

my $arena = FAFTS_tempdir nick => q|arena|;
my $stderr = FAFTS_tempfile nick => q|stderr|, dir => $arena;

my( $cfg, $rv, $serr );

File::AptFetch::ConfigData->set_config( config_source => [ qw| /dev/null | ]);
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( q|void| ) };
like $rv, qr{^\Q(void): (apt-config) died: (\E\d+\)}sm,
  q|F::AF->init fails with broken {config_source}|;

$cfg = FAFTS_tempfile nick => q|ctag6205|, dir => $arena;
FAFTS_prepare_method $cfg, q|x-method|, $stderr, 1;
File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]);
$rv = FAFTS_wrap { File::AptFetch->init( q|void| ) };
like $rv, qr{^\Q(void): (apt-config): failed to output anything}sm,
  q|F::AF->init fails with empty {config_source}|;

$cfg = FAFTS_tempfile nick => q|ctag10fb|, dir => $arena;
FAFTS_prepare_method $cfg, q|x-method|, $stderr, 25;
File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]);
$rv = FAFTS_wrap { File::AptFetch->init( q|void| ) };
SKIP:                                               {
    skip q|unable to test due local restrictions(?)|, 1                     if
      $rv =~ m{interrupted system call}i;
    like $rv, qr{^\Q(void): (apt-config): timeouted}sm,
      q|F::AF->init fails with slow {config_source}| }

File::AptFetch::ConfigData->set_config( lib_method => undef );

my %samples =
( tageafc => q|!@#$ "xyz";|,                     tag0e6c => q|$self|,
  tagbcd2 => q|ABC|,     tagad60 => q|ABC |,    tag71b6 => q|ABC ";|,
  tag4498 => q|ABC ;|, tag1c53 => q|ABC ""|, tag6896 => q|ABC"xyz";|,
  tag7bb2 => q|ABC "xyz"|,                   tagd54f => q|ABC "xyz;|,
  tag651b => q|ABC "xyz"abc;|,             tag6d9b => q|ABC "xyz" ;|,
  tag5278 => q|ABC """;|,               tag4418 => q|ABC "uvw"xyz";|,
  tag1c68 => q|ABC: "xyz";|,             tag6a26 => q|ABC::: "xyz";|,
  tagf010 => q|ABC::::: "xyz";|,           tag339d => q| ABC "xyz";|,
  tag8db1 => q|ABC::!@#$ "xyz";|,     tagcab5 => q|ABC ::def "xyz";|,
  tagbeb7 => q|ABC:: def "xyz";|,       tagb82e => q|ABC:def "xyz";|,
  tag453d => q|ABC:::def "xyz";|,   tag5f8f => q|ABC:::::def "xyz";|,
  tag0aea => q|ABC::def: "xyz";|,   tag3ecb => q|ABC::def::: "xyz";|,
                                  tag552e => q|ABC::def::::: "xyz";| );
while( my( $tag, $sample ) = each %samples )           {
    $cfg = FAFTS_tempfile nick => qq|c$tag|, dir => $arena;
    FAFTS_prepare_method $cfg, q|y-method|, $stderr, $sample;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]);
    ( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( q|void| ) };
    like $rv, qr{^\Q(void): ($sample): that's unparsable}sm,
      qq|F::AF->init fails with broken entry ($tag)| }

# FIXME: Unorthogonal.
$cfg = FAFTS_tempfile nick => q|ctagf21a|, dir => $arena;
FAFTS_prepare_method $cfg, q|y-method|, $stderr,
  q|ABC "";|,                                             q|DEF "xyz";|,
  q|ABC::def "";|,       q|GHI::jkl "xyz";|,       q|MNO::::pqr "xyz";|,
  q|ABC::def:: "";|,    q|GHI::jkl:: "xyz";|,    q|MNO::::pqr:: "xyz";|,
  q|ABC::def:::: "";|, q|GHI::jkl:::: "xyz";|, q|MNO::::pqr:::: "xyz";|,
  q|PQR "abc xyz";|,                             q|PQR::stu "abc xyz";|,
  q|ABC "\\";|,  q|ABC "abc\\";|,  q|ABC "\\abc";|,  q|ABC "abc\\xyz";|;
File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]);
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( q|void| ) };
like $rv, qr{^\(void\): \(\$lib_method\): neither preset nor found}sm,
  q|F::AF->init fails with missing I<lib_method>|;

# vim: syntax=perl
