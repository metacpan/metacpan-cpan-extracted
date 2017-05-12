use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 2;

my $robot = Hubot::Robot->new(
    {   adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "tweet" ] );
$robot->adapter->interval(3);

push @{ $robot->{receive} },
    (
    'hubot help tweet',
    'https://twitter.com/saltfactory/status/263821902001369088',
    );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

SKIP: {
    skip "API v1 Retirement is Complete - Use API v1.1", 1
        if !$ENV{HUBOT_TWITTER_CONSUMER_KEY}
        or !$ENV{HUBOT_TWITTER_CONSUMER_SECRET};
    $got = shift @{ $robot->{sent} };
    like( "@$got", qr/Ruby/, 'has tweet content' );
}
