package MyRecognizer;
use strict;
use diagnostics;

sub new {
    my ($pkg, $string, $log) = @_;
    open my $fh, "<", \$string;
    return bless { line => undef, fh => $fh, log => $log }, $pkg;
}


sub read {
    my $self = shift;
    my $line = $self->{line} = readline($self->{fh});
    if (! defined($line)) {
      $self->{log}->errorf("read failure, %s", $!);
      return 0;
    } else {
      $self->{log}->tracef("read => %s", $line);
      return 1;
    }
}

sub isEof {
    my $self = shift;
    my $isEof = eof($self->{fh});
    $self->{log}->tracef("isEof => %d", $isEof);
    return $isEof;
}

sub isCharacterStream {
    my ($self) = @_;
    my $isCharacterStream = 1;
    $self->{log}->tracef("isCharacterStream => %d", $isCharacterStream);
    return $isCharacterStream;
}

sub encoding {
  my ($self) = @_;
  my $encoding = undef;
  $self->{log}->tracef("encoding => %s", $encoding);
  return $encoding;
}

sub data {
    my $self = shift;
    my $data = $self->{line};
    $self->{log}->tracef("data => %s", $data);
    return $data;
}

sub isWithDisableThreshold {
    my ($self) = @_;
    my $isWithDisableThreshold = 0;
    $self->{log}->tracef("isWithDisableThreshold => %d", $isWithDisableThreshold);
    return $isWithDisableThreshold;
}

sub isWithExhaustion {
    my ($self) = @_;
    my $isWithExhaustion = 0;
    $self->{log}->tracef("isWithExhaustion => %d", $isWithExhaustion);
    return $isWithExhaustion;
}

sub isWithNewline {
    my ($self) = @_;
    my $isWithNewline = 1;
    $self->{log}->tracef("isWithNewline = %d", $isWithNewline);
    return $isWithNewline;
}

sub isWithTrack {
    my ($self) = @_;
    my $isWithTrack = 1;
    $self->{log}->tracef("isWithTrack = %d", $isWithTrack);
    return $isWithTrack;
}

package MyValue;
use strict;
use diagnostics;
use Carp qw/croak/;
#
# In our example we have NOT specified a symbol action, therefore
# lexemes that come directly from the grammar are exactly what is in the input
#*/

sub new {
    my ($pkg, $log) = @_;

    return bless { result => undef, log => $log }, $pkg;
}

sub do_symbol {
    my ($self, $symbol) = @_;

    my $do_symbol = $symbol;
    $self->{log}->tracef("do_symbol(%s) => %s", $symbol, $do_symbol);
    return $do_symbol;
}

sub do_free {
    my ($self, $result) = @_;

    $self->{log}->fatalf("do_free(%s) called and this should never happen", $result);
    die "do_free() called and this should never happen";
    undef $result;
}

sub do_int {
    my ($self, $number) = @_;

    my $do_int = int($number);
    $self->{log}->tracef("do_int(%s) => %s", $number, $do_int);
    return $do_int;
}

sub do_op {
    my ($self, $left, $op, $right) = @_;

    my $result;
    if ($op eq '**') {
        $result = $left ** $right;
    }
    elsif ($op eq '*') {
        $result = $left * $right;
    }
    elsif ($op eq '/') {
        $result = $left / $right;
    }
    elsif ($op eq '+') {
        $result = $left + $right;
    }
    elsif ($op eq '-') {
        $result = $left - $right;
    }
    else {
        croak "Unsupported op $op";
    }

    $self->{log}->tracef("do_op(%s, %s, %s) => %s", $left, $op, $right, $result);
    return $result;
}

sub isWithHighRankOnly {
    my ($self) = @_;
    my $isWithHighRankOnly = 1;
    $self->{log}->tracef("isWithHighRankOnly => %s");
    return $isWithHighRankOnly;
}

sub isWithOrderByRank {
    my ($self) = @_;
    my $isWithOrderByRank = 1;
    $self->{log}->tracef("isWithOrderByRank => %s", $isWithOrderByRank);
    return $isWithOrderByRank;
}

sub isWithAmbiguous {
    my ($self) = @_;
    my $isWithAmbiguous = 0;
    $self->{log}->tracef("isWithAmbiguous => %s", $isWithAmbiguous);
    return $isWithAmbiguous;
}

