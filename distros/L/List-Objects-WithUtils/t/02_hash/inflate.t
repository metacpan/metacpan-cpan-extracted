use Test::More;
use strict; use warnings FATAL => 'all';

use List::Objects::WithUtils 'hash';

my $obj = hash(foo => 'bar', baz => 'quux')->inflate;
ok $obj->foo eq 'bar';
ok $obj->baz eq 'quux';

my $cref = $obj->can('foo');
ok ref $cref eq 'CODE', 'can() on inflated obj returned code ref';
ok $obj->$cref eq 'bar', 'can() coderef works';

ok !$obj->can('cake'), 'negative can() ok';

my $isa = $obj->can('isa');
ok ref $isa eq 'CODE', 'can() fetched UNIVERSAL method ok';
ok $isa->($obj, 'List::Objects::WithUtils::Hash::Inflated'),
  'autoloaded isa ok';

{ local $@;
  eval {; $obj->set };
  ok $@, 'nonexistant key dies ok';
}
{ local $@;
  eval {; $obj->foo('bar') };
  ok $@, 'read-only inflated hash setter attempt dies ok';
}

{ local $@;
  my $pkg = ref $obj;
  eval {; $pkg->foo };
  like $@, qr/class method/, 'attempt to call class method dies ok';
}

my %deflated = $obj->DEFLATE;
ok $deflated{foo} eq 'bar', 'deflated HASH looks ok';

my $rwobj = hash(foo => 1, baz => 2)->inflate(rw => 1);
ok $rwobj->foo == 1, 'rw inflated obj ok';
ok $rwobj->foo('bar') eq 'bar', 'rw inflated obj setter ok';
ok $rwobj->foo eq 'bar', 'rw inflated obj set attrib ok';

{ local $@;
  eval {; $rwobj->set };
  like $@, qr/object method/, 'nonexistant key dies ok (rw)';
}

{ local $@;
  eval {; $rwobj->foo(qw/bar baz/) };
  like $@, qr/Multiple arguments/i, 'multiple args setter dies ok';
}

{ local $@;
  my $pkg = ref $rwobj;
  eval {; $pkg->foo };
  like $@, qr/class method/, 'attempt to call class method on rw dies ok';
}

done_testing;
