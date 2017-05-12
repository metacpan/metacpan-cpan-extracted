use inc::Module::Install;
name 'HTTP-MobileAgent-Plugin-Charset';
all_from 'lib/HTTP/MobileAgent/Plugin/Charset.pm';

requires 'HTTP::MobileAgent' => '0.26';

test_requires 'Test::More' => 0.98;
author_tests('xt');
WriteAll;
