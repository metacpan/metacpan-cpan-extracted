use strict;
use warnings;
use Hubot::Robot;
use Hubot::User;
use lib 't/lib';
use Test::More tests => 1;

my $robot = Hubot::Robot->new(
    {
        adapter => 'helper',
        name    => 'hubot'
    }
);

$robot->loadHubotScripts( [ "help", "bugzilla" ] );
push @{ $robot->{receive} }, 'hubot help bug';
$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
ok( "@$got", 'containing help messages' );
