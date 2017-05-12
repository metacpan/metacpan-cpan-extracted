use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;
use SUPER;

# ABSTRACT: ECMAScript-262, Edition 5, string numeric literal grammar written in Marpa BNF

our $VERSION = '0.020'; # VERSION


#
# Note that this grammar is NOT supposed to be injected in Program
#
our $grammar_content = do {local $/; <DATA>};


sub new {
    my ($class, $optionsp) = @_;

    $optionsp //= {};

    my $semantics_package = exists($optionsp->{semantics_package}) ? $optionsp->{semantics_package} : join('::', $class, 'NativeNumberSemantics');

    my $self = $class->SUPER();

    #
    # Add semantics package to self
    #
    $self->{_semantics_package} = $semantics_package;

    return $self;
}


sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
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

#
# INTERNAL ACTIONS
#

sub _secondArg {
    return $_[2];
}

sub _value {
    return _secondArg(@_)->host_value;
}

sub _value_zero {
    return $_[0]->pos_zero->host_value;
}

sub _Infinity {
    return $_[0]->pos_inf;
}

#
# Note that HexIntegerLiteral output is a HexDigit modified
#
sub _HexIntegerLiteral_HexDigit {
    my $sixteen = $_[0]->clone_init->int("16");

    return $_[1]->mul($sixteen)->add($_[2]);
}

#
# Note that DecimalDigits output is a DecimalDigit modified
#
sub _DecimalDigits_DecimalDigit {
    my $ten = $_[0]->clone_init->int("10");
    return $_[1]->mul($ten)->add($_[2])->inc_length;
}

sub _Dot_DecimalDigits_ExponentPart {
    my $n = $_[2]->new_from_length;
    my $tenpowexponentminusn = $_[0]->clone_init->int("10")->pow($_[3]->sub($n));

    $_[2]->decimalOn;
    return $_[2]->mul($tenpowexponentminusn);
}

sub _DecimalDigits_Dot {
    $_[1]->decimalOn;
    return $_[1];
}

sub _DecimalDigits_Dot_DecimalDigits_ExponentPart {
    #
    # Done using polish logic -;
    #
    $_[1]->decimalOn;
    return $_[1]->add(
	_DecimalDigits_ExponentPart(
	    $_[0],
            _Dot_DecimalDigits($_[0], '.', $_[3]),
	    $_[4])
	);
}

sub _DecimalDigits_Dot_ExponentPart {
    my $tenpowexponent = $_[0]->clone_init->int("10")->pow($_[3]);
    $_[1]->decimalOn;
    return $_[1]->mul($tenpowexponent);
}

sub _DecimalDigits_Dot_DecimalDigits {
    $_[1]->decimalOn;
    return $_[1]->add(_Dot_DecimalDigits($_[0], '.', $_[3]));
}

sub _Dot_DecimalDigits {
    my $n = $_[2]->new_from_length;
    my $tenpowminusn = $_[0]->clone_init->int("10")->pow($n->neg);
    $_[2]->decimalOn;
    return $_[2]->mul($tenpowminusn);
}

sub _DecimalDigits_ExponentPart {
    my $tenpowexponent = $_[0]->clone_init->int("10")->pow($_[2]);

    $_[1]->decimalOn;
    return $_[1]->mul($tenpowexponent);
}

sub _HexDigit {
    return $_[0]->clone_init->hex("$_[1]");
}

sub _DecimalDigit {
    return $_[0]->clone_init->int("$_[1]");
}

sub _neg {
  return $_[2]->neg;
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral - ECMAScript-262, Edition 5, string numeric literal grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 string numeric literal grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>, section 9.3.1. This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package.

=head1 SUBROUTINES/METHODS

=head2 new($optionsp)

$optionsp is a reference to hash that may contain the following key/value pair:

=over

=item semantics_package

As per Marpa::R2, The semantics package is used when resolving action names to fully qualified Perl names. This package must support and behave as documented in the NativeNumberSemantics (c.f. SEE ALSO).

=back

=head2 make_grammar_content($class)

Returns the grammar. This will be injected in the Program's grammar.

=head2 recce_option($self)

Returns option for Marpa::R2::Scanless::R->new(), returned as a reference to a hash.

=head1 SEE ALSO

L<Data::Float>

L<Scalar::Util::Numeric>

L<Math::BigFloat>

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base>

L<MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# ================================================
# ECMAScript Script Lexical String Numeric Grammar
# ================================================
#
:start ::= StringNumericLiteral
lexeme default = forgiving => 1

StrWhiteSpaceopt ::= StrWhiteSpace
StrWhiteSpaceopt ::=

StringNumericLiteral ::=                                   action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_value_zero
StringNumericLiteral ::= StrWhiteSpace                     action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_value_zero
StringNumericLiteral ::= 
    StrWhiteSpaceopt StrNumericLiteral StrWhiteSpaceopt    action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_value

StrWhiteSpace ::=
  StrWhiteSpaceChar StrWhiteSpaceopt                       action => ::undef

StrWhiteSpaceChar ::=
    _WhiteSpace                                            action => ::undef
  | _LineTerminator                                        action => ::undef

StrNumericLiteral ::=
    StrDecimalLiteral                                      action => ::first
  | HexIntegerLiteral                                      action => ::first

StrDecimalLiteral ::=
    StrUnsignedDecimalLiteral                              action => ::first
  | '+' StrUnsignedDecimalLiteral                          action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_secondArg
  | '-' StrUnsignedDecimalLiteral                          action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_neg

StrUnsignedDecimalLiteral ::=
    'Infinity'                                             action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_Infinity
  | DecimalDigits '.'                                      action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_Dot
  | DecimalDigits '.' DecimalDigits                        action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_Dot_DecimalDigits
  | DecimalDigits '.' ExponentPart                         action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_Dot_ExponentPart
  | DecimalDigits '.' DecimalDigits ExponentPart           action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_Dot_DecimalDigits_ExponentPart
  | '.' DecimalDigits                                      action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_Dot_DecimalDigits
  | '.' DecimalDigits ExponentPart                         action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_Dot_DecimalDigits_ExponentPart
  | DecimalDigits                                          action => ::first
  | DecimalDigits ExponentPart                             action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_ExponentPart

DecimalDigits ::=
    DecimalDigit                                           action => ::first
  | DecimalDigits DecimalDigit                             action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigits_DecimalDigit

DecimalDigit ::= _DecimalDigit                             action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_DecimalDigit

ExponentPart ::=
  ExponentIndicator SignedInteger                          action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_secondArg

ExponentIndicator ::= _ExponentIndicator                   action => ::first

SignedInteger ::=
    DecimalDigits                                          action => ::first
  | '+' DecimalDigits                                      action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_secondArg
  | '-' DecimalDigits                                      action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_neg

HexIntegerLiteral ::=
    '0x' HexDigit                                          action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_secondArg
  | '0X' HexDigit                                          action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_secondArg
  | HexIntegerLiteral HexDigit                             action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_HexIntegerLiteral_HexDigit

HexDigit ::= _HexDigit                                     action => MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::_HexDigit

_WhiteSpace        ~ [\p{IsWhiteSpace}]
_LineTerminator    ~ [\p{IsLineTerminator}]
_DecimalDigit      ~ [\p{IsDecimalDigit}]
_ExponentIndicator ~ [\p{IseOrE}]
_HexDigit          ~ [\p{IsHexDigit}]
