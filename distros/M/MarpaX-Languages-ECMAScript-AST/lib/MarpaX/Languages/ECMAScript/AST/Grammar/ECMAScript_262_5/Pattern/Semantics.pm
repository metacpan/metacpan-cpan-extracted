use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern::Semantics;
use MarpaX::Languages::ECMAScript::AST::Exceptions qw/:all/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;
use List::Compare::Functional 0.21 qw/get_union_ref/;
use Unicode::Normalize qw/NFD NFC/;
use Import::Into;

#
# Credit goes to utf8::all
#
if ($^V >= v5.11.0) {
    'feature'->import::into(__PACKAGE__, qw/unicode_strings/);
}

use constant {
  ASSERTION_IS_NOT_MATCHER => 0,
  ASSERTION_IS_MATCHER     => 1
};
use constant {
    ORD_a => ord('a'),
    ORD_z => ord('z'),
    ORD_A => ord('A'),
    ORD_Z => ord('Z'),
    ORD_0 => ord('0'),
    ORD_9 => ord('9'),
    ORD__ => ord('_'),
};

# ABSTRACT: ECMAScript 262, Edition 5, pattern grammar default semantics package

our $VERSION = '0.020'; # VERSION


sub new {
    my ($class) = @_;
    my $self = {_lparen => $MarpaX::Languages::ECMAScript::AST::Grammar::Pattern::lparen};
    bless $self, $class;
}


sub lparen {
    my ($self) = @_;

    return $self->{_lparen};
}

#
# IMPORTANT NOTE: These actions DELIBIRATELY do not use any perl regular expression. This is the prove that one can
# write a fresh regular expression engine from scratch. The only important notion is case-folding. There we rely
# on perl.
#
our @LINETERMINATOR = @{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::LineTerminator()};
our %HASHLINETERMINATOR = map {$_ => 1} @LINETERMINATOR;
our @WHITESPACE = @{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::WhiteSpace()};

sub _Pattern_Disjunction {
    my ($self, $disjunction) = @_;

    my $m = $disjunction;

    return sub {
	#
	# Note: $str is a true perl string, $index is a true perl scalar
	#
	my ($str, $index, $multiline, $ignoreCase, $upperCase) = @_;
	$multiline //= 0;
	$ignoreCase //= 0;
	$upperCase //= sub {
	    if ($^V >= v5.11.0) {
		#
		# C.f. http://www.effectiveperlprogramming.com/2012/02/fold-cases-properly/
		# Please note that we really want only the upper case version as per
		# ECMAScript specification
		#
		return uc($_[0]);
	    } else {
		#
		# C.f. uc from Unicode::Tussle
		#
		return NFC(uc(NFD($_[0])));
	    }
	};
	#
	# We localize input, input length, mutiline and ignoreCase
	#
	local $MarpaX::Languages::ECMAScript::AST::Pattern::input = $str;
	local $MarpaX::Languages::ECMAScript::AST::Pattern::inputLength = length($str);
	local $MarpaX::Languages::ECMAScript::AST::Pattern::multiline = $multiline;
	local $MarpaX::Languages::ECMAScript::AST::Pattern::ignoreCase = $ignoreCase;
	local $MarpaX::Languages::ECMAScript::AST::Pattern::upperCase = $upperCase;

	my $c = sub {
	    my ($state) = @_;
	    return $state;
	};
	my $cap = [ (undef) x scalar(@{$self->lparen}) ];
	my $x = [ $index, $cap ];

	return &$m($x, $c);
    };
}

sub _Disjunction_Alternative {
    my ($self, $alternative) = @_;
    return $alternative;
}

sub _Disjunction_Alternative_OR_Disjunction {
    my ($self, $alternative, undef, $disjunction) = @_;

    my $m1 = $alternative;
    my $m2 = $disjunction;

    return sub {
	my ($x, $c) = @_;
	my $r = &$m1($x, $c);
        if ($r) {
          return $r;
        }
        return &$m2($x, $c);
    };
}

sub _Alternative {
    my ($self) = @_;

    return sub {
	my ($x, $c) = @_;
	return &$c($x);
    };
}

sub _Alternative_Alternative_Term {
    my ($self, $alternative, $term) = @_;

    my $m1 = $alternative;
    my $m2 = $term;

    return sub {
      my ($x, $c) = @_;
      my $d = sub {
	  my ($y) = @_;
	  return &$m2($y, $c);
      };
      return &$m1($x, $d);
    };
}

