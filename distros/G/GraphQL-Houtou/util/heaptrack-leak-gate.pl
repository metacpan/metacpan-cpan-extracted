#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;

use Getopt::Long qw(GetOptions);

my $max_leak_bytes = 0;
my $suppressions = 'util/heaptrack-perl.supp';
my $help = 0;

GetOptions(
  'max-leak-bytes=i' => \$max_leak_bytes,
  'suppressions=s' => \$suppressions,
  'help' => \$help,
) or usage(1);

usage(0) if $help;

my ($data_file) = @ARGV;
usage(1) unless defined $data_file;
die "heaptrack data file not found: $data_file\n" unless -e $data_file;

my @command = ('heaptrack_print', '-f', $data_file);
push @command, '--suppressions', $suppressions if length $suppressions && -e $suppressions;

open(my $fh, '-|', @command) or die "failed to run @command: $!\n";
local $/;
my $output = <$fh>;
close $fh;
die "heaptrack_print exited with status " . ($? >> 8) . " for $data_file\n" if $? != 0;

print $output;

my ($leaked) = $output =~ /^total memory leaked:\s*(\S+)\s*$/m;
die "could not find a 'total memory leaked' line in heaptrack_print output for $data_file\n"
  unless defined $leaked;

my $leaked_bytes = parse_byte_count($leaked);

printf "== heaptrack-leak-gate: %s leaked (%d bytes), gate is %d bytes, file=%s ==\n",
  $leaked, $leaked_bytes, $max_leak_bytes, $data_file;

if ($leaked_bytes > $max_leak_bytes) {
  die sprintf(
    "Heaptrack leak gate failed: %s (%d bytes) exceeds the %d byte gate for %s\n"
      . "(suppressions applied from %s; a real leak, or a new perl-internal noise source that needs a suppression, was introduced)\n",
    $leaked, $leaked_bytes, $max_leak_bytes, $data_file, $suppressions
  );
}

exit 0;

# heaptrack_print prints byte counts through its formatBytes() helper, which
# divides by 1000 (not 1024) per step and, at the default field width used
# in the summary lines, truncates the unit to its first letter (so "1.23KB"
# prints as "1.23K", "4.56MB" as "4.56M", while plain bytes keep the full
# "B"). See src/analyze/print/heaptrack_print.cpp upstream.
sub parse_byte_count {
  my ($text) = @_;
  my %scale = ( B => 1, K => 1_000, M => 1_000_000, G => 1_000_000_000, T => 1_000_000_000_000 );
  if ($text =~ /^(-?[0-9]+(?:\.[0-9]+)?)(B|K|M|G|T)$/) {
    return $1 * $scale{$2};
  }
  if ($text =~ /^-?[0-9]+(?:\.[0-9]+)?$/) {
    return $text + 0;
  }
  die "unrecognized byte value from heaptrack_print: '$text'\n";
}

sub usage {
  my ($exit) = @_;
  print <<"USAGE";
Usage: $0 DATA_FILE [--max-leak-bytes N] [--suppressions FILE]

Runs heaptrack_print against a recorded heaptrack data file, applies the
perl-interpreter-noise suppressions, parses the "total memory leaked" line,
and fails if it exceeds --max-leak-bytes (default: 0).
USAGE
  exit $exit;
}
