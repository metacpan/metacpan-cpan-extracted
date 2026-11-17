package Dist::Zilla::Plugin::DBIO::RequireCoreVersion;
# ABSTRACT: Stop a release whose runtime prereq on DBIO lags behind the dist's own version
our $VERSION = '0.900007';
use Moose;
use version ();
with 'Dist::Zilla::Role::BeforeRelease';


sub before_release {
  my ($self) = @_;
  my $want = $self->zilla->version;
  my $have = $self->zilla->prereqs->requirements_for('runtime', 'requires')
    ->as_string_hash->{DBIO};
  my $line = "requires 'DBIO', '$want';";

  unless (defined $have) {
    $self->log_debug('no runtime prereq on DBIO, nothing to check');
    return;
  }

  my $min = $self->_minimum($have);
  $self->log_fatal("the cpanfile requires DBIO $have, below this dist's version $want -- change the cpanfile line to $line")
    if version->parse($min) < version->parse($want);

  $self->log_debug("DBIO $have required, dist version $want");
}

# The lowest version a requirement string allows: "0.9" or ">= 0.9, < 2" give
# 0.9, a string without a lower bound gives 0.
sub _minimum {
  my ($self, $req) = @_;
  for my $part (split /\s*,\s*/, $req) {
    return $1 if $part =~ /^(?:>=\s*)?([0-9][0-9._]*)\z/;
  }
  return 0;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::RequireCoreVersion - Stop a release whose runtime prereq on DBIO lags behind the dist's own version

=head1 VERSION

version 0.900007

=head1 DESCRIPTION

Part of the C<[@DBIO]> bundle for every distribution except the DBIO core. The
DBIO distributions are released together and a driver of version X is written
against the core API of version X. The F<cpanfile> of a driver says so with
C<requires 'DBIO', 'X'>, a line kept by hand.

Before the release this plugin reads the runtime prereq on C<DBIO> from the
prereqs of the distribution (the F<cpanfile> via
L<Dist::Zilla::Plugin::Prereqs::FromCPANfile>) and compares its minimum
version with the version being released. A minimum version lower than the
distribution's version aborts the release. The message names both versions and
the F<cpanfile> line to write. A minimum version above the distribution's is
accepted. Only the runtime phase counts. A distribution without a runtime prereq
on C<DBIO> (the bundle itself, the tombstones of DBIO-Deprecated) has nothing to
check and releases.

The plugin changes no prereq and gathers nothing; it only checks.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
