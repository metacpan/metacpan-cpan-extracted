#####################################################################
package Helpers;

use strict;
use warnings;
use utf8;

sub new {
    my ($class) = @_;
    return bless { "Helpers" => {} }, $class;
}

sub makeChars {
    my ( $class, $json ) = @_;

    my @chars = split( "", $json );
    $class->{"Helpers"}->{"Chars"}  = \@chars;
    $class->{"Helpers"}->{"length"} = $#chars;
}

sub jsonLength {
    my ($class) = @_;

    my $jsonLength = $class->{"Helpers"}->{"length"};
    return $jsonLength;
}

sub getChar {
    my ($class) = @_;

    my @chars       = @{ $class->{"Helpers"}->{"Chars"} };
    my $currentChar = shift(@chars);
    $class->{"Helpers"}->{"Chars"} = \@chars;
    return $currentChar;
}

sub nextChar {
    my ($class) = @_;

    my @chars       = @{ $class->{"Helpers"}->{"Chars"} };
    my $currentChar = $chars[0];
    return $currentChar;
}

sub putChar {
    my ( $class, $char ) = @_;

    my @chars = @{ $class->{"Helpers"}->{"Chars"} };
    unshift( @chars, $char );
    $class->{"Helpers"}->{"Chars"} = \@chars;
}
1;

#####################################################################
package CharGroups;

