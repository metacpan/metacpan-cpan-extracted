package My::ModuleBuild;

use strict;
use warnings;
use 5.008001;
use base qw( Module::Build );

sub new
{
  my($class, %args) = @_;

  $args{requires}->{'Dist::Zilla::PluginBundle::Git'} = 0
    if $] >= 5.010001 && $^O ne 'MSWin32';
  $args{requires}->{'Dist::Zilla::Plugin::PkgVersion::Block'} = 0
    if $] >= 5.014;

  my $self = $class->SUPER::new(%args);
  
  return $self;
}

1;
