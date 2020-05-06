use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.24;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Record;
use FFI::C::StructDef;

{
  my $count = 1;
  sub record
  {
    my $struct = shift;
    my $perl = qq{
      package Rec$count;
      use FFI::Platypus::Record;
      record_layout_1(\@_);
    };
    eval $perl;  ## no critic (BuiltinFunctions::ProhibitStringyEval)
    die $@ if $@;
    my $rec = FFI::Platypus->new( api => 1 )->cast( 'opaque' => "record(Rec$count)*", $struct->{ptr} );
    $count++;
    $rec;
  }
}

is(
  FFI::C::StructDef->new,
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => U();
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'unnamed, empty struct',
);

is(
  FFI::C::StructDef->new( name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct',
);

is(
  FFI::C::StructDef->new( FFI::Platypus->new( api => 1 ), name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct, explicit Platypus',
);

my $ptr = malloc(10);

is(
  FFI::C::StructDef->new( members => [
    foo => 'uint8',
    bar => 'uint32',
    baz => 'sint64',
    roger => 'opaque',
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call foo                => 0;
      call bar                => 0;
      call baz                => 0;
      call roger              => U();
      call [ foo => 22 ]      => 22;
      call [ bar => 1900 ]    => 1900;
      call [ baz => -500 ]    => -500;
      call [ roger => $ptr ]  => $ptr;
      call foo                => 22;
      call bar                => 1900;
      call baz                => -500;
      call roger              => $ptr;
      call sub { record(shift, qw( uint8 foo uint32 bar sint64 baz opaque roger ) ) } => object {
        call foo   =>   22;
        call bar   => 1900;
        call baz   => -500;
        call roger => $ptr;
      };
      call [ roger => undef ] => U();
      call roger              => U();
    };
  },
  'with members',
);

is(
  FFI::C::StructDef->new( members => [
    foo => 'uint8',
    bar => FFI::C::StructDef->new( members => [
      baz => 'sint32',
    ]),
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call foo               => 0;
      call bar => object {
        call baz             => 0;
      };
      call [ foo => 200 ]    => 200;
      call bar => object {
        call [baz => -9999 ] => -9999;
      };
      call foo               => 200;
      call bar => object {
        call baz             => -9999;
      };
    },
  },
  'nested'
);

is(
  FFI::C::StructDef->new( members => [
    foo => 'uint8',
    bar => FFI::C::StructDef->new( members => [
      baz => 'sint32',
    ]),
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call [ create => { foo => 200, bar => { baz => -9999 } } ] => object {
      call foo              => 200;
      call bar => object {
        call baz            => -9999;
      }
    },
  },
  'nested'
);

is(
  FFI::C::StructDef->new( members => [
    foo => 'string(10)',
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call foo                => "\0\0\0\0\0\0\0\0\0\0";
      call [ foo => "hello" ] => "hello\0\0\0\0\0";
      call foo                => "hello\0\0\0\0\0";
    },
  },
  'fixed string',
);

{
  my $ffi = FFI::Platypus->new( api => 1 );

  FFI::C::StructDef->new(
    $ffi,
    name => 'value_color_t',
    class => 'Color::Value',
    members => [
      red   => 'uint8',
      green => 'uint8',
      blue  => 'uint8',
    ]
  );

  is(
    Color::Value->new({ red => 1, green => 2, blue => 3 }),
    object {
      call [ isa => 'Color::Value' ] => T();
      call red => 1;
      call green => 2;
      call blue => 3;
    },
    'initalizers',
  );

  FFI::C::StructDef->new(
    $ffi,
    name    => 'named_color_t',
    class   => 'Color::Named',
    members => [
      name => 'string(5)',
      value => 'value_color_t',
    ],
  );

  is(
    Color::Named->new,
    object {
      call [ isa => 'Color::Named' ] => T();
      call name => "\0\0\0\0\0";
      call [ name => "red" ] => "red\0\0";
      call name => "red\0\0";
      call value => object {
        call [ isa => 'Color::Value' ] => T();
        call red => 0;
        call [ red => 255] => 255;
        call red   => 255;
        call green => 0;
        call blue  => 0;
      };
    },
    'named color',
  );

  {

    my $def = FFI::C::StructDef->new(
      $ffi,
      name  => 'byte_array1_t',
      members => [
        e => 'uint8[3]',
      ],
    );

    {
      my $ar = $def->create;
      is($ar->e(0), 0, 'a.get.0 = 0');
      is($ar->e(1), 0, 'a.get.1 = 0');
      is($ar->e(2), 0, 'a.get.2 = 0');
      is($ar->e(0,1), 1, 'a.set.0,1 = 1');
      is($ar->e(1,2), 2, 'a.set.0,2 = 2');
      is($ar->e(2,3), 3, 'a.set.0,3 = 3');
      is($ar->e(0), 1, 'a.get.0 = 1');
      is($ar->e(1), 2, 'a.get.1 = 2');
      is($ar->e(2), 3, 'a.get.2 = 3');
      is($ar->e, [1,2,3], 'a = [1,2,3]');

      is(
        dies { $ar->e(-1) },
        match qr/Negative index on array member/,
        'disallow negative index',
      );

      is(
        dies { $ar->e(3) },
        match qr/OOB index on array member/,
        'disallow oob index',
      );

      my $c = $ffi->cast('byte_array1_t' => 'value_color_t', $ar);
      is(
        $c,
        object {
          call [ isa => 'Color::Value' ] => T();
          call red   => 1;
          call green => 2;
          call blue  => 3;
        },
        'cast from bytes to color worked'
      );
    }

    {
      my $ar = $def->create;
      is($ar->e->[0], 0, 'a.get.0 = 0');
      is($ar->e->[1], 0, 'a.get.1 = 0');
      is($ar->e->[2], 0, 'a.get.2 = 0');
      is($ar->e->[0] = 1, 1, 'a.set.0,1 = 1');
      is($ar->e->[1] = 2, 2, 'a.set.0,2 = 2');
      is($ar->e->[2] = 3, 3, 'a.set.0,3 = 3');
      is($ar->e->[0], 1, 'a.get.0 = 1');
      is($ar->e->[1], 2, 'a.get.1 = 2');
      is($ar->e->[2], 3, 'a.get.2 = 3');
      is(scalar @{ $ar->e }, 3, 'a.length = 3');
      is($ar->e, [1,2,3], 'a = [1,2,3]');

      is(
        dies { $ar->e(-1) },
        match qr/Negative index on array member/,
        'disallow negative index',
      );

      is(
        dies { $ar->e(3) },
        match qr/OOB index on array member/,
        'disallow oob index',
      );

      my $c = $ffi->cast('byte_array1_t' => 'value_color_t', $ar);
      is(
        $c,
        object {
          call [ isa => 'Color::Value' ] => T();
          call red   => 1;
          call green => 2;
          call blue  => 3;
        },
        'cast from bytes to color worked'
      );

      is($ar->e([4,5,6]), [4,5,6], 'a = [4,5,6]');
      is($ar->e, [4,5,6], 'a == [4,5,6]');
    }
  }

  {

    my $def = FFI::C::StructDef->new(
      $ffi,
      name  => 'byte_array2_t',
      class => 'Byte::Array2',
      members => [
        e => 'uint8[3]',
      ],
    );

    {
      my $ar = Byte::Array2->new;
      is($ar->e(0), 0, 'a.get.0 = 0');
      is($ar->e(1), 0, 'a.get.1 = 0');
      is($ar->e(2), 0, 'a.get.2 = 0');
      is($ar->e(0,1), 1, 'a.set.0,1 = 1');
      is($ar->e(1,2), 2, 'a.set.0,2 = 2');
      is($ar->e(2,3), 3, 'a.set.0,3 = 3');
      is($ar->e(0), 1, 'a.get.0 = 1');
      is($ar->e(1), 2, 'a.get.1 = 2');
      is($ar->e(2), 3, 'a.get.2 = 3');
      is($ar->e, [1,2,3], 'a = [1,2,3]');

      is(
        dies { $ar->e(-1) },
        match qr/Negative index on array member/,
        'disallow negative index',
      );

      is(
        dies { $ar->e(3) },
        match qr/OOB index on array member/,
        'disallow oob index',
      );

      my $c = $ffi->cast('byte_array2_t' => 'value_color_t', $ar);
      is(
        $c,
        object {
          call [ isa => 'Color::Value' ] => T();
          call red   => 1;
          call green => 2;
          call blue  => 3;
        },
        'cast from bytes to color worked'
      );
    }

    {
      my $ar = Byte::Array2->new;
      is($ar->e->[0], 0, 'a.get.0 = 0');
      is($ar->e->[1], 0, 'a.get.1 = 0');
      is($ar->e->[2], 0, 'a.get.2 = 0');
      is($ar->e->[0] = 1, 1, 'a.set.0,1 = 1');
      is($ar->e->[1] = 2, 2, 'a.set.0,2 = 2');
      is($ar->e->[2] = 3, 3, 'a.set.0,3 = 3');
      is($ar->e->[0], 1, 'a.get.0 = 1');
      is($ar->e->[1], 2, 'a.get.1 = 2');
      is($ar->e->[2], 3, 'a.get.2 = 3');
      is(scalar @{ $ar->e }, 3, 'a.length = 3');
      is($ar->e, [1,2,3], 'a = [1,2,3]');

      is(
        dies { $ar->e(-1) },
        match qr/Negative index on array member/,
        'disallow negative index',
      );

      is(
        dies { $ar->e(3) },
        match qr/OOB index on array member/,
        'disallow oob index',
      );

      my $c = $ffi->cast('byte_array2_t' => 'value_color_t', $ar);
      is(
        $c,
        object {
          call [ isa => 'Color::Value' ] => T();
          call red   => 1;
          call green => 2;
          call blue  => 3;
        },
        'cast from bytes to color worked'
      );

      is($ar->e([4,5,6]), [4,5,6], 'a = [4,5,6]');
      is($ar->e, [4,5,6], 'a == [4,5,6]');
    }
  }

}

is(
  dies {
    my $ffi = FFI::Platypus->new( api => 1 );
    FFI::C::StructDef->new(
      name => 'self_nest_t',
      members => [
        self => 'self_nest_t',
      ],
    );
  },
  match qr/Canot nest a struct or union def inside of itself/,
  'Canot nest a struct or union def inside of itself',
);

is(
  do {
    my $ffi = FFI::Platypus->new( api => 1 );
    FFI::C::StructDef->new(
      $ffi,
      name     => 'foo_t',
      members  => [ x => 'uint8' ],
      nullable => 1,
    );
    $ffi->cast('foo_t' => 'opaque' => undef);
  },
  U(),
  'nullable okay'
);


done_testing;
