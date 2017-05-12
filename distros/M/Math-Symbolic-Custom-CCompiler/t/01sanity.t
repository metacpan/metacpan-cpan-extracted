use Test::More tests => 4;
use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::CCompiler;
ok(1); 

my $f = parse_from_string('a*b+c');

ok(1);

$f->to_c();

ok(1);

$f->to_compiled_c();

ok(1);

