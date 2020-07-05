use strict;
use warnings;
use Test::More;
use FFI::ExtractSymbols;
use FFI::CheckLib qw( find_lib );
use File::ShareDir::Dist::Install qw( install_config_get );

my $config = install_config_get 'FFI-ExtractSymbols';

plan skip_all => 'requires posix_nm mode with no underscore prefix'
  unless $config->{'posix_nm'}
  &&     $config->{'function_prefix'} eq ''
  &&     $config->{'data_prefix'} eq '';

plan tests => 3;

my $lib = find_lib lib => 'test', symbol => 'my_function', libpath => 't/ffi';

note "lib=$lib";

my @export;
my @code;
my @data;

extract_symbols($lib,
  export => sub {
    note "export: $_[0] = $_[1]";
    push @export, $_[1]
      if $_[0] =~ /my_(function|variable)/;
  },
  code => sub {
    note "code:   $_[0] = $_[1]";
    push @code, $_[1]
      if $_[0] =~ /my_function/;
  },
  data => sub {
    note "data:   $_[0] = $_[1]";
    push @data, $_[1]
      if $_[0] =~ /my_variable/;
  },
);

is_deeply \@code, ['my_function'], "\\\@code = ['my_function']";
is_deeply \@data, ['my_variable'], "\\\@data = ['my_variable']";
is_deeply [sort @export], ['my_function','my_variable'], "\\\@data = ['my_function', 'my_data']";
