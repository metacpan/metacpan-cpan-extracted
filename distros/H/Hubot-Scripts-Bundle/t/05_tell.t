use strict;
use warnings;
use Hubot::Robot;
use Hubot::User;
use lib 't/lib';
use Test::More tests => 3;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "tell" ] );
$robot->adapter->interval(0.2);
$robot->userForId( 'misskim', {} );

push @{ $robot->{receive} },
  ( 'hubot help tell', 'hubot tell misskim hi', 'hubot tell aanoaa hi', );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/hi/, 'pass message directly if user exists' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/OK/, 'robot should respond to telling message' );

# TODO: should emit Hubot::EnterMessage