sub _Term_Assertion {
    my ($self, $assertion) = @_;

    my ($isMatcher, $assertionCode) = @{$assertion};

    return sub {
	my ($x, $c) = @_;

        if (! $isMatcher) {
          my $t = $assertionCode;
          my $r = &$t($x, $c);        # Take care! Typo in ECMAScript spec, $c is missing
          if (! $r) {
	    return 0;
          }
          return &$c($x);
        } else {
          my $m = $assertionCode;
          return &$m($x, $c);
        }
    };
}

sub _Term_Atom {
    my ($self, $atom) = @_;

    return $atom;
}

sub _repeatMatcher {
  my ($m, $min, $max, $greedy, $x, $c, $parenIndex, $parenCount) = @_;

  if (defined($max) && $max == 0) {
    return &$c($x);
  }
  my $d = sub {
    my ($y) = @_;
    if ($min == 0 && $y->[0] == $x->[0]) {
      return 0;
    }
    my $min2 = ($min == 0) ? 0 : ($min - 1);
    my $max2 = (! defined($max)) ? undef : ($max - 1);
    return _repeatMatcher($m, $min2, $max2, $greedy, $y, $c, $parenIndex, $parenCount);
  };
  my @cap = @{$x->[1]};
  foreach my $k (($parenIndex+1)..($parenIndex+$parenCount)) {
    $cap[$k-1] = undef;     # Take care, cap index in ECMA spec start at 1
  }
  my $e = $x->[0];
  my $xr = [$e, \@cap ];
  if ($min != 0) {
    return &$m($xr, $d);
  }
  if (! $greedy) {
    my $z = &$c($x);
    if ($z) {
      return $z;
    }
    return &$m($xr, $d);
  }
  my $z = &$m($xr, $d);
  if ($z) {
    return $z;
  }
  return &$c($x);
}

sub _parenIndexAndCount {
    my ($self) = @_;

    my ($start, $end) = Marpa::R2::Context::location();
    my $parenIndex = 0;
    my $parenCount = 0;
    foreach (@{$self->lparen}) {
	if ($_ < $start) {
	    ++$parenIndex;
	}
	elsif ($_ <= $end) {
	    ++$parenCount;
	}
    }
    return {parenIndex => $parenIndex, parenCount => $parenCount};
}

#
# Note: we will use undef for $max when its value is infinite
#
sub _Term_Atom_Quantifier {
    my ($self, $atom, $quantifier) = @_;

    my $m = $atom;
    my ($min, $max, $greedy) = @{$quantifier};
    if (defined($max) && $max < $min) {
      SyntaxError("Bad quantifier {$min,$max} in regular expression");
    }
    my $hashp = $self->_parenIndexAndCount();

    return sub {
	my ($x, $c) = @_;

	return _repeatMatcher($m, $min, $max, $greedy, $x, $c, $hashp->{parenIndex}, $hashp->{parenCount});
    };
}

sub _Assertion_Caret {
    my ($self, $caret) = @_;

    return [ASSERTION_IS_NOT_MATCHER,
            sub {
              my ($x) = @_;


              my $e = $x->[0];
              if ($e == 0) {
                return 1;
              }
              if (! $MarpaX::Languages::ECMAScript::AST::Pattern::multiline) {
                return 0;
              }
              my $c = substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $e-1, 1);
              if (exists($HASHLINETERMINATOR{$c})) {
                return 1;
              }

              return 0;
            }],
}

sub _Assertion_Dollar {
    my ($self, $caret) = @_;

    return [ASSERTION_IS_NOT_MATCHER,
            sub {
              my ($x) = @_;

              my $e = $x->[0];
              if ($e == $MarpaX::Languages::ECMAScript::AST::Pattern::inputLength) {
                return 1;
              }
              if (! $MarpaX::Languages::ECMAScript::AST::Pattern::multiline) {
                return 0;
              }
              my $c = substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $e, 1);
              if (exists($HASHLINETERMINATOR{$c})) {
                return 1;
              }

              return 0;
            }];
}

