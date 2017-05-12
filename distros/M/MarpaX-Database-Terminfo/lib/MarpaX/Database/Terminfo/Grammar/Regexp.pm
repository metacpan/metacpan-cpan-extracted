use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo::Grammar::Regexp;
use MarpaX::Database::Terminfo::Grammar::CharacterClasses;
use Exporter 'import';

our @EXPORT_OK = qw/@TOKENSRE %TOKENSRE/;

# ABSTRACT: Terminfo grammar regexps

our $VERSION = '0.012'; # VERSION


#
# List of escaped characters allowed in terminfo source files
# ^x : Control-x (for any appropriate x)
# any appropriate x here is all the ASCII Control Characters (C0 set + DEL, even if it is outdated)
# \x where x can be a b E e f l n r s t ^ \ , : 0 [0-7]{3}
#
our $C0 =          qr/[\@A-Z\[\\\]\^_ \?]/;
our $CONTROLX      = qr/(?<!\^)(?>\^\^)*\^$C0/;                                                       # Takes care of ^^
our $ALLOWED_BACKSLASHED_CHARACTERS = qr/(?:a|b|E|e|f|l|n|r|s|t|\^|\\|,|:|0|[0-7]{3})/;
our $BACKSLASHX    = qr/(?<!\\)(?>\\\\)*\\$ALLOWED_BACKSLASHED_CHARACTERS/;                         # Takes care of \\
our $ESCAPED       = qr/(?:$CONTROLX|$BACKSLASHX)/;
our $I_CONSTANT = qr/(?:(0[xX][a-fA-F0-9]+(?:[uU](?:ll|LL|[lL])?|(?:ll|LL|[lL])[uU]?)?)             # Hexadecimal
                      |([1-9][0-9]*(?:[uU](?:ll|LL|[lL])?|(?:ll|LL|[lL])[uU]?)?)                    # Decimal
                      |(0[0-7]*(?:[uU](?:ll|LL|[lL])?|(?:ll|LL|[lL])[uU]?)?)                        # Octal
                      |([uUL]?'(?:[^'\\\n]|\\(?:[\'\"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))+')     # Character
                    )/x;

our %TOKENSRE = (
    'ALIASINCOLUMNONE' => qr/\G^((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InAlias})+)/ms,
    'PIPE'             => qr/\G(\|)/,
    'LONGNAME'         => qr/\G((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InNcursesLongname})+), ?/,
    'ALIAS'            => qr/\G((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InAlias})+)/,
    'NUMERIC'          => qr/\G(((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InName})+)#($I_CONSTANT))/,
    'STRING'           => qr/\G(((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InName})+)=((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InIsPrintExceptComma})*))/,
    'BOOLEAN'          => qr/\G((?:$ESCAPED|\p{MarpaX::Database::Terminfo::Grammar::CharacterClasses::InName})+)/,
    'COMMA'            => qr/\G(, ?)/,
    'NEWLINE'          => qr/\G(\n)/,
    'WS_many'          => qr/\G( +)/,
    'BLANKLINE'        => qr/\G^([ \t]*\n)/ms,
    'COMMENT'          => qr/\G^([ \t]*#[^\n]*\n)/ms,
    );

#
# It is important to have LONGNAME before ALIAS because LONGNAME will do a lookahead on COMMA
# It is important to have NUMERIC and STRING before BOOLEAN because BOOLEAN is a subset of them
# It is important to have BLANKLINE and COMMENT at the end: they are 'discarded' by the grammar
# In these regexps we add the embedded comma: \, (i.e. these are TWO characters)
#

our @TOKENSRE = (
    [ 'ALIASINCOLUMNONE' , $TOKENSRE{ALIASINCOLUMNONE} ],
    [ 'PIPE'             , $TOKENSRE{PIPE} ],
    [ 'LONGNAME'         , $TOKENSRE{LONGNAME} ],
    [ 'ALIAS'            , $TOKENSRE{ALIAS} ],
    [ 'NUMERIC'          , $TOKENSRE{NUMERIC} ],
    [ 'STRING'           , $TOKENSRE{STRING} ],
    [ 'BOOLEAN'          , $TOKENSRE{BOOLEAN} ],
    [ 'COMMA'            , $TOKENSRE{COMMA} ],
    [ 'NEWLINE'          , $TOKENSRE{NEWLINE} ],
    [ 'WS_many'          , $TOKENSRE{WS_many} ],
    [ 'BLANKLINE'        , $TOKENSRE{BLANKLINE} ],
    [ 'COMMENT'          , $TOKENSRE{COMMENT} ],
    );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo::Grammar::Regexp - Terminfo grammar regexps

=head1 VERSION

version 0.012

=head1 DESCRIPTION

This modules give the regular expressions associated to terminfo grammar.

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
