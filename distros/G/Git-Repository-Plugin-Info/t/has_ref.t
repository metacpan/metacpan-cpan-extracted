use strict;
use warnings;

use File::Spec qw();
use IO::File qw();

use Git::Repository qw(Info);
use Test::Git qw(test_repository);
use Test::Requires::Git;

use Test::More;

test_requires_git();
plan tests => 4;

do {
    my $repo = test_repository();
    $repo->run('config', 'user.name', 'Nathaniel Nutter');
    $repo->run('config', 'user.email', 'nnutter@cpan.org');
    commit_readme($repo);

    subtest 'branch does not exist yet' => sub {
        plan tests => 3;
        ok(!$repo->has_ref('refs/heads/other_branch'), q(has_ref('refs/heads/other_branch') is false));
        ok(!$repo->has_branch('refs/heads/other_branch'), q(has_branch('refs/heads/other_branch') is false));
        ok(!$repo->has_branch('other_branch'), q(has_branch('other_branch') is false));
    };
    $repo->run('branch', 'other_branch');
    subtest 'branch does exist now' => sub {
        plan tests => 3;
        ok($repo->has_ref('refs/heads/other_branch'), q(has_ref('refs/heads/other_branch') is true));
        ok($repo->has_branch('refs/heads/other_branch'), q(has_branch('refs/heads/other_branch') is true));
        ok($repo->has_branch('other_branch'), q(has_branch('other_branch') is true));
    };

    subtest 'tag does not exist yet' => sub {
        plan tests => 3;
        ok(!$repo->has_ref('refs/tags/other_tag'), q(has_ref('refs/tags/other_tag') is false));
        ok(!$repo->has_tag('refs/tags/other_tag'), q(has_tag('refs/tags/other_tag') is false));
        ok(!$repo->has_tag('other_tag'), q(has_tag('other_tag') is false));
    };
    $repo->run('tag', 'other_tag', '-m', '');
    subtest 'tag does exist now' => sub {
        plan tests => 3;
        ok($repo->has_ref('refs/tags/other_tag'), q(has_ref('refs/tags/other_tag') is true));
        ok($repo->has_tag('refs/tags/other_tag'), q(has_tag('refs/tags/other_tag') is true));
        ok($repo->has_tag('other_tag'), q(has_tag('other_tag') is true));
    };
};

sub commit_readme {
    my $repo = shift;

    my $readme_path = File::Spec->join($repo->work_tree, 'README.md');
    my $readme = IO::File->new($readme_path, 'w');
    $readme->print("Hello world.");
    $readme->close();

    $repo->run('add', $readme_path);
    $repo->run('commit', '-m', 'add README.md');
}
