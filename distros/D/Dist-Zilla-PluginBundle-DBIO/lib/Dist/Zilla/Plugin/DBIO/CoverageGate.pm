package Dist::Zilla::Plugin::DBIO::CoverageGate;
# ABSTRACT: Judge the Devel::Cover database after the whole test suite has run
our $VERSION = '0.900007';
use Moose;
use File::pushd ();
use Path::Tiny ();
use Scalar::Util 'blessed';
with 'Dist::Zilla::Role::TestRunner';


has coverage_threshold => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { $_[0]->payload->{coverage_threshold} // 80 },
);

sub test {
  my ($self, $target, $arg) = @_;

  my $threshold = $self->coverage_threshold;
  unless ($threshold > 0) {
    $self->log('coverage gate disabled (coverage_threshold = 0)');
    return;
  }

  # Dist::Zilla changes into the build directory and passes it relative to the
  # directory it came from, so a relative target means the current directory.
  my $root    = Path::Tiny::path($target);
  $root       = Path::Tiny->cwd if !$root->is_absolute;
  my $db_dir  = $root->child('cover_db');
  my $release = $ENV{RELEASE};

  # A release without a coverage run, or with one that measured nothing, is a
  # failed release: the gate must not pass by having nothing to look at.
  my $unmeasured = sub {
    my ($why) = @_;
    $self->log_fatal($why) if $release;
    $self->log("coverage not checked: $why");
    return;
  };

  return $unmeasured->('no cover_db/ -- run with HARNESS_PERL_SWITCHES=-MDevel::Cover')
    unless $db_dir->is_dir;
  return $unmeasured->("Devel::Cover::DB is required for the coverage gate: $@")
    unless eval { require Devel::Cover::DB; 1 };

  # Devel::Cover finds the source files of a run (structure, digests) by their
  # recorded relative path, so merge and read from the build directory.
  my $dir = File::pushd::pushd("$root");
  my $db = Devel::Cover::DB->new(db => "$db_dir");
  return $unmeasured->('cover_db/ is not a valid Devel::Cover database')
    unless $db->is_valid;

  # A coverage run leaves runs/ only; the merged database is what `cover`
  # makes. Merge here, so a fresh cover_db/ is scored.
  $db->merge_runs;
  my $cover = $db->cover;

  my (@per_module, $covered, $total);
  for my $file (sort $cover->items) {
    # Only the lib/ of this dist: a path relative to the build directory (or
    # absolute below it) that starts with lib/ or blib/lib/.
    (my $rel = $file) =~ s{^\Q$root\E/}{};
    next unless $rel =~ m{^(?:blib/)?lib/};

    my $f = $cover->file($file);
    next unless $f->items;
    my $crit = $f->criterion('statement') or next;

    my ($c_covered, $c_total) = (0, 0);
    for my $loc ($crit->items) {
      # An entry that is not a statement object counts as uncovered.
      for my $stmt (@{ $crit->location($loc) }) {
        $c_total++;
        $c_covered++ if blessed($stmt) && $stmt->can('val') && $stmt->val > 0;
      }
    }
    next unless $c_total;

    $covered += $c_covered;
    $total   += $c_total;
    push @per_module, { file => $rel, pct => 100 * $c_covered / $c_total };
  }

  return $unmeasured->('no lib/ file was measured in cover_db/') unless $total;

  my $overall = sprintf '%.1f', 100 * $covered / $total;
  if ($overall + 0 >= $threshold) {
    $self->log("statement coverage $overall% >= $threshold%");
    return;
  }

  # The 20 lowest modules, so a failure stays readable for a large dist.
  my @lowest = sort { $a->{pct} <=> $b->{pct} or $a->{file} cmp $b->{file} } @per_module;
  my $more   = @lowest > 20 ? @lowest - 20 : 0;
  splice @lowest, 20 if $more;
  my $msg = "statement coverage $overall% below threshold $threshold%; lowest first: "
    . join(', ', map { sprintf '%s %.1f%%', $_->{file}, $_->{pct} } @lowest)
    . ($more ? " and $more more" : '');
  $self->log_fatal($msg) if $release || $ENV{COVERAGE_STRICT};
  $self->log("$msg -- set COVERAGE_STRICT=1 or RELEASE=1 to enforce");
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::CoverageGate - Judge the Devel::Cover database after the whole test suite has run

=head1 VERSION

version 0.900007

=head1 DESCRIPTION

Part of the C<[@DBIO]> bundle. A coverage gate that runs B<after> the test
suite: it is a L<Dist::Zilla::Role::TestRunner> placed behind the build plugin
(C<MakeMaker> or C<MakeMaker::Awesome>), so L<Dist::Zilla> calls it once the
suite of the built distribution has finished. It reads the F<cover_db/> in the
build directory, which a suite run under C<HARNESS_PERL_SWITCHES=-MDevel::Cover>
has filled, and it scores the statement coverage of the distribution's own
F<lib/> (C<lib/> and C<blib/lib/> of the build directory; vendor code, perl's
own libraries and L<Devel::Cover> stay out). The gate runs for C<dzil test> and
C<dzil release>. It judges the whole run, also under a parallel harness, and
does not depend on the names or the directories of the test files.

The gate merges the runs of a fresh F<cover_db/> itself
(L<Devel::Cover::DB/merge_runs>), so a plain coverage run is scored without a
prior C<cover>.

A score below the threshold only logs a warning, so a low-coverage run never
blocks C<dzil test> for developers. With C<COVERAGE_STRICT=1> or C<RELEASE=1> in
the environment it aborts. A release without a measured coverage is a failed
release, so under C<RELEASE=1> the gate also aborts when there is no
F<cover_db/>, when L<Devel::Cover::DB> is not installed, when the database is
not valid, or when no F<lib/> file was measured; without C<RELEASE=1> these only
log a note. The failure names the overall score and then the 20 modules with
the lowest coverage, lowest first; a success names the overall score.

With a threshold of 0 the gate is off and only logs that.

=head1 ATTRIBUTES

=head2 coverage_threshold

Statement-coverage percentage required for a passing run. Default: 80.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
