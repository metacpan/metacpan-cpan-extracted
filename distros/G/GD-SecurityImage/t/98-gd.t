#!/usr/bin/env perl -w
use strict;
use warnings;
use vars qw( %API );
use Test::More;
use Cwd;
use Carp qw(croak);
use lib qw(
   ..
   ../t/lib
      t/lib
);

BEGIN {
   %API = (
      gd_normal                       => 6,
      gd_ttf                          => 6,
      gd_normal_scramble              => 6,
      gd_ttf_scramble                 => 6,
      gd_ttf_scramble_fixed           => 6,
      gd_normal_info_text             => 6,
      gd_ttf_info_text                => 6,
      gd_normal_scramble_info_text    => 6,
      gd_ttf_scramble_info_text       => 6,
      gd_ttf_scramble_fixed_info_text => 6,
   );
   my $total  = 0;
      $total += $API{$_} foreach keys %API;
   plan tests => $total;
   require GD::SecurityImage;
   import  GD::SecurityImage;
}

use Test::GDSI;

my $tapi = 'Test::GDSI';
   $tapi->clear;

my $font = getcwd.'/StayPuft.ttf';

my %info_text = (
   text   => $tapi->the_info_text,
   ptsize => 8,
   color  => '#000000',
   scolor => '#FFFFFF',
);

foreach my $api (keys %API) {
   $tapi->options(args($api), extra($api));
   my $c = 1;
   foreach my $style ($tapi->styles) {
      ok(
         $tapi->save(
            $api->$style()->out(
               force    => 'png',
               compress => 1,
            ),
            $style,
            $api,
            $c++
         ),
         "$style - $api - $c++"
      );
   }
   $tapi->clear;
}

sub extra {
   my $name = shift;
   if ( $name =~ m{ _info_text \z}xms ) {
      my %extra = ( info_text => {%info_text} );
      if ( $name =~ m{ normal }xms ) {
         $extra{info_text}->{gd} = 1;
      }
      if ($name =~ m{ fixed }xms ) {
         # yes, we can use GD' s internal font and ttf together...
         $extra{info_text}->{gd} = 1;
      }
      return %extra;
   }
   return +();
}

sub args {
   my $name = shift;
   my %options = (
   gd_normal => {
      width      => 120,
      height     => 30,
      send_ctobg => 1,
      gd_font    => 'Giant',
   },
   gd_ttf => {
      width      => 210,
      height     => 60,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 25,
   },
   gd_normal_scramble =>  {
      width      => 120,
      height     => 30,
      send_ctobg => 1,
      gd_font    => 'Giant',
      scramble   => 1,
   },
   gd_ttf_scramble =>  {
      width      => 300,
      height     => 90,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 20,
      scramble   => 1,
   },
   gd_ttf_scramble_fixed =>  {
      width      => 350,
      height     => 90,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 25,
      scramble   => 1,
      angle      => 30,
   },
   );
   my $o = $options{$name};
   if ( not $o ) {
     (my $tmp = $name) =~ s{ _info_text }{}xms;
      $o = $options{$tmp};
   }
   croak "Bogus arg name $name!" if not $o;
   return %{$o}
}
