use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 2;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "uptime" ] );

push @{ $robot->{receive} }, ( 'hubot help uptime', 'hubot uptime', );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/I've been sentient for 0 years/, 'got uptime' );
