use utf8;
use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 1;

my $robot = Hubot::Robot->new(
    {   adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "backup" ] );

push @{ $robot->{receive} }, ('hubot help backup');

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );
