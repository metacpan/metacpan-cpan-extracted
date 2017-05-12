#!/usr/bin/perl

use strict;

use File::Temp;
use Test::More;
use lib 't';
use Test::Utils;
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use File::Spec::Functions qw(:ALL);

# To prevent undef warnings
my $GZIP = $Mail::Mbox::MessageParser::Config{'programs'}{'gzip'} || 'gzip';
my $CAT = $Mail::Mbox::MessageParser::Config{'programs'}{'cat'} || 'cat';

my %tests = (
 qq{"$CAT" "} . catfile('t','mailboxes','mailarc-2.txt.gz') . qq{" | "$GZIP" -cd} => ['mailarc-2.txt','none'],
);

my %expected_errors = (
);

plan (tests => scalar (keys %tests));

my %skip = SetSkip(\%tests);

foreach my $test (sort keys %tests) 
{
  print "Running test:\n  $test\n";

  SKIP:
  {
    skip("$skip{$test}",1) if exists $skip{$test};

    TestIt($test, $tests{$test}, $expected_errors{$test});
  }
}

# ---------------------------------------------------------------------------

sub TestIt
{
  my $test = shift;
  my ($stdout_file,$stderr_file) = @{ shift @_ };
  my $error_expected = shift;

  my $testname = [splitdir($0)]->[-1];
  $testname =~ s/\.t//;

  my $test_stdout = File::Temp->new();
  $test_stdout->close();
  my $test_stderr = File::Temp->new();
  $test_stderr->close();

  system "$test 1>" . $test_stdout->filename . " 2>" . $test_stderr->filename;

  if (!$? && defined $error_expected)
  {
    ok(0,"Did not encounter an error executing the test when one was expected.\n\n");
    return;
  }

  if ($? && !defined $error_expected)
  {
    ok(0,"Encountered an error executing the test when one was not expected.\n" .
      "See " . $test_stdout->filename . " and " . $test_stderr->filename . ".\n\n");
    return;
  }


  my $real_stdout = catfile('t','results',$stdout_file);
  my $real_stderr = catfile('t','results',$stderr_file);

  CheckDiffs([$real_stdout,$test_stdout->filename],[$real_stderr,$test_stderr->filename]);
}

# ---------------------------------------------------------------------------

sub SetSkip
{
  my %tests = %{ shift @_ };

  my %skip;

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'gzip'})
  {
    $skip{qq{"$CAT" "} . catfile('t','mailboxes','mailarc-2.txt.gz') . qq{" | "$GZIP" -cd}}
      = 'gzip not available';
  }

  return %skip;
}

# ---------------------------------------------------------------------------

