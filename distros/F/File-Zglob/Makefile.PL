use inc::Module::Install;
use Module::Install::AuthorTests;

name 'File-Zglob';
all_from 'lib/File/Zglob.pm';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
