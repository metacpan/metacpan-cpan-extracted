use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);
my $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall';
    $OPTIMIZE .= ' -g -Wextra -Wdeclaration-after-statement' if (-d 'dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

WriteMakefile(
    NAME          => 'Devel::Pragma',
    VERSION_FROM  => 'lib/Devel/Pragma.pm',
    PREREQ_PM     => {
        'Lexical::SealRequireHints' => '0.010',
    },
    ABSTRACT_FROM => 'lib/Devel/Pragma.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    OPTIMIZE      => $OPTIMIZE,
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.8.1') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            resources => {
                repository => 'http://github.com/chocolateboy/Devel-Pragma',
                bugtracker => 'http://github.com/chocolateboy/Devel-Pragma/issues',
            },
        })
        : ()
    ),
);
