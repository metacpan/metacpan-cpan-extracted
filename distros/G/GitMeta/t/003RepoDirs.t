######################################################################
# Test suite for Git::Meta
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Cwd;
use Test::More;
use GitMeta::GMF;

my $gm = GitMeta::GMF->new();

plan tests => 3;

is $gm->repo_dir_from_git_url( 'foo@bar.com:get.git' ), "get";
is $gm->repo_dir_from_git_url( 'foo@bar.com:baz/get.git' ), "get";

is $gm->repo_dir_from_git_url( 'foo@bar.com:baz/get' ), "get";
