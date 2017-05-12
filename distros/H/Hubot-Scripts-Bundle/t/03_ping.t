use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 3;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "ping" ] );

push @{ $robot->{receive} }, ( 'hubot help ping', 'hubot ping', 'hubot die', );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/pong/i, 'got pong' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/goodbye/i, 'die message' );
