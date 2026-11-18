package Dist::Zilla::Plugin::Author::GETTY::InstallCheck;
# ABSTRACT: Test-install the release tarball with cpanm before it is uploaded
use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

our $VERSION = '0.328';


has command => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [ 'cpanm', '--test-only' ] },
);

sub mvp_multivalue_args { qw( command ) }

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  delete $args->{command} unless $args->{command} && @{ $args->{command} };
  return $args;
};

sub before_release {
  my ($self, $archive) = @_;
  my $tarball = $archive->absolute->stringify;
  my @cmd = (@{ $self->command }, $tarball);

  $self->log("testing the release tarball with $cmd[0] before the upload: $tarball");

  my $status;
  {
    local $ENV{RELEASE_TESTING};
    local $ENV{AUTHOR_TESTING};
    delete $ENV{RELEASE_TESTING};
    delete $ENV{AUTHOR_TESTING};
    $status = system { $cmd[0] } @cmd;
  }

  return if $status == 0;

  my $why = $status == -1 ? "could not run $cmd[0]: $!"
          : $status & 127 ? "$cmd[0] died of signal " . ($status & 127)
          :                 "$cmd[0] exited with " . ($status >> 8);
  my $home = $ENV{PERL_CPANM_HOME} || ($ENV{HOME} ? "$ENV{HOME}/.cpanm" : undef);
  my $log = $home ? "$home/build.log" : undef;
  my $hint = $log && -e $log ? " See the cpanm log: $log." : '';
  $self->log_fatal("The install test of $tarball failed ($why); nothing was uploaded.$hint");
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::GETTY::InstallCheck - Test-install the release tarball with cpanm before it is uploaded

=head1 VERSION

version 0.328

=head1 DESCRIPTION

Runs C<cpanm --test-only> on the release tarball before the release uploads it.
The tarball is unpacked, built and tested the way a user's C<cpanm> and a CPAN
tester do it: below cpanm's own working directory, outside of the checkout, from
C<blib>, with the author and release test switches off. Missing dependencies
come from C<~/perl5> or from CPAN, as they do for a user.

This catches what the tests inside the checkout and the C<.build> directory of
L<Dist::Zilla::Plugin::TestRelease> cannot: a test file that only passes there,
a requirement that is missing from the C<cpanfile>, a dependency that cannot be
resolved. The check has to run B<before> the upload, because an upload cannot be
taken back: once the version is on CPAN, a failed installation by
L<Dist::Zilla::Plugin::InstallRelease> comes too late.

C<RELEASE_TESTING> and C<AUTHOR_TESTING> are removed from the environment of
the command; the rest of the environment is passed through. A command that does
not end with 0 aborts the release, and nothing has been uploaded.

L<Dist::Zilla::PluginBundle::Author::GETTY> adds this plugin after
C<TestRelease> and before C<ConfirmRelease>, unless C<no_installrelease> or one
of the Alien options is set.

=head2 command

The command to run, as a list without shell. The tarball path is appended.
Default: C<cpanm --test-only>. Repeatable.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-dist-zilla-pluginbundle-author-getty/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
