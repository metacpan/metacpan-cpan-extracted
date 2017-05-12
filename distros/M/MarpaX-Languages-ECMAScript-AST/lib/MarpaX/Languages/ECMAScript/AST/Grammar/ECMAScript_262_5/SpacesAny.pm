#
# Used to generate a grammar containing spaces only
#
use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use SUPER;

# ABSTRACT: ECMAScript-262, Edition 5, spaces only grammar written in Marpa BNF

our $VERSION = '0.020'; # VERSION

#
# We reuse Program grammar, only a subset of it -;
#
our $grammar_content = do {local $/; <DATA>};



sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
}


sub parse {
    my ($self, $source, $impl, $start) = @_;
    $self->{endReached} = undef;
    return $self->SUPER($source, $impl,
                        {
                         failure => \&_failureCallback,
                         failureargs => [ $self ],
                         end => \&_endCallback,
                         endargs => [ $self ],
                        },
			$start
	);
}


sub endReached {
    my ($self) = @_;
    return $self->{endReached};
}

sub _failureCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  $self->{endReached} = 0;
  #
  # This is forcing the parsing to end
  #
  return $max+1;
}

sub _endCallback {
  my ($self, $source, $pos, $max, $impl) = @_;

  $self->{endReached} //= ($pos > $max) ? 1 : 0;
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny - ECMAScript-262, Edition 5, spaces only grammar written in Marpa BNF

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::SpacesAny->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 spaces only grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>. This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package.

=head1 SUBROUTINES/METHODS

=head2 make_grammar_content($class)

Returns the grammar.

=head2 parse($self, $source, $impl, $start)

Parse the source given as $source, from position $start up to the end, using implementation $impl.

=head2 endReached($self)

Returns a boolean indicating if the parse() method succeeded up to the end of the source or not. Meaningful only after a call to parse().

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
:start ::= s_any

s_any ::= S_ANY

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

# - A general space is one or the other, and is the default :discard
_S ~
    _SNOLT
  | _SLT
S_ANY ~ _S*

# ---------------
# _LineTerminator
# ---------------
_LineTerminator                        ~ [\p{IsLineTerminator}]

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
