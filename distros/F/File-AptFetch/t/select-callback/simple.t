# $Id: simple.t 510 2014-08-11 13:26:00Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::TestSuite::FAFS;
use base qw| File::AptFetch::Simple |;

sub request                                                       {
    shift;
    my $args = shift;
    bless { trace => $args, pid => -1, cheat_beat => q|tag-b29c| } }

sub DESTROY { }

sub tick                      {
    my $self = shift;
    my $rv;
    File::AptFetch::Simple::_select_callback( $self );
    $rv += File::AptFetch::Simple::_read_callback( $_ )                foreach
      values %{$self->{trace}} }

package main;
use version 0.77; our $VERSION = version->declare( v0.1.3 );

use t::TestSuite qw| :temp :file :mthd :diag |;
use File::AptFetch::Simple;
use Test::More;

my( @units,  $dsrc,  @file,  @faux );
my( $faf, $rv, $serr, $fdat, $sdat );

my $msgv = qr{\Atag-b29c\x5b([perl5]+X/s)\x5d};
my $msgb = qr{\Atag-b29c\x5b([ \d.]+b/s)\x5d};
my $msgk = qr{\Atag-b29c\x5b([ \d.]+K/s)\x5d};
my $msgm = qr{\Atag-b29c\x5b([ \d.]+M/s)\x5d};

@units =
([{ tag => q|tag+3413|, init => !0 },
  sub                             {
      @file = ( FAFTS_tempfile
        nick => q|ftag87c0|, dir => $dsrc, unlink => !0 );
      @faux = ( (File::Temp::tempfile
        +(split m{/}, $file[0])[-1] . q|_XXXX|, DIR => $dsrc)[-1] );
      unlink @faux                 }                                ],
 [{ tag => q|tag+b835|, stderr => qr{^$} }, sub { }, [ '',  1 ]     ],
 [{ tag => q|tag+d742|, stderr => $msgv },
  sub {   FAFTS_set_file $faux[0] => '' },
  [                               '', 1 ]                           ],
 [{ tag => q|tag+875b|, stderr => $msgv }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+23a7|,           stderr => $msgv },
  sub { FAFTS_append_file $faux[0] => q|tag+f332| },
  [                                         '', 1 ]                 ],
 [{ tag => q|tag+c140|,           stderr => $msgb },
  sub { FAFTS_append_file $faux[0] => q|tag+f988| },
  [                                         '', 1 ]                 ],
 [{ tag => q|tag+7f15|,                stderr => $msgb },
  sub { FAFTS_append_file $faux[0] => q|tag+a4a2| x 10 },
  [                                              '', 1 ]            ],
 [{ tag => q|tag+ca26|,                 stderr => $msgb },
  sub { FAFTS_append_file $faux[0] => q|tag+4bc8| x 100 },
  [                                               '', 1 ]           ],
 [{ tag => q|tag+c891|,                  stderr => $msgk },
  sub { FAFTS_append_file $faux[0] => q|tag+e0aa| x 1000 },
  [                                                '', 1 ]          ],
 [{ tag => q|tag+bd88|, stderr => $msgk },
  sub {       rename $faux[0], $file[0] },
  [                               '', 1 ]                           ],
 [{ tag => q|tag+81d0|, stderr => $msgk }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+fe6a|, stderr => $msgv }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+cc16|, stderr => $msgv }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+9325|, init => !0 },
  sub                             {
      @file =
      ( FAFTS_tempfile( nick => q|ftag979b|, dir => $dsrc, unlink => !0 ),
        FAFTS_tempfile( nick => q|ftagf21d|, dir => $dsrc, unlink => !0 ) );
      @faux =
     ( (File::Temp::tempfile
       +(split m{/}, $file[0])[-1] . q|_XXXX|, DIR => $dsrc)[-1],
       (File::Temp::tempfile
       +(split m{/}, $file[1])[-1] . q|_XXXX|, DIR => $dsrc)[-1] );
      unlink @faux                 }                                ],
 [{ tag => q|tag+0021|, stderr => $msgv }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+9086|,                 stderr => $msgv },
  sub { FAFTS_append_file $faux[0] => q|tag+d1c8| x 100 },
  [                                               '', 1 ]           ],
 [{ tag => q|tag+385d|,                stderr => $msgk },
  sub { FAFTS_append_file $faux[1] => q|tag+7463| x 10 },
  [                                              '', 1 ]            ],
 [{ tag => q|tag+3225|,                 stderr => $msgb },
  sub {
      FAFTS_append_file $faux[0] => q|tag+c8d2| x 20000;
      FAFTS_append_file $faux[1] => q|tag+b359| x 20000 },
  [                                               '', 1 ]           ],
 [{ tag => q|tag+449b|, stderr => $msgm },
  sub {
      FAFTS_append_file $faux[1] => q|tag+dc41| x 10;
      rename $faux[0], $file[0]         },
  [                               '', 1 ]                           ],
 [{ tag => q|tag+a366|, stderr => qr{$msgk|$msgm} },
  sub {                   rename $faux[1], $file[1] },
  [                                           '', 2 ]               ],
 [{ tag => q|tag+8c24|, stderr => $msgb }, sub { }, [ '', 1 ]       ],
 [{ tag => q|tag+b63a|, stderr => $msgv }, sub { }, [ '', 1 ]       ] );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => scalar @units );

$dsrc = FAFTS_tempdir nick => q|dtag4080|;

while( my $unit = shift @units )                                          {
    $t::TestSuite::Diag_Tag = $unit->[0]{tag};
    $unit->[1]->();
    FAFTS_show_message %$_                                     foreach @$fdat;
    if( $unit->[0]{init} )                                               {
      ( $faf, $serr ) = FAFTS_wrap {
            t::TestSuite::FAFS->request( { map                          {
                $unit->[0]{tag} . (split m{_})[-2] => { filename => $_ } }
              @file })              };
        $fdat = [ values %{$faf->{trace}} ];
        ok !$serr, $unit->[0]{tag}                                        }
    else                                                                 {
        unless( exists $unit->[0]{sleep} ) {                 sleep 1 }
        elsif( !$unit->[0]{sleep}        ) {                         }
        else                               { sleep $unit->[0]{sleep} }
      ( $rv, $serr ) = FAFTS_wrap { $faf->tick };
        $sdat = [ $unit->[0]{stderr} ? $serr =~ m($unit->[0]{stderr}) : ( ) ];
        is_deeply [ $rv, scalar @$sdat ], $unit->[2],
          sprintf q|%s (%s)|, $unit->[0]{tag}, join ' ', grep $_, @$sdat  }}

# vim: syntax=perl
