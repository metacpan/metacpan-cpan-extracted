#!perl
use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Devel::Profit',
    VERSION_FROM => 'lib/Devel/Profit.pm',
    ABSTRACT     => 'A Perl profiler',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    LIBS         => ['-lrt'],
    EXE_FILES    => ['bin/devel_profit'],
    PREREQ_PM    => {
        'Test::More'       => '0',
        'PPI'              => '0',
        'PPIx::LineToSub'  => '0',
        'Term::Size'       => '0',
        'Moose'            => '0',
        'MooseX::App::Cmd' => '0',
    },
);
