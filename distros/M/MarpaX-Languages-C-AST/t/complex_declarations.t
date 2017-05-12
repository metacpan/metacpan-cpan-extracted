#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::AST' ) || print "Bail out!\n";
}

my $cSourceCode = do { local $/; <DATA> };
my $cAst = MarpaX::Languages::C::AST->new();
my $valuep = $cAst->parse(\$cSourceCode)->value();
ok(defined($valuep), 'Output from parse()->value() is ok');

__DATA__
/* http://msdn.microsoft.com/en-us/library/1x82y1z4.aspx */
char *( *(*var)() )[10];
int *var[5]; /* Array of pointers to int values */
int (*var)[5]; /* Pointer to array of int values */
long *var( long, long ); /* Function returning pointer to long */
long (*var)( long, long ); /* Pointer to function returning long */
struct both       /* Array of pointers to functions */
{                 /*   returning structures         */
    int a;
    char b;
} ( *var[5] )( struct both, struct both );
unsigned int *(* const *name[5][10] ) ( void );
double ( *var( double (*)[3] ) )[3];
union sign         /* Array of arrays of pointers */
{                  /* to pointers to unions       */
     int x;
     unsigned y;
} **var[5][5];
union sign *(*var[5])[5]; /* Array of pointers to arrays
                             of pointers to unions        */

/* http://www.java-samples.com/showtutorial.php?tutorialid=543 */
int *f();
int (*pf)();
char **argv;
int (*daytab)[13];
int *daytab[13];
void *comp();
void (*comp)();
char (*(*x())[])();
char (*(*x[3])())[5];

/* http://codinghighway.com/?p=986 */
char **(*(*(*x)[100])(int, char *, double *const**, void (*)(int **, char [])))[50];
unsigned const char volatile (*const(*volatile(*volatile const a)(unsigned int (*const)(const char, int, float), char *const*))[12])(int (**)[50]);
char *const *(*next)();
