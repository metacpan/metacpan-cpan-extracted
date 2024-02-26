package MyRecognizerInterface;
use strict;
use diagnostics;
use Log::Any qw/$log/;

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
use Test::More tests => 3;
use Log::Any qw/$log/;
use Log::Any::Adapter 'Stdout';

BEGIN { require_ok('MarpaX::ESLIF') };

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');

my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });
isa_ok($eslifGrammar, 'MarpaX::ESLIF::Grammar');

my @strings = (
    "(((3 * 4) + 2 * 7) / 2 - 1) ** 3",
    "5 / (2 * 3)",
    "5 / 2 * 3",
    "(5 ** 2) ** 3",
    "5 * (2 * 3)",
    "5 ** (2 ** 3)",
    "5 ** (2 / 3)",
    "1 + ( 2 + ( 3 + ( 4 + 5) )",
    "1 + ( 2 + ( 3 + ( 4 + 50) ) )",
    " 100"
    );

#
# Test the parse() interface
#
for (my $i = 0; $i <= $#strings; $i++) {
  my $string = $strings[$i];

  my $recognizerInterface = MyRecognizerInterface->new($string);
  my $valueInterface = MyValueInterface->new();
  my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $recognizerInterface);

  if ($eslifRecognizer->scan) {
      my $ok = 1;
      while ($eslifRecognizer->isCanContinue) {
          if (! $eslifRecognizer->resume) {
              $ok = 0;
              last;
          }
      }
      if ($ok) {
          my $eslifValue = eval { MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface) };
          if (defined($eslifValue)) {
              while ($eslifValue->value) {
                  my $result = $valueInterface->getResult;
                  if (defined($result)) {
                      diag("$string => $result");
                  } else {
                      diag("$string => <undef>");
                  }
              }
          }
      }
  }

  if ($eslifGrammar->parse($recognizerInterface, $valueInterface)) {
    my $result = $valueInterface->getResult;
    if (defined($result)) {
      diag("$string => $result");
    } else {
      diag("$string => <undef>");
    }
  } else {
    diag("$string => ?");
  }
}

__DATA__
/*
 * Example of a calulator with ESLIF BNF:
 *
 * Automatic discard of whitespaces
 * Correct association for expressions
 * Embedded action using anonymous lua functions
 *
*/
:discard ::= /[\s]+/
:default ::= event-action => ::luac->function()
                                       print('In event-action')
                                       return true
                                     end
event ^exp = predicted exp
exp ::=
    /[\d]+/                             action => ::lua->function(input) return tonumber(input) end
    |    "("  exp ")"    assoc => group action => ::lua->function(l,e,r) return e               end
   || exp (- '**' -) exp assoc => right action => ::lua->function(x,y)   return x^y             end
   || exp (-  '*' -) exp                action => ::luac->function(x,y)  return x*y             end
    | exp (-  '/' -) exp                action => ::lua->function(x,y)   return x/y             end
   || exp (-  '+' -) exp                action => ::luac->function(x,y)  return x+y             end
    | exp (-  '-' -) exp                action => ::lua->function(x,y)   return x-y             end
