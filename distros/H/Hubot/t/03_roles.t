use strict;
use warnings;
use Hubot::Robot;
use Hubot::User;
use lib 't/lib';
use Test::More tests => 9;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "roles" ] );
$robot->adapter->interval(0.2);
$robot->userForId( 'misskim', {} );    # for known user test

push @{ $robot->{receive} },
  (
    'hubot help user',
    'hubot who is ' . time,
    'hubot ' . time . ' is a dayfly',
    'hubot who is misskim',
    'hubot misskim is a dayfly',
    'hubot who is misskim',
    'hubot misskim is not a dayfly',
    'hubot who is misskim',
    'hubot who is ' . $robot->name,
  );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
like( "@$got", qr/badass guitarist/, '<robot> help roles' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/Never heard/, 'who is <unknown>' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/anything about/, 'assign a role to <unknown>' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/nothing to me/, 'who is <known>' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/is a dayfly/, 'give a role' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/is a dayfly/, 'got correct role' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/is no longer a dayfly/, 'drop a role' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/nothing to me/, 'who is <known> again after drop roles' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/The best/, 'who is hubot' );
