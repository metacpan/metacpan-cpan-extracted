use Test2::V0 -no_srand => 1;
use FFI::Platypus 2.00;
use FFI::Platypus::Lang::Zig;

subtest types => sub {

  my $types = FFI::Platypus::Lang::Zig->native_type_map;

  foreach my $key (sort keys %$types) {
    my $val = $types->{$key};
    note sprintf "%-12s = %s\n", $key, $val;
  }

  pass 'good';

};

subtest 'use' => sub {

  my $ffi;
  try_ok { $ffi = FFI::Platypus->new( api => 2, lang => 'Zig' ) } 'create platypus instance';

  is
    $ffi,
    object {
      call [ sizeof => 'i32' ] => 4;
    },
    'some basics without having to call code';

};

done_testing;
