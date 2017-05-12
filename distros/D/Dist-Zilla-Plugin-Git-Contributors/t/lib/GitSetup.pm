use strict;
use warnings;
package GitSetup;

use Test::More;
use Git::Wrapper;
use Sort::Versions;
use Path::Tiny;

use Exporter 5.57 'import';
our @EXPORT = qw(no_git_tempdir git_wrapper);

$ENV{HOME} = Path::Tiny->tempdir->stringify;

# provides a temp directory that is guaranteed to not be inside a git repository
sub no_git_tempdir
{
    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    mkdir $tempdir if not -d $tempdir;    # FIXME: File::Temp::newdir doesn't make the directory?!

    {
        my $in_git;
        my $dir = $tempdir;
        my $count = 0;
        while (not $dir->is_rootdir) {
            # this should never happen.
            do { diag "failed to detect that $dir is at the root?!"; last } if $dir eq $dir->parent;

            my $checkdir = path($dir, '.git');
            if (-d $checkdir) {
                note "found $checkdir in $tempdir";
                $in_git = 1;
                last;
            }
            $dir = $dir->parent;
        }
        continue {
            die "too many iterations when traversing $tempdir!"
                if $count++ > 100;
        }

        ok(!$in_git, 'tempdir is not in a real git repository');
    }

    return $tempdir;
}

# adds --no-verify to all 'git commit' commands, to avoid triggering any
# globally-configured pre-commit hooks.
{
    package My::Git::Wrapper;
    use parent 'Git::Wrapper';

    sub commit {
        return shift->RUN(commit => @_, { 'no-verify' => 1 });
    }
}

# does some preliminary setup of the test Git::Wrapper object
# and a sanity check
sub git_wrapper
{
    my $root = shift;
    my $config = shift || {};

    diag 'testing with git repo ' . $root;

    my $git = My::Git::Wrapper->new($root);
    my $version = $git->version;
    my $err = $git->ERR;
    diag explain @$err if @$err;

    diag 'Testing with git version: ' . $version;
    plan skip_all => "Need git v1.5.0 for 'config' subcommand" if versioncmp($version, '1.5.0') < 0;

    plan skip_all => 'Need mysysgit v1.7.10 for proper unicode support on windows (https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support)'
        if $^O eq 'MSWin32' and versioncmp($version, '1.7.10') < 0;

    $git->init;
    $err = $git->ERR;
    diag explain @$err if @$err;

    # allow overriding configs, or skipping entirely
    if (not exists $config->{setup_user} or $config->{setup_user}) {
        $git->config('user.name', $config->{'user.name'} || 'Test User');
        $git->config('user.email', $config->{'user.email'} || 'test@example.com');
    }

    # see https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support
    # and http://ox.no/posts/how-to-combine-git-windows-and-non-ascii-letters
    if ($^O eq 'MSWin32')
    {
        $git->config('i18n.logoutputencoding', 'utf-8');
        $git->config('i18n.commitencoding', 'utf-8');
        $ENV{LESSCHARSET} = 'utf-8';
    }

    $git;
}

1;
