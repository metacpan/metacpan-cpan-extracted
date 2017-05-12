use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 32;
use lib 't/lib';
use Capture
  capture => ['-MDevel::Confess'],
  capture_dump => ['-MDevel::Confess=dump'],
;

sub scrub_refaddr ($) {
  my $in = shift;
  $in =~ s/\b([A-Z]+)\(0x[0-9a-zA-Z]+\)/$1(0xXXXXXX)/g;
  $in;
}

is capture <<"END_CODE",
package A;

sub f {
#line 1 test-block.pl
    warn  "Beware!";
}

sub g {
#line 2 test-block.pl
    f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'basic test';

is capture <<"END_CODE",
package A;

sub f {
\tuse strict;
\tmy \$a;
#line 1 test-block.pl
\tmy \@a = \@\$a;
}

sub g {
#line 2 test-block.pl
\tf();
}

package main;

#line 3 test-block.pl
A::g();

END_CODE
  <<"END_OUTPUT",
Can't use an undefined value as an ARRAY reference at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'interpreter-thrown warnings';

for my $type (qw(die croak confess)) {

  is capture <<"END_CODE",
use Carp;
#line 1 test-block.pl
$type "foo at bar";
END_CODE
    <<"END_OUTPUT",
foo at bar at test-block.pl line 1.
END_OUTPUT
    "$type at root";

  is capture <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type "foo at bar";
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
foo at bar at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type in sub";

  is capture <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type "foo at bar\\n";
}
sub bar {
#line 2 test-block.pl
  foo();
}
#line 3 test-block.pl
bar();
END_CODE
    <<"END_OUTPUT",
foo at bar
 at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
\tmain::bar() called at test-block.pl line 3
END_OUTPUT
    "$type with newline";

  is scrub_refaddr capture <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type bless {}, 'NoOverload';
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
NoOverload=HASH(0xXXXXXX) at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with object";

  is capture <<"END_CODE",
use Carp;
{
  package HasOverload;
  use overload '""' => sub { "message" };
}
sub foo {
#line 1 test-block.pl
  $type bless {}, 'HasOverload';
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
message at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with object with overload";

  is capture_dump <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type bless {}, 'NoOverload';
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
bless( {}, 'NoOverload' ) at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with object + dump";

  is capture_dump <<"END_CODE",
use Carp;
{
  package HasOverload;
  use overload '""' => sub { "message" };
}
sub foo {
#line 1 test-block.pl
  $type bless {}, 'HasOverload';
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
message at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with object with overload + dump";

  is scrub_refaddr capture <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type [1];
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
ARRAY(0xXXXXXX) at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with non-object ref";

  is capture_dump <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type [1];
}
#line 2 test-block.pl
foo();
END_CODE
    <<"END_OUTPUT",
[1] at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 2
END_OUTPUT
    "$type with non-object ref + dump";

  is scrub_refaddr capture_dump <<"END_CODE",
use Carp;
sub foo {
#line 1 test-block.pl
  $type [1];
}
#line 2 test-block.pl
eval {
  foo();
};
print STDERR \$@ . "\\n";
die;
END_CODE
    <<"END_OUTPUT",
ARRAY(0xXXXXXX)
[1] at test-block.pl line 1.
\tmain::foo() called at test-block.pl line 3
\teval {...} called at test-block.pl line 2
END_OUTPUT
    "$type rethrowing non-object ref + dump";
}
