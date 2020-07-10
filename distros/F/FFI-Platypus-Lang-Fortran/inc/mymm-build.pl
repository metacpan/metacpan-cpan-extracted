use strict;
use warnings;
use blib;
use FFI::Build;
use File::Which qw( which );
use File::ShareDir::Dist qw( dist_config );

my $config = dist_config 'FFI-Platypus-Lang-Fortran';

# add.f       f90add.f90  f95add.f95
my @source = ( 't/ffi/add.f' );

push @source, 't/ffi/f90add.f90' if which($config->{f77}->{f90});
push @source, 't/ffi/f95add.f95' if which($config->{f77}->{f95});

my $build = FFI::Build->new(
  'test',
  source  => \@source,
  dir     => 't/ffi',
  verbose => 2,
);

$build->build;
