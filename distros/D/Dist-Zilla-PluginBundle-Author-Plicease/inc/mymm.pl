package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;

sub myWriteMakefile
{
  my %args = @_;

  $args{PREREQ_PM}->{'Dist::Zilla::PluginBundle::Git'} = 0
    if $^O ne 'MSWin32' && !$ENV{PLICEASE_DZIL_NO_GIT};
  $args{PREREQ_PM}->{'Dist::Zilla::Plugin::PkgVersion::Block'} = 0
    if $] >= 5.014;
  
  WriteMakefile(%args);
}

1;
