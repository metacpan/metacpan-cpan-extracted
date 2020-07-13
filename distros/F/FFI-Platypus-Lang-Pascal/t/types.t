use Test2::V0 -no_srand => 1;
use FFI::Platypus::Lang::Pascal;

my $types = FFI::Platypus::Lang::Pascal->native_type_map;

foreach my $cpp_type (sort keys %$types)
{
  note sprintf "%-10s %s\n", $cpp_type, $types->{$cpp_type};
}

pass 'okay';

done_testing;
