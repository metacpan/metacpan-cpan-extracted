use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus::Lang::Fortran;

my $types = FFI::Platypus::Lang::Fortran->native_type_map;

foreach my $cpp_type (sort keys %$types)
{
  note sprintf "%-18s = %s\n", $cpp_type, $types->{$cpp_type};
}

pass 'okay';
