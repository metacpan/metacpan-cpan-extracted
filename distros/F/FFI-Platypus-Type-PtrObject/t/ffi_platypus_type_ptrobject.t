use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use FFI::Platypus::Type::PtrObject;

my $ffi = ffi->test;

is(
  dies { $ffi->load_custom_type('::PtrObject', 'foo_t') },
  match qr/no class specified/,
  'no class specified',
);

is(
  dies { $ffi->load_custom_type('::PtrObject', 'foo_t', '&*%&*$GHG') },
  match qr/illegal class name/,
  'bad class specified',
);

$ffi->load_custom_type('::PtrObject', 'foo_t', 'Foo::Bar');

{ package Foo::Bar;
  use FFI::Platypus::Memory qw( malloc free );

  sub new
  {
    my $class = shift;
    bless {
      ptr => malloc(100),
    }, $class;
  }

  $ffi->attach( set   => ['foo_t','string']    );
  $ffi->attach( get   => ['foo_t'] => 'string' );
  $ffi->attach( clone => ['foo_t'] => 'foo_t'  );
  $ffi->attach( null  => ['foo_t'] => 'foo_t'  );

  sub take_ownership
  {
    my($self) = @_;
    return delete $self->{ptr};
  }

  sub DESTROY
  {
    my($self) = @_;
    if(defined $self->{ptr})
    {
      free($self->{ptr});
    }
  }
}

pass 'created class without segv';

is(
  dies { Foo::Bar::get(undef) },
  match qr/argument is not a Foo::Bar/,
  'handles undef',
);

is(
  dies { Foo::Bar::get(bless {}, 'Baz') },
  match qr/argument is not a Foo::Bar/,
  'handles different class',
);

is(
  Foo::Bar->new,
  object {
    call [ isa => 'Foo::Bar' ] => T();
    field 'ptr' => match qr/^[0-9]+$/;
    call [ set => 'frooble' ] => U();
    call get => 'frooble';
    call clone => object {
      call [ isa => 'Foo::Bar' ] => T();
      call get => 'frooble';
    };
    call null => U();
  },
  'regular object',
);

is(
  dies {
    my $foo = Foo::Bar->new;
    my $ptr = $foo->take_ownership;
    $foo->get;
  },
  match qr/pointer for Foo::Bar went away/,
  'dies when ptr goes away',
);

done_testing;
