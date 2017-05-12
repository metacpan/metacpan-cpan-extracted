package HTML::Summary;
$HTML::Summary::VERSION = '0.022';
#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

HTML::Summary - generate a summary from a web page

=head1 SYNOPSIS

 use HTML::Summary;
 use HTML::TreeBuilder;
 
 my $tree = HTML::TreeBuilder->new;
 $tree->parse( $document );

 my $summarizer = HTML::Summary->new(
     LENGTH      => 200,
     USE_META    => 1,
 );

 $summary = $summarizer->generate( $tree );
 $summarizer->option( 'USE_META' => 1 );
 $length = $summarizer->option( 'LENGTH' );
 if ( $summarizer->meta_used() ) {
     # do something
 }

=head1 DESCRIPTION

The C<HTML::Summary> module produces summaries from the textual content of
web pages. It does so using the location heuristic, which determines the value
of a given sentence based on its position and status within the document; for
example, headings, section titles and opening paragraph sentences may be
favoured over other textual content. A LENGTH option can be used to restrict
the length of the summary produced.

=head1 CONSTRUCTOR

=head2 new( $attr1 => $value1 [, $attr2 => $value2 ] )

Possible attributes are:

=over 4

=item VERBOSE

Generate verbose messages to STDERR.

=item LENGTH

Maximum length of summary (in bytes). Default is 500.

=item USE_META

Flag to tell summarizer whether to use the content of the C<<META>> tag
in the page header, if one is present, instead of generating a summary from the
body text. B<Note that> if the USE_META flag is set, this overrides the LENGTH
flag - in other words, the summary provided by the C<<META>> tag is
returned in full, even if it is greater than LENGTH bytes. Default is 0 (no).

=back

 my $summarizer = HTML::Summary->new(LENGTH => 200);

=head1 METHODS

=head2 option( )

Get / set HTML::Summary configuration options.

 my $length = $summarizer->option( 'LENGTH' );
 $summarizer->option( 'USE_META' => 1 );

=head2 generate( $tree )

Takes an HTML::Element object, and generates a summary from it.

 my $tree = HTML::TreeBuilder->new;
 $tree->parse( $document );
 my $summary = $summarizer->generate( $tree );

=head2 meta_used( )

Returns 1 if the META tag description was used to generate the summary.

 if ( $summarizer->meta_used() ) {
     # do something ...
 }

=head1 SEE ALSO

L<HTML::TreeBuilder>,
L<Text::Sentence>,
L<Lingua::JA::Jcode>,
L<Lingua::JA::Jtruncate>.

=head1 REPOSITORY

L<https://github.com/neilb/HTML-Summary>

=head1 AUTHORS

This module was originally whipped up by Neil Bowers and Tony Rose.
It was then developed and maintained by Ave Wrigley and Tony Rose.

Neil Bowers is currently maintaining the HTML-Summary distribution.

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1997 Canon Research Centre Europe (CRE). All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#==============================================================================
#
# End of POD
#
#==============================================================================

#==============================================================================
#
# Pragmas
#
#==============================================================================

require 5.006;
use strict;
use warnings;

#==============================================================================
#
# Modules
#
#==============================================================================

use Text::Sentence qw( split_sentences );
use Lingua::JA::Jtruncate qw( jtruncate );

#==============================================================================
#
# Constants
#
#==============================================================================

use constant IGNORE_TEXT => 1;

#==============================================================================
#
# Private globals
#
#==============================================================================

my $DEFAULT_SCORE = 0;

my %ELEMENT_SCORES = (
    'p'         => 100,
    'h1'        => 90,
    'h2'        => 80,
    'h3'        => 70,
);

my %DEFAULTS = (
    'USE_META'  => 0,
    'VERBOSE'   => 0,
    'LENGTH'    => 500,
);

#==============================================================================
#
# Public methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# new - constructor. Configuration through "hash" type arguments, i.e.
# my $abs = HTML::Summary->new( VAR1 => 'foo', VAR2 => 'bar' );
#
#------------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my $self = bless { }, $class;
    return $self->_initialize( @_ );
}

