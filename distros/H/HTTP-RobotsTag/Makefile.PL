use strict;
use inc::Module::Install;

name           'HTTP-RobotsTag';
all_from       'lib/HTTP/RobotsTag.pm';

requires       'Carp';
requires       'HTTP::Headers';
requires       'DateTime::Format::Strptime';
build_requires 'Test::More';

auto_install;
WriteAll;
