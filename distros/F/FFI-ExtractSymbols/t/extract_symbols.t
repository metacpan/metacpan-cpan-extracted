use strict;
use warnings;
use Test::More tests => 3;
use FFI::CheckLib qw( find_lib );
use FFI::ExtractSymbols;

my $lib = find_lib lib => 'test', symbol => 'my_function', libpath => 't/ffi';

note "lib=$lib";

my @export;
my @code;
my @data;

extract_symbols($lib,
  export => sub {
    note "export: $_[0] = $_[1]";
    push @export, $_[0]
      if $_[0] =~ /my_(function|variable)/;
  },
  code => sub {
    note "code:   $_[0] = $_[1]";
    push @code, $_[0]
      if $_[0] =~ /my_(function|variable)/;
  },
  data => sub {
    note "data:   $_[0] = $_[1]";
    push @data, $_[0]
      if $_[0] =~ /my_(function|variable)/;
  },
);

if($FFI::ExtractSymbols::mode eq 'mixed')
{
  is_deeply \@code, ['my_function','my_variable'], "\\\@code = ['my_function','my_variable']";
  is_deeply \@data, [], "\\\@data = []";
  is_deeply [sort @export], ['my_function','my_variable'], "\\\@data = ['my_function', 'my_data']";
}
else
{
  is_deeply \@code, ['my_function'], "\\\@code = ['my_function']";
  is_deeply \@data, ['my_variable'], "\\\@data = ['my_variable']";
  is_deeply [sort @export], ['my_function','my_variable'], "\\\@data = ['my_function', 'my_data']";
}

