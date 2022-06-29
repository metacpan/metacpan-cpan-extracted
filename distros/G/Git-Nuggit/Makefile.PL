use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Git::Nuggit',
    AUTHOR       => [q{Chris Monaco <chris.monaco@jhuapl.edu>}, q{David Edell <david.edell@jhuapl.edu>} ],
    VERSION_FROM => 'lib/Git/Nuggit.pm',
    ABSTRACT     => 'Git Toolkit for Submodule-Aware workflows',
              ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
              EXE_FILES  => [
                             'bin/ngt',
                             'bin/list_all_submodules.pl',
                             'bin/nuggit_add.pl',
                             'bin/nuggit_branch.pl',
                             'bin/nuggit_clone.pl',
                             'bin/nuggit_commit.pl',
                             'bin/nuggit_diff.pl',
                             'bin/nuggit_fetch.pl',
                             'bin/nuggit_foreach.pl',
                             'bin/nuggit_history.pl',
                             'bin/nuggit_init.pl',
			     'bin/nuggit_log.pl',
                             'bin/nuggit_merge_tree.pl',
                             'bin/nuggit_ops.pl',
                             'bin/nuggit_mv.pl',
                             'bin/nuggit_push.pl',
                             'bin/nuggit_reset.pl',
                             'bin/nuggit_rm.pl',
                             'bin/nuggit_status.pl',
                            ],
    MAN1PODS => {
        # All other man pages will be installed under the full nuggit name
        'docs/index.pod'      => 'blib/man1/ngt.1',
        
        'docs/index.pod'         => 'blib/man1/nuggit.1',
        'docs/alias.pod'         => 'blib/man1/nuggit-alias.1',
        'docs/rebase.pod'        => 'blib/man1/nuggit-rebase.1',
        'docs/checkout.pod'      => 'blib/man1/nuggit-checkout.1',
        'docs/merge.pod'         => 'blib/man1/nuggit-merge.1',
        'docs/merge-tree.pod'    => 'blib/man1/nuggit_tree.1',
        'bin/nuggit_ops.pl'      => 'blib/man1/nuggit-ops.1',
        'bin/nuggit_add.pl'      => 'blib/man1/nuggit-add.1',
        'bin/nuggit_branch.pl'   => 'blib/man1/nuggit-branch.1',
        'bin/nuggit_clone.pl'    => 'blib/man1/nuggit-clone.1',
        'bin/nuggit_commit.pl'   => 'blib/man1/nuggit-commit.1',
        'bin/nuggit_diff.pl'     => 'blib/man1/nuggit-diff.1',
        'bin/nuggit_fetch.pl'    => 'blib/man1/nuggit-fetch.1',
        'bin/nuggit_foreach.pl'  => 'blib/man1/nuggit-foreach.1',
        'bin/nuggit_history.pl'  => 'blib/man1/nuggit-history.1',
        'bin/nuggit_init.pl'     => 'blib/man1/nuggit-init.1',
        'bin/nuggit_log.pl'      => 'blib/man1/nuggit-log.1',
        'bin/nuggit_mv.pl'       => 'blib/man1/nuggit-mv.1',
        'bin/nuggit_push.pl'     => 'blib/man1/nuggit-push.1',
        'bin/nuggit_reset.pl'    => 'blib/man1/nuggit-reset.1',
        'bin/nuggit_rm.pl'       => 'blib/man1/nuggit-rm.1',
        'bin/nuggit_status.pl'   => 'blib/man1/nuggit-status.1',

        # Other help pages
        'docs/intro.pod'         => 'blib/man1/nuggit-intro.1',

    },
    PREREQ_PM => {
                  'FindBin'      => 0,
                  'Getopt::Long' => 0,
                  'IPC::Run3'    => 0,
                  'Term::ANSIColor' => 4,
                  'Complete::File' => 0,
                  'Complete::Bash' => 0,
                  'IO::Page' => 0,
                  'JSON' => 0,
                  'File::Slurp'     => 0,
                  'File::Spec'      => 0
                 },
    TEST_REQUIRES => {
        'Test::Compile'             => 0,
        'Test2::V0'                 => 0,
        'Test2::Plugin::BailOnFail' => 0,
                      'File::pushd'     => 0,
                     },
              test => {TESTS => 'test/*.t'}
             );
