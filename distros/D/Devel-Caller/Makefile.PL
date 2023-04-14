#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Devel::Caller',
    AUTHOR        => 'Richard Clamp <richardc@unixbeard.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Devel/Caller.pm',
    ABSTRACT_FROM => 'lib/Devel/Caller.pm',
    PREREQ_PM     => {
        'Test::More' => 0,
        'PadWalker'  => '0.08'
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                url => 'https://github.com/richardc/perl-devel-caller.git',
                web => 'https://github.com/richardc/perl-devel-caller',
            },
            license     => 'http://dev.perl.org/licenses/',
        },
   },
);
