# $Id: 0.t 506 2014-07-04 18:07:33Z whynot $
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

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                    ( tests => 72 );

my( $dira, $dirb, $dirc );
my( $fafs, $serr, $tmpl );

sub give_got ( )                                                         {
    stderr => $serr, status => $fafs->{Status}, method => $fafs->{method},
    mark => scalar keys %{$fafs->{trace}},  location => $fafs->{location} }

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( q|copy| ) };
$tmpl =
{ stderr => '', status => 100, method => q|copy|,
  mark => 0,                     location => '.' };
isa_ok $fafs, q|File::AptFetch::Simple|, q|[copy:] sCM|;
is_deeply { give_got }, $tmpl, q|tag+5566 deeply|;

( $fafs, $serr ) = FAFTS_wrap                           {
  File::AptFetch::Simple->request({ method => q|copy| }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|[copy:] cCM|;
is_deeply { give_got }, $tmpl, q|tag+5192 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ method => q|tag+7c57| }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+b447 cUM|;
is_deeply { rv => qq|$fafs|, give_got }, { rv => qq|$fafs|, %$tmpl },
  q|tag+9f59 deeply|;

$dira = FAFTS_tempdir nick => q|dtag2e92|;
( $fafs, $serr ) = FAFTS_wrap                                              {
  File::AptFetch::Simple->request({ method => q|copy|, location => $dira }) };
$tmpl->{location} = $dira;
delete $tmpl->{rv};
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+0a14 cCM with {$location}|;
is_deeply { give_got }, $tmpl, q|tag+76b2 deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+0bbe sUM|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+4a6e deeply|;

$dirb = FAFTS_tempdir nick => q|dtag5d98|;
( $fafs, $serr ) = FAFTS_wrap                                 {
  $fafs->request({ method => q|tag+1a18|, location => $dirb }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+bb14 cUM {$location}|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+d1da deeply|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( q|file| ) };
$tmpl->{location} = '.';
delete $tmpl->{rv};
isa_ok $fafs, q|File::AptFetch::Simple|, q|[file:] sCM|;
is_deeply { give_got }, $tmpl, q|tag+8003 deeply|;

( $fafs, $serr ) = FAFTS_wrap                           {
  File::AptFetch::Simple->request({ method => q|file| }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|[file:] cCM|;
is_deeply { give_got }, $tmpl, q|tag+a97c deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+1d93 sUM|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+c588 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( undef ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+e04d sUM undef|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+2d20 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( '' ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+2918 sUM empty string|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+f02e deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( 0 ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+3ffe sUM nil|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+5f60 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ method => q|tag+d129| }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+83b5 cUM {%options}|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+4374 deeply|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request(
{ method => q|file|, force_file => !0 }) };
$tmpl->{method} = q|file|;
delete $tmpl->{rv};
isa_ok $fafs, q|File::AptFetch::Simple|, q|{force_file} cCM|;
is_deeply { give_got }, $tmpl, q|tag+ed5b deeply|;
$tmpl->{rv} = qq|$fafs|;

$dira = FAFTS_tempdir nick => q|dtag3889|;
( $fafs, $serr ) = FAFTS_wrap                                              {
  File::AptFetch::Simple->request({ method => q|file|, location => $dira }) };
$tmpl =
{ stderr => '',                     status => 100,
  method => q|copy|, mark => 0, location => $dira };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+f4da cCM {$location}|;
is_deeply { give_got }, $tmpl, q|tag+43e0 deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+7927 sUM|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+a955 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( undef ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+1c74 sUM undef|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+01f4 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( '' ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+f950 sUM empty string|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+8f28 deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( 0 ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+fb96 sUM nil|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+d6d7 deeply|;

$dirb = FAFTS_tempdir nick => q|dtag008f|;
( $fafs, $serr ) = FAFTS_wrap                                 {
  $fafs->request({ method => q|tag+0317|, location => $dirb }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|tag+3615 cUM {$location}|;
is_deeply { rv => qq|$fafs|, give_got }, $tmpl, q|tag+6892 deeply|;

$dirc = substr $dirb = FAFTS_tempdir( nick => q|dtag760d| ), 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
( $fafs, $serr ) = FAFTS_wrap                                              {
  File::AptFetch::Simple->request({ method => q|file|, location => $dirc }) };
$tmpl->{location} = $dirc;
delete $tmpl->{rv};
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$location} isn't absolute|;
is_deeply { give_got, exists => !-d $dirc }, { %$tmpl, exists => !1 },
  q|tag+0752 deeply|;

$dirc = substr $dirb = FAFTS_tempfile( nick => q|dtag659f|, dir => $dira ), 1;
$dirc =~ s{[^/]+/}{}                                           until -f $dirc;
unlink $dirc;
$tmpl->{location} = $dirc;
( $fafs, $serr ) = FAFTS_wrap                                              {
  File::AptFetch::Simple->request({ method => q|file|, location => $dirc }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$location} is missing|;
is_deeply { give_got, exists => !-e $dirc }, { %$tmpl, exists => !0 },
  q|tag+56f5 deeply|;
$tmpl->{rv} = qq|$fafs|;

$dirc = substr $dirb = FAFTS_tempdir( nick => q|dtag6e8b| ), 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirc }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cUM {$location} isn't absolute|;
is_deeply
{ rv => qq|$fafs|, give_got, exists => !-d $dirc },
{ %$tmpl,                           exists => !1 },
                                q|tag+5026 deeply|;

$dirc = substr $dirb = FAFTS_tempfile( nick => q|dtag13cc|, dir => $dira ), 1;
$dirc =~ s{[^/]+/}{}                                           until -f $dirc;
unlink $dirc;
( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirc }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cUM {$location} is missing|;
is_deeply
{ rv => qq|$fafs|, give_got, exists => !-e $dirc },
{ %$tmpl,                           exists => !0 },
                                q|tag+8d2e deeply|;

File::AptFetch::ConfigData->set_config( wink => !1 );
File::AptFetch::ConfigData->set_config( beat => !1 );
delete $tmpl->{rv};
$tmpl->{location} = '.';

( $fafs, $serr ) = FAFTS_wrap                             {
    File::AptFetch::Simple->request({ method => q|file| }) };
isa_ok $fafs, q|File::AptFetch::Simple|,
  q|cCM {$wink} and {$beat} aren't merged|;
is_deeply
{ give_got, ew => !exists $fafs->{wink}, eb => !exists $fafs->{beat} },
{ %$tmpl,                     ew => !0,                     eb => !0 },
                                                    q|tag+488e deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( ) };
isa_ok $fafs, q|File::AptFetch::Simple|,
  q|tag+711d sUM {$wink} and {$beat} aren't merged|;
is_deeply { rv => qq|$fafs|,                      give_got,
  ew => !exists $fafs->{wink}, eb => !exists $fafs->{beat} },
{             %$tmpl,
  ew => !0, eb => !0                                       },
                                          q|tag+7b8d deeply|;

( $fafs, $serr ) = FAFTS_wrap                       {
    $fafs->request({ wink => !0, beat => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|,
  q|tag+1080 cUM {$wink} and {$beat} aren't merged|;
is_deeply { rv => qq|$fafs|,                      give_got,
  ew => !exists $fafs->{wink}, eb => !exists $fafs->{beat} },
{             %$tmpl,
  ew => !0, eb => !0                                       },
                                          q|tag+3e14 deeply|;

delete $tmpl->{rv};
( $fafs, $serr ) = FAFTS_wrap                                         {
    File::AptFetch::Simple->request({ method => q|file|, wink => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$wink} is adopted|;
is_deeply {                                give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
                        eb => !exists $fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
            eb => !0                                },
                                   q|tag+ecd3 deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|sUM {$wink} isn't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
                        eb => !exists $fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
            eb => !0                                },
                                   q|tag+5d8a deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ wink => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cUM {$wink} isn't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
                        eb => !exists $fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
            eb => !0                                },
                                   q|tag+01f3 deeply|;

delete $tmpl->{rv};
( $fafs, $serr ) = FAFTS_wrap                                         {
    File::AptFetch::Simple->request({ method => q|file|, beat => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$beat} is adopted|;
is_deeply {                                give_got,
                        ew => !exists $fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
            ew => !0,
  eb => !1, vb => !1                                },
                                   q|tag+8f25 deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|sUM {$beat} isn't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
                        ew => !exists $fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
            ew => !0,
  eb => !1, vb => !1                                },
                                   q|tag+897a deeply|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request({ beat => !1 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cUM {$beat} isn't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
  ew => !exists $fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
            ew => !0,
  eb => !1, vb => !1                                },
                                   q|tag+9beb deeply|;

delete $tmpl->{rv};
( $fafs, $serr ) = FAFTS_wrap                     {
    File::AptFetch::Simple->request(
    { method => q|file|, wink => !0, beat => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|, 
  q|cCM {$wink} and {$beat} are adopted|;
is_deeply {                                give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
  eb => !1, vb => !1                                },
                                   q|tag+039b deeply|;
$tmpl->{rv} = qq|$fafs|;

( $fafs, $serr ) = FAFTS_wrap { $fafs->request( ) };
isa_ok $fafs, q|File::AptFetch::Simple|,
  q|sUM {$wink} and {$beat} aren't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
  eb => !1, vb => !1                                },
                                   q|tag+93b5 deeply|;

( $fafs, $serr ) = FAFTS_wrap                 {
    $fafs->request({ wink => !1, beat => !0 }) };
isa_ok $fafs, q|File::AptFetch::Simple|,
  q|cUM {$wink} and {$beat} aren't merged|;
is_deeply { rv => qq|$fafs|,               give_got,
  ew => !exists $fafs->{wink}, vw => !$fafs->{wink},
  eb => !exists $fafs->{beat}, vb => !$fafs->{beat} },
{             %$tmpl,
  ew => !1, vw => !1,
  eb => !1, vb => !1                                },
                                   q|tag+f4e5 deeply|;

# XXX:201406062046:whynot: Just a usual undef-trick.
# http://www.cpantesters.org/cpan/report/42366dee-ddfe-11e3-b06d-4e4e11ab0dd0
undef $fafs; $fafs = !1;

# vim: syntax=perl
