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
void allocate_array(int ** const a_p, const int A) {
/*
 allocate array of A ints
 assigning to *a_p alters the 'a' in main()
*/
    *a_p = malloc(sizeof(int) * A);
}

int main(void) {
    int * a; /* create a pointer to one or more ints, this will be the array */

 /* pass the address of 'a' */
    allocate_array(&a, 42);

/* 'a' is now an array of length 42 and can be manipulated and freed here */

    free(a);
    return 0;
}
