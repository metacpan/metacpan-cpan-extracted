# $Id: 9raCtd.t 497 2014-03-17 23:44:36Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :file :diag :mthd |;
use File::AptFetch::ConfigData;
use Test::More;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
unless( defined $Apt_Lib ) {  plan skip_all => q|not *nix, or misconfigured| }

my $mlib = FAFTS_tempdir nick => q|dtagfb09|;
my $src_serr = FAFTS_tempfile nick => q|ftagab8c|, dir => $mlib;
my $src  = FAFTS_tempfile nick => q|ftag3e99|, dir => $mlib;
FAFTS_prepare_method $src, q|y-method|, $src_serr,
  qq|Dir::Bin::methods "$mlib";|;
my $mthd_serr = FAFTS_tempfile nick => q|ftag5662|, dir => $mlib;
my $mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|ftag79c4|, dir => $mlib ),
  q|w-method|, $mthd_serr;

my $sout = FAFTS_tempfile nick => q|ftag97cf|;
my $serr = FAFTS_tempfile nick => q|ftag59a6|;
my $unit = FAFTS_tempfile
  nick => q|tag+fa79|, content => <<'END_OF_UNIT' . <<"END_OF_DATA";
use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :mthd |;
use File::AptFetch;
use Test::More;

END { print STDERR qq|# {CHILD_ERROR}: ($?)\n| }

my( $fsrc, $ftrg );
my( $faf, $rv, $serr );

plan tests => 2;

my $source = <DATA>; chomp $source;
my $method = <DATA>; chomp $method;

File::AptFetch::ConfigData->set_config( config_source => [ $source ] );

sub just_do_it                                                  {
    ( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) }}

( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
ok 1, q|tag+8a9f|;
# XXX:201403151450:whynot: See F<t/copy/slow.t> how it works.

__DATA__
END_OF_UNIT
$src
$mthd
END_OF_DATA

defined( my $pid = fork )                               or die qq|[fork]: $!|;
unless( $pid )                                                   {
    open STDOUT, q|>|, $sout       or die qq|[open] (STDOUT): $!|;
    open STDERR, q|>|, $serr       or die qq|[open] (STDERR): $!|;
    open STDIN, q|<|, q|/dev/null| or die qq|[open] (STDERR): $!|;
    exec qw| /usr/bin/perl |, $unit or die qq|[exec] ($unit): $!| }

my $check = waitpid $pid, 0;
my $cerr = $?;

FAFTS_diag q|+++ STDERR +++|;
$serr = FAFTS_get_file $serr;
FAFTS_diag q|+++ STDOUT +++|;
$sout = FAFTS_get_file $sout;
FAFTS_diag q|+++ method STDERR +++|;
FAFTS_get_file $mthd_serr;
FAFTS_diag q|+++ source STDERR +++|;
FAFTS_get_file $src_serr;
if( $check == $pid && $cerr == 0xff00 && $serr =~ m{ 2 tests but ran 1\.} ) {
    plan tests => 1; ok 1, qq|($^V) is|                                      }
else                                                                        {
    plan skip_all =>
      sprintf q|(%vd): %s # %x|, $^V, ( split m{\n}, $serr )[0], $cerr       }

# vim: syntax=perl
