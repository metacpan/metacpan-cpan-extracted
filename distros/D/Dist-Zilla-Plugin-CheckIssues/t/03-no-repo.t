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
    $meta->add_around_method_modifier(_github_issue_count => sub { } );
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ CheckIssues => { colour => 0, rt => 0, github => 1 } ],
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
        '[CheckIssues] failed to find a github repo in metadata',
    ],
    'no RT information found - reported as 0 issues',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
