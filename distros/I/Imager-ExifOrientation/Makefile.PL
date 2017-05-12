use inc::Module::Install;
name 'Imager-ExifOrientation';
all_from 'lib/Imager/ExifOrientation.pm';

requires 'Imager' => 0.51; # requires Imager::Color, Exif support
requires 'Image::ExifTool';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_include;
auto_set_repository;
WriteAll;
