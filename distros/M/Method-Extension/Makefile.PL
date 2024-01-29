use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Method::Extension',
    DISTNAME           => "Method-Extension",
    AUTHOR             => 'Tiago Peczenyj <tiago.peczenyj+cpan@gmail.com>',
    LICENSE            => "mit",
    ABSTRACT_FROM      => 'lib/Method/Extension.pm',
    VERSION_FROM       => 'lib/Method/Extension.pm',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
    PREREQ_PM          => {
        "Attribute::Handlers" => 0
    },
    TEST_REQUIRES => {
        'Test::More'      => 0.94,
        'Test::Pod'       => 0,
    },
    (   eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE => {
                'meta-spec'    => { version => 2 },
                dynamic_config => 0,
                resources      => {
                    homepage =>
                      'https://github.com/peczenyj/Method-Extension',
                    repository => {
                        type => 'git',
                        url  =>
                          'https://github.com/peczenyj/Method-Extension.git',
                        web =>
                          'https://github.com/peczenyj/Method-Extension',
                    },
                    bugtracker => {
                        web =>
                          'https://github.com/peczenyj/Method-Extension/issues'
                    },
                },
                x_authority => 'cpan:PACMAN',
            }
          )
        : ()
    ),
);
