use utf8;
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

$robot->loadHubotScripts( [ "help", "macboogi" ] );

push @{ $robot->{receive} },
  ( 'hubot help mac', 'use catalyst.mac', '안녕하세요.mac', );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/USE CATALYST/, 'converted lower to upper' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/아ㄴ녀ㅇ하세요/, 'hangul have been macboogified' );
