#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/';
use Test::More tests => 94;

my $module = 'Graphics::Toolkit::Color::Space::Hub';
my $space_ref = 'Graphics::Toolkit::Color::Space';
my @space_names = (qw/RGB LinearRGB CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/,
                   qw/CIEXYZ CIERGB CIELAB CIELUV CIELCHab CIELCHuv HunterLAB/,
                   qw/AdobeRGB AppleRGB ProPhotoRGB WideGamutRGB/,
                   qw/DisplayP3Linear DisplayP3 DCIP3Linear DCIP3 Rec709 Rec2020/,
                   qw/OKLAB OKLCH/);
my $space_name_aliases = 16;
my $space_names = @space_names + $space_name_aliases;
eval "use $module";
is( not($@), 1, 'could load the module'); # say $@;

is( ref Graphics::Toolkit::Color::Space::Hub::get_space('RGB'),  $space_ref, 'RGB is a color space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),   1, "found $_ color space") for @space_names;

my @names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  $space_names, 'intalled 27 space names');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),      1, "$_ is a space name") for @names;

my $Tspace = Graphics::Toolkit::Color::Space->new( axis => [qw/one two three/], range => 10 );
   $Tspace->add_converter(          'RGB', \&p, \&p );
   sub p { @{$_[0]} }

my $ret = Graphics::Toolkit::Color::Space::Hub::add_space( $Tspace );
is( $ret, 1, "could add test color space");
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          1, 'test space was installed');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),   $Tspace, 'got access to test space');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names, $space_names+1, 'intalled 34st space name');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('TTT'), '', 'try to delete unknown space');

is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), $space_ref, 'removed test space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is gone');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),        '', 'no access to test space');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), '', 'test space was already removed');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is still gone');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names, $space_names, 'intalled again only 20 space names');

my $rgb_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($rgb_name),             1, 'default space name is valid');
is( ref Graphics::Toolkit::Color::Space::Hub::get_space($rgb_name),    $space_ref, 'can get default space');
is( ref Graphics::Toolkit::Color::Space::Hub::default_space(),    $space_ref, 'default space is a space');
my %sn = map {$_ => 1} @names;
is( $sn{$rgb_name},  1  , 'default space is among color spaces');

exit 0;
