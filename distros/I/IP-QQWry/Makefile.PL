use strict;
use inc::Module::Install;
name 'IP-QQWry';
all_from 'lib/IP/QQWry.pm';
requires version => 0;
build_requires 'Test::More' => 0;
auto_install;
author_tests('xt/');
WriteAll;
