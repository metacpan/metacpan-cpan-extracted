use strict;
use warnings;
use inc::Module::Install;

name            'HTTP-MobileAgent-Plugin-Locator';
author          'Yoshiki Kurihara <kurihara __at__ cpan.org>';
all_from        'lib/HTTP/MobileAgent/Plugin/Locator.pm';

build_requires 'Test::More' => 0;

requires 'Geo::Coordinates::Converter' => '0.10';
requires 'Geo::Coordinates::Converter::iArea' => '0.11';
requires 'HTTP::MobileAgent' => 0.31;
requires 'UNIVERSAL::require' => 0;
requires 'UNIVERSAL::can' => 0;

test_requires 'Test::Requires';
tests 't/*.t t/*/*.t';

WriteAll;
