package Dist::Zilla::Plugin::MakeMaker::Runner 6.032;
# ABSTRACT: Test and build dists with a Makefile.PL

use Moose;
with(
  'Dist::Zilla::Role::BuildRunner',
  'Dist::Zilla::Role::TestRunner',
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

use Config;

has 'make_path' => (
  isa => 'Str',
  is  => 'ro',
  default => $Config{make} || 'make',
);

sub build {
  my $self = shift;

  my $make = $self->make_path;

  my $makefile = $^O eq 'VMS' ? 'Descrip.MMS' : 'Makefile';

  return
    if -e $makefile and (stat 'Makefile.PL')[9] <= (stat $makefile)[9];

  $self->log_debug("running $^X Makefile.PL");
  system($^X => qw(Makefile.PL INSTALLMAN1DIR=none INSTALLMAN3DIR=none)) and die "error with Makefile.PL\n";

  $self->log_debug("running $make");
  system($make) and die "error running $make\n";

  return;
}

sub test {
  my ($self, $target, $arg) = @_;

  my $make = $self->make_path;
  $self->build;

  my $job_count = $arg && exists $arg->{jobs}
                ? $arg->{jobs}
                : $self->default_jobs;

  my $jobs = "j$job_count";
  my $ho = "HARNESS_OPTIONS";
  local $ENV{$ho} = $ENV{$ho} ? "$ENV{$ho}:$jobs" : $jobs;

  $self->log_debug(join(' ', "running $make test", ( $self->zilla->logger->get_debug ? 'TEST_VERBOSE=1' : () )));
  system($make, 'test',
    ( $self->zilla->logger->get_debug || $arg->{test_verbose} ? 'TEST_VERBOSE=1' : () ),
  ) and die "error running $make test\n";

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MakeMaker::Runner - Test and build dists with a Makefile.PL

=head1 VERSION

version 6.032

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