#------------------------------------------------------------------------------
#
# generate - main public interface method to generate a summary
#
#------------------------------------------------------------------------------

sub generate
{
    my $self = shift;
    my $tree = shift;

    my $summary;

    $self->_verbose( 'Generate summary ...' );

    # check to see if there is a summary already defined in a META tag ...

    if ( 
        $self->{ USE_META } and 
        $summary = $self->_get_summary_from_meta( $tree ) 
    )
    {
        $self->_verbose( "use summary from META tag ..." );
        $self->_verbose( $summary );
        return $summary;
    }

    # traverse the HTML tree, building up @summary array

    my @summary = $self->_get_summary( $tree );

    # sort @summary by score, truncate if it is greater than LENGTH
    # characters, and the re-sort by original order. Truncate AFTER the LENGTH
    # has been exceeded, so that last sentence is truncated later by
    # jtruncate

    @summary = sort { $b->{ score } <=> $a->{ score } } @summary;

    my $tot_length = 0;
    my @truncated = ();

    for ( @summary )
    {
        push( @truncated, $_ );
        last if ( $tot_length += $_->{ 'length' } ) > $self->{ LENGTH };
    }
    @truncated = sort { $a->{ order } <=> $b->{ order } } @truncated;

    # these whitespaces will push the length over LENGTH, but jtruncate
    # should take care of this

    $summary = join( ' ', map { $_->{ text } } @truncated );
    $self->_verbose( "truncate the summary to ", $self->{ LENGTH } );
    $summary = jtruncate( $summary, $self->{ LENGTH } );
    return $summary;
}

#------------------------------------------------------------------------------
#
# meta_used - tells whether the description from the META tag was used; returns
# 1 if it was, 0 if the summary was generated automatically
#
#------------------------------------------------------------------------------

sub meta_used
{
    my $self = shift;

    return $self->{ META_USED };
}

#------------------------------------------------------------------------------
#
# option - get / set configuration option
#
#------------------------------------------------------------------------------

sub option
{
    my $self    = shift;
    my $option  = shift;
    my $val     = shift;

    die "No HTML::Summary option name given" unless defined $option;
    die "$option is not an HTML::Summary option" unless 
        grep { $_ eq $option } keys %DEFAULTS
    ;

    if ( defined $val )
    {
        $self->{ $option } = $val;
    }

    return $self->{ $option } = $val;
}

#==============================================================================
#
# Private methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# _initialize - supports sub-classing
#
#------------------------------------------------------------------------------

sub _initialize
{
    my $self = shift;

    return undef unless @_ % 2 == 0;    # check that config hash has even no.
                                        # of elements

    %{ $self } = ( %DEFAULTS, @_ );     # set options from defaults / config.
                                        # hash passed as arguments

    return $self;
}

#------------------------------------------------------------------------------
#
# _verbose - generate verbose error messages, if the VERBOSE option has been
# selected
#
#------------------------------------------------------------------------------

sub _verbose
{
    my $self = shift;

    return unless $self->{ VERBOSE };
    print STDERR @_, "\n";
}

#------------------------------------------------------------------------------
#
# _get_summary - get sentences from an element to generate the summary from.
# Uses lexically scoped array @sentences to build up result from the traversal
# callback
#
#------------------------------------------------------------------------------

