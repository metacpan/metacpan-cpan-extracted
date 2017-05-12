package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use FFI::CheckLib;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  check_lib_or_exit(
    lib => 'magic',
    symbol => [ map { "magic_$_" } qw( 
      open
      load
      file
      buffer
      close
    ),
  ] );
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

1;
