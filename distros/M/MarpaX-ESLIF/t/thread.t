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

package main;
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Config;
    if (! $Config{usethreads}) {
        print("1..0 # Skip: No threads\n");
        exit(0);
    }
}

use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use threads;
my $NTHREAD;
BEGIN {
    $NTHREAD = 5;
}
use Test::More tests => 3 + $NTHREAD * 5;
BEGIN { require_ok('MarpaX::ESLIF') }

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = TRACE, Screen
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

my $eslif_in_main = MarpaX::ESLIF->new($log);
my $eslif2_in_main = MarpaX::ESLIF->new($log);
ok($eslif_in_main == $eslif2_in_main, "Thread 0 - new with logger $eslif_in_main == $eslif2_in_main");

my $eslif_in_main_without_logger = MarpaX::ESLIF->new();
my $eslif2_in_main_without_logger = MarpaX::ESLIF->new();
ok($eslif_in_main_without_logger == $eslif2_in_main_without_logger, "Thread 0 - new without logger $eslif_in_main_without_logger == $eslif2_in_main_without_logger");

#
# We introduce tiny sleeps to make sure threads overlaps
#
sub _sleep {
    my $sleep = 1 + int(rand(2));
    sleep($sleep);
}

sub thr_sub {
  my ($input, $expected) = @_;

  my $tid = threads->tid();
  Log::Log4perl::MDC->put("tid", $tid);

  $log->trace("Starting");

  _sleep;

  $log->tracef("Testing ESLIF creation with logger=%s", "$log");

  my $eslif = MarpaX::ESLIF->new($log);
  my $eslif2 = MarpaX::ESLIF->new($log);
  ok($eslif == $eslif2, "Thread $tid - new with logger $eslif == new $eslif2");
  ok($eslif == $eslif_in_main, "Thread $tid - new with logger $eslif == main $eslif_in_main");

  _sleep;

  $log->trace('Testing ESLIF creation without logger');

  my $eslif_without_logger = MarpaX::ESLIF->new();
  my $eslif2_without_logger = MarpaX::ESLIF->new();
  ok($eslif_without_logger == $eslif2_without_logger, "Thread $tid - new without logger $eslif_without_logger == new $eslif2_without_logger");
  ok($eslif_without_logger == $eslif_in_main_without_logger, "Thread $tid - new without logger $eslif_without_logger == main $eslif_in_main_without_logger");

  _sleep;

  $log->trace('Testing valuation');

  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar);
  my $eslifRecognizerInterface = MyRecognizerInterface->new($input);
  my $eslifValueInterface = MyValueInterface->new();

  $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface);
  my $value = $eslifValueInterface->getResult;
  is($value, $expected, "Thread $tid - value $value == expected $expected");

  _sleep;
  $log->trace('Ending');
}

my $input = '(1+2)*3';
my $expected = '(1+2)*3';
my @t = grep { defined } map {
  threads->create(\&thr_sub, $input, $expected)
} (1..$NTHREAD);

my $remains = scalar(@t);
while ($remains) {
    foreach (@t) {
        next unless $_->is_joinable;
        $_->join;
        --$remains
    }
}

done_testing();

1;
