use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern::Semantics;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;
use SUPER;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

# ABSTRACT: ECMAScript-262, Edition 5, pattern grammar written in Marpa BNF

our $VERSION = '0.020'; # VERSION


#
# Note that this grammar is NOT supposed to be injected in Program
#
our $grammar_content = do {local $/; <DATA>};


sub new {
    my ($class, $optionsp) = @_;

    $optionsp //= {};

    my $semantics_package = exists($optionsp->{semantics_package}) ? $optionsp->{semantics_package} : join('::', $class, 'Semantics');

    my $self = $class->SUPER();

    #
    # Add semantics package to self
    #
    $self->{_semantics_package} = $semantics_package;
    #
    # Add tracking of disjunction positions
    #
    $self->{_lparen} = [];

    return $self;
}


sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
}


sub lparen {
    my ($self) = @_;

    return $self->{_lparen};
}


sub recce_option {
    my ($self) = @_;
    #
    # Get default hash
    #
    my $default = $self->SUPER();
    #
    # And overwrite the semantics_package
    #
    $default->{semantics_package} = $self->{_semantics_package};

    return $default;
}


sub parse {
    my ($self, $source, $impl) = @_;
    #
    # Reset tracking of disjunction positions
    #
    $self->{_lparen} = [];
    return $self->SUPER($source, $impl,
                        {
                         callback => \&_eventCallback,
                         callbackargs => [ $self ],
                        });
}

sub _eventCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  #
  # $pos is the exact position where SLIF stopped because of an event
  #
  my $rc = $pos;

  foreach (@{$impl->events()}) {
    my ($name) = @{$_};
    #
    # Events are always in this order:
    #
    # ---------------------------------
    # 1. Completion events first (XXX$)
    # ---------------------------------
    #
    if ($name eq 'LPAREN_ATOM_DISJUNCTION$') {
	#
	# By definition, the current position here is exactly
	# after the '(', so position in the stream of this
	# lexeme is $pos-1.
	push(@{$self->{_lparen}}, $pos-1);
    }
  }

  return $rc;
}


sub value {
  my ($self, $impl) = @_;

  #
  # Left-parenthesis locations, so that they are visible when Marpa will call
  # semantics_package's new().
  #
  local $MarpaX::Languages::ECMAScript::AST::Grammar::Pattern::lparen = $self->{_lparen};

  return $self->SUPER($impl);
}



1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern - ECMAScript-262, Edition 5, pattern grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 pattern grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>, section 15.10.1. This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package.

=head1 SUBROUTINES/METHODS

=head2 new($optionsp)

$optionsp is a reference to hash that may contain the following key/value pair:

=over

=item semantics_package

As per Marpa::R2, The semantics package is used when resolving action names to fully qualified Perl names. This package must support and behave as documented in the Semantics package (c.f. SEE ALSO).

=back

=head2 make_grammar_content($class)

Returns the grammar. This will be injected in the Program's grammar.

=head2 lparen($self)

Returns current lexer left parenthesis offsets of captures.

=head2 recce_option($self)

Returns option for Marpa::R2::Scanless::R->new(), returned as a reference to a hash.

=head2 parse($self, $source, $impl)

Parse the source given as $source using implementation $impl.

=head2 value($self, $impl)

Return the parse tree (unique) value. $impl is the recognizer instance for the grammar. Will raise an InternalError exception if there is no parse tree value, or more than one parse tree value. Please note that this method explicity destroys the recognizer using $impl->destroy_R. Value itself is an AST where every string is a perl string. This a subclass of MarpaX::Languages::ECMAScript::AST::Grammar::Base::value() because the position of disjunction left parenthesis is localized, so that value() will see them.

This method is explicitely setting a localized MarpaX::Languages::ECMAScript::AST::Grammar::Pattern::lparen variable that is an array reference of all disjunctions left parenthesis locations in the regular expression perl string.

=head1 SEE ALSO

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base>

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Pattern::Semantics>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# =================================
# ECMAScript Script Pattern grammar
# =================================
#
:start ::= Pattern
:default ::= action => [values]
lexeme default = action => [start,length,value] forgiving => 1

Pattern ::=
      Disjunction                             action => _Pattern_Disjunction

Disjunction ::=
      Alternative                             action => _Disjunction_Alternative
    | Alternative '|' Disjunction             action => _Disjunction_Alternative_OR_Disjunction

Alternative ::=                               action => _Alternative
Alternative ::= Alternative Term              action => _Alternative_Alternative_Term

Term ::=
      Assertion                               action => _Term_Assertion
    | Atom                                    action => _Term_Atom
    | Atom Quantifier                         action => _Term_Atom_Quantifier

Assertion ::=
      '^'                                     action => _Assertion_Caret
    | '$'                                     action => _Assertion_Dollar
    | '\b'                                    action => _Assertion_b
    | '\B'                                    action => _Assertion_B
    | '(?=' Disjunction ')'                   action => _Assertion_DisjunctionPositiveLookAhead
    | '(?!' Disjunction ')'                   action => _Assertion_DisjunctionNegativeLookAhead

Quantifier ::=
      QuantifierPrefix                        action => _Quantifier_QuantifierPrefix
    | QuantifierPrefix '?'                    action => _Quantifier_QuantifierPrefix_QuestionMark

QuantifierPrefix ::=
      '*'                                     action => _QuantifierPrefix_Star
    | '+'                                     action => _QuantifierPrefix_Plus
    | '?'                                     action => _QuantifierPrefix_QuestionMark
    | '{' DecimalDigits '}'                   action => _QuantifierPrefix_DecimalDigits
    | '{' DecimalDigits ',}'                  action => _QuantifierPrefix_DecimalDigits_Comma
    | '{' DecimalDigits ',' DecimalDigits '}' action => _QuantifierPrefix_DecimalDigits_DecimalDigits

