package Dist::Zilla::Plugin::TestRelease 6.032;
# ABSTRACT: extract archive and run tests before releasing the dist

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin runs before a release happens.  It will extract the to-be-released
#pod archive into a temporary directory and use the TestRunner plugins to run its
#pod tests.  If the tests fail, the release is aborted and the temporary directory
#pod is left in place.  If the tests pass, the temporary directory is cleaned up and
#pod the release process continues.
#pod
#pod This will set the RELEASE_TESTING and AUTHOR_TESTING env vars while running the
#pod test suite.
#pod
#pod =head1 CREDITS
#pod
#pod This plugin was originally contributed by Christopher J. Madsen.
#pod
#pod =cut

use File::pushd ();
use Dist::Zilla::Path;

sub before_release {
  my ($self, $tgz) = @_;
  $tgz = $tgz->absolute;

  my $build_root = $self->zilla->root->child('.build');
  $build_root->mkpath unless -d $build_root;

  my $tmpdir = path( File::Temp::tempdir(DIR => $build_root) );

  $self->log("Extracting $tgz to $tmpdir");

  require Archive::Tar;

  my @files = do {
    my $wd = File::pushd::pushd($tmpdir);
    Archive::Tar->extract_archive("$tgz");
  };

  $self->log_fatal([ "Failed to extract archive: %s", Archive::Tar->error ])
    unless @files;

  # Run tests on the extracted tarball:
  my $target = $tmpdir->child( $self->zilla->dist_basename );

  local $ENV{RELEASE_TESTING} = 1;
  local $ENV{AUTHOR_TESTING} = 1;
  $self->zilla->run_tests_in($target);

  $self->log("all's well; removing $tmpdir");
  $tmpdir->remove_tree({ safe => 0 });
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TestRelease - extract archive and run tests before releasing the dist

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin runs before a release happens.  It will extract the to-be-released
archive into a temporary directory and use the TestRunner plugins to run its
tests.  If the tests fail, the release is aborted and the temporary directory
is left in place.  If the tests pass, the temporary directory is cleaned up and
the release process continues.

This will set the RELEASE_TESTING and AUTHOR_TESTING env vars while running the
test suite.

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

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
