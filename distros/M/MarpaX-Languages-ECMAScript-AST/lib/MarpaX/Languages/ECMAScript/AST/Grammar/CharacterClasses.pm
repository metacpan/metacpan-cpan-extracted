use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses;
use Exporter 'import';
use Encode qw/decode/;

# ABSTRACT: ECMAScript, character classes

our $VERSION = '0.020'; # VERSION


our @EXPORT_OK = qw/
BOM
BS
CR
FF
Isb
IsBackslash
IsBOM
IsCaret
IsCR
IsDecimalDigit
IsDollar
IsDot
IsDquote
IseOrE
Ise
IsE
IsEight
IsEscapeCharacter
IsExponentIndicator
Isf
IsFF
IsHexDigit
IsIdentityEscape
IsLbracket
IsLcurly
IsLF
IsLineTerminator
IsLparen
IsLS
IsMinus
Isn
IsNBSP
IsNine
IsNonZeroDigit
IsNULL
IsOctalDigit
IsPatternCharacter
IsPipe
IsPlus
IsPS
IsQuestion_Mark
Isr
IsRbracket
IsRcurly
IsRegularExpressionNonTerminator
IsRegularExpressionNonTerminatorButNotOneOfBackslashOrSlashOrLbracket
IsRegularExpressionNonTerminatorButNotOneOfRbracketOrBackslash
IsRegularExpressionNonTerminatorButNotOneOfStarOrBackslashOrSlashOrLbracket
IsRparen
IsSingleEscapeCharacter
IsSlash
IsSourceCharacter
IsSourceCharacterButNotLineTerminator
IsSourceCharacterButNotOneOfBackslashOrRbracketOrMinus
IsSourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator
IsSourceCharacterButNotOneOfDquoteOrBackslashOrU0000ThroughU001F
IsSourceCharacterButNotOneOfEscapeCharacterOrLineTerminator
IsSourceCharacterButNotOneOfSlashOrStar
IsSourceCharacterButNotOneOfSlashOrStarOrLineTerminator
IsSourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator
IsSourceCharacterButNotSlash
IsSourceCharacterButNotStar
IsSourceCharacterButNotStarOrLineTerminator
IsSP
IsSquote
IsStar
Ist
IsTAB
Isu
IsU0000ThroughU001F
IsUnderscore
IsUnicodeCombiningMark
IsUnicodeConnectorPunctuation
IsUnicodeDigit
IsUnicodeLetter
IsUSP
Isv
IsVT
IsWhiteSpace
Isx
IsZero
IsZeroToThree
IsFourToSeven
IsZWJ
IsZWNJ
LineTerminator
LF
LS
NBSP
NULL
PS
SP
TAB
USP
VT
WhiteSpace
/;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

our $STAR            = sprintf('%x', ord('*'));
our $SLASH           = sprintf('%x', ord('/'));
our $BACKSLASH       = sprintf('%x', ord('\\'));
our $DQUOTE          = sprintf('%x', ord('"'));
our $SQUOTE          = sprintf('%x', ord("'"));
our $a               = sprintf('%x', ord('a'));
our $b               = sprintf('%x', ord('b'));
our $c               = sprintf('%x', ord('c'));
our $d               = sprintf('%x', ord('d'));
our $e               = sprintf('%x', ord('e'));
our $f               = sprintf('%x', ord('f'));
our $n               = sprintf('%x', ord('n'));
our $r               = sprintf('%x', ord('r'));
our $t               = sprintf('%x', ord('t'));
our $u               = sprintf('%x', ord('u'));
our $v               = sprintf('%x', ord('v'));
our $x               = sprintf('%x', ord('x'));
our $A               = sprintf('%x', ord('A'));
our $B               = sprintf('%x', ord('B'));
our $C               = sprintf('%x', ord('C'));
our $D               = sprintf('%x', ord('D'));
our $E               = sprintf('%x', ord('E'));
our $F               = sprintf('%x', ord('F'));
our $LBRACKET        = sprintf('%x', ord('['));
our $RBRACKET        = sprintf('%x', ord(']'));
our $LPAREN          = sprintf('%x', ord('('));
our $RPAREN          = sprintf('%x', ord(')'));
our $LCURLY          = sprintf('%x', ord('{'));
our $RCURLY          = sprintf('%x', ord('}'));
our $CARET           = sprintf('%x', ord('^'));
our $DOLLAR          = sprintf('%x', ord('$'));
our $UNDERSCORE      = sprintf('%x', ord('_'));
our $DOT             = sprintf('%x', ord('.'));
our $PLUS            = sprintf('%x', ord('+'));
our $QUESTION_MARK   = sprintf('%x', ord('?'));
our $PIPE            = sprintf('%x', ord('|'));
our $MINUS           = sprintf('%x', ord('-'));
our $ZERO            = sprintf('%x', ord('0'));
our $ONE             = sprintf('%x', ord('1'));
our $TWO             = sprintf('%x', ord('2'));
our $THREE           = sprintf('%x', ord('3'));
our $FOUR            = sprintf('%x', ord('4'));
our $FIVE            = sprintf('%x', ord('5'));
our $SIX             = sprintf('%x', ord('6'));
our $SEVEN           = sprintf('%x', ord('7'));
our $EIGHT           = sprintf('%x', ord('8'));
our $NINE            = sprintf('%x', ord('9'));