sub _isWordChar {
    my ($e) = @_;

    if ($e == -1 || $e == $MarpaX::Languages::ECMAScript::AST::Pattern::inputLength) {
	return 0;
    }
    #
    # This really refers to ASCII characters, so it is ok to test the ord directly
    #
    my $c = ord(substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $e, 1));
    #
    # I put the most probables (corresponding also to the biggest ranges) first
    if (
	($c >= ORD_a && $c <= ORD_z)
	||
	($c >= ORD_A && $c <= ORD_Z)
	||
	($c >= ORD_0 && $c <= ORD_9)
	||
	($c == ORD__)
	) {
	return 1;
    }

    return 0;
}

sub _Assertion_b {
    my ($self, $caret) = @_;

    return [ASSERTION_IS_NOT_MATCHER,
            sub {
              my ($x) = @_;

              my $e = $x->[0];
              my $a = _isWordChar($e-1);
              my $b = _isWordChar($e);
              if ($a && ! $b) {
                return 1;
              }
              if (! $a && $b) {
                return 1;
              }
              return 0;
            }];
}

sub _Assertion_B {
    my ($self, $caret) = @_;

    return [ASSERTION_IS_NOT_MATCHER,
            sub {
              my ($x) = @_;

              my $e = $x->[0];
              my $a = _isWordChar($e-1);
              my $b = _isWordChar($e);
              if ($a && ! $b) {
                return 0;
              }
              if (! $a && $b) {
                return 0;
              }
              return 1;
            }];
}

sub _Assertion_DisjunctionPositiveLookAhead {
    my ($self, undef, $disjunction, undef) = @_;

    my $m = $disjunction;

    return [ASSERTION_IS_MATCHER,
            sub {
              my ($x, $c) = @_;

              my $d = sub {
                my ($y) = @_;
                return $y;
              };

              my $r = &$m($x, $d);
              if (! $r) {
                return 0;
              }
              my $y = $r;
              my $cap = $y->[1];
              my $xe = $x->[0];
              my $z = [$xe, $cap];
              return &$c($z);
            }];
}

sub _Assertion_DisjunctionNegativeLookAhead {
    my ($self, undef, $disjunction, undef) = @_;

    my $m = $disjunction;

    return [ASSERTION_IS_MATCHER,
            sub {
              my ($x, $c) = @_;

              my $d = sub {
                my ($y) = @_;
                return $y;
              };

              my $r = &$m($x, $d);
              if ($r) {
                return 0;
              }
              return &$c($x);
            }];
}

sub _Quantifier_QuantifierPrefix {
    my ($self, $quantifierPrefix) = @_;

    my ($min, $max) = @{$quantifierPrefix};
    return [$min, $max, 1];
}

sub _Quantifier_QuantifierPrefix_QuestionMark {
    my ($self, $quantifierPrefix, $questionMark) = @_;

    my ($min, $max) = @{$quantifierPrefix};
    return [$min, $max, 0];
}

sub _QuantifierPrefix_Star {
    my ($self, $start) = @_;

    return [0, undef];
}

sub _QuantifierPrefix_Plus {
    my ($self, $plus) = @_;

    return [1, undef];
}

sub _QuantifierPrefix_QuestionMark {
    my ($self, $questionMark) = @_;

    return [0, 1];
}

sub _QuantifierPrefix_DecimalDigits {
    my ($self, undef, $decimalDigits, undef) = @_;

    return [$decimalDigits, $decimalDigits];
}

sub _QuantifierPrefix_DecimalDigits_Comma {
    my ($self, undef, $decimalDigits, undef) = @_;

    return [$decimalDigits, undef];
}

sub _QuantifierPrefix_DecimalDigits_DecimalDigits {
    my ($self, undef, $decimalDigits1, undef, $decimalDigits2, undef) = @_;

    return [$decimalDigits1, $decimalDigits2];
}

sub _canonicalize {
    my ($ch) = @_;

    if (! $MarpaX::Languages::ECMAScript::AST::Pattern::ignoreCase) {
	return $ch;
    }

    my $u = &$MarpaX::Languages::ECMAScript::AST::Pattern::upperCase($ch);
    if (length($u) != 1) {
	#
	# I don't know why it has been designed like that -;
	#
	return $ch;
    }
    my $cu = $u;
    if (ord($ch) >= 128 && ord($cu) < 128) {
	return $ch;
    }
    return $cu;
}

