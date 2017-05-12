use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 4;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "googleImage" ] );
$robot->adapter->interval(3);

push @{ $robot->{receive} },
  (
    'hubot help image',
    "hubot image psy",
    "hubot animate psy",
    "hubot mustache psy",
  );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/http/, 'got image url from query' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/http/, 'got gif url from query' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/http/, 'got mutache url from query' );
