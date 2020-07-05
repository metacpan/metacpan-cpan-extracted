use strict;
use warnings;
use Test::More tests => 1;
use File::ShareDir::Dist::Install qw( install_config_get );

diag '';
diag '';
diag '';

my $config = install_config_get 'FFI-ExtractSymbols';

foreach my $key (sort qw( ms_windows openbsd_nm posix_nm function_prefix function_code data_prefix data_code ))
{
  my $value = $config->{$key};
  $value = '~' unless defined $value;
  diag sprintf "%-15s = %s", $key, $value;
}

diag '';

my %exe = %{ $config->{'exe'} };

foreach my $key (keys %exe)
{
  diag sprintf "%-15s = %s", "exe.$key", ($exe{$key}||'~');
}

diag '';
diag '';


pass 'good stuff';
