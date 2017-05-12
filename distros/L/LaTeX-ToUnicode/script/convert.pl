#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

use feature 'say';
use FindBin;

my $UNICODE_DATA_URL = "http://www.unicode.org/Public/UNIDATA/UnicodeData.txt";


my $stream;
if ( -f "$FindBin::Bin/UnicodeData.txt" ) {
    open $stream, "<", "$FindBin::Bin/UnicodeData.txt" or die;
} else {
    open $stream, "-|", "curl $UNICODE_DATA_URL" or die;
}
my %data;

my %chars = (
  'ACUTE' => "'",
  'ACUTE AND DOT ABOVE' => '',
  'BAR' => '',
  'BELT' => '',
  'BREVE' => 'u',
  'BREVE AND ACUTE' => '',
  'BREVE AND DOT BELOW' => '',
  'BREVE AND GRAVE' => '',
  'BREVE AND HOOK ABOVE' => '',
  'BREVE AND TILDE' => '',
  'BREVE BELOW' => '',
  'CARON' => 'v',
  'CARON AND DOT ABOVE' => '',
  'CEDILLA' => 'c',
  'CEDILLA AND ACUTE' => '',
  'CEDILLA AND BREVE' => '',
  'CIRCUMFLEX' => '^',
  'CIRCUMFLEX AND ACUTE' => '',
  'CIRCUMFLEX AND DOT BELOW' => '',
  'CIRCUMFLEX AND GRAVE' => '',
  'CIRCUMFLEX AND HOOK ABOVE' => '',
  'CIRCUMFLEX AND TILDE' => '',
  'CIRCUMFLEX BELOW' => '',
  'COMMA' => '',
  'COMMA BELOW' => '',
  'CROSSED-TAIL' => '',
  'CURL' => '',
  'DESCENDER' => '',
  'DIAERESIS' => '"',
  'DIAERESIS AND ACUTE' => '',
  'DIAERESIS AND CARON' => '',
  'DIAERESIS AND GRAVE' => '',
  'DIAERESIS AND MACRON' => '',
  'DIAERESIS BELOW' => '',
  'DIAGONAL STROKE' => '',
  'DOT ABOVE' => '.',
  'DOT ABOVE AND MACRON' => '',
  'DOT BELOW' => 'd',
  'DOT BELOW AND DOT ABOVE' => '',
  'DOT BELOW AND MACRON' => '',
  'DOUBLE ACUTE' => 'H',
  'DOUBLE BAR' => '',
  'DOUBLE GRAVE' => '',
  'FISHHOOK' => '',
  'FISHHOOK AND MIDDLE TILDE' => '',
  'FLOURISH' => '',
  'GRAVE' => '`',
  'HIGH STROKE' => '',
  'HOOK' => '',
  'HOOK ABOVE' => 'h',
  'HOOK AND TAIL' => '',
  'HOOK TAIL' => '',
  'HORIZONTAL BAR' => '',
  'HORN' => '',
  'HORN AND ACUTE' => '',
  'HORN AND DOT BELOW' => '',
  'HORN AND GRAVE' => '',
  'HORN AND HOOK ABOVE' => '',
  'HORN AND TILDE' => '',
  'INVERTED BREVE' => '',
  'LEFT HOOK' => '',
  'LINE BELOW' => '',
  'LONG LEG' => '',
  'LONG RIGHT LEG' => '',
  'LONG STROKE OVERLAY' => '',
  'LOOP' => '',
  'LOW RING INSIDE' => '',
  'MACRON' => '=',
  'MACRON AND ACUTE' => '',
  'MACRON AND DIAERESIS' => '',
  'MACRON AND GRAVE' => '',
  'MIDDLE DOT' => '',
  'MIDDLE TILDE' => '',
  'NOTCH' => '',
  'OGONEK' => 'k',
  'OGONEK AND MACRON' => '',
  'PALATAL HOOK' => '',
  'RETROFLEX HOOK' => '',
  'RIGHT HALF RING' => '',
  'RIGHT HOOK' => '',
  'RING ABOVE' => 'r',
  'RING ABOVE AND ACUTE' => '',
  'RING BELOW' => '',
  'SMALL LETTER J' => '',
  'SMALL LETTER Z' => '',
  'SMALL LETTER Z WITH CARON' => '',
  'SQUIRREL TAIL' => '',
  'STRIKETHROUGH' => '',
  'STROKE' => '',
  'STROKE AND ACUTE' => '',
  'STROKE AND DIAGONAL STROKE' => '',
  'STROKE THROUGH DESCENDER' => '',
  'SWASH TAIL' => '',
  'TAIL' => '',
  'TILDE' => '~',
  'TILDE AND ACUTE' => '',
  'TILDE AND DIAERESIS' => '',
  'TILDE AND MACRON' => '',
  'TILDE BELOW' => '',
  'TOPBAR' => '',
);

my %missing;

while(<$stream>) {
    chomp;
    my @F = split /;/; 
    my $hex = $F[0]; 
    if ( $F[1] =~ /LATIN (SMALL|CAPITAL) LETTER ((?:\w+ )*\w{1,2}) WITH (.+)$/ ) {
        my $case = $1;
        my $letter = $2;
        my $accent = $3;

        if ( $case eq 'SMALL' ) {
            $letter = lc $letter;
        }
        if ( $chars{$accent} && $letter !~ / / ) {
            my $char = chr( eval "0x$hex" );
            $data{ $chars{$accent} }->{ $letter } = $char;
            if ( lc( $letter ) eq 'i' ) {
                my $additional_letter = "\\$letter";
                $data{ $chars{$accent} }->{ $additional_letter } = $char;
            }
        } else {
            push @{ $missing{$accent} }, $letter;
        }
    }
}

use Data::Dumper::Concise;

binmode(STDOUT, ":utf8");

say Dumper( \%data );
#say Dumper( \%missing );
