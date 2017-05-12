use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 6;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "blacklist" ] );

$ENV{HUBOT_BLACKLIST_MANAGER} = 'helper';

push @{ $robot->{receive} },
  (
    'hubot help blacklist',
    'hubot blacklist add hshong',
    'hubot blacklist',
    'hubot blacklist del 0',
    'hubot blacklist subscribe',
    'hubot blacklist unsubscribe',
  );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/OK, added/, 'add blacklist' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/hshong/, 'contained added pattern in blacklist' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/Deleted/, 'delete blacklist <index>' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/subscribe/, 'subscribe blacklist' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/unsubscribe/, 'unsubscribe blacklist' );
