use warnings;
use strict;

use Capture::Tiny qw(:all);
use Mock::Sub;
use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr qw(:private);
use File::Touch;
use Hook::Output::Tiny;
use Test::More;
use version;

BEGIN {
    # DIST_MGR_REPO_DIR eg. /home/spek/repos

    if (!$ENV{DIST_MGR_GIT_TEST} || !$ENV{DIST_MGR_REPO_DIR}) {
        plan skip_all => "DIST_MGR_GIT_TEST and DIST_MGR_REPO_DIR env vars must be set";
    }
}

use lib 't/lib';
use Helper qw(:all);

my $h = Hook::Output::Tiny->new;

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
            `git clone 'https://stevieb9\@github.com/stevieb9/test-push`;
        }
        is $?, 0, "git cloned 'test-push' test repo ok";
    }
}

# git commit
{
    chdir $repo_dir or die $!;
    is getcwd(), $repo_dir, "in test-push repo dir ok";
    croak "not in the test-push repo dir!" if getcwd() ne $repo_dir;

    open my $fh, '>', 'Dist-Mgr.txt' or die $!;
    my $random = rand() + rand() * rand() * 10;
    print $fh $random;
    close $fh;

    capture_merged {
        git_commit('0.01');
    };

    is defined $?, 1, "commit exit code defined ok";
    is $? == 256 || $? == 0, 1, "git_commit() exited with success status ok";
}

# git push
{

    capture_merged {
        git_push();
    };

    is defined $?, 1, "push exit code defined ok";
    is $? == 0, 1, "git_push() exited with success status ok";
}

chdir $cwd or die $!;
like getcwd(), qr/dist-mgr$/, "back in root dir ok";

done_testing;
