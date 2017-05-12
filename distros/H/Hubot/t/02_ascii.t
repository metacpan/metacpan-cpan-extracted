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

$robot->loadHubotScripts( [ "help", "ascii" ] );
$robot->adapter->interval(3);

push @{ $robot->{receive} }, 'hubot help ascii';
push @{ $robot->{receive} }, 'ascii hi';

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
like( "@$got", qr/ascii me/, 'correct help message' );
$got = shift @{ $robot->{sent} };
like( "@$got", qr/\| \|/, 'ascii art' );
