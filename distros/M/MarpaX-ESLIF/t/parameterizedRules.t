package MyRecognizerInterface;
use strict;
use diagnostics;
use Log::Any qw/$log/;
use Carp qw/croak/;

sub new                    { my ($pkg, $string) = @_; bless { string => $string, nbParameterizedRhsCalls => 0 }, $pkg }
sub read                   { 1 }
sub isEof                  { 1 }
sub isCharacterStream      { 1 }
sub encoding               { }
sub data                   { $_[0]->{string} }
sub isWithDisableThreshold { 0 }
sub isWithExhaustion       { 0 }
sub isWithNewline          { 1 }
sub isWithTrack            { 1 }
sub parameterizedRhs {
    my $self = shift;

    my ($parameter, $undef, $explanation) = @_;

    my $output;
    $self->{nbParameterizedRhsCalls}++;
    if ($self->{nbParameterizedRhsCalls} == 5) {
        $output = "start ::= '5'\n";
    } elsif ($self->{nbParameterizedRhsCalls} > 5) {
        $output = "start ::= 'no match'\n";
    } else {
        ++$parameter;
        $output = "start ::= . => parameterizedRhs->($parameter, { x = 'Value of x', y = 'Value of y' }, 'Input should be \"$parameter\"')\n";
    }
    $log->infof('In rhs, parameters: %s => %s', \@_, $output);

    return $output;
}

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
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;

#
# Init log
#
our $defaultLog4perlConf = '
log4perl.rootLogger              = INFO, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 0
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

BEGIN { require_ok('MarpaX::ESLIF') };

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');

my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, do { local $/; <DATA> });
isa_ok($eslifGrammar, 'MarpaX::ESLIF::Grammar');

my @strings = (
    "5",
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

  $recognizerInterface = MyRecognizerInterface->new($string);
  $valueInterface = MyValueInterface->new();
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
 * Example of parameterized rules
*/
:discard ::= /[\s]+/

top  ::= rhs1
rhs1 ::= . => parameterizedRhs->(1, nil, 'Input should be "1"')
       | . => parameterizedRhs->(2, nil, 'Input should be "2"')
       | . => parameterizedRhs->(3, nil, 'Input should be "3"')
       | . => parameterizedRhs->(4, nil, 'Input should be "4"')