sub IsWhiteSpace { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsTAB
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsVT
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsFF
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSP
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsNBSP
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBOM
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUSP
END
}


sub WhiteSpace { return [
		     @{TAB()},
		     @{VT()},
		     @{FF()},
		     @{SP()},
		     @{NBSP()},
		     @{BOM()},
		     @{USP()},
		     ];
}


sub IsSourceCharacter { return <<END;
+utf8::Any
END
}


sub IsZWNJ { return <<END;
200C
END
}


sub IsZWJ { return <<END;
200D
END
}


sub IsBOM { return <<END;
FEFF
END
}


sub BOM { return [ "\N{U+FEFF}" ] }


sub BS { return [ "\N{U+0008}" ] }


sub IsTAB { return <<END;
0009
END
}


sub TAB { return [ "\N{U+0009}" ] }


sub IsVT { return <<END;
000B
END
}


sub VT { return [ "\N{U+000B}" ] }


sub IsFF { return <<END;
000C
END
}


sub FF { return [ "\N{U+000C}" ] }


sub IsSP { return <<END;
0020
END
}


sub SP { return [ "\N{U+0020}" ] }


sub IsNBSP { return <<END;
00A0
END
}


sub NBSP { return [ "\N{U+00A0}" ] }


sub IsUSP { return <<END;
+utf8::Zs
END
}


our @USP = ();
{
    #
    # We do as "unichars". And hardcode restriction to 65535, i.e.
    # the maximum supported by ECMAScript
    #
    foreach (0..65535) {
        # gaggy UTF-16 surrogates are invalid UTF-8 code points
        next if ($_ >= 0xD800 && $_ <= 0xDFFF);

        # from utf8.c in perl src; must avoid fatals in 5.10
        next if ($_ >= 0xFDD0 && $_ <= 0xFDEF);

        next if (0xFFFE == ($_ & 0xFFFE)); # both FFFE and FFFF

        # see "Unicode non-character %s is illegal for interchange" in perldiag(1)
        $_ = do { no warnings "utf8"; chr($_) };

        # fixes "the Unicode bug"
        unless (utf8::is_utf8($_)) {
            $_ = decode("iso-8859-1", $_);
        }

	if ($_ =~ /\p{Zs}/) {
	    push(@USP, $_);
	}
    }
}

sub USP { return \@USP }


sub IsLF { return <<END;
000A
END
}


sub LF { return [ "\N{U+000A}" ]; }


sub IsCR { return <<END;
000D
END
}


sub CR { return [ "\N{U+000D}" ]; }


sub IsNULL { return <<END;
0000
END
}


sub NULL { return [ "\N{U+0000}" ]; }


sub IsLS { return <<END;
2028
END
}


sub LS { return [ "\N{U+2028}" ]; }


sub IsPS { return <<END;
2029
END
}


sub PS { return [ "\N{U+2029}" ]; }


sub IsSourceCharacterButNotStar { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
END
}


sub IsSourceCharacterButNotStarOrLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsSourceCharacterButNotOneOfDquoteOrBackslashOrU0000ThroughU001F { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDquote
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsU0000ThroughU001F
END
}


sub IsSourceCharacterButNotOneOfSlashOrStar { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSlash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
END
}


sub IsSourceCharacterButNotSlash { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSlash
END
}


sub IsSourceCharacterButNotOneOfSlashOrStarOrLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSlash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLF
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsCR
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLS
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsPS
END
}


sub LineTerminator { return
			 [
			  @{LF()},
			  @{CR()},
			  @{LS()},
			  @{PS()}
			 ]; }


sub IsSourceCharacterButNotLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsUnicodeLetter { return <<END;
+utf8::Lu
+utf8::Ll
+utf8::Lt
+utf8::Lm
+utf8::Lo
+utf8::Nl
END
}


sub IsUnicodeCombiningMark { return <<END;
+utf8::Mn
+utf8::Mc
END
}


