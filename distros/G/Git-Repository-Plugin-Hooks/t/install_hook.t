use strict;
use warnings;

use File::Temp qw();

use Test::Git qw(test_repository);
use Test::Requires::Git;
use Git::Repository qw(Hooks);

use Test::More;

test_requires_git();
plan tests => 3;

my $repo = test_repository();

my $source = File::Temp->new();

my $hook = $repo->hook_path('post-receive');

ok(! -e $hook, 'post-receive hook should not exist yet');
$repo->install_hook($source, 'post-receive');
ok(-e $hook, 'post-receive hook exist after install');
ok(-x $hook, 'post-receive hook is executable');
