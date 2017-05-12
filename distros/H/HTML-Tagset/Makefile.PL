# This -*-perl-*- program writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'HTML::Tagset',
    AUTHOR          => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM    => 'Tagset.pm', # finds $VERSION
    ABSTRACT_FROM   => 'Tagset.pm', # retrieve abstract from module
    PMLIBDIRS       => [qw(lib/)],
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'HTML-Tagset-*' },

);
