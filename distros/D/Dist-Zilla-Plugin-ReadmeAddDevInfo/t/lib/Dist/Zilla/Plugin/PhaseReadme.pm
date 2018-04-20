package # no_index
  Dist::Zilla::Plugin::PhaseReadme;

use strict;
use warnings;

use Moose;
with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
);

sub after_build {
  $_[0]->wrap('build');
}

sub after_release {
  $_[0]->wrap('release');
}

sub wrap {
  my ($self, $phase) = @_;
  my ($file) = grep { $_->basename =~ /README/ } $self->zilla->root->children;
  $file->spew(
    # Wrap previous content in phase markers to show when edits appear.
    join "\n\n", $phase, scalar($file->slurp), $phase,
  );
}

1;
