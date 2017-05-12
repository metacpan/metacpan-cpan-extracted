use strict;
use warnings;
use Test::More;
use FFI::CheckLib;
use FFI::Platypus::Declare
  'void', 'int', 'string',
  [ '::StringArray' => 'string_array' ];

my $libtest = find_lib lib => 'test', libpath => 'libtest';
plan skip_all => 'test requires a compiler'
  unless $libtest;

plan tests => 4;

lib $libtest;

attach get_string_from_array => [string_array,int] => string;

my @list = qw( foo bar baz );

for(0..2)
{
  is get_string_from_array(\@list, $_), $list[$_], "get_string_from_array(\@list, $_) = $list[$_]";
}

is get_string_from_array(\@list, 3), undef, "get_string_from_array(\@list, 3) = undef";
