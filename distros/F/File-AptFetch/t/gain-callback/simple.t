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
    bless { trace => $args, pid => -1, cheat_beat => q|tag-cf9e| } }

sub DESTROY { }

sub tick                                          {
    my $slf = shift;
    my $rv;
    File::AptFetch::Simple::_gain_callback( $slf ) }

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :file :mthd :diag |;
use File::AptFetch::Simple;
use Test::More;

my( @units,           @file );
my( $faf, $rv, $serr, $sdat );

@units =
([{ tag => q|tag+b835|, init => !0 }, sub { @file = ( ) },     [ '',  1 ]],
 [{ tag => q|tag+5aec|,                           stderr => '' },
  sub { $faf->{status} = q|tag+45a2| }, [ undef, [ ], undef, 0 ]         ],
 [{ tag => q|tag+8019|,                      stderr => '' },
  sub                          {
      ( $faf->{status}, $faf->{message}{uri} ) =
        qw| tag+9984 tag+0ddc | }, [ undef, [ ], undef, 0 ]              ],
 [{ tag => q|tag+cccd|,                                   stderr => '' },
   sub                                {
       ( $faf->{status}, $faf->{message}{uri}, $faf->{trace}{tag_5424} ) =
       ( qw| tag+84da tag_5424 |, { }) }, [ undef, [ undef ], undef, 0 ] ],
 [{ tag => q|tag+ee91|,                                 stderr => '' },
   sub                        {
       ( $faf->{message}{size}, $faf->{trace}{tag_5424}{final_size} ) =
       qw| tag+3e3f tag+94d0 | }, [ undef, [ q|tag+94d0| ], undef, 0 ]   ],
 [{ tag => q|tag+fddf|, init => !0 }, sub { @file = ( ) },     [ '',  1 ]],
 [{ tag => q|tag+5eee|,                     stderr => '' },
   sub                         {
       ( @{$faf->{message}}{qw| uri size |}, $faf->{trace}{tag_d0a1} ) =
       ( q|tag_d0a1|, 200, { }) }, [ '', [ 200 ], 200, 0 ]               ],
 [{ tag => q|tag+22c0|,                          stderr => '' },
   sub                         {
       ( @{$faf->{message}}{qw| uri size |}, $faf->{trace}{tag_8397} ) =
       ( q|tag_8397|, 100, { }) }, [ '', [ 100, 200 ], 300, 0 ]          ],
 [{ tag => q|tag+063d|,                                  stderr => '' },
   sub { ( @{$faf->{message}}{qw| uri size |} ) = ( q|tag_d0a1|, 50 ) },
   [                                      '', [qw| 100 200 |], 300, 0 ]  ],
 [{ tag => q|tag+ac08|,                           stderr => '' },
   sub                               {
       ( @{$faf->{message}}{qw| uri size |} ) = ( q|tag_8397|, 70 );
       delete $faf->{trace}{tag_d0a1} }, [ '', [ 100 ], 100, 0 ]         ] );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => scalar @units );

while( my $unit = shift @units )   {
    $t::TestSuite::Diag_Tag = $unit->[0]{tag};
    $unit->[1]->();
    if( $unit->[0]{init}    )     {
      ( $faf, $serr ) = FAFTS_wrap {
            t::TestSuite::FAFS->request( { map                          {
                $unit->[0]{tag} . (split m{_})[-2] => { filename => $_ } }
              @file })              };
        ok !$serr, $unit->[0]{tag} }
    elsif( $unit->[0]{fail} )     {
      ( $rv, $serr ) = FAFTS_wrap { $faf->tick };
        $sdat = [ $unit->[0]{stderr} ? $serr =~ m($unit->[0]{stderr}) : ( ) ];
        is_deeply [ $rv =~ m|$unit->[0]{fail}|, scalar @$sdat ], $unit->[2],
          $unit->[0]{tag}          }
    else                          {
      ( $rv, $serr ) = FAFTS_wrap { $faf->tick };
        $sdat = [ $unit->[0]{stderr} ? $serr =~ m($unit->[0]{stderr}) : ( ) ];
        is_deeply
        [ $rv,
          [ map { exists $_->{final_size} ? $_->{final_size} : undef }
            map {                                  $faf->{trace}{$_} }
              sort keys %{$faf->{trace}} ],
          $faf->{pending},
          scalar @$sdat ],
          $unit->[2],
          $unit->[0]{tag}          }}

# vim: syntax=perl
