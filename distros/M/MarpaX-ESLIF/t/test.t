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
    my ($pkg, $log, $grammar) = @_;

    my $self = bless { result => undef, log => $log, grammar => $grammar }, $pkg;
    $self->trace_local_variables('new');
    return $self;
}

sub DESTROY {
    my ($self) = @_;

    $self->trace_local_variables('DESTROY');
}

sub trace_local_variables {
    my ($self, $context) = @_;

    no warnings 'once';
    $self->{log}->tracef("... In %s::%s: \$MarpaX::ESLIF::Context::symbolName   is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::symbolName);
    $self->{log}->tracef("... In %s::%s: \$MarpaX::ESLIF::Context::symbolNumber is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::symbolNumber);
    $self->{log}->tracef("... In %s::%s: \$MarpaX::ESLIF::Context::ruleName     is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::ruleName);
    $self->{log}->tracef("... In %s::%s: \$MarpaX::ESLIF::Context::ruleNumber   is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::ruleNumber);
    $self->{log}->tracef("... In %s::%s: \$MarpaX::ESLIF::Context::grammar      is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::grammar);
}

sub trace_rule_property {
    my ($self, $context) = @_;

    if ($MarpaX::ESLIF::Context::ruleNumber && $MarpaX::ESLIF::Context::grammar && ref($MarpaX::ESLIF::Context::grammar)) {
        $self->{log}->tracef("... In %s::%s: rule %d property is: %s", __PACKAGE__, $context, $MarpaX::ESLIF::Context::ruleNumber, $MarpaX::ESLIF::Context::grammar->currentRuleProperties($MarpaX::ESLIF::Context::ruleNumber));
    }
}

sub do_symbol {
    my ($self, $symbol) = @_;

    my $do_symbol = $symbol;
    $self->{log}->tracef("do_symbol('%s') => %s", $symbol, $do_symbol);
    $self->trace_local_variables('do_symbol');
    return $do_symbol;
}

sub do_free {
    my ($self, $result) = @_;

    $self->{log}->fatalf("do_free(%s) called and this should never happen", $result);
    $self->trace_local_variables('do_free');
    die "do_free() called and this should never happen";
    undef $result;
}

sub do_int {
    my ($self, $number) = @_;

    my $do_int = int($number);
    $self->{log}->tracef("do_int(%s) => %s", $number, $do_int);
    $self->trace_local_variables('do_int');
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
    $self->trace_local_variables('do_op');
    $self->trace_rule_property('do_op');
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

sub setSymbolName {
    my ($self, $info) = @_;
    $self->{symbolName} = $info;
    $self->{log}->tracef("setSymbolName('%s')", $self->{symbolName});
    $self->trace_local_variables('setSymbolName');
    return;
}

sub setSymbolNumber {
    my ($self, $info) = @_;
    $self->{symbolNumber} = $info;
    $self->{log}->tracef("setSymbolNumber(%s)", $self->{symbolNumber});
    $self->trace_local_variables('setSymbolNumber');
    return;
}

sub setRuleName {
    my ($self, $info) = @_;
    $self->{ruleName} = $info;
    $self->{log}->tracef("setRuleName('%s')", $self->{ruleName});
    $self->trace_local_variables('setRuleName');
    return;
}

sub setRuleNumber {
    my ($self, $info) = @_;
    $self->{ruleNumber} = $info;
    $self->{log}->tracef("setRuleNumber(%s)", $self->{ruleNumber});
    $self->trace_local_variables('setRuleNumber');
    return;
}

sub setGrammar {
    my ($self, $info) = @_;
    $self->{grammar} = $info;
    $self->{log}->tracef("setGrammar(%s)", $self->{grammar});
    $self->trace_local_variables('setGrammar');
    return;
}

package main;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep::NoTest qw/cmp_details deep_diag/;
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

#
# Test Rule properties
#
foreach (qw/MARPAESLIF_RULE_IS_ACCESSIBLE MARPAESLIF_RULE_IS_NULLABLE MARPAESLIF_RULE_IS_NULLING MARPAESLIF_RULE_IS_LOOP MARPAESLIF_RULE_IS_PRODUCTIVE/) {
  ok (defined(MarpaX::ESLIF::Rule::PropertyBitSet->$_), "MarpaX::ESLIF::Rule::PropertyBitSet->$_ is defined: " . MarpaX::ESLIF::Rule::PropertyBitSet->$_);
}

#
# Test Symbol properties
#
foreach (qw/MARPAESLIF_SYMBOL_IS_ACCESSIBLE MARPAESLIF_SYMBOL_IS_NULLABLE MARPAESLIF_SYMBOL_IS_NULLING MARPAESLIF_SYMBOL_IS_PRODUCTIVE MARPAESLIF_SYMBOL_IS_START MARPAESLIF_SYMBOL_IS_TERMINAL/) {
  ok (defined(MarpaX::ESLIF::Symbol::PropertyBitSet->$_), "MarpaX::ESLIF::Symbol::PropertyBitSet->$_ is defined: " . MarpaX::ESLIF::Symbol::PropertyBitSet->$_);
}

#
# Test Symbol types
#
foreach (qw/MARPAESLIF_SYMBOLTYPE_TERMINAL MARPAESLIF_SYMBOLTYPE_META/) {
  ok (defined(MarpaX::ESLIF::Symbol::Type->$_), "MarpaX::ESLIF::Symbol::Type->$_ is defined: " . MarpaX::ESLIF::Symbol::Type->$_);
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
my %GRAMMAR_PROPERTIES_BY_LEVEL = (
    '0' => { defaultFreeAction   => ":defaultFreeActions",
             defaultRuleAction   => "do_op",
             defaultSymbolAction => "do_symbol",
             description         => "Grammar level 0",
             discardId           => 1,
             latm                => 1,
             level               => 0,
             maxLevel            => 1,
             ruleIds             => [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
             startId             => 0,
             symbolIds           => [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18] },
    '1' => { defaultFreeAction   => ":defaultFreeActions",
             defaultRuleAction   => "::concat",
             defaultSymbolAction => "::transfer",
             description         => "Grammar level 1",
             discardId           => -1,
             latm                => 1,
             level               => 1,
             maxLevel            => 1,
             ruleIds             => [0,1],
             startId             => 0,
             symbolIds           => [0,1,2,3] }
    );
my %RULE_PROPERTIES_BY_LEVEL = (
    '0' => {
        '0' => { action                   => undef,
                 description              => "Rule No 0",
                 discardEvent             => "discard_whitespaces\$",
                 discardEventInitialState => 1,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 0,
                 internal                 => 0,
                 lhsId                    => 1,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [2],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE,
                 show                     => ":discard ::= <whitespaces> event => discard_whitespaces\$=on" },
        '1' => { action                   => undef,
                 description              => "Rule No 1",
                 discardEvent             => "discard_comment\$",
                 discardEventInitialState => 1,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 1,
                 internal                 => 0,
                 lhsId                    => 1,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [3],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE,
                 show                     => ":discard ::= <comment> event => discard_comment\$=on" },
        '2' => { action                   => "::shift",
                 description              => "Rule No 2",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 2,
                 internal                 => 0,
                 lhsId                    => 4,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [5],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Number> ::= <NUMBER> action => ::shift" },
        '3' => { action                   => "::shift",
                 description              => "Rule No 3",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 3,
                 internal                 => 0,
                 lhsId                    => 0,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [6],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Expression> ::= <Expression[0]> action => ::shift" },
        '4' => { action                   => "::shift",
                 description              => "Rule No 4",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 4,
                 internal                 => 0,
                 lhsId                    => 6,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [7],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[0]> ::= <Expression[1]> action => ::shift" },
        '5' => { action                   => "::shift",
                 description              => "Rule No 5",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 5,
                 internal                 => 0,
                 lhsId                    => 7,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [8],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[1]> ::= <Expression[2]> action => ::shift" },
        '6' => { action                   => "::shift",
                 description              => "Rule No 6",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 6,
                 internal                 => 0,
                 lhsId                    => 8,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [9],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[2]> ::= <Expression[3]> action => ::shift" },
        '7' => { action                   => "do_int",
                 description              => "Expression is Number",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 7,
                 internal                 => 0,
                 lhsId                    => 9,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [4],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Expression[3]> ::= <Number> action => do_int name => 'Expression is Number'" },
        '8' => { action                   => "::copy[1]",
                 description              => "Expression is ()",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 8,
                 internal                 => 0,
                 lhsId                    => 9,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [10,6,11],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[3]> ::= '(' <Expression[0]> ')' action => ::copy[1] name => 'Expression is ()'" },
        '9' => { action                   => undef,
                 description              => "Expression is **",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 9,
                 internal                 => 0,
                 lhsId                    => 8,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [9,12,8],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Expression[2]> ::= <Expression[3]> '**' <Expression[2]> name => 'Expression is **'" },
        '10' => {action                   => undef,
                 description              => "Expression is *",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 10,
                 internal                 => 0,
                 lhsId                    => 7,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [7,13,8],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Expression[1]> ::= <Expression[1]> '*' <Expression[2]> name => 'Expression is *'" },
        '11' => {action                   => undef,
                 description              => "Expression is /",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 11,
                 internal                 => 0,
                 lhsId                    => 7,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [7,14,8],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[1]> ::= <Expression[1]> '/' <Expression[2]> name => 'Expression is /'" },
        '12' => {action                   => undef,
                 description              => "Expression is +",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 12,
                 internal                 => 0,
                 lhsId                    => 6,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [6,15,7],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<Expression[0]> ::= <Expression[0]> '+' <Expression[1]> name => 'Expression is +'" },
        '13' => {action                   => undef,
                 description              => "Expression is -",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 13,
                 internal                 => 0,
                 lhsId                    => 6,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [6,16,7],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show => "<Expression[0]> ::= <Expression[0]> '-' <Expression[1]> name => 'Expression is -'" },
        '14' => {action                   => undef,
                 description              => "Rule No 14",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 14,
                 internal                 => 0,
                 lhsId                    => 2,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [17],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE,
                 show                     => "<whitespaces> ::= <WHITESPACES>"},
        '15' => {action                   => undef,
                 description              => "Rule No 15",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 15,
                 internal                 => 0,
                 lhsId                    => 3,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [18],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE,
                 show                     => "<comment> ::= /(?:(?:(?:\\/\\/)(?:[^\\n]*)(?:\\n|\\z))|(?:(?:\\/\\*)(?:(?:[^\\*]+|\\*(?!\\/))*)(?:\\*\\/)))/u"}
    },
    '1' => {
        '0' => { action                   => undef,
                 description              => "Rule No 0",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 0,
                 internal                 => 0,
                 lhsId                    => 0,
                 minimum                  => -1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [1],
                 separatorId              => -1,
                 sequence                 => 0,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE|
                                             MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE,
                 show                     => "<NUMBER> ~ /[\\d]+/" },
        '1' => { action                   => undef,
                 description              => "Rule No 1",
                 discardEvent             => undef,
                 discardEventInitialState => 0,
                 exceptionId              => -1,
                 hideseparator            => 0,
                 id                       => 1,
                 internal                 => 0,
                 lhsId                    => 2,
                 minimum                  => 1,
                 nullRanksHigh            => 0,
                 proper                   => 0,
                 rank                     => 0,
                 rhsIds                   => [3],
                 separatorId              => -1,
                 sequence                 => 1,
                 propertyBitSet           => MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE,
                 show                     => "<WHITESPACES> ~ /[\\s]/+" }
    }
    );

my %SYMBOL_PROPERTIES_BY_LEVEL = (
    '0' => {
        '0' => { description => "Expression",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => "Expression\$",
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => "^Expression",
                 eventPredictedInitialState => 1,
                 id => 0,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_START,
                 start => 1,
                 top => 1,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '1' => { description => ":discard",
                 discard => 1,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 1,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 1,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '2' => { description => "whitespaces",
                 discard => 0,
                 discardEvent => "discard_whitespaces\$",
                 discardEventInitialState => 1,
                 discardRhs => 1,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 2,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '3' => { description => "comment",
                 discard => 0,
                 discardEvent => "discard_comment\$",
                 discardEventInitialState => 1,
                 discardRhs => 1,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 3,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '4' => { description => "Number",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => "Number\$",
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => "^Number",
                 eventPredictedInitialState => 1,
                 id => 4,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '5' => { description => "NUMBER",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => "NUMBER\$",
                 eventAfterInitialState => 1,
                 eventBefore => "^NUMBER",
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 5,
                 lhs => 0,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '6' => { description => "Expression[0]",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 6,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '7' => { description => "Expression[1]",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 7,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '8' => { description => "Expression[2]",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 8,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '9' => { description => "Expression[3]",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 9,
                 lhs => 1,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '10' => {description => "'('",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 10,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '11' => {description => "')'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 11,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '12' => {description => "'**'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 12,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '13' => {description => "'*'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 13,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '14' => {description => "'/'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 14,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '15' => {description => "'+'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 15,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '16' => {description => "'-'",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 16,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '17' => {description => "WHITESPACES",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 17,
                 lhs => 0,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '18' => {description => "/(?:(?:(?:\\/\\/)(?:[^\\n]*)(?:\\n|\\z))|(?:(?:\\/\\*)(?:(?:[^\\*]+|\\*(?!\\/))*)(?:\\*\\/)))/u",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 18,
                 lhs => 0,
                 lookupResolvedLeveli => 0,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL}
    },
    '1' => {
        '0' => { description => "NUMBER",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 0,
                 lhs => 1,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_START,
                 start => 0,
                 top => 1,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '1' => { description => "/[\\d]+/",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 1,
                 lhs => 0,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_ACCESSIBLE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL},
        '2' => { description => "WHITESPACES",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 2,
                 lhs => 1,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE,
                 start => 0,
                 top => 1,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META},
        '3' => { description => "/[\\s]/",
                 discard => 0,
                 discardEvent => undef,
                 discardEventInitialState => 1,
                 discardRhs => 0,
                 eventAfter => undef,
                 eventAfterInitialState => 1,
                 eventBefore => undef,
                 eventBeforeInitialState => 1,
                 eventCompleted => undef,
                 eventCompletedInitialState => 1,
                 eventNulled => undef,
                 eventNulledInitialState => 1,
                 eventPredicted => undef,
                 eventPredictedInitialState => 1,
                 id => 3,
                 lhs => 0,
                 lookupResolvedLeveli => 1,
                 nullableAction => undef,
                 priority => 0,
                 propertyBitSet => MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_PRODUCTIVE|
                                   MarpaX::ESLIF::Symbol::PropertyBitSet->MARPAESLIF_SYMBOL_IS_TERMINAL,
                 start => 0,
                 top => 0,
                 type => MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL}
    }
    );

my $grammarCurrentProperties = $eslifGrammar->currentProperties;
isa_ok($grammarCurrentProperties, 'MarpaX::ESLIF::Grammar::Properties');
doCmpProperties($grammarCurrentProperties, bless($GRAMMAR_PROPERTIES_BY_LEVEL{'0'}, 'MarpaX::ESLIF::Grammar::Properties'), "Grammar current properties");

my $currentDescription = $eslifGrammar->currentDescription;
ok($currentDescription ne '', "Current description is not empty");
diag($currentDescription);
foreach my $level (0..$ngrammar-1) {
    my $descriptionByLevel = $eslifGrammar->descriptionByLevel($level);
    ok($descriptionByLevel ne '', "Description of level $level is not empty");
    diag($descriptionByLevel);
    my $got = $eslifGrammar->propertiesByLevel($level);
    my $expected = bless($GRAMMAR_PROPERTIES_BY_LEVEL{$level}, 'MarpaX::ESLIF::Grammar::Properties');
    doCmpProperties($got, $expected, "Grammar properties at level $level");
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
    my $got = $eslifGrammar->currentRuleProperties($ruleId);
    my $expected = $RULE_PROPERTIES_BY_LEVEL{'0'}{$ruleId};
    doCmpProperties($got, bless($expected, 'MarpaX::ESLIF::Grammar::Rule::Properties'), "Rule No $ruleId current properties");
}

my $currentSymbolIds = $eslifGrammar->currentSymbolIds;
ok($#{$currentSymbolIds} >= 0, "Number of current symbols is > 0");
diag("@{$currentSymbolIds}");
foreach my $symbolId (0..$#{$currentSymbolIds}) {
    my $symbolDisplay = $eslifGrammar->symbolDisplay($currentSymbolIds->[$symbolId]);
    ok($symbolDisplay ne '', "Display of symbol No " . $currentSymbolIds->[$symbolId]);
    diag($symbolDisplay);
    my $got = $eslifGrammar->currentSymbolProperties($symbolId);
    my $expected = $SYMBOL_PROPERTIES_BY_LEVEL{'0'}{$symbolId};
    doCmpProperties($got, bless($expected, 'MarpaX::ESLIF::Grammar::Symbol::Properties'), "Symbol No $symbolId current properties");
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

        my $got = $eslifGrammar->rulePropertiesByLevel($level, $ruleId);
        my $expected = $RULE_PROPERTIES_BY_LEVEL{$level}{$ruleId};
        doCmpProperties($got, bless($expected, 'MarpaX::ESLIF::Grammar::Rule::Properties'), "Rule No $ruleId of level $level properties");
    }

    my $symbolIdsByLevel = $eslifGrammar->symbolIdsByLevel($level);
    ok($#{$symbolIdsByLevel} >= 0, "Number of symbols at level $level is > 0");
    diag("@{$symbolIdsByLevel}");

    foreach my $symbolId (0..$#{$symbolIdsByLevel}) {
        my $symbolDisplayByLevel = $eslifGrammar->symbolDisplayByLevel($level, $symbolIdsByLevel->[$symbolId]);
        ok($symbolDisplayByLevel ne '', "Display of symbol No " . $symbolIdsByLevel->[$symbolId] . " of level $level");
        diag($symbolDisplayByLevel);

        my $got = $eslifGrammar->symbolPropertiesByLevel($level, $symbolId);
        # $log->tracef("\$SYMBOL_PROPERTIES_BY_LEVEL{%d}{%d} = %s", $level, $symbolId, $got);
        my $expected = $SYMBOL_PROPERTIES_BY_LEVEL{$level}{$symbolId};
        doCmpProperties($got, bless($expected, 'MarpaX::ESLIF::Grammar::Symbol::Properties'), "Symbol No $symbolId of level $level properties");
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
  $MarpaX::ESLIF::Context::symbolName = 'none (original value)';
  $MarpaX::ESLIF::Context::symbolNumber = 'none (original value)';
  $MarpaX::ESLIF::Context::ruleName = 'none (original value)';
  $MarpaX::ESLIF::Context::ruleNumber = 'none (original value)';
  $MarpaX::ESLIF::Context::grammar = 'none (original value)';
  my $valueInterface = MyValue->new($log, $eslifGrammar);

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

  $log->tracef("... In %s: \$MarpaX::ESLIF::Context::symbolName   is: %s", __PACKAGE__, $MarpaX::ESLIF::Context::symbolName);
  $log->tracef("... In %s: \$MarpaX::ESLIF::Context::symbolNumber is: %s", __PACKAGE__, $MarpaX::ESLIF::Context::symbolNumber);
  $log->tracef("... In %s: \$MarpaX::ESLIF::Context::ruleName     is: %s", __PACKAGE__, $MarpaX::ESLIF::Context::ruleName);
  $log->tracef("... In %s: \$MarpaX::ESLIF::Context::ruleNumber   is: %s", __PACKAGE__, $MarpaX::ESLIF::Context::ruleNumber);
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
            my $eslifAppValue = MyValue->new($log, $eslifGrammar);
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

sub doCmpProperties {
  my ($got, $expected, $what) = @_;

  my ($ok, $stack) = cmp_details($got, $expected);
  diag(deep_diag($stack)) unless (ok($ok, $what));
  #
  # Properties are blessed objects, and we expect to getXxx() members
  # for every expected hash value. cmp_details() made sure this is a
  # blessed hash ref.
  #
  if ($ok) {
      foreach (keys %{$expected}) {
          my $getter = 'get' . ucfirst($_);
          #
          # We know in advance that properties content are either scalars, either array references
          #
          my $ref = ref($got);
          if (ok($ref->can($getter), "$ref can $getter")) {
              my $got2 = $got->$getter;
              my $expected2 = $expected->{$_};
              my $what2 = $ref . "'s $getter method";
              my ($ok2, $stack2) = cmp_details($got2, $expected2);
              diag(deep_diag($stack2)) unless (ok($ok2, $what2));
          }
      }
  }
}


1;

__DATA__
:start   ::= Expression
:default ::=             action        => do_op
                         symbol-action => do_symbol
                         free-action   => do_free
:discard ::= whitespaces event  => discard_whitespaces$
:discard ::= comment     event  => discard_comment$

event ^Number = predicted Number
event Number$ = completed Number
Number   ::= NUMBER   action => ::shift

event Expression$ = completed Expression
event ^Expression = predicted Expression
Expression ::=
    Number                                           action => do_int            name => 'Expression is Number'
    | '(' Expression ')'              assoc => group action => ::copy[1]         name => 'Expression is ()'
   ||     Expression '**' Expression  assoc => right                             name => 'Expression is **'
   ||     Expression  '*' Expression                                             name => 'Expression is *'
    |     Expression  '/' Expression                                             name => 'Expression is /'
   ||     Expression  '+' Expression                                             name => 'Expression is +'
    |     Expression  '-' Expression                                             name => 'Expression is -'

:lexeme ::= NUMBER pause => before event => ^NUMBER
:lexeme ::= NUMBER pause => after  event => NUMBER$
NUMBER     ~ /[\d]+/
whitespaces ::= WHITESPACES
WHITESPACES ~ [\s]+
comment ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/u

