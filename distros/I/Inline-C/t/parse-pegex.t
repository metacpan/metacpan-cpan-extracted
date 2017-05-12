use Test::More;

use lib -e 't' ? 't' : 'test';
use TestInlineC;

test <<'...', 'Basic def';
void foo(int a, int b) {
    a + b;
}
...

TODO: {

local $TODO = 'Rigorous function definition and declaration tests not yet passing.';

test <<'...', 'Basic decl';
void foo(int a, int b);
...

test <<'...', 'Basic decl, no identifiers';
void foo(int,int);
...

test <<'...', 'char* param';
void foo(char* ch) {
}
...

test <<'...', 'char* param decl';
void foo(char* ch);
...

test <<'...', 'char * decl';
void foo(char *);
...


test <<'...', 'char *param';
void foo(char *ch) {
}
...

test <<'...', 'char** param';
void foo( char** ch ) {
}
...

test <<'...', 'char* rv, char* param';
char* foo(char* ch) {
  return ch;
}
...

test <<'...', 'const char*';
const char* foo(const char* ch) {
  return ch;
}
...

test <<'...', 'char* const param';
char* const foo(char * const ch ) {
  return ch;
}
...

test <<'...', 'const char* const param';
const char* const foo(const char* const ch) {
  return ch;
}
...

test <<'...', 'const char* const no-id decl';
const char * const foo( const char * const);
...

test <<'...', 'long int';
long int foo( long int a ) {
  return a + a;
}
...

test <<'...', 'long long';
long long foo ( long long a ) {
  return a + a;
}
...

test <<'...', 'long long int';
long long int foo ( long long int a ) {
  return a + a;
}
...

test <<'...', 'unsigned long long int';
unsigned long long int foo ( unsigned long long int abc ) {
  return abc + abc;
}
...

test <<'...', 'unsigned long long int decl no-id';
unsigned long long int foo( unsigned long long int );
...

test <<'...', 'unsigned long long decl no-id';
unsigned long long foo(unsigned long long);
...

test <<'...', 'unsigned int';
unsigned int _foo ( unsigned int abcd ) {
  return abcd + abcd;
}
...

test <<'...', 'unsigned long';
unsigned long _bar1( unsigned long abcd ) {
  return abcd + abcd;
}
...

test <<'...', 'unsigned';
unsigned baz2(unsigned abcd) {
  return abcd+abcd;
}
...

test <<'...', 'unsigned decl no-id';
unsigned baz2(unsigned);
...

}

TODO: {
local $TODO = 'Failing tests for Pegex Parser';
test <<'...', 'Issue/27';
void _dump_ptr(long d1, long d2, int use_long_output) {
    printf("hello, world! %d %d %d\n", d1, d2, use_long_output);
}
...
}

done_testing;
