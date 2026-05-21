use strict;
use warnings;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use Path::Tiny;

# Author test: Check for leftover debug statements in source code
# Reports each offending line as a test failure

my @debug_failures;

# Find all Perl source files recursively
my @all_files;
path('lib')->visit(
  sub {
    my $file = $_[0];
    push @all_files, $file if $file->is_file && $file =~ /\.pm$/;
  },
  {recurse => 1}
);

path('bin')->visit(
  sub {
    my $file = $_[0];
    push @all_files, $file if $file->is_file;
  },
  {recurse => 1}
);

path('t')->visit(
  sub {
    my $file = $_[0];
    push @all_files, $file if $file->is_file && ($file =~ /\.t$/ || $file =~ /\.pm$/);
  },
  {recurse => 1}
);

# Check each file for debug statements
foreach my $file (sort @all_files) {
  my $content = $file->slurp_utf8;
  my @lines = split /\n/, $content;

  foreach my $i (0 .. $#lines) {
    my $line = $lines[$i];
    my $lineno = $i + 1;
    my $filename = $file->relative;

    # Skip comments (lines starting with # after whitespace)
    next if $line =~ /^\s*#/;

    # Check for leftover debug modules at start of line
    if ($line =~ /^use\s+(Data::Dumper|Data::Printer|Carp)/) {
      push @debug_failures, "$filename:$lineno - use $1 (debug module)";
      next;
    }

    # Check for debug functions at start of line (p, dumper, say, print, warn)
    if ($line =~ /^(print|p|dumper|say)\s*[\(\[]/) {
      push @debug_failures, "$filename:$lineno - $1() call (debug function)";
      next;
    }

    # Warn at start of line outside test files is suspicious
    if ($line =~ /^warn\s/ && $file !~ /\.t$/) {
      push @debug_failures, "$filename:$lineno - warn statement (non-test file)";
      next;
    }
  }
}

if (@debug_failures) {
  foreach my $failure (@debug_failures) {
    ok(0, "Debug statement: $failure");
  }
  ok(0, "Found " . scalar(@debug_failures) . " debug statement(s)");
} else {
  ok(1, 'No debug statements found in source');
}

done_testing();
