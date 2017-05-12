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
struct s
{
    int   x;
    float y;
    char  *z;
} tee;
struct s r;
void func() {
  tee.y;
  struct s *ptr_to_tee = &tee;
  (*ptr_to_tee).y;
  ptr_to_tee->y;
  tee.x = 74;
  ptr_to_tee->x = 74;
}
