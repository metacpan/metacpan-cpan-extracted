package Lingua::ManagementSpeak;
# ABSTRACT: Tool to generate managerial-sounding text and full documents

use 5.010;
use strict;
use warnings;

our $VERSION = '1.06'; # VERSION

sub new {
    my $self = shift;
    return bless( {
        pronouns      => [ qw( I we they ) ],
        articles      => [ qw( the your my our its ) ],
        conj_adverbs  => [ qw( however moreover nevertheless consequently ) ],
        conjuntors    => [ 'though', 'although', 'notwithstanding that', 'yet', 'still' ],
        sub_conjuncs  => [
            'after', 'although', 'as', 'as if', 'as long as', 'as though', 'because',
            'before', 'even if', 'even though', 'if', 'if only', 'in order that',
            'now that', 'once', 'since', 'so that', 'though',
            'unless', 'until', 'when', 'whenever', 'where', 'whereas', 'wherever',
            'while'
        ],
        power_words => [ qw(
            accomplished dealt implemented projected achieved debated improved
            promoted acquired decided included proofed adjusted defined increased
            purchased administered delegated indicated qualified advised delivered
            initiated questioned analyzed demonstrated inspected rated applied
            designed instructed received appraised determined insured recognized
            arranged developed interpreted recommended assessed devised interviewed
            recorded assisted directed introduced recruited assured discovered
            investigated reduced awarded dispensed joined rehabilitated bought
            displayed kept related briefed distributed launched renovated brought
            earned led repaired budgeted edited located reported calculated educated
            maintained represented cataloged elected managed researched chaired
            encouraged maximized reviewed changed enlisted measured revised
            classified ensured mediated selected closed entertained modified served
            coached established motivated simplified combined evaluated named
            sketched communicated examined negotiated sold compared excelled
            observed solved completed executed obtained spearheaded computed
            exhibited operated specified conceived expanded ordered started
            concluded expedited organized streamlined conducted explained paid
            strengthened confronted facilitated participated studied constructed
            financed perceived suggested continued forecast performed summarized
            contracted formulated persuaded supervised controlled gained placed
            targeted convinced gathered planned taught coordinated graded predicted
            tested corrected greeted prepared trained corresponded guided presented
            translated counseled handled processed treated created helped produced
            updated critiqued identified programmed wrote
        ) ],
        verbs => [ qw(
            aggregate architect benchmark brand cultivate deliver deploy
            disintermediate drive e-enable embrace empower enable engage engineer
            enhance envision evolve expedite exploit extend facilitate generate grow
            implement incentivize incubate innovate integrate iterate
            leverage maximize mesh monetize morph optimize orchestrate
            recontextualize reintermediate reinvent repurpose revolutionize scale
            seize strategize streamline syndicate synergize synthesize target
            transform transition unleash utilize visualize whiteboard
        ) ],
        aux_verbs => [
            'will', 'shall', 'may', 'might', 'can', 'could', 'must',
            'ought to', 'should', 'would', 'need to'
        ],
        adjectives => [ qw (
            24/365 24/7 B2B B2C back-end best-of-breed bleeding-edge
            bricks-and-click clicks-and-mortar collaborative compelling
            cross-platform cross-media customized cutting-edge
            distributed dot-com dynamic e-business efficient
            end-to-end enterprise extensible frictionless front-end
            global granular holistic impactful innovative integrated interactive
            intuitive killer leading-edge magnetic mission-critical next-generation
            one-to-one open-source out-of-the-box plug-and-play proactive real-time
            revolutionary robust scalable seamless sexy sticky strategic synergistic
            transparent turn-key ubiquitous user-centric value-added vertical
            viral virtual visionary web-enabled wireless world-class
        )],
        nouns => [ qw(
            action-item application architecture bandwidth channel community
            content convergence deliverable e-business e-commerce e-market
            e-service e-tailer experiences functionality infomediary
            infrastructure initiative interface market methodology metric
            mindshare model network niche paradigm partnership platform
            portal relationship ROI synergy web-readiness schema solution
            supply-chain system technology user
        ) ],
        nounss => [ qw(
            action-items applications architectures channels communities
            convergences deliverables e-businesses e-commerces e-markets
            e-services e-tailers experiences eyeballs functionalities infomediaries
            infrastructures initiatives interfaces markets methodologies metrics
            models networks niches paradigms partnerships platforms
            portals relationships synergies schemas solutions
            supply-chains systems technologies users vortals
        ) ],
    }, ref($self) || $self );
}

