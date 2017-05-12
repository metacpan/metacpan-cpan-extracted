use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 2;

my $robot = Hubot::Robot->new({adapter => 'helper', name => 'hubot'});

$robot->loadHubotScripts(["help", "githubIssue"]);

push @{$robot->{receive}}, ('hubot help GitHub', 'aanoaa/p5-hubot#10');

$robot->run;

my $got;
$got = shift @{$robot->{sent}};
ok("@$got", 'containing help messages');

$got = shift @{$robot->{sent}};
like("@$got", qr/Issue/i, 'got issue link');
