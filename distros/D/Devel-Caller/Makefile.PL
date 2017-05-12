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
    }
);
