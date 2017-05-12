# $Id: EmMn8o.t 497 2014-03-17 23:44:36Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :file :diag |;
use File::AptFetch::ConfigData;
use Test::More;

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
unless( defined $Apt_Lib ) {  plan skip_all => q|not *nix, or misconfigured| }
elsif( !$Apt_Lib )         {       plan  skip_all => q|not Debian, or alike| }

my $sout = FAFTS_tempfile nick => q|ftag4c83|;
my $serr = FAFTS_tempfile nick => q|ftage10e|;
my $unit = FAFTS_tempfile nick => q|ftag93df|, content => <<'END_OF_UNIT';
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

sub just_do_it                                                  {
    ( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) }}

( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( q|copy| ) };
ok 1, q|tag+e19c|;
# XXX:201403151450:whynot: See F<t/copy/slow.t> how it works.

END_OF_UNIT

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
if( $check == $pid && $cerr == 0xff00 && $serr =~ m{ 2 tests but ran 1\.} ) {
    plan tests => 1; ok 1, qq|($^V) is|                                      }
else                                                                        {
    plan skip_all =>
      sprintf q|(%vd): %s # %x|, $^V, ( split m{\n}, $serr )[0], $cerr       }

# vim: syntax=perl
