package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use 5.008001;
use lib 'share';
use My::DLL;

sub new
{
  my($class, %args) = @_;

  if(defined ${^GLOBAL_PHASE})
  {
    print "You have a working \${^GLOBAL_PHASE}\n";
  }
  else
  {
    print "You do not have a working \${^GLOBAL_PHASE} and will need to install Devel::GlobalDestruction\n";
    $args{requires}->{'Devel::GlobalDestruction'} = 0;
  }
  
  my $self = $class->SUPER::new(%args);
  
  $self->add_to_cleanup('share/libtcc.*');
  $self->add_to_cleanup('share/lib');
  $self->add_to_cleanup('share/build.log');
  
  $self;
}

sub ACTION_build
{
  my $self = shift;
  tcc_build() unless -e tcc_name();
  $self->SUPER::ACTION_build(@_)
}

sub ACTION_clean
{
  my $self = shift;
  tcc_clean();
  $self->SUPER::ACTION_clean(@_);
}

1;
