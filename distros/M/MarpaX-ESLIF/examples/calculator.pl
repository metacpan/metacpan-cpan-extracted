#!env perl

package main;
use strict;
use diagnostics;
use Log::Any qw/$log/;
use Log::Any::Adapter qw/Stderr/;
use MarpaX::ESLIF;

my $eslif = MarpaX::ESLIF->new($log);
print  "************************************************************\n";
my $grammar_v1 = q{
      Expression ::=
          /[\d]+/
          | '(' Expression ')'              assoc => group
         ||     Expression '**' Expression  assoc => right
         ||     Expression  '*' Expression
          |     Expression  '/' Expression
         ||     Expression  '+' Expression
          |     Expression  '-' Expression
      };
printf "Grammar:%s\n", $grammar_v1;
my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v1);

package MyRecognizer;
use strict;
use diagnostics;
#
# Constructor
#
sub new {
  my ($pkg, $string) = @_;
  open my $fh, "<", \$string;
  bless { data => undef, fh => $fh }, $pkg
}

#
# Required methods
#
sub read                   {
  my ($self) = @_;   # read data
  defined($self->{data} = readline($self->{fh}))
}
sub isEof                  {  eof $_[0]->{fh} } # End of data ?
sub isCharacterStream      {                1 } # Character stream ?
sub encoding               {                  } # Encoding ?
sub data                   {    shift->{data} } # data
sub isWithDisableThreshold {                0 } # Disable threshold warning ?
sub isWithExhaustion       {                0 } # Exhaustion event ?
sub isWithNewline          {                1 } # Newline count ?
sub isWithTrack            {                0 } # Absolute position tracking ?

package MyValue;
use strict;
use diagnostics;
#
# Constructor
#
sub new { bless { result => undef}, shift }

#
# Required methods
#
sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
sub isWithNull         { 0 }  # Allow null parse ?
sub maxParses          { 0 }  # Maximum number of parse tree values
#
# ... result getter and setter
#
sub getResult          { my ($self) = @_; $self->{result} }
sub setResult          { my ($self, $result) = @_; $self->{result} = $result }

package main;

my $input = '(1+2)*3';
my $eslifRecognizerInterface = MyRecognizer->new($input);
my $eslifValueInterface = MyValue->new();

my $result = $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface) ? $eslifValueInterface->getResult : '??';
printf "Default parse tree value of $input: %s\n", $result;

print  "************************************************************\n";
my $grammar_v2 = $grammar_v1 . q{
      :discard ::= /[\s]+/
      :discard ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/
      :discard ::= /#[^\n]*(?:\n|\z)/
      };
printf "Grammar:%s\n", $grammar_v2;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v2);
$input = q{( /* C comment */1+2)
# perl comment
*3};
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifValueInterface = MyValue->new();
$result = $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface) ? $eslifValueInterface->getResult : '??';
printf "Default parse tree value of $input: %s\n", $result;

package MyRecognizer;
no warnings 'redefine';
sub read {
  my ($self) = @_;   # read data
  CORE::read($self->{fh}, $self->{data}, 1) ? 1 : 0x
}

#package MyRecognizer;
#no warnings 'redefine';
#sub encoding               { 'ASCII' } # Encoding ?

package MyValue;
sub do_pow   { my ($self, $left, $op, $right) = @_; $left**$right }
sub do_mul   { my ($self, $left, $op, $right) = @_; $left*$right }
sub do_div   { my ($self, $left, $op, $right) = @_; $left/$right }
sub do_plus  { my ($self, $left, $op, $right) = @_; $left+$right }
sub do_minus { my ($self, $left, $op, $right) = @_; $left-$right }

package main;
print  "************************************************************\n";
my $grammar_v3 = q{
  Expression ::=
      /[\d]+/
      | '(' Expression ')'              assoc => group action => ::copy[1]
     ||     Expression '**' Expression  assoc => right action => do_pow
     ||     Expression  '*' Expression                 action => do_mul
      |     Expression  '/' Expression                 action => do_div
     ||     Expression  '+' Expression                 action => do_plus
      |     Expression  '-' Expression                 action => do_minus
  :discard ::= /[\s]+/
  };
printf "Grammar:%s\n", $grammar_v3;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v3);
$input = q{(1 + 2) * 3};
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifValueInterface = MyValue->new();
$result = $eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface) ? $eslifValueInterface->getResult : '??';
printf "Default parse tree value of $input: %s\n", $result;

