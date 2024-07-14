use strict;
use warnings;

use Test::More;
use KelpX::Symbiosis::Test;
use HTTP::Request::Common;
use lib 't/lib';
use CountingApp;

my $app = CountingApp->new(mode => 'none_mounted');
my $t = KelpX::Symbiosis::Test->wrap(app => $app);

$t->request(GET "/kelp")
	->code_is(200);

$t->request(GET "/also-kelp")
	->code_is(200);

is $app->get_count, 1, 'run count ok';

done_testing;

