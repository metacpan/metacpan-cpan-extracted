use inc::Module::Install;
name 'Image-JpegCheck';
all_from 'lib/Image/JpegCheck.pm';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;
test_requires 'Test::More' => 0.92;
WriteAll;
