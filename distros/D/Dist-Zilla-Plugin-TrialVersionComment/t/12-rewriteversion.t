use strict;
use warnings;

use Test::Needs qw(Dist::Zilla::Plugin::RewriteVersion Dist::Zilla::Plugin::BumpVersionAfterRelease);

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

local $ENV{TRIAL} = 1;
local $ENV{RELEASE_STATUS} = 'testing';

my $original_content = <<'FOO';
package Foo;
our $VERSION = '0.001';
# TRIAL comment will be added above
1;
FOO

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                {   # use as root section
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    # no version here
                    author   => 'E. Xavier Ample <example@example.org>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                    is_trial => 1,
                },
                [ GatherDir => ],
                [ RewriteVersion => ],      # version provider and file munger
                #[ 'TrialVersionComment' ], # not needed
            ),
            path(qw(source lib Foo.pm)) => $original_content,
        },
    },
);

my $assign_re =
    eval { Dist::Zilla::Plugin::BumpVersionAfterRelease::_Util->assign_re }
        ||
    do {
        require PadWalker;
        my ($bumpversion_closures) = PadWalker::closed_over(\&Dist::Zilla::Plugin::BumpVersionAfterRelease::rewrite_version);
        ${$bumpversion_closures->{'$assign_regex'}};
    };

like(
    $original_content,
    $assign_re,
    '$VERSION declaration is something that [BumpVersionAfterRelease] will recognize',
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

ok($tzil->is_trial, 'trial flag is set on the distribution');

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
    $content,
    qr/^our \$VERSION = '0\.001'; # TRIAL$/m,
    'TRIAL comment added to $VERSION assignment by [RewriteVersion]',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
