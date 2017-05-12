package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use File::Spec;
use Config::AutoConf;
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
  
  my $ac = Config::AutoConf->new;
  $ac->check_default_headers;
  
  $ac->check_sizeof_type($_) for 
    ("short", "int", "long ", "unsigned short", "unsigned int",
     "unsigned long", "long long", "unsigned long long");
  
  my $config_h = File::Spec->catfile('xs', 'auto-typesize.h');
  
  $self->add_to_cleanup($config_h);
  $ac->write_config_h( $config_h );

  
  $self->SUPER::ACTION_build(@args);
}

1;
