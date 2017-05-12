#
# This file is adapted from Marpa::R2's t/sl_advent.t
#
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
use Test::More;
use Test::More::UTF8;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use Encode qw/decode encode/;
use utf8;
use open ':std', ':encoding(utf8)';

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

my $base_dsl = <<'END_OF_BASE_DSL';
:desc ::= '$TEST'
:start ::= deal
deal ::= hands
hands ::= hand | hands ';' hand
hand ::= card card card card card
card ~ face suit
face ~ [2-9jqka] | '10'
WS ~ [\s]
:discard ::= WS

:lexeme ::= <card>  pause => after event => card
END_OF_BASE_DSL

my $eslif = MarpaX::ESLIF->new($log);
isa_ok($eslif, 'MarpaX::ESLIF');

my @tests = ();
push @tests,
    [
    '2♥ 5♥ 7♦ 8♣ 9♠',
    'Parse OK',
    'Hand was 2♥ 5♥ 7♦ 8♣ 9♠',
    ];
push @tests,
    [
    '2♥ a♥ 7♦ 8♣ j♥',
    'Parse OK',
    'Hand was 2♥ a♥ 7♦ 8♣ j♥',
    ];
push @tests,
    [
    'a♥ a♥ 7♦ 8♣ j♥',
    'Parse stopped by application',
    'Duplicate card a♥'
    ];
push @tests,
    [
    'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♥ q♥ k♥ a♥',
    'Parse stopped by application',
    'Duplicate card j♥'
    ];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣ 3♦',
    'Parse OK',
    'Hand was 2♥ 7♥ 2♦ 3♣ 3♦',
    ];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣',
    'Parse reached end of input, but failed',
    'No hands were found'
    ];
push @tests, [
    '2♥ 7♥ 2♦ 3♣ 3♦ 1♦',
    'Parse failed before end',
    undef
    ];
push @tests,
    [
    '2♥ 7♥ 2♦ 3♣',
    'Parse reached end of input, but failed',
    'No hands were found'
    ];
push @tests,
    [
    'a♥ 7♥ 7♦ 8♣ j♥; 10♥ j♣ q♥ k♥',
    'Parse failed after finding hand(s)',
    'Last hand successfully parsed was a♥ 7♥ 7♦ 8♣ j♥'
    ];

my @suit_line = (
    [ 'suit ~ [\x{2665}\x{2666}\x{2663}\x{2660}]:u', 'hex' ],
    [ 'suit ~ [♥♦♣♠]',                     'char class' ],
    [ q{suit ~ '♥' | '♦' | '♣'| '♠'},      'strings' ],
);

for my $test_data (@tests) {
    my ( $input, $expected_result, $expected_value ) = @{$test_data};
    my ( $actual_result, $actual_value );

    utf8::encode(my $byte_input = $input);

    for my $suit_line_data (@suit_line) {
        my ( $suit_line, $suit_line_type ) = @{$suit_line_data};
      PROCESSING: {
          # Note: in production, you would compute the three grammar variants
          # ahead of time.
          my $full_dsl = $base_dsl . $suit_line;
          $full_dsl =~ s/\$TEST/$input/;
          my $grammar = MarpaX::ESLIF::Grammar->new($eslif, $full_dsl);
          my $description = $grammar->currentDescription;
          my $descriptionByLevel0 = $grammar->descriptionByLevel(0);
          my $descriptionByLevel1 = $grammar->descriptionByLevel(1);
          ok(utf8::is_utf8($description), "Description '$description' have the utf8 flag");
          ok(utf8::is_utf8($descriptionByLevel0), "descriptionByLevel(0) '$descriptionByLevel0' have the utf8 flag");
          ok(utf8::is_utf8($descriptionByLevel1), "descriptionByLevel(1) '$descriptionByLevel1' have the utf8 flag");
          my $recognizerInterface = MyRecognizerInterface->new($input);
          my $re = MarpaX::ESLIF::Recognizer->new($grammar, $recognizerInterface);
          my %played = ();
          my $pos;
          my $ok = $re->scan();
          while ($ok && $re->isCanContinue()) {

            # In our example there is a single event: no need to ask what it is
            my $card = $re->lexemeLastPause('card');
            ok(utf8::is_utf8($card), "Card '$card' have the utf8 flag");
            if ( ++$played{$card} > 1 ) {
                $actual_result = 'Parse stopped by application';
                $actual_value  = "Duplicate card " . $card;
                last PROCESSING;
            }
            $ok = $re->resume();
          }
          if ( not $ok ) {
              $actual_result = "Parse failed before end";
              $actual_value  = $@;
              last PROCESSING;
          }

          my $valueInterface = MyValueInterface->new();
          my $status = eval { MarpaX::ESLIF::Value->new($re, $valueInterface)->value() };
          my $last_hand;
          my ($handoffset, $handlength) = eval { $re->lastCompletedLocation('hand') };
          if ( $handlength ) {
              $last_hand = decode('UTF-8', my $tmp = substr($byte_input, $handoffset, $handlength), Encode::FB_CROAK);
          }
          if ($status) {
              my $value = $valueInterface->getResult();
              ok(utf8::is_utf8($value), "Value '$value' have the utf8 flag");
              $actual_result = 'Parse OK';
              $actual_value  = "Hand was $last_hand";
              last PROCESSING;
          }
          if ( defined $last_hand ) {
              $actual_result = 'Parse failed after finding hand(s)';
              $actual_value =  "Last hand successfully parsed was $last_hand";
              last PROCESSING;
          }
          $actual_result = 'Parse reached end of input, but failed';
          $actual_value  = 'No hands were found';
        }

        is( $actual_result, $expected_result, "Result of $input using $suit_line_type" );
        is( $actual_value, $expected_value, "Value of $input using $suit_line_type" ) if $expected_value;
    }
}

done_testing();


