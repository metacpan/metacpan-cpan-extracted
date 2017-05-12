#! perl

use strict;
use warnings;
use inc::Module::Install;

name	'Image-DS9';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Image/DS9.pm';

requires_external_bin 'ds9';

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://github.com/djerius/image-ds9',
   bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9',
);

author_tests( 'xt' );

cpanfile;

WriteAll;
