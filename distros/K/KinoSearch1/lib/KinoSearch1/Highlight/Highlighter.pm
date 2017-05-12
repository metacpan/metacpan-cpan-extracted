package KinoSearch1::Highlight::Highlighter;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );
use locale;

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        excerpt_field  => undef,
        analyzer       => undef,
        formatter      => undef,
        encoder        => undef,
        terms          => undef,
        excerpt_length => 200,
        pre_tag        => undef,                  # back compat
        post_tag       => undef,                  # back compat
        token_re       => qr/\b\w+(?:'\w+)?\b/,

        # members
        limit => undef,
    );
    __PACKAGE__->ready_get_set(qw( terms ));
}

use KinoSearch1::Highlight::SimpleHTMLFormatter;
use KinoSearch1::Highlight::SimpleHTMLEncoder;

sub init_instance {
    my $self = shift;
    croak("Missing required arg 'excerpt_field'")
        unless defined $self->{excerpt_field};
    $self->{terms} = [];

    # assume HTML
    if ( !defined $self->{encoder} ) {
        $self->{encoder} = KinoSearch1::Highlight::SimpleHTMLEncoder->new;
    }
    if ( !defined $self->{formatter} ) {
        my ( $pre_tag, $post_tag ) = @{$self}{qw( pre_tag post_tag )};
        $pre_tag  = '<strong>'  unless defined $pre_tag;
        $post_tag = '</strong>' unless defined $post_tag;
        $self->{formatter} = KinoSearch1::Highlight::SimpleHTMLFormatter->new(
            pre_tag  => $pre_tag,
            post_tag => $post_tag,
        );
    }

    # scoring window is 1.66 * excerpt_length, with the loc in the middle
    $self->{limit} = int( $self->{excerpt_length} / 3 );
}

sub generate_excerpt {
    my ( $self, $doc ) = @_;
    my $excerpt_length = $self->{excerpt_length};
    my $limit          = $self->{limit};
    my $token_re       = $self->{token_re};

    # retrieve the text from the chosen field
    my $field       = $doc->get_field( $self->{excerpt_field} );
    my $text        = $field->get_value;
    my $text_length = bytes::length $text;
    return '' unless $text_length;

    # determine the rough boundaries of the excerpt
    my $posits        = $self->_starts_and_ends($field);
    my $best_location = $self->_calc_best_location($posits);
    my $top           = $best_location - $limit;

    # expand the excerpt if the best location is near the end
    $top
        = $text_length - $excerpt_length < $top
        ? $text_length - $excerpt_length
        : $top;

    # if the best starting point is the very beginning, cool...
    if ( $top <= 0 ) {
        $top = 0;
    }
    # ... otherwise ...
    else {
        # lop off $top bytes
        $text = bytes::substr( $text, $top );

        # try to start the excerpt at a sentence boundary
        if ($text =~ s/
                \A
                (
                \C{0,$limit}?
                \.\s+
                )
                //xsm
            )
        {
            $top += bytes::length($1);
        }
        # no sentence boundary, so we'll need an ellipsis
        else {
            # skip past possible partial tokens, prepend an ellipsis
            if ($text =~ s/
                \A
                (
                \C{0,$limit}?  # don't go outside the window
                $token_re      # match possible partial token
                .*?            # ... and any junk following that token
                )
                (?=$token_re)  # just before the start of a full token...
                /... /xsm    # ... insert an ellipsis
                )
            {
                $top += bytes::length($1);
                $top -= 4    # three dots and a space
            }
        }
    }

    # remove possible partial tokens from the end of the excerpt
    $text = bytes::substr( $text, 0, $excerpt_length + 1 );
    if ( bytes::length($text) > $excerpt_length ) {
        my $extra_char = chop $text;
        # if the extra char wasn't part of a token, we aren't splitting one
        if ( $extra_char =~ $token_re ) {
            $text =~ s/$token_re$//;    # if this is unsuccessful, that's fine
        }
    }

    # if the excerpt doesn't end with a full stop, end with an an ellipsis
    if ( $text !~ /\.\s*\Z/xsm ) {
        $text =~ s/\W+\Z//xsm;
        while ( bytes::length($text) + 4 > $excerpt_length ) {
            my $extra_char = chop $text;
            if ( $extra_char =~ $token_re ) {
                $text =~ s/\W+$token_re\Z//xsm; # if unsuccessful, that's fine
            }
            $text =~ s/\W+\Z//xsm;
        }
        $text .= ' ...';
    }

    # remap locations now that we know the starting and ending bytes
    $text_length = bytes::length($text);
    my @relative_starts = map { $_->[0] - $top } @$posits;
    my @relative_ends   = map { $_->[1] - $top } @$posits;

    # get rid of pairs with at least one member outside the text
    while ( @relative_starts and $relative_starts[0] < 0 ) {
        shift @relative_starts;
        shift @relative_ends;
    }
    while ( @relative_ends and $relative_ends[-1] > $text_length ) {
        pop @relative_starts;
        pop @relative_ends;
    }

    # insert highlight tags
    my $formatter   = $self->{formatter};
    my $encoder     = $self->{encoder};
    my $output_text = '';
    my ( $start, $end, $last_start, $last_end ) = ( undef, undef, 0, 0 );
    while (@relative_starts) {
        $end   = shift @relative_ends;
        $start = shift @relative_starts;
        $output_text .= $encoder->encode(
            bytes::substr( $text, $last_end, $start - $last_end ) );
        $output_text
            .= $formatter->highlight(
            $encoder->encode( bytes::substr( $text, $start, $end - $start ) )
            );
        $last_end = $end;
    }
    $output_text .= $encoder->encode( bytes::substr( $text, $last_end ) );

    return $output_text;
}

