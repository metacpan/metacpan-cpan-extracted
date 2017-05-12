# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package Test::Plugin;
# ABSTRACT: Test Dist::Zilla::Role::Stash::Plugins

use strict;
use warnings;
use Moose;
with 'Dist::Zilla::Role::Plugin';

sub mvp_multivalue_args { qw(arr) }

has 'arr' => (
  is      => 'rw',
  isa     => 'ArrayRef',
  default => sub { [] },
);

has 'strung' => (
  is      => 'rw',
  isa     => 'Str',
  default => '',
);

has 'not' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'not',
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