$input = q{(1 + 2) * 3 + ( abcdef};
# Remember that we are using the 'read-one-character-per-character' implementation
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifValueInterface = MyValue->new();
$eslifGrammar->parse($eslifRecognizerInterface, $eslifValueInterface);

$input = q{(1 + 2) * 3};
# Our usual ESLIF Recognizer interface
$eslifRecognizerInterface = MyRecognizer->new($input);
# ESLIF Recognizer engine
my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
#
# Start scanning the input, we want initial events here
#
$eslifRecognizer->scan(1);
my $eventsRef = $eslifRecognizer->events();
use Data::Dumper;
print "Events after scan():\n" . Dumper($eventsRef);

print  "************************************************************\n";
my $grammar_v4 = $grammar_v3 . q{
  event ^Expression = predicted Expression
  };
printf "Grammar:%s\n", $grammar_v4;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v4);
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
$eslifRecognizer->scan(1);
$eventsRef = $eslifRecognizer->events();
print "Events after scan():\n" . Dumper($eventsRef);
use MarpaX::ESLIF::Event::Type;
printf "MARPAESLIF_EVENTTYPE_PREDICTED is: %d\n", MarpaX::ESLIF::Event::Type->MARPAESLIF_EVENTTYPE_PREDICTED; # 4

print  "************************************************************\n";
my $grammar_v5 = $grammar_v4 . q{
    event Expression$ = completed Expression
    };
printf "Grammar:%s\n", $grammar_v5;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v5);
$eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
#
# Always start with scan()
# ------------------------
$eslifRecognizer->scan(1);
print "Events after scan():\n" . Dumper($eslifRecognizer->events());
$eslifRecognizer->eventOnOff('Expression', [ MarpaX::ESLIF::Event::Type->MARPAESLIF_EVENTTYPE_PREDICTED ], 0);
#
# -------------------------------
# Always check if we can continue
# -------------------------------
if ($eslifRecognizer->isCanContinue) {
  do {
    #
    # resume() optional parameter is a number of BYTES.
    # Because we stopped with initial event ^Expression, it is okay in this specific case
    # and this specific grammar to resume() without changing the position, since we switched off
    # the only possible initial event ^Expression
    #
    $eslifRecognizer->resume();
    print "Events after resume():\n" . Dumper($eslifRecognizer->events());
  } while ($eslifRecognizer->isCanContinue)
};

print  "************************************************************\n";
my $grammar_v6 = q{
Expression ::=
               /[\d]+/
             | '(' NulledSymbol Expression ')' assoc => group action => ::copy[1]
            ||     Expression '**' Expression  assoc => right action => do_pow
            ||     Expression  '*' Expression                 action => do_mul
             |     Expression  '/' Expression                 action => do_div
            ||     Expression  '+' Expression                 action => do_plus
             |     Expression  '-' Expression                 action => do_minus
NulledSymbol ::=
:discard ::= /[\s]+/
event Expression$ = completed Expression
event NulledSymbol[] = nulled NulledSymbol
};
printf "Grammar:%s\n", $grammar_v6;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v6);

print  "************************************************************\n";
my $grammar_v7 = q{
Expression ::=
               /[\d]+/
             | LPAREN Expression RPAREN           assoc => group action => ::copy[1]
            ||        Expression '**' Expression  assoc => right action => do_pow
            ||        Expression  '*' Expression                 action => do_mul
             |        Expression  '/' Expression                 action => do_div
            ||        Expression  '+' Expression                 action => do_plus
             |        Expression  '-' Expression                 action => do_minus
:discard ::= /[\s]+/
event Expression$ = completed Expression
LPAREN ~ '('
RPAREN ~ ')'
:lexeme ::= LPAREN pause => after event => LPAREN$
:lexeme ::= RPAREN pause => after event => RPAREN$
};
printf "Grammar:%s\n", $grammar_v7;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v7);

print  "************************************************************\n";
my $grammar_v8 = q{
Expression ::=
               NUMBER
             | '(' Expression ')'              assoc => group action => ::copy[1]
            ||     Expression  POW Expression  assoc => right action => do_pow
            ||     Expression  '*' Expression                 action => do_mul
             |     Expression  '/' Expression                 action => do_div
            ||     Expression  '+' Expression                 action => do_plus
             |     Expression  '-' Expression                 action => do_minus
:discard ::= /[\s]+/
:lexeme ::= NUMBER pause => before event => ^NUMBER
NUMBER     ~ /[\d]+/
POW        ~ '**'
};
printf "Grammar:%s\n", $grammar_v8;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v8);
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
$eslifRecognizer->scan();
if ($eslifRecognizer->isCanContinue) {
  do {
    my $alreadyResumed = 0;
    foreach (@{$eslifRecognizer->events()}) {
      if ($_->{event}) {   # Can be undef for exhaustion
        if ($_->{event} eq '^NUMBER') {
          my $lastPause = $eslifRecognizer->lexemeLastPause($_->{symbol});
          printf "Pause before event %s for symbol %s: \"%s\"\n", $_->{event}, $_->{symbol}, $lastPause;
          printf "  Replacing number by number**2 !\n";
          # ------------------------------
          # We replace NUMBER by NUMBER**2
          # ------------------------------
          $eslifRecognizer->lexemeRead('NUMBER', $lastPause, 0);
          $eslifRecognizer->lexemeRead('POW', '**', 0);
          $eslifRecognizer->lexemeRead('NUMBER', '2', 0);
          # -------------------------------------------
          # We say to resume exactly where NUMBER ended
          # -------------------------------------------
          $eslifRecognizer->resume(bytes::length($lastPause));
          $alreadyResumed = 1;
          last
        }
      }
    }
    $eslifRecognizer->resume() unless $alreadyResumed
  } while ($eslifRecognizer->isCanContinue)
}
$eslifValueInterface = MyValue->new();
my $eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $eslifValueInterface);
while ($eslifValue->value()) {
  #
  # (1**2 + 2**2) * 3**2 = 45
  #
  printf "======> %s\n", $eslifValueInterface->getResult;
}

