#!env perl
#
# Dump PCRE2 callout.
#
# Example: echo "\"foo\\\\u0000bar\"" | perl callout_inspect.pl "/\"(?C50)(?:((?:[^\"\\\\\\x00-\\x1F]+)|(?:\\\\[\"\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*\"(?C52)/"
# Output is in the __DATA_ section
# 
package MyRecognizerInterface;
use Data::Dumper;

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
sub regex_action           { my ($self) = shift; print Dumper(shift); 0 }

package MyValueInterface;
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
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;
use MarpaX::ESLIF;

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

my $re_as_string = shift || die "Usage: $0 regexp";
#
# Generate a grammar from it
#
my $ESLIF = MarpaX::ESLIF->new($log);
my $GRAMMAR = MarpaX::ESLIF::Grammar->new($ESLIF, ":default ::= regex-action => regex_action input ::= $re_as_string");
#
# Loop on input from the command-line and parse it - this will dump the callouts
#
while (my $line = <STDIN>) {
    $line =~ s/\R$//;
    print STDERR ">>>>>>>>>$line<<<<<<<<<\n";
    my $recognizerInterface = MyRecognizerInterface->new($line);
    my $valueInterface = MyValueInterface->new();
    $GRAMMAR->parse($recognizerInterface, $valueInterface);
}

__DATA__
# Example: echo "\"foo\\\\u0000bar\"" | perl callout_inspect.pl "/\"(?C50)(?:((?:[^\"\\\\\\x00-\\x1F]+)|(?:\\\\[\"\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*\"(?C52)/"
#
# There are 5 callouts:
#
# First the opening ":
#
$VAR1 = bless( {
                 'callout_number' => 50,
                 'offset_vector' => [
                                      -1,
                                      -1
                                    ],
                 'current_position' => 1,
                 'mark' => undef,
                 'capture_top' => 1,
                 'subject' => '"foo\\u0000bar"',
                 'next_item' => '(?:',
                 'capture_last' => 0,
                 'start_match' => 0,
                 'pattern' => '"(?C50)(?:((?:[^"\\\\\\x00-\\x1F]+)|(?:\\\\["\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*"(?C52)',
                 'callout_string' => undef
               }, 'MarpaX::ESLIF::RegexCallout' );

#
# Then foo:
#
$VAR1 = bless( {
                 'current_position' => 4,
                 'offset_vector' => [
                                      -1,
                                      -1,
                                      1,
                                      4
                                    ],
                 'callout_number' => 51,
                 'mark' => undef,
                 'next_item' => ')*',
                 'subject' => '"foo\\u0000bar"',
                 'capture_top' => 2,
                 'callout_string' => undef,
                 'pattern' => '"(?C50)(?:((?:[^"\\\\\\x00-\\x1F]+)|(?:\\\\["\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*"(?C52)',
                 'capture_last' => 1,
                 'start_match' => 0
               }, 'MarpaX::ESLIF::RegexCallout' );
#
# Then \u0000:
#
$VAR1 = bless( {
                 'start_match' => 0,
                 'capture_last' => 1,
                 'callout_string' => undef,
                 'pattern' => '"(?C50)(?:((?:[^"\\\\\\x00-\\x1F]+)|(?:\\\\["\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*"(?C52)',
                 'subject' => '"foo\\u0000bar"',
                 'capture_top' => 2,
                 'next_item' => ')*',
                 'mark' => undef,
                 'offset_vector' => [
                                      -1,
                                      -1,
                                      4,
                                      10
                                    ],
                 'callout_number' => 51,
                 'current_position' => 10
               }, 'MarpaX::ESLIF::RegexCallout' );
#
# Then bar:
#
$VAR1 = bless( {
                 'next_item' => ')*',
                 'capture_top' => 2,
                 'subject' => '"foo\\u0000bar"',
                 'pattern' => '"(?C50)(?:((?:[^"\\\\\\x00-\\x1F]+)|(?:\\\\["\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*"(?C52)',
                 'callout_string' => undef,
                 'start_match' => 0,
                 'capture_last' => 1,
                 'current_position' => 13,
                 'callout_number' => 51,
                 'offset_vector' => [
                                      -1,
                                      -1,
                                      10,
                                      13
                                    ],
                 'mark' => undef
               }, 'MarpaX::ESLIF::RegexCallout' );
#
# Then the closing ":
#
$VAR1 = bless( {
                 'next_item' => undef,
                 'capture_top' => 2,
                 'subject' => '"foo\\u0000bar"',
                 'pattern' => '"(?C50)(?:((?:[^"\\\\\\x00-\\x1F]+)|(?:\\\\["\\\\\\/bfnrt])|(?:(?:\\\\u[[:xdigit:]]{4})+))(?C51))*"(?C52)',
                 'callout_string' => undef,
                 'start_match' => 0,
                 'capture_last' => 1,
                 'current_position' => 14,
                 'callout_number' => 52,
                 'offset_vector' => [
                                      -1,
                                      -1,
                                      10,
                                      13
                                    ],
                 'mark' => undef
               }, 'MarpaX::ESLIF::RegexCallout' );
