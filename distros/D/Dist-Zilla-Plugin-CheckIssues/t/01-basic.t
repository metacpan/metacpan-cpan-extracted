use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use NoNetworkHits;

{
    use Dist::Zilla::Plugin::CheckIssues;
    my $meta = find_meta('Dist::Zilla::Plugin::CheckIssues');
    $meta->make_mutable;

    # data copied from Moose stats
    $meta->add_around_method_modifier(_rt_data_raw => sub { '{"Foo-Bar":{"dist":"Foo-Bar","counts":{"rejected":0,"inactive":1,"active":0,"resolved":1,"patched":0,"open":0,"stalled":0,"new":0}},"DZT-Sample":{"dist":"DZT-Sample","counts":{"rejected":47,"inactive":207,"active":52,"resolved":160,"patched":0,"deleted":108,"open":39,"stalled":4,"new":9}}}' });
    $meta->add_around_method_modifier(_github_issue_count => sub { 3 });
}

my $repo = 'github.com/dude/project';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaResources => { 'repository.url' => 'git://' . $repo . '.git' } ],
                [ CheckIssues => { colour => 0 } ],
                [ FakeRelease => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'release proceeds normally',
);

cmp_deeply(
    [ grep { /^\[CheckIssues\]/ } @{ $tzil->log_messages } ],
    [
        '[CheckIssues] getting issue data for git://' . $repo . '.git...',
        '[CheckIssues] Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample):',
        '[CheckIssues]   open: 48   stalled: 4',
        '[CheckIssues] Issues on github (https://' . $repo . '):',
        '[CheckIssues]   open: 3',
    ],
    'bug information correctly printed',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
