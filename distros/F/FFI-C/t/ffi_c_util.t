use Test2::V0 0.000081 -no_srand => 1;
use FFI::C::Util qw( owned take perl_to_c c_to_perl set_array_count addressof );
use FFI::Platypus::Memory qw( free );
use FFI::C::StructDef;
use FFI::C::UnionDef;
use FFI::C::ArrayDef;

subtest 'owned / take' => sub {

  imported_ok 'take';
  imported_ok 'owned';

  my $def = FFI::C::StructDef->new(
    name => 'foo_t',
    members => [],
  );

  my $inst = $def->create;

  is
    $inst,
    object {
      call [ isa => 'FFI::C::Struct' ] => T();
      field ptr => match qr/^[0-9]+$/;
      etc;
    },
    'object before take',
  ;

  is owned($inst), T(), 'instance is owned';

  my $ptr1 = addressof $inst;
  is $ptr1, match qr/^[0-9]+$/, 'addressof is a pointer';

  is
    $inst,
    object {
      call [ isa => 'FFI::C::Struct' ] => T();
      field ptr => match qr/^[0-9]+$/;
      etc;
    },
    'object after addressof',
  ;

  my $ptr2 = take $inst;
  is $ptr2, match qr/^[0-9]+$/, 'gave us a pointer';

  is $ptr2, $ptr1, 'pointer from take and addressof are the same';

  is
    $inst,
    object {
      call [ isa => 'FFI::C::Struct' ] => T();
      field ptr => U();
      etc;
    },
    'object after take',
  ;

  is owned($inst), F(), 'instance is unowned';

};

subtest 'perl_to_c / c_to_perl' => sub {

  imported_ok 'perl_to_c';
  imported_ok 'c_to_perl';

  subtest 'generated classes' => sub {

    my $def = FFI::C::StructDef->new(
      class => 'Class1',
      members => [
        x => 'uint8',
        y => FFI::C::ArrayDef->new(
          class => 'Class2',
          members => [
            FFI::C::StructDef->new(
              class => 'Class3',
              members => [
                foo => 'sint16',
                bar => 'uint32',
                baz => 'double',
              ],
            ),
            2,
          ],
        ),
        z => 'sint16[3]',
        a => FFI::C::UnionDef->new(
          class => 'Class4',
          members => [
            u8  => 'uint8',
            u16 => 'uint16',
          ],
        ),
      ],
    );

    my $inst = $def->create;
    perl_to_c($inst, {
      x => 1,
      y => [
        { foo => 2, bar => 3, baz => 5.5 },
        { foo => 6, bar => 7, baz => 8.8 },
      ],
      z => [ 1, 2, 3 ],
      a => { u16 => 900 },
    });

    is(
      $inst,
      object {
        call [ isa => 'Class1' ] => T();
        call x => 1;
        call y => object {
          call [ isa => 'Class2' ] => T();
          call [ get => 0 ] => object {
            call [ isa => 'Class3' ] => T();
          };
          call [ get => 1 ] => object {
            call [ isa => 'Class3' ] => T();
          };
        };
        call a => object {
          call [ isa => 'Class4' ] => T();
          call u16 => 900;
        };
      },
      'value converted to c',
    );

    { no warnings 'once';
    *Class1::blow_up = sub { die } }

    is(
      c_to_perl($inst),
      {
        x => 1,
        y => [
          { foo => 2, bar => 3, baz => float(5.5, tolerance => 0.01) },
          { foo => 6, bar => 7, baz => float(8.8, tolerance => 0.01) },
        ],
        z => [ 1, 2, 3 ],
        a => { u8 => match qr/^[0-9]+$/, u16 => 900 },
      },
      'c_to_perl'
    );

  };


  subtest 'ungenerated types' => sub {

    my $def = FFI::C::StructDef->new(
      name => 'Class1',
      members => [
        x => 'uint8',
        y => FFI::C::ArrayDef->new(
          name => 'Class2',
          members => [
            FFI::C::StructDef->new(
              name => 'Class3',
              members => [
                foo => 'sint16',
                bar => 'uint32',
                baz => 'double',
              ],
            ),
            2,
          ],
        ),
        z => 'sint16[3]',
        a => FFI::C::UnionDef->new(
          name => 'Class4',
          members => [
            u8  => 'uint8',
            u16 => 'uint16',
          ],
        ),
      ],
    );

    my $inst = $def->create;
    perl_to_c($inst, {
      x => 1,
      y => [
        { foo => 2, bar => 3, baz => 5.5 },
        { foo => 6, bar => 7, baz => 8.8 },
      ],
      z => [ 1, 2, 3 ],
      a => { u16 => 900 },
    });

    is(
      c_to_perl($inst),
      {
        x => 1,
        y => [
          { foo => 2, bar => 3, baz => float(5.5, tolerance => 0.01) },
          { foo => 6, bar => 7, baz => float(8.8, tolerance => 0.01) },
        ],
        z => [ 1, 2, 3 ],
        a => { u8 => match qr/^[0-9]+$/, u16 => 900 },
      },
      'c_to_perl'
    );

  };

};

subtest 'var-to-fixed' => sub {

  imported_ok 'set_array_count';

  my $ffi = FFI::Platypus->new( api => 1 );
  my $def = FFI::C::ArrayDef->new(
    $ffi,
    name => 'array_t',
    members => [
      FFI::C::StructDef->new(
        members => [ x => 'uint32' ],
      ),
    ],
  );

  my $fixed = $def->create([ map { { x => $_ } } 0..9 ]);
  is(
    $fixed,
    object {
      call [ isa => 'FFI::C::Array' ] => T();
      call count => 10;
    },
    'fixed is okay'
  );

  is(
    dies { set_array_count $fixed, 5 },
    match qr/This array already has a size/,
    'Trying to set count on already existing array fails',
  );

  # casting looses the count.
  my $huh = $ffi->cast('array_t','array_t', $fixed);

  is(
    $huh,
    object {
      call [ isa => 'FFI::C::Array' ] => T();
      call count => U();
      call [ get => $_ ] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call x => $_;
      } for 0..9;
    },
    'huh is okay',
  );

  set_array_count $huh, 5;

  is(
    $huh,
    object {
      call [ isa => 'FFI::C::Array' ] => T();
      call count => 5;
      call [ get => $_ ] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call x => $_;
      } for 0..4;
    },
    'huh is okay',
  );

  is(
    dies { $huh->get(5) },
    match qr/OOB array index/,
    'oob error on set count'
  );

};

done_testing;
