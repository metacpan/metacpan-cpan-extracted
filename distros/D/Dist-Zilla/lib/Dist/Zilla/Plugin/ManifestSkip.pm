package Dist::Zilla::Plugin::ManifestSkip 6.010;
# ABSTRACT: decline to build files that appear in a MANIFEST.SKIP-like file

use Moose;
with 'Dist::Zilla::Role::FilePruner';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin reads a MANIFEST.SKIP-like file, as used by L<ExtUtils::MakeMaker>
#pod and L<ExtUtils::Manifest>, and prunes any files that it declares should be
#pod skipped.
#pod
#pod This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
#pod bundle.
#pod
#pod =attr skipfile
#pod
#pod This is the name of the file to read for MANIFEST.SKIP-like content.  It
#pod defaults, unsurprisingly, to F<MANIFEST.SKIP>.
#pod
#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla core plugins:
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>,
#pod L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
#pod L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>.
#pod
#pod Other modules: L<ExtUtils::Manifest>.
#pod
#pod =cut

has skipfile => (is => 'ro', required => 1, default => 'MANIFEST.SKIP');

sub prune_files {
  my ($self) = @_;
  my $files = $self->zilla->files;

  my $skipfile_name = $self->skipfile;
  my ($skipfile) = grep { $_->name eq $skipfile_name } @$files;
  unless (defined $skipfile) {
    $self->log_debug([ 'file %s not found', $skipfile_name ]);
    return;
  }

  my $content = $skipfile->content;

  # If the content has been generated in memory or changed from disk,
  # create a temp file with the content.
  # (Unfortunately maniskip can't read from a string ref)
  my $fh;
  if (! -f $skipfile_name || (-s $skipfile_name) != length($content)) {
    $fh = File::Temp->new;
    $skipfile_name = $fh->filename;
    $self->log_debug([ 'create temporary %s', $skipfile_name ]);
    print $fh $content;
    close $fh;
  }

  require ExtUtils::Manifest;
  ExtUtils::Manifest->VERSION('1.54');

  my $skip = ExtUtils::Manifest::maniskip($skipfile_name);

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $files }) {
    next unless $skip->($file->name);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ManifestSkip - decline to build files that appear in a MANIFEST.SKIP-like file

=head1 VERSION

version 6.010

=head1 DESCRIPTION

This plugin reads a MANIFEST.SKIP-like file, as used by L<ExtUtils::MakeMaker>
and L<ExtUtils::Manifest>, and prunes any files that it declares should be
skipped.

This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
bundle.

=head1 ATTRIBUTES

=head2 skipfile

This is the name of the file to read for MANIFEST.SKIP-like content.  It
defaults, unsurprisingly, to F<MANIFEST.SKIP>.

=head1 SEE ALSO

Dist::Zilla core plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<PruneCruft|Dist::Zilla::Plugin::PruneCruft>,
L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>.

Other modules: L<ExtUtils::Manifest>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
