#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use Path::Tiny;
use IPC::Open3 ();

BEGIN {
    my $have_git = eval {
        open my $null, '>', File::Spec->devnull or die;
        my $pid = IPC::Open3::open3(undef, '>&' . fileno($null), undef, 'git', '--version');
        waitpid $pid, 0;
        $? == 0;
    };
    plan skip_all => 'git is not available' unless $have_git;
}

use Dist::Zilla::Plugin::Docker::API;

# _git_capture feeds full_sha, short_sha and branch to the tag templates. It
# must work without the implicit fork of open('-|'), which Windows lacks.

my $capture = \&Dist::Zilla::Plugin::Docker::API::_git_capture;

# The repo is made without a global git config, so the test needs no identity
# and never reads the user's settings.
local $ENV{GIT_CONFIG_NOSYSTEM} = 1;
local $ENV{GIT_CONFIG_GLOBAL}   = File::Spec->devnull;
local $ENV{GIT_AUTHOR_NAME}     = 'T';
local $ENV{GIT_AUTHOR_EMAIL}    = 't@example.invalid';
local $ENV{GIT_COMMITTER_NAME}  = 'T';
local $ENV{GIT_COMMITTER_EMAIL} = 't@example.invalid';

sub git { my $d = shift; system('git', '-C', "$d", @_) == 0 or die "git @_ failed" }

my $repo = Path::Tiny->tempdir;
{
    open my $null, '>', File::Spec->devnull or die;
    open my $oldout, '>&', \*STDOUT or die;
    open STDOUT, '>&', $null or die;
    git($repo, 'init', '-q');
    git($repo, 'checkout', '-q', '-b', 'probe-branch');
    $repo->child('f')->spew("x\n");
    git($repo, 'add', 'f');
    git($repo, 'commit', '-q', '-m', 'one');
    open STDOUT, '>&', $oldout or die;
}

my $sha = $capture->("$repo", 'rev-parse', 'HEAD');
like $sha, qr/\A[a-f0-9]{40}\z/, 'rev-parse HEAD gives the full sha, no line ending';
is $capture->("$repo", 'rev-parse', '--abbrev-ref', 'HEAD'), 'probe-branch',
    'the branch name comes back';

my $plain = Path::Tiny->tempdir;
{
    local $ENV{GIT_CEILING_DIRECTORIES} = $plain->parent->stringify;
    is $capture->("$plain", 'rev-parse', 'HEAD'), '', 'no repository gives the empty string';
}
is $capture->("$repo/does-not-exist", 'rev-parse', 'HEAD'), '',
    'a missing directory gives the empty string';
is $capture->("$repo", 'no-such-subcommand'), '', 'a failing git gives the empty string';

# Windows has no fork: the capture must use the list form of a piped open.
my $src = path($INC{'Dist/Zilla/Plugin/Docker/API.pm'})->slurp_utf8;
my ($body) = $src =~ /(sub _git_capture \{.*?\n\})/s;
ok $body, 'found _git_capture in the source';
unlike $body, qr/open\s*\(?\s*my\s+\$\w+\s*,\s*['"]-\|['"]\s*\)/, 'no implicit-fork open';
unlike $body, qr{/dev/null}, 'no hard-coded /dev/null';

done_testing;