=for comment
Find all points in the text where a relevant term begins and ends.  For terms
that are part of a phrase, only include points that are part of the phrase.

=cut

sub _starts_and_ends {
    my ( $self, $field ) = @_;
    my @posits;
    my %done;

TERM: for my $term ( @{ $self->{terms} } ) {
        if ( a_isa_b( $term, 'KinoSearch1::Index::Term' ) ) {
            my $term_text = $term->get_text;

            next TERM if $done{$term_text};
            $done{$term_text} = 1;

            # add all starts and ends
            my $term_vector = $field->term_vector($term_text);
            next TERM unless defined $term_vector;
            my $starts = $term_vector->get_start_offsets;
            my $ends   = $term_vector->get_end_offsets;
            while (@$starts) {
                push @posits, [ shift @$starts, shift @$ends, 1 ];
            }
        }
        # intersect positions for phrase terms
        else {
            # if not a Term, it's an array of Terms representing a phrase
            my @term_texts = map { $_->get_text } @$term;

            my $phrase_text = join( ' ', @term_texts );
            next TERM if $done{$phrase_text};
            $done{$phrase_text} = 1;

            my $posit_vec = KinoSearch1::Util::BitVector->new;
            my @term_vectors = map { $field->term_vector($_) } @term_texts;

            # make sure all terms are present
            next TERM unless scalar @term_vectors == scalar @term_texts;

            my $i = 0;
            for my $tv (@term_vectors) {
                # one term missing, ergo no phrase
                next TERM unless defined $tv;
                if ( $i == 0 ) {
                    $posit_vec->set( @{ $tv->get_positions } );
                }
                else {
                    # filter positions using logical "and"
                    my $other_posit_vec = KinoSearch1::Util::BitVector->new;
                    $other_posit_vec->set(
                        grep    { $_ >= 0 }
                            map { $_ - $i } @{ $tv->get_positions }
                    );
                    $posit_vec->logical_and($other_posit_vec);
                }
                $i++;
            }

            # add only those starts/ends that belong to a valid position
            my $tv_start_positions = $term_vectors[0]->get_positions;
            my $tv_starts          = $term_vectors[0]->get_start_offsets;
            my $tv_end_positions   = $term_vectors[-1]->get_positions;
            my $tv_ends            = $term_vectors[-1]->get_end_offsets;
            $i = 0;
            my $j                = 0;
            my $last_token_index = $#term_vectors;
            for my $valid_position ( @{ $posit_vec->to_arrayref } ) {

                while ( $i <= $#$tv_start_positions ) {
                    last if ( $tv_start_positions->[$i] >= $valid_position );
                    $i++;
                }
                $valid_position += $last_token_index;
                while ( $j <= $#$tv_end_positions ) {
                    last if ( $tv_end_positions->[$j] >= $valid_position );
                    $j++;
                }
                push @posits,
                    [ $tv_starts->[$i], $tv_ends->[$j], scalar @$term ];
                $i++;
                $j++;
            }
        }
    }

    # sort, uniquify and return
    @posits = sort { $a->[0] <=> $b->[0] || $b->[1] <=> $a->[1] } @posits;
    my @unique;
    my $last = ~0;
    for (@posits) {
        push @unique, $_ if $_->[0] != $last;
        $last = $_->[0];
    }
    return \@unique;
}

