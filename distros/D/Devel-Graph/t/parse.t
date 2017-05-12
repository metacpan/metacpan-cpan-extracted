#!/usr/bin/perl -w

use Test::More;
use Test::Differences;
use strict;

# Parse test snippets from t/data/ and compare them to the stored output

BEGIN
   {
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Devel::Graph") or die($@);
   };

#############################################################################
# OO interface

my @files;

if (@ARGV)
  {
  @files = shift;
  plan tests => 2;
  }
else
  {
  # get all files to test
  opendir(DIR, 'data') or die("Can’t opendir 'data': $!");
  @files = readdir(DIR);
  closedir DIR;
  plan tests => 29;
  }

my $graph;
my @failures;

for my $file (sort @files)
  {
  next unless $file =~ /\.txt\z/;	# only *.txt

  # read in the file
  my $FILE;
  open ($FILE, "data/$file") or die("Can’t read 'data/$file': $!");
  my ($code, $line);
  my $expect = 'as_ascii';
  while (defined ($line = <$FILE>))
    {
    $expect = $1 if $line =~ /^# EXPECT:\s*(.*)/;
    $code = $line unless defined $code;
#    print STDERR "read: '$line";
    last if $line !~ /^(# |\s+\z)/;
    }
  $line = '' unless defined $line;

  # read the rest in
  local $/ = undef; 				# slurp mode
  my $output = $line . <$FILE>; $output = '' unless defined $output;
  close $FILE;

  $code =~ s/^#\s*//; 
#  print STDERR "# Testing data/$file:\n";
#  print STDERR "# Parsing snippet: $code";

  my $grapher = Devel::Graph->new();

  $grapher->reset();
#  $grapher->debug(1);
  $graph = undef; eval '$graph = $grapher->graph( \$code )';

  if ($expect =~ /error/)
    {
    if (! isnt ($grapher->error(), '', 'got some error'))
      {
      sleep(1); push @failures, 't/data/' . $file;
      }
    }
  else
    {
    print STDERR "# Error: " . $grapher->error() unless
      is (ref($graph), 'Graph::Easy', 'got reference');

    $expect =~ s/[^a-z_]//g;			# "as_ascii " => "as_ascii"
    my $expected = 'got no output'; $expected = $graph->$expect() if ref($graph);
    if (!eq_or_diff ($expected, $output, 'output matches'))
      {
      sleep(1); push @failures, 't/data/' . $file;
      }
    }
  }

print STDERR "# The following tests failed:\n" if @failures;
for my $file (@failures)
  {
  print STDERR "#  $file\n";
  }

