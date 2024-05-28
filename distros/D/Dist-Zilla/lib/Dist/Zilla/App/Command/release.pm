package Dist::Zilla::App::Command::release 6.032;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   dzil release
#pod
#pod   dzil release --trial
#pod
#pod   # long form, jobs takes an integer
#pod   dzil release --jobs 9
#pod
#pod   # short form, same as above
#pod   dzil release -j 9
#pod
#pod This command is a very, very thin wrapper around the
#pod C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
#pod build, archive, and release your distribution using your Releaser plugins.
#pod
#pod Available options are:
#pod
#pod =over
#pod
#pod =item C<--trial>, will cause it to build a trial build.
#pod
#pod =item C<--jobs|-j=i>, number of test jobs run in parallel using L<Test::Harness|Test::Harness>.
#pod
#pod =back
#pod
#pod The default for L<Test::Harness|Test::Harness> is C<9>. The number of parallel jobs can also be specified setting C<HARNESS_OPTIONS>.
#pod
#pod     HARNESS_OPTIONS=j9
#pod
#pod See L<Test::Harness|Test::Harness> for more details.
#pod
#pod =cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
  [ 'jobs|j=i' => 'number of parallel test jobs to run' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla;
  {
    # isolate changes to RELEASE_STATUS to zilla construction
    local $ENV{RELEASE_STATUS} = $ENV{RELEASE_STATUS};
    $ENV{RELEASE_STATUS} = 'testing' if $opt->trial;
    $zilla = $self->zilla;
  }

  local $ENV{HARNESS_OPTIONS} = join ':', split(':', $ENV{HARNESS_OPTIONS} // ''), 'j'.$opt->jobs if $opt->jobs;
  $self->zilla->release;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::release - release your dist to the CPAN

=head1 VERSION

version 6.032

=head1 SYNOPSIS

  dzil release

  dzil release --trial

  # long form, jobs takes an integer
  dzil release --jobs 9

  # short form, same as above
  dzil release -j 9

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.

Available options are:

=over

=item C<--trial>, will cause it to build a trial build.

=item C<--jobs|-j=i>, number of test jobs run in parallel using L<Test::Harness|Test::Harness>.

=back

The default for L<Test::Harness|Test::Harness> is C<9>. The number of parallel jobs can also be specified setting C<HARNESS_OPTIONS>.

    HARNESS_OPTIONS=j9

See L<Test::Harness|Test::Harness> for more details.

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

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