sub IsUnicodeDigit { return <<END;
+utf8::Nd
END
}


sub IsUnicodeConnectorPunctuation { return <<END;
+utf8::Pc
END
}


sub IsU0000ThroughU001F { return <<END;
0000\t001F
END
}


sub IsSourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDquote
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsSourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSquote
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsSingleEscapeCharacter { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSquote
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDquote
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isb
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isf
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isn
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isr
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Ist
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isv
END
}

#
# Note: PosixDigit is a perl extension, changed to be coherent with RT #91120
#

sub IsDecimalDigit { return <<END;
$ZERO\t$NINE
END
}


sub IsOctalDigit { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDecimalDigit
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsEight
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsNine
END
}


sub IsNonZeroDigit { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDecimalDigit
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsZero
END
}


sub IsEscapeCharacter { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSingleEscapeCharacter
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDecimalDigit
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isx
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Isu
END
}


sub IsSourceCharacterButNotOneOfEscapeCharacterOrLineTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsEscapeCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsRegularExpressionNonTerminator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLineTerminator
END
}


sub IsRegularExpressionNonTerminatorButNotOneOfStarOrBackslashOrSlashOrLbracket { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRegularExpressionNonTerminator
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSlash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLbracket
END
}


sub IsRegularExpressionNonTerminatorButNotOneOfBackslashOrSlashOrLbracket { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRegularExpressionNonTerminator
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSlash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLbracket
END
}


sub IsRegularExpressionNonTerminatorButNotOneOfRbracketOrBackslash { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRegularExpressionNonTerminator
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRbracket
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
END
}

#
# Note: PosixXDigit is a perl extension, not available before perl-5.12.5 RT #91120
#

sub IsHexDigit { return <<END;
$ZERO\t$NINE
$A\t$F
$a\t$f
END
}


sub IsIdentityEscape { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUnicodeLetter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDollar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUnderscore
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUnicodeCombiningMark
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUnicodeDigit
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsUnicodeConnectorPunctuation
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsZWNJ
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsZWJ
END
}


sub IsExponentIndicator { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Ise
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsE
END
}


sub IsPatternCharacter { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRegularExpressionNonTerminator
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsCaret
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDollar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsDot
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsStar
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsPlus
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsQuestion_Mark
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLparen
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRparen
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLbracket
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRbracket
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsLcurly
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRcurly
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsPipe
END
}


sub IsSourceCharacterButNotOneOfBackslashOrRbracketOrMinus { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsSourceCharacter
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsBackslash
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsRbracket
-MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsMinus
END
}

# -------------------------------------------------------------------


sub Isx { return <<END;
$x
END
}


sub Isu { return <<END;
$u
END
}


sub IsUnderscore { return <<END;
$UNDERSCORE
END
}


sub Isv { return <<END;
$v
END
}


sub IsStar { return <<END;
$STAR
END
}


sub IsBackslash { return <<END;
$BACKSLASH
END
}


sub IsCaret { return <<END;
$CARET
END
}


sub IsDollar { return <<END;
$DOLLAR
END
}


sub IsDot { return <<END;
$DOT
END
}


sub IsLparen { return <<END;
$LPAREN
END
}


sub IsRparen { return <<END;
$RPAREN
END
}


sub IsLcurly { return <<END;
$LCURLY
END
}


sub IsRcurly { return <<END;
$RCURLY
END
}


sub IsQuestion_Mark { return <<END;
$QUESTION_MARK
END
}


sub IsPlus { return <<END;
$PLUS
END
}


sub IsMinus { return <<END;
$MINUS
END
}


sub IsSquote { return <<END;
$SQUOTE
END
}


sub IsDquote { return <<END;
$DQUOTE
END
}


sub IsPipe { return <<END;
$PIPE
END
}


sub IsSlash { return <<END;
$SLASH
END
}


sub IsLbracket { return <<END;
$LBRACKET
END
}


sub IsRbracket { return <<END;
$RBRACKET
END
}



sub Isb { return <<END;
$b
END
}


sub Isf { return <<END;
$f
END
}


sub Ise { return <<END;
$e
END
}


sub IsE { return <<END;
$E
END
}


sub IseOrE { return <<END;
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::Ise
+MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses::IsE
END
}


sub Isn { return <<END;
$n
END
}


sub Isr { return <<END;
$r
END
}


sub Ist { return <<END;
$t
END
}


sub IsZero { return <<END;
$ZERO
END
}


sub IsEight { return <<END;
$EIGHT
END
}


sub IsNine { return <<END;
$NINE
END
}


