use Test2::V0 -no_srand => 1;
use FFI::Platypus;

subtest 'Pascal' => sub {
  my $ffi = FFI::Platypus->new(lang => 'Pascal');
  eval { $ffi->type('Integer') };
  is $@, '', 'int is not an okay type';
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';
};

done_testing;
