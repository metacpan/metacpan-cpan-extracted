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
typedef struct x
{
   long (__attribute__((__stdcall__)) *a)(
        long b,
        short (__attribute__((__stdcall__)) *c)(unsigned long *d));
   /* bug here, scope was not correctly closed... */
} x_t;
/* then the typedef x_t was not available afterwards */
typedef struct y {
  x_t t;
};
