#!/usr/bin/perl

use strict;
use inc::Module::Install;

name('Inline-Perl');
version_from('lib/Inline/Perl.pm');
abstract_from('lib/Inline/Perl.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
build_requires('Test::More');
requires(qw(
    Inline              0.43
    Perl                0.03
));

WriteAll( sign => 1 );
