# $Id: fail.t 510 2014-08-11 13:26:00Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.5 );

use t::TestSuite qw| :mthd :temp |;
use File::AptFetch::Simple;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );
File::AptFetch::ConfigData->set_config( tick    =>  1 );
File::AptFetch::ConfigData->set_config( wink    => !1 );
File::AptFetch::ConfigData->set_config( beat    => !1 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                    ( tests => 10 );

my( $dir, $fsrc, $ftrg );
my( $fafs, $rv, $serr );

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( ) };
like $fafs, qr{either ..method. or .%options. is required}, q|no args|;
is $serr, '', q|tag+32da {STDERR} is empty|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( undef ) };
like $fafs, qr{either ..method. or .%options. is required},
  q|explicit (undef)|;
is $serr, '', q|tag+ea6e {STDERR} is empty|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request({ }) };
like $fafs, qr{..options.method.. is required}, q|no {$options{method}}|;
is $serr, '', q|tag+111b {STDERR} is empty|;

( $fafs, $serr ) = FAFTS_wrap                           {
  File::AptFetch::Simple->request([ method => q|copy| ]) };
like $fafs, qr{first must be either ..method. or .%options.}, q|ARRAY|;
is $serr, '', q|tag+002c {STDERR} is empty|;

$dir = FAFTS_tempdir nick => q|dtag4c14|;
$fsrc = FAFTS_tempfile
  nick => q|ftag2e98|, dir => $dir, content => q|tag+0fd5|, unlink => !0;
$ftrg = FAFTS_cat_fn q|.|, $fsrc;
( $fafs, $serr ) = FAFTS_wrap {
  File::AptFetch::Simple->request( copy => $fsrc ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|requesting missing|;
is_deeply
{ stderr => $serr,   status => $fafs->{Status},  log => $fafs->{log},
  mark => scalar keys %{$fafs->{trace}}, pending => $fafs->{pending},
                                                   file => !-f $ftrg },
{ stderr => '', status => 400, log => [ ],
  mark => 0,                 pending => undef,
                               file => !0     }, q|missing is missing|;

# vim: syntax=perl
