use strict;
use warnings;
use Test::More;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

my $libtest = find_lib lib => 'test', libpath => 't/ffi';
plan skip_all => 'test requires Fortran'
  unless $libtest;

plan tests => 3;

my $ffi = FFI::Platypus->new;
$ffi->lang('Fortran');
$ffi->lib($libtest);

subtest 'Fortran 77' => sub {

  $ffi->attach( add => ['integer*', 'integer*'] => 'integer');
  is add(\1,\2), 3, 'add(\1,\2) = 3';

};

subtest 'Fortran 90' => sub {

  plan skip_all => 'test requires Fortran 90' unless $ffi->find_symbol('f90add');

  $ffi->attach( f90add => ['integer*', 'integer*'] => 'integer');
  is f90add(\1,\2), 3, 'add(\1,\2) = 3';

};

subtest 'Fortran 95' => sub {

  plan skip_all => 'test requires Fortran 95' unless $ffi->find_symbol('f95add');

  $ffi->attach( f95add => ['integer*', 'integer*'] => 'integer');
  is f95add(\1,\2), 3, 'add(\1,\2) = 3';

};
