#!/usr/bin/perl

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME         => 'HTML::Diff',
    VERSION_FROM => 'lib/HTML/Diff.pm',

    PREREQ_PM    => {
        'Algorithm::Diff'   => '1.15',
        'warnings'          => 0,
        'strict'            => 0,
        'Exporter'          => 0,
    },

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test'         => 0,
                'Getopt::Long' => 0.88,
                'Data::Dumper' => 0,
          })
        : ()
    ),

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => {
                version => 2,
            },
            resources => {
                bugtracker  => {
                    web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Diff',
                },
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilb/html-diff',
                    url  => 'git://github.com/neilb/html-diff.git',
                },
            },
          })
    ),

    EXE_FILES    => ['htmldiff'],
);

