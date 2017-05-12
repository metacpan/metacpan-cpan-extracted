#!/usr/bin/perl

use strict;
use inc::Module::Install;

name('Inline-MzScheme');
version_from('lib/Inline/MzScheme.pm');
abstract_from('lib/Inline/MzScheme.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
build_requires('Test::More');
requires(qw(
    Inline              0.43
    Language::MzScheme  0.05
));

WriteAll( sign => 1 );
