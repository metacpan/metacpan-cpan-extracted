package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  $args{c_source}     = 'xs';
  $args{include_dirs} = 'xs';
  
  my $self = $class->SUPER::new(%args);
  
  $self;
}

sub ACTION_build
{
  my($self, @args) = @_;
  
  system $^X, 'xs/typesize.pl';
  
  $self->SUPER::ACTION_build(@args);
}

1;
