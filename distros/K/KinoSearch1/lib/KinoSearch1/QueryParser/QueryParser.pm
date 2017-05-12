package KinoSearch1::QueryParser::QueryParser;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor args / members
        analyzer       => undef,
        default_boolop => 'OR',
        default_field  => undef,    # back compat
        fields         => undef,
        # members
        bool_groups   => undef,
        phrases       => undef,
        bool_group_re => undef,
        phrase_re     => undef,
        label_inc     => 0,
    );
}

use KinoSearch1::Analysis::TokenBatch;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Search::BooleanQuery;
use KinoSearch1::Search::PhraseQuery;
use KinoSearch1::Search::TermQuery;
use KinoSearch1::Index::Term;

sub init_instance {
    my $self = shift;
    $self->{bool_groups} = {};
    $self->{phrases}     = {};

    croak("default_boolop must be either 'AND' or 'OR'")
        unless $self->{default_boolop} =~ /^(?:AND|OR)$/;

    # create a random string that presumably won't appear in a search string
    my @chars      = ( 'A' .. 'Z' );
    my $randstring = '';
    $randstring .= $chars[ rand @chars ] for ( 1 .. 16 );
    $self->{randstring} = $randstring;

    # create labels which won't appear in search strings
    $self->{phrase_re}     = qr/^(_phrase$randstring\d+)/;
    $self->{bool_group_re} = qr/^(_boolgroup$randstring\d+)/;

    # verify fields param
    my $fields
        = defined $self->{fields}
        ? $self->{fields}
        : [ $self->{default_field} ];
    croak("Required parameter 'fields' not supplied as arrayref")
        unless ( defined $fields
        and reftype($fields) eq 'ARRAY' );
    $self->{fields} = $fields;

    # verify analyzer
    croak("Missing required param 'analyzer'")
        unless a_isa_b( $self->{analyzer},
                'KinoSearch1::Analysis::Analyzer' );
}

