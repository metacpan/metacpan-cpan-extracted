package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Which qw( which );

sub myWriteMakefile
{
  my %args = @_;

  $args{PREREQ_PM}->{'Dist::Zilla::PluginBundle::Git'} = 0 if which 'git';

  WriteMakefile(%args);
}

1;
