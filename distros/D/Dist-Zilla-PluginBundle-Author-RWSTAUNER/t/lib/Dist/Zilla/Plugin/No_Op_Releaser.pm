# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-PluginBundle-Author-RWSTAUNER
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
package # no_index
  Dist::Zilla::Plugin::No_Op_Releaser;
# ABSTRACT: Release by doing nothing (no-op)

use Moose;

with qw(
  Dist::Zilla::Role::Plugin
  Dist::Zilla::Role::Releaser
);

sub release {
  shift->log('Not releasing anything.  La la la...');
}

1;

=head1 DESCRIPTION

none.

=cut
