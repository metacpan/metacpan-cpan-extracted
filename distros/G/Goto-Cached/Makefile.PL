use 5.008008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;
  
our $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall -W';
    $OPTIMIZE .= ' -g -Wextra -Wdeclaration-after-statement' if (-f '.dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

our %XS_PREREQUISITES = (
    'B::Hooks::OP::Check'      => '0.18',
    'B::Hooks::OP::Annotation' => '0.43',
);

our %XS_DEPENDENCIES = ExtUtils::Depends->new('Goto-Cached', keys(%XS_PREREQUISITES))->get_makefile_vars();

# version.pm is core from 5.9 and is a common dependency.
# ExtUtils::MakeMaker::VERSION can contain an underscore (the stock version on Ubuntu 10.04 is 6.55_02)
# which makes >= complain; use version.pm to avoid this where available
our $MAKE_MAKER_VERSION = eval "use version; version->can('parse')" ?
    version->parse($ExtUtils::MakeMaker::VERSION) :
    $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME          => 'Goto::Cached',
    VERSION_FROM  => 'lib/Goto/Cached.pm',
    PREREQ_PM => {
        %XS_PREREQUISITES,
        'Devel::Pragma'        => '0.54',
        'B::Hooks::EndOfScope' => '0.09',
      },
    ABSTRACT_FROM => 'lib/Goto/Cached.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    OPTIMIZE      => $OPTIMIZE,
    ($MAKE_MAKER_VERSION >= 6.46 ?
        (META_MERGE => {
            configure_requires => {
                'ExtUtils::Depends' => '0.302',
                %XS_PREREQUISITES
            },
            resources => {
                repository => 'http://github.com/chocolateboy/Goto-Cached',
            },
        })
        : ()
    ),
    ($MAKE_MAKER_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    %XS_DEPENDENCIES,
);