# regex matching a quoted string
my $quoted_re = qr/
                "            # opening quote
                (            # capture
                    [^"]*?   # anything not a quote
                )
                (?:"|$)      # closed by either a quote or end of string
            /xsm;

# regex matching a parenthetical group
my $paren_re = qr/
                \(           # opening paren
                (            # capture
                    [^()]*?  # anything not a paren
                )
                (?:\)|$)     # closed by paren or end of string
            /xsm;

# regex matching a negating boolean operator
my $neg_re = qr/^(?:
                NOT\s+         # NOT followed by space
                |-(?=\S)       # minus followed by something not-spacey
             )/xsm;

# regex matching a requiring boolean operator
my $req_re = qr/^
                \+(?=\S)       # plus followed by something not-spacey
             /xsm;

# regex matching a field indicator
my $field_re = qr/^
                (              # capture
                    [^"(:\s]+  # non-spacey string
                )
                :              # followed by :
             /xsm;

sub parse {
    my ( $self, $qstring_orig, $default_fields ) = @_;
    $qstring_orig = '' unless defined $qstring_orig;
    $default_fields ||= $self->{fields};
    my $default_boolop = $self->{default_boolop};
    my @clauses;

    # substitute contiguous labels for phrases and boolean groups
    my $qstring = $self->_extract_phrases($qstring_orig);
    $qstring = $self->_extract_boolgroups($qstring);

    local $_ = $qstring;
    while ( bytes::length $_ ) {
        # fast-forward past whitespace
        next if s/^\s+//;

        my $occur = $default_boolop eq 'AND' ? 'MUST' : 'SHOULD';

        if (s/^AND\s+//) {
            if (@clauses) {
                # require the previous clause (unless it's negated)
                if ( $clauses[-1]{occur} eq 'SHOULD' ) {
                    $clauses[-1]{occur} = 'MUST';
                }
            }
            # require this clause
            $occur = 'MUST';
        }
        elsif (s/^OR\s+//) {
            if (@clauses) {
                $clauses[-1]{occur} = 'SHOULD';
            }
            $occur = 'SHOULD';
        }

        # detect tokens which cause this clause to be required or negated
        if (s/$neg_re//) {
            $occur = 'MUST_NOT';
        }
        elsif (s/$req_re//) {
            $occur = 'MUST';
        }

        # set the field
        my $fields = s/^$field_re// ? [$1] : $default_fields;

        # if a phrase label is detected...
        if (s/$self->{phrase_re}//) {
            my $query;

            # retreive the text and analyze it
            my $orig_phrase_text = delete $self->{phrases}{$1};
            my $token_texts      = $self->_analyze($orig_phrase_text);
            if (@$token_texts) {
                my $query = $self->_get_field_query( $fields, $token_texts );
                push @clauses, { query => $query, occur => $occur }
                    if defined $query;
            }
        }
        # if a label indicating a bool group is detected...
        elsif (s/$self->{bool_group_re}//) {
            # parse boolean subqueries recursively
            my $inner_text = delete $self->{bool_groups}{$1};
            my $query = $self->parse( $inner_text, $fields );
            push @clauses, { query => $query, occur => $occur };
        }
        # what's left is probably a term
        elsif (s/([^"(\s]+)//) {
            my $token_texts = $self->_analyze($1);
            @$token_texts = grep { $_ ne '' } @$token_texts;
            if (@$token_texts) {
                my $query = $self->_get_field_query( $fields, $token_texts );
                push @clauses, { occur => $occur, query => $query };
            }
        }
    }

    if ( @clauses == 1 and $clauses[0]{occur} ne 'MUST_NOT' ) {
        # if it's just a simple query, return it unwrapped
        return $clauses[0]{query};
    }
    else {
        # otherwise, build a boolean query
        my $bool_query = KinoSearch1::Search::BooleanQuery->new;
        for my $clause (@clauses) {
            $bool_query->add_clause(
                query => $clause->{query},
                occur => $clause->{occur},
            );
        }
        return $bool_query;
    }
}

# Wrap a TermQuery/PhraseQuery to deal with multiple fields.
sub _get_field_query {
    my ( $self, $fields, $token_texts ) = @_;

    my @queries = grep { defined $_ }
        map { $self->_gen_single_field_query( $_, $token_texts ) } @$fields;

    if ( @queries == 0 ) {
        return;
    }
    elsif ( @queries == 1 ) {
        return $queries[0];
    }
    else {
        my $wrapper_query = KinoSearch1::Search::BooleanQuery->new;
        for my $query (@queries) {
            $wrapper_query->add_clause(
                query => $query,
                occur => 'SHOULD',
            );
        }
        return $wrapper_query;
    }
}

# Create a TermQuery, a PhraseQuery, or nothing.
sub _gen_single_field_query {
    my ( $self, $field, $token_texts ) = @_;

    if ( @$token_texts == 1 ) {
        my $term = KinoSearch1::Index::Term->new( $field, $token_texts->[0] );
        return KinoSearch1::Search::TermQuery->new( term => $term );
    }
    elsif ( @$token_texts > 1 ) {
        my $phrase_query = KinoSearch1::Search::PhraseQuery->new;
        for my $token_text (@$token_texts) {
            $phrase_query->add_term(
                KinoSearch1::Index::Term->new( $field, $token_text ),
            );
        }
        return $phrase_query;
    }
}

# break a string into tokens
sub _analyze {
    my ( $self, $string ) = @_;

    my $token_batch = KinoSearch1::Analysis::TokenBatch->new;
    $token_batch->append( $string, 0, bytes::length($string) );
    $token_batch = $self->{analyzer}->analyze($token_batch);
    my @token_texts;
    while ( $token_batch->next ) {
        push @token_texts, $token_batch->get_text;
    }
    return \@token_texts;
}

# replace all phrases with labels
sub _extract_phrases {
    my ( $self, $qstring ) = @_;

    while ( $qstring =~ $quoted_re ) {
        my $label
            = sprintf( "_phrase$self->{randstring}%d", $self->{label_inc}++ );
        $qstring =~ s/$quoted_re/$label /;    # extra space for safety

        # store the phrase text for later retrieval
        $self->{phrases}{$label} = $1;
    }

    return $qstring;
}

# recursively replace boolean groupings with labels, innermost first
sub _extract_boolgroups {
    my ( $self, $qstring ) = @_;

    while ( $qstring =~ $paren_re ) {
        my $label = sprintf( "_boolgroup$self->{randstring}%d",
            $self->{label_inc}++ );
        $qstring =~ s/$paren_re/$label /;    # extra space for safety

        # store the text for later retrieval
        $self->{bool_groups}{$label} = $1;
    }

    return $qstring;
}

1;

__END__

=head1 NAME

KinoSearch1::QueryParser::QueryParser - transform a string into a Query object

=head1 SYNOPSIS

    my $query_parser = KinoSearch1::QueryParser::QueryParser->new(
        analyzer => $analyzer,
        fields   => [ 'bodytext' ],
    );
    my $query = $query_parser->parse( $query_string );
    my $hits  = $searcher->search( query => $query );

=head1 DESCRIPTION

The QueryParser accepts search strings as input and produces Query objects,
suitable for feeding into L<KinoSearch1::Searcher|KinoSearch1::Searcher>.

=head2 Syntax

The following constructs are recognized by QueryParser.

=over

=item *

Boolean operators 'AND', 'OR', and 'AND NOT'.

=item *

Prepented +plus and -minus, indicating that the labeled entity should be
either required or forbidden -- be it a single word, a phrase, or a
parenthetical group.

=item *

Logical groups, delimited by parentheses.

=item *

Phrases, delimited by double quotes.

=item *

Field-specific terms, in the form of C<fieldname:termtext>.  (The field
specified by fieldname will be used instead of the QueryParser's default
fields).

A field can also be given to a logical group, in which case it is the same as
if the field had been prepended onto every term in the group.  For example:
C<foo:(bar baz)> is the same as C<foo:bar foo:baz>.

=back

=head1 METHODS

=head2 new

    my $query_parser = KinoSearch1::QueryParser::QueryParser->new(
        analyzer       => $analyzer,       # required
        fields         => [ 'bodytext' ],  # required
        default_boolop => 'AND',           # default: 'OR'
    );

Constructor.  Takes hash-style parameters:

=over

=item *

B<analyzer> - An object which subclasses
L<KinoSearch1::Analysis::Analyzer|KinoSearch1::Analysis::Analyzer>.  This
B<must> be identical to the Analyzer used at index-time, or the results won't
match up.

=item *

B<fields> - the names of the fields which will be searched against.  Must be
supplied as an arrayref.

=item *

B<default_field> - deprecated. Use C<fields> instead.

=item *

B<default_boolop> - two possible values: 'AND' and 'OR'.  The default is 'OR',
which means: return documents which match any of the query terms.  If you
want only documents which match all of the query terms, set this to 'AND'.

=back

=head2 parse

    my $query = $query_parser->parse( $query_string );

Turn a query string into a Query object.  Depending on the contents of the
query string, the returned object could be any one of several subclasses of
L<KinoSearch1::Search::Query|KinoSearch1::Search::Query>.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
