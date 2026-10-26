package Dist::Zilla::Plugin::LicenseFile;
# ABSTRACT: Ship the repository's committed LICENSE, and keep it honest

use Moose;
with 'Dist::Zilla::Role::FileMunger';

use Path::Tiny;
use namespace::autoclean;

our $VERSION = '0.002';


has required => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1,
);


sub filename { 'LICENSE' }

sub wanted_text {
  my ($self, $zilla) = @_;
  return $zilla->license->license;
}

sub comparable {
  my ($self, $text) = @_;
  $text =~ s{\s+\z}{};
  return $text;
}

sub munge_files {
  my ($self) = @_;

  my $filename = $self->filename;
  my ($file) = grep { $_->name eq $filename } @{ $self->zilla->files };

  unless ($file) {
    return $self->_complain(
      "no $filename in the distribution: run 'dzil genlicense' and commit the file"
    );
  }

  my $wanted = $self->wanted_text($self->zilla);

  my $have = $self->comparable($file->content);
  $wanted  = $self->comparable($wanted);

  unless ($have eq $wanted) {
    my $differs = $self->_copyright_difference($have, $wanted)
      // "it no longer matches the license in dist.ini";
    return $self->_complain(
      "$filename is out of date: $differs. Run 'dzil genlicense' and commit the file"
    );
  }

  $self->_warn_floating_year($wanted);

  $self->log_debug("$filename matches the declared license");

  return;
}

# When the two texts differ on the copyright line(s) alone - same line count,
# every differing line mentions "copyright" - name both lines, so the reader is
# sent to copyright_holder / copyright_year rather than to the license setting.
sub _copyright_difference {
  my ($self, $have, $wanted) = @_;

  my @have   = split /\n/, $have;
  my @wanted = split /\n/, $wanted;
  return unless @have == @wanted;

  my @diff = grep { $have[$_] ne $wanted[$_] } 0 .. $#have;
  return if grep { $have[$_] !~ /copyright/i || $wanted[$_] !~ /copyright/i } @diff;

  my $at = $diff[0];
  return "only the copyright line differs from copyright_holder/copyright_year "
    . "in dist.ini (LICENSE says '$have[$at]', dist.ini says '$wanted[$at]')";
}

# A licence that embeds the year, with no copyright_year in dist.ini, is
# checked against the year Dist::Zilla takes from the clock: the check starts
# failing on 1 January.
sub _warn_floating_year {
  my ($self, $wanted) = @_;

  my $zilla = $self->zilla;
  my $year  = $zilla->_copyright_year;
  return unless $wanted =~ /\Q$year\E/;

  my $rights = $zilla->stash_named('%Rights');
  return if $rights && defined $rights->copyright_year;

  my $ini = path($zilla->root)->child('dist.ini');
  return if $ini->exists && $ini->slurp_utf8 =~ /^\s*copyright_year\s*=/m;

  $self->log(
    "copyright_year is not set in dist.ini: the year in the license floats with "
    . "the clock, and the check will fail on 1 January. Set copyright_year"
  );
  return;
}

sub _complain {
  my ($self, $message) = @_;
  return $self->required ? $self->log_fatal($message) : $self->log($message);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LicenseFile - Ship the repository's committed LICENSE, and keep it honest

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  ; in dist.ini — note that @Basic's License plugin has to go, it would
  ; generate a second LICENSE and the build would abort
  [@Filter]
  -bundle = @Basic
  -remove = License

  [LicenseFile]

Then write the file once and commit it:

  dzil genlicense
  git add LICENSE && git commit

=head1 DESCRIPTION

L<Dist::Zilla> generates C<LICENSE> into the build by default, which means the
file exists in the tarball on CPAN but never in the repository. Hosting
platforms only see the repository: GitHub, Gitea and Forgejo all detect and
link a licence from a committed C<LICENSE> file, so a distribution built the
default way shows up as unlicensed on its own project page.

The fix is to commit the file and let C<GatherDir> pick it up like any other
source file. That works, but it silently rots: nothing connects the committed
text to the C<license> setting in F<dist.ini> any more. Switch the licence and
the repository keeps serving the old one, with no warning and no build failure.

This plugin closes that gap. On every build it checks the C<LICENSE> that was
gathered from the repository against the licence the distribution declares, and
refuses to build when the file is missing or no longer matches. The companion
command L<dzil genlicense|Dist::Zilla::App::Command::genlicense> writes the file
the check expects.

The plugin never writes or modifies anything itself — the committed file is
shipped verbatim, and a build either passes the check or stops.

=head2 Why the bare licence text

The file holds C<< $zilla->license->license >>, the licence on its own, and
deliberately not C<< ->fulltext >>, which is what
L<Dist::Zilla::Plugin::License> writes into the build. C<fulltext> prefixes the
licence with a copyright notice for the current distribution, and that prefix
is enough to stop GitHub's detector: a repository whose C<LICENSE> holds the
C<fulltext> of the Artistic License 2.0 is reported as C<NOASSERTION> —
GitHub links the file but names no licence. The same repository with the bare
text is reported as C<Artistic-2.0>.

Since detection is the entire reason to commit the file, the bare text wins.
Nothing is lost: the copyright notice still reaches the tarball through the
C<LICENSE AND COPYRIGHT> section L<Pod::Weaver> writes into the POD, and the
holder and year still reach F<META.json>.

"Bare" does not mean free of holder and year, though: some licences embed the
copyright line in their own text. Perl 5's does, twice (C<This software is
Copyright (c) YYYY by H.>), while the Artistic License 2.0 does not. For such a
licence C<copyright_holder> and C<copyright_year> are part of the compared
text, and changing either makes the check fail until C<dzil genlicense> has
rewritten the file. The message then says that only the copyright line differs
and shows both lines, instead of blaming the C<license> setting.

That has one trap: a F<dist.ini> without C<copyright_year> gets the current
year from L<Dist::Zilla>, so the committed file goes out of date on 1 January
and every build stops until the file is regenerated and committed. The plugin
warns on every build when it sees that combination; set C<copyright_year> to
make the year stay put.

=head2 required

Whether a failing check aborts the build. Defaults to true.

Set it to C<0> to log the same complaint as a warning and carry on — useful
while migrating an existing distribution, where the first build is the thing
that tells you the file is missing.

  [LicenseFile]
  required = 0

=head2 filename

The name of the file, C<LICENSE>. A class method, so that
L<Dist::Zilla::App::Command::genlicense> writes the file this plugin looks for.

=head2 wanted_text

The text the committed file is expected to hold, for a given L<Dist::Zilla>
object. A class method shared with the command, see L</Why the bare licence
text> for what it returns and why.

=head2 comparable

Normalises licence text for comparison, and is likewise a class method shared
with the command. Only whitespace at the very end of the text is forgiven — an
editor adding a final newline is not drift, any other difference is.

Both halves have to agree on this, or a distribution can end up in a state
where C<dzil genlicense> reports the file as current and the build still
rejects it.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::App::Command::genlicense> — writes the file this plugin checks

=item *

L<Dist::Zilla::Plugin::License> — the default plugin, which generates C<LICENSE> into the build instead

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
