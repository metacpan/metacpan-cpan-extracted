use warnings;
use strict;

use Capture::Tiny qw(:all);
use Mock::Sub;
use Test::More;
use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr qw(:private);
use File::Touch;
use version;

BEGIN {
    # DIST_MGR_REPO_DIR eg. /home/spek/repos

    if (!$ENV{DIST_MGR_GIT_TEST} || !$ENV{DIST_MGR_REPO_DIR}) {
        plan skip_all => "DIST_MGR_GIT_TEST and DIST_MGR_REPO_DIR env vars must be set";
    }
}

use lib 't/lib';
use Helper qw(:all);

my $repos = $ENV{DIST_MGR_REPO_DIR};
my $repo  = 'test-push';
my $repo_dir = "$repos/$repo";

my $cwd = getcwd();
like $cwd, qr/dist-mgr$/, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr$/;

chdir $repos or die "Can't change into 'repos' dir $repos: $!";
is getcwd(), $repos, "in repos dir ok";
croak "not in the 'repos' dir!" if getcwd() ne $repos;

my $git_ok = _validate_git();

# validate git installed, exit if not
{
    if (! $git_ok) {
        done_testing;
        exit;
    }
}

# clone our test repo
{
    if (! -e 'test-push') {
        capture_merged {
            `git clone 'https://stevieb9\@github.com/stevieb9/test-push'`;
        };
        is $?, 0, "git cloned 'test-push' test repo ok";
    }
}

# git_release
{
    chdir $repo_dir or die $!;
    is getcwd(), $repo_dir, "in test-push repo dir ok";
    croak "not in the test-push repo dir!" if getcwd() ne $repo_dir;

    is eval { git_release(); 1 }, undef, "git_release() requires a version ok";
    like $@, qr/requires a version/, "...and error is sane";

    capture_merged {
        git_release(0.01, 0); # 0 == don't wait for CI tests to run
    };
}

chdir $cwd or die $!;
like getcwd(), qr/dist-mgr$/, "back in root dir ok";

remove_init();

done_testing;
