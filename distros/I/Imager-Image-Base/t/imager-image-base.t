#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Test::More 'no_plan';

use Imager::Image::Base;
use Imager::Image::Xpm;
use Imager::Image::Xbm;

my $test_xpm = "$FindBin::RealBin/../img/test.xpm";
my $test_xbm = "$FindBin::RealBin/../img/test.xbm";
my $museum_xpm = "$FindBin::RealBin/../img/museum.xpm"; # with transparency

ok !eval { Imager::Image::Xpm->new(); 1 };
like $@, qr{file option is mandatory};

ok !eval { Imager::Image::Xpm->new(x => 123, file => 'non-existing'); 1 };
like $@, qr{unhandled option}i;

{
    my $imager_xpm = Imager::Image::Xpm->new(file => $test_xpm);
    isa_ok $imager_xpm, 'Imager';
    is $imager_xpm->getwidth, 127;
    is $imager_xpm->getheight, 13;
    my $color = $imager_xpm->getpixel(x=>0, y=>0);
    is(($color->rgba)[3], 255, 'opaque pixel');
}

{
    my $imager_xpm = Imager::Image::Xpm->new(file => $museum_xpm);
    isa_ok $imager_xpm, 'Imager';
    is $imager_xpm->getwidth, 12;
    is $imager_xpm->getheight, 13;
    my $color = $imager_xpm->getpixel(x=>0, y=>0);
    is(($color->rgba)[3], 0, 'transparent pixel');

}

{
    my $imager_xbm = Imager::Image::Xbm->new(file => $test_xbm);
    isa_ok $imager_xbm, 'Imager';
    is $imager_xbm->getwidth, 6;
    is $imager_xbm->getheight, 6;
}

{
    my $image_base_xpm = Image::Xpm->new(-file => $test_xpm);
    my $imager_image_base_xpm = Imager::Image::Base->convert($image_base_xpm);
    isa_ok $imager_image_base_xpm, 'Imager';
}

__END__
