#!perl
use Test::More;
use Test::Exception;

use strict;
use warnings;

use JSPL;
my $cx1 = JSPL::Runtime->new->create_context();
if(!JSPL::does_support_opcb) {
    plan tests => 3;
} else {
    plan tests => 1;
    throws_ok {
	$cx1->set_branch_handler(\&branch_handler);
    } qr/not available/, 'Not available';
    exit(0);
}

my $called = 0;
sub branch_handler {
    $called++;
    return 1;
}


$cx1->eval("for(i = 0; i < 10; i++) {}");
is($called, 0);

$cx1->set_branch_handler(\&branch_handler);
$cx1->eval("for(i = 0; i < 10; i++) {}");
is($called, 10);

$cx1->set_branch_handler(undef);
$called = 0;
$cx1->eval("for(i = 0; i < 10; i++) {}");
is($called, 0);