sub isWithNull {
    my ($self) = @_;
    my $isWithNull = 0;
    $self->{log}->tracef("isWithNull => %s", $isWithNull);
    return $isWithNull;
}

sub maxParses {
    my ($self) = @_;
    my $maxParses = 0;
    $self->{log}->tracef("maxParses => %s", $maxParses);
    return $maxParses;
}

sub getResult {
    my ($self) = @_;
    my $getResult = $self->{result};
    $self->{log}->tracef("getResult => %s", $getResult);
    return $getResult;
}

sub setResult {
    my ($self, $result) = @_;
    $self->{log}->tracef("setResult(%s)", $result);
    $self->{result} = $result;
    return;
}

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use Try::Tiny;
use Encode qw/decode encode/;

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = TRACE, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

BEGIN { require_ok('MarpaX::ESLIF') };
BEGIN { require_ok('MarpaX::ESLIF::Event::Type') };
BEGIN { require_ok('MarpaX::ESLIF::Value::Type') };
BEGIN { require_ok('MarpaX::ESLIF::Logger::Level') };

#
# Test Event constants
#
foreach (qw/MARPAESLIF_EVENTTYPE_NONE MARPAESLIF_EVENTTYPE_COMPLETED MARPAESLIF_EVENTTYPE_NULLED MARPAESLIF_EVENTTYPE_PREDICTED MARPAESLIF_EVENTTYPE_BEFORE MARPAESLIF_EVENTTYPE_AFTER MARPAESLIF_EVENTTYPE_EXHAUSTED MARPAESLIF_EVENTTYPE_DISCARD/) {
  ok (defined(MarpaX::ESLIF::Event::Type->$_), "MarpaX::ESLIF::Event::Type->$_ is defined: " . MarpaX::ESLIF::Event::Type->$_);
}

#
# Test Value constants
#
foreach (qw/MARPAESLIF_VALUE_TYPE_UNDEF MARPAESLIF_VALUE_TYPE_CHAR MARPAESLIF_VALUE_TYPE_SHORT MARPAESLIF_VALUE_TYPE_INT MARPAESLIF_VALUE_TYPE_LONG MARPAESLIF_VALUE_TYPE_FLOAT MARPAESLIF_VALUE_TYPE_DOUBLE MARPAESLIF_VALUE_TYPE_PTR MARPAESLIF_VALUE_TYPE_ARRAY/) {
  ok (defined(MarpaX::ESLIF::Value::Type->$_), "MarpaX::ESLIF::Value::Type->$_ is defined: " . MarpaX::ESLIF::Value::Type->$_);
}

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');
my $version = $eslif->version;
ok (defined($version), "Library version is defined (currently: $version)");

my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> } );
isa_ok($eslifGrammar, 'MarpaX::ESLIF::Grammar');
my $ngrammar = $eslifGrammar->ngrammar;
ok($ngrammar > 0, "Number of grammars is > 0");
my $currentLevel = $eslifGrammar->currentLevel;
ok($currentLevel >= 0, "Current level is >= 0");

my $currentDescription = $eslifGrammar->currentDescription;
ok($currentDescription ne '', "Current description is not empty");
diag($currentDescription);
foreach my $level (0..$ngrammar-1) {
    my $descriptionByLevel = $eslifGrammar->descriptionByLevel($level);
    ok($descriptionByLevel ne '', "Description of level $level is not empty");
    diag($descriptionByLevel);
}

