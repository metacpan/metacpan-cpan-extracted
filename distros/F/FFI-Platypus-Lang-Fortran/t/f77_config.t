use strict;
use warnings;
use Test::More tests => 1;
use File::ShareDir::Dist qw( dist_config );

my $config = dist_config 'FFI::Platypus-Lang-Fortran';

diag '';
diag '';
diag '';

foreach my $key (sort keys %{ $config->{f77} })
{
  diag "$key=", $config->{f77}->{$key};
}

diag '';
diag '';

pass 'good';
