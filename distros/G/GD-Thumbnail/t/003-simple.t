#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use GD::Thumbnail;
use File::Spec;
use IO::File;
use Cwd;
use Carp qw( croak );
use IO::File;

use constant RGB_WHITE  => 255, 255, 255;
use constant RGB_BLACK  =>   0,   0,   0;
use constant MAX_PIXELS => 100;

sub save;

BEGIN {
   plan tests => 128;
}

my $COUNTER = 1;

my $foriginal   = File::Spec->catfile( getcwd, 'cpan.jpg'   );
my $foriginal90 = File::Spec->catfile( getcwd, 'cpan90.jpg' );

ok( ( -e $foriginal   && ! -d _ ), 'Original file seems to be ok'         );
ok( ( -e $foriginal90 && ! -d _ ), 'Original rotated file seems to be ok' );

my($original, $original90);

DUMB_GD_DIES_ON_WINDOWS_PATHS_SO_WE_NEED_SCALARS: {
   my $o   = IO::File->new;
   my $o90 = IO::File->new;

   $o->open(   $foriginal   ) or croak "Can not open $foriginal   : $!";
   $o90->open( $foriginal90 ) or croak "Can not open $foriginal90 : $!";
   binmode $o;
   binmode $o90;

   local $/;
   $original   = <$o>;
   $original90 = <$o90>;
   $o->close;
   $o90->close;
}

my %opt = (
   strip_color => [ RGB_WHITE ],
   info_color  => [ RGB_BLACK ],
   square      => 1,
   frame       => 1,
);

run();

delete @opt{qw/ strip_color info_color /};
run();

$opt{square}  = 'crop';
run();

sub run { # x42 tests
   test( GD::Thumbnail->new(%opt), $original   );
   test( GD::Thumbnail->new(%opt), $original90 );

   test( $_, $original ) for
      GD::Thumbnail->new( %opt, force_mime  => 'gif'  ),
      GD::Thumbnail->new( %opt, force_mime  => 'png'  ),
      GD::Thumbnail->new( %opt, force_mime  => 'jpeg' ),
      GD::Thumbnail->new( %opt, force_mime  => 'gd'   ),
      GD::Thumbnail->new( %opt, force_mime  => 'gd2'  ),
   ;
   return;
}

sub test { # x6 tests
   my $gd  = shift;
   my $img = shift;
   #seek $img, 0, 0;
   ok( save $gd->create($img, MAX_PIXELS, 2), $gd->mime );
   ok( save $gd->create($img, MAX_PIXELS, 1), $gd->mime );
   ok( save $gd->create($img, MAX_PIXELS, 0), $gd->mime );
   $gd->{FRAME}   = 0;
   $gd->{SQUARE}  = 0;
   $gd->{OVERLAY} = 0;
   ok( save $gd->create($img, MAX_PIXELS, 2), $gd->mime );
   ok( save $gd->create($img, MAX_PIXELS, 1), $gd->mime );
   ok( save $gd->create($img, MAX_PIXELS, 0), $gd->mime );
   return;
}

sub save {
   my($raw, $mime) = @_;
   my $id = sprintf '%04d.%s', $COUNTER++, $mime;
   my $IMG = IO::File->new;
   $IMG->open( $id, '>' ) or croak "Save error: $!";
   binmode $IMG;
   my $pok = print {$IMG} $raw;
   $IMG->close;
   return  1;
}

exit;
