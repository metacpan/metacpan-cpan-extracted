#!perl
use warnings;
use strict;
use Test::More;
use File::Find::Rule;

my $test_pod = eval 'use Test::Pod; 1';
my $coverage = eval 'use Pod::Coverage::CountParents; 1';

my @files = File::Find::Rule->file()->name('*.pm', '*.pod')->in('lib');
plan skip_all => "No modules" unless scalar @files;
plan tests => ( scalar @files * 3 ) + 1;

my $total_coverage;
my $total_files;

# We sort the files to make results predictable. We had a Heisenbug caused by a
# package jamming methods into another package's namespace; depending on
# whether the offending package was loaded before or after its victim this test
# would fail.
for my $file (sort @files) {
  SKIP: {
    skip "Test::Pod not installed", 1 unless $test_pod;
    pod_file_ok( $file );
  }

  SKIP: {
    skip "Pod::Coverage::CountParents not installed", 2 unless $coverage;
    skip "$file is not a module", 2 if $file =~ /pod$/;

    # read in the file and look for trustmes
    my $fh;
    open $fh, "<", $file
      or die "Can't read file $fh";
    my @trustme;
    while (<$fh>) {
      push @trustme, qr/^\Q$1\E$/ if (/^\s*#\s+(.*?) is documented\s*$/)
    }

    # work out the package that is
    my $package = $file;
    for ($package) {
    s|.*lib/||;
    s|/|::|g;
    s|\.pm$||;
  }

    # load the package
    my $pc = Pod::Coverage::CountParents->new(
      package => $package,
      trustme => [ @trustme, qr/db_(in|de)flate/ ]
    );

    # check if we got coverage or not
    my $coverage = $pc->coverage;
    if (defined $coverage) {
      ok( $coverage, "$file has POD" );
      ok( $coverage > 0.90, "$file has ".($coverage * 100)."% coverage > 90%" );
      diag(map {"Naked sub: $_\n"} $pc->naked);

      $total_coverage += $coverage;
      $total_files++;
    }
    else {
      ok( !($pc->why_unrated eq "couldn't find pod"), "$file has POD" );
      SKIP: {
        skip "$file has no subs", 1 if 1;
        # missing subs need no docs
      }
    }
  }
}

#
SKIP: {
  skip "Pod::Coverage::CountParents not installed", 1 unless $coverage;
  skip "no files with pod", 1 unless $total_files;
  my $average_coverage = $total_coverage / $total_files;
  ok( $average_coverage > 0.98,
    "Average POD coverage ". ( $average_coverage * 100 )."% > 98%" );
}

