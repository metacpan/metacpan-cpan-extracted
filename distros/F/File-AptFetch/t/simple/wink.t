# $Id: wink.t 506 2014-07-04 18:07:33Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.2 );

use t::TestSuite qw| :mthd :temp |;
use File::AptFetch::Simple;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );
File::AptFetch::ConfigData->set_config( wink    => !0 );
File::AptFetch::ConfigData->set_config( beat    => !1 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                     ( tests => 4 );

my( $dsrc, $dtrg, $fsrc );
my( $fafs, $serr );

$dsrc = FAFTS_tempdir nick => q|dtag0f74|;
$dtrg = FAFTS_tempdir nick => q|dtagb62a|;

$fsrc = FAFTS_tempfile
  nick => q|ftagdd5f|, dir => $dsrc, content => q|tag+875b|;
( $fafs, $serr ) = FAFTS_wrap                      {
  File::AptFetch::Simple->request(
  { method => q|copy|, location => $dtrg }, $fsrc ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|[init]|;
# http://www.cpantesters.org/cpan/report/ab66a7d6-f288-11e3-a9ed-95bae0bfc7aa
# TODO:201407031530:whynot: C<qr/\V/> is of v5.10.
my $vh = qr{[^\f\r\n]};
like $serr, qr{(?m)^$vh+_ftagdd5f_$vh+\(URI Start\)$vh*$}, q|URI Start|;
like $serr, qr{(?m)^$vh+_ftagdd5f_$vh+\(URI Done\)$vh*$}, q|URI Done|;

$fsrc = FAFTS_tempfile
  nick => q|ftagd316|, dir => $dsrc, content => q|tag+65bd|;
$serr = ( FAFTS_wrap { $fafs->request({ wink => !1 }, $fsrc ) } )[1];
is $serr, '', q|no wink|;

# vim: syntax=perl
