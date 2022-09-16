use strict;
use warnings FATAL => 'all';

BEGIN {
    use Config;
    if (! $Config{usethreads}) {
        print("1..0 # Skip: No threads\n");
        exit(0);
    }
}

use threads;
use threads::shared;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
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

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d [Thread %X{tid}] %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');
Log::Log4perl::MDC->put("tid", threads->tid());

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

my ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger, $eslifGrammar, $eslifGrammar2) = unit_test();

sub thr_sub {
  my $tid = threads->tid();
  Log::Log4perl::MDC->put("tid", $tid);

  {
      lock($go);
      $log->trace("Waiting for go signal");
      {
          lock($nwaitingGoSignal);
          $nwaitingGoSignal++;
      }
      cond_wait($go) until $go;
  }

  unit_test();

  $log->trace('Ending');
}

my @t = grep { defined } map {
    my $thr = threads->create(\&thr_sub, $input, $expected);
    $log->warn("threads->create failure, $!") if ! defined($thr);
    $thr;
} (1..NTHREAD);
$log->trace('Number of threads created: ' . scalar(@t));

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
    $log->trace('Broadcasting go signal');
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
    $log->tracef("Thread $tid - Testing ESLIF multiton creation with logger=%s", "$log");
    my $eslif_with_logger = MarpaX::ESLIF->new($log);
    ok(defined($eslif_with_logger), "Thread $tid - \$eslif_with_logger is defined");
    my $eslif2_with_logger = MarpaX::ESLIF->new($log);
    ok(defined($eslif2_with_logger), "Thread $tid - \$eslif2_with_logger is defined");

    ok($eslif_with_logger == $eslif2_with_logger, "Thread $tid - ESLIF multiton with logger $eslif_with_logger == $eslif2_with_logger");

    $log->trace("Thread $tid - Testing ESLIF multiton creation without logger");
    my $eslif_without_logger = MarpaX::ESLIF->new();
    ok(defined($eslif_without_logger), "Thread $tid - \$eslif_without_logger is defined");
    my $eslif2_without_logger = MarpaX::ESLIF->new();
    ok(defined($eslif2_without_logger), "Thread $tid - \$eslif2_without_logger is defined");

    ok($eslif_without_logger == $eslif2_without_logger, "Thread $tid - ESLIF multiton without logger $eslif_without_logger == $eslif2_without_logger");

    return ($eslif_with_logger, $eslif2_with_logger, $eslif_without_logger, $eslif2_without_logger);
}

sub test_eslifGrammar_multiton {
    my ($eslif) = @_;

    #
    # 3 tests
    #
    my $tid = threads->tid();

    $log->trace("Thread $tid - Testing ESLIFGrammar multiton using $eslif");
    my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar);
    ok(defined($eslifGrammar), "Thread $tid - \$eslifGrammar is defined");
    my $eslifGrammar2 = MarpaX::ESLIF::Grammar->new($eslif, $grammar);
    ok(defined($eslifGrammar2), "Thread $tid - \$eslifGrammar2 is defined");

    ok($eslifGrammar == $eslifGrammar2, "Thread $tid - ESLIFGrammar multiton $eslifGrammar == $eslifGrammar2");

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

    $log->tracef("Thread $tid - Testing parse()");
    $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface);
    my $value = $eslifValueInterface->getResult;
    is($value, $expected, "Thread $tid - value $value == expected $expected");
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
