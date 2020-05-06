use Test2::V0 -no_srand => 1;
use FFI::C::FFI qw( malloc );
use FFI::C::ArrayDef;
use FFI::C::StructDef;

is(
  FFI::C::ArrayDef->new( name => 'foo', members => [
    FFI::C::StructDef->new( members => [
      u64 => 'uint64',
    ]),
    10,
  ]),
  object {
    call [ isa => 'FFI::C::ArrayDef' ] => T();
    call ffi   => object { call [ isa => 'FFI::Platypus' ] => T() };
    call size  => 80;
    call align => match qr/^[0-9]+$/;
    call name  => 'foo';

    call create => object {
      call [ isa => 'FFI::C::Array' ] => T();
      call [ get => 5] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call u64           => 0;
        call [ u64 => 10 ] => 10;
        call u64           => 10;
      };
      call [ get => 4] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call u64          => 0;
        call [ u64 => 6 ] => 6;
        call u64          => 6;
      };
      call [ get => 5] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call u64 => 10;
      };
      call [ get => 4] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call u64 => 6;
      };
      call_list sub { map { $_->u64 } @{ shift() } } => [ 0, 0, 0, 0, 6, 10, 0, 0, 0, 0 ];
      call tie => array {
        item object {
          call [ isa => 'FFI::C::Struct' ] => T();
          call u64 => $_;
        } for ( 0, 0, 0, 0, 6, 10, 0, 0, 0, 0 );
        end;
      };
    };

    call [ create => [ map { { u64 => $_ * 100 } } (1..10) ] ] => object {
      call [ isa => 'FFI::C::Array' ] => T();
      call [ get => $_-1 ] => object { call u64 => $_*100 } for 1..10;
    };

  },
  'simple'
);

{
  FFI::C::ArrayDef->new(
    name => 'color_array_t',
    class => 'Color::Array',
    members => [
      FFI::C::StructDef->new(
        name => 'color_value_t',
        class => 'Color::Value',
        members => [
          red   => 'uint8',
          green => 'uint8',
          blue  => 'uint8',
        ],
      ),
      2,
    ],
  );

  is(
    Color::Array->new([ { red => 1, green => 2, blue => 3 }, { red => 4, green => 5, blue => 6 }]),
    object {
      call [ isa => 'Color::Array' ] => T();
      call [ get => 0 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 1;
        call green => 2;
        call blue  => 3;
      };
      call [ get => 1 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 4;
        call green => 5;
        call blue  => 6;
      };
    },
    'initalizers',
  );

  is(
    Color::Array->new,
    object {
      call [ isa => 'Color::Array' ] => T();
      call [ isa => 'FFI::C::Array' ] => T();
      call [ get => 0 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 0;
        call green => 0;
        call blue  => 0;
        call [ red => 0xff ] => 0xff;
        call red   => 0xff;
        call green => 0;
        call blue  => 0;
      };
      call [ get => 1 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 0;
        call green => 0;
        call blue  => 0;
      };
      call [ get => 0 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 0xff;
        call green => 0;
        call blue  => 0;
      };
      call [ get => 1 ] => object {
        call [ isa => 'Color::Value' ] => T();
        call red   => 0;
        call green => 0;
        call blue  => 0;
      };
      call count => 2;
      call sub { my $self = shift; dies { $self->get(2) } } => match qr/OOB array index/;
      call sub { my $self = shift; dies { $self->get(-1) } } => match qr/Negative array index/;
    },
    'default count'
  );

  is(
    Color::Array->new(3),
    object {
      call [ isa => 'Color::Array' ] => T();
      call [ isa => 'FFI::C::Array' ] => T();
      call count => 3;
      call [ get => 0 ] => object {};
      call [ get => 1 ] => object {};
      call [ get => 2 ] => object {};
      call sub { my $self = shift; dies { $self->get(3) } } => match qr/OOB array index/;
    },
    'override count'
  );
}

{
  my $ffi = FFI::Platypus->new( api => 1 );

  my $vdef = FFI::C::StructDef->new(
    $ffi,
    name => 'color_value_t',
    class => 'Color::VarValue',
    members => [
      red   => 'uint8',
      green => 'uint8',
      blue  => 'uint8',
    ],
  );

  FFI::C::ArrayDef->new(
    $ffi,
    name => 'color_array_t',
    class => 'Color::VarArray',
    members => [
      'color_value_t',
    ],
  );

  is(
    dies { Color::VarArray->new },
    match qr/Cannot create array without knowing the number of elements/,
    'var array dies without size',
  );

  is(
    Color::VarArray->new(2),
    object {
      call [ isa => 'Color::VarArray' ] => T();
      call [ get => 0 ] => object {};
      call [ get => 1 ] => object {};
      call sub { my $self = shift; dies { $self->get(2) } } => match qr/OOB array index/;
      call sub { my $self = shift; dies { $self->get(-1) } } => match qr/Negative array index/;
    },
    'Create var array with size'
  );

  is(
    Color::VarArray->new([{ red => 255, green => 128, blue => 25 },{}]),
    object {
      call [ isa => 'Color::VarArray' ] => T();
      call [ get => 0 ] => object {};
      call [ get => 1 ] => object {};
      call sub { my $self = shift; dies { $self->get(2) } } => match qr/OOB array index/;
      call sub { my $self = shift; dies { $self->get(-1) } } => match qr/Negative array index/;
    },
    'Create var away with array ref',
  );

  is(
    $ffi->cast('opaque', 'color_array_t', malloc(10 * $vdef->size)),
    object {
      call [ isa => 'Color::VarArray' ] => T();
      call [ get => 0 ] => object {};
      call [ get => 1 ] => object {};
      call sub { my $self = shift; dies { $self->get(-1) } } => match qr/Negative array index/;
    },
    'create from pointer',
  );

}

is(
  dies {
    my $ffi = FFI::Platypus->new( api => 1 );
    FFI::C::ArrayDef->new(
      name => 'self_nest_t',
      members => [
        'self_nest_t',
      ],
    );
  },
  match qr/Canot nest an array def inside of itself/,
  'Canot nest an array def inside of itself',
);

done_testing;