sub _get_summary
{
    my $self = shift;
    my $tree = shift;

    my @summary = ();
    my $add_sentence = sub {
        my $text        = shift;
        my $tag         = shift;
        my $score       = shift || $DEFAULT_SCORE;

        return unless $text =~ /\w/;

        $text =~ s!^\s*!!; # remove leading ...
        $text =~ s!\s*$!!; # ... and trailing whitespace

        $summary[ scalar( @summary ) ] = {
            'text'          => $text,
            'length'        => length( $text ),
            'tag'           => $tag,
            'score'         => $score,
            'order'         => scalar( @summary ),
        };
    };
    $tree->traverse(
        sub {
            my $node = shift;
            my $flag = shift;

            if ( $flag ) # entering node ...
            {
                my $tag = $node->tag;
                return 0 if $tag eq 'head';

                # add sentences which either are scoring, or span no other
                # scoring sentences (and have a score of 0).  In this way, all
                # text is captured, even if it scores 0; the only exception is
                # something like <BODY>some text <P>foobar</P></BODY>, where
                # everything but "foobar" will be lost. However, if you have
                # <BODY><TD>some text</TD><P>foobar</P></BODY> you should get
                # all the text.

                if ( 
                    $ELEMENT_SCORES{ $tag } || 
                    ! _has_scoring_element( $node ) 
                )
                {
                    my $text = _get_text( $node );
                    foreach ( $text ) # alias $_ to $text
                    {
                        # get rid of whitespace (including &nbsp;) from start /
                        # end of $text
                        s/^[\s\160]*//;
                        s/[\s\160]*$//;
                        # get rid of any spurious tags that have slipped
                        # through the HTML::TreeBuilder
                        s!<[^>]+>!!g;
                    }

                    if ( $text =~ /\S/ )
                    {
                        my $score = $ELEMENT_SCORES{ $tag } || $DEFAULT_SCORE;

                        # add all the sentences in the text. Only the first
                        # sentence gets the element score - the rest get the
                        # default score

                        $self->_verbose( "TEXT: $text" );
                        for my $sentence ( 
                            split_sentences( $text, $self->{ 'LOCALE' } )
                        )
                        {
                            $self->_verbose( "SENTENCE: $text" );
                            $add_sentence->( $sentence, $tag, $score );
                            $score = $DEFAULT_SCORE;
                        }
                    }

                    # return 0 to avoid getting the same sentence in a scoring
                    # "daughter" element

                    return 0;
                }
            }

            # continue traversal ...

            return 1;
        },
        IGNORE_TEXT
    );
    return @summary;
}

#------------------------------------------------------------------------------
#
# _get_summary_from_meta - check to see if there is already a summary
# defined in the META tag in the HEAD
#
#------------------------------------------------------------------------------

sub _get_summary_from_meta
{
    my $self = shift;
    my $tree = shift;

    my $summary;

    $tree->traverse(
        sub {
            my $node = shift;
            my $flag = shift;

            if ($node->tag eq 'meta'
                && defined($node->attr('name'))
                && lc( $node->attr('name') ) eq 'description'
                && defined($node->attr('content')))
            {
                $summary = $node->attr( 'content' );
                $summary = undef if $summary eq 'content';
                return 0;
            }
            return 1;
        },
        IGNORE_TEXT
    );

    $self->{ META_USED } = defined( $summary ) ? 1 : 0;
    return $summary;
}

#==============================================================================
#
# Private functions
#
#==============================================================================

#------------------------------------------------------------------------------
#
# _get_text - get all the text spanned by an element. Uses lexically scoped
# variable $html to build up result from the traversal callback
#
#------------------------------------------------------------------------------
    
sub _get_text
{
    my $node = shift;
    
    my $html = '';
    $node->traverse(
        sub {
            my $node = shift;
            $html .= $node unless ref( $node );
            return 1;
        }
    );
    return $html;
}

#------------------------------------------------------------------------------
#
# _has_scoring_element - check to see if this element spans any scoring
# element.  Uses lexically scoped variable $has_scoring_element to build up
# result from the traversal callback.
#
#------------------------------------------------------------------------------

sub _has_scoring_element
{
    my $node = shift;
    
    my $has_scoring_element = 0;
    $node->traverse(
        sub {
            my $node = shift;
            my $tag = $node->tag;
            $has_scoring_element ||= $ELEMENT_SCORES{ $tag };
            return 1;
        },
        IGNORE_TEXT
    );
    return $has_scoring_element;
}

#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