#
# Note: we extend a little the notion of range to:
# * range including characters from ... to ...
# and
# * range NOT including characters from ... to ...
#
# i.e. a character set is [ negation flag, [range] ]
#
# This is different from the invert flag. For example:
# [^\d] means: $A=[0,[0..9]], $invert=1
# [^\D] means: $A=[1,[0..9]], $invert=1, which is equivalent to [\d], i.e.: $A=[0,[0..9], $invert=0

sub _characterSetMatcher {
    my ($self, $A, $invert) = @_;

    my ($x, $c) = @_;

    my ($Anegation, $Arange) = @{$A};

    if ($Anegation) {
	$invert = ! $invert;
    }

    return sub {
	my ($x, $c) = @_;

	my $e = $x->[0];
	if ($e == $MarpaX::Languages::ECMAScript::AST::Pattern::inputLength) {
	    return 0;
	}
	my $ch = substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $e, 1);
	my $cc = _canonicalize($ch);
	if (! $invert) {
	    if (! grep {$cc eq _canonicalize($_)} @{$Arange}) {
		return 0;
	    }
	} else {
	    if (grep {$cc eq _canonicalize($_)} @{$Arange}) {
		return 0;
	    }
	}
	my $cap = $x->[1];
	my $y = [$e+1, $cap];
	return &$c($y);
    };
}

sub _Atom_PatternCharacter {
    my ($self, $patternCharacter) = @_;

    #
    # Note: PatternCharacter is a lexeme, default lexeme value is [start,length,value]
    #
    my $ch = $patternCharacter->[2];
    my $A = [0 , [ $ch ]];
    return $self->_characterSetMatcher($A, 0);
}

sub _Atom_Dot {
    my ($self, $dot) = @_;

    my $A = [1 , \@LINETERMINATOR];
    return $self->_characterSetMatcher($A, 0);


}

sub _Atom_Backslash_AtomEscape {
    my ($self, $backslash, $atomEscape) = @_;

    return $atomEscape;
}

sub _Atom_Backslash_CharacterClass {
    my ($self, $characterClass) = @_;

    my ($A, $invert) = @{$characterClass};
    return $self->_characterSetMatcher($A, $invert);
}

sub _Atom_Lparen_Disjunction_Rparen {
    my ($self, $lparen, $disjunction, $rparen) = @_;

    my $m = $disjunction;
    my $parenIndex = $self->_parenIndexAndCount()->{parenIndex};
    return sub {
	my ($x, $c) = @_;

	my $d = sub {
	    my ($y) = @_;

	    my @cap = @{$y->[1]};
	    my $xe = $x->[0];
	    my $ye = $y->[0];
	    my $s = substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $xe, $ye-$xe);
	    $cap[$parenIndex] = $s;        # Take care, in ECMA spec, cap index start at 1
	    my $z = [$ye, \@cap ];
	    return &$c($z);
	};

	return &$m($x, $d);
    };
}

sub _Atom_nonCapturingDisjunction {
    my ($self, undef, $disjunction, undef) = @_;

    return $disjunction;
}

sub _AtomEscape_DecimalEscape {
    my ($self, $decimalEscape) = @_;

    my $E = $decimalEscape;

    #
    # We are in an atom escape context: the only allowed character is NUL
    #
    my $ch = ($decimalEscape == 0) ? MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::NULL()->[0] : undef;

    if (defined($ch)) {
	my $A = [0 , [ $ch ]];
	return $self->_characterSetMatcher($A, 0);
    }
    my $n = $E;
    if ($n == 0 || $n > scalar(@{$self->lparen})) {
	SyntaxError("backtrack number must be <= " . scalar(@{$self->lparen}));
    }
    return sub {
	my ($x, $c) = @_;

	my $cap = $x->[1];
	my $s = $cap->[$n-1];     # Take care, in ECMA spec cap index start at 1
	if (! defined($s)) {
	    return &$c($x);
	}
	my $e = $x->[0];
	my $len = length($s);
	my $f = $e+$len;
	if ($f > $MarpaX::Languages::ECMAScript::AST::Pattern::inputLength) {
	    return 0;
	}
	foreach (0..($len-1)) {
	    if (_canonicalize(substr($s, $_, 1)) ne _canonicalize(substr($MarpaX::Languages::ECMAScript::AST::Pattern::input, $e+$_, 1))) {
		return 0;
	    }
	}
	my $y = [$f, $cap];
	return &$c($y);
    };
}