=for comment 
Select the byte address representing the greatest keyword density.  Because
the algorithm counts bytes rather than characters, it will degrade if the
number of bytes per character is larger than 1.

=cut

sub _calc_best_location {
    my ( $self, $posits ) = @_;
    my $window = $self->{limit} * 2;

    # if there aren't any keywords, take the excerpt from the top of the text
    return 0 unless @$posits;

    my %locations = map { ( $_->[0] => 0 ) } @$posits;

    # if another keyword is in close proximity, add to the loc's score
    for my $loc_index ( 0 .. $#$posits ) {
        # only score positions that are in range
        my $location        = $posits->[$loc_index][0];
        my $other_loc_index = $loc_index - 1;
        while ( $other_loc_index > 0 ) {
            my $diff = $location - $posits->[$other_loc_index][0];
            last if $diff > $window;
            my $num_tokens_at_pos = $posits->[$other_loc_index][2];
            $locations{$location}
                += ( 1 / ( 1 + log($diff) ) ) * $num_tokens_at_pos;
            --$other_loc_index;
        }
        $other_loc_index = $loc_index + 1;
        while ( $other_loc_index <= $#$posits ) {
            my $diff = $posits->[$other_loc_index] - $location;
            last if $diff > $window;
            my $num_tokens_at_pos = $posits->[$other_loc_index][2];
            $locations{$location}
                += ( 1 / ( 1 + log($diff) ) ) * $num_tokens_at_pos;
            ++$other_loc_index;
        }
    }

    # return the highest scoring position
    return ( sort { $locations{$b} <=> $locations{$a} } keys %locations )[0];
}

1;

__END__

=head1 NAME

KinoSearch1::Highlight::Highlighter - create and highlight excerpts

=head1 SYNOPSIS

    my $highlighter = KinoSearch1::Highlight::Highlighter->new(
        excerpt_field  => 'bodytext',
    );
    $hits->create_excerpts( highlighter => $highlighter );

=head1 DESCRIPTION

KinoSearch1's Highlighter can be used to select a relevant snippet from a
document, and to surround search terms with highlighting tags.  It handles
both stems and phrases correctly and efficiently, using special-purpose data
generated at index-time.  

=head1 METHODS

=head2 new

    my $highlighter = KinoSearch1::Highlight::Highlighter->new(
        excerpt_field  => 'bodytext', # required
        excerpt_length => 150,        # default: 200
        formatter      => $formatter, # default: SimpleHTMLFormatter
        encoder        => $encoder,   # default: SimpleHTMLEncoder
    );

Constructor.  Takes hash-style parameters: 

=over

=item *

B<excerpt_field> - the name of the field from which to draw the excerpt.  This
field B<must> be C<vectorized>.

=item *

B<excerpt_length> - the length of the excerpt, in I<bytes>.  This should
probably use characters as a unit instead of bytes, and the behavior is likely
to change in the future.

=item *

B<formatter> - an object which subclasses L<KinoSearch1::Highlight::Formatter>,
used to perform the actual highlighting.

=item *

B<encoder> - an object which subclasses L<KinoSearch1::Highlight::Encoder>.
All excerpt text gets passed through the encoder, including highlighted terms.
By default, this is a SimpleHTMLEncoder, which encodes HTML entities.

=item *

B<pre_tag> - deprecated.  

=item *

B<post_tag> - deprecated.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