my $currentRuleIds = $eslifGrammar->currentRuleIds;
ok($#{$currentRuleIds} >= 0, "Number of current rules is > 0");
diag("@{$currentRuleIds}");
foreach my $ruleId (0..$#{$currentRuleIds}) {
    my $ruleDisplay = $eslifGrammar->ruleDisplay($currentRuleIds->[$ruleId]);
    ok($ruleDisplay ne '', "Display of rule No " . $currentRuleIds->[$ruleId]);
    diag($ruleDisplay);
    my $ruleShow = $eslifGrammar->ruleShow($currentRuleIds->[$ruleId]);
    ok($ruleShow ne '', "Show of rule No " . $currentRuleIds->[$ruleId]);
    diag($ruleShow);
}

foreach my $level (0..$ngrammar-1) {
    my $ruleIdsByLevel = $eslifGrammar->ruleIdsByLevel($level);
    ok($#{$ruleIdsByLevel} >= 0, "Number of rules at level $level is > 0");
    diag("@{$ruleIdsByLevel}");

    foreach my $ruleId (0..$#{$ruleIdsByLevel}) {
        my $ruleDisplayByLevel = $eslifGrammar->ruleDisplayByLevel($level, $ruleIdsByLevel->[$ruleId]);
        ok($ruleDisplayByLevel ne '', "Display of rule No " . $ruleIdsByLevel->[$ruleId] . " of level $level");
        diag($ruleDisplayByLevel);

        my $ruleShowByLevel = $eslifGrammar->ruleShowByLevel($level, $ruleIdsByLevel->[$ruleId]);
        ok($ruleShowByLevel ne '', "Show of rule No " . $ruleIdsByLevel->[$ruleId] . " of level $level");
        diag($ruleShowByLevel);
    }
}

my $show = $eslifGrammar->show;
ok($show ne '', "Show of current grammar");
diag($show);
foreach my $level (0..$ngrammar-1) {
    my $showByLevel = $eslifGrammar->showByLevel($level);
    ok($show ne '', "Show of grammar at level $level");
    diag($showByLevel);
}

my @strings = (
    "(((3 * 4) + 2 * 7) / 2 - 1)/* This is a\n comment \n */** 3",
    "5 / (2 * 3)",
    "5 / 2 * 3",
    "(5 ** 2) ** 3",
    "5 * (2 * 3)",
    "5 ** (2 ** 3)",
    "5 ** (2 / 3)",
    "1 + ( 2 + ( 3 + ( 4 + 5) )",
    "1 + ( 2 + ( 3 + ( 4 + 50) ) )   /* comment after */",
    " 100"
    );

#
# Test the parse() interface
#
for (my $i = 0; $i <= $#strings; $i++) {
  my $string = $strings[$i];

  $log->infof("Testing parse() on %s", $string);
  my $recognizerInterface = MyRecognizer->new($string, $log);
  my $valueInterface = MyValue->new($log);

  if ($eslifGrammar->parse($recognizerInterface, $valueInterface)) {
    my $result = $valueInterface->getResult;
    $log->infof("Result: %s", $result);
    if (defined($result)) {
      diag("$string => $result");
    } else {
      diag("$string => <undef>");
    }
  } else {
    diag("$string => ?");
  }
}

#
# Test the scan()/resume() interface
#
for (my $i = 0; $i <= $#strings; $i++) {
    my $string = $strings[$i];

    $log->infof("Testing scan()/resume() on %s", $string);
    my $recognizerInterface = MyRecognizer->new($string, $log);
    my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $recognizerInterface);
    isa_ok($eslifRecognizer, 'MarpaX::ESLIF::Recognizer');
    if (doScan($log, $eslifRecognizer, 1)) {
        showLocation("After doScan", $log, $eslifRecognizer);
        if (! $eslifRecognizer->isEof()) {
            if (! $eslifRecognizer->read()) {
                last;
            }
            showRecognizerInput("after read", $log, $eslifRecognizer);
        }
        if ($i == 0) {
            $eslifRecognizer->progressLog(-1, -1, MarpaX::ESLIF::Logger::Level->GENERICLOGGER_LOGLEVEL_NOTICE);
        }
        my $j = 0;
        while ($eslifRecognizer->isCanContinue()) {
            if (! doResume($log, $eslifRecognizer, 0)) {
                last;
            }
            showLocation("Loop No $j", $log, $eslifRecognizer);

            my $events = $eslifRecognizer->events();
            for (my $k = 0; $k < scalar(@{$events}); $k++) {
                my $event = $events->[$k];
                if ($event->{event} eq "^NUMBER") {
                    #
                    # Take opportunity of this event to test the hooks
                    #
                    $eslifRecognizer->hookDiscard(0);
                    $eslifRecognizer->hookDiscard(1);
                    #
                    # Recognizer will wait forever if we do not feed the number
                    #
                    my $pause = $eslifRecognizer->lexemeLastPause("NUMBER");
                    if (! defined($pause)) {
                        BAIL_OUT("Pause before on NUMBER but no pause information!");
                      }
                    if (! doLexemeRead($log, $eslifRecognizer, "NUMBER", $j, $pause)) {
                        BAIL_OUT("NUMBER expected but reading such lexeme fails!");
                    }
                    doDiscardTry($log, $eslifRecognizer);
                    doLexemeTry($log, $eslifRecognizer, "WHITESPACES");
                    doLexemeTry($log, $eslifRecognizer, "whitespaces");
                }
            }
            if ($j == 0) {
                changeEventState("Loop No $j", $log, $eslifRecognizer, "Expression", [ MarpaX::ESLIF::Event::Type->MARPAESLIF_EVENTTYPE_PREDICTED ], 0);
                changeEventState("Loop No $j", $log, $eslifRecognizer, "whitespaces", [ MarpaX::ESLIF::Event::Type->MARPAESLIF_EVENTTYPE_DISCARD ], 0);
                changeEventState("Loop No $j", $log, $eslifRecognizer, "NUMBER", [ MarpaX::ESLIF::Event::Type->MARPAESLIF_EVENTTYPE_AFTER ], 0);
            }
            showLastCompletion("Loop No $j", $log, $eslifRecognizer, "Expression", $string);
            showLastCompletion("Loop No $j", $log, $eslifRecognizer, "Number", $string);
            $j++;
        }
        try {
            my $eslifAppValue = MyValue->new($log);
            $log->infof("Testing value() on %s", $string);
            my $value = MarpaX::ESLIF::Value->new($eslifRecognizer, $eslifAppValue);
            while ($value->value()) {
                $log->infof("Result: %s", $eslifAppValue->getResult());
            }
        } catch {
            $log->errorf("Cannot value the input: %s", $_);
        }
    }
}

done_testing();

sub doScan {
    my ($log, $eslifRecognizer, $initialEvents) = @_;
		
    $log->debugf(" =============> scan(initialEvents=%s", $initialEvents);
    if (! $eslifRecognizer->scan($initialEvents)) {
        return 0;
    }
    my $context = "after scan";
    showRecognizerInput($context, $log, $eslifRecognizer);
    showEvents($context, $log, $eslifRecognizer);
    showLexemeExpected($context, $log, $eslifRecognizer);
		
    return 1;
}

sub showRecognizerInput {
    my ($context, $log, $eslifRecognizer) = @_;

    my $input = $eslifRecognizer->input();
    $log->debugf("[%s] Recognizer buffer:\n%s", $context, $input);
}

sub showEvents {
    my ($context, $log, $eslifRecognizer) = @_;

    $log->debugf("[%s] Events: %s", $context, $eslifRecognizer->events);
}

sub showLexemeExpected {
    my ($context, $log, $eslifRecognizer) = @_;

    $log->debugf("[%s] Expected lexemes: %s", $context, $eslifRecognizer->lexemeExpected);
}

sub doResume {
    my ($log, $eslifRecognizer, $deltaLength) = @_;
    my $context;
		
    $log->debugf(" =============> resume(deltaLength=%d)", $deltaLength);
    if (! $eslifRecognizer->resume($deltaLength)) {
        return 0;
    }

    $context = "after resume";
    showRecognizerInput($context, $log, $eslifRecognizer);
    showEvents($context, $log, $eslifRecognizer);
    showLexemeExpected($context, $log, $eslifRecognizer);
		
    return 1;
}

sub changeEventState {
    my ($context, $log, $eslifRecognizer, $symbol, $type, $state) = @_;
    $log->debugf("[%s] Changing event state %s of symbol %s to %s", $context, $type, $symbol, $state);
    $eslifRecognizer->eventOnOff($symbol, $type, $state);
}

sub showLastCompletion {
    my ($context, $log, $eslifRecognizer, $symbol, $origin)  = @_;

    try {
        my $lastExpressionOffset = $eslifRecognizer->lastCompletedOffset($symbol);
        my $lastExpressionLength = $eslifRecognizer->lastCompletedLength($symbol);
        my ($lastExpressionOffsetV2, $lastExpressionLengthV2) = $eslifRecognizer->lastCompletedLocation($symbol);
        if (($lastExpressionOffset != $lastExpressionOffsetV2) || ($lastExpressionLength != $lastExpressionLengthV2)) {
            BAIL_OUT("\$eslifRecognizer->lastCompletedLocation() is not equivalent to (\$eslifRecognizer->lastCompletedOffset, \$eslifRecognizer->lastCompletedLength)");
        }
        my $string2byte = encode('UTF-8', $origin, Encode::FB_CROAK);
        my $matchedbytes = substr($string2byte, $lastExpressionOffset, $lastExpressionLength);
        my $matchedString = decode('UTF-8', $matchedbytes, Encode::FB_CROAK);
        $log->debugf("[%s] Last %s completion is %s", $context, $symbol, $matchedString);
    } catch {
        $log->warnf("[%s] Last %s completion raised an exception, %s", $context, $symbol, $_);
    }
}

sub showLocation {
    my ($context, $log, $eslifRecognizer)  = @_;

    try {
        my $line = $eslifRecognizer->line();
        my $column = $eslifRecognizer->column();
        my ($lineV2, $columnV2) = $eslifRecognizer->location();
        if (($line != $lineV2) || ($column != $columnV2)) {
            BAIL_OUT("\$eslifRecognizer->location() is not equivalent to (\$eslifRecognizer->line, \$eslifRecognizer->column)");
        }
        $log->debugf("[%s] Location is %s", $context, [$line, $column]);
    } catch {
        $log->warnf("[%s] Location raised an exception, %s", $_);
    }
}

#
# We replace current NUMBER by the Integer object representing value
#
sub doLexemeRead {
    my ($log, $eslifRecognizer, $symbol, $value, $pause) = @_;
    my $length = length(encode('UTF-8', $pause));
    my $context;
    $log->debugf("... Forcing Integer object for \"%s\" spanned on %d bytes instead of \"%s\"", $value, $length, $pause);
    if (! $eslifRecognizer->lexemeRead($symbol, int($value), $length, 1)) {
        return 0;
    }

    $context = "after lexemeRead";
    showRecognizerInput($context, $log, $eslifRecognizer);
    showEvents($context, $log, $eslifRecognizer);
    showLexemeExpected($context, $log, $eslifRecognizer);
		
    return 1;
}

sub doDiscardTry {
    my ($log, $eslifRecognizer) = @_;

    my $test;
    try {
        $test = $eslifRecognizer->discardTry();
        $log->debugf("... Testing discard at current position returns %d", $test);
        if ($test) {
            my $discard = $eslifRecognizer->discardLastTry();
            $log->debugf("... Testing discard at current position gave \"%s\"", $discard);
        }
    } catch {
        # Because we test with a symbol that is not a lexeme, and that raises an exception
        $log->debugf($_);
    }
}

sub doLexemeTry {
    my ($log, $eslifRecognizer, $symbol) = @_;
    my $test;
    try {
        $test = $eslifRecognizer->lexemeTry($symbol);
        $log->debugf("... Testing %s lexeme at current position returns %d", $symbol, $test);
        if ($test) {
            my $try = $eslifRecognizer->lexemeLastTry($symbol);
            $log->debugf("... Testing symbol %s at current position gave \"%s\"", $symbol, $try);
        }
    } catch {
        # Because we test with a symbol that is not a lexeme, and that raises an exception
        $log->debugf($_);
    }
}

1;

__DATA__
:start   ::= Expression
:default ::=             action        => do_op
                         #symbol-action => do_symbol
                         free-action   => do_free
:discard ::= whitespaces event  => discard_whitespaces$
:discard ::= comment     event  => discard_comment$

event ^Number = predicted Number
event Number$ = completed Number
Number   ::= NUMBER   action => ::shift

event Expression$ = completed Expression
event ^Expression = predicted Expression
Expression ::=
    Number                                           action => do_int
    | '(' Expression ')'              assoc => group action => ::copy[1]
   ||     Expression '**' Expression  assoc => right
   ||     Expression  '*' Expression
    |     Expression  '/' Expression
   ||     Expression  '+' Expression
    |     Expression  '-' Expression

:lexeme ::= NUMBER pause => before event => ^NUMBER
:lexeme ::= NUMBER pause => after  event => NUMBER$
NUMBER     ~ /[\d]+/
whitespaces ::= WHITESPACES
WHITESPACES ~ [\s]+
comment ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/u

