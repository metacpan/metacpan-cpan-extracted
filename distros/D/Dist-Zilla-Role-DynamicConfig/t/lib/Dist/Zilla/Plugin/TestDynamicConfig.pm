# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Role-DynamicConfig
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Plugin::TestDynamicConfig;
# ABSTRACT: Test Dist::Zilla::Role::DynamicConfig

use strict;
use warnings;
use Moose;
with qw(
  Dist::Zilla::Role::DynamicConfig
  Dist::Zilla::Role::Plugin
);

has 'extra' => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);

sub separate_local_config {
  my ($self, $config) = @_;
  my %other = (extra => delete $config->{extra} || '');
  return \%other;
}

no Moose;
1;
