#
# Here is the exhaustive list of difficulties with the ECMAScript grammar:
#
# * The list of reserved keywords is context sensitive (depend on strict mode)
# * The source CAN be not ok v.s. semi-colon: automatic semi-colon insertion will then happen
# * Allowed separators is contextual (sometimes no line terminator is allowed)
# * RegularExpressionLiteral ambiguity with AssignmentExpression or MultiplicativeExpression
#
use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program::Semantics;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::RegularExpressionLiteral;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::NumericLiteral;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;
use MarpaX::Languages::ECMAScript::AST::Exceptions qw/:all/;
#use Log::Any qw/$log/;
use SUPER;

# ABSTRACT: ECMAScript-262, Edition 5, lexical program grammar written in Marpa BNF

our $VERSION = '0.020'; # VERSION

our $WhiteSpace        = qr/(?:[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsWhiteSpace}])/;
our $LineTerminator    = qr/(?:[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsLineTerminator}])/;
our $SingleLineComment = qr/(?:\/\/[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsSourceCharacterButNotLineTerminator}]*)/;
our $MultiLineComment  = qr/(?:(?:\/\*)(?:(?:[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsSourceCharacterButNotStar}]+|\*(?![\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsSourceCharacterButNotSlash}]))*)(?:\*\/))/;
our $UnicodeLetter = qr/[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsUnicodeLetter}]/;
our $HexDigit4 = qr/[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsHexDigit}]{4}/;

our $S                 = qr/(?:$WhiteSpace|$LineTerminator|$SingleLineComment|$MultiLineComment)/;
our $isPostLineTerminatorLength = qr/\G$S+/;
our $isPreSLength = qr/\G$S+/;
our $isRcurly = qr/\G$S*\}/;
our $isEnd = qr/\G$S*$/;
our $isDecimalDigit = qr/\G[\p{MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses::IsDecimalDigit}]/;
our $isIdentifierStart = qr/\G(?:$UnicodeLetter|\$|_|\\u$HexDigit4)/;
our @Keyword =
    qw/break      do       instanceof typeof
       case       else     new        var
       catch      finally  return     void
       continue   for      switch     while
       debugger   function this       with
       default    if       throw
       delete     in       try/;

our @FutureReservedWord =
    qw/class      enum     extends    super
       const      export   import/;

our @FutureReservedWordStrict =
    qw/implements let      private    public    yield
       interface  package  protected  static/;

our @NullLiteral = qw/null/;

our @BooleanLiteral = qw/true false/;

#
# Force eventual higher priority
#
our %PRIORITY = (FUNCTION => 2);

our $grammar_content = do {local $/; <DATA>};

#
# It is clearer to have reserved words in an array. But for efficienvy the hash is better,
# so I create on-the-fly associated hashes using the arrays. Convention is: the lexeme name of
# a reserved word is this word, but in capital letters (since none of them is in capital letter)
#
our %Keyword                  = map {($_, uc($_))} @Keyword;
our %FutureReservedWord       = map {($_, uc($_))} @FutureReservedWord;
our %FutureReservedWordStrict = map {($_, uc($_))} @FutureReservedWordStrict;
our %NullLiteral              = map {($_, uc($_))} @NullLiteral;
our %BooleanLiteral           = map {($_, uc($_))} @BooleanLiteral;

#
# ... And we inject in the grammar those that exist (FutureReservedWord do not)
#
$grammar_content .= "\n";
# ... Priorities
map {$grammar_content .= ":lexeme ~ <$_> priority => " . ($PRIORITY{$_} || 1) . "\n"} values %Keyword;
map {$grammar_content .= ":lexeme ~ <$_> priority => " . ($PRIORITY{$_} || 1) . "\n"} values %NullLiteral;
map {$grammar_content .= ":lexeme ~ <$_> priority => " . ($PRIORITY{$_} || 1) . "\n"} values %BooleanLiteral;
# ... Definition
map {$grammar_content .= uc($_) . " ~ '$_'\n"} @Keyword;
map {$grammar_content .= uc($_) . " ~ '$_'\n"} @NullLiteral;
map {$grammar_content .= uc($_) . " ~ '$_'\n"} @BooleanLiteral;
#
# Injection of grammars.
#
our $StringLiteral = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::StringLiteral->new();
our $RegularExpressionLiteral = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::RegularExpressionLiteral->new();
our $NumericLiteral = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Lexical::NumericLiteral->new();
$grammar_content .= $StringLiteral->extract;
$grammar_content .= $NumericLiteral->extract;
$grammar_content .= $RegularExpressionLiteral->extract;

#
# For convenience in the IDENTIFIER$ lexeme callback, we merge Keyword, FutureReservedWord, NullLiteral, BooleanLiteral into
# a single hash ReservedWord.
#
our %ReservedWord = map {$_ => 1} (keys %Keyword, keys %FutureReservedWord, keys %NullLiteral, keys %BooleanLiteral);



sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
}


sub make_semantics_package {
    my ($class) = @_;
    return join('::', $class, 'Semantics');
}


sub spacesAny {
    my $self = shift;
    if (@_) {
	$self->{_spacesAny} = shift;
    }
    return $self->{_spacesAny};
}


sub parse {
    my ($self, $source, $impl) = @_;
    #
    # Because of Automatic Semicolon Insertion that may happen at the end,
    # a space is appended to a copy of the source to be parsed.
    #
    $self->{programCompleted} = 0;
    $source .= ' ';
    return $self->SUPER($source, $impl,
                        {
                         callback => \&_eventCallback,
                         callbackargs => [ $self ],
                         failure => \&_failureCallback,
                         failureargs => [ $self ],
                         end => \&_endCallback,
                         endargs => [ $self ],
                        });
}

