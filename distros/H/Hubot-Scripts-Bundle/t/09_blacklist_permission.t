use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 1;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "blacklist" ] );

push @{ $robot->{receive} }, ( 'hubot blacklist add hshong', );

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
like( "@$got", qr/no managers/, 'no managers' );
