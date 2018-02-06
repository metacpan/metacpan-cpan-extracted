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
int foo() {
 asm();
 asm ("fsinx %1,%0" : "=f" (result) : "f" (angle));
  asm ("fsinx %[angle],%[output]"
          : [output] "=f" (result)
          : [angle] "f" (angle));
 asm ("combine %2,%0" : "=r" (foo) : "0" (foo), "g" (bar));
 asm ("combine %2,%0" : "=r" (foo) : "r" (foo), "g" (bar));
 asm ("cmoveq %1,%2,%[result]"
          : [result] "=r"(result)
          : "r" (test), "r"(new), "[result]"(old));
 asm ("sysint" : "=r" (result) : "0" (p1), "r" (p2));
 asm volatile ("movc3 %0,%1,%2"
                   : /* no outputs */
                   : "g" (from), "g" (to), "g" (count)
                   : "r0", "r1", "r2", "r3", "r4", "r5");

 return 0;
}

int frob(int x)
{
    int y;
    asm goto ("frob %%r5, %1; jc %l[error]; mov (%2), %%r5"
	      : : "r"(x), "r"(&y) : "r5", "memory" : error);
    return y;
 error:
    return -1;
}

void doit(void)
{
  int i = 0;
  asm goto ("mfsr %%r1, 123; jmp %%r1;"
	    ".pushsection doit_table;"
	    ".long %l0, %l1, %l2, %l3;"
	    ".popsection"
	    : : : "r1" : label1, label2, label3, label4);
  __builtin_unreachable ();

 label1:
  f1();
  return;
 label2:
  f2();
  return;
 label3:
  i = 1;
 label4:
  f3(i);
}

int foo ()
{
  int x = 42;
  int *y = &x;
  int result;
  asm ("magic stuff accessing an 'int' pointed to by '%1'"
       : "=&d" (r) : "a" (y), "m" (*y));
  return result;
}

static inline char * strcpy(char * dest,const char *src)
{
  int d0, d1, d2;
  __asm__ __volatile__(  "1:\tlodsb\n\t"
			 "stosb\n\t"
			 "testb %%al,%%al\n\t"
			 "jne 1b"
			 : "=&S" (d0), "=&D" (d1), "=&a" (d2)
			 : "0" (src),"1" (dest)
			 : "memory");
  return dest;
}

unsigned char _bittest(const long *Base, long Offset) { unsigned char old; __asm__ ("bt{" "l" " %[Offset],%[Base] | %[Base],%[Offset]}" : [old] "=@ccc" (old) : [Offset] "I" "r" (Offset), [Base] "rm" (*Base) : ); return old; }