sub _eventCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  #
  # $pos is the exact position where SLIF stopped because of an event
  #
  my $rc = $pos;
  my %lastLexeme = ();
  my $lastLexemeDoneb = 0;

  #
  # Cache of some call results
  #
  $self->{_isIdentifierStart} = {};
  $self->{_isDecimalDigit} = {};
  $self->{_preSLength} = {};
  $self->{_isEnd} = {};
  $self->{_postLineTerminatorLength} = {};

  foreach (@{$impl->events()}) {
    my ($name) = @{$_};
    #
    # Events are always in this order:
    #
    # ---------------------------------
    # 1. Completion events first (XXX$)
    # ---------------------------------
    #
    if ($name eq 'Program$') {
	#
	# Program$ will happen rarely, so even it does cost it is ok to do so
	#
	$self->{programCompleted} = ($self->{_isEnd}->{$pos} //= $self->_isEnd($source, $pos, $impl));
    }
    elsif ($name eq 'NumericLiteral$') {
      #
      # The source character immediately following a NumericLiteral must not be
      # an IdentifierStart or DecimalDigit
      #
      if (($self->{_isIdentifierStart}->{$pos} //= $self->_isIdentifierStart($source, $pos, $impl)) ||
          ($self->{_isDecimalDigit}->{$pos} //= $self->_isDecimalDigit($source, $pos, $impl))) {
        my ($start, $end) = $impl->last_completed_range('NumericLiteral');
        my $lastNumericLiteral = $impl->range_to_string($start, $end);
        SyntaxError(error => "NumericLiteral $lastNumericLiteral must not be immediately followed by an IdentifierStart or DecimalDigit");
      }
    }
    elsif ($name eq 'IDENTIFIER$') {
	if (! $lastLexemeDoneb) {
	    $self->getLastLexeme(\%lastLexeme, $impl);
	    $lastLexemeDoneb = 1;
	}
	if (exists($ReservedWord{$lastLexeme{value}})) {
	    SyntaxError(error => "Identifier $lastLexeme{value} is a reserved word");
	}
    }
    #
    # ------------------------
    # 2. nulled events (XXX[])
    # ------------------------
    #
    # ------------------------------------
    # 3. prediction events (^XXX or ^^XXX)
    # ------------------------------------
    #
    elsif ($name eq '^INVISIBLE_SEMICOLON') {
      #
      # In the AST, we explicitely associate the ';' to the missing semicolon
      #
	if (! $lastLexemeDoneb) {
	    $self->getLastLexeme(\%lastLexeme, $impl);
	    $lastLexemeDoneb = 1;
	}
	my $Slength = ($self->{_preSLength}->{$rc} //= $self->_preSLength($source, $rc, $impl));
	$self->_insertInvisibleSemiColon($impl, $rc, $Slength);
	$rc += $Slength;
    }
    #
    # ^PLUSPLUS_POSTFIX, ^MINUSMINUS_POSTFIX
    # --------------------------------------
    elsif ($name eq '^PLUSPLUS_POSTFIX' || $name eq '^MINUSMINUS_POSTFIX') {
	if (! $lastLexemeDoneb) {
	    $self->getLastLexeme(\%lastLexeme, $impl);
	    $lastLexemeDoneb = 1;
	}
      my $postLineTerminatorPos = $lastLexeme{start} + $lastLexeme{length};
      my $postLineTerminatorLength = ($self->{_postLineTerminatorLength}->{$postLineTerminatorPos} //= $self->_postLineTerminatorLength($source, $postLineTerminatorPos, $impl));
      my $asi = 0;
      if ($postLineTerminatorLength > 0) {
	  if (! $impl->lexeme_read('SEMICOLON', $postLineTerminatorPos, $postLineTerminatorLength, ';')) {
	      SyntaxError(error => "SEMICOLON lexeme_read failure at position $rc");
	  }
	  $asi = 1;
      }
      my $lname = $name;
      substr($lname, 0, 1, '');
      my $lvalue = ($lname eq 'PLUSPLUS_POSTFIX') ? '++' : '--';
      #
      # The value does not change if ASI was performed. But the name, yes.
      #
      if ($asi) {
	  $lname = ($lname eq 'PLUSPLUS_POSTFIX') ? 'PLUSPLUS' : 'MINUSMINUS';
      }
      if (! $impl->lexeme_read($lname, $rc, 2, $lvalue)) {
	  SyntaxError(error => "$lname lexeme_read failure at position $rc");
      }
      $rc += 2;
    }
    #
    # ^^DIV (because of REGULAREXPRESSIONLITERAL that can eat it)
    # -----------------------------------------------------------
    elsif ($name eq '^^DIV') {
	my $realpos = $rc + ($self->{_preSLength}->{$rc} //= $self->_preSLength($source, $rc, $impl));
      if (index($source, '/',  $realpos) == $realpos &&
          index($source, '/=', $realpos) != $realpos &&
          index($source, '//', $realpos) != $realpos &&
          index($source, '/*', $realpos) != $realpos) {
        if (! $impl->lexeme_read('DIV', $realpos, 1, '/')) {
	    SyntaxError(error => "DIV lexeme_read failure at position $rc");
	}
        $rc = $realpos + 1;
      }
    }
    #
    # ^^DIVASSIGN  (because of REGULAREXPRESSIONLITERAL that can eat it)
    # ------------------------------------------------------------------
    elsif ($name eq '^^DIVASSIGN') {
	my $realpos = $rc + ($self->{_preSLength}->{$rc} //= $self->_preSLength($source, $rc, $impl));
      if (index($source, '/=', $realpos) == $realpos &&
          index($source, '//', $realpos) != $realpos &&
          index($source, '/*', $realpos) != $realpos) {
        if (! $impl->lexeme_read('DIVASSIGN', $realpos, 2, '/=')) {
	    SyntaxError(error => "DIVASSIGN lexeme_read failure at position $rc");
	}
        $rc = $realpos + 2;
      }
    }
  }

  #
  # Remove cache
  #
  delete($self->{_isIdentifierStart});
  delete($self->{_isDecimalDigit});
  delete($self->{_preSLength});
  delete($self->{_isEnd});
  delete($self->{_postLineTerminatorLength});

  #if ($rc != $pos) {
  #  $log->tracef('[_eventCallback] Resuming at position %d (was %d when called)', $rc, $pos);
  #}

  return $rc;
}

sub _postLineTerminatorLength {
    # my ($self, $source, $pos, $impl) = @_;

  my $rc = 0;

  my $prevpos = pos($_[1]);
  pos($_[1]) = $_[2];

  #
  # Take care: the separator is:  _WhiteSpace | _LineTerminator | _SingleLineComment | _MultiLineComment
  # where a _MultiLineComment that contains a _LineTerminator is considered equivalent to a _LineTerminator
  #
  # This is why if we find a separator just before $pos, we check again the presence of _LineTerminator in the match
  #
  if ($_[1] =~ $isPostLineTerminatorLength) {
    my $length = $+[0] - $-[0];
    if (substr($_[1], $-[0], $length) =~ /$LineTerminator/) {
      $rc = $length;
    }
  }

  #if ($rc > 0) {
  #  $log->tracef('[_postLineTerminatorLength] Found postLineTerminator of length %d', $rc);
  #}

  pos($_[1]) = $prevpos;

  return $rc;
}

sub _preSLength {
    # my ($self, $source, $pos, $impl) = @_;

  my $rc = 0;

  my $prevpos = pos($_[1]);
  pos($_[1]) = $_[2];

  if ($_[1] =~ $isPreSLength) {
    my $length = $+[0] - $-[0];
    $rc = $length;
  }

  #if ($rc > 0) {
  #  $log->tracef('[_preSLength] Found S of length %d', $rc);
  #}

  pos($_[1]) = $prevpos;

  return $rc;
}

sub _isRcurly {
    # my ($self, $source, $pos, $impl) = @_;

  my $rc = 0;

  my $prevpos = pos($_[1]);
  pos($_[1]) = $_[2];

  if ($_[1] =~ $isRcurly) {
    $rc = 1;
  }

  #if ($rc) {
  #  $log->tracef('[_isRcurly] Found \'}\'');
  #}

  pos($_[1]) = $prevpos;

  return $rc;
}

sub _isIdentifierStart {
    # my ($self, $source, $pos, $impl) = @_;

  my $rc = 0;

  my $prevpos = pos($_[1]);
  pos($_[1]) = $_[2];

  if ($_[1] =~ $isIdentifierStart) {
    $rc = 1;
  }

  #if ($rc) {
  #  $log->tracef('[_isIdentifierStart] Found \'%s\'', $&);
  #}

  pos($_[1]) = $prevpos;

  return $rc;
}

sub _isDecimalDigit {
    # my ($self, $source, $pos, $impl) = @_;

  my $rc = 0;

  my $prevpos = pos($_[1]);
  pos($_[1]) = $_[2];

  if ($_[1] =~ $isDecimalDigit) {
    $rc = 1;
  }

  #if ($rc) {
  #  $log->tracef('[_isDecimalDigit] Found \'%s\'', $&);
  #}

  pos($_[1]) = $prevpos;

  return $rc;
}

sub _isEnd {
    # my ($self, $source, $pos, $impl) = @_;

    my $grammar     = $_[0]->spacesAny->{grammar};
    my $impl        = $_[0]->spacesAny->{impl};
    $grammar->parse($_[1], $impl, $_[2]);
    return $grammar->endReached;
}

sub _insertSemiColon {
  my ($self, $impl, $pos, $length) = @_;

  if (! $impl->lexeme_read('SEMICOLON', $pos, $length, ';')) {
    SyntaxError(error => "Automatic Semicolon Insertion not allowed at position $pos");
  }
}

sub _insertInvisibleSemiColon {
  my ($self, $impl, $pos, $length) = @_;

  if (! $impl->lexeme_read('INVISIBLE_SEMICOLON', $pos, $length, ';')) {
    SyntaxError(error => "Automatic Invisible Semicolon Insertion not allowed at position $pos");
  }
}

sub _failureCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  #
  # The position of failure is exactly the end of the very last lexeme
  #
  my %lastLexeme = ();
  $self->getLastLexeme(\%lastLexeme, $impl);
  my $rc = $lastLexeme{start} + $lastLexeme{length};

  #
  # Automatic Semicolon Insertion rules apply here
  #
  # 1. When, as the program is parsed from left to right, a token
  # (called the offending token) is encountered that is not allowed
  # by any production of the grammar, then a semicolon is automatically
  # inserted before the offending token if one or more of the following conditions is true:
  # - The offending token is separated from the previous token by at least one LineTerminator.
  # - The offending token is }.
  #
  my $length = 0;
  if (($length = $self->_postLineTerminatorLength($source, $rc, $impl)) > 0) {
    $self->_insertSemiColon($impl, $rc, $length);
    $rc += $length;
  } elsif ($self->_isRcurly($source, $rc, $impl)) {
    $self->_insertSemiColon($impl, $rc, 1);
  } else {
    SyntaxError();
  }

  return $rc;
}

sub _endCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  if ($self->{programCompleted}) {
      return;
  }

  #
  # Automatic Semicolon Insertion rules apply here
  #
  # 2. When, as the program is parsed from left to right, the end of the input stream of tokens
  #    is encountered and the parser is unable to parse the input token stream as a single complete ECMAScript Program
  #    then a semicolon is automatically inserted at the end of the input stream.
  #
  if (! $self->{programCompleted}) {
      my %lastLexeme = ();
      $self->getLastLexeme(\%lastLexeme, $impl);
      my $lastValidPos = $lastLexeme{start} + $lastLexeme{length};
      $self->_insertSemiColon($impl, $lastValidPos, 1);
      my $haveProgramCompletion = grep {$_ eq 'Program$'} map {$_->[0]} @{$impl->events};
      if (! $haveProgramCompletion) {
	  SyntaxError(error => "Incomplete program");
      }
  }
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program - ECMAScript-262, Edition 5, lexical program grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Program->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 lexical program grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>. This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package.

=head1 SUBROUTINES/METHODS

=head2 make_grammar_content($class)

Returns the grammar. This will be injected in the Program's grammar.

=head2 semantics_package($class)

Class method that returns Program default recce semantics_package. These semantics are adding ruleId to all values, and execute eventually StringLiteral lexical grammar.

=head2 spacesAny($self, $spacesAny)

Getter/Setter of a SpacesAny grammar implementation, used internally by the Program grammar.

=head2 parse($self, $source, $impl)

Parse the source given as $source using implementation $impl.

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
:start ::= Program
:default ::= action => valuesAndRuleId # bless => ::lhs
lexeme default = action => [start,length,value] forgiving => 1 

#
# Literal definition as per lexical grammar
#
Literal ::=
    NullLiteral
  | BooleanLiteral
  | NumericLiteral
  | StringLiteral
  | RegularExpressionLiteral

PrimaryExpression ::=
    THIS
  | IDENTIFIER
  | Literal
  | ArrayLiteral
  | ObjectLiteral
  | LPAREN  Expression  RPAREN

ArrayLiteral ::=
    LBRACKET  Elisionopt  RBRACKET
  | LBRACKET  ElementList  RBRACKET
  | LBRACKET  ElementList  COMMA  Elisionopt  RBRACKET

ElementList ::=
    Elisionopt  AssignmentExpression
  | ElementList  COMMA  Elisionopt  AssignmentExpression

Elision ::=
    COMMA
  | Elision  COMMA

Elisionopt ::= Elision
Elisionopt ::=

ObjectLiteral ::=
    LCURLY  RCURLY
  | LCURLY  PropertyNameAndValueList  RCURLY
  | LCURLY  PropertyNameAndValueList  COMMA RCURLY

PropertyNameAndValueList ::=
    PropertyAssignment
  | PropertyNameAndValueList  COMMA  PropertyAssignment

PropertyAssignment ::=
    PropertyName  COLON  AssignmentExpression
  | GET  PropertyName  LPAREN                           RPAREN  LCURLY  FunctionBody  RCURLY
  | SET  PropertyName  LPAREN  PropertySetParameterList RPAREN  LCURLY  FunctionBody  RCURLY

PropertyName ::=
    IDENTIFIERNAME
  | StringLiteral
  | NumericLiteral

PropertySetParameterList ::=
    IDENTIFIER

MemberExpression ::=
    PrimaryExpression
  | FunctionExpression
  | MemberExpression  LBRACKET  Expression  RBRACKET
  | MemberExpression  DOT  IDENTIFIERNAME
  | NEW  MemberExpression  Arguments

NewExpression ::=
    MemberExpression
  | NEW  NewExpression

CallExpression ::=
    MemberExpression  Arguments
  | CallExpression  Arguments
  | CallExpression  LBRACKET  Expression  RBRACKET
  | CallExpression  DOT  IDENTIFIERNAME

Arguments ::=
    LPAREN  RPAREN
  | LPAREN  ArgumentList  RPAREN

ArgumentList ::=
    AssignmentExpression
  | ArgumentList  COMMA  AssignmentExpression

LeftHandSideExpression ::=
    NewExpression
  | CallExpression

PostfixExpression ::=
    LeftHandSideExpression
  | LeftHandSideExpression PLUSPLUS_POSTFIX
  | LeftHandSideExpression MINUSMINUS_POSTFIX

UnaryExpression ::=
    PostfixExpression
  | DELETE  UnaryExpression
  | VOID  UnaryExpression
  | TYPEOF  UnaryExpression
  | PLUSPLUS  UnaryExpression
  | MINUSMINUS  UnaryExpression
  | PLUS  UnaryExpression
  | MINUS  UnaryExpression
  | INVERT  UnaryExpression
  | NOT  UnaryExpression

MultiplicativeExpression ::=
    UnaryExpression
  | MultiplicativeExpression  MUL  UnaryExpression
  | MultiplicativeExpression  DIV  UnaryExpression
  | MultiplicativeExpression  MODULUS  UnaryExpression

AdditiveExpression ::=
    MultiplicativeExpression
  | AdditiveExpression  PLUS  MultiplicativeExpression
  | AdditiveExpression  MINUS  MultiplicativeExpression

ShiftExpression ::=
    AdditiveExpression
  | ShiftExpression  LEFTMOVE   AdditiveExpression
  | ShiftExpression  RIGHTMOVE   AdditiveExpression
  | ShiftExpression  RIGHTMOVEFILL  AdditiveExpression

RelationalExpression ::=
    ShiftExpression
  | RelationalExpression  LT           ShiftExpression
  | RelationalExpression  GT           ShiftExpression
  | RelationalExpression  LE          ShiftExpression
  | RelationalExpression  GE          ShiftExpression
  | RelationalExpression  INSTANCEOF  ShiftExpression
  | RelationalExpression  IN          ShiftExpression

RelationalExpressionNoIn ::=
    ShiftExpression
  | RelationalExpressionNoIn  LT           ShiftExpression
  | RelationalExpressionNoIn  GT           ShiftExpression
  | RelationalExpressionNoIn  LE          ShiftExpression
  | RelationalExpressionNoIn  GE          ShiftExpression
  | RelationalExpressionNoIn  INSTANCEOF  ShiftExpression

EqualityExpression ::=
    RelationalExpression
  | EqualityExpression  EQ   RelationalExpression
  | EqualityExpression  NE   RelationalExpression
  | EqualityExpression  STRICTEQ  RelationalExpression
  | EqualityExpression  STRICTNE  RelationalExpression

EqualityExpressionNoIn ::=
    RelationalExpressionNoIn
  | EqualityExpressionNoIn  EQ   RelationalExpressionNoIn
  | EqualityExpressionNoIn  NE   RelationalExpressionNoIn
  | EqualityExpressionNoIn  STRICTEQ  RelationalExpressionNoIn
  | EqualityExpressionNoIn  STRICTNE  RelationalExpressionNoIn

BitwiseANDExpression ::=
    EqualityExpression
  | BitwiseANDExpression  BITAND  EqualityExpression

BitwiseANDExpressionNoIn ::=
    EqualityExpressionNoIn
  | BitwiseANDExpressionNoIn  BITAND  EqualityExpressionNoIn

BitwiseXORExpression ::=
    BitwiseANDExpression
  | BitwiseXORExpression  BITXOR  BitwiseANDExpression

BitwiseXORExpressionNoIn ::=
    BitwiseANDExpressionNoIn
  | BitwiseXORExpressionNoIn  BITXOR  BitwiseANDExpressionNoIn

BitwiseORExpression ::=
    BitwiseXORExpression
  | BitwiseORExpression  BITOR  BitwiseXORExpression

BitwiseORExpressionNoIn ::=
    BitwiseXORExpressionNoIn
  | BitwiseORExpressionNoIn  BITOR  BitwiseXORExpressionNoIn

LogicalANDExpression ::=
    BitwiseORExpression
  | LogicalANDExpression  AND  BitwiseORExpression

LogicalANDExpressionNoIn ::=
    BitwiseORExpressionNoIn
  | LogicalANDExpressionNoIn  AND  BitwiseORExpressionNoIn

LogicalORExpression ::=
    LogicalANDExpression
  | LogicalORExpression  OR  LogicalANDExpression

LogicalORExpressionNoIn ::=
    LogicalANDExpressionNoIn
  | LogicalORExpressionNoIn  OR  LogicalANDExpressionNoIn

ConditionalExpression ::=
    LogicalORExpression
  | LogicalORExpression  QUESTION_MARK  AssignmentExpression  COLON  AssignmentExpression

ConditionalExpressionNoIn ::=
    LogicalORExpressionNoIn
  | LogicalORExpressionNoIn  QUESTION_MARK  AssignmentExpression  COLON  AssignmentExpressionNoIn

AssignmentExpression ::=
    ConditionalExpression
  | LeftHandSideExpression  ASSIGN  AssignmentExpression
  | LeftHandSideExpression  AssignmentOperator  AssignmentExpression

AssignmentExpressionNoIn ::=
    ConditionalExpressionNoIn
  | LeftHandSideExpression  ASSIGN  AssignmentExpressionNoIn
  | LeftHandSideExpression  AssignmentOperator  AssignmentExpressionNoIn

AssignmentOperator ::=
    MULASSIGN
  | DIVASSIGN
  | MODULUSASSIGN
  | PLUSASSIGN
  | MINUSASSIGN
  | LEFTMOVEASSIGN
  | RIGHTMOVEASSIGN
  | RIGHTMOVEFILLASSIGN
  | BITANDASSIGN
  | BITXORASSIGN
  | BITORASSIGN

Expression ::=
    AssignmentExpression
  | Expression  COMMA  AssignmentExpression

ExpressionNoIn ::=
    AssignmentExpressionNoIn
  | ExpressionNoIn  COMMA  AssignmentExpressionNoIn

Statement ::=
    Block
  | VariableStatement
  | EmptyStatement
  | ExpressionStatement
  | IfStatement
  | IterationStatement
  | ContinueStatement
  | BreakStatement
  | ReturnStatement
  | WithStatement
  | LabelledStatement
  | SwitchStatement
  | ThrowStatement
  | TryStatement
  | DebuggerStatement

Block ::=
    LCURLY_BLOCK  StatementListopt  RCURLY

StatementList ::=
    Statement
  | StatementList  Statement

VariableStatement ::=
    VAR  VariableDeclarationList  SEMICOLON

VariableDeclarationList ::=
    VariableDeclaration
  | VariableDeclarationList  COMMA  VariableDeclaration

VariableDeclarationListNoIn ::=
    VariableDeclarationNoIn
  | VariableDeclarationListNoIn  COMMA  VariableDeclarationNoIn

VariableDeclaration ::=
    IDENTIFIER  Initialiseropt

VariableDeclarationNoIn ::=
    IDENTIFIER  InitialiserNoInopt

Initialiseropt ::= Initialiser
Initialiseropt ::=

Initialiser ::=
    ASSIGN  AssignmentExpression

InitialiserNoInopt ::= InitialiserNoIn
InitialiserNoInopt ::=

InitialiserNoIn ::=
    ASSIGN  AssignmentExpressionNoIn

EmptyStatement ::=
    VISIBLE_SEMICOLON

#
# A note in the spec says:
#
# An ExpressionStatement cannot start with an opening curly brace because that might
# make it ambiguous with a Block.
# Also, an ExpressionStatement cannot start with the function keyword because that might
# make it ambiguous with a FunctionDeclaration.
#
# To solve this:
# - we associate an explicit lexeme to Block with priority 2: LCURLY_BLOCK
# - we explicitely raise the priority of 'function' keyword to 2 as well
#
ExpressionStatement ::=
    Expression  SEMICOLON # [lookahead not in LCURLY, 'function']

#
# There is the usual ambiguity if/else/else here.
# Two ways to solve it:
# * use right recursion
# * use Marpa's rank facility
#
IfStatement ::=
    IF  LPAREN  Expression  RPAREN  Statement  ELSE  Statement
  | IF  LPAREN  Expression  RPAREN  Statement                               rank => 1

ExpressionNoInopt ::= ExpressionNoIn
ExpressionNoInopt ::=

Expressionopt ::= Expression
Expressionopt ::=

IterationStatement ::=
    DO  Statement  WHILE  LPAREN  Expression  RPAREN  SEMICOLON
  | WHILE  LPAREN  Expression  RPAREN  Statement
  | FOR  LPAREN  ExpressionNoInopt VISIBLE_SEMICOLON  Expressionopt VISIBLE_SEMICOLON  Expressionopt  RPAREN  Statement
  | FOR  LPAREN  VAR  VariableDeclarationListNoIn  VISIBLE_SEMICOLON  Expressionopt  VISIBLE_SEMICOLON  Expressionopt  RPAREN  Statement
  | FOR  LPAREN  LeftHandSideExpression  IN  Expression  RPAREN  Statement
  | FOR  LPAREN  VAR  VariableDeclarationNoIn  IN  Expression  RPAREN  Statement

ContinueStatement ::=
    CONTINUE           SEMICOLON
  | CONTINUE INVISIBLE_SEMICOLON
  | CONTINUE IDENTIFIER           SEMICOLON

BreakStatement ::=
    BREAK           SEMICOLON
  | BREAK INVISIBLE_SEMICOLON
  | BREAK IDENTIFIER           SEMICOLON

ReturnStatement ::=
    RETURN           SEMICOLON
  | RETURN INVISIBLE_SEMICOLON
  | RETURN Expression           SEMICOLON

WithStatement ::=
    WITH  LPAREN  Expression  RPAREN  Statement

SwitchStatement ::=
    SWITCH  LPAREN  Expression  RPAREN  CaseBlock

CaseBlock ::=
      LCURLY  CaseClausesopt  RCURLY
    | LCURLY  CaseClausesopt  DefaultClause  CaseClausesopt  RCURLY

CaseClausesopt ::= CaseClauses
CaseClausesopt ::= rank => 1

CaseClauses ::=
    CaseClause
  | CaseClauses  CaseClause

CaseClause ::=
    CASE  Expression  COLON  StatementListopt

StatementListopt ::= StatementList
StatementListopt ::=

DefaultClause ::=
    DEFAULT  COLON  StatementListopt

LabelledStatement ::=
    IDENTIFIER  COLON  Statement

ThrowStatement ::=
      THROW Expression SEMICOLON

TryStatement ::=
    TRY  Block  Catch
  | TRY  Block  Finally
  | TRY  Block  Catch  Finally

Catch ::=
    CATCH  LPAREN  IDENTIFIER  RPAREN  Block

Finally ::=
    FINALLY  Block

DebuggerStatement ::=
    DEBUGGER  SEMICOLON

FunctionDeclaration ::=
    FUNCTION  IDENTIFIER  LPAREN  FormalParameterListopt  RPAREN  LCURLY  FunctionBody  RCURLY

Identifieropt ::= IDENTIFIER
Identifieropt ::=

FunctionExpression ::=
    FUNCTION  Identifieropt  LPAREN  FormalParameterListopt  RPAREN  LCURLY  FunctionBody  RCURLY

FormalParameterListopt ::= FormalParameterList
FormalParameterListopt ::=

FormalParameterList ::=
    IDENTIFIER
  | FormalParameterList  COMMA  IDENTIFIER

SourceElementsopt ::= SourceElements
SourceElementsopt ::=

FunctionBody ::=
    SourceElementsopt

Program ::=
     SourceElementsopt
event 'Program$' = completed <Program>

SourceElements ::=
    SourceElement
  | SourceElements  SourceElement

SourceElement ::=
    Statement
  | FunctionDeclaration

#
# "space":
# - We distinguish explicitely spaces containing a LineTerminator v.s. spaces without a LineTerminator
#   + Without LineTerminator:
_SNOLT ~
    _WhiteSpace
  | _SingleLineComment
  | _MultiLineCommentWithoutLineTerminator

#   + With LineTerminator:
#     (Note: ECMAScript says that a multi-line comment with at least one line terminator is
#            equivalent to a single line terminator)
_SLT ~
    _LineTerminator
  | _MultiLineCommentWithLineTerminator

# - A general space is one of the other, and is the default :discard
_S ~
    _SNOLT
  | _SLT
_S_MANY ~ _S+
_S_ANY ~ _S*
:discard ~ _S_MANY

# - An invisible semicolon is a lexeme that should be at least as long as _S_MANY when _S_MANY matches.
#   With this constraint: it must contain a LineTerminator.
#   This mean that when the grammar is expecting a SEMICOLON, but there is no VISIBLE_SEMICOLON (i.e. a
#   true physical ';' in the input), but finds that it can match both _S_MANY and INVISIBLE_SEMICOLON
#   it will automatically insert INVISIBLE_SEMICOLON instead of the discardable _S_MANY.
#   The subtility is that when INVISIBLE_SEMICOLON matches, we know per-def this is an automatic
#   semicolon insertion: grammar expected a semicolon, and found it hidden.
#
# - Obviously, the presence of a true VISIBLE_SEMICOLON should have higher priority
#
:lexeme ~ <INVISIBLE_SEMICOLON> pause => before event => '^INVISIBLE_SEMICOLON'
INVISIBLE_SEMICOLON ~ _S_ANY _SLT _S_ANY

NullLiteral                           ::= NULL
BooleanLiteral                        ::= TRUE | FALSE
StringLiteral                         ::= STRINGLITERAL           action => StringLiteral
RegularExpressionLiteral              ::= REGULAREXPRESSIONLITERAL
NumericLiteral                        ::= DecimalLiteral
                                        | HexIntegerLiteral
                                        | OctalIntegerLiteral
DecimalLiteral                        ::= DECIMALLITERAL
HexIntegerLiteral                     ::= HEXINTEGERLITERAL
OctalIntegerLiteral                   ::= OCTALINTEGERLITERAL
event 'NumericLiteral$' = completed <NumericLiteral>

# --------------------------------------------------------------------------------------
#
# Take care 1
#
# IDENTIFIER cannot be a ReservedWord where ReservedWord means:
# Keyword
# FutureReservedWord
# NullLiteral
# BooleanLiteral
# FutureReservedWordStrict if in strict mode
#
# Solution: lexemes that are Keyword, NullLiteral and BooleanLiteral
# will have a priority of 1. So that any match of them via IDENTIFIER or IDENTIFIERNAME
# will be rejected by Marpa if out of context.
# For all other cases we will use the completion event of lexeme IDENTIFIER.
#

# --------------------------------------------------------------------------------------
# Take care 2
#
# REGULAREXPRESSIONLITERAL lexeme start with '/' thus it may compete badly with
# all lexemes starting with '/'. They are:
#
# MultiplicativeExpression ...  MultiplicativeExpression  '/'  UnaryExpression
# AssignmentOperator       ...  '/='
#
# Other cases starting with '/' are:
#
# _SingleLineComment   ~ '//' _SingleLineCommentCharsopt
# _MultiLineComment    ~ '/*' _MultiLineCommentCharsopt '*/'
#
# And none of later can happen because RegularExpressionLiteral requires a first char that is:
#
# __RegularExpressionFirstChar ::= ___RegularExpressionNonTerminatorButNotOneOfStarOrBackslashOrSlashOrLbracket
#                              | __RegularExpressionBackslashSequence
#                              | __RegularExpressionClass
#
# ==> A regular expression cannot start with '//' nor '/*'.
#
# We want to avoid RegularExpression as a lexeme to take over when '/' or '/=' is predicted.
# Fortunately this never happens at the beginning of a rule (then other problems appear).
#
# Solution:
# - When '/' or '/=' is predicted and is found in the stream, we test and lexeme_read
#   one of those. This always work (unless source has a bad syntax) because a RegularExpression can
#   never happen in the same places where '/' or '/=' is predicted.
# - Note that '//' or '/*' will be catched by the preceding  or (SNoLT)
#
# --------------------------------------------------------------------------------------
#
# Note from Marpa::R2::Scanless::DSL
#
# Completed and nulled events may not be defined for symbols that are lexemes, but lexemes are
# allowed to be predicted events. A predicted event which is a lexeme is different from a lexeme
# pause. The lexeme pause will not occur unless that the lexeme is actually found in the input.
# A predicted event, on the other hand, is as the name suggests, only a prediction.
# The predicted symbol may or not actually be found in the input.
#
event '^^DIV'       = predicted <DIV>
event '^^DIVASSIGN' = predicted <DIVASSIGN>

# --------------------------------------------------------------------------------------
# Take care 2
#
# Automatic semicolon insertion
#
# The most painful thing in the grammar:
#
# 7.9.1 Rules of Automatic Semicolon Insertion
#
# There are three basic rules of semicolon insertion:
#
# 1. When, as the program is parsed from left to right, a token (called the offending token)
#    is encountered that is not allowed by any production of the grammar, then a semicolon
#    is automatically inserted before the offending token if one or more of the following
#    conditions is true:
# - The offending token is separated from the previous token by at least one LineTerminator.
# - The offending token is }.
#
# 2. When, as the program is parsed from left to right, the end of the input stream of tokens
#    is encountered and the parser is unable to parse the input token stream as a single complete
#    ECMAScript Program, then a semicolon is automatically inserted at the end of the input stream.
#
# 3. When, as the program is parsed from left to right, a token is encountered that is allowed by
#    some production of the grammar, but the production is a restricted production and the token
#    would be the first token for a terminal or nonterminal immediately following the annotation
#    [no LineTerminator here] within the restricted production (and therefore such a token is called
#    a restricted token), and the restricted token is separated from the previous token by at least
#    one LineTerminator, then a semicolon is automatically inserted before the restricted token.
#
# However, there is an additional overriding condition on the preceding rules: a semicolon is never
# inserted automatically if the semicolon would then be parsed as an empty statement or if that
# semicolon would become one of the two semicolons in the header of a for statement (see 12.6.3).
#
# --------------------------------------------------------------------------------------
LPAREN ~ '('
RPAREN ~ ')'
LBRACKET ~ '['
RBRACKET ~ ']'
SEMICOLON ~ ';'
:lexeme ~ <VISIBLE_SEMICOLON> priority => 1
VISIBLE_SEMICOLON ~ ';'
#
# This event is NOT needed. I let its processing in _eventCallback for archiving purpose
_LCURLY ~ '{'
:lexeme ~ <LCURLY_BLOCK> priority => 1
LCURLY_BLOCK ~ _LCURLY
LCURLY ~ _LCURLY
RCURLY ~ '}'
COLON ~ ':'
COMMA ~ ','
ASSIGN ~ '='
QUESTION_MARK ~ '?'
DOT ~ '.'
GET ~ 'get'
SET ~ 'set'
:lexeme ~ <PLUSPLUS_POSTFIX>  pause => before event => '^PLUSPLUS_POSTFIX'
_PLUSPLUS ~ '++'
PLUSPLUS ~ _PLUSPLUS
PLUSPLUS_POSTFIX ~ _PLUSPLUS
:lexeme ~ <MINUSMINUS_POSTFIX>  pause => before event => '^MINUSMINUS_POSTFIX'
_MINUSMINUS ~ '--'
MINUSMINUS ~ _MINUSMINUS
MINUSMINUS_POSTFIX ~ _MINUSMINUS
PLUS ~ '+'
MINUS ~ '-'
INVERT ~ '~'
NOT ~ '!'
MUL ~ '*'
DIV ~ '/'
MODULUS ~ '%'
LEFTMOVE ~ '<<'
RIGHTMOVE ~ '>>'
RIGHTMOVEFILL ~ '>>>'
LT ~ '<'
GT ~ '>'
LE ~ '<='
GE ~ '>='
EQ ~ '=='
NE ~ '!='
STRICTEQ ~ '==='
STRICTNE ~ '!=='
BITAND ~ '&'
BITXOR ~ '^'
BITOR ~ '|'
AND ~ '&&'
OR ~ '||'
MULASSIGN ~ '*='
MODULUSASSIGN ~ '%='
PLUSASSIGN ~ '+='
MINUSASSIGN ~ '-='
LEFTMOVEASSIGN ~ '<<='
RIGHTMOVEASSIGN ~ '>>='
RIGHTMOVEFILLASSIGN ~ '>>>='
BITANDASSIGN ~ '&='
BITXORASSIGN ~ '^='
BITORASSIGN ~ '|='
DIVASSIGN ~ '/='


##############################################################################
#
# G0: Lexemes that do NOT need an internal analysis are writen directly below.
#     Those that need an look inside are writen as independant grammars and
#     injected here as G0 after manipulation of their '::=' and '__' prefix
##############################################################################

# ---------------
# _LineTerminator
# ---------------
_LineTerminator                        ~ [\p{IsLineTerminator}]

# ---------------
# IDENTIFIERNAME
# ---------------
IDENTIFIERNAME                         ~ _IdentifierNameInternal

_IdentifierNameInternal                ~ _IdentifierStart
                                       | _IdentifierNameInternal _IdentifierPart

_UnicodeLetter                         ~ [\p{IsUnicodeLetter}]

_IdentifierStart                       ~ _UnicodeLetter
                                       | '$'
                                       | '_'
                                       | '\' _UnicodeEscapeSequence
                                       # ' for my editor

_ZWNJ                                  ~ [\p{IsZWJ}]

_ZWJ                                   ~ [\p{IsZWJ}]

_UnicodeCombiningMark                  ~ [\p{IsUnicodeCombiningMark }]

_UnicodeDigit                          ~ [\p{IsUnicodeDigit}]

_UnicodeConnectorPunctuation           ~ [\p{IsUnicodeConnectorPunctuation}]

_UnicodeEscapeSequence                 ~ 'u' _HexDigit _HexDigit _HexDigit _HexDigit

_IdentifierPart                        ~ _IdentifierStart
                                       | _UnicodeCombiningMark
                                       | _UnicodeDigit
                                       | _UnicodeConnectorPunctuation
                                       | _ZWNJ
                                       | _ZWJ

_HexDigit                              ~ [\p{IsHexDigit}]

# -----------
# IDENTIFIER
# -----------
:lexeme ~ <IDENTIFIER>  pause => after event => 'IDENTIFIER$'
IDENTIFIER                             ~ _IdentifierNameInternal

# -----------
# _WhiteSpace
# -----------
_WhiteSpace                            ~ [\p{IsWhiteSpace}]

# ------------------
# _SingleLineComment
# ------------------
_SingleLineComment                     ~ '//' _SingleLineCommentCharsopt

_SingleLineCommentChars                ~ _SingleLineCommentChar _SingleLineCommentCharsopt

_SingleLineCommentCharsopt             ~ _SingleLineCommentChars

_SingleLineCommentCharsopt             ~

_SingleLineCommentChar                 ~ [\p{IsSourceCharacterButNotLineTerminator}]

# -----------------------------------
# _MultiLineCommentWithLineTerminator
# -----------------------------------
_MultiLineCommentWithLineTerminator ~ '/*' _MultiLineCommentWithLineTerminatorCharsopt _LineTerminator _MultiLineCommentWithLineTerminatorCharsopt '*/'

_MultiLineCommentWithLineTerminatorChars ~ _MultiLineWithLineTerminatorNotAsteriskChar _MultiLineCommentWithLineTerminatorCharsopt
                                                          | '*' _PostAsteriskCommentWithLineTerminatorCharsopt

_PostAsteriskCommentWithLineTerminatorChars ~ _MultiLineWithLineTerminatorNotForwardSlashOrAsteriskChar _MultiLineCommentWithLineTerminatorCharsopt
                                                          | '*' _PostAsteriskCommentWithLineTerminatorCharsopt

_MultiLineCommentWithLineTerminatorCharsopt ~ _MultiLineCommentWithLineTerminatorChars
_MultiLineCommentWithLineTerminatorCharsopt ~

_PostAsteriskCommentWithLineTerminatorCharsopt ~ _PostAsteriskCommentWithLineTerminatorChars
_PostAsteriskCommentWithLineTerminatorCharsopt ~

_MultiLineWithLineTerminatorNotAsteriskChar ~ [\p{IsSourceCharacterButNotStar}]
_MultiLineWithLineTerminatorNotForwardSlashOrAsteriskChar ~ [\p{IsSourceCharacterButNotOneOfSlashOrStar}]

# -----------------------------------
# _MultiLineCommentWithoutLineTerminator
# -----------------------------------
_MultiLineCommentWithoutLineTerminator ~ '/*' _MultiLineCommentWithoutLineTerminatorCharsopt '*/'

_MultiLineCommentWithoutLineTerminatorChars ~ _MultiLineWithoutLineTerminatorNotAsteriskChar _MultiLineCommentWithoutLineTerminatorCharsopt
                                                          | '*' _PostAsteriskCommentWithoutLineTerminatorCharsopt

_PostAsteriskCommentWithoutLineTerminatorChars ~ _MultiLineWithoutLineTerminatorNotForwardSlashOrAsteriskChar _MultiLineCommentWithoutLineTerminatorCharsopt
                                                          | '*' _PostAsteriskCommentWithoutLineTerminatorCharsopt

_MultiLineCommentWithoutLineTerminatorCharsopt ~ _MultiLineCommentWithoutLineTerminatorChars
_MultiLineCommentWithoutLineTerminatorCharsopt ~

_PostAsteriskCommentWithoutLineTerminatorCharsopt ~ _PostAsteriskCommentWithoutLineTerminatorChars
_PostAsteriskCommentWithoutLineTerminatorCharsopt ~

_MultiLineWithoutLineTerminatorNotAsteriskChar ~ [\p{IsSourceCharacterButNotStarOrLineTerminator}]
_MultiLineWithoutLineTerminatorNotForwardSlashOrAsteriskChar ~ [\p{IsSourceCharacterButNotOneOfSlashOrStarOrLineTerminator}]

# ----------------------------------------------------------------
# STRINGLITERAL injected: it is a G1 grammar in StringLiteral.pm
# ----------------------------------------------------------------
STRINGLITERAL                          ~ __StringLiteral

# --------------------------------------------------------------------------------------
# __RegularExpressionLiteral injected: it is a G1 grammar in RegularExpressionLiteral.pm
# --------------------------------------------------------------------------------------
REGULAREXPRESSIONLITERAL               ~ __RegularExpressionLiteral

# --------------------------------------------------------------------------------------
# __DecimalLiteral      injected: it is a G1 grammar in NumericLiteral.pm
# __HexIntegerLiteral   injected: it is a G1 grammar in NumericLiteral.pm
# __OctalIntegerLiteral injected: it is a G1 grammar in NumericLiteral.pm
# --------------------------------------------------------------------------------------
DECIMALLITERAL                         ~ __DecimalLiteral
HEXINTEGERLITERAL                      ~ __HexIntegerLiteral
OCTALINTEGERLITERAL                    ~ __OctalIntegerLiteral

# -------------------------------------------
# Injection of reserved keywords happens here
# -------------------------------------------

