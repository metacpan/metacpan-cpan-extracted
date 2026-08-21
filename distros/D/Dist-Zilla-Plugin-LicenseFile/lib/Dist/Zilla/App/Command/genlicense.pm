package Dist::Zilla::App::Command::genlicense;
# ABSTRACT: write the LICENSE file into the repository

use Dist::Zilla::App -command;
use Dist::Zilla::Plugin::LicenseFile;
use Path::Tiny;

our $VERSION = '0.001';


sub abstract { 'write the LICENSE file into the repository' }

sub opt_spec { }

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla    = $self->zilla;
  my $plugin   = 'Dist::Zilla::Plugin::LicenseFile';
  my $filename = $plugin->filename;

  my $wanted = $plugin->wanted_text($zilla);
  my $file   = path($zilla->root)->child($filename);

  if ($file->exists && $plugin->comparable($file->slurp_utf8) eq $plugin->comparable($wanted)) {
    print "$filename is up to date\n";
    return;
  }

  $file->spew_utf8($wanted);
  print "wrote $filename\n";

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::genlicense - write the LICENSE file into the repository

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  dzil genlicense

=head1 DESCRIPTION

Writes C<LICENSE> into the root of the repository, holding the text of the
licence the distribution declares in F<dist.ini>. Commit the result — a licence
only counts on GitHub, Gitea or Forgejo if it is a file they can see.

This is the file L<Dist::Zilla::Plugin::LicenseFile> expects to find on every
build, so run the command again whenever the C<license> setting changes — the
plugin will tell you when that is.

What lands in the file is the bare licence, without the copyright notice
C<< ->fulltext >> would put above it; see
L<Dist::Zilla::Plugin::LicenseFile/Why the bare licence text>.

Writing the same text twice is a no-op, so the command is safe to run at any
time, and safe to wire into a release process.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::LicenseFile> — the build-time check this command satisfies

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-dist-zilla-plugin-licensefile/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
