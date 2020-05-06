use Test2::V0 -no_srand => 1;
use FFI::C::UnionDef;

is(
  FFI::C::UnionDef->new,
  object {
    call [ isa => 'FFI::C::UnionDef' ] => T();
    call name => U();
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Union' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'unnamed, empty union',
);

is(
  FFI::C::UnionDef->new( name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::UnionDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Union' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty union',
);

is(
  FFI::C::UnionDef->new( FFI::Platypus->new( api => 1 ), name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::UnionDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Union' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty union, explicit Platypus',
);

is(
  FFI::C::UnionDef->new( members => [
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
    u64 => 'uint64',
  ]),
  object {
    call [ isa => 'FFI::C::UnionDef' ] => T();
    # I don't think there is any arch out there where 8-64 ints
    # are more than 8 byte aligned?
    call size => 8;
    call create => object {
      call [ isa => 'FFI::C::Union' ] => T();
      call u8                => 0;
      call u16               => 0;
      call u32               => 0;
      call u64               => 0;
      call [ u8 => 22 ]      => 22;
      call u8                => 22;
      call [ u16 => 1024 ]   => 1024;
      call u16               => 1024;
      call [ u32 => 999999 ] => 999999;
      call u32               => 999999;
      call [ u64 => 55 ]     => 55;
      call u64               => 55;
    };
  },
  'union with members',
);

done_testing;
