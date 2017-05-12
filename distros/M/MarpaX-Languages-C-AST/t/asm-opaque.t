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
int func() {
  __asm int 3
  __asm {
    mov al, 2
    mov dx, 0xD007
    out dx, al
  }
  __asm mov al, 2
  __asm mov dx, 0xD007
  __asm out dx, al
  __asm mov al, 2   __asm mov dx, 0xD007   __asm out dx, al
  __asm {
    ; Comment 1 }
    /* Comment 2 } */
    // Comment 3 }
    COMMENT } anything }
    COMMENT } anything
    again
    and again } and etc...
    COMMENT & anything } &

  }
  asm ("fsinx %1,%0" : "=f" (result) : "f" (angle));
}
