# $Id: 0.t 496 2014-02-26 17:39:18Z whynot $
# Copyright 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.3 );

use t::TestSuite qw| :temp :mthd :diag |;
use Test::More;
use File::AptFetch;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan !defined $Apt_Lib                        ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 3 );

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $arena = FAFTS_tempdir nick => q|dtag0403|;
my $stderr = FAFTS_tempfile nick => q|ftag084a|, dir => $arena;
my $fake_method = FAFTS_tempfile nick => q|mtagd6c8|, dir => $arena;
chmod 0755, $fake_method                                       or BAIL_OUT $!;
$fake_method = FAFTS_prepare_method $fake_method, q|w-method|, $stderr;

my $config_source = File::AptFetch::ConfigData->config( q|config_source| );
my $src_serr = FAFTS_tempfile nick => q|ftage75e|, dir => $arena;
my $fake_source = FAFTS_tempfile nick => q|ftagf2b7|, dir => $arena;
FAFTS_prepare_method $fake_source, q|y-method|, $src_serr, 
  qq|Dir::Bin::methods "$arena";|;
File::AptFetch::ConfigData->set_config( config_source => [ $fake_source ]);

my $rc  = File::AptFetch->init( $fake_method );
isa_ok $rc, q|File::AptFetch|                                 or BAIL_OUT $rc;
undef $rc;

my @fails;
while( -1 != ( my $pid = wait )) {                         push @fails, $pid }
FAFTS_diag join ' ', map qq|[$_]|, @fails                           if @fails;
ok !@fails, @fails . q| zombies found|                 or BAIL_OUT q|zombies|;

my $serr = t::TestSuite::FAFTS_get_file $stderr;
is $serr, qq|{{{TERM}}}\n|, qq|{STDERR} isn't empty|                        or
  BAIL_OUT q|no {STDERR}|;
unless( -t STDOUT || -f q|Changes.pod| )  {
    $serr = [ split m{\n}, $serr ];
    print STDERR qq|# $_\n| foreach @$serr }

# vim: syntax=perl
