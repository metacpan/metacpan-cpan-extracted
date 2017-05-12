use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral::Semantics;

# ABSTRACT: ECMAScript-262, Edition 5, string literal grammar written in Marpa BNF

our $VERSION = '0.020'; # VERSION


#
# Prevent injection of this grammar to collide with others:
# ___yy is changed to ___StringLiteral___yy
#
our $grammar_content = do {local $/; <DATA>};
$grammar_content =~ s/___/___StringLiteral___/g;


sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
}


sub make_semantics_package {
    my ($class) = @_;
    return join('::', $class, 'Semantics');
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral - ECMAScript-262, Edition 5, string literal grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 lexical string literal grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>.

This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package, and have a semantics.

=head1 SUBROUTINES/METHODS

=head2 make_grammar_content($class)

Returns the grammar. This will be injected in the Program's grammar.

=head2 semantics_package($class)

Class method that returns a default recce semantics_package, doing nothing else but a new().

=head1 SEE ALSO

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# ==================================
# ECMAScript Script Lexical String Grammar
# ==================================
#
# The source text of an ECMAScript program is first converted into a sequence of input elements, which are
# tokens, line terminators, comments, or white space.
#
:start ::= __StringLiteral
:default ::= action => ::first
lexeme default = forgiving => 1

#
# DO NOT REMOVE NOR MODIFY THIS LINE
#
# This grammar is injected in Lexical grammar, with the following modifications:
# action => xxx              are removed
# __xxx\s*::=\s*               are changed to __xxx ~
# ___yy are left as is
#

__StringLiteral ::=
    ___DoubleStringLiteral
  | ___SingleStringLiteral

___DoubleStringLiteral ::=
    '"' ___DoubleStringCharacters '"'                      action => _secondArg
  | '"' '"'                                                action => _emptyString

___SingleStringLiteral ::=
    ___Quote ___SingleStringCharacters ___Quote            action => _secondArg
  | ___Quote ___Quote                                      action => _emptyString

___DoubleStringCharacters ::=  ___DoubleStringCharacter+   action => _concat
___SingleStringCharacters ::=  ___SingleStringCharacter+   action => _concat

___DoubleStringCharacter ::=
    ___SourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator
  | '\' ___EscapeSequence                                  action => _secondArg
  # ' for my editor
  | ___LineContinuation

___SingleStringCharacter ::=
    ___SourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator
  | '\' ___EscapeSequence                                  action => _secondArg
  # ' for my editor
  | ___LineContinuation

___LineContinuation ::=
  '\' ___LineTerminatorSequence                            action => _emptyString
  # ' for my editor

___EscapeSequence ::=
    ___CharacterEscapeSequence
  | ___OctalEscapeSequence
  | ___HexEscapeSequence
  | ___UnicodeEscapeSequence

___OctalEscapeSequence ::=
    ___OctalDigit                                                             action => _OctalEscapeSequence01
  | ___ZeroToThree ___OctalDigit                                              action => _OctalEscapeSequence02
  | ___FourToSeven ___OctalDigit                                              action => _OctalEscapeSequence02
  | ___ZeroToThree ___OctalDigit ___OctalDigit                                action => _OctalEscapeSequence03

___CharacterEscapeSequence ::=
    ___SingleEscapeCharacter                                                  action => _SingleEscapeCharacter
  | ___NonEscapeCharacter

___HexEscapeSequence ::= 'x' ___HexDigit ___HexDigit                          action => _HexEscapeSequence

___UnicodeEscapeSequence ::= 'u' ___HexDigit ___HexDigit ___HexDigit ___HexDigit action => _UnicodeEscapeSequence

#
# The ___ are to prevent errors with eventual duplicate rules when injecting
# this grammar in main lexical grammar
#
___Quote ~ [\p{IsSquote}]
___SourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator ~ [\p{IsSourceCharacterButNotOneOfDquoteOrBackslashOrLineTerminator}]
___SourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator ~ [\p{IsSourceCharacterButNotOneOfSquoteOrBackslashOrLineTerminator}]
___LineTerminatorSequence ~
      [\p{IsLF}]
    | [\p{IsCR}] # Note: [lookahead not in [\p{IsLF}] ] is ok because of longest-token implementation
    | [\p{IsLS}]
    | [\p{IsPS}]
    | [\p{IsCR}] [\p{IsLF}]
___ZeroToThree           ~ [\p{IsZeroToThree}]
___FourToSeven           ~ [\p{IsFourToSeven}]
___NonEscapeCharacter    ~ [\p{IsSourceCharacterButNotOneOfEscapeCharacterOrLineTerminator}]
___SingleEscapeCharacter ~ [\p{IsSingleEscapeCharacter}]
___OctalDigit            ~ [\p{IsOctalDigit}]
___HexDigit              ~ [\p{IsHexDigit}]

