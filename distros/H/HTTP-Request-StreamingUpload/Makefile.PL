use inc::Module::Install;
name 'HTTP-Request-StreamingUpload';
all_from 'lib/HTTP/Request/StreamingUpload.pm';

requires 'HTTP::Request';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Requires';

use_test_base;
auto_include;
WriteAll;
