# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package Dist::Zilla::Stash::Test;
# ABSTRACT: Test Dist::Zilla::Role::Stash::Plugins

use strict;
use warnings;
use Moose;
with 'Dist::Zilla::Role::Stash::Plugins';

sub expand_package {
  my ($self, $pack) = @_;

  my %exp = qw(
    + Plus
    - Minus
    @ At
  );

  # escape the @ symbol to avoid spurious warnings and test failures on 5.8.x
  $pack =~ s/^(\@|[+-])/$exp{$1}::/;

  "Test::$pack";
}

1;
