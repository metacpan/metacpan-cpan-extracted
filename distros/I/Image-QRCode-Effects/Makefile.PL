use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Image-QRCode-Effects';
all_from 'lib/Image/QRCode/Effects.pm';
license  'perl';

perl_version 5.006;

tests 't/*.t';

resources (
   license    => 'http://dev.perl.org/licenses/',
   repository => 'http://github.com/mcartmell/Image-QRCode-Effects',
   bugtracker => 'http://github.com/mcartmell/Image-QRCode-Effects/issues',
);

requires (
	'File::Slurp' => 9999.19,
	'Image::Magick' => 6,
	'Imager' => 0.94,
	'Imager::QRCode' => 0.033,
	'File::Temp' => 0.22,
	'Params::Validate' => 1.07,
	'Scalar::Util' => 1.27
);

test_requires 'Test::More' => 0;

WriteAll;
