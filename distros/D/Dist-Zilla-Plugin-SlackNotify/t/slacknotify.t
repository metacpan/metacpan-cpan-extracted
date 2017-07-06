use strict;
use warnings;
use Test::More tests => 1;

use Test::DZil;

my %conf;

# Set environment variables to test SlackNotify
$conf{SlackNotify}{webhook_url} = $ENV{TEST_SLACKNOTIFY_WEBHOOK_URL}
    || die "Please set TEST_SLACKNOTIFY_WEBHOOK_URL environment variable to test\n";
$conf{SlackNotify}{username}    = $ENV{TEST_SLACKNOTIFY_USERNAME}
    if $ENV{TEST_SLACKNOTIFY_USERNAME};
$conf{SlackNotify}{icon_url}    = $ENV{TEST_SLACKNOTIFY_ICON_URL}
    if $ENV{TEST_SLACKNOTIFY_ICON_URL};
$conf{SlackNotify}{icon_emoji}  = $ENV{TEST_SLACKNOTIFY_ICON_EMOJI}
    if $ENV{TEST_SLACKNOTIFY_ICON_EMOJI};
$conf{SlackNotify}{message}     = $ENV{TEST_SLACKNOTIFY_MESSAGE}
    if $ENV{TEST_SLACKNOTIFY_MESSAGE};
$conf{SlackNotify}{channel}     = [ split( ',', $ENV{TEST_SLACKNOTIFY_CHANNEL} ) ]
    if $ENV{TEST_SLACKNOTIFY_CHANNEL};

my $tzil = Builder->from_config(
    { dist_root => 'corpus/John' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                {
                    author  => "JOHN",
                    name    => "John",
                    version => "3.16",
                 },
                'FakeRelease',
                [ %conf ],
            ),
        },
    },
);

$tzil->release;

pass( "Completed release" );

done_testing;
