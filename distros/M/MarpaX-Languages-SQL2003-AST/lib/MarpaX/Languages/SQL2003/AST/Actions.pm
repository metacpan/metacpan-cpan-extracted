use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::SQL2003::AST::Actions;
use MarpaX::Languages::SQL2003::AST::Actions::XML;
use MarpaX::Languages::SQL2003::AST::Actions::Blessed;
use Marpa::R2;
use Carp qw/croak/;
use Math::BigFloat;

# ABSTRACT: Translate SQL-2003 source to an AST - Semantic actions generic class

our $VERSION = '0.005'; # VERSION

our $SEPARATOR = <<SEPARATOR;
_WS ~ [\\s]+
<space any L0> ~ _WS
<discard> ~ <space any L0>

_COMMENT_EVERYYHERE_START ~ '--'
_COMMENT_EVERYYHERE_END ~ [^\\n]*
_COMMENT ~ _COMMENT_EVERYYHERE_START _COMMENT_EVERYYHERE_END
<SQL style comment L0> ~ _COMMENT
<discard> ~ <SQL style comment L0>

############################################################################
# Discard of a C comment, c.f. https://gist.github.com/jeffreykegler/5015057
############################################################################
<C style comment L0> ~ '/*' <comment interior> '*/'
<comment interior> ~
    <optional non stars>
    <optional star prefixed segments>
    <optional pre final stars>
