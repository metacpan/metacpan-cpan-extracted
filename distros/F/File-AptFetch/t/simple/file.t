# $Id: file.t 510 2014-08-11 13:26:00Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.2 );

use t::TestSuite qw| :mthd :temp :file |;
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
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [file:]| ) :
                                                    ( tests => 19 );

use t::TestSuite qw| :temp :mthd :diag |;
use Test::More;

use File::AptFetch;
File::AptFetch::ConfigData->set_config( timeout => 10 );

my( $dira, $dirb, $dirc, $fsra, $fsrb, $ftga, $ftgb );
my( $fafs, $rv, $serr, $tmpl );

my @purg;
END { unlink @purg if @purg }

$dira = FAFTS_tempdir nick => q|dtag7b1a|;
$dirb = FAFTS_tempdir nick => q|dtagbb1b|;

sub give_got ( $ )                                                        {
    my $arg = shift;
    FAFTS_show_message %{$fafs->{message}};
    { stderr => $serr,  status => $fafs->{Status},   log => $fafs->{log},
      mark => scalar keys %{$fafs->{trace}}, pending => $fafs->{pending},
      $arg eq q|tag+12d0| ?
      ( md5sum => $fafs->{message}{md5_hash},
        rv     =>                    qq|$rv|,
        file   =>                  !-f $ftga                    ) :
      $arg eq q|tag+c43d| ?
      ( rv => qq|$rv|,   fila => !-f $ftga,   filb => !-f $ftgb ) :
      $arg eq q|tag+54e9| ?
      ( md5sum => $fafs->{message}{md5_hash}, file => !-f $ftga ) :
                                                                die $arg } }

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request(
{ method => q|file|, force_file => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM|;
FAFTS_show_message %{$fafs->{message}};
is $serr, '', q|tag+cf50 {STDERR} is empty|;
$tmpl =
{ rv => qq|$fafs|, stderr => '', status => 201, log => [ ],
  mark => 0,                                  pending => 8 };

$fsra = FAFTS_tempfile
  nick => q|ftag1b69|, dir => $dira, content => q|tag+fc9c|;
push @purg, $ftga = FAFTS_cat_fn q|.|, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|86f96b5dd4e5e242bdcda51dbd31d4a9|, file => !0 },
                                                 q|tag+7aa9 one file|;

$fsra = FAFTS_tempfile
 nick => q|ftag3bfb|, dir => $dira, content => q|tag+20f0|;
push @purg, $ftga = FAFTS_cat_fn q|.|, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|e99900ad611fcf5b121d28df3f6098fe|, file => !0 },
                                            q|tag+7f00 no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftagd28c|, dir => $dira, content => q|tag+4228|;
$fsrb = FAFTS_tempfile
  nick => q|ftag8cb9|, dir => $dira, content => q|tag+4100|;
push @purg,
  $ftga = FAFTS_cat_fn( q|.|, $fsra ), $ftgb = FAFTS_cat_fn( q|.|, $fsrb );
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply give_got( q|tag+c43d| ), { %$tmpl, fila => !0, filb => !0 },
  q|tag+ab58 two files|;

$fsra = FAFTS_tempfile
  nick => q|ftag4d06|, dir => $dira, content => q|tag+d194|;
$fsrb = FAFTS_tempfile
  nick => q|ftag21b6|, dir => $dira, content => q|tag+4a47|;
push @purg,
  $ftga = FAFTS_cat_fn( q|.|, $fsra ), $ftgb = FAFTS_cat_fn( q|.|, $fsrb );
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra, $fsrb ) };
is_deeply give_got( q|tag+c43d| ), { %$tmpl, fila => !0, filb => !0 },
  q|tag+872b no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftagbc9e|, dir => $dira, content => q|tag+2600|;
$fsrb = FAFTS_tempfile
  nick => q|ftag87ef|, dir => $dirb, content => q|tag+4895|;
push @purg,
  $ftga = FAFTS_cat_fn( q|.|, $fsra ), $ftgb = FAFTS_cat_fn( q|.|, $fsrb );
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply give_got( q|tag+c43d| ), { %$tmpl, fila => !0, filb => !0 },
  q|tag+103b two files in two dirs|;

$fsra = FAFTS_tempfile
  nick => q|ftag7c90|, dir => $dira, content => q|tag+9222|;
$ftga = FAFTS_cat_fn $dirb, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirb }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|630fb806bbd386450768186e8d3a1601|, file => !0 },
                           q|tag+de36 overriding default {$location}|;

