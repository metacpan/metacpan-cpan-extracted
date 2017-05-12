use Test::More tests => 3;

use strict;
use warnings;

use HTTP::OAI;

my $ha = HTTP::OAI::Harvester->new( baseURL => 'file:///' );

ok(defined $ha);

my $r = "HTTP::OAI::GetRecord"->new(
	harvestAgent => $ha,
	resume => $ha->resume,
);

$HTTP::OAI::UserAgent::SILENT_BAD_CHARS = 1;

$r = $ha->request(
	HTTP::Request->new( GET => 'file:examples/badbytes.xml' ),
	undef, # arg
	undef, # size
	undef, # previous
	$r
);

ok($r->is_success);

ok(1);
