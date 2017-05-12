use inc::Module::Install;
name 'HTTP-Session-Store-KyotoTycoon';
all_from 'lib/HTTP/Session/Store/KyotoTycoon.pm';

requires 'HTTP::Session' => 0.40;
requires 'Cache::KyotoTycoon';

test_requires 'File::Which';
test_requires 'Test::Requires';
test_requires 'Test::More' => 0.9701;

readme_markdown_from 'lib/HTTP/Session/Store/KyotoTycoon.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
include('Test::Requires');
WriteAll;