$dirc = FAFTS_tempdir nick => q|dtag6a1f|;
( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request(
{ method => q|file|, force_file => !0, location => $dirc }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$location}|;
is $serr, '', q|tag+4710 {STDERR} is empty|;
$tmpl->{rv} = qq|$fafs|;

$fsra = FAFTS_tempfile
  nick => q|ftag32d2|, dir => $dira, content => q|tag+30fd|;
$ftga = FAFTS_cat_fn $dirc, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|3e4dd19bfd128f46c4d520d87e854008|, file => !0 },
                                                 q|tag+b641 one file|;

$fsra = FAFTS_tempfile
  nick => q|ftagf507|, dir => $dira, content => q|tag+b320|;
$ftga = FAFTS_cat_fn $dirc, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|7ab390fd9dfdd612c9e4d3b67843ae3a|, file => !0 },
                                            q|tag+0aa0 no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftaga87f|, dir => $dira, content => q|tag+938a|;
$fsrb = FAFTS_tempfile
  nick => q|ftag328d|, dir => $dira, content => q|tag+64e7|;
( $ftga, $ftgb ) =
( FAFTS_cat_fn( $dirc, $fsra ), FAFTS_cat_fn( $dirc, $fsrb ));
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply give_got( q|tag+c43d| ), { %$tmpl, fila => !0, filb => !0 },
  q|tag+d528 two files|;

$fsra = FAFTS_tempfile
  nick => q|ftagf552|, dir => $dira, content => q|tag+424a|;
$fsrb = FAFTS_tempfile
  nick => q|ftagbc80|, dir => $dirb, content => q|tag+e901|;
( $ftga, $ftgb ) =
( FAFTS_cat_fn( $dirc, $fsra ), FAFTS_cat_fn( $dirc, $fsrb ));
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply give_got( q|tag+c43d| ), { %$tmpl, fila => !0, filb => !0 },
  q|tag+13a4 two files in two dirs|;

$fsra = FAFTS_tempfile
  nick => q|ftagbae6|, dir => $dira, content => q|tag+6031|;
$ftga = FAFTS_cat_fn $dirb, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirb }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|7ccff20113419050acd66eb508fec771|, file => !0 },
                           q|tag+68c5 overriding default {$location}|;

$fsra = FAFTS_tempfile
  nick => q|ftag4e3b|, dir => $dira, content => q|tag+faca|;
push @purg, $ftga = FAFTS_cat_fn q|.|, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => q|.| }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|af3af7537cfa7861501f8e08db18af8a|, file => !0 },
                           q|tag+0cbc overriding default {$location}|;

$fsra = FAFTS_tempfile
  nick => q|ftag3340|, dir => $dirc, content => q|tag+5294|;
$ftga = FAFTS_cat_fn $dira, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dira }, $fsra ) };
is_deeply                                     give_got( q|tag+12d0| ),
{ %$tmpl, md5sum => q|4f73680d76104b02bccea86bee75fe5d|, file => !0 },
                           q|tag+eb42 overriding default {$location}|;

$dirc = substr $dirb, 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
$fsra = FAFTS_tempfile
  nick => q|ftag7a52|, dir => $dira, content => q|tag+730c|;
$ftga = FAFTS_cat_fn $dirb, $fsra;
delete $tmpl->{rv};
( $rv, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request(
{ method => q|file|, force_file => !0, location => $dirc }, $fsra ) };
is_deeply                                     give_got( q|tag+54e9| ),
{ %$tmpl, md5sum => q|4f73680d76104b02bccea86bee75fe5d|, file => !0 },
                                    q|cCM {$location} isn't absolute|;
$tmpl->{rv} = qq|$fafs|;

$dirc = substr $dirb = FAFTS_tempdir( nick => q|dtag89f5| ), 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
$fsra = FAFTS_tempfile
  nick => q|ftagf462|, dir => $dira, content => q|tag+c83e|;
$ftga = FAFTS_cat_fn $dirb, $fsra;
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirc }, $fsra ) };
is_deeply                                      give_got( q|tag+12d0| ),
{ %$tmpl,, md5sum => q|5b5ca6895e35cf469e6cc98d62b5481d|, file => !0 },
                                     q|cUM {$location} isn't absolute|;

undef $fafs; $fafs = '';
undef $rv; $rv = '';

# vim: syntax=perl
