# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2005-01-01 16:45:20 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'	=> 'Lingua::EN::Numbers',
    'VERSION_FROM' => 'lib/Lingua/EN/Numbers.pm', # finds $VERSION
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
    PREREQ_PM      => {
        'Exporter' => 0,
        'strict' => 0,
        'warnings' => 0,
        'vars' => 0,
    },

    ($mm_ver >= 6.31
        ? (LICENSE => 'gpl')
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-Numbers',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilb/Lingua-EN-Numbers',
                    url  => 'git://github.com/neilb/Lingua-EN-Numbers.git',
                },
            },
          })
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test' => 0,
                'Test::More' => 0.88,
                'bigint' => 0,
          })
        : ()
    ),

);