sub _random {
    my $high = shift || 5;
    my $low  = shift || 1;
    return int( rand( $high - $low + 1 ) ) + $low;
}

sub words {
    my ( $self, $meta ) = @_;

    # deal with "maybe_n/n_word" meta words
    while ( $meta =~ /maybe[_-](\d+)\/(\d+)[_-](\w+)\S*/ ) {
        my $word = ( _random( $2, $1 ) == $1 ) ? $3 : '';
        if ($word) {
            $meta =~ s/maybe[_-]\d+\/\d+[_-]\w+(\S*)/$word$1/;
        }
        else {
            $meta =~ s/maybe[_-]\d+\/\d+[_-]\w+\S*\s*//;
        }
    }

    # convert "phrase" into phrase meta words
    $meta =~ s/(\w)\s+phrase/$1, phrase/g;
    $meta =~ s/phrase/conjuntor article noun to_be power_word/g;

    while ( $meta =~ /(
        pronoun|article|sub_conjuc|power_word|verb|aux_verb|
        adjective|noun|conj_adverb|conjuntor|sub_conjunc|adverb
    )/x ) {
        # if the word is an adverb, we have to pick a verb and add "ing" to it
        my ( $t1, $t2 ) = ( $1, $1 );
        $t2 = 'verb' if ( $t1 eq 'adverb' );
        my $word = $self->{ $t2 . 's' }[ _random( $#{ $self->{ $t2 . 's' } }, 0 ) ];
        $word =~ s/[e]*$/ing/ if ( $t1 eq 'adverb' );
        $meta =~ s/$t1/$word/;
    }

    # convert "to_be" into the proper conjugated form
    while ( $meta =~ /\b(\w+)\s+to_be/ ) {
        if ( $1 =~ /ess$/ ) {
            $meta =~ s/to_be/is/;
        }
        elsif ( $1 =~ /s$/ ) {
            $meta =~ s/to_be/are/;
        }
        else {
            $meta =~ s/to_be/is/;
        }
    }

    $meta =~ s/^\s+|\s+$//;
    $meta =~ s/\b(a)(\s[aeiouy])/$1n$2/i;

    return $meta;
}

sub sentence {
    my ( $self, $is_first ) = @_;

    my @meta = (
        'article noun to_be power_word sub_conjunc pronoun verb ' .
            'article maybe_1/2_adjective noun maybe_1/3_phrase',
        'sub_conjunc pronoun power_word article maybe_1/2_adjective ' .
            'noun, article maybe_1/2_adjective noun power_word article ' .
            'maybe_1/2_adjective noun maybe_1/4_phrase',
        'pronoun aux_verb verb article maybe_1/2_adjective noun ' .
            'sub_conjunc article adjective noun aux_verb verb article ' .
            'maybe_1/2_adjective noun maybe_1/5_phrase',
        'sub_conjunc pronoun verb article maybe_1/2_adjective noun, ' .
            'pronoun can verb article ' .
            'maybe_1/2_adjective noun maybe_1/4_phrase',
        'pronoun aux_verb verb article maybe_1/2_adjective noun ' .
            'sub_conjunc pronoun verb article ' .
            'maybe_1/2_adjective noun maybe_1/5_phrase',
        'article noun verbs adjective noun',
        'article noun to_be a adjective noun, sub_conjunc article noun verbs article noun',
    );

    my $meta = $meta[ _random( 6, 0 ) ];
    $meta = 'maybe_1/4_conj_adverb, ' . $meta if ( not $is_first );

    return ucfirst( $self->words($meta) ) . '.';
}

sub paragraph {
    my ( $self, $low, $high ) = @_;
    my $count = 0;
    if ( not defined $low ) {
        $count = _random( 7, 4 );
    }
    elsif ( not defined $high ) {
        $count = $low;
    }
    else {
        $count = _random( $high, $low );
    }
    $count--;
    return join( ' ', $self->sentence(1), map { $self->sentence } ( 1 .. $count ) );
}

sub paragraphs {
    my $self = shift;
    my $count = shift || 2;
    my ( $low, $high ) = @_;
    return map { $self->paragraph( $low, $high ) } ( 1 .. $count );
}

sub bullets {
    my ( $self, $meta ) = ( shift, '' );
    my $count = shift || 5;

    my @bullet_forms = (
        'power_word article adjective noun',
        'power_word adjective noun',
        'power_word adjective noun and power_word adjective noun',
        'power_word article noun power_word by article noun',
    );

    return map { ucfirst $self->words( $bullet_forms[ _random( @bullet_forms - 1, 0 ) ] ) } ( 1 .. $count );
}

sub body {
    my ( $self, $params ) = @_;

    $params->{p_min}  = 1  if ( not exists $params->{p_min}  );
    $params->{p_max}  = 3  if ( not exists $params->{p_max}  );
    $params->{b_freq} = 25 if ( not exists $params->{b_freq} );
    $params->{b_min}  = 3  if ( not exists $params->{b_min}  );
    $params->{b_max}  = 6  if ( not exists $params->{b_max}  );

    my @data = ();
    my $p_count = _random( $params->{p_max}, $params->{p_min} );

    foreach ( 1 .. $p_count ) {
        push @data, {
            type => 'paragraph',
            text => $self->paragraphs (1, $params->{p_s_min}, $params->{p_s_max} ),
        };

        # a bulletted list should never be first in a body block
        if (
            ( $_ != $p_count ) and
            ( _random(100, 1 ) < $params->{b_freq} )
        ) {
            my $type = _random( 4, 1 );
            push @data, {
                type => 'bullet',
                text => $self->bullets( 1, $type )
            } foreach ( 1 .. _random( $params->{b_max}, $params->{b_min} ) );
        }
    }

    return \@data;
}

sub header {
    my ( $self, $level ) = @_;

    my $meta = [
        [
            'noun and noun',
            'noun',
            'article noun',
        ],
        'power_word noun',
        'adverb power_word noun',
        'adverb power_word adjective noun',
        'power_word adjective noun adverb noun',
    ];

    $meta = $meta->[ $level - 1 ] if ($level);
    $meta = $meta->[ _random( @$meta - 1, 0 ) ] while ( ref($meta) );

    # capitalize every word with the exception of: of, and, or
    return join( ' ', map {
        join( '-', map { ( $_ !~ /^(of|and|or)$/ ) ? ucfirst : $_ } split('-') )
    } split( ' ', $self->words($meta) ) );
}

sub structure {
    my ( $self, $depth, $last_push ) = ( shift, 1, 0 );
    my $block_limit = shift || 3;
    my $depth_limit = shift || 3;
    my $mimimum_length = shift || 10;
    my @structure = ();

    my $structure;
    $structure = sub {
        my $block = 0;
        while (
            ( $block < _random( $block_limit, 1 ) ) and
            ( ( _random( 4, 1 ) > 1 ) or ( $last_push ne $depth ) )
            # 1/4 chance of exiting early
        ) {
            push( @structure, $depth );
            my $last_push = $depth;
            $block++;
            if (
                ( $depth < $depth_limit ) and
                ( _random( 5, 1 ) > 1 )
                # 1/5 chance of not nesting
            ) {
                $depth++;
                $structure->();
            }
        }
        $depth--;
    };

    while ( @structure < $mimimum_length ) {
        ( $last_push, $depth ) = ( 0, 1 );
        $structure->();
    }
    return @structure;
}

sub document {
    my $self = shift;
    my $structure = shift || [ $self->structure ];
    my $params = shift || undef;

    return [ map {
        {
            type => 'header' . $_,
            text => $self->header($_)
        }, @{ $self->body($params) }
    } ( @{$structure} ) ];
}

sub to_html {
    my ( $self, $data ) = @_;
    my ( $inside_list, $output ) = ( 0, '' );

    for ( @{$data} ) {
        if ( ( $_->{type} ne 'bullet' ) and ($inside_list) ) {
            $inside_list = 0;
            $output .= "</ul>\n";
        }

        if ( $_->{type} =~ /header(\d+)/ ) {
            $output .= '<h' . $1 . '>' . $_->{text} . '</h' . $1 . ">\n";
        }
        elsif ( $_->{type} eq 'paragraph' ) {
            $output .= '<p>' . $_->{text} . "</p>\n";
        }
        elsif ( $_->{type} eq 'bullet' ) {
            my $ul = (not $inside_list) ? "<ul>\n" : '';
            $inside_list++;
            $output .= $ul . '<li>' . $_->{text} . "</li>\n";
        }
        else {
            $output .= '<pre>' . $_->{text} . "</pre>\n";
        }
    }

    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::ManagementSpeak - Tool to generate managerial-sounding text and full documents

=head1 VERSION

version 1.06

=for markdown [![test](https://github.com/gryphonshafer/Lingua-ManagementSpeak/workflows/test/badge.svg)](https://github.com/gryphonshafer/Lingua-ManagementSpeak/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Lingua-ManagementSpeak/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Lingua-ManagementSpeak)

=head1 SYNOPSIS

    use Lingua::ManagementSpeak;
    my $ms = Lingua::ManagementSpeak->new;

    print $ms->words(
        'pronoun article sub_conjunc power_word verb aux_verb adjective ' .
        'noun to_be conj_adverb conjuntor adverb phrase maybe_1/2_phrase'
    );

    print $ms->sentence;
    print $ms->sentence(1);
    print $ms->paragraph;
    print $ms->paragraph(2);
    print $ms->paragraph(2, 3);

    print join("\n\n", $ms->paragraphs(2));
    print join("\n\n", $ms->paragraphs(2, 1));
    print join("\n\n", $ms->paragraphs(2, 1, 3));
    print join("\n\n", $ms->bullets);
    print join("\n\n", $ms->bullets(3));
    print $ms->header;
    print $ms->header(5);
    print join(', ', $ms->structure);
    print join(', ', $ms->structure(3, 3, 5));

    my $body_default = $ms->body;
    my $body_custom  = $ms->body({
        p_min   => 2,
        p_max   => 4,
        p_s_min => 1,
        p_s_max => 1,
        b_freq  => 20,
        b_min   => 4,
        b_max   => 6
    });

    my $document_default = $ms->document;
    my $document_custom  = $ms->document(
        [ 1, 2, 2, 1, 2 ],
        {
            p_min   => 1,
            p_max   => 2,
            p_s_min => 1,
            p_s_max => 3,
            b_freq  => 40,
            b_min   => 3,
            b_max   => 4
        }
    );

    print $ms->to_html($document_custom);

=head1 DESCRIPTION

This module generates (probably) grammatically correct, managerial-sounding text
and full-length documents that mean absolutely nothing. It can output sentences,
paragraphs, and whole documents with embedded structure. The goal is to easily
provide filler or lorem ipsen content that has the potential to pass as real.
This module does for geeks what lorem ipsen does for designers.

Most common cases are the need to create whole documents or just a paragraph
with a few sentences.

    $ms->document;
    $ms->paragraph;

This being said, there are methods that let you hook in at just about any
useful level between word and document.

=head1 METHODS

The most commonly used method (at least for me) is C<document()>. It calls
several other methods internally and returns a randomly generated document
based on some good defaults. However, you can tap into the process at
a variety of levels.

=head2 new

Simple instantiator. Nothing special.

    my $ms = Lingua::ManagementSpeak->new;

=head2 words

Using a text string of meta words, this returns a management-speak
block of text. It parses the meta string and converts each meta word into
a randomly picked associated real word.

    my $real_words = $ms->words($meta_words_string);
    print $ms->words('verb article adjective noun');

Currently supported meta words include:

=over 4

=item noun

Nouns like: paradigms, interfaces, solutions, markets, and synergies

=item verb

Verbs like: expedite, revolutionize, visualize, facilitate, and maximize

=item pronoun

Pronouns: I, we, and they.

=item adjective

Adjectives like: innovative, extensible, seamless, distributed, and interactive

=item adverb

Adverbs like: expediting, revolutionizing, visualizing, facilitating,
and maximizing

=item aux_verb

Auxilary verbs: will, shall, may, might, can, could, must, ought to,
should, would, and need to

=item article

Articles: the, your, my, our, this, and its

=item conjuntor

Conjuntors: though, although, notwithstanding, yet, still

=item sub_conjunc

Subordinate conjuntors like: even though, if, in order that, so that, and until

=item power_word

So-called management "power words" like:
assured, discovered, sketched, communicated, examine, and modified

=item conj_adverb

Conjunctive adverbs: however, moreover, nevertheless, and consequently

=item to_be

This looks at the preceding word and conjugates the verb "to be" accordingly,
placing it next in the returned string.

=item phrase

This is a keyword that gets literally translated into:
"conjuntor article noun to_be power_word"

=item maybe_n/n_word

This is a fun little keyword that says, "insert 'word' here every n/n times."
For example, "maybe_1/4_noun" will insert a random noun at this point in
the string 25% of the time. This also works with stuff like "phrase" to give
you "maybe_1/2_phrase" things.

=back

The meta string gets searched for these keywords, so you can usually insert
extra text into the meta string and it will come through as expected:

    print $ms->words('I need you to verb the adjective noun.');
    # Might return: "I need you to expedite the customized interfaces."

=head2 sentence

This returns a fully-formed sentence randomly selected from a set of
pre-defined patterns. It accepts a true or false input. If true, the returned
sentence is assumed to be the lead sentence of a paragraph and will therefore
not contain a leading conjunctive adverb. The default is false, which means
there is a 1/4 change of a leading conjunctive adverb.

    print $ms->sentence(1);
    # Might return: "Our mindshare engages open-source architectures."

    print $ms->sentence;
    # Might return:
    #   "Consequently, our mindshare engages open-source architectures."

=head2 paragraph

This returns a paragraph with a certain number of constructed sentences.
It accepts either two or one integers. If passed two, it returns a paragraph
consisting of n sentences where n is between the two integers.
(The lower integer should get passed in first.) If passed
only one, then it returns that number of sentences. If no integers are
passed, it returns between 4 and 7 sentences.

    print $ms->paragraph;       # Returns between 4 and 7 sentences.
    print $ms->paragraph(2);    # Returns 2 sentences.
    print $ms->paragraph(2, 5); # Returns between 2 and 5 sentences.

=head2 paragraphs

This returns a set of paragraphs. You can optionally supply a number of
paragraphs to return and sentence parameters like sentence count per
paragraph or a range for sentence count.

    my @paragraphs1 = $ms->paragraphs($total_paragraphs, $sentence_count);
    my @paragraphs2 = $ms->paragraphs(
        $total_paragraphs,
        $sentence_min,
        $sentence_max
    );

    # Returns two paragraphs
    my @paragraphs3 = $ms->paragraphs(2);

    # Returns two paragraphs, each with three sentences
    my @paragraphs4 = $ms->paragraphs(2, 3);

    # Returns two paragraphs, each with between one and three sentences
    my @paragraphs5 = $ms->paragraphs(2, 1, 3);

=head2 bullets

This returns a certain number of bullet items, either defined or random.
The elements within each set of bullets will be written in parallel
structure, but each set may be different than the others. Each bullet is
just a string that's capitalized.

    my @bullets = $ms->bullets(5); # Returns five bullet items (just strings)

There are no periods at the end of each bullet. If you want your bulletted
lists to have periods, you have to add them yourself; but you shouldn't,
because periods at the end of bullet items are dumb.

=head2 body

This will build a "body" chunk that you might find inside any given section
of a document. It will only ever contain paragraphs and bulletted lists.
The method returns a reference to an array where each element is a reference
to a hash containing two keys: type and text. Type will be either paragraph or
bullet.

It accepts parameters in a reference to a hash as follows:

    my $ref_to_array = $ms->body({
        p_min   => 2,  # Minimum number of paragraphs to return
        p_max   => 4,  # Maximum number of paragraphs to return
        p_s_min => 1,  # Minimum number of sentences in a paragraph
        p_s_max => 1,  # Maximum number of sentences in a paragraph
        b_freq  => 20, # % chance of a bulletted list after each paragraph
        b_min   => 4,  # Minimum number of bullet items in a bulletted list
        b_max   => 6   # Maximum number of bullet items in a bulletted list
    });

Note that C<body()> will work without any parameters.

By the way, if you're reading this far into the POD, you've earned the
privilege to gripe about any bugs you find.

The data structure of C<$ref_to_array> might look something like this:

    [
        {
            type => 'paragraph',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'bullet',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'bullet',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'paragraph',
            text => 'blah ... blah ... blah'
        }
    ]

=head2 header

This returns a correctly formatted (meaning most words will appear in
upper-case) text string for use as a header. It accepts a single whole number
integer between 5 and 1 that represents the "level" of header.
Header 1 is highest, 2 is next, etc.
If no integer is given, it will randomly pick a number between 5 and 1.

    my $header = $ms->header(3);
    # Might return: "Monetizing Distributed Partnerships"

=head2 structure

This returns an array of numbers, each number representing a "heading level"
for a document structure. The purpose of this method is to build what could
pass for a real document's information architecture.

    my @structure1 = $ms->structure;
    my @structure2 = $ms->structure($block_limit, $depth_limit, $mimimum_length);

C<$block_limit> is the maximum of any similar heading level within the same
parent level. C<$depth_limit> is how deep the levels are allowed to nest.
C<$minimum_length> is, well, the minimum length.

=head2 document

This is my favorite function. It builds a complete document with a structure
and body sections containing paragraphs and bulletted lists.
It returns a reference to an array containing hash references, similar to body.
It works solo, but it can optionally accept a reference to an array with
the document structure and a reference to a hash containing body parameters.

    my $ref_to_array1 = $ms->document;
    my $ref_to_array2 = $ms->document(\@structure,    \%body_parameters);
    my $ref_to_array3 = $ms->document($ms->structure, \%body_parameters);

The "type" for each header will be referenced along with it's level. For
example, a header 1 will be C<header1>.
The data structure of C<$ref_to_array1> might look something like this:

    [
        {
            type => 'header1',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'paragraph',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'bullet',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'bullet',
            text => 'blah ... blah ... blah'
        },
        {
            type => 'paragraph',
            text => 'blah ... blah ... blah'
        }
    ]

=head2 to_html

This accepts either a C<body()> or C<document()> result and converts it into
mostly good HTML. By mostly, I mean that you could probably parse it with
some simple regexes, but it ain't gonna validate against the W3C.

    my $html_body = $ms->to_html($ms->body);
    my $html_doc  = $ms->to_html($ms->document);

I tossed this in here because I use this functionality a lot. If you want to
build real web pages, you should probably use something better than this
function.

=head1 SEE ALSO

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Lingua-ManagementSpeak>

=item *

L<MetaCPAN|https://metacpan.org/pod/Lingua::ManagementSpeak>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Lingua-ManagementSpeak/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Lingua-ManagementSpeak>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Lingua-ManagementSpeak>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/L/Lingua-ManagementSpeak.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
