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
__declspec(align(32)) struct Str1{
   int a, b, c, d, e;
};
__declspec(allocate("mycode"))  int i = 0;
__declspec(appdomain) int i = 0;
__declspec(deprecated) void func1(int) {}
__declspec(deprecated("** this is a deprecated function **")) void func2(int) {}
__declspec( dllimport ) int i;
__declspec( dllexport ) void func();
__declspec(jitintrinsic) void func();
__declspec( naked ) int func( formal_parameters ) {}
__declspec(noalias) void multiply(float * a, float * b, float * c)
{
    int i, j, k;

    for (j=0; j<P; j++)
        for (i=0; i<M; i++)
            for (k=0; k<N; k++)
                c[i * P + j] =
                          a[i * N + k] *
                          b[k * P + j];
}
__declspec(noinline) int mbrfunc() {}
__declspec(noreturn) extern void fatal () {}

int main() {
   if(1)
     return 1;
   else if(0)
     return 0;
   else
     fatal();
}
void __declspec(nothrow) f2();
struct __declspec(novtable) X {
   int f;
};
__declspec(process)
__declspec(property(get=GetX, put=PutX)) int x[];
__declspec(restrict) void f();
__declspec( safebuffers )
__declspec(selectany) int x1=1;
__declspec( thread ) int tls_i = 1;
struct __declspec(uuid("00000000-0000-0000-c000-000000000046")) IUnknown;
