package Dist::Zilla::Plugin::DBIO::CoverageTest;
# ABSTRACT: Generate xt/release/coverage.t from a Devel::Cover DB
use Moose;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';


has coverage_threshold => (
  is      => 'ro',
  isa     => 'Int',
  lazy    => 1,
  default => sub { $_[0]->payload->{coverage_threshold} // 80 },
);

sub gather_files {
  my ($self) = @_;
  $self->add_file(Dist::Zilla::File::InMemory->new(
    name    => 'xt/release/coverage.t',
    content => $self->_template,
  ));
  $self->log_debug('gathered xt/release/coverage.t');
}

# Build the test script. The body is a heredoc so the perl inside is easy
# to read and the placeholders stay obvious -- no string-formatting surprises.
sub _template {
  my ($self) = @_;
  my $threshold = $self->coverage_threshold;

  # If the threshold is 0 (or negative) the test degenerates to a no-op
  # skip -- the bundle still gathers the file, but it never fails and never
  # reports a number. Useful for distributions that opt out of coverage.
  my $body = $threshold > 0 ? $self->_strict_body : $self->_off_body;
  $body =~ s/__THRESHOLD__/$threshold/g;
  return $body;
}

sub _strict_body {
  return <<'PERL';
use strict;
use warnings;
use FindBin;
use Cwd;
use Test::More;

# Resolve the dist root: the parent of t/ when the test was rewritten from
# xt/release/coverage.t (dzil test/release layout), or $FindBin::Bin if run
# straight from xt/release/. Then chdir there so the relative 'cover_db/'
# path resolves no matter where the harness invoked us from.
my $dist_root = -d 'cover_db' ? Cwd::getcwd() : $FindBin::Bin;
$dist_root =~ s{/t$}{};
chdir $dist_root or die "chdir $dist_root: $!"
  unless Cwd::getcwd() eq $dist_root;

my $THRESHOLD = __THRESHOLD__;

if (! -d 'cover_db') {
  plan skip_all => 'No cover_db/ -- run with HARNESS_PERL_SWITCHES=-MDevel::Cover';
}

# Hard dependency on Devel::Cover::DB at test-time (recorded in cpanfile
# under on test). If a downstream install strips it, fail loud rather than
# silently mark the test as passed.
eval { require Devel::Cover::DB; 1 }
  or plan skip_all => "Devel::Cover::DB required for coverage test: $@";

my $db = Devel::Cover::DB->new(db => 'cover_db');
unless ($db->is_valid) {
  plan skip_all => 'cover_db/ is not a valid Devel::Cover database';
}

# Materialise the merged run data. Devel::Cover::DB->cover is lazy: it
# reads structure + runs on first call and returns a Cover handle.
my $cover = $db->cover;

my (@per_module, $covered, $total);
for my $file (sort $cover->items) {
  # Only score the distribution's own lib/ -- vendor and Devel::Cover itself
  # are out of scope.
  next unless $file =~ m{(?:^|/)lib/};
  next if $file =~ m{(?:^|/)Devel/Cover};

  my $f = $cover->file($file);
  next unless $f->items;  # no data for this file

  # Statement criterion may be absent if Devel::Cover was started without it.
  my $crit = $f->criterion('statement');
  my @locs = $crit ? $crit->items : ();
  unless (@locs) {
    push @per_module, { file => $file, pct => 'n/a', note => 'no statement data' };
    next;
  }

  my ($c_covered, $c_total) = (0, 0);
  for my $loc (@locs) {
    my $loc_data = $crit->location($loc);
    # Each location is an arrayref of Devel::Cover::Statement objects;
    # a statement with val > 0 was executed.
    for my $stmt (@$loc_data) {
      $c_total++;
      $c_covered++ if ref($stmt) && $stmt->can('val') && $stmt->val > 0;
    }
  }

  next unless $c_total;
  my $pct = 100 * $c_covered / $c_total;
  $covered += $c_covered;
  $total   += $c_total;
  push @per_module, { file => $file, pct => sprintf('%.1f', $pct), covered => $c_covered, total => $c_total };
}

if (!$total) {
  plan skip_all => 'No lib/ files were exercised under coverage';
}

my $overall = sprintf '%.1f', 100 * $covered / $total;

my $strict = $ENV{COVERAGE_STRICT} || $ENV{RELEASE};
my @diag = map { "  $_->{file}: $_->{pct}%$_->{note}" } @per_module;

if ($overall + 0 >= $THRESHOLD) {
  pass("statement coverage $overall% >= $THRESHOLD%");
  diag("coverage per module:\n", join("\n", @diag)) if @diag;
  done_testing;
}
else {
  my $msg = "statement coverage $overall% below threshold $THRESHOLD%";
  if ($strict) {
    fail($msg);
    diag("coverage per module:\n", join("\n", @diag));
    done_testing;
  }
  else {
    $msg .= " -- set COVERAGE_STRICT=1 or RELEASE=1 to enforce";
    pass($msg);
    diag("coverage per module:\n", join("\n", @diag));
    diag("run with COVERAGE_STRICT=1 (or RELEASE=1) to turn this into a failure");
    done_testing;
  }
}
PERL
}

sub _off_body {
  return <<'PERL';
use strict;
use warnings;
use Test::More;
plan skip_all => 'coverage enforcement disabled (coverage_threshold = 0)';
PERL
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::CoverageTest - Generate xt/release/coverage.t from a Devel::Cover DB

=head1 VERSION

version 0.900003

=head1 DESCRIPTION

Gathers an F<xt/release/coverage.t> test that, after a coverage run of
F<dzil test>, reads F<cover_db/> and checks that statement coverage of the
modules under F<lib/> meets a threshold. The threshold is configurable
via the C<coverage_threshold> option (default 80).

By default the test emits a TAP skip when coverage is below the threshold
so a missing or low-coverage run never blocks `dzil test` for developers.
Set C<COVERAGE_STRICT=1> or C<RELEASE=1> in the environment to flip the
same gap into a failure -- that is how `dzil release` enforces coverage.

The test must be installed by F<[ExtraTests]> before it counts as a real
release test, so this plugin is wired into F<[@DBIO]> B<before>
F<[ExtraTests]> in F<Dist::Zilla::PluginBundle::DBIO>.

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