Atom ::=
      PatternCharacter                        action => _Atom_PatternCharacter
    | '.'                                     action => _Atom_Dot
    | '\' AtomEscape                          action => _Atom_Backslash_AtomEscape
    | CharacterClass                          action => _Atom_Backslash_CharacterClass
    | LPAREN_ATOM_DISJUNCTION Disjunction ')' action => _Atom_Lparen_Disjunction_Rparen
    | '(?:' Disjunction ')'                   action => _Atom_nonCapturingDisjunction

PatternCharacter ~
      [\p{IsPatternCharacter}]

AtomEscape ::=
      DecimalEscape                           action => _AtomEscape_DecimalEscape
    | CharacterEscape                         action => _AtomEscape_CharacterEscape
    | CharacterClassEscape                    action => _AtomEscape_CharacterClassEscape

CharacterEscape ::=
      ControlEscape                           action => _CharacterEscape_ControlEscape
    | 'c' ControlLetter                       action => _CharacterEscape_ControlLetter
    | HexEscapeSequence                       action => _CharacterEscape_HexEscapeSequence
    | UnicodeEscapeSequence                   action => _CharacterEscape_UnicodeEscapeSequence
    | IdentityEscape                          action => _CharacterEscape_IdentityEscape

ControlEscape ~
      [fnrtv]

ControlLetter ~
      [a-zA-Z]

#
# What means "SourceCharacterbut not IdentifierPart":
# - first this is a SourceCharacter, i.e. one single (utf8) character
# - IdentifierPart is
#    [\p{IsUnicodeLetter}]
#  | '$'
#  | '_'
#  | '\' _UnicodeEscapeSequence       ELIMINATED: more than one character
#  | [\p{IsUnicodeCombiningMark }]
#  | [\p{IsUnicodeDigit}]
#  | [\p{IsUnicodeConnectorPunctuation}]
#  | _ZWNJ
#  | _ZWJ
#
# So this mean:
#  +IsSourceCharacter
#  -IsUnicodeLetter
#  -'$'
#  -'_'
#  -IsUnicodeCombiningMark
#  -IsUnicodeDigit
#  -IsUnicodeConnectorPunctuation

#IdentityEscape ::=
#      SourceCharacterbut not IdentifierPart
#    | <ZWJ>
#    | <ZWNJ>

IdentityEscape ~
       [\p{IsIdentityEscape}]

DecimalEscape ::= # Lookahead not in decimal digit is automatic
    DecimalIntegerLiteral                           action => _DecimalEscape_DecimalIntegerLiteral

DecimalIntegerLiteral ::= _DecimalIntegerLiteral    action => _DecimalIntegerLiteral

_DecimalIntegerLiteral ~
    '0'
  | _NonZeroDigit
  | _NonZeroDigit __DecimalDigits

__DecimalDigits ~ [\p{IsDecimalDigit}]+
_DecimalDigits  ~ __DecimalDigits
DecimalDigits ::= _DecimalDigits                    action => _DecimalDigits

_NonZeroDigit      ~ [\p{IsNonZeroDigit}]

CharacterClassEscape ::=
      [dDsSwW]                                      action => _CharacterClassEscape

CharacterClass ::=
      '[' ClassRanges ']'                           action => _CharacterClass_ClassRanges
    | '[^' ClassRanges ']'                          action => _CharacterClass_CaretClassRanges

ClassRanges ::=                                     action => _ClassRanges
ClassRanges ::=
  NonemptyClassRanges                               action => _ClassRanges_NonemptyClassRanges

NonemptyClassRanges ::=
      ClassAtom                                     action => _NonemptyClassRanges_ClassAtom
    | ClassAtom NonemptyClassRangesNoDash           action => _NonemptyClassRanges_ClassAtom_NonemptyClassRangesNoDash
    | ClassAtom '-' ClassAtom ClassRanges           action => _NonemptyClassRanges_ClassAtom_ClassAtom_ClassRanges

NonemptyClassRangesNoDash ::=
      ClassAtom                                     action => _NonemptyClassRangesNoDash_ClassAtom
    | ClassAtomNoDash NonemptyClassRangesNoDash     action => _NonemptyClassRangesNoDash_ClassAtomNoDash_NonemptyClassRangesNoDash
    | ClassAtomNoDash '-' ClassAtom ClassRanges     action => _NonemptyClassRangesNoDash_ClassAtomNoDash_ClassAtom_ClassRanges

ClassAtom ::=
      '-'                                           action => _ClassAtom_Dash
    | ClassAtomNoDash                               action => _ClassAtom_ClassAtomNoDash

ClassAtomNoDash ::=
      OneChar                                       action => _ClassAtomNoDash_OneChar
    | '\' ClassEscape                               action => _ClassAtomNoDash_ClassEscape

ClassEscape ::=
      DecimalEscape                                 action => _ClassEscape_DecimalEscape
    | 'b'                                           action => _ClassEscape_b
    | CharacterEscape                               action => _ClassEscape_CharacterEscape
    | CharacterClassEscape                          action => _ClassEscape_CharacterClassEscape

HexEscapeSequence ::= 'x' _HexDigit _HexDigit                         action => _HexEscapeSequence

UnicodeEscapeSequence ::= 'u' _HexDigit _HexDigit _HexDigit _HexDigit action => _UnicodeEscapeSequence

_HexDigit              ~ [\p{IsHexDigit}]

OneChar                ~ [\p{IsSourceCharacterButNotOneOfBackslashOrRbracketOrMinus}]

:lexeme ~ <LPAREN_ATOM_DISJUNCTION> pause => after event => 'LPAREN_ATOM_DISJUNCTION$'
LPAREN_ATOM_DISJUNCTION ~ '('
