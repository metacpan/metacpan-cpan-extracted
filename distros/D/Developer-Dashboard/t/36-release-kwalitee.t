use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

BEGIN {
    eval {
        require Module::CPANTS::Analyse;
        require Module::CPANTS::Kwalitee;
        1;
    }
      or plan skip_all => 'Module::CPANTS::Analyse is required for the release kwalitee gate';
}

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

opendir( my $dh, $ROOT ) or die "Unable to read $ROOT: $!";
my @tarballs = sort grep { /^Developer-Dashboard-\d+\.\d+\.tar\.gz$/ && -f File::Spec->catfile( $ROOT, $_ ) } readdir($dh);
rewinddir($dh) or die "Unable to rewind $ROOT: $!";
my @build_dirs = sort grep { /^Developer-Dashboard-\d+\.\d+$/ && -d File::Spec->catdir( $ROOT, $_ ) } readdir($dh);
closedir($dh) or die "Unable to close $ROOT: $!";

plan skip_all => 'build the release tarball first with dzil build'
  if !@tarballs;

is( scalar @tarballs, 1, 'exactly one release tarball is present for the kwalitee gate' );
ok( scalar @build_dirs <= 1, 'at most one unpacked release build directory is present for the kwalitee gate' );

my $tarball  = File::Spec->catfile( $ROOT, $tarballs[-1] );
my $tarball_stem = $tarballs[-1];
$tarball_stem =~ s/\.tar\.gz\z//;
if (@build_dirs) {
    is( $build_dirs[-1], $tarball_stem, 'the unpacked build directory matches the single release tarball version when present' );
}
else {
    pass('kwalitee gate can analyse the single release tarball even when the unpacked build directory has already been cleaned up');
}
my $report   = Module::CPANTS::Analyse->new( { dist => $tarball } )->run;
my $kwalitee = $report->{kwalitee} || {};

ok( ref($kwalitee) eq 'HASH', 'CPANTS analyser returns a kwalitee hash for the release tarball' );

my @indicators = sort grep { $_ ne 'kwalitee' } keys %{$kwalitee};
ok( scalar @indicators > 0, 'release kwalitee analysis exposes concrete indicators' );

my @failing = grep { !$kwalitee->{$_} } @indicators;
is( scalar @failing, 0, 'all release kwalitee indicators pass' )
  or diag( 'Failing indicators: ' . join( ', ', @failing ) );
is( $kwalitee->{kwalitee}, scalar @indicators, 'release kwalitee score reaches 100%' )
  or diag( explain( { kwalitee => $kwalitee, errors => $report->{error} || {} } ) );

done_testing;

__END__

=pod

=head1 NAME

t/36-release-kwalitee.t - enforce 100 percent CPANTS kwalitee for the release tarball

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the release kwalitee gate. Read it when you need to understand the real fixture setup, assertions, and failure modes for the tarball-level CPANTS analysis instead of guessing from a stale website score.

=head1 WHY IT EXISTS

It exists because release kwalitee is measured on the built tarball, not on the source checkout, and that difference is easy to miss during local verification. Keeping the exact tarball analysis in a dedicated test file makes the TDD loop, release loop, and PAUSE verification concrete.

=head1 WHEN TO USE

Use this file after C<dzil build>, when changing release metadata or packaging rules, when chasing a CPANTS or kwalitee drift report, or when you want a focused gate before a PAUSE upload.

=head1 HOW TO USE

Build the tarball first, then run C<prove -lv t/36-release-kwalitee.t> from the repository root. The test locates the single C<Developer-Dashboard-X.XX.tar.gz> artifact, tolerates the unpacked C<Developer-Dashboard-X.XX/> build directory being absent after later cleanup, analyzes the tarball with C<Module::CPANTS::Analyse>, and fails unless every reported indicator passes.

=head1 WHAT USES IT

Developers during release verification, the CPAN release workflow, and any local PAUSE preparation that needs a deterministic 100 percent kwalitee guard rely on this file to keep the release artifact honest.

=head1 EXAMPLES

Example 1:

  rm -rf Developer-Dashboard-* Developer-Dashboard-*.tar.gz
  dzil build
  prove -lv t/36-release-kwalitee.t

Build the release tarball and verify the exact artifact reaches 100 percent kwalitee.

Example 2:

  dashboard pause-release --dry-run

Preview the release path, then run this focused kwalitee gate before the real upload if you changed packaging metadata.

Example 3:

  prove -lr t

Put any related release-metadata or packaging fix back through the full repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
