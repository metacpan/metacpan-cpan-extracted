#!/usr/bin/env perl -w
use strict;
use warnings;
use vars qw( %API $MAGICK_SKIP );
use Test::More;
use Cwd;
use Carp qw(croak);
use lib qw(
   ..
   ../t/lib
      t/lib
);

BEGIN {
   do 't/magick.pl' || croak "Can not include t/magick.pl: $!";

   %API = (
      magick                          => 6,
      magick_scramble                 => 6,
      magick_scramble_fixed           => 6,
      magick_info_text                => 6,
      magick_scramble_info_text       => 6,
      magick_scramble_fixed_info_text => 6,
   );

   my $total  = 0;
      $total += $API{$_} foreach keys %API;

   plan tests => $total;

   SKIP: {
      if ( $MAGICK_SKIP ) {
         skip( $MAGICK_SKIP . ' Skipping...', $total );
      }
      require GD::SecurityImage;
      GD::SecurityImage->import( use_magick => 1 );
   }
   exit if $MAGICK_SKIP;
}

use Test::GDSI;

my $tapi = 'Test::GDSI';
   $tapi->clear;

my $font = getcwd.'/StayPuft.ttf';

my %info_text = (
   text   => $tapi->the_info_text,
   ptsize => 12,
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
   if ( $name =~ m{ _info_text \z }xms ) {
      return info_text => { %info_text };
   }
   return +();
}

sub args {
   my $name = shift;
   my %options = (
      magick => {
         width      => 250,
         height     => 80,
         send_ctobg => 1,
         font       => $font,
         ptsize     => 50,
      },
      magick_scramble => {
         width      => 350,
         height     => 80,
         send_ctobg => 1,
         font       => $font,
         ptsize     => 30,
         scramble   => 1,
      },
      magick_scramble_fixed => {
         width      => 350,
         height     => 80,
         send_ctobg => 1,
         font       => $font,
         ptsize     => 30,
         scramble   => 1,
         angle      => 32,
      },
   );
   my $o = $options{$name};
   if ( not $o ) {
     (my $tmp = $name) =~ s{ _info_text }{}xms;
      $o = $options{$tmp};
   }
   croak "Bogus arg name $name!" if not $o;
   return %{ $o }
}
