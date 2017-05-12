#!perl

use Test::More qw(no_plan);
use Test::Exception;
use IO::File;

use JSPL;
my $rt1 = JSPL::Runtime->new;
{
my $ctx;
$ctx = $rt1->create_context;
is($ctx->eval_file('t/sample1.js'), 'Hello World', "Eval file");
}
{
my $ctx = $rt1->create_context;
throws_ok  { $ctx->eval_file('t/notfound.js') } qr/can't open/, "Not found";
throws_ok  { $ctx->eval_file('t/error.js') } qr/illegal character/, "error";
}
{
my $ctx = $rt1->create_context;
my $fh = IO::File->new("< t/sample1.js") or die "Can't open";
is($ctx->eval($fh, 't/sample1.js'), 'Hello World', "Eval FH");
}

