package My::ModuleBuild;

use strict;
use warnings;
use FFI::Platypus;
use File::Which qw( which );
use base qw( Module::Build::FFI::Fortran );

sub new
{
  my($class, %args) = @_;

  unlink 'config.log' if -e 'config.log';  
  my $f77_config = $class->_f77_config;

  $args{ffi_libtest_dir} = [ 'libtest' ];
  push @{ $args{ffi_libtest_dir} }, 'libtest/f90'
    if which($f77_config->{f90});
  push @{ $args{ffi_libtest_dir} }, 'libtest/f95'
    if which($f77_config->{f95});
  
  my $self = $class->SUPER::new(%args);
  
  $self->config_data(f77 => $f77_config);
  
  my %type;
  my $ffi = FFI::Platypus->new;
  
  foreach my $size (qw( 1 2 4 8 ))
  {
    my $bits = $size*8;
    $type{"integer_$size"}  = "sint$bits";
    $type{"unsigned_$size"} = "uint$bits";
    $type{"logical_$size"}  = "sint$bits";
  }
  
  # http://docs.oracle.com/cd/E19957-01/805-4939/z40007365fe9/index.html
  
  # should always be 32 bit... I believe, but use
  # the C int as a guide
  $type{'integer'} = 'sint' . $ffi->sizeof('int')*8;
  $type{'unsigned'} = 'uint' . $ffi->sizeof('int')*8;
  $type{'logical'} = 'sint' . $ffi->sizeof('int')*8;
  
  $type{byte} = 'sint8';
  $type{character} = 'uint8';
  
  $type{'double precision'} = $type{real_8} = 'double';
  $type{'real_4'} = $type{'real'} = 'float';
  
  # TODO:
  #  COMPLEX         = { float, float }
  #  COMPLEX*8       = { float, float }
  #  DOUBLE COMPLEX  = { double, double }
  #  COMPLEX*16      = { double, double }
  #  COMPLEX*32      = { long double, long double }
  #  REAL*16         = long double
  
  $self->config_data(
    type => \%type,
  );

  $self;
}

sub ACTION_dist
{
  my($self) = @_;
  $self->dispatch('distdir');
  my $dist_dir = $self->dist_dir;
  $self->make_tarball($dist_dir);
  # $self->delete_filetree($dist_dir);
}

sub ACTION_readme
{
  system $^X, 'inc/run/readme.pl';
}

sub Module::Build::FFI::Fortran::ExtUtilsF77::config_log
{
  my $config_log;
  open $config_log, '>>', 'config.log';
  print $config_log @_;
  close $config_log;
}

1;
