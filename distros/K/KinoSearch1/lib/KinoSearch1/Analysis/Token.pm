package KinoSearch1::Analysis::Token;

1;

__END__

__H__

#ifndef H_KINOSEARCH_ANALYSIS_TOKEN
#define H_KINOSEARCH_ANALYSIS_TOKEN 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMemManager.h"

typedef struct Token Token;

struct Token {
    char   *text;
    STRLEN  len;
    I32     start_offset;
    I32     end_offset;
    I32     pos_inc;
    Token  *next;
    Token  *prev;
};

Token* Kino1_Token_new(char* text, STRLEN len, I32 start_offset, 
                      I32 end_offset, I32 pos_inc);
void Kino1_Token_destroy(Token*);

#endif /* include guard */

__C__

#include "KinoSearch1AnalysisToken.h"

Token*
Kino1_Token_new(char* text, STRLEN len, I32 start_offset, I32 end_offset, 
               I32 pos_inc) {
    Token *token;

    /* allocate */
    Kino1_New(0, token, 1, Token);

    /* allocate and assign */
    token->text = Kino1_savepvn(text, len);

    /* assign */
    token->len          = len;
    token->start_offset = start_offset;
    token->end_offset   = end_offset;
    token->pos_inc      = pos_inc;

    /* init */
    token->next = NULL;
    token->prev = NULL;

    return token;
}


void
Kino1_Token_destroy(Token *token) {
    Kino1_Safefree(token->text);
    Kino1_Safefree(token);
}

__POD__

=head1 NAME

KinoSearch1::Analysis::Token - unit of text

=head1 SYNOPSIS

    # private class - no public API

=head1 PRIVATE CLASS

You can't actually instantiate a Token object at the Perl level -- however,
you can affect individual Tokens within a TokenBatch by way of TokenBatch's
(experimental) API.

=head1 DESCRIPTION

Token is the fundamental unit used by KinoSearch1's Analyzer subclasses.  Each
Token has 4 attributes: text, start_offset, end_offset, and pos_inc (for
position increment).

The text of a token is a string.

A Token's start_offset and end_offset locate it within a larger text, even if
the Token's text attribute gets modified -- by stemming, for instance.  The
Token for "beating" in the text "beating a dead horse" begins life with a
start_offset of 0 and an end_offset of 7; after stemming, the text is "beat",
but the end_offset is still 7. 

The position increment, which defaults to 1, is a an advanced tool for
manipulating phrase matching.  Ordinarily, Tokens are assigned consecutive
position numbers: 0, 1, and 2 for "three blind mice".  However, if you set the
position increment for "blind" to, say, 1000, then the three tokens will end
up assigned to positions 0, 1, and 1001 -- and will no longer produce a phrase
match for the query '"three blind mice"'.

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

