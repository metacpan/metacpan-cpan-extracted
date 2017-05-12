use strict;
use warnings;
use Test::More tests => 1;
use Module::Build::FFI::Fortran;

my $config = Module::Build::FFI::Fortran->_f77_config;

diag '';
diag '';
diag '';

if(-r 'config.log')
{
  my $fh;
  open $fh, '<', 'config.log';
  diag $_ for <$fh>;
  close $fh;
  
  diag '';
  diag '';
}

foreach my $key (sort keys %$config)
{
  diag "$key=", $config->{$key};
}

diag '';
diag '';

pass 'good';
