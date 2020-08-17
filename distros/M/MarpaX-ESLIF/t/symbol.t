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
use Test::More tests => 10;
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

my $dsl = q{
X ::= 'X'
};

my $target       = "This is a string\nsubject";
my $input        = $target . " followed by anything";

my $stringSymbol = MarpaX::ESLIF::Symbol->new($eslif, type => 'string', pattern => "'$target'");
isa_ok($stringSymbol, 'MarpaX::ESLIF::Symbol');
my $regexSymbol  = MarpaX::ESLIF::Symbol->new($eslif, type => 'regex', pattern => "a.*\nsubject", modifiers => 'A');
isa_ok($regexSymbol, 'MarpaX::ESLIF::Symbol');

my $match;

$match = $stringSymbol->try($input) // '';
ok($match eq $target, "String try");
$match = $regexSymbol->try($input) // '';
ok($match eq "a string\nsubject", "Regex try");

my $recognizerInterface = MyRecognizerInterface->new($input);
my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $dsl);
isa_ok($eslifGrammar, 'MarpaX::ESLIF::Grammar');
my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $recognizerInterface);
isa_ok($eslifRecognizer, 'MarpaX::ESLIF::Recognizer');

$match = $eslifRecognizer->symbolTry($stringSymbol) // '';
ok($match eq $target, "Recognizer string try");
$match = $eslifRecognizer->symbolTry($regexSymbol) // '';
ok($match eq "a string\nsubject", "Recognizer regex try");

exit 0;
