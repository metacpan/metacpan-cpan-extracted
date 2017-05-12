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

my $rt_text = '{"Foo-Bar":{"dist":"Foo-Bar","counts":{"rejected":0,"inactive":1,"active":0,"resolved":1,"patched":0,"open":0,"stalled":0,"new":0}}}';

{
    use Dist::Zilla::Plugin::CheckIssues;
    my $meta = find_meta('Dist::Zilla::Plugin::CheckIssues');
    $meta->make_mutable;
    $meta->add_around_method_modifier(_rt_data_raw => sub { $rt_text });
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ CheckIssues => { colour => 0, rt => 1, github => 0 } ],
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
        '[CheckIssues] Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample):',
        '[CheckIssues]   open: 0   stalled: 0',
    ],
    'no RT information found - reported as 0 issues',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
