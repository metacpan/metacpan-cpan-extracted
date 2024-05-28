package Dist::Zilla::Plugin::PruneFiles 6.032;
# ABSTRACT: prune arbitrary files from the dist

use Moose;
with 'Dist::Zilla::Role::FilePruner';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod This plugin allows you to explicitly prune some files from your
#pod distribution. You can either specify the exact set of files (with the
#pod "filenames" parameter) or provide the regular expressions to
#pod check (using "match").
#pod
#pod This is useful if another plugin (maybe a FileGatherer) adds a
#pod bunch of files, and you only want a subset of them.
#pod
#pod In your F<dist.ini>:
#pod
#pod   [PruneFiles]
#pod   filename = xt/release/pod-coverage.t ; pod coverage tests are for jerks
#pod   filename = todo-list.txt             ; keep our secret plans to ourselves
#pod
#pod   match     = ^test_data/
#pod   match     = ^test.cvs$
#pod
#pod =cut

sub mvp_multivalue_args { qw(filenames matches) }
sub mvp_aliases { return { filename => 'filenames', match => 'matches' } }

#pod =attr filenames
#pod
#pod This is an arrayref of filenames to be pruned from the distribution.
#pod
#pod =cut

has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

#pod =attr matches
#pod
#pod This is an arrayref of regular expressions and files matching any of them,
#pod will be pruned from the distribution.
#pod
#pod =cut

has matches => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub prune_files {
  my ($self) = @_;

  # never match (at least the filename characters)
  my $matches_regex = qr/\000/;

  $matches_regex = qr/$matches_regex|$_/ for (@{ $self->matches });

  # \A\Q$_\E should also handle the `eq` check
  $matches_regex = qr/$matches_regex|\A\Q$_\E/ for (@{ $self->filenames });

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $self->zilla->files }) {
    next unless $file->name =~ $matches_regex;

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla plugins:
#pod L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
#pod L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
#pod L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PruneFiles - prune arbitrary files from the dist

=head1 VERSION

version 6.032

=head1 SYNOPSIS

This plugin allows you to explicitly prune some files from your
distribution. You can either specify the exact set of files (with the
"filenames" parameter) or provide the regular expressions to
check (using "match").

This is useful if another plugin (maybe a FileGatherer) adds a
bunch of files, and you only want a subset of them.

In your F<dist.ini>:

  [PruneFiles]
  filename = xt/release/pod-coverage.t ; pod coverage tests are for jerks
  filename = todo-list.txt             ; keep our secret plans to ourselves

  match     = ^test_data/
  match     = ^test.cvs$

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 filenames

This is an arrayref of filenames to be pruned from the distribution.

=head2 matches

This is an arrayref of regular expressions and files matching any of them,
will be pruned from the distribution.

=head1 SEE ALSO

Dist::Zilla plugins:
L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
L<GatherDir|Dist::Zilla::Plugin::GatherDir>,
L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
