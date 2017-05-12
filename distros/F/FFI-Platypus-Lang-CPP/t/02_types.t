use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus::Lang::CPP;

my $types = FFI::Platypus::Lang::CPP->native_type_map;

foreach my $cpp_type (sort keys %$types)
{
  note sprintf "%-10s %s\n", $cpp_type, $types->{$cpp_type};
}

pass 'okay';
