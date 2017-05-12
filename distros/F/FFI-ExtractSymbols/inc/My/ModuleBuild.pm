package My::ModuleBuild;

use strict;
use warnings;
use File::Which qw( which );
use FFI::CheckLib qw( find_lib );
use base qw( Module::Build::FFI );

sub new
{
  my($class, %args) = @_;
  
  $args{ffi_libtest_optional} = 0;
  
  my $self = $class->SUPER::new(%args);
 
  my $exe = {};
  foreach my $name (qw( nm objdump dumpbin readelf ))
  {
    $exe->{$name} = which($name);
    unless(defined $exe->{$name})
    {
      my $try = $ENV{"FFI_EXTRACTSYMBOLS_" . uc $name};
      $exe->{$name} = $try if -e $try;
    }
  }
  
  $self->config_data( exe => $exe );
  
  if($^O =~ /^(cygwin|MSWin32)$/)
  {
    unless(defined $exe->{dumpbin})
    {
      print STDERR "dumpbin is required on this platform.\n";
      exit;
    }
    $self->config_data( 'ms_windows' => 1 );
  }
  else
  {
    unless(defined $exe->{nm})
    {
      print STDERR "nm is required on this platform.\n";
      exit;
    }
    if($^O eq 'openbsd')
    {
      $self->config_data( 'openbsd_nm' => 1 );
    }
    else
    {
      # we assume that everyone else is going to support 
      # nm -g -P foo.so
      # although I have no way of testing AIX, HP-UX
      $self->config_data( 'posix_nm' => 1 );
    }
  }
  
  $self;
}

sub ACTION_probe_libtest
{
  my($self) = shift;
  
  if($self->config_data('posix_nm'))
  {

    $self->depends_on('libtest');
    my $lib = find_lib lib => 'test', symbol => 'my_function', libpath => 'libtest';
    die "unable to find libtest!" unless defined $lib;
    
    my $nm = $self->config_data('exe')->{nm};
    
    my @lines = `$nm -g -P $lib`;

    my $function = '';
    my $variable = '';

    foreach my $line (@lines)
    {
      if($line =~ /^(_?)my_function ([A-Za-z])/)
      {
        $self->config_data( function_prefix => $1 );
        $self->config_data( function_code   => $2 );
        $function = 1;
      }
      if($line =~ /^(_?)my_variable ([A-Za-z])/)
      {
        $self->config_data( data_prefix => $1 );
        $self->config_data( data_code   => $2 );
        $variable = 1;
      }
    }

    unless($function || $variable)
    {
      print STDERR "unable to find my_function from nm output\n" unless $function;
      print STDERR "unable to find my_variable from nm output\n" unless $variable;
      print STDERR "[out]\n";
      print STDERR $_ for @lines;
      die "missing some symbols in nm output scan";
    }
  }
}

sub ACTION_build
{
  my $self = shift;
  $self->depends_on('probe_libtest');
  $self->SUPER::ACTION_build(@_);
}

1;
