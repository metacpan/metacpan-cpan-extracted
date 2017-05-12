use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI;
use parent qw/MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base/;
use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;

our $grammar_content = do {local $/; <DATA>};

# ABSTRACT: ECMAScript-262, Edition 5, URI grammar

our $VERSION = '0.020'; # VERSION



sub make_grammar_content {
    my ($class) = @_;
    return $grammar_content;
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI - ECMAScript-262, Edition 5, URI grammar

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI;

    my $grammar = MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::URI->new();

    my $grammar_content = $grammar->content();
    my $grammar_option = $grammar->grammar_option();
    my $recce_option = $grammar->recce_option();

=head1 DESCRIPTION

This modules returns describes the ECMAScript 262, Edition 5 URI grammar written in Marpa BNF, as of L<http://www.ecma-international.org/publications/standards/Ecma-262.htm>. This module inherits the methods from MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::Base package.

=head1 SUBROUTINES/METHODS

=head2 make_grammar_content($class)

Returns the grammar. This will be injected in the Program's grammar.

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
:start ::= uri
:default ::= action => [values]
lexeme default = action => [start,length,value] forgiving => 1

uri           ::= uriCharactersopt

uriCharactersopt ::= uriCharacters
uriCharactersopt ::=

uriCharacters    ::= uriCharacter+

uriCharacter  ::= uriReserved | uriUnescaped | uriEscaped

uriReserved   ~ [;/?:@&=+$,]

uriUnescaped  ::= uriAlpha | DecimalDigit | uriMark

uriEscaped    ~ '%' HexDigit HexDigit

uriAlpha      ~ [a-zA-Z]

uriMark       ~ [\-_\.!~\*'\(\)]

#
# Copy/pasted from Program grammar
#
DecimalDigit  ~ [\p{IsDecimalDigit}]

HexDigit      ~ [\p{IsHexDigit}]
