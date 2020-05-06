use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.24;
use FFI::C::UnionDef;
use FFI::C::Union;

{ package Foo;
  use FFI::Platypus::Record;
  record_layout_1(
    sint64 => 'bar',
  );
}

subtest 'basic' => sub {

  my $def = FFI::C::UnionDef->new(
    name => "foo_t",
    members => [
      bar => 'sint64',
      baz => 'uint8',
    ],
  );

  is(
    do {
      my $o = $def->create;
      $o->bar(-42);
      $def->ffi->cast('foo_t' => 'record(Foo)*', $o);
    },
    object {
      call [ isa => 'Foo' ] => T();
      call bar => -42;
    },
    'object argument',
  );

  is(
    do {
      our $r = Foo->new( bar => -47 );
      $def->ffi->cast('record(Foo)*', 'foo_t', $r);
    },
    object {
      call [ isa => 'FFI::C::Union' ] => T();
      call bar => -47;
      field owner => 1;
      field def => object {
        call [ isa => 'FFI::C::UnionDef' ] => T();
        call name => 'foo_t';
      };
      etc;
    },
    'object return',
  );

};

done_testing;