sub _AtomEscape_CharacterEscape {
    my ($self, $characterEscape) = @_;

    my $ch = $characterEscape;
    my $A = [0 , [ $ch ]];
    return $self->_characterSetMatcher($A, 0);
}

sub _AtomEscape_CharacterClassEscape {
    my ($self, $characterClassEscape) = @_;

    return $self->_characterSetMatcher($characterClassEscape, 0);
}

sub _CharacterEscape_ControlEscape {
    my ($self, $controlEscape) = @_;

    #
    # Note: ControlEscape is a lexeme, default lexeme value is [start,length,value]
    #
    if ($controlEscape->[2] eq 't') {
	return MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::TAB()->[0];
    }
    elsif ($controlEscape->[2] eq 'n') {
	return MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::LF()->[0];
    }
    elsif ($controlEscape->[2] eq 'v') {
	return MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::VT()->[0];
    }
    elsif ($controlEscape->[2] eq 'f') {
	return MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::FF()->[0];
    }
    elsif ($controlEscape->[2] eq 'r') {
	return MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::CR()->[0];
    }
}

sub _CharacterEscape_ControlLetter {
    my ($self, undef, $controlLetter) = @_;

    #
    # Note: ControlEscape is a lexeme, default lexeme value is [start,length,value]
    #
    my $ch = $controlLetter->[2];
    my $i = ord($ch);
    my $j = $i % 32;
    return chr($j);
}

#
# Note: _HexDigit is a lexeme, default lexeme value is [start,length,value]
#
sub _HexEscapeSequence { return chr(16 * hex($_[2]->[2]) + hex($_[3]->[2])); }
sub _UnicodeEscapeSequence { return chr(4096 * hex($_[2]->[2]) + 256 * hex($_[3]->[2]) + 16 * hex($_[4]->[2]) + hex($_[5]->[2])); }

sub _CharacterEscape_HexEscapeSequence {
    my ($self, $hexEscapeSequence) = @_;

    return $hexEscapeSequence;
}

sub _CharacterEscape_UnicodeEscapeSequence {
    my ($self, $unicodeEscapeSequence) = @_;

    return $unicodeEscapeSequence;
}

sub _CharacterEscape_IdentityEscape {
    my ($self, $identityEscape) = @_;
    #
    # Note: IdentityEscape is a lexeme, default lexeme value is [start,length,value]
    #
    return $identityEscape->[2];
}

sub _DecimalEscape_DecimalIntegerLiteral {
    my ($self, $decimalIntegerLiteral) = @_;

    #
    # Note: DecimalIntegerLiteral is already an integer
    #
    my $i = $decimalIntegerLiteral;

    return $i;
}

sub _DecimalIntegerLiteral {
    my ($self, $decimalIntegerLiteral) = @_;

    #
    # Note: decimalIntegerLiteral is a lexeme, default lexeme value is [start,length,value]
    #
    return int($decimalIntegerLiteral->[2]);
}

sub _DecimalDigits {
    my ($self, $decimalDigits) = @_;

    #
    # Note: decimalDigits is a lexeme, default lexeme value is [start,length,value]
    #
    return int($decimalDigits->[2]);
}

sub _CharacterClassEscape {
    my ($self, $cCharacterClassEscape) = @_;

    if ($cCharacterClassEscape eq 'd') {
	return [0 , [ '0'..'9' ]];
    }
    elsif ($cCharacterClassEscape eq 'D') {
	return [1 , [ '0'..'9' ]];
    }
    elsif ($cCharacterClassEscape eq 's') {
	return [0 , [ @WHITESPACE, @LINETERMINATOR ]];
    }
    elsif ($cCharacterClassEscape eq 'S') {
	return [1 , [ @WHITESPACE, @LINETERMINATOR ]];
    }
    elsif ($cCharacterClassEscape eq 'w') {
	return [0 , [ 'a'..'z', 'A'..'Z', '0'..'9', '_' ]];
    }
    elsif ($cCharacterClassEscape eq 'W') {
	return [1 , [ 'a'..'z', 'A'..'Z', '0'..'9', '_' ]];
    }

}

sub _CharacterClass_ClassRanges {
    my ($self, undef, $classRanges, undef) = @_;

    return [$classRanges, 0];
}

sub _CharacterClass_CaretClassRanges {
    my ($self, undef, $classRanges, undef) = @_;

    return [$classRanges, 1];
}