<optional non stars> ~ [^*]*
<optional star prefixed segments> ~ <star prefixed segment>*
<star prefixed segment> ~ <stars> [^/*] <optional star free text>
<stars> ~ [*]+
<optional star free text> ~ [^*]*
<optional pre final stars> ~ [*]*
<discard> ~ <C style comment L0>

<discard many> ~ <discard>+

<separator> ::= <discard many>
SEPARATOR



sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

# ----------------------------------------------------------------------------------------

sub _nonTerminalSemantic { croak "Please implement the _nonTerminalSemantic method!"; }

# ----------------------------------------------------------------------------------------

sub _lexemeValue { croak "Please implement the _lexemeValue method!"; }

# ----------------------------------------------------------------------------------------

sub _lexemeStart { croak "Please implement the _lexemeStart method!"; }

# ----------------------------------------------------------------------------------------

sub _lexemeLength { croak "Please implement the _lexemeLength method!"; }

# ----------------------------------------------------------------------------------------

sub _childByIndex { croak "Please implement the _childByIndex method!"; }
sub _firstChild { my $self = shift; return $self->_childByIndex(@_, 0) }
sub _secondChild { my $self = shift; return $self->_childByIndex(@_, 1) }

# ----------------------------------------------------------------------------------------

sub _getRuleDescription {
  my ($self) = @_;

  my $rule_id     = $Marpa::R2::Context::rule;
  my $slg         = $Marpa::R2::Context::slg;
  my ($lhs, @rhs) = map { $slg->symbol_display_form($_) } $slg->rule_expand($rule_id);

  return ($lhs, @rhs);
}

# ----------------------------------------------------------------------------------------

sub _unicodeDelimitedIdentifierValue {
  my ($self, $start, $length, $text, $Unicode_Escape_Specifier_Value) = @_;

  #
  # $Unicode_Escape_Specifier_Value is in the form 'X'
  #
  if ($Unicode_Escape_Specifier_Value =~ /[a-fA-F0-9]/   # <hexit>
      ||
      $Unicode_Escape_Specifier_Value eq '+'             # <plus sign>
      ||
      $Unicode_Escape_Specifier_Value =~ /\s/            # <white space>, whatever this mean
     ) {
    croak "Unicode specifier '$Unicode_Escape_Specifier_Value' (" . sprintf("0x%x", $Unicode_Escape_Specifier_Value) . ") is not allowed";
  }
  #
  # Now that we have the unicode specifier, redo on-the-fly a grammar that is handling the full text!
  #
  $self->{Unicode_Escape_Specifier_Grammar} //= {};
  if (! defined($self->{Unicode_Escape_Specifier_Grammar}->{$Unicode_Escape_Specifier_Value})) {
    my $Unicode_Escape_Specifier_Hex = sprintf('%x', ord($Unicode_Escape_Specifier_Value));
    my $data = <<GRAMMAR;
:default ::= action => ::first
:start ::= <Unicode delimited identifier value>

<Unicode delimiter body many> ::= <Unicode delimiter body>+  separator => <separator> action => MarpaX::Languages::SQL2003::AST::Actions::_concat
<Unicode delimited identifier value> ::= ('U&':i) <Unicode delimiter body many>

<nondoublequote character> ~ [^"]
                           | [\\x{$Unicode_Escape_Specifier_Hex}] '"'

<Unicode identifier part any> ::= <Unicode identifier part>*  action => MarpaX::Languages::SQL2003::AST::Actions::_concat
<Unicode delimiter body> ::= ('"') <Unicode identifier part any> ('"')
<Unicode identifier part> ::= <Unicode delimited identifier part>
                            | <Unicode escape value>

<Unicode delimited identifier part> ::= <nondoublequote character>   action => MarpaX::Languages::SQL2003::AST::Actions::_lastChar
                                      | <doublequote symbol>

<doublequote symbol> ::= '""' action => MarpaX::Languages::SQL2003::AST::Actions::_lastChar

<Unicode escape value> ::=
                           <Unicode 4 digit escape value> action => MarpaX::Languages::SQL2003::AST::Actions::_Unicode4
                         | <Unicode 6 digit escape value> action => MarpaX::Languages::SQL2003::AST::Actions::_Unicode4
                         | <Unicode character escape value> action => MarpaX::Languages::SQL2003::AST::Actions::_UnicodeEscape

<hexit> ~ [a-fA-f0-9]

<Unicode 4 digit escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] <hexit> <hexit> <hexit> <hexit>
<Unicode 6 digit escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] '+' <hexit> <hexit> <hexit> <hexit> <hexit> <hexit>
<Unicode character escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] [\\x{$Unicode_Escape_Specifier_Hex}]

$SEPARATOR
GRAMMAR
    $self->{Unicode_Escape_Specifier_Grammar}->{$Unicode_Escape_Specifier_Value} = Marpa::R2::Scanless::G->new({source => \$data});
  }
  my $r = Marpa::R2::Scanless::R->new({grammar => $self->{Unicode_Escape_Specifier_Grammar}->{$Unicode_Escape_Specifier_Value},
                                       # trace_terminals => 1,
                                       # trace_values => 1,
                                       semantics_package => 'MarpaX::Languages::SQL2003::AST::Actions'});
  $r->read(\$text);
  #
  # Fake this is a lexeme
  #
  my $value = ${$r->value};
  #
  # Unicode stuff. Make sure this has the UTF8 flag in perl.
  # Otherwise you might hit the "error: string is not in UTF-8".
  #
  return [$start, $length, $text, $value];
}

# ----------------------------------------------------------------------------------------

sub _unicodeDelimitedIdentifier {
  my ($self, $Unicode_Delimited_Identifier_Lexeme) = @_;

  my ($start, $length, $text, $value) = @{$Unicode_Delimited_Identifier_Lexeme};

  return $self->_unicodeDelimitedIdentifierValue($start, $length, $text, '\\');
}

# ----------------------------------------------------------------------------------------

sub _unicodeDelimitedIdentifierUescape {
  my ($self, $Unicode_Delimited_Identifier_Lexeme, $separator_L0_any, $Unicode_Escape_Specifier) = @_;

  my $text = $Unicode_Delimited_Identifier_Lexeme->[2];
  #
  # $Unicode_Escape_Specifier is:
  # <Unicode_Escape_Specifier> ::= <XXX_Maybe>
  # <XXX_Maybe> ::= <XXX>
  # <XXX_Maybe> ::=
  # <XXX> ::= <UESCAPE> <LEXEME>
  # where LEXEME is the escape specifier. Constraint is:
  # Syntax rule 15: <Unicode escape character> shall be a single character
  # from the source language character set other than a <hexit>, <plus
  # sign>, or <white space>.
  my $Unicode_Escape_Specifier_Lexeme = $self->_secondChild($self->_firstChild($self->_firstChild($Unicode_Escape_Specifier)));
  my $Unicode_Escape_Specifier_Value = $self->_lexemeValue($Unicode_Escape_Specifier_Lexeme);

  my $start = $Unicode_Delimited_Identifier_Lexeme->[0];
  my $end = $self->_lexemeStart($Unicode_Escape_Specifier_Lexeme) + $self->_lexemeLength($Unicode_Escape_Specifier_Lexeme) - 1;
  my $length = $end - $start;

  substr($Unicode_Escape_Specifier_Value,  0, 1) = '';
  substr($Unicode_Escape_Specifier_Value, -1, 1) = '';

  return $self->_unicodeDelimitedIdentifierValue($start, $length, $text, $Unicode_Escape_Specifier_Value);
}

# ----------------------------------------------------------------------------------------

sub _concat {
  my ($self, @args) = @_;

  return join('', @args);
}

# ----------------------------------------------------------------------------------------

sub _lastChar {
  my ($self, $string) = @_;

  return substr($string, -1, 1);
}

# ----------------------------------------------------------------------------------------

sub _Unicode6 {
  # <Unicode 6 digit escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] '+' <hexit> <hexit> <hexit> <hexit> <hexit> <hexit>
  my ($self, $unicode) = @_;

  substr($unicode, 0, 2) = '';

  return chr(hex($unicode));
}

# ----------------------------------------------------------------------------------------

sub _Unicode4 {
  # <Unicode 4 digit escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] <hexit> <hexit> <hexit> <hexit>
  my ($self, $unicode) = @_;

  substr($unicode, 0, 1) = '';

  return chr(hex($unicode));
}

# ----------------------------------------------------------------------------------------

sub _UnicodeEscape {
  # <Unicode character escape value> ~ [\\x{$Unicode_Escape_Specifier_Hex}] [\\x{$Unicode_Escape_Specifier_Hex}]
  my ($self, $unicode) = @_;

  substr($unicode, 0, 1) = '';

  return $unicode;
}

# ----------------------------------------------------------------------------------------

sub _nationalCharacterStringLiteral {
  my ($self, $nationalCharacterStringLiteral_Lexeme) = @_;

  my ($start, $length, $text, $value) = @{$nationalCharacterStringLiteral_Lexeme};

  return $self->_nationalCharacterStringLiteralValue($start, $length, $text, '\\');
}

# ----------------------------------------------------------------------------------------

sub _nationalCharacterStringLiteralValue {
  my ($self, $start, $length, $text, $Escape_Specifier_Value) = @_;

  $self->{National_Character_String_Literal_Grammar} //= {};
  if (! defined($self->{National_Character_String_Literal_Grammar}->{$Escape_Specifier_Value})) {
    my $Escape_Specifier_Value_Hex = sprintf('%x', ord($Escape_Specifier_Value));
    my $data = <<GRAMMAR;
:default ::= action => ::first
:start ::= <National Character String Literal value>
lexeme default = latm => 1

<_quote> ~ [']
<quote> ~ <_quote>

<_notquote> ~ [^']
<notquote symbol> ~ <_notquote> | [\\x{$Escape_Specifier_Value_Hex}] <_quote>
<quote symbol> ~ <_quote> <_quote>

<inner representation> ::= <notquote symbol> | <quote symbol>

<character representation many> ::= <character representation>+  separator => <separator> action => MarpaX::Languages::SQL2003::AST::Actions::_concat
<National Character String Literal value> ::= ('N':i) <character representation many>

<character representation> ::= (<quote>) <inner> (<quote>)
<inner> ::= <inner representation>* action => MarpaX::Languages::SQL2003::AST::Actions::_concat

$SEPARATOR
GRAMMAR
    $self->{National_Character_String_Literal_Grammar}->{$Escape_Specifier_Value} = Marpa::R2::Scanless::G->new({source => \$data});
  }
  my $r = Marpa::R2::Scanless::R->new({grammar => $self->{National_Character_String_Literal_Grammar}->{$Escape_Specifier_Value},
                                       # trace_terminals => 1,
                                       # trace_values => 1,
                                       semantics_package => 'MarpaX::Languages::SQL2003::AST::Actions'});
  $r->read(\$text);
  #
  # Fake this is a lexeme
  #
  my $value = ${$r->value};
  #
  # Unicode stuff. Make sure this has the UTF8 flag in perl.
  # Otherwise you might hit the "error: string is not in UTF-8".
  #
  return [$start, $length, $text, $value];
}

# ----------------------------------------------------------------------------------------

sub _characterStringLiteral {
  my ($self, $characterStringLiteral_Lexeme) = @_;

  my ($start, $length, $text, $value) = @{$characterStringLiteral_Lexeme};

  return $self->_characterStringLiteralValue($start, $length, $text, '\\');
}

# ----------------------------------------------------------------------------------------

sub _characterStringLiteralValue {
  my ($self, $start, $length, $text, $Escape_Specifier_Value) = @_;

  $self->{Character_String_Literal_Grammar} //= {};
  if (! defined($self->{Character_String_Literal_Grammar}->{$Escape_Specifier_Value})) {
    my $Escape_Specifier_Value_Hex = sprintf('%x', ord($Escape_Specifier_Value));
    my $data = <<GRAMMAR;
:default ::= action => ::first
:start ::= <Character String Literal value>
lexeme default = latm => 1        # LATM is important here because <set name> and <character representation> compete each other

<_quote> ~ [']
<quote> ~ <_quote>

<_notquote> ~ [^']
<notquote symbol> ~ <_notquote> | [\\x{$Escape_Specifier_Value_Hex}] <_quote>
<quote symbol> ~ <_quote> <_quote>

<character representation many> ::= <character representation>+  separator => <separator> action => MarpaX::Languages::SQL2003::AST::Actions::_concat

<_period> ~ '.'
<_simple latin letter> ~ [a-zA-Z]
<_digit> ~ [0-9]
<_identifier start> ~ <_simple latin letter>
<_identifier part> ~  <_simple latin letter> | <_digit>
<_identifier part many> ~ <_identifier part>+

<_schema name> ~ <_catalog name> <_period> <_unqualified schema name> | <_unqualified schema name>
<_unqualified schema name> ~ <_identifier>
<_catalog name> ~ <_identifier>

<_identifier> ~ <_identifier start> <_identifier part many>

<set name> ~ <_schema name> <_period> <_identifier> | <_identifier>

<Character String Literal introducer> ::= ('_':i) <set name>

<Character String Literal value> ::= <Character String Literal introducer> <character representation many> action => MarpaX::Languages::SQL2003::AST::Actions::_characterStringLiteralWithIntroducer
                                   |
                                   <character representation many> action => MarpaX::Languages::SQL2003::AST::Actions::_characterStringLiteralWithoutIntroducer

<character representation> ::= (<quote>) <inner> (<quote>)
<inner> ::= <inner representation>* action => MarpaX::Languages::SQL2003::AST::Actions::_concat
<inner representation> ::= <notquote symbol> | <quote symbol>

$SEPARATOR
GRAMMAR
    $self->{Character_String_Literal_Grammar}->{$Escape_Specifier_Value} = Marpa::R2::Scanless::G->new({source => \$data});
  }
  my $r = Marpa::R2::Scanless::R->new({grammar => $self->{Character_String_Literal_Grammar}->{$Escape_Specifier_Value},
                                       # trace_terminals => 1,
                                       # trace_values => 1,
                                       semantics_package => 'MarpaX::Languages::SQL2003::AST::Actions'});
  $r->read(\$text);
  #
  # Fake this is a lexeme.
  # Here the value is guaranteed to be an array reference containing:
  # ['introducer', $introducerValue, $text]
  # where $introducerValue can be an empty string
  #
  my $arrayp = ${$r->value};

  my ($label, $introducerValue, $value) = @{$arrayp};
  #
  # Unicode stuff. Make sure this has the UTF8 flag in perl.
  # Otherwise you might hit the "error: string is not in UTF-8".
  #
  return [$start, $length, $text, $value, $label, $introducerValue];
}

# ----------------------------------------------------------------------------------------

sub _characterStringLiteralWithIntroducer {
  my ($self, $introducer, $value) = @_;
  # Internal action
  return ['introducer', $introducer, $value];
}

# ----------------------------------------------------------------------------------------

sub _characterStringLiteralWithoutIntroducer {
  my ($self, $value) = @_;
  # Internal action
  return ['introducer', '', $value];
}

# ----------------------------------------------------------------------------------------

sub _unsignedNumericLiteral {
  my ($self, $lexeme) = @_;

  my ($start, $length, $text, $value) = @{$lexeme};

  return [$start, $length, $text, Math::BigFloat->new("$value")->bstr()];
}

# ----------------------------------------------------------------------------------------


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::SQL2003::AST::Actions - Translate SQL-2003 source to an AST - Semantic actions generic class

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This modules give a semantic actions generic class associated to SQL-2003 grammar

The following rules have dedicated semantics:

=over

=item Unicode Delimited Identifier

Syntax is U&"..." "..." [UESCAPE '.'] and is considered as a whole token. The value is the unicode string concatenation with respect to UESCAPE character.

=item Character String Literal

Syntax is an eventual introducer followed by the string. The value is the string, and and extra attribute "introducer" is created.

=item National Character String Literal

Syntax is a succession of N'...'. The value is the string concatenation.

=item Unsigned Numeric Literal

The value is the perl's Math::BigFloat string representation.

=back

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new object of the class $class.

=head1 SEE ALSO

L<MarpaX::Languages::SQL2003::AST>, L<MarpaX::Languages::SQL2003::AST::Actions::Blessed>, L<MarpaX::Languages::SQL2003::AST::Actions::XML>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
