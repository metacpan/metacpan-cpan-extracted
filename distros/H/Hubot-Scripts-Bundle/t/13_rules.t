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

$robot->loadHubotScripts( [ "help", "rules" ] );

push @{ $robot->{receive} }, ( 'hubot help rules',
	'hubot the rules',
	'hubot the 3 rules');

$robot->run;

my $got;
$got = shift @{ $robot->{sent} };
like( "@$got", qr/make sure hubot still knows the rules/, "got help" );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/robot may not injure/i, 'got rules' );

$got = shift @{ $robot->{sent} };
like( "@$got", qr/protect its own existence as long as such protection/i, 'got rules' );