sub _ClassRanges {
    my ($self) = @_;

    return [0, []];
}

sub _ClassRanges_NonemptyClassRanges {
    my ($self, $nonemptyClassRanges) = @_;

    return $nonemptyClassRanges;
}

sub _NonemptyClassRanges_ClassAtom {
    my ($self, $classAtom) = @_;

    return $classAtom;
}

sub _rangeComplement {
    my ($self, $A) = @_;

    my ($Anegation, $Arange) = @{$A};

    my %hash = map {$_ => 1} @{$Arange};

    return [ $Anegation ? 0 : 1, [ grep {! exists($hash{$_})} (1.65535) ] ];
  
}

sub _charsetUnion {
    my ($self, $A, $B) = @_;

    my ($Anegation, $Arange) = @{$A};
    my ($Bnegation, $Brange) = @{$B};

    if ($Anegation == $Bnegation) {
	#
	# If A and B have the same negation, then this really is a normal union
	#
	return [ $Anegation, get_union_ref('--unsorted', [ $Arange, $Brange ]) ];
    } else {
	#
	# If not A and B have the same negation, then this really is a normal union.
	# We choose the one with the smallest number of elements
	#
	my $Aelements = $#{$A->[1]};
	my $Belements = $#{$B->[1]};
	#
	# 65534 because this is the maximum index in JavaScript, limited explicitely to UCS-2
	#
	my $AelementsRevert = 65534 - $#{$A->[1]};
	my $BelementsRevert = 65534 - $#{$B->[1]};

	if (($Aelements + $BelementsRevert) <= ($AelementsRevert + $Belements)) {
	    #
	    # We take the union of A and reverted B
	    #
	    return $self->_charsetUnion($A, $self->_rangeComplement($B));
	} else {
	    #
	    # We take the union of reverted A and B
	    #
	    return $self->_charsetUnion($self->_rangeComplement($A), $B);
	}
    }
}

sub _NonemptyClassRanges_ClassAtom_NonemptyClassRangesNoDash {
    my ($self, $classAtom, $nonemptyClassRangesNoDash) = @_;

    my $A = $classAtom;
    my $B = $nonemptyClassRangesNoDash;
    return $self->_charsetUnion($A, $B);
}

sub _characterRange {
    my ($self, $A, $B) = @_;

    my ($Anegation, $Arange) = @{$A};
    my ($Bnegation, $Brange) = @{$B};

    if ($Anegation != $Bnegation) {
	# We choose the one with the smallest number of elements
	#
	my $Aelements = $#{$A->[1]};
	my $Belements = $#{$B->[1]};
	#
	# 65534 because this is the maximum index in JavaScript, limited explicitely to UCS-2
	#
	my $AelementsRevert = 65534 - $#{$A->[1]};
	my $BelementsRevert = 65534 - $#{$B->[1]};

	if ($AelementsRevert <= $BelementsRevert) {
	    #
	    # We take the reverted A
	    #
	    ($Anegation, $Arange) = $self->_rangeComplement($A);
	} else {
	    #
	    # We take the reverted B
	    #
	    ($Bnegation, $Brange) = $self->_rangeComplement($B);
	}
    }

    if ($#{$Arange} != 0 || $#{$Brange} != 0) {
	SyntaxError("Doing characterRange requires both charsets to have exactly one element");
    }
    my $a = $Arange->[0];
    my $b = $Brange->[0];
    my $i = ord($a);
    my $j = ord($b);
    if ($i > $j) {
	SyntaxError("Doing characterRange requires first char '$a' to be <= second char '$b'");
    }

    return [$Anegation, [ map {chr($_)} ($i..$j) ]];

}

sub _NonemptyClassRanges_ClassAtom_ClassAtom_ClassRanges {
    my ($self, $classAtom1, undef, $classAtom2, $classRanges) = @_;

    my $A = $classAtom1;
    my $B = $classAtom2;
    my $C = $classRanges;
    my $D = $self->_characterRange($A, $B);

    return $self->_charsetUnion($D, $C);
}

sub _NonemptyClassRangesNoDash_ClassAtom {
    my ($self, $classAtom) = @_;

    return $classAtom;
}

