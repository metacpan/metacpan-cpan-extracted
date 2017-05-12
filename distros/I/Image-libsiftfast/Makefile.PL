use inc::Module::Install;
name 'Image-libsiftfast';
all_from 'lib/Image/libsiftfast.pm';

requires 'Imager';
requires 'File::Which';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'FindBin::libs';
auto_set_repository;
auto_include;
WriteAll;
