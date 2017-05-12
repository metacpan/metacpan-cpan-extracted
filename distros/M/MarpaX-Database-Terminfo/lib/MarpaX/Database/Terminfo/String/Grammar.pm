use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo::String::Grammar;
use MarpaX::Database::Terminfo::String::Grammar::Actions;
use MarpaX::Database::Terminfo::Grammar::CharacterClasses;

# ABSTRACT: Terminfo string grammar in Marpa BNF

our $VERSION = '0.012'; # VERSION


our $GRAMMAR_CONTENT = do {local $/; <DATA>};

sub new {
    my $class = shift;

    my $self = {};

    $self->{_content} = $GRAMMAR_CONTENT;
    $self->{_grammar_option} = {
        action_object  => sprintf('%s::%s', __PACKAGE__, 'Actions'),
        source => \$self->{_content}
    };
    $self->{_recce_option} = {};

    bless($self, $class);

    return $self;
}


sub content {
    my ($self) = @_;
    return $self->{_content};
}


sub grammar_option {
    my ($self) = @_;
    return $self->{_grammar_option};
}


sub recce_option {
    my ($self) = @_;
    return $self->{_recce_option};
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo::String::Grammar - Terminfo string grammar in Marpa BNF

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use MarpaX::Database::Terminfo::String;

    my $grammar = MarpaX::Database::Terminfo::String->new();
    my $grammar_content = $grammar->content();

=head1 DESCRIPTION

This modules returns Terminfo string grammar written in Marpa BNF.

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instance a new object.

=head2 content($self)

Returns the content of the grammar.

=head2 grammar_option($self)

Returns recommended option for Marpa::R2::Scanless::G->new(), returned as a reference to a hash.

=head2 recce_option($self)

Returns recommended option for Marpa::R2::Scanless::R->new(), returned as a reference to a hash.

=head1 SEE ALSO

L<Marpa::R2>

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# -------------------------------------------------------------------------
# Grammar says that a string has the following particularities:
#
# Both \E and \e map to an ESCAPE character           ==> "\e"
# ^x maps to a control-x for any appropriate x        ==> "\cX"
# \n maps to newline                                  ==> "\n"
# \l maps to line-feed                                ==> "\n"
# \r maps to return                                   ==> "\r"
# \t maps to tab                                      ==> "\t"
# \b maps to backspace                                ==> "\b"
# \f maps to form-feed                                ==> "\f"
# \s maps to space                                    ==> ' '
#
# General syntax
#
# 	     The % encodings have the following meanings:
#
# 	     %%        outputs `%'
# 	     %c        print pop() like %c in printf()
# 	     %s        print pop() like %s in printf()
#            %[[:]flags][width[.precision]][doxXs]
#                      as in printf, flags are [-+#] and space
#                      The ':' is used to avoid making %+ or %-
#                      patterns (see below).
#
# 	     %p[1-9]   push ith parm
# 	     %P[a-z]   set dynamic variable [a-z] to pop()
# 	     %g[a-z]   get dynamic variable [a-z] and push it
# 	     %P[A-Z]   set static variable [A-Z] to pop()
# 	     %g[A-Z]   get static variable [A-Z] and push it
# 	     %l        push strlen(pop)
# 	     %'c'      push char constant c
# 	     %{nn}     push integer constant nn
#
# 	     %+ %- %* %/ %m
# 	               arithmetic (%m is mod): push(pop() op pop())
# 	     %& %| %^  bit operations: push(pop() op pop())
# 	     %= %> %<  logical operations: push(pop() op pop())
# 	     %A %O     logical and & or operations for conditionals
# 	     %! %~     unary operations push(op pop())
# 	     %i        add 1 to first two parms (for ANSI terminals)
#
# 	     %? expr %t thenpart %e elsepart %;
# 	               if-then-else, %e elsepart is optional.
# 	               else-if's are possible ala Algol 68:
# 	               %? c1 %t b1 %e c2 %t b2 %e c3 %t b3 %e c4 %t b4 %e b5 %;
#
# 	For those of the above operators which are binary and not commutative,
# 	the stack works in the usual way, with
# 			%gx %gy %m
# 	resulting in x mod y, not the reverse.
#
# NOTE: there is no notion of associativity in this grammar: operators are
#       taking what is on the stack and that's all.
#
# -------------------------------------------------------------------------
:default ::= action => [values]
:start ::= units

units ::= unit*

unit ::= ESCAPED_CHARACTER                              action => addEscapedCharacterToRc
       | INISPRINTEXCEPTCOMMA                           action => addCharacterToRc
       | PERCENT                                        action => addPercentToRc
       | C                                              action => addPrintPopToRc
# Commented because our PRINT lexeme includes %s
#       | S
       | PRINT                                          action => addPrintToRc
       | PUSH                                           action => addPushToRc
       | DYNPOP                                         action => addDynPop
       | DYNPUSH                                        action => addDynPush
       | STATICPOP                                      action => addStaticPop
       | STATICPUSH                                     action => addStaticPush
       | L                                              action => addL
       | PUSHCONST                                      action => addPushConst
       | PUSHINT                                        action => addPushInt
       | PLUS                                           action => addPlus
       | MINUS                                          action => addMinus
       | STAR                                           action => addStar
       | DIV                                            action => addDiv
       | MOD                                            action => addMod
       | BITAND                                         action => addBitAnd
       | BITOR                                          action => addBitOr
       | BITXOR                                         action => addBitXor
       | EQUAL                                          action => addEqual
       | GREATER                                        action => addGreater
       | LOWER                                          action => addLower
       | AND                                            action => addLogicalAnd
       | OR                                             action => addLogicalOr
       | NOT                                            action => addNot
       | COMPLEMENT                                     action => addComplement
       | ADDONE                                         action => addOneToParams
       | IF units THEN units elifUnits ELSE units ENDIF action => addIfThenElse
       | IF units THEN units elifUnits ENDIF            action => addIfThen
       # Look to wy350.is3: this look like an empty if
       | IF ENDIF                                       action => ifEndif
       | EOF                                            action => eof

elifUnit ::= ELSE units THEN units                      action => elifUnit
elifUnits ::= elifUnit*

_CONST      ~ [^']              # It appears that SQUOTE never appears within %'' (always true ?)
_CONST      ~ _BS _ALLOWED_BS   # or an escaped character
_DIGITS     ~ [\d]+
_DIGIT      ~ [\d]
_OCTALDIGIT ~ [0-7]
_LCHAR      ~ [a-z]
_UCHAR      ~ [A-Z]
_PERCENT    ~ '%'
PERCENT     ~ _PERCENT _PERCENT
_C          ~ 'c'
C           ~ _PERCENT _C
#_S          ~ 's'
#S           ~ _PERCENT _S
_COLON      ~ ':'
_DOT        ~ '.'
__FLAGS     ~ [-+# ]
_FLAGS      ~ _COLON __FLAGS
            | __FLAGS
_FORMAT     ~ [doxXs]
PRINT       ~ _PERCENT _FORMAT
            | _PERCENT _DIGITS _FORMAT
            | _PERCENT _DIGITS _DOT _DIGITS _FORMAT
PRINT       ~ _PERCENT _FLAGS _FORMAT
            | _PERCENT _FLAGS _DIGITS _FORMAT
            | _PERCENT _FLAGS _DIGITS _DOT _DIGITS _FORMAT
PUSH        ~ '%p' _DIGIT
DYNPOP      ~ '%P' _LCHAR
DYNPUSH     ~ '%g' _LCHAR
STATICPOP   ~ '%P' _UCHAR
STATICPUSH  ~ '%g' _UCHAR
L           ~ 'ls'
_SQUOTE     ~ [']
PUSHCONST   ~ '%' _SQUOTE _CONST _SQUOTE
_LCURLY     ~ '{'
_RCURLY     ~ '}'
PUSHINT     ~ _PERCENT _LCURLY _DIGITS _RCURLY
_PLUS       ~ '+'
PLUS        ~ _PERCENT _PLUS
_MINUS      ~ '-'
MINUS       ~ _PERCENT _MINUS
_STAR       ~ '*'
STAR        ~ _PERCENT _STAR
_DIV        ~ '/'
DIV         ~ _PERCENT _DIV
_MOD        ~ 'm'
MOD         ~ _PERCENT _MOD
_BITAND     ~ '&'
BITAND      ~ _PERCENT _BITAND
_BITOR      ~ '|'
BITOR       ~ _PERCENT _BITOR
_BITXOR     ~ '^'
BITXOR      ~ _PERCENT _BITXOR
_EQUAL      ~ '='
EQUAL       ~ _PERCENT _EQUAL
_GREATER    ~ '>'
GREATER     ~ _PERCENT _GREATER
_LOWER      ~ '<'
LOWER       ~ _PERCENT _LOWER
_AND        ~ 'A'
AND         ~ _PERCENT _AND
_OR         ~ 'O'
OR          ~ _PERCENT _OR
_NOT        ~ '!'
NOT         ~ _PERCENT _NOT
_COMPLEMENT ~ '~'
COMPLEMENT  ~ _PERCENT _COMPLEMENT
_ADDONE     ~ 'i'
ADDONE      ~ _PERCENT _ADDONE
_IF         ~ '?'
IF          ~ _PERCENT _IF
_THEN       ~ 't'
THEN        ~ _PERCENT _THEN
_ELSE       ~ 'e'
ELSE        ~ _PERCENT _ELSE
_ENDIF      ~ ';'
ENDIF       ~ _PERCENT _ENDIF
_EOF        ~ ','
# COMMA, at the end of string, IS LIKE AN ENDIF MARKER: quite often IF-THEN-ELSE-IF are MISSING
# the %; symbol at the very end. This is really a PITY because it is
# exactly with this symbol that the IF-THEN-ELSE-IF ambiguity is
# disappearing. This mean that when parsing the string, one HAS to restore the ',' COMMA
# at then end when parsing it with Marpa.
ENDIF       ~ _EOF

_CARET      ~ '^'
_BS         ~ '\'
_ALLOWED_BS ~ [abEeflnrst^\,:0]
_ALLOWED_BS ~ _OCTALDIGIT _OCTALDIGIT _OCTALDIGIT
_C0_AND_DEL ~ [@A-Z[\]^_?]
ESCAPED_CHARACTER ~ _CARET _C0_AND_DEL
                  | _BS _ALLOWED_BS
INISPRINTEXCEPTCOMMA ~ [\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InIsPrintExceptComma}]
EOF         ~ _EOF
