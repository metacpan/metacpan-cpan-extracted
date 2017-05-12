package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use ExtUtils::CppGuess;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;
  
  $args{c_source}           = 'xs';
  $args{include_dirs}       = 'include';
  
  my $self = $class->SUPER::new(
    ExtUtils::CppGuess->new->module_build_options,
    %args,
  );
  
  $self;
}

1;
