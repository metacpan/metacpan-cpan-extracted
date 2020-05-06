use Test2::V0 -no_srand => 1;
use FFI::C;
use FFI::C::Util qw( c_to_perl );
use FFI::Platypus;
use Capture::Tiny qw( capture_merged );

my $ffi = FFI::Platypus->new( api => 1 );

is(
  FFI::C->ffi($ffi),
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi first set ok',
);

is(
  dies { FFI::C->ffi($ffi) },
  match qr/Already have an FFI::Platypus instance for/,
  'FFI::C->ffi second call dies',
);

is(
  FFI::C->ffi,
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi can call get as many times as we like',
);

subtest 'example' => sub {

  skip_all 'test requires Perl 5.14 or better' unless $] >= 5.014;

  {
    my($out, $ret) = capture_merged {
        require './examples/synopsis/c.pl';
    };
    is $ret, T(), 'example compiles';
    note $out;
  }

  is(
    c_to_perl(ArrayNamedColor->new([
      { name => "red",    value => { red   => 255 } },
      { name => "green",  value => { green => 255 } },
      { name => "blue",   value => { blue  => 255 } },
      { name => "purple", value => { red   => 255,
                                     blue  => 255 } },
    ])),
    [
      { name => match qr/^red\0+$/,
        value => { red => 255, blue => 0, green => 0 } },
      { name => match qr/^green\0+$/,
        value => { red => 0, blue => 0, green => 255 } },
      { name => match qr/^blue\0+$/,
        value => { red => 0, blue => 255, green => 0 } },
      { name => match qr/^purple\0+$/,
        value => { red => 255, blue => 255, green => 0 } },
    ],
    'create instance array + struct',
  );

  is(
    c_to_perl(AnyInt->new({ u8 => 42 })),
    hash {
      field u8 => 42;
      field u16 => match qr/^[0-9]+$/;
      field u32 => match qr/^[0-9]+$/;
      field u64 => match qr/^[0-9]+$/;
      end;
    },
    'create instance union'
  );

};

subtest 'with type name' => sub {

  { package ColorValue1;
    FFI::C->struct( color_value_t => [
      red   => 'uint8',
      green => 'uint8',
      blue  => 'uint8',
    ]);
  }

  { package NamedColor1;
    FFI::C->struct( named_color_t => [
      name  => 'string(22)',
      value => 'color_value_t',
    ]);
  }

  { package ArrayNamedColor1;
    FFI::C->array(array_named_color_t => ['named_color_t' => 4]);
  };

  is(
    c_to_perl(ArrayNamedColor1->new([
      { name => "red",    value => { red   => 255 } },
      { name => "green",  value => { green => 255 } },
      { name => "blue",   value => { blue  => 255 } },
      { name => "purple", value => { red   => 255,
                                     blue  => 255 } },
    ])),
    [
      { name => match qr/^red\0+$/,
        value => { red => 255, blue => 0, green => 0 } },
      { name => match qr/^green\0+$/,
        value => { red => 0, blue => 0, green => 255 } },
      { name => match qr/^blue\0+$/,
        value => { red => 0, blue => 255, green => 0 } },
      { name => match qr/^purple\0+$/,
        value => { red => 255, blue => 255, green => 0 } },
    ],
    'create instance array + struct',
  );

  { package AnyInt1;
    FFI::C->union(any_int_t => [
      u8  => 'uint8',
      u16 => 'uint16',
      u32 => 'uint32',
      u64 => 'uint64',
    ]);
  }

  is(
    c_to_perl(AnyInt1->new({ u8 => 42 })),
    hash {
      field u8 => 42;
      field u16 => match qr/^[0-9]+$/;
      field u32 => match qr/^[0-9]+$/;
      field u64 => match qr/^[0-9]+$/;
      end;
    },
    'create instance union'
  );

};

done_testing;
