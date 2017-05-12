#!/usr/bin/perl

use strict;

use File::Temp;
use Test::More;
use lib 't';
use Mail::Mbox::MessageParser::Config;
use File::Spec::Functions qw(:ALL);
use Test::Utils;

# To prevent undef warnings
my $GREP = $Mail::Mbox::MessageParser::Config{'programs'}{'grep'} || 'grep';

my %tests = (
qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-1.txt')
  => ['grep_1','none'],
qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-2.txt')
  => ['grep_2','none'],
qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-3.txt')
  => ['grep_3','none'],
qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailseparators.txt')
  => ['grep_4','none'],
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
    print "Did not encounter an error executing the test when one was expected.\n\n";
    ok(0);
    return;
  }

  if ($? && !defined $error_expected)
  {
    print "Encountered an error executing the test when one was not expected.\n";
    print "See " . $test_stdout->filename . " and " . $test_stderr->filename .  ".\n\n";
    ok(0);
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

  unless (defined $Mail::Mbox::MessageParser::Config{'programs'}{'grep'})
  {
    $skip{qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-1.txt')}
    = 1;

    $skip{qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-2.txt')}
    = 1;

    $skip{qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailarc-3.txt')}
    = 1;

    $skip{qq`unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $GREP --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" ` . catfile('t','mailboxes','mailseparators.txt')}
    = 1;
  }

  return %skip;
}

# ---------------------------------------------------------------------------