use strict;
use warnings;
use utf8;
no warnings qw(experimental::smartmatch);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub isSpaceNewline {
    my ( $class, $char ) = @_;

    my @spaceNewline = ( " ", "\n" );
    if ( $char ~~ @spaceNewline ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isDigit {
    my ( $class, $char ) = @_;

    my @digits = ( "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" );
    foreach my $digit (@digits) {
        if ( $char eq $digit ) {
            return 1;
        }
    }

    return 0;
}

sub isQuote {
    my ( $class, $char ) = @_;
    if ( $char eq "\"" ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isAlpha {
    my ( $class, $char ) = @_;
    my @alpha = ();

    for my $char ( 'a' ... 'z' ) {
        push @alpha, $char;
    }
    for my $char ( 'A' ... 'Z' ) {
        push @alpha, $char;
    }

    if ( $char ~~ @alpha ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isSpecialCharachter {
    my ( $class, $char ) = @_;
    my @specialCharachters = ( "{", "}", "[", "]", ",", ":" );

    if ( $char ~~ @specialCharachters ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

#####################################################################
package Lexer;

use strict;
use warnings;
use utf8;
use Data::Printer;

our @ISA = qw(Helpers CharGroups);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub lexer {
    my ( $class, $json ) = @_;
    my @tokens;

    $class->makeChars($json);

    my $counter    = 0;
    my $jsonLength = $class->jsonLength();

    while ( $counter <= $jsonLength ) {
        my $currentChar = $class->getChar();
        $counter++;

        if ( $class->isSpaceNewline($currentChar) ) {
            next;
        }

        if ( $class->isSpecialCharachter($currentChar) ) {
            my $token =
              { "type" => "SpecialCharachter", "value" => $currentChar };
            push( @tokens, $token );
            next;
        }

        if ( $class->isQuote($currentChar) ) {
            my $string    = "";
            my $delimiter = $currentChar;

            $currentChar = $class->getChar();
            $counter++;

            while ( $currentChar ne $delimiter ) {
                $string .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
            }

            my $token = { "type" => "String", "value" => $string };
            push( @tokens, $token );
            next;
        }

        if ( $class->isAlpha($currentChar) ) {
            my $symbol = "";
            $symbol .= $currentChar;

            $currentChar = $class->getChar();
            $counter++;

            while ( $class->isAlpha($currentChar) ) {
                $symbol .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
            }

            $class->putChar($currentChar);
            $counter = $counter - 1;

            my $token = { "type" => "Symbol", "value" => $symbol };
            push( @tokens, $token );
            next;
        }

        if ( $class->isDigit($currentChar) ) {
            my $number = "";
            $number .= $currentChar;

            $currentChar = $class->getChar();
            $counter++;

            while ( $class->isDigit($currentChar) || $currentChar eq "." ) {
                $number .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
            }

            $class->putChar($currentChar);
            $counter = $counter - 1;

            my $token = { "type" => "Number", "value" => $number };
            push( @tokens, $token );
            next;
        }
    }

    return @tokens;
}

1;

#####################################################################
package ParserHelpers;

use strict;
use warnings;
use utf8;

sub new {
    my ($class) = @_;
    return bless { "ParserHelpers" => {} }, $class;
}

sub makeTokens {
    my ( $class, $tokens ) = @_;

    my @tokens = @{$tokens};
    $class->{"ParserHelpers"}->{"Tokens"}       = \@tokens;
    $class->{"ParserHelpers"}->{"TokensLength"} = $#tokens;
}

sub tokensLength {
    my ($class) = @_;

    my $tokensLength = $class->{"ParserHelpers"}->{"TokensLength"};
    return $tokensLength;
}

sub getToken {
    my ($class) = @_;

    my @tokens       = @{ $class->{"ParserHelpers"}->{"Tokens"} };
    my $currentToken = shift(@tokens);
    $class->{"ParserHelpers"}->{"Tokens"} = \@tokens;
    return $currentToken;
}

sub nextToken {
    my ($class) = @_;

    my @tokens       = @{ $class->{"ParserHelpers"}->{"Tokens"} };
    my $currentToken = $tokens[0];
    return $currentToken;
}

sub putToken {
    my ( $class, $token ) = @_;

    my @tokens = @{ $class->{"ParserHelpers"}->{"Tokens"} };
    unshift( @tokens, $token );
    $class->{"ParserHelpers"}->{"Tokens"} = \@tokens;
}

sub tabSpace {
    my ($class) = @_;
    $class->{"ParserHelpers"}->{"tabSpace"} = 0;
}

sub incTabSpace {
    my ($class) = @_;
    my $tabSpace = $class->{"ParserHelpers"}->{"tabSpace"};
    $tabSpace = $tabSpace + 1;
    $class->{"ParserHelpers"}->{"tabSpace"} = $tabSpace;
}

sub decTabSpace {
    my ($class) = @_;
    my $tabSpace = $class->{"ParserHelpers"}->{"tabSpace"};
    $tabSpace = $tabSpace - 1;
    $class->{"ParserHelpers"}->{"tabSpace"} = $tabSpace;
}

1;

#####################################################################
package Parser;

use strict;
use warnings;
use utf8;
use Data::Printer;

our @ISA = qw(ParserHelpers);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub parse {
    my ( $class, $tokens ) = @_;
    $class->makeTokens($tokens);

    my $json = $class->Json();
    if($json) {
        return $json;
    } else {
        return 0;
    }
}

sub Json {
    my ( $class ) = @_;

    my $hash = $class->hash();
    if( $hash ) {
        return $hash;
    } else {
        return 0;
    }
}

sub hash {
    my ( $class ) = @_;
    my $hash = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "{" ) {
        my $hash .= "{\n";

        my $keyValues = $class->keyValues();
        $hash .= $keyValues;

        $currentToken = $class->getToken();
        if ( $currentToken->{"value"} eq "}" ) {
            $hash .= "\n}";
            return $hash;
        } else {
            $class->putToken($currentToken);
            return 0;
        }
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub keyValues {
    my ( $class ) = @_;
    my $keyValues = "";

    my $keyValue = $class->keyValue();
    if ( $keyValue ) {
        $keyValues .= $keyValue;
        # print $keyValues, "\n";
    } else {
        return 0;
    }

    my $comma = $class->comma();
    if ( $comma ) {
        $keyValues .= $comma . "\n";
    } else {
        return $keyValues;
    }

    my $rightKeyValues = $class->keyValues();
    if ( $rightKeyValues ) {
        $keyValues .= $rightKeyValues;
    } else {
        return 0;
    }

    return $keyValues;
}

sub comma {
    my ( $class ) = @_;
    my $comma = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "," ) {
        $comma .= ",";
        return $comma;
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub keyValue {
    my ( $class ) = @_;
    my $keyValue = "";

    my $key = $class->key();
    if ( $key ) {
        $keyValue .= $key;
    } else {
        return 0;
    }

    my $sep = $class->sep();
    if ( $sep ) {
        $keyValue .= $sep . " ";
    } else {
        return 0;
    }

    my $value = $class->value();
    if ( $value ) {
        $keyValue .= $value;
    } else {
        return 0;
    }

    return $keyValue;
}

sub sep {
    my ( $class ) = @_;
    my $sep = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ":" ) {
        $sep .= ":";
        return $sep;
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub key {
    my ( $class ) = @_;
    my $key = "";

    my $anyValue = $class->anyValue();
    if ( $anyValue ) {
        $key .= $anyValue;
        return $key;
    } else {
        return 0;
    }
}

sub value {
    my ( $class ) = @_;
    my $value = "";

    my $anyValue = $class->anyValue();
    if ( $anyValue ) {
        $value .= $anyValue;
        return $value;
    } else {
        return 0;
    }
}

sub anyValue {
    my ( $class ) = @_;

    my $hash = $class->hash();
    if ( $hash ) {
        return $hash;
    }

    my $array = $class->array();
    if ( $array ) {
        return $array;
    }

    my $stringValue = $class->stringValue();
    if ( $stringValue ) {
        return $stringValue;
    }

    my $numericValue = $class->numericValue();
    if ( $numericValue ) {
        return $numericValue;
    }

    my $nullValue = $class->nullValue();
    if ( $nullValue ) {
        return $nullValue;
    }

    return 0;
}

sub stringValue {
    my ( $class ) = @_;
    my $string = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "String" ) {
        $string .= '"' . $currentToken->{"value"} . '"';
        return $string;
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub numericValue {
    my ( $class ) = @_;

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Number" ) {
        my $number = $currentToken->{"value"};
        return $number;
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub nullValue {
    my ( $class ) = @_;
    my $null = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "null" ) {
        $null .= "null";
        return $null;
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub array {
    my ( $class ) = @_;
    my $array = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "[" ) {
        $array .= "[";

        my $arrayElements = $class->arrayElements();
        $array .= $arrayElements;

        $currentToken = $class->getToken();
        if ( $currentToken->{"value"} eq "]" ) {
            $array .= "]";
            return $array;
        } else {
            $class->putToken($currentToken);
            return 0;
        }
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub arrayElements {
    my ( $class ) = @_;
    my $arrayElements = "";

    my $arrayElement = $class->arrayElement();
    if ( $arrayElement ) {
        $arrayElements .= $arrayElement;
    } else {
        return 0;
    }

    my $comma = $class->comma();
    if ( $comma ) {
        $arrayElements .= $comma . " ";
    } else {
        return $arrayElements;
        return 0;
    }

    my $rightArrayElements = $class->arrayElements();
    if ( $arrayElements ) {
        $arrayElements .= $rightArrayElements;
    } else {
        return 0;
    }

    return $arrayElements;
}

sub arrayElement {
    my ( $class ) = @_;
    my $arrayElement = "";

    my $anyValue = $class->anyValue();
    if ( $anyValue ) {
        $arrayElement .= $anyValue;
    } else {
        return 0;
    }

    return $arrayElement;
}

1;

package JSON::Formatter::Align;

use strict;
use warnings;
use utf8;

our $VERSION = '0.03';
our @ISA = qw(Lexer Parser);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub json {
    my ( $class, $json ) = @_;

    my @tokens    = $class->lexer($json);
    my $formattedJson = $class->parse( \@tokens );
	return $formattedJson;
}


1;
__END__

=head1 NAME

JSON::Formatter::Align - Formatting for JSON

=head1 SYNOPSIS

  use JSON::Formatter::Align;

  my $json = <<END;
  {
      "glossary" : {
          "title" : "example glossary",
  		"GlossDiv" : {
              "title" : "S",
  			"GlossList" : {
                  "GlossEntry" : {
                      "ID" : "SGML",
  				    "SortAs" : "SGML",
  				    "GlossTerm" : "Standard Generalized Markup Language",
  				    "Acronym" : "SGML",
  				    "Abbrev" : "ISO 8879:1986",
  				    "GlossDef" : {
                          "para" : "A meta-markup language, used to create markup languages such as DocBook.",
  					    "GlossSeeAlso" : ["GML", "XML"]
                  	},
  				    "GlossSee" : "markup"
                 	}
              }
          }
      }
  }
  END

  my $jsonFormatter = JSON::Formatter::Align->new();
  print $jsonFormatter->json($json);

=head1 DESCRIPTION

Formatting for JSON.
Look for the future versions of this package.

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.30.0 or, at your option, any later version of Perl 5 you may have available.


=cut
