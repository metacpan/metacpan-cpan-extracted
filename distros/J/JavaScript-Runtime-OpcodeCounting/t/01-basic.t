#!perl

use Test::More tests => 9;

use JavaScript;

BEGIN { use_ok('JavaScript::Runtime::OpcodeCounting'); }

my $runtime = JavaScript::Runtime->new(qw(-OpcodeCounting));

is($runtime->get_opcount(), 0, "Default number is 0");
is($runtime->get_opcount_limit(), 0, "Default limit is 0");

my $context = $runtime->create_context();

# Execute some code
$context->eval("1+1");

my $opcount = $runtime->get_opcount();

ok($opcount > 0, "A few opcodes have been executed");

$runtime->set_opcount(0);
is($runtime->get_opcount(), 0, "Resetting works");
$context->eval("1+1");
is($opcount, $runtime->get_opcount(), "Old opcount same as new");

$runtime->set_opcount_limit(100);
$context->eval("for(i = 0; i < 100; i++) {}");
ok($@);
isa_ok($@, "JavaScript::Error::OpcodeLimitExceeded");

$runtime->set_opcount(0);
$runtime->set_opcount_limit(0);

$context->eval("for(i = 0; i < 100; i++) {}");
ok(!defined $@);