sub _NonemptyClassRangesNoDash_ClassAtomNoDash_NonemptyClassRangesNoDash {
    my ($self, $classAtomNoDash, $nonemptyClassRangesNoDash) = @_;

    my $A = $classAtomNoDash;
    my $B = $nonemptyClassRangesNoDash;
    return $self->_charsetUnion($A, $B);
}

sub _NonemptyClassRangesNoDash_ClassAtomNoDash_ClassAtom_ClassRanges {
    my ($self, $classAtomNoDash, undef, $classAtom, $classRanges) = @_;

    my $A = $classAtomNoDash;
    my $B = $classAtom;
    my $C = $classRanges;
    my $D = $self->_characterRange($A, $B);
    return $self->_charsetUnion($D, $C);
}

sub _ClassAtom_Dash {
    my ($self, undef) = @_;

    return [0, [ '-' ]];
}

sub _ClassAtom_ClassAtomNoDash {
    my ($self, $classAtomNoDash) = @_;

    return $classAtomNoDash;
}

sub _ClassAtomNoDash_OneChar {
    my ($self, $oneChar) = @_;

    #
    # Note: OneChar is a lexeme, default lexeme value is [start,length,value]
    #
    return [0, [ $oneChar->[2] ]];
}

sub _ClassAtomNoDash_ClassEscape {
    my ($self, undef, $classEscape) = @_;

    return $classEscape;
}

sub _ClassEscape_DecimalEscape {
    my ($self, $decimalEscape) = @_;

    my $E = $decimalEscape;

    #
    # We are in the ClassEscape context. Only a character is possible.
    # Yet, it is possible that the codepoint $E correspond to no character
    #
    my $ch = eval {chr($E)};
    if ($@) {
	SyntaxError("Decimal Escape is not a valid character");
    }
    return [0, [ $ch ]];
}

sub _ClassEscape_b {
    my ($self, undef) = @_;

    return [0, MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::BS() ];
}

sub _ClassEscape_CharacterEscape {
    my ($self, $characterEscape) = @_;

    return [0, [ $characterEscape ]];
}

sub _ClassEscape_CharacterClassEscape {
    my ($self, $characterClassEscape) = @_;

    return $characterClassEscape;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern::Semantics - ECMAScript 262, Edition 5, pattern grammar default semantics package

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules provide default host implementation for the actions associated to ECMAScript_262_5 pattern grammar.

=head2 new($class)

Instantiate a new object. The value will be a perl subroutine closure that returns a perl representation of a "MatchResult"; i.e. either a "State", either the perl's undef. A "State" is an ordered pair of [$endIndex, $captures] where $endIndex is an integer, and $captures is array reference whose length is the number of capturing parenthesis, holdign the result of the capture as perl strings. Note, however, that these perl strings are constructed using $str->charAt($index) method.

It will be the responsability of the caller to coerce back into host's representations of array and strings.

The perl subroutine closure will have four parameters: $str, $index, $multiline and $ignoreCase:

=over

=item $str

perl's string. Typically this will JavaScript's String.prototype.valueOf() on JavaScript's string.

=item $index

perl's scalar. Typically Number.prototype.valueOf() on JavaScript's number.

=item $mutiline

perl's scalar boolean, saying if this is a multiline match. Default is a false value.

=item $ignoreCase

perl's scalar boolean, saying if this is an insensitive match. Default is a false value.

=item $upperCase

CODE reference to a function that take a single argument, a code point, and returns its upper case version. Default to a builtin subroutine reference that returns Unicode's uppercase.

=back

This new routine is instanciated by a call to Marpa as a "semantics_package" recognizer option, and until one can pass directly arguments to it, it is using the localized variable $MarpaX::Languages::ECMAScript::AST::Grammar::Pattern::lparen, that is an array reference of left-parenthesis capture disjunctions's offsets.

Please note the a SyntaxError error can be thrown.

It will be the responsability of the caller to coerce back into host's representations of array and strings.

Internally the closures are overwriting explicitely the two internal variables __input__ and __inputLength__.

=head2 lparen($self)

Return an array reference of left-parenthesis capture disjunction's offsets.

=head1 NOTE

The only deviation from the standard is what I believe is an error in the ECMA-262-5 specification for Term :: Assertion. The assertion is of two types, and assertion tester and an internal matcher, while the spec assumes this is always an assertion tester. The internal matcher is when an assertion is a disjunction lookahead. In such Term :: Assertion is modified to call this matcher below and return its result.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