print  "************************************************************\n";
my $grammar_v9 = q{
Expression ::=
               NUMBER
             | '(' Expression ')'              assoc => group
            ||     Expression  POW Expression  assoc => right
            ||     Expression  '*' Expression
             |     Expression  '/' Expression
            ||     Expression  '+' Expression
             |     Expression  '-' Expression
:discard ::= /[\s]+/
:lexeme ::= NUMBER pause => before event => ^NUMBER
NUMBER     ~ /[\d]+/
POW        ~ '**'
};
printf "Grammar:%s\n", $grammar_v9;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v9);
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
$eslifRecognizer->scan();
if ($eslifRecognizer->isCanContinue) {
  do {
    my $alreadyResumed = 0;
    foreach (@{$eslifRecognizer->events()}) {
      if ($_->{event}) {   # Can be undef for exhaustion
        if ($_->{event} eq '^NUMBER') {
          my $lastPause = $eslifRecognizer->lexemeLastPause($_->{symbol});
          printf "Pause before event %s for symbol %s: \"%s\"\n", $_->{event}, $_->{symbol}, $lastPause;
          printf "  Replacing $lastPause by $lastPause**2 !\n";
          # ------------------------------
          # We replace NUMBER by NUMBER**2
          # ------------------------------
          $eslifRecognizer->lexemeRead('NUMBER', $lastPause, 0);
          $eslifRecognizer->lexemeRead('POW', '**', 0);
          $eslifRecognizer->lexemeRead('NUMBER', '2', 0);
          # -------------------------------------------
          # We say to resume exactly where NUMBER ended
          # -------------------------------------------
          $eslifRecognizer->resume(bytes::length($lastPause));
          $alreadyResumed = 1;
          last
        }
      }
    }
    $eslifRecognizer->resume() unless $alreadyResumed
  } while ($eslifRecognizer->isCanContinue)
}
$eslifValueInterface = MyValue->new();
$eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $eslifValueInterface);
while ($eslifValue->value()) {
  #
  # (1**2 + 2**2) * 3**2 = (1**2+2**2)*3**2
  #
  printf "======> %s\n", $eslifValueInterface->getResult;
}

print  "************************************************************\n";
my $grammar_v10 = q{
Expression ::=
               NUMBER
             | '(' Expression ')'              assoc => group
            ||     Expression  POW Expression  assoc => right
            ||     Expression  '*' Expression
             |     Expression  '/' Expression
            ||     Expression  '+' Expression
             |     Expression  '-' Expression
:discard ::= /[\s]+/
:lexeme ::= NUMBER pause => before event => ^NUMBER
NUMBER     ~ /[\d]+/
POW        ~ '**'
};
printf "Grammar:%s\n", $grammar_v10;
$eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar_v10);
$eslifRecognizerInterface = MyRecognizer->new($input);
$eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
$eslifRecognizer->scan();
if ($eslifRecognizer->isCanContinue) {
  do {
    my $alreadyResumed = 0;
    foreach (@{$eslifRecognizer->events()}) {
      if ($_->{event}) {   # Can be undef for exhaustion
        if ($_->{event} eq '^NUMBER') {
          my $lastPause = $eslifRecognizer->lexemeLastPause($_->{symbol});
          printf "Pause before event %s for symbol %s: \"%s\"\n", $_->{event}, $_->{symbol}, $lastPause;
          printf "  Replacing $lastPause by $lastPause*ANYTHING*2 saying that *ANYTHING* is the representation of POW token!\n";
          # ------------------------------
          # We replace NUMBER by NUMBER**2
          # ------------------------------
          $eslifRecognizer->lexemeRead('NUMBER', $lastPause, 0);
          $eslifRecognizer->lexemeRead('POW', '*ANYTHING*', 0);
          $eslifRecognizer->lexemeRead('NUMBER', '2', 0);
          # -------------------------------------------
          # We say to resume exactly where NUMBER ended
          # -------------------------------------------
          $eslifRecognizer->resume(bytes::length($lastPause));
          $alreadyResumed = 1;
          last
        }
      }
    }
    $eslifRecognizer->resume() unless $alreadyResumed
  } while ($eslifRecognizer->isCanContinue)
}
$eslifValueInterface = MyValue->new();
$eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $eslifValueInterface);
while ($eslifValue->value()) {
  #
  # (1**2 + 2**2) * 3**2 = (1*ANYTHING*2+2*ANYTHING*2)*3*ANYTHING*2
  #
  printf "======> %s\n", $eslifValueInterface->getResult;
}

