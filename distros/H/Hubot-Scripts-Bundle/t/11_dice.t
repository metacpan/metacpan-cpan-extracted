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

$robot->loadHubotScripts( [ "help", "dice" ] );

push @{ $robot->{receive} }, ( 'hubot help dice', 'hubot dice', 'hubot dice 100' );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/\d+/, 'got number' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/\d+/, 'got number2' );
