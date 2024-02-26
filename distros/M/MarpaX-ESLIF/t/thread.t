use strict;
use warnings FATAL => 'all';

#
# Note that we do not use diag() within thread because it seems to me
# that is reordering the output, hiding the fact that threads run in
# parallel, in contrary to $log->trace().
#

BEGIN {
    use Config;
    if (! $Config{usethreads}) {
        print("1..0 # Skip: No threads\n");
        exit(0);
    }
}

use threads;
use threads::shared;
use Log::Any qw/$log/;
use Log::Any::Adapter 'Stdout';
use constant { NTHREAD => 3 };
use Test::More;

my $number_of_tests_in_unit_test = 10;
my $number_of_tests = 1 + ((NTHREAD + 1) * $number_of_tests_in_unit_test);
my $nwaitingGoSignal = 0;
my $go = 0;

share($nwaitingGoSignal);
share($go);

BEGIN {
    diag("Using " . NTHREAD . " threads");
    require_ok('MarpaX::ESLIF');
}

my $grammar = q{
Expression ::=
    /[\d]+/
    | '(' Expression ')'              assoc => group
   ||     Expression '**' Expression  assoc => right
   ||     Expression  '*' Expression
    |     Expression  '/' Expression
   ||     Expression  '+' Expression
    |     Expression  '-' Expression
};

my $input = '(1+2)*3';
my $expected = '(1+2)*3';

sub trace_and_ok {
    my ($condition, $trace) = @_;
    #
    # This method ensures that there is a trace (used to see that threads are truely running in parallel)
    # and to call ok() (output of the later is digested by Test package before being printed out, so we
    # cannot use ok() to "see" that threads are running... in parallel)
    #
    $log->trace($trace);
    ok($condition, $trace);
}

my ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger, $eslifGrammar, $eslifGrammar2) = unit_test();

sub thr_sub {
  my $tid = threads->tid();
  {
      lock($go);
      $log->trace("[Thread $tid] Waiting for go signal");
      {
          lock($nwaitingGoSignal);
          $nwaitingGoSignal++;
      }
      cond_wait($go) until $go;
  }

  unit_test();

  $log->trace("[Thread $tid] Ending");
}

my $tid = threads->tid(); # This is main thread in fact
my @t = grep { defined } map {
    my $thr = threads->create(\&thr_sub, $input, $expected);
    $log->warn("[Thread $tid] threads->create failure, $!") if ! defined($thr);
    $thr;
} (1..NTHREAD);
$log->trace("[Thread $tid] Number of threads created: " . scalar(@t));

#
# Wait for all threads to signal they are ready
#
while (1) {
    my $canExitWhile = 0;
    {
        lock($nwaitingGoSignal);
        if ($nwaitingGoSignal == scalar(@t)) {
            $canExitWhile = 1;
        }
    }
    last if $canExitWhile;
    sleep(1);
}

#
# Ensure parallelization by waking up all threads
#
{
    lock($go);
    $go = 1;
    $log->trace("[Thread $tid] Broadcasting go signal");
    cond_broadcast($go);
}

my $remains = scalar(@t);
while ($remains) {
    foreach (@t) {
        next unless $_->is_joinable;
        $_->join;
        --$remains
    }
}

sub test_eslif_multiton {
    my $tid = threads->tid();

    #
    # 6 tests
    #
    $log->trace("[Thread $tid] Testing ESLIF multiton creation with logger=$log");
    my $eslif_with_logger = MarpaX::ESLIF->new($log);
    trace_and_ok(defined($eslif_with_logger), "[Thread $tid] \$eslif_with_logger is defined");
    my $eslif2_with_logger = MarpaX::ESLIF->new($log);
    trace_and_ok(defined($eslif2_with_logger), "[Thread $tid] \$eslif2_with_logger is defined");

    trace_and_ok($eslif_with_logger == $eslif2_with_logger, "[Thread $tid] ESLIF multiton with logger $eslif_with_logger == $eslif2_with_logger");

    $log->trace("[Thread $tid] Testing ESLIF multiton creation without logger");
    my $eslif_without_logger = MarpaX::ESLIF->new();
    trace_and_ok(defined($eslif_without_logger), "[Thread $tid] \$eslif_without_logger is defined");
    my $eslif2_without_logger = MarpaX::ESLIF->new();
    trace_and_ok(defined($eslif2_without_logger), "[Thread $tid] \$eslif2_without_logger is defined");

    trace_and_ok($eslif_without_logger == $eslif2_without_logger, "[Thread $tid] ESLIF multiton without logger $eslif_without_logger == $eslif2_without_logger");

    return ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger);
}

sub test_eslifGrammar_multiton {
    my ($eslif) = @_;

    #
    # 3 tests
    #
    my $tid = threads->tid();

    $log->trace("[Thread $tid] Testing ESLIFGrammar multiton using $eslif");
    my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar);
    trace_and_ok(defined($eslifGrammar), "[Thread $tid] \$eslifGrammar is defined");
    my $eslifGrammar2 = MarpaX::ESLIF::Grammar->new($eslif, $grammar);
    trace_and_ok(defined($eslifGrammar2), "[Thread $tid] \$eslifGrammar2 is defined");

    trace_and_ok($eslifGrammar == $eslifGrammar2, "[Thread $tid] ESLIFGrammar multiton $eslifGrammar == $eslifGrammar2");

    return ($eslifGrammar, $eslifGrammar2);
}

sub valuation_test {
    my ($eslifGrammar) = @_;

    my $tid = threads->tid();

    #
    # 1 test
    #
    my $eslifRecognizerInterface = MyRecognizerInterface->new($input);
    my $eslifValueInterface = MyValueInterface->new();

    $log->trace("[Thread $tid] Testing parse()");
    $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface);
    my $value = $eslifValueInterface->getResult;
    is($value, $expected, "[Thread $tid] value $value == expected $expected");
}

sub unit_test {
    #
    # 6 tests
    #
    my ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger) = test_eslif_multiton();

    #
    # 3 tests
    #
    my ($eslifGrammar, $eslifGrammar2) = test_eslifGrammar_multiton($eslif_with_logger);

    #
    # 1 test
    #
    valuation_test($eslifGrammar);

    return ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger, $eslifGrammar, $eslifGrammar2);
}

done_testing($number_of_tests);

package MyRecognizerInterface;
use strict;
use diagnostics;

sub new                    { my ($pkg, $string) = @_; bless { string => $string }, $pkg }
sub read                   { 1 }
sub isEof                  { 1 }
sub isCharacterStream      { 1 }
sub encoding               { }
sub data                   { $_[0]->{string} }
sub isWithDisableThreshold { 0 }
sub isWithExhaustion       { 0 }
sub isWithNewline          { 1 }
sub isWithTrack            { 1 }

package MyValueInterface;
use strict;
use diagnostics;

sub new                { my ($pkg) = @_; bless { result => undef }, $pkg }
sub isWithHighRankOnly { 1 }
sub isWithOrderByRank  { 1 }
sub isWithAmbiguous    { 0 }
sub isWithNull         { 0 }
sub maxParses          { 0 }
sub getResult          { $_[0]->{result} }
sub setResult          { $_[0]->{result} = $_[1] }

1;
