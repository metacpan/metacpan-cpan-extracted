package MyRecognizerInterface;
use strict;
use diagnostics;

sub new                    { my ($pkg, $characterStream) = @_; bless { characterStream => $characterStream }, $pkg }
sub read                   { 1 }
sub isEof                  { 1 }
sub isCharacterStream      { $_[0]->{characterStream} // 1 }
sub encoding               { }
sub data                   { " " } # One byte
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
sub perl_proxy         { $_[1] }

package main;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 31; # require_ok + scalar(@input)
use Test::More::UTF8;
use Test::Deep qw/cmp_details deep_diag/;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use Math::BigInt;
use Math::BigFloat;
use Encode qw/ encode :fallbacks /;
use utf8;
use Safe::Isa;
use open qw( :utf8 :std );

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


BEGIN { require_ok('MarpaX::ESLIF') }
#
# Our input depends on MarpaX::ESLIF, and Test::More says it has to be
# in another BEGIN block, after the one that is loading/requiring our module
#
my @input;
BEGIN {
    @input =
        (
         undef,
         "XXX",
         "\xa0\xa1",
         ["\xa0\xa1", 0],
         ["\xf0\x28\x8c\x28", 0],
         "Ḽơᶉëᶆ ȋṕšᶙṁ ḍỡḽǭᵳ ʂǐť ӓṁệẗ, ĉṓɲṩḙċťᶒțûɾ ấɖḯƥĭṩčįɳġ ḝłįʈ, șếᶑ ᶁⱺ ẽḭŭŝḿꝋď ṫĕᶆᶈṓɍ ỉñḉīḑȋᵭṵńť ṷŧ ḹẩḇőꝛế éȶ đꝍꞎôꝛȇ ᵯáꞡᶇā ąⱡîɋṹẵ.",
         ["Ḽơᶉëᶆ ȋṕšᶙṁ ḍỡḽǭᵳ ʂǐť ӓṁệẗ, ĉṓɲṩḙċťᶒțûɾ ấɖḯƥĭṩčįɳġ ḝłįʈ, șếᶑ ᶁⱺ ẽḭŭŝḿꝋď ṫĕᶆᶈṓɍ ỉñḉīḑȋᵭṵńť ṷŧ ḹẩḇőꝛế éȶ đꝍꞎôꝛȇ ᵯáꞡᶇā ąⱡîɋṹẵ.", 0],
         ["Ḽơᶉëᶆ ȋṕšᶙṁ ḍỡḽǭᵳ ʂǐť ӓṁệẗ, ĉṓɲṩḙċťᶒțûɾ ấɖḯƥĭṩčįɳġ ḝłįʈ, șếᶑ ᶁⱺ ẽḭŭŝḿꝋď ṫĕᶆᶈṓɍ ỉñḉīḑȋᵭṵńť ṷŧ ḹẩḇőꝛế éȶ đꝍꞎôꝛȇ ᵯáꞡᶇā ąⱡîɋṹẵ.", 1],
         0,
         1,
         -32768,
         32767,
         -32769,
         32768,
         2.34,
         1.6e+308,
         Math::BigFloat->new("6.78E+9"),
         Math::BigInt->new("6.78E+9"),
         [[1, undef, 2], 0],
         "",
         $MarpaX::ESLIF::true,
         $MarpaX::ESLIF::false,
         { one => "one", two => "two", perltrue => 1, true => $MarpaX::ESLIF::true, false => $MarpaX::ESLIF::false, 'else' => 'again', 'undef' => undef },
         { element1 => { one => "one", two => "two", perltrue => 1, true => $MarpaX::ESLIF::true, false => $MarpaX::ESLIF::false, 'else' => 'again', 'undef' => undef },
           element2 => { one => "one", two => "two", perltrue => 1, true => $MarpaX::ESLIF::true, false => $MarpaX::ESLIF::false, 'else' => 'again', 'undef' => undef }},
         MarpaX::ESLIF::String->new("XXXḼơᶉëᶆYYY", 'UTF-8'),
         MarpaX::ESLIF::String->new("", 'UTF-8'),
         MarpaX::ESLIF::String->new(encode('UTF-16LE', my $s = "XXXḼơᶉëᶆYYY", FB_CROAK), 'UTF-16LE'),
         MarpaX::ESLIF::String->new("", 'UTF-16'),
         'one',
         'two'
        );
}

my $grammar = q{
event ^perl_input = predicted perl_input

perl_output ::= lua_proxy  action => perl_proxy
lua_proxy   ::= perl_input action => ::lua->lua_proxy
perl_input  ::= PERL_INPUT action => perl_proxy
PERL_INPUT    ~ [^\s\S]

<luascript>
  function table_print (tt, indent, done)
    done = done or {}
    indent = indent or 0
    if type(tt) == "table" then
      for key, value in pairs (tt) do
        io.write(string.rep (" ", indent)) -- indent it
        if type (value) == "table" and not done [value] then
          done [value] = true
          io.write(string.format("  [%s] => table\n", tostring(key)));
          io.write(string.rep (" ", indent+4)) -- indent it
          io.write("(\n");
          table_print (value, indent + 7, done)
          io.write(string.rep (" ", indent+4)) -- indent it
          io.write(")\n");
        else
          if type(value) == 'string' then
            io.write(string.format("  [%s] => %s (type: %s, encoding: %s, length: %d bytes)\n", tostring (key), tostring(value), type(value), tostring(value:encoding()), string.len(value)))
          else
            io.write(string.format("  [%s] => %s (type: %s)\n", tostring (key), tostring(value), type(value)))
          end
        end
      end
    else
      io.write(tostring(tt) .. "\n")
    end
  end
  io.stdout:setvbuf('no')

  function lua_proxy(value)
    print('  lua_proxy received value of type: '..type(value))
    if type(value) == 'string' then
      print('  lua_proxy value: '..tostring(value)..', encoding: '..tostring(value:encoding())..', length: '..string.len(value)..' bytes')
    else
      print('  lua_proxy value: '..tostring(value))
      if type(value) == 'table' then
        table_print(value)
      end
    end
    return value
  end
</luascript>
};

my $eslif = MarpaX::ESLIF->new($log);
my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $grammar);

foreach my $inputArray (@input) {
    my ($input, $characterStream) = (ref($inputArray) || '') eq 'ARRAY' ? @{$inputArray} : ($inputArray, 1);
    my $eslifRecognizerInterface = MyRecognizerInterface->new($characterStream);
    my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($eslifGrammar, $eslifRecognizerInterface);
    $eslifRecognizer->scan(1); # Initial events
    $eslifRecognizer->lexemeRead('PERL_INPUT', $input, 1, 1);
    my $eslifValueInterface = MyValueInterface->new();
    my $eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $eslifValueInterface);
    $eslifValue->value();
    my $value = $eslifValueInterface->getResult;
    if ($input->$_isa('MarpaX::ESLIF::String') && $input->encoding eq 'UTF-8') {
        #
        # marpaESLIF will always reinject UTF-8 strings as true PV scalars for performance
        #
        $input = "$input";
        $value = "$value" if defined($value);
    }
    my ($ok, $stack) = cmp_details($value, $input);
    diag(deep_diag($stack)) unless (ok($ok, "import/export of " . (ref($input) ? ref($input) : (defined($input) ? ((length($input) > 0) ? "$input" : '<empty string>') : 'undef'))));
}

done_testing();

1;
