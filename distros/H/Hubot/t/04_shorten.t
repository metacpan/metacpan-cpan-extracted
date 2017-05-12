use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 7;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "shorten" ] );
$robot->adapter->interval(3);

push @{ $robot->{receive} },
  (
    'hubot help shorten',
    'https://www.google.com/',
    'https://github.com/aanoaa/p5-hubot/blob/master/lib/Hubot/Scripts/shorten.pm',
    'http://cafe.naver.com/cloudfrontier/3374',
  );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

SKIP: {
    skip "ENV [HUBOT_BITLY_USERNAME] and [HUBOT_BITLY_API_KEY] are required", 6
      if !$ENV{HUBOT_BITLY_USERNAME}
      or !$ENV{HUBOT_BITLY_API_KEY};
    $got = shift @{ $robot->{sent} } || [];
    ok( "@$got", "got response on https" );
    like( "@$got", qr/google/i,     'pick a title from google' );
    like( "@$got", qr/google\.com/, 'has link' );

    $got = shift @{ $robot->{sent} } || [];
    like( "@$got", qr/master/i, 'pick a title from github' );
    like( "@$got", qr/bit\.ly/, 'got shorten link' );

    $got = shift @{ $robot->{sent} } || [];
    like( "@$got", qr/naver/i, 'pick a title from naver' ); # charset: ksc5601
}
