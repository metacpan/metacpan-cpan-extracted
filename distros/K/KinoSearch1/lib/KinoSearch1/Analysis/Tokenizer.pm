package KinoSearch1::Analysis::Tokenizer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Analysis::Analyzer );
use locale;

BEGIN {
    __PACKAGE__->init_instance_vars(

        # constructor params / members
        token_re => undef,    # regex for a single token

        # members
        separator_re => undef,    # regex for separations between tokens
    );
}

use KinoSearch1::Analysis::TokenBatch;

sub init_instance {
    my $self = shift;

    # supply defaults if token_re wasn't specified
    if ( !defined $self->{token_re} ) {
        $self->{token_re}     = qr/\b\w+(?:'\w+)?\b/;
        $self->{separator_re} = qr/\W*/;
    }

    # if user-defined token_re...
    if ( !defined $self->{separator_re} ) {

        # define separator using lookahead
        $self->{separator_re} = qr/
            .*?                    # match up to...
            (?=                    # but not including...
                $self->{token_re}  # a token, 
                |\z                # or the end of the string
            )/xsm;
    }
}

sub analyze {
    my ( $self, $batch ) = @_;

    my $new_batch    = KinoSearch1::Analysis::TokenBatch->new;
    my $token_re     = $self->{token_re};
    my $separator_re = $self->{separator_re};

    # alias input to $_
    while ( $batch->next ) {
        local $_ = $batch->get_text;

        # ensure that pos is set to 0 for this scalar
        pos = 0;

        # accumulate token start_offsets and end_offsets
        my ( @starts, @ends );
        1 while ( m/$separator_re/g and push @starts,
            pos and m/$token_re/g and push @ends, pos );

        # correct for overshoot
        $#starts = $#ends;

        # add the new tokens to the batch
        $new_batch->add_many_tokens( $_, \@starts, \@ends );
    }

    return $new_batch;
}

1;

__END__

=head1 NAME

KinoSearch1::Analysis::Tokenizer - customizable tokenizing 

=head1 SYNOPSIS

    my $whitespace_tokenizer
        = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/\S+/, );

    # or...
    my $word_char_tokenizer
        = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/\w+/, );

    # or...
    my $apostrophising_tokenizer = KinoSearch1::Analysis::Tokenizer->new;

    # then... once you have a tokenizer, put it into a PolyAnalyzer
    my $polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
        analyzers => [ $lc_normalizer, $word_char_tokenizer, $stemmer ], );


=head1 DESCRIPTION

Generically, "tokenizing" is a process of breaking up a string into an array
of "tokens".

    # before:
    my $string = "three blind mice";

    # after:
    @tokens = qw( three blind mice );

KinoSearch1::Analysis::Tokenizer decides where it should break up the text
based on the value of C<token_re>.

    # before:
    my $string = "Eats, Shoots and Leaves.";

    # tokenized by $whitespace_tokenizer
    @tokens = qw( Eats, Shoots and Leaves. );

    # tokenized by $word_char_tokenizer
    @tokens = qw( Eats Shoots and Leaves   );

=head1 METHODS

=head2 new

    # match "O'Henry" as well as "Henry" and "it's" as well as "it"
    my $token_re = qr/
            \b        # start with a word boundary
            \w+       # Match word chars.
            (?:       # Group, but don't capture...
               '\w+   # ... an apostrophe plus word chars.
            )?        # Matching the apostrophe group is optional.
            \b        # end with a word boundary
        /xsm;
    my $tokenizer = KinoSearch1::Analysis::Tokenizer->new(
        token_re => $token_re, # default: what you see above
    );

Constructor.  Takes one hash style parameter.

=over

=item *

B<token_re> - must be a pre-compiled regular expression matching one token.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
