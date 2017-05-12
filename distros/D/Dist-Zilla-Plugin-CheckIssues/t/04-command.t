use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Dist::Zilla::App::Tester;
use Path::Tiny;
use File::pushd 'pushd';
use Moose::Util 'find_meta';
use Dist::Zilla::App::Command::issues;  # load this now, before we change directories

use lib 't/lib';
use NoNetworkHits;

{
    use Dist::Zilla::Plugin::CheckIssues;
    my $meta = find_meta('Dist::Zilla::Plugin::CheckIssues');
    $meta->make_mutable;

    # data copied from Moose stats
    $meta->add_around_method_modifier(_rt_data_raw => sub { '{"Foo-Bar":{"dist":"Foo-Bar","counts":{"rejected":0,"inactive":1,"active":0,"resolved":1,"patched":0,"open":0,"stalled":0,"new":0}},"DZT-Sample":{"dist":"DZT-Sample","counts":{"rejected":47,"inactive":207,"active":52,"resolved":160,"patched":0,"deleted":108,"open":39,"stalled":4,"new":9}}}' });
    $meta->add_around_method_modifier(_github_issue_count => sub {
        my ($orig, $self, $owner_name, $repo_name) = @_;

        return 3 if $owner_name eq 'dude' and $repo_name eq 'project';
        return 5 if $owner_name eq 'anonymous' and $repo_name eq 'junk';
        die "no info found for $owner_name/$repo_name";
    });
}

{
    package inc::FatalMetadata;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider';

    sub metadata { die "oops, all plugins' metadata methods are being called" }
}

{
    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = 'does-not-exist';

    # TODO: we should be able to call a sub that specifies our corpus layout
    # including dist.ini, rather than having to build it ourselves, here.
    # This would also help us improve the tests for the 'authordeps' command.

    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    my $root = $tempdir->child('source');
    $root->mkpath;
    my $wd = pushd $root;

    path($root, 'dist.ini')->spew_utf8(
        simple_ini(
            [ GatherDir => ],
            [ '=inc::FatalMetadata' ],
            [ MetaResources => { 'repository.url' => 'git://github.com/dude/project.git' } ],
        )
    );

    my $result = test_dzil('.', [ 'issues', '--nocolour' ]);

    my $zilla = $result->app->zilla;
    ok(!$zilla->built_in, 'the dist was not fully built just to print issues');
    is($zilla->{distmeta}, undef, 'distmeta builder never ran');

    is($result->exit_code, 0, 'dzil would have exited 0');
    is($result->error, undef, 'no errors');
    is(
        $result->stdout,
        join("\n",
            'Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample):',
            '  open: 48   stalled: 4',
            'Issues on github (https://github.com/dude/project):',
            '  open: 3',
            ''
        ),
        'RT and github issues printed',
    );

    diag 'got stderr output: ' . $result->stderr
        if $result->stderr;

    diag 'got result: ', explain $result
        if not Test::Builder->new->is_passing;
}

{
    local $ENV{DZIL_GLOBAL_CONFIG_ROOT} = 'does-not-exist';

    # TODO: we should be able to call a sub that specifies our corpus layout
    # including dist.ini, rather than having to build it ourselves, here.
    # This would also help us improve the tests for the 'authordeps' command.

    my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
    my $root = $tempdir->child('source');
    $root->mkpath;
    my $wd = pushd $root;

    path($root, 'dist.ini')->spew_utf8(
        simple_ini(
            [ GatherDir => ],
            [ '=inc::FatalMetadata' ],
        )
    );

    my $result = test_dzil('.', [ 'issues', '--nocolour', '--repo', 'http://github.com/anonymous/junk.git' ]);

    my $zilla = $result->app->zilla;
    ok(!$zilla->built_in, 'the dist was not fully built just to print issues');
    is($zilla->{distmeta}, undef, 'distmeta builder never ran');

    is($result->exit_code, 0, 'dzil would have exited 0');
    is($result->error, undef, 'no errors');
    is(
        $result->output,
        join("\n",
            'Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample):',
            '  open: 48   stalled: 4',
            'Issues on github (https://github.com/anonymous/junk):',
            '  open: 5',
            ''
        ),
        'RT and github issues printed',
    );

    diag 'got result: ', explain $result
        if not Test::Builder->new->is_passing;
}
done_testing;
