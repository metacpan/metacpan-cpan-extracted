package Dist::Zilla::Role::BuildPL 6.015;
# ABSTRACT: Common ground for Build.PL based builders

use Moose::Role;

with qw(
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::TestRunner
);

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role is a helper for Build.PL based installers. It implements the
#pod L<Dist::Zilla::Plugin::BuildRunner> and L<Dist::Zilla::Plugin::TestRunner>
#pod roles, and requires you to implement the L<Dist::Zilla::Plugin::PrereqSource>
#pod and L<Dist::Zilla::Plugin::InstallTool> roles yourself.
#pod
#pod =cut

sub build {
  my $self = shift;

  return
    if -e 'Build' and (stat 'Build.PL')[9] <= (stat 'Build')[9];

  $self->log_debug("running $^X Build.PL");
  system $^X, 'Build.PL' and die "error with Build.PL\n";

  $self->log_debug("running $^X Build");
  system $^X, 'Build'    and die "error running $^X Build\n";

  return;
}

sub test {
  my ($self, $target, $arg) = @_;

  $self->build;

  my $job_count = $arg && exists $arg->{jobs}
                ? $arg->{jobs}
                : $self->default_jobs;
  my $jobs = "j$job_count";
  my $ho = "HARNESS_OPTIONS";
  local $ENV{$ho} = $ENV{$ho} ? "$ENV{$ho}:$jobs" : $jobs;

  my @testing = $self->zilla->logger->get_debug || $arg->{test_verbose} ? '--verbose' : ();

  $self->log_debug('running ' . join(' ', $^X, 'Build', 'test', @testing));
  system $^X, 'Build', 'test', @testing and die "error running $^X Build test\n";

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::BuildPL - Common ground for Build.PL based builders

=head1 VERSION

version 6.015

=head1 DESCRIPTION

This role is a helper for Build.PL based installers. It implements the
L<Dist::Zilla::Plugin::BuildRunner> and L<Dist::Zilla::Plugin::TestRunner>
roles, and requires you to implement the L<Dist::Zilla::Plugin::PrereqSource>
and L<Dist::Zilla::Plugin::InstallTool> roles yourself.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
