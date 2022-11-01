use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::Fortran;

subtest 'types' => sub {

  my $types = FFI::Platypus::Lang::Fortran->native_type_map;

  foreach my $cpp_type (sort keys %$types)
  {
    note sprintf "%-18s = %s\n", $cpp_type, $types->{$cpp_type};
  }

  is
    $types,
    hash {
      field 'integer_1' => 'sint8';
      etc;
    };
};

done_testing;
