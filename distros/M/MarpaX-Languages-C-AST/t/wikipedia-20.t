#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}
use MarpaX::Languages::C::AST::Expected;

my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my $valuep = $cAst->parse(\$cSourceCode)->value();
ok(defined($valuep), 'Output from parse()->value() is ok');

__DATA__
void func() {
  int* ptr;
  ptr = (int[]){ 10, 20, 30, 40 };
  struct s pi;
  pi = (struct s){ 3, 3.1415, "Pi" };
  pi = (struct s){ .z = "Pi", .x = 3, .y = 3.1415 };
}

