use strict;
use warnings;
use Test::More tests => 1;
use FFI::ExtractSymbols::ConfigData;

diag '';
diag '';
diag '';

foreach my $key (sort qw( ms_windows openbsd_nm posix_nm function_prefix function_code data_prefix data_code ))
{
  my $value = FFI::ExtractSymbols::ConfigData->config($key);
  $value = '~' unless defined $value;
  diag sprintf "%-15s = %s", $key, $value;
}

diag '';

my %exe = %{ FFI::ExtractSymbols::ConfigData->config('exe') };

foreach my $key (keys %exe)
{
  diag sprintf "%-15s = %s", "exe.$key", ($exe{$key}||'~');
}

diag '';
diag '';


pass 'good stuff';
