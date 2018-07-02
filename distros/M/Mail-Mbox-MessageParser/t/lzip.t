#!/usr/bin/perl

use strict;

use File::Temp qw(tempfile);
use Test::More;
use lib 't';
use Test::Utils;
use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;
use File::Spec::Functions qw(:ALL);

# To prevent undef warnings
my $LZIP = $Mail::Mbox::MessageParser::Config{'programs'}{'lzip'} || 'lzip';
my $CAT = $Mail::Mbox::MessageParser::Config{'programs'}{'cat'} || 'cat';

my %tests = (
 qq{"$CAT" "} . catfile('t','mailboxes','mailarc-2.txt.lz') . qq{" | "$LZIP" -cd} => ['mailarc-2.txt','none'],
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

  my ($test_stdout_fh, $test_stdout_fn) = tempfile();
  $test_stdout_fh->close();
  my ($test_stderr_fh, $test_stderr_fn) = tempfile();
  $test_stderr_fh->close();

  system "$test 1>$test_stdout_fn 2>" . $test_stderr_fn;

  if (!$? && defined $error_expected)
  {
    ok(0,"Did not encounter an error executing the test when one was expected.\n\n");
    return;
  }

  if ($? && !defined $error_expected)
  {
    ok(0,"Encountered an error executing the test when one was not expected.\n" .
      "See $test_stdout_fn and $test_stderr_fn.\n\n");
    return;
  }


  my $real_stdout = catfile('t','results',$stdout_file);
  my $real_stderr = catfile('t','results',$stderr_file);

  CheckDiffs([$real_stdout,$test_stdout_fn],[$real_stderr,$test_stderr_fn]);
}

# ---------------------------------------------------------------------------

sub SetSkip
{
  my %tests = %{ shift @_ };

  my %skip;

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'lzip'})
  {
    $skip{qq{"$CAT" "} . catfile('t','mailboxes','mailarc-2.txt.lz') . qq{" | "$LZIP" -cd}}
      = 'lzip not available';
  }

  return %skip;
}

# ---------------------------------------------------------------------------

