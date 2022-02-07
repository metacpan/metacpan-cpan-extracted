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
    my ( $class, $program ) = @_;

    my @chars = split( "", $program );
    $class->{"Helpers"}->{"Chars"}  = \@chars;
    $class->{"Helpers"}->{"length"} = $#chars;
}

sub programLength {
    my ($class) = @_;

    my $programLength = $class->{"Helpers"}->{"length"};
    return $programLength;
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

sub nextNextChar {
    my ($class) = @_;

    my @chars       = @{ $class->{"Helpers"}->{"Chars"} };
    my $currentChar = $chars[1];
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

    my @spaceNewline = ( " ", "\n", "\t", "\r" );
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

sub isAlpha {
    my ( $class, $char ) = @_;
    my @alpha = ();

    for my $char ( 'a' ... 'z' ) {
        push @alpha, $char;
    }
    for my $char ( 'A' ... 'Z' ) {
        push @alpha, $char;
    }
    push @alpha, "_";

    if ( $char ~~ @alpha ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isQuote {
    my ( $class, $char ) = @_;
    if ( $char eq '"' ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isSpecialCharachter {
    my ( $class, $char ) = @_;
    my @specialCharachters =
      ( "{", "}", "(", ")", "[", "]", ",", ";", ":", ".", "=", "?" );

    if ( $char ~~ @specialCharachters ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub isOperator {
    my ( $class, $char ) = @_;
    my @operators = ( "+", "-", "|", "*", "/", ">", "<", "!", "&", "%" );

    if ( $char ~~ @operators ) {
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

our @ISA = qw(Helpers CharGroups);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub lexer {
    my ( $class, $program ) = @_;
    my @tokens;

    $class->makeChars($program);

    my $counter       = 0;
    my $programLength = $class->programLength();

    while ( $counter <= $programLength ) {
        my $currentChar = $class->getChar();
        $counter++;

        if ( $class->isSpaceNewline($currentChar) ) {
            next;
        }

        if ( $currentChar eq "#" ) {
            my $comment   = "";
            my $delimiter = "@";

            $currentChar = $class->getChar();
            $counter++;

            while ( $currentChar ne $delimiter ) {
                $comment .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
            }

            $class->getChar();
            $counter++;

            my $token = { "type" => "Comment", "value" => $comment };
            push( @tokens, $token );
            next;
        }

        if ( $currentChar eq "(" && $class->nextChar eq "?" ) {
            my $embedBlock = "";
            $class->getChar();
            $counter++;

            $currentChar = $class->getChar();
            $counter++;
            while ( $currentChar ne "?" && $class->nextChar() ne ")" ) {
                $embedBlock .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
                while ( $currentChar ne "?" ) {
                    $embedBlock .= $currentChar;
                    $currentChar = $class->getChar();
                    $counter++;
                }
            }

            $class->getChar();
            $counter++;

            my $token = { "type" => "EmbedBlock", "value" => $embedBlock };
            push( @tokens, $token );
            next;
        }

        if ( $currentChar eq "!" && $class->isAlpha( $class->nextChar() ) ) {
            my $object = "";
            $object .= $currentChar;

            $currentChar = $class->getChar();
            $counter++;

            while ( $class->isAlpha($currentChar) ) {
                $object .= $currentChar;
                $currentChar = $class->getChar();
                $counter++;
            }

            $class->putChar($currentChar);
            $counter = $counter - 1;

            my $token = { "type" => "Object", "value" => $object };
            push( @tokens, $token );
            next;
        }

        if ( $currentChar eq ":" && $class->nextChar() eq ":" ) {
            $class->getChar();
            $counter++;

            my $token = { "type" => "ObjectColon", "value" => "::" };
            push( @tokens, $token );
            next;
        }

        if ( $currentChar eq "=" && $class->nextChar() eq "=" ) {
            $class->getChar();
            $counter++;

            my $token = { "type" => "Equals", "value" => "==" };
            push( @tokens, $token );
            next;
        }

        if ( $class->isSpecialCharachter($currentChar) ) {
            my $token =
              { "type" => "SpecialCharachter", "value" => $currentChar };
            push( @tokens, $token );
            next;
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq "&" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "&" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => "&&" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq "|" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "|" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => "||" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq "!" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "=" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => "!=" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq ">" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "=" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => ">=" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq "<" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "=" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => "<=" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            if ( $currentChar eq "*" ) {
                my $nextChar = $class->nextChar();
                if ( $nextChar eq "*" ) {
                    $class->getChar();
                    $counter++;

                    my $token = { "type" => "Operator", "value" => "**" };
                    push( @tokens, $token );
                    next;
                }
            }
        }

        if ( $class->isOperator($currentChar) ) {
            my $token = { "type" => "Operator", "value" => $currentChar };
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

        if ( $currentChar eq "e" && $class->nextChar() eq "q" ) {
            $class->getChar();
            $counter++;

            my $token = { "type" => "Operator", "value" => "eq" };
            push( @tokens, $token );
            next;
        }

        if ( $currentChar eq "n" && $class->nextChar() eq "e" ) {
            $class->getChar();
            $counter++;

            my $token = { "type" => "Operator", "value" => "ne" };
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

        else {
            my $errorArea = "";
            foreach ( @tokens[ -3 .. -1 ] ) {
                my %token = %{$_};
                $errorArea .= $token{value} . " ";
            }

            print "Lexical Error at ", $errorArea, "$currentChar \n";
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

sub setCurrentClass {
    my ( $class, $className ) = @_;
    $class->{"ParserHelpers"}->{"currentClassName"} = $className;
}

sub getCurrentClass {
    my ($class) = @_;
    my $currentClassName = $class->{"ParserHelpers"}->{"currentClassName"};
    return $currentClassName;
}

sub setCurrentFunction {
    my ( $class, $functionName ) = @_;
    $class->{"ParserHelpers"}->{"currentFunctionName"} = $functionName;
}

sub getCurrentFunction {
    my ($class) = @_;
    my $currentFunctionName =
      $class->{"ParserHelpers"}->{"currentFunctionName"};
    return $currentFunctionName;
}

sub setLastBlock {
    my ( $class, $lastBlock ) = @_;
    $class->{"ParserHelpers"}->{"lastBlock"} = $lastBlock;
}

sub nextTokens {
    my ($class) = @_;
    my @tokens = @{ $class->{"ParserHelpers"}->{"Tokens"} };

    my $nextTokens;
    foreach ( @tokens[ 0 .. 5 ] ) {
        my %token = %{$_};
        $nextTokens .= $token{"value"} . " ";
    }

    return $nextTokens;
}

sub printError {
    my ($class) = @_;

    my $currentClassName    = $class->getCurrentClass();
    my $currentFunctionName = $class->getCurrentFunction();
    my $nextTokens          = $class->nextTokens();

    print "Error at: \nclassName: ", $currentClassName, "\nfunctionName: ",
      $currentFunctionName, "\nnextTokens: ", $nextTokens, "\n";
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

    my $code = $class->Lang();
    if ($code) {
        return $code;
    }
    else {
        $class->printError();
    }
}

sub Lang {

    # check line return $lang; => return 0;
    my ($class) = @_;
    my $lang = "";

    my $classString = $class->Class();
    if ($class) {
        $lang .= $classString;
    }
    else {
        return $lang;
    }

    my $rightLang = $class->Lang();
    if ($rightLang) {
        $lang .= $rightLang;
    }
    else {
        return 0;
    }

    return $lang;
}

sub Class {
    my ($class) = @_;
    my $classString = "";

    my $tokenClass = $class->TokenClass();
    if ($tokenClass) {
        $classString .= $tokenClass;
    }
    else {
        return 0;
    }

    my $className = $class->ClassName();
    if ($className) {
        $classString .= $className;
        $class->setCurrentClass($className);
    }
    else {
        return 0;
    }

    my $classBlock = $class->ClassBlock();
    if ($classBlock) {
        $classString .= $classBlock;
    }
    else {
        return 0;
    }

    return $classBlock;
}

sub TokenClass {
    my ($class) = @_;

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "class" ) {
        return "class";
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub ClassName {
    my ($class) = @_;

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        return $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub ClassBlock {
    my ($class) = @_;
    my $classBlock = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "{" ) {
        $classBlock .= "{\n";
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $classGroups = $class->ClassGroups();
    if ($classGroups) {
        $classBlock .= $classGroups;
    }
    else {
        return 0;
    }

    if ( $currentToken->{"value"} eq "}" ) {
        $classBlock .= "\n}";
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }
}

sub ClassGroups {

    # check line return $classGroups; => return 0;
    my ($class) = @_;
    my $classGroups = "";

    my $group = $class->Group();
    if ($group) {
        $classGroups .= $group;
    }
    else {
        return $classGroups;
    }

    my $rightClassGroup = $class->ClassGroups();
    if ($rightClassGroup) {
        $classGroups .= $rightClassGroup;
    }
    else {
        return 0;
    }

    return $classGroups;
}

sub Group {
    my ($class) = @_;

    my $comment = $class->Comment();
    if ($comment) {
        return $comment;
    }

    my $parent = $class->Parent();
    if ($parent) {
        return $parent;
    }

    my $packages = $class->Packages();
    if ($packages) {
        return $packages;
    }

    my $function = $class->Function();
    if ($function) {
        return $function;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub Comment {
    my ($class) = @_;
    my $comment = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "#" ) {
        $comment .= "#";
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $lineComment = $class->LineComment();
    if ($lineComment) {
        $comment .= $lineComment;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "@" ) {
        $comment .= "@";
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    return $comment;
}

sub LineComment {
    my ($class) = @_;
    my $lineComment = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Comment" ) {
        $lineComment .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    return $lineComment;
}

sub Parent {
    my ($class) = @_;
    my $parent = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "parent" ) {
        my $parent .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        my $parent .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $classNames = $class->ClassNames();
    if ($classNames) {
        $parent .= $classNames;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        my $parent .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ";" ) {
        my $parent .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    return $currentToken;
}

sub ClassNames {
    my ($class) = @_;
    my $classNames = "";

    my $className = $class->ClassName();
    if ($className) {
        $classNames .= $className;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($comma) {
        $classNames .= $comma;
    }
    else {
        return $classNames;
    }

    my $rightClassNames = $class->ClassNames();
    if ($classNames) {
        $classNames .= $rightClassNames;
    }
    else {
        return 0;
    }

    return $classNames;
}

sub Packages {
    my ($class) = @_;
    my $packages = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        $packages .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $packageList = $class->PackageList();
    if ($packageList) {
        $packages .= $packageList;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        $packages .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ";" ) {
        $packages .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    return $packages;
}

sub PackageList {
    my ($class) = @_;
    my $packageList = "";

    my $package = $class->Package();
    if ($package) {
        $packageList .= $package;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($package) {
        $packageList .= $comma;
    }
    else {
        return $packageList;
    }

    my $rightpackageList = $class->PackageList();
    if ($rightpackageList) {
        $packageList .= $rightpackageList;
    }
    else {
        return 0;
    }

    return $rightpackageList;
}

sub Package {
    my ($class) = @_;

    my $packageWithConstructor = $class->PackageWithConstructor();
    if ($packageWithConstructor) {
        return $packageWithConstructor;
    }

    my $packageWithoutConstructor = $class->PackageWithoutConstructor();
    if ($packageWithoutConstructor) {
        return $packageWithoutConstructor;
    }

    return 0;
}

sub PackageWithConstructor {
    my ($class) = @_;
    my $packageWithConstructor = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Object" ) {
        $packageWithConstructor .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "=" ) {
        $packageWithConstructor .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $packageName = $class->PackageName();
    if ($packageName) {
        $packageWithConstructor .= $packageName;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "." ) {
        $packageWithConstructor .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $constructor = $class->Constructor();
    if ($constructor) {
        $packageWithConstructor .= $packageName;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        $packageWithConstructor .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    my $objectParameters = $class->ObjectParameters();
    if ($objectParameters) {
        $packageWithConstructor .= $objectParameters;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        $packageWithConstructor .= $currentToken->{"value"};
    }
    else {
        $class->putToken($currentToken);
        return 0;
    }

    return $packageWithConstructor;
}

sub ObjectParameters {
    my ($class) = @_;

    my $packageParams = $class->PackageParams();
    if ($packageParams) {
        return $packageParams;
    }

    my $parameters = $class->Parameters();
    if ($parameters) {
        return $parameters;
    }

    return 0;
}

sub PackageParams {
    my ($class) = @_;
    my $packageParams = "";

    my $keyValue = $class->KeyValue();
    if ($keyValue) {
        $packageParams .= $keyValue;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($comma) {
        $packageParams .= $comma;
    }
    else {
        return $packageParams;
    }

    my $rightPackageParams = $class->PackageParams();
    if ($rightPackageParams) {
        $packageParams .= $rightPackageParams;
    }
    else {
        return 0;
    }

    return $packageParams;
}

sub PackageName {
    my ($class) = @_;
    my $packageName = "";

    my $packageDir = $class->PackageDir();
    if ($packageDir) {
        $packageName .= $packageDir;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "ObjectColon" ) {
        $packageName .= $currentToken->{"value"};
    }
    else {
        return $packageName;
    }

    my $rightpackageName = $class->PackageName();
    if ($rightpackageName) {
        $packageName .= $rightpackageName;
    }
    else {
        return 0;
    }

    return $packageName;
}

sub PackageWithConstructor {
    my ($class) = @_;
    my $packageWithConstructor = "";

    my $packageName = $class->PackageName();
    if ($packageName) {
        $packageWithConstructor .= $packageName;
    }
    else {
        return 0;
    }

    my $qw = $class->QW();
    if ($qw) {
        $packageWithConstructor .= $qw;
    }

    return $packageWithConstructor;
}

sub QW {
    my ($class) = @_;
    my $qw = "";

    my $dot = $class->Dot();
    if ($dot) {
        $qw .= $dot;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        $qw .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    my $functionList = $class->FunctionList();
    if ($functionList) {
        $qw .= $functionList;
    }
    else {
        return 0;
    }

    $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        $qw .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $qw;
}

sub FunctionList {
    my ($class) = @_;
    my $functionList = "";

    my $functionName = $class->FunctionName();
    if ($functionName) {
        $functionList .= $functionName;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($comma) {
        $functionList .= $comma;
    }
    else {
        return $functionList;
    }

    my $rightFunctionName = $class->FunctionList();
    if ($rightFunctionName) {
        $functionList .= $rightFunctionName;
    }
    else {
        return 0;
    }

    return $functionList;
}

sub Constructor {
    my ($class) = @_;
    my $constructor = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $constructor .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $constructor;
}

sub Object {
    my ($class) = @_;
    my $object = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Object" ) {
        $object .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $object;
}

sub PackageDir {
    my ($class) = @_;
    my $packageDir = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $packageDir .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $packageDir;
}

sub Function {
    my ($class) = @_;
    my $function = "";

    my $tokenFunction = $class->TokenFunction();
    if ($tokenFunction) {
        $function .= $tokenFunction;
    }
    else {
        return 0;
    }

    my $functionName = $class->FunctionName();
    if ($functionName) {
        $function .= $functionName;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        $function .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    my $functionParamList = $class->FunctionParamList();
    if ($functionParamList) {
        $function .= $functionParamList;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        $function .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $function .= $codeBlock;
    }
    else {
        return 0;
    }

    return $function;
}

sub FunctionName {
    my ($class) = @_;
    my $functionName = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $functionName .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $functionName;
}

sub FunctionParamList {
    my ($class) = @_;
    my $functionParamList = "";

    my $emptyParamList = $class->EmptyParamList();
    if ($emptyParamList) {
        return $emptyParamList;
    }

    my $functionParams = $class->FunctionParams();
    if ($functionParams) {
        return $functionParams;
    }

    return 0;
}

sub EmptyParamList {
    my ($class) = @_;
    return "";
}

sub FunctionParams {
    my ($class) = @_;
    my $functionParams = "";

    my $arg = $class->Arg();
    if ($arg) {
        $functionParams .= $arg;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($arg) {
        $functionParams .= $comma;
    }
    else {
        return $functionParams;
    }

    my $rightFunctionParams = $class->FunctionParams();
    if ($rightFunctionParams) {
        $functionParams .= $rightFunctionParams;
    }
    else {
        return 0;
    }

    return $rightFunctionParams;
}

sub Arg {
    my ($class) = @_;
    my $arg = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $arg .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $arg;
}

sub CodeBlock {
    my ($class) = @_;
    my $codeBlock = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "{" ) {
        $codeBlock .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    my $blocks = $class->Blocks();
    if ($blocks) {
        $codeBlock .= $blocks;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "}" ) {
        $codeBlock .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $codeBlock;
}

sub Blocks {
    my ($class) = @_;
    my $blocks = "";

    my $block = $class->Block();
    if ($block) {
        $blocks .= $block;
    }
    else {
        return $blocks;
    }

    my $rightBlock = $class->Blocks();
    if ($rightBlock) {
        $blocks .= $rightBlock;
    }
    else {
        return 0;
    }

    return $blocks;
}

sub Block {
    my ($class) = @_;
    my $block = "";

    my $ifElse = $class->IfElse();
    if ($ifElse) {
        return $ifElse;
    }

    my $ifWhile = $class->While();
    if ($ifWhile) {
        return $ifWhile;
    }

    my $forEach = $class->ForEach();
    if ($forEach) {
        return $forEach;
    }

    my $for = $class->For();
    if ($for) {
        return $for;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    my $comment = $class->Comment();
    if ($comment) {
        return $comment;
    }

    my $statement = $class->Statement();
    if ($statement) {
        return $statement;
    }

    return 0;
}

sub EmbedBlock {
    my ($class) = @_;
    my $embedBlock = "";

    my $tokenEmbedBlock = $class->TokenEmbedBlock();
    if ($tokenEmbedBlock) {
        $embedBlock .= $tokenEmbedBlock;
    }
    else {
        return 0;
    }

    my $embedCodeBlock = $class->EmbedCodeBlock();
    if ($embedCodeBlock) {
        $embedBlock .= $embedCodeBlock;
    }
    else {
        return 0;
    }

    return $embedBlock;
}

sub EmbedCodeBlock {
    my ($class) = @_;
    my $embedCodeBlock = "";

    my $embedBegin = $class->EmbedBegin();
    if ($embedBegin) {
        $embedCodeBlock .= $embedBegin;
    }
    else {
        return 0;
    }

    my $embeddedCode = $class->EmbeddedCode();
    if ($embeddedCode) {
        $embedCodeBlock .= $embeddedCode;
    }
    else {
        return 0;
    }

    my $embedEnd = $class->EmbedEnd();
    if ($embedEnd) {
        $embedCodeBlock .= $embedEnd;
    }
    else {
        return 0;
    }

    return $embedCodeBlock;
}

sub EmbedBegin {
    my ($class) = @_;
    my $embedBegin = "";

    my $lParen = $class->LParen();
    if ($lParen) {
        $embedBegin .= $lParen;
    }
    else {
        return 0;
    }

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "?" ) {
        $embedBegin .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $embedBegin;
}

sub EmbedEnd {
    my ($class) = @_;
    my $embedEnd = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "?" ) {
        $embedEnd .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $embedEnd .= $rParen;
    }
    else {
        return 0;
    }

    return $embedEnd;
}

sub EmbeddedCode {
    my ($class) = @_;
    my $embeddedCode = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "EmbedBlock" ) {
        $embedEnd .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $embedEnd;
}

sub While {
    my ($class) = @_;
    my $while = "";

    my $tokenWhile = $class->TokenWhile();
    if ($tokenWhile) {
        $while .= $tokenWhile;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $while .= $lParen;
    }
    else {
        return 0;
    }

    my $boolExpression = $class->BoolExpression();
    if ($boolExpression) {
        $while .= $boolExpression;
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $while .= $rParen;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $while .= $codeBlock;
    }
    else {
        return 0;
    }

    return $while;
}

sub ForEach {
    my ($class) = @_;
    my $forEach = "";

    my $tokenForEach = $class->TokenForEach();
    if ($tokenForEach) {
        $forEach .= $tokenForEach;
    }
    else {
        return 0;
    }

    my $var = $class->Var();
    if ($var) {
        $forEach .= $var;
    }
    else {
        return 0;
    }

    my $forEachVariableName = $class->ForEachVariableName();
    if ($forEachVariableName) {
        $forEach .= $forEachVariableName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $forEach .= $lParen;
    }
    else {
        return 0;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        $forEach .= $variableName;
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $forEach .= $rParen;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $forEach .= $codeBlock;
    }
    else {
        return 0;
    }

    return $codeBlock;
}

sub ForEachVariableName {
    my ($class) = @_;
    my $forEachVariableName = "";

    my $variableName = $class->VariableName();
    if ($variableName) {
        $forEachVariableName .= $variableName;
    }
    else {
        return 0;
    }

    return $forEachVariableName;
}

sub For {
    my ($class) = @_;
    my $for = "";

    my $tokenFor = $class->TokenFor();
    if ($tokenFor) {
        $for .= $tokenFor;
    }
    else {
        return 0;
    }

    my $var = $class->Var();
    if ($var) {
        $for .= $var;
    }
    else {
        return 0;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        $for .= $variableName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $for .= $lParen;
    }
    else {
        return 0;
    }

    my $forRange = $class->ForRange();
    if ($forRange) {
        $for .= $forRange;
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $for .= $rParen;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $for .= $codeBlock;
    }
    else {
        return 0;
    }

    return $codeBlock;
}

sub ForRange {
    my ($class) = @_;
    my $forRange = "";

    my $lowerRange = $class->LowerRange();
    if ($lowerRange) {
        $forRange .= $lowerRange;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $forRange .= $dot;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $forRange .= $dot;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $forRange .= $dot;
    }
    else {
        return 0;
    }

    my $upperRange = $class->UpperRange();
    if ($upperRange) {
        $forRange .= $upperRange;
    }
    else {
        return 0;
    }

    return $forRange;
}

sub LowerRange {
    my ($class) = @_;

    my $number = $class->Number();
    if ($number) {
        return $number;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $classAccessor = $class->ClassAccessor();
    if ($classAccessor) {
        return $classAccessor;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $FunctionReturn = $class->FunctionReturn();
    if ($FunctionReturn) {
        return $FunctionReturn;
    }

    return 0;
}

sub UpperRange {
    my ($class) = @_;

    my $number = $class->Number();
    if ($number) {
        return $number;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $classAccessor = $class->ClassAccessor();
    if ($classAccessor) {
        return $classAccessor;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $FunctionReturn = $class->FunctionReturn();
    if ($FunctionReturn) {
        return $FunctionReturn;
    }

    return 0;
}

sub IfElse {
    my ($class) = @_;
    my $ifElse = "";

    my $if = $class->If();
    if ($if) {
        $ifElse .= $if;
    }
    else {
        return 0;
    }

    my $elsIf = $class->ElsIf();
    if ($elsIf) {
        $ifElse .= $elsIf;
    }

    my $else = $class->Else();
    if ($else) {
        $ifElse .= $else;
    }

    return $ifElse;
}

sub If {
    my ($class) = @_;
    my $if = "";

    my $tokenIf = $class->TokenIf();
    if ($tokenIf) {
        $if .= $tokenIf;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $if .= $lParen;
    }
    else {
        return 0;
    }

    my $boolExpression = $class->BoolExpression();
    if ($boolExpression) {
        $if .= $boolExpression;
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $if .= $rParen;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $if .= $codeBlock;
    }
    else {
        return 0;
    }

    return $if;
}

sub BoolExpression {
    my ($class) = @_;
    my $boolExpression = "";

    my $booleanExpression = $class->BooleanExpression();
    if ($booleanExpression) {
        $boolExpression .= $codeBlock;
    }
    else {
        return 0;
    }

    my $booleanOperator = $class->BooleanOperator();
    if ($booleanOperator) {
        $boolExpression .= $booleanOperator;
    }
    else {
        return $boolExpression;
    }

    my $rightBooleanExpression = $class->BoolExpression();
    if ($rightBooleanExpression) {
        $boolExpression .= $rightBooleanExpression;
    }
    else {
        return 0;
    }

    return $boolExpression;
}

sub BooleanExpression {
    my ($class) = @_;
    my $booleanExpression = "";

    my $boolOperands = $class->BoolOperands();
    if ($boolOperands) {
        $booleanExpression .= $boolOperands;
    }
    else {
        return 0;
    }

    my $boolOperatorExpression = $class->BoolOperatorExpression();
    if ($boolOperatorExpression) {
        $booleanExpression .= $boolOperatorExpression;
    }

    return $booleanExpression;
}

sub BoolOperatorExpression {
    my ($class) = @_;
    my $boolOperatorExpression = "";

    my $boolOperator = $class->BoolOperator();
    if ($boolOperator) {
        $boolOperatorExpression .= $boolOperator;
    }
    else {
        return 0;
    }

    my $boolOperands = $class->BoolOperands();
    if ($boolOperands) {
        $boolOperatorExpression .= $boolOperands;
    }
    else {
        return 0;
    }

    return $boolOperatorExpression;
}

sub BoolOperands {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $string = $class->String();
    if ($string) {
        return $string;
    }

    my $scalarVariable = $class->ScalarVariable();
    if ($scalarVariable) {
        return $scalarVariable;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $classAccessor = $class->ClassAccessor();
    if ($classAccessor) {
        return $classAccessor;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub BoolOperator {
    my ($class) = @_;

    my $greaterThan = $class->GreaterThan();
    if ($greaterThan) {
        return $greaterThan;
    }

    my $lessThan = $class->LessThan();
    if ($lessThan) {
        return $lessThan;
    }

    my $equals = $class->Equals();
    if ($equals) {
        return $equals;
    }

    my $greaterThanEquals = $class->GreaterThanEquals();
    if ($greaterThanEquals) {
        return $greaterThanEquals;
    }

    my $lessThanEquals = $class->LessThanEquals();
    if ($lessThanEquals) {
        return $lessThanEquals;
    }

    my $stringEquals = $class->StringEquals();
    if ($stringEquals) {
        return $stringEquals;
    }

    my $stringNotEquals = $class->StringNotEquals();
    if ($stringNotEquals) {
        return $stringNotEquals;
    }

    my $notEquals = $class->NotEqulas();
    if ($notEquals) {
        return $notEquals;
    }

    my $logicalAnd = $class->LogicalAnd();
    if ($logicalAnd) {
        return $logicalAnd;
    }

    my $logicalOr = $class->LogicalOr();
    if ($logicalOr) {
        return $logicalOr;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub ElsIf {
    my ($class) = @_;
    my $elsIf = "";

    my $elsIfChain = $class->ElsIfChain();
    if ($elsIfChain) {
        $elsIf .= $elsIfChain;
    }
    else {
        return $elsIf;
    }

    my $rightElsIf = $class->ElsIf();
    if ($rightElsIf) {
        $elsIf .= $rightElsIf;
    }
    else {
        return 0;
    }

    return $elsIf;
}

sub ElsIfChain {
    my ($class) = @_;
    my $elsIfChain = "";

    my $tokenIf = $class->TokenIf();
    if ($tokenIf) {
        $elsIfChain .= $tokenIf;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $elsIfChain .= $lParen;
    }
    else {
        return 0;
    }

    my $boolExpression = $class->BoolExpression();
    if ($boolExpression) {
        $elsIfChain .= $boolExpression;
    }
    else {
        return 0;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $elsIfChain .= $rParen;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $elsIfChain .= $codeBlock;
    }
    else {
        return 0;
    }

    return $elsIfChain;
}

sub Else {
    my ($class) = @_;
    my $else = "";

    my $tokenElse = $class->TokenElse();
    if ($tokenElse) {
        $else .= $tokenElse;
    }
    else {
        return 0;
    }

    my $codeBlock = $class->CodeBlock();
    if ($codeBlock) {
        $else .= $codeBlock;
    }
    else {
        return 0;
    }

    return $else;
}

sub Statement {
    my ($class) = @_;
    my $statement = "";

    my $variableDeclaration = $class->VariableDeclaration();
    if ($variableDeclaration) {
        return $variableDeclaration;
    }

    my $functionCall = $class->FunctionCall();
    if ($functionCall) {
        return $functionCall;
    }

    my $calssFunctionCall = $class->ClassFunctionCall();
    if ($classFunctionCall) {
        return $classFunctionCall;
    }

    my $objectCall = $class->ObjectCall();
    if ($objectCall) {
        return $objectCall;
    }

    my $assignment = $class->Assignment();
    if ($assignment) {
        return $assignment;
    }

    my $return = $class->Return();
    if ($return) {
        return $return;
    }

    my $last = $class->Last();
    if ($last) {
        return $last;
    }

    my $next = $class->Next();
    if ($next) {
        return $next;
    }

    return 0;
}

sub ClassFunctionCall {
    my ($class) = @_;
    my $classFunctionCall = "";

    my $tokenClass = $class->TokenClass();
    if ($tokenClass) {
        return $tokenClass;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        return $dot;
    }
    else {
        return 0;
    }

    my $functionName = $class->FunctionName();
    if ($funcitonName) {
        return $functionName;
    }
    else {
        return 0;
    }
}

sub ObjectCall {
    my ($class) = @_;
    my $objectCall = "";

    my $objectFunctionCall = $class->ObjectFunctionCall();
    if ($objectFunctionCall) {
        $objectCall .= $objectFunctionCall;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $objectCall .= $semiColon;
    }
    else {
        return 0;
    }

    return $objectCall;
}

sub variableDeclaration {
    my ($class) = @_;

    my $arrayDeclaration = $class->ArrayDeclaration();
    if ($arrayDeclaration) {
        return $arrayDeclaration;
    }

    my $hashDeclaration = $class->HashDeclaration();
    if ($hashDeclaration) {
        return $hashDeclaration;
    }

    my $scalarDeclaration = $class->ScalarDeclaration();
    if ($scalarDeclaration) {
        return $scalarDeclaration;
    }

    return 0;
}

sub scalarDeclaration {
    my ($class) = @_;
    my $scalarDeclaration = "";

    my $var = $class->Var();
    if ($var) {
        $scalarDeclaration .= $var;
    }
    else {
        return 0;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        $scalarDeclaration .= $variableName;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $scalarDeclaration .= $equal;
    }
    else {
        return 0;
    }

    my $value = $class->Value();
    if ($value) {
        $scalarDeclaration .= $value;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $scalarDeclaration .= $semiColon;
    }
    else {
        return 0;
    }

    return $scalarDeclaration;
}

sub Var {
    my ($class) = @_;
    my $var = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "var" ) {
        $var .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $var;
}

sub VariableName {
    my ($class) = @_;
    my $variableName = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "symbol" ) {
        $variableName .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $variableName;
}

sub Value {
    my ($class) = @_;
    my $value = "";

    my $rhs = $class->RHS();
    if ($rhs) {
        $value .= $rhs;
    }
    else {
        return 0;
    }

    return $value;
}

sub Number {
    my ($class) = @_;
    my $number = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Number" ) {
        $number .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $number;
}

sub RealNumber {
    my ($class) = @_;
    my $realNumber = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "RealNumber" ) {
        $realNumber .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $realNumber;
}

sub String {
    my ($class) = @_;
    my $string = "";

    my $lQuote = $class->LQuote();
    if ($lQuote) {
        $string .= $lQuote;
    }
    else {
        return 0;
    }

    my $stringValue = $class->StringValue();
    if ($stringValue) {
        $string .= $stringValue;
    }
    else {
        return 0;
    }

    my $rQuote = $class->RQuote();
    if ($rQuote) {
        $string .= $rQuote;
    }
    else {
        return 0;
    }

    return $string;
}

sub LQuote {
    my ($class) = @_;
    my $lQuote = "";

    my $quote = $class->Quote();
    if ($quote) {
        $lQuote .= $quote;
    }
    else {
        return 0;
    }

    return $lQuote;
}

sub RQuote {
    my ($class) = @_;
    my $rQuote = "";

    my $quote = $class->Quote();
    if ($quote) {
        $rQuote .= $quote;
    }
    else {
        return 0;
    }

    return $rQuote;
}

sub StringValue {
    my ($class) = @_;
    my $stringValue;

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "String" ) {
        $stringValue .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $stringValue;
}

sub ArrayDeclaration {
    my ($class) = @_;
    my $arrayDeclaration = "";

    my $var = $class->Var();
    if ($var) {
        $arrayDeclaration .= $var;
    }
    else {
        return 0;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        $arrayDeclaration .= $variableName;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $arrayDeclaration .= $equal;
    }
    else {
        return 0;
    }

    my $arrayList = $class->ArrayList();
    if ($arrayList) {
        $arrayDeclaration .= $arrayList;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $arrayDeclaration .= $semiColon;
    }
    else {
        return 0;
    }

    return $arrayDeclaration;
}

sub ArrayList {
    my ($class) = @_;
    my $arrayList = "";

    my $lBracket = $class->LBracket();
    if ($lBracket) {
        $arrayList .= $lBracket;
    }
    else {
        return 0;
    }

    my $listElements = $class->ListElements();
    if ($semiColon) {
        $arrayList .= $semiColon;
    }
    else {
        return 0;
    }

    my $rBracket = $class->RBracket();
    if ($rBracket) {
        $arrayList .= $rBracket;
    }
    else {
        return 0;
    }

    return $rBracket;
}

sub ListElements {
    my ($class) = @_;
    my $listElements = "";

    my $listElement = $class->ListElement();
    if ($listElement) {
        my $listElements .= $listElement;
    }

    my $comma = $class->Comma();
    if ($comma) {
        my $listElements .= $comma;
    }
    else {
        return $listElements;
    }

    my $rightListElements = $class->ListElements();
    if ($rightListElements) {
        $listElements .= $rightListElements;
    }

    return $listElements;
}

sub ListElement {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $string = $class->String();
    if ($string) {
        return $string;
    }

    my $classfunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $arrayList = $class->ArrayList();
    if ($arrayList) {
        return $arrayList;
    }

    my $hashRef = $class->HashRef();
    if ($hashRef) {
        return $hashRef;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub HashDeclaration {
    my ($class) = @_;
    my $hashDeclaration = "";

    my $var = $class->Var();
    if ($var) {
        $hashDeclaration .= $var;
    }
    else {
        return 0;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        $hashDeclaration .= $variableName;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $hashDeclaration .= $equal;
    }
    else {
        return 0;
    }

    my $hashRef = $class->HashRef();
    if ($hashRef) {
        $hashDeclaration .= $hashRef;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $hashDeclaration .= $semiColon;
    }
    else {
        return 0;
    }

    return $hashDeclaration;
}

sub HashRef {
    my ($class) = @_;
    my $hashRef = "";

    my $lBrace = $class->LBrace();
    if ($lBrace) {
        my $hashRef .= $lBrace;
    }
    else {
        return 0;
    }

    my $keyValuePairs = $class->KeyValuePairs();
    if ($keyValuePairs) {
        my $hashRef .= $keyValuePairs;
    }
    else {
        return 0;
    }

    my $rBrace = $class->RBrace();
    if ($rBrace) {
        my $hashRef .= $rBrace;
    }
    else {
        return 0;
    }

    return $hashRef;
}

sub KeyValuePairs {
    my ($class) = @_;
    my $keyValuePairs = "";

    my $keyValue = $class->KeyValue();
    if ($keyValue) {
        $keyValuePairs .= $keyValue;
    }
    else {
        return 0;
    }

    my $comma = $class->Comma();
    if ($comma) {
        $keyValuePairs .= $comma;
    }
    else {
        return $keyValuePairs;
    }

    my $rightKeyValuePairs = $class->KeyValuePairs();
    if ($rightKeyValuePairs) {
        $keyValuePairs .= $rightKeyValuePairs;
    }
    else {
        return 0;
    }

    return $keyValuePairs;
}

sub KeyValue {
    my ($class) = @_;
    my $keyValue = "";

    my $pairKey = $class->PairKey();
    if ($pairKey) {
        $keyValue .= $pairKey;
    }
    else {
        return 0;
    }

    my $colon = $class->Colon();
    if ($colon) {
        $keyValue .= $colon;
    }
    else {
        return 0;
    }

    my $pairValue = $class->PairValue();
    if ($pairValue) {
        $keyValue .= $pairValue;
    }
    else {
        return 0;
    }

    return $pairValue;
}

sub PairKey {
    my ($class) = @_;

    my $number = $class->Number();
    if ($number) {
        return $number;
    }

    my $stirng = $class->String();
    if ($string) {
        return $string;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub PairValue {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $stirng = $class->String();
    if ($string) {
        return $string;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $arrayList = $class->ArrayList();
    if ($arrayList) {
        return $arrayList;
    }

    my $hashRef = $class->HashRef();
    if ($hashRef) {
        return $hashRef;
    }

    return 0;
}

sub FunctionCall {
    my ($class) = @_;
    my $funcitonCall;

    my $functionName = $class->FunctionName();
    if ($funcitonName) {
        $functionCall .= $funcitonName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $functionCall .= $lParen;
    }
    else {
        return 0;
    }

    my $parameters = $class->Parameters();
    if ($parameters) {
        $functionCall .= $parameters;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $functionCall .= $rParen;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $functionCall .= $semiColon;
    }
    else {
        return 0;
    }

    return $functionCall;
}

sub Parameters {
    my ($class) = @_;
    my $parameters;

    my $param .= $class->Param();
    if ($param) {
        $parameters .= $param;
    }
    else {
        return 0;
    }

    my $comma .= $class->Comma();
    if ($comma) {
        $parameters .= $comma;
    }
    else {
        return $parameters;
    }

    my $rightParameters = $class->Parameters();
    if ($rightParameters) {
        $parameters .= $rightParameters;
    }
    else {
        return 0;
    }

    return $parameters;
}

sub Param {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $stirng = $class->String();
    if ($string) {
        return $string;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $variableName = $class->VariableName();
    if ($variableName) {
        return $variableName;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $arrayList = $class->ArrayList();
    if ($arrayList) {
        return $arrayList;
    }

    my $hashRef = $class->HashRef();
    if ($hashRef) {
        return $hashRef;
    }

    return 0;
}

sub Assignment {
    my ($class) = @_;

    my $scalarAssignment = $class->ScalarAssignment();
    if ($scalarAssignment) {
        return $scalarAssignment;
    }

    my $arrayAssignment = $class->ArrayAssignment();
    if ($arrayAssignment) {
        return $arrayAssignment;
    }

    my $hashAssignment = $class->HashAssignment();
    if ($hashAssignment) {
        return $hashAssignment;
    }

    my $accessorAssignment = $class->AccessorAssignment();
    if ($accessorAssignment) {
        return $accessorAssignment;
    }

    return 0;
}

sub ScalarAssignment {
    my ($class) = @_;
    my $scalarAssignment = "";

    my $scalarVariable = $class->ScalarVariable();
    if ($scalarVariable) {
        $scalarAssignment .= $scalarVariable;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $scalarAssignment .= $equal;
    }
    else {
        return 0;
    }

    my $rhs = $class->RHS();
    if ($rhs) {
        $scalarAssignment .= $rhs;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $scalarAssignment .= $semiColon;
    }
    else {
        return 0;
    }

    return $scalarAssignment;
}

sub ScalarVariable {
    my ($class) = @_;
    my $scalarVariable = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $scalarVariable .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $scalarVariable;
}

sub RHS {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $stirng = $class->String();
    if ($string) {
        return $string;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $arrayList = $class->ArrayList();
    if ($arrayList) {
        return $arrayList;
    }

    my $hashRef = $class->HashRef();
    if ($hashRef) {
        return $hashRef;
    }

    my $scalarVariable = $class->ScalarVariable();
    if ($scalarVariable) {
        return $scalarVariable;
    }

    my $calc = $class->Calc();
    if ($calc) {
        return $calc;
    }

    my $classAccessor = $class->classAccessor();
    if ($classAccessor) {
        return $classAccessor;
    }

    my $stdin = $class->STDIN();
    if ($stdin) {
        return $stdin;
    }

    my $objectFunctionCall = $class->ObjectFunctionCall();
    if ($objectFunctionCall) {
        return $objectFunctionCall;
    }

    return 0;
}

sub FunctionReturn {
    my ($class) = @_;
    my $functionReturn = "";

    my $functionName = $class->FunctionName();
    if ($functionName) {
        $functionReturn .= $functionName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $functionReturn .= $lParen;
    }
    else {
        return 0;
    }

    my $parameters = $class->Parameters();
    if ($parameters) {
        $functionReturn .= $parameters;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $functionReturn .= $rParen;
    }
    else {
        return 0;
    }

    return 0;
}

sub ArrayElement {
    my ($class) = @_;
    my $arrayElement = "";

    my $arrayName = $class->ArrayName();
    if ($arrayName) {
        $arrayElement .= $arrayName;
    }
    else {
        return 0;
    }

    while (1) {
        my $arrayAccess = $class->ArrayAccess();
        if ($arrayAccess) {
            $arrayElement .= $arrayAccess;
        }
        else {
            return $arrayElement;
        }
    }

    return $arrayElement;
}

sub ArrayAccess {
    my ($class) = @_;
    my $arrayAccess = "";

    my $lBracket = $class->LBracket();
    if ($lBracket) {
        $arrayAccess .= $lBracket;
    }
    else {
        return 0;
    }

    my $number = $class->Number();
    if ($number) {
        $arrayAccess .= $number;
    }
    else {
        return 0;
    }

    my $rBracket = $class->RBracket();
    if ($rBracket) {
        $arrayAccess .= $rBracket;
    }
    else {
        return 0;
    }

    return $arrayAccess;
}

sub ArrayName {
    my ($class) = @_;
    my $arrayName = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $arrayName .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $arrayName;
}

sub HashElement {
    my ($class) = @_;
    my $hashElement = "";

    my $hashName = $class->HashName();
    if ($hashName) {
        $hashElement .= $hashName;
    }
    else {
        return 0;
    }

    while (1) {
        my $hashAccess = $class->HashAccess();
        if ($hashAccess) {
            $hashElement .= $hashAccess;
        }
        else {
            return $hashElement;
        }
    }

    return $hashElement;
}

sub HashAccess {
    my ($class) = @_;
    my $hashAccess = "";

    my $lBrace = $class->LBrace();
    if ($lBrace) {
        $hashAccess .= $lBrace;
    }
    else {
        return 0;
    }

    my $hashKey = $class->HashKey();
    if ($hashKey) {
        $hashAccess .= $hashKey;
    }
    else {
        return 0;
    }

    my $rBrace = $class->RBrace();
    if ($rBrace) {
        $hashAccess .= $rBrace;
    }
    else {
        return 0;
    }

    return $hashAccess;
}

sub HashName {
    my ($class) = @_;
    my $hashName = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $hashName .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $hashName;
}

sub HashKey {
    my ($class) = @_;

    my $hashKeyString = $class->HashKeyString();
    if ($hashKeyString) {
        return $hashKeyString;
    }

    my $hashKeyNumber = $class->HashKeyNumber();
    if ($hashKeyNumber) {
        return $hashKeyNumber;
    }

    return 0;
}

sub HashKeyString {
    my ($class) = @_;
    my $hashKeyString = "";

    my $lQuote = $class->LQuote();
    if ($lQuote) {
        $hashKeyString .= $lQuote;
    }
    else {
        return 0;
    }

    my $hashKeyStringValue = $class->HashKeyStringValue();
    if ($hashKeyStringValue) {
        $hashKeyString .= $hashKeyStringValue;
    }
    else {
        return 0;
    }

    my $rQuote = $class->RQuote();
    if ($rQuote) {
        $hashKeyString .= $rQuote;
    }
    else {
        return 0;
    }

    return $hashKeyString;
}

sub HashKeyStringValue {
    my ($class) = @_;
    my $hashKeyStringValue = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $hashKeyStringValue .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $hashKeyStringValue;
}

sub HashKeyNumber {
    my ($class) = @_;
    my $hashKeyNumber = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"type"} eq "Symbol" ) {
        $hashKeyNumber .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $hashKeyNumber;
}

sub STDIN {
    my ($class) = @_;
    my $stdin = "";

    my $lessThan = $class->LessThan();
    if ($lessThan) {
        $stdin .= $lessThan;
    }
    else {
        return 0;
    }

    my $tokenStdin = $class->TokenSTDIN();
    if ($tokenStdin) {
        $stdin .= $tokenStdin;
    }
    else {
        return 0;
    }

    my $greaterThan = $class->GreaterThan();
    if ($greaterThan) {
        $stdin .= $greaterThan;
    }
    else {
        return 0;
    }

    return $stdin;
}

sub AccessorAssignment {
    my ($class) = @_;
    my $accessorAssignment = "";

    my $tokenClass = $class->TokenClass();
    if ($tokenClass) {
        $accessorAssignment .= $tokenClass;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $accessorAssignment .= $dot;
    }
    else {
        return 0;
    }

    my $hashKeyStringValue = $class->HashKeyStringValue();
    if ($hashKeyStringValue) {
        $accessorAssignment .= $hashKeyStringValue;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $accessorAssignment .= $equal;
    }
    else {
        return 0;
    }

    my $rhs = $class->RHS();
    if ($rhs) {
        $accessorAssignment .= $rhs;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $accessorAssignment .= $semiColon;
    }
    else {
        return 0;
    }

    return $accessorAssignment;
}

sub ClassAccessor {
    my ($class) = @_;
    my $classAccessor = "";

    my $tokenClass = $class->TokenClass();
    if ($tokenClass) {
        $classAccessor .= $tokenClass;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $classAccessor .= $dot;
    }
    else {
        return 0;
    }

    my $hashKeyStringValue = $class->HashKeyStringValue();
    if ($hashKeyStringValue) {
        $classAccessor .= $hashKeyStringValue;
    }
    else {
        return 0;
    }

    return $classAccessor;
}

sub ClassFunctionReturn {
    my ($class) = @_;
    my $classFunctionReturn = "";

    my $tokenClass = $class->TokenClass();
    if ($tokenClass) {
        $classFunctionReturn .= $tokenClass;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $classFunctionReturn .= $dot;
    }
    else {
        return 0;
    }

    my $functionName = $class->FunctionName();
    if ($functionName) {
        $classFunctionReturn .= $functionName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $classFunctionReturn .= $lParen;
    }
    else {
        return 0;
    }

    my $parameters = $class->Parameters();
    if ($parameters) {
        $classFunctionReturn .= $parameters;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $classFunctionReturn .= $rParen;
    }
    else {
        return 0;
    }

    return $classFunctionReturn;
}

class ArrayAssignment {
    my ($class) = @_;
    my $arrayAssignment = "";

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        $arrayAssignment .= $arrayElement;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $arrayAssignment .= $equal;
    }
    else {
        return 0;
    }

    my $rhs = $class->RHS();
    if ($rhs) {
        $arrayAssignment .= $rhs;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $arrayAssignment .= $semiColon;
    }
    else {
        return 0;
    }

    return $arrayAssignment;
}

sub HashAssignment {
    my ($class) = @_;
    my $hashAssignment = "";

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        $hashAssignment .= $hashElement;
    }
    else {
        return 0;
    }

    my $equal = $class->Equal();
    if ($equal) {
        $hashAssignment .= $equal;
    }
    else {
        return 0;
    }

    my $rhs = $class->RHS();
    if ($rhs) {
        $hashAssignment .= $rhs;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $hashAssignment .= $semiColon;
    }
    else {
        return 0;
    }

    return $hashAssignment;
}

sub Calc {
    my ($class) = @_;
    my $calc = "";

    my $calcExpression = $class->CalcExpression();
    if ($calcExpression) {
        $calc .= $calcExpression;
    }
    else {
        return 0;
    }

    return $calc .;
}

sub CalcExpression {
    my ($class) = @_;
    my $calcExpression = "";

    my $calcOperands = $class->CalcOperands();
    if ($calcOperands) {
        $calcExpression .= $calcOperands;
    }
    else {
        return 0;
    }

    my $calcOperator = $class->CalcOperator();
    if ($calcOperator) {
        $calcExpression .= $calcOperator;
    }
    else {
        return $calcExpression;
    }

    my $rightCalcExpression = $class->CalcExpression();
    if ($rightCalcExpression) {
        $calcExpression .= $rightCalcExpression;
    }
    else {
        return 0;
    }

    return $calcExpression;
}

sub CalcOperands {
    my ($class) = @_;

    my $realNumber = $class->RealNumber();
    if ($realNumber) {
        return $realNumber;
    }

    my $classFunctionReturn = $class->ClassFunctionReturn();
    if ($classFunctionReturn) {
        return $classFunctionReturn;
    }

    my $functionReturn = $class->FunctionReturn();
    if ($functionReturn) {
        return $functionReturn;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    my $arrayElement = $class->ArrayElement();
    if ($arrayElement) {
        return $arrayElement;
    }

    my $hashElement = $class->HashElement();
    if ($hashElement) {
        return $hashElement;
    }

    my $scalarVariable = $class->ScalarVariable();
    if ($scalarVariable) {
        return $scalarVariable;
    }

    my $classAccessor = $class->classAccessor();
    if ($classAccessor) {
        return $classAccessor;
    }

    my $objectFunctionCall = $class->ObjectFunctionCall();
    if ($objectFunctionCall) {
        return $objectFunctionCall;
    }

    return 0;
}

sub CalcOperator {
    my ($class) = @_;

    my $plus = $class->Plus();
    if ($plus) {
        return $plus;
    }

    my $minus = $class->Minus();
    if ($minus) {
        return $minus;
    }

    my $multiply = $class->Multiply();
    if ($multiply) {
        return $multiply;
    }

    my $divide = $class->Divide();
    if ($divide) {
        return $divide;
    }

    my $modulus = $class->Modulus();
    if ($modulus) {
        return $modulus;
    }

    my $exponent = $class->Exponent();
    if ($exponent) {
        return $exponent;
    }

    my $embedBlock = $class->EmbedBlock();
    if ($embedBlock) {
        return $embedBlock;
    }

    return 0;
}

sub Return {
    my ($class) = @_;
    my $return = "";

    my $tokenReturn = $class->TokenReturn();
    if ($tokenReturn) {
        $return .= $tokenReturn;
    }
    else {
        return 0;
    }

    my $rhs = $class->RHS();
    if ($rhs) {
        $return .= $rhs;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $return .= $semiColon ();
    }
    else {
        return 0;
    }

    return $return;
}

sub Last {
    my ($class) = @_;
    my $last = "";

    my $tokenLast = $class->TokenLast();
    if ($tokenLast) {
        $last .= $tokenLast;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $last .= $semiColon ();
    }
    else {
        return 0;
    }

    return $last;
}

sub Next {
    my ($class) = @_;
    my $next = "";

    my $tokenNext = $class->TokenNext();
    if ($tokenNext) {
        $next .= $tokenNext;
    }
    else {
        return 0;
    }

    my $semiColon = $class->SemiColon();
    if ($semiColon) {
        $next .= $semiColon ();
    }
    else {
        return 0;
    }

    return $next;
}

sub ObjectFunctionCall {
    my ($class) = @_;
    my $objectFunctionCall = "";

    my $object = $class->Object();
    if ($object) {
        $objectFunctionCall .= $object;
    }
    else {
        return 0;
    }

    my $dot = $class->Dot();
    if ($dot) {
        $objectFunctionCall .= $dot;
    }
    else {
        return 0;
    }

    my $functionName = $class->FunctionName();
    if ($functionName) {
        $objectFunctionCall .= $functionName;
    }
    else {
        return 0;
    }

    my $lParen = $class->LParen();
    if ($lParen) {
        $objectFunctionCall .= $lParen;
    }
    else {
        return 0;
    }

    my $parameters = $class->Parameters();
    if ($dot) {
        $objectFunctionCall .= $parameters;
    }

    my $rParen = $class->RParen();
    if ($rParen) {
        $objectFunctionCall .= $rParen;
    }
    else {
        return 0;
    }

    return $objectFunctionCall;
}

sub TokenReturn {
    my ($class) = @_;
    my $tokenReturn = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "return" ) {
        $tokenReturn .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenReturn;
}

sub TokenNext {
    my ($class) = @_;
    my $tokenNext = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "next" ) {
        $tokenNext .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenNext;
}

sub TokenLast {
    my ($class) = @_;
    my $tokenLast = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "last" ) {
        $tokenNext .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenNext;
}

sub TokenElse {
    my ($class) = @_;
    my $tokenElse = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "else" ) {
        $tokenElse .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenElse;
}

sub TokenElsIf {
    my ($class) = @_;
    my $tokenElseIf = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "elsif" ) {
        $tokenElseIf .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenElseIf;
}

sub TokenIf {
    my ($class) = @_;
    my $if = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "if" ) {
        $if .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $if;
}

sub TokenFor {
    my ($class) = @_;
    my $for = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "for" ) {
        $for .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $for;
}

sub TokenForEach {
    my ($class) = @_;
    my $forEach = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "foreach" ) {
        $forEach .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $forEach;
}

sub TokenWhile {
    my ($class) = @_;
    my $tokenWhile = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "while" ) {
        $tokenWhile .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenWhile;
}

sub TokenFunction {
    my ($class) = @_;
    my $tokenFunction = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "function" ) {
        $tokenFunction .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenFunction;
}

sub TokenParent {
    my ($class) = @_;
    my $tokenParent = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "parent" ) {
        $tokenParent .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenParent;
}

sub TokenClass {
    my ($class) = @_;
    my $tokenClass = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "class" ) {
        $tokenClass .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenClass;
}

sub TokenEmbedBlock {
    my ($class) = @_;
    my $tokenEmbedBlock = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "embed" ) {
        $tokenEmbedBlock .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenEmbedBlock;
}

sub TokenSTDIN {
    my ($class) = @_;
    my $tokenSTDIN = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "STDIN" ) {
        $tokenSTDIN .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $tokenSTDIN;
}

sub Modulus {
    my ($class) = @_;
    my $modulus = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "%" ) {
        $modulus .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $modulus;
}

sub Exponent {
    my ($class) = @_;
    my $exponent = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "**" ) {
        $exponent .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $exponent;
}

sub LogicalAnd {
    my ($class) = @_;
    my $logicalAnd = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "&&" ) {
        $logicalAnd .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $logicalAnd;
}

sub LogicalOr {
    my ($class) = @_;
    my $logicalOr = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "||" ) {
        $logicalOr .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $logicalOr;
}

sub NotEqulas {
    my ($class) = @_;
    my $notEquals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "!=" ) {
        $notEquals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $notEquals;
}

sub StringNotEquals {
    my ($class) = @_;
    my $stringNotEquals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "ne" ) {
        $stingNotEquals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $stringNotEquals;
}

sub StringEquals {
    my ($class) = @_;
    my $stringEquals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "eq" ) {
        $stingEquals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $stringEquals;
}

sub LessThanEquals {
    my ($class) = @_;
    my $lessThanEquals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "<=" ) {
        $lessThanEquals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $lessThanEquals;
}

sub GreaterThanEquals {
    my ($class) = @_;
    my $greaterThanEquals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ">=" ) {
        $greaterThanEquals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $greaterThanEquals;
}

sub GreaterThan {
    my ($class) = @_;
    my $greaterThan = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ">" ) {
        $greaterThan .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $greaterThan;
}

sub LessThan {
    my ($class) = @_;
    my $lessThan = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "<" ) {
        $lessThan .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $lessThan;
}

sub Equals {
    my ($class) = @_;
    my $equals = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "==" ) {
        $equals .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $equals;
}

sub Plus {
    my ($class) = @_;
    my $plus = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "+" ) {
        $plus .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $plus;
}

sub Minus {
    my ($class) = @_;
    my $minus = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "-" ) {
        $minus .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $minus;
}

sub Multiply {
    my ($class) = @_;
    my $multiply = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "*" ) {
        $multiply .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $multiply;
}

sub Divide {
    my ($class) = @_;
    my $divide = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "/" ) {
        $divide .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $divide;
}

sub Quote {
    my ($class) = @_;
    my $quote = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq '"' ) {
        $quote .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $quote;
}

sub SemiColon {
    my ($class) = @_;
    my $semiColon = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ";" ) {
        $semiColon .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $semiColon;
}

sub SemiColon {
    my ($class) = @_;
    my $colon = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ":" ) {
        $colon .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $colon;
}

sub Dot {
    my ($class) = @_;
    my $dot = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "." ) {
        $dot .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $dot;
}

sub Equal {
    my ($class) = @_;
    my $equal = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "=" ) {
        $equal .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $equal;
}

sub Comma {
    my ($class) = @_;
    my $comma = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "," ) {
        $comma .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $comma;
}

sub LParen {
    my ($class) = @_;
    my $lParen = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "(" ) {
        $lParen .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $lParen;
}

sub RParen {
    my ($class) = @_;
    my $rParen = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq ")" ) {
        $rParen .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $rParen;
}

sub LBrace {
    my ($class) = @_;
    my $lBrace = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "{" ) {
        $lBrace .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $lBrace;
}

sub RBrace {
    my ($class) = @_;
    my $rBrace = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "}" ) {
        $rBrace .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $rBrace;
}

sub LBracket {
    my ($class) = @_;
    my $lBracket = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "[" ) {
        $lBracket .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $lBracket;
}

sub RBracket {
    my ($class) = @_;
    my $rBracket = "";

    my $currentToken = $class->getToken();
    if ( $currentToken->{"value"} eq "]" ) {
        $rBracket .= $currentToken->{"value"};
    }
    else {
        return 0;
    }

    return $rBracket;
}

1;

package Lang::HL::Syntax;

use strict;
use warnings;
use utf8;

our $VERSION = '0.07';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub syntax {
    my ( $class, $program ) = @_;

    $program =~ s/[\t\r\n\f]+//g;

    my @tokens = $class->lexer($program);
    my $code   = $class->parse( \@tokens );
    return $code;
}

1;

__END__

=head1 NAME

Lang::HL::Syntax

=head1 SYNOPSIS

	$> hle <directory>

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Rajkumar Reddy. All rights reserved.


=cut
