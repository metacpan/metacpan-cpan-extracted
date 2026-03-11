package LangerthaX::Engine::TestEngine;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}

1;
