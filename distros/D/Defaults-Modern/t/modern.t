use Test::More;

use Defaults::Modern;

# Imports

# Types
can_ok __PACKAGE__, qw/ is_Int is_ArrayObj is_HashObj /;

#  Carp
can_ok __PACKAGE__, qw/ carp croak confess /;
  
#  List::Objects::WithUtils
can_ok __PACKAGE__, qw/ 
  array immarray array_of immarray_of
  hash immhash hash_of immhash_of
/;

#  Path::Tiny
can_ok __PACKAGE__, qw/ path /;
ok is_Path(path('/')), 'Path::Tiny and Types for same';

#  PerlX::Maybe
can_ok __PACKAGE__, qw/ maybe provided /;

#  Quote::Code
my $qcstr = qc'2+2 = {2+2}';
cmp_ok $qcstr, 'eq', '2+2 = 4', 'qc';
my @qcwlist = qcw/ foo {2+2} / ;
is_deeply \@qcwlist, ['foo', 4], 'qcw';
my $qcto = qc_to <<'EOT';
bar
#{2+2}
EOT
cmp_ok $qcto, 'eq', "bar\n4\n", 'qc_to';

#  Scalar::Util
can_ok __PACKAGE__, qw/ blessed reftype weaken /;

#  Try::Catch
can_ok __PACKAGE__, qw/ try catch /;

# match::simple
my @foo = qw/foo bar baz/;
ok 'foo' |M| \@foo, 'match::simple imported ok';

# true
use lib 't/inc';
use_ok 'PkgTrue';
ok 'PkgTrue'->can('foo'), 'true.pm imported ok';

# no indirect
package T { 
    sub f { 1 } 
}
ok not(eval 'f T'), 'indirect eval failed ok';
ok $@, 'indirect method call died ok';
cmp_ok $@, '=~', qr/indirect/i, 'indirect method call threw exception ok'
  or diag explain $@;

# no bareword::filehandles
ok not(eval 'open F, __FILE__'), 'bareword fh eval failed ok';
ok $@, 'bareword fh died ok';
cmp_ok $@, '=~', qr/bareword/i, 'bareword fh threw exception ok'
  or diag explain $@;

# strict
ok not(eval "\$x"), 'strict eval failed ok';
ok $@, 'strict eval died ok';
cmp_ok $@, '=~', qr/^Global symbol "\$x" requires explicit package name/,
  'strict eval threw exception ok' or diag explain $@;

# warnings
ok not(eval "my \$foo = 'bar'; 1 if \$foo == 1"),
  'fatal numeric warning ok';
ok $@, 'numeric warning died ok';
cmp_ok $@, '=~', qr/numeric/, 'numeric warning threw exception ok'
  or diag explain $@;

# 5.14 features
eval 'state $foo';
ok !$@, 'state imported ok';
eval 'given ("") {}';
ok $@, 'switch not imported ok';

# Function::Parameters
fun calc (Int $x, Num $y) { $x + $y }
ok calc( 1, 0.5 ) == 1.5, 'Function::Parameters imported ok';

# Switch::Plain
sswitch ('foo') {
  case 'foo': { ok 1, 'Switch::Plain imported ok' }
}

# List::Objects::Types
fun frob (ArrayObj $arr) { $arr->count }
ok frob( array(1,2,3) ) == 3, 'List::Objects::Types imported ok';

# bad import tag
package My::Bad {
  use Test::More;
  require Defaults::Modern;

  ok not(eval "Defaults::Modern->import('foobar')"),
    'eval with bad import tag failed';
  ok $@, 'eval with bad import tag died';
  cmp_ok $@, '=~', qr/export/, 'eval with bad import tag exception ok'
    or diag explain $@;
}

# autobox_lists
package My::Foo {
  use Test::More;
  use Defaults::Modern 'autobox_lists';

  ok []->count == array->count, 'ARRAY autoboxed ok';
  ok +{}->keys->count == 0, 'HASH autoboxed ok';
  ok +{foo => 1}->inflate->foo == 1, 'autoboxed ->inflate ok';
}

# Moo
package My::OO {
  use Test::More;
  use Defaults::Modern 'Moo';

  has foo => (
    is      => 'ro',
    isa     => ImmutableArray,
    coerce  => 1,
    default => sub { [] },
  );
}

ok is_ArrayObj( My::OO->new->foo ), 'Moo imported ok';

# 'all' import tag
package My::Bar {
  use Test::More;
  use Defaults::Modern ':all';

  ok []->count == 0, ':all import tag ok';
}

# define
define FOO = 'bar';
ok FOO eq 'bar', 'define (1) ok';
define BAR => 'baz';
ok BAR eq 'baz', 'define (2) ok';

# extra typelibs

=for comment

# deprecated -with_types opt
  { package TypedFoo;
    use Test::More;
    use Defaults::Modern
      -all,
      -with_types => [ 'TypeLib' ];

    ok []->count == 0, '-all import tag ok';
    fun takes_foo (FooType $foo) {
      ok $foo eq 'foo', 'extra typelib (-with_types)  registered ok';
    }
    takes_foo('foo');
    eval {; takes_foo('bar') };
    ok $@, 'extra typelibs ok';
  }
  { package TypedFooStr;
    use Test::More;
    use Defaults::Modern
      -all,
      -with_types => 'TypeLib';

    ok []->count == 0, '-all import tag ok';
    fun takes_foo (FooType $foo) {
      ok $foo eq 'foo', 'extra typelib (as string) registered ok';
    }
    takes_foo('foo');
    eval {; takes_foo('bar') };
    ok $@, 'extra typelibs ok';
  }

=cut

{ package TypedFooAutoRegistry;
  use Test::More;
  use Defaults::Modern -all;
  use TypeLib -types;

  ok []->count == 0, '-all import tag ok';
  fun takes_foo (FooType $foo) {
    ok $foo eq 'foo', 'extra typelib (plain import) registered ok';
  }
  takes_foo('foo');
  eval {; takes_foo('bar') };
  ok $@, 'extra typelibs ok';
}

done_testing;
