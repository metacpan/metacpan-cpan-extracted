use utf8;
use strict;
use warnings;
use Hubot::Robot;
use lib 't/lib';
use Test::More tests => 10;

require_ok('Hubot::Scripts::sayhttpd');

my $robot = Hubot::Robot->new({
	adapter => 'helper',
	name    => 'hubot'
	});

$robot->loadHubotScripts( [ "help", "sayhttpd" ] );

use Hubot::Scripts::sayhttpd;

my $helper = Hubot::Scripts::sayhttpd::helper->new();
isa_ok($helper, "Hubot::Scripts::sayhttpd::helper");

is($helper->checkSecret(""), undef, "Return False, missing ENV");
undef $helper;

$ENV{HUBOT_SAY_HTTP_SECRET} = "bar";
$helper = Hubot::Scripts::sayhttpd::helper->new();

is($helper->checkSecret(""), undef, "Return False, missing secret");

is($helper->checkSecret("foo"), undef, "Return False, wrong secret");

is($helper->checkSecret("bar"), 1, "Return 1, secret OK");

is($helper->checkRoom(""), undef, "Return False, missing room");

is($helper->checkRoom("#foobar"), 1, "Return 1, room OK");

is($helper->checkMessage(""), undef, "Return False, missing message");

is($helper->checkMessage("Hello John Doe"), 1, "Return 1, message OK");