sub IsZeroToThree { return <<END;
$ZERO
$ONE
$TWO
$THREE
END
}


sub IsFourToSeven { return <<END;
$FOUR
$FIVE
$SIX
$SEVEN
END
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses - ECMAScript, character classes

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses;

=head2 IsWhiteSpace()

=head2 WhiteSpace()

Return an array reference of characters composing WhiteSpace

=head2 IsSourceCharacter()

=head2 IsZWNJ()

=head2 sub IsZWJ()

=head2 IsBOM()

=head2 BOM()

Return an array reference of characters composing BOM

=head2 BS()

Return an array reference of characters composing BS

=head2 IsTAB()

=head2 TAB()

Return an array reference of characters composing TAB

=head2 IsVT()

=head2 VT()

Return an array reference of characters composing VT

=head2 IsFF()

=head2 FF()

Return an array reference of characters composing FF

=head2 IsSP()

=head2 SP()

Return an array reference of characters composing SP

=head2 IsNBSP()

=head2 NBSP()

Return an array reference of characters composing NBSP

=head2 IsUSP()

=head2 USP()

Return an array reference of characters composing USP

=head2 IsLF()

=head2 LF()

Return an array reference of characters composing LF

=head2 IsCR()

=head2 CR()

Return an array reference of characters composing CR

=head2 IsNULL()

=head2 NULL()

Return an array reference of characters composing NULL

=head2 IsLS()

=head2 LS()

Return an array reference of characters composing LS

=head2 IsPS()

=head2 PS()

Return an array reference of characters composing PS

=head2 IsSourceCharacterButNotStar()

=head2 IsSourceCharacterButNotStarOrLineTerminator()

=head2 IsSourceCharacterButNotOneOfDquoteOrBackslashOrU0000ThroughU001F()

=head2 IsSourceCharacterButNotOneOfSlashOrStar()

=head2 IsSourceCharacterButNotSlash()

=head2 IsSourceCharacterButNotOneOfSlashOrStarOrLineTerminator()

=head2 IsLineTerminator()

=head2 LineTerminator()

Return an array reference of characters composing LineTerminator

=head2 IsSourceCharacterButNotLineTerminator()

=head2 IsUnicodeLetter()

=head2 IsUnicodeCombiningMark()

=head2 IsUnicodeDigit()

=head2 IsUnicodeConnectorPunctuation()

=head2 IsU0000ThroughU001F()

=head2 IsSourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator()

=head2 IsSourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator()

=head2 IsSingleEscapeCharacter()

=head2 IsDecimalDigit()

=head2 IsOctalDigit()

=head2 IsNonZeroDigit()

=head2 IsEscapeCharacter()

=head2 IsSourceCharacterButNotOneOfEscapeCharacterOrLineTerminator()

=head2 IsRegularExpressionNonTerminator()

=head2 IsRegularExpressionNonTerminatorButNotOneOfStarOrBackslashOrSlashOrLbracket()

=head2 IsRegularExpressionNonTerminatorButNotOneOfBackslashOrSlashOrLbracket()

=head2 IsRegularExpressionNonTerminatorButNotOneOfRbracketOrBackslash()

=head2 IsHexDigit()

=head2 IsIdentityEscape()

=head2 IsExponentIndicator()

=head2 IsPatternCharacter()

=head2 IsSourceCharacterButNotOneOfBackslashOrRbracketOrMinus()

=head2 Isx()

=head2 Isu()

=head2 IsUnderscore()

=head2 Isv()

=head2 IsStar()

=head2 IsBackslash()

=head2 IsCaret()

=head2 IsDollar()

=head2 IsDot()

=head2 IsLparen()

=head2 IsRparen()

=head2 IsLcurly()

=head2 IsRcurly()

=head2 IsQuestion_Mark()

=head2 IsPlus()

=head2 IsMinus()

=head2 IsSquote()

=head2 IsDquote()

=head2 IsPipe()

=head2 IsSlash()

=head2 IsLbracket()

=head2 IsRbracket()

=head2 Isb()

=head2 Isf()

=head2 Ise()

=head2 IsE()

=head2 IseOrE()

=head2 Isn()

=head2 Isr()

=head2 Ist()

=head2 IsZero()

=head2 IsEight()

=head2 IsNine()

=head2 IsZeroToThree()

=head2 IsFourToSeven()

=head1 DESCRIPTION

This modules defines generic user-defined character classes for ECMAScript. There is no notion of object here, only functions that can be imported using the tag qw/:all/.

=head1 EXPORTS

This module is exporting on demand the following tags:

=over

=item all

All functions.

=back

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
