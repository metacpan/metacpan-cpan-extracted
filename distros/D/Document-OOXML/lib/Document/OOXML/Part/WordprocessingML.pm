use utf8;
package Document::OOXML::Part::WordprocessingML;
use Moose;
use namespace::autoclean;

with 'Document::OOXML::Part';

# ABSTRACT: WordprocessingML document part handling

use Carp;
use List::Util qw(first);
use XML::LibXML;


has xml => (
    is       => 'ro',
    isa      => 'XML::LibXML::Document',
    required => 1,
);


has xpc => (
    is       => 'ro',
    isa      => 'XML::LibXML::XPathContext',
    required => 1,
);

has is_strict => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

sub to_string {
    my $self = shift;
    return $self->xml->toString();
}

my %XML_NS = (
    strict       => 'http://purl.oclc.org/ooxml/wordprocessingml/main',
    transitional => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',

    relationships_strict => 'http://purl.oclc.org/ooxml/officeDocument/relationships',
    relationships        => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
);


sub new_from_xml {
    my $class = shift;
    my $part_name = shift;
    my $xml       = shift;
    my $is_strict = shift;

    my $doc = XML::LibXML->load_xml( string => $xml );
    my $xpc = XML::LibXML::XPathContext->new();

    if ($is_strict) {
        $xpc->registerNs('w' => $XML_NS{strict});
        $xpc->registerNs('r' => $XML_NS{relationships_strict});
    } else {
        $xpc->registerNs('w' => $XML_NS{transitional});
        $xpc->registerNs('r' => $XML_NS{relationships});
    }

    return $class->new(
        part_name => $part_name,
        xml       => $doc,
        xpc       => $xpc,
        is_strict => $is_strict,
    );
}

sub _clone_run {
    my $self = shift;
    my $run = shift;

    my $new_run = $run->cloneNode(0);

    my ($run_props) = $self->xpc->findnodes('./w:rPr', $run);
    if ($run_props) {
        my $new_props = $run_props->cloneNode(1);
        $new_run->appendChild($new_props);
    }

    return $new_run;
}


sub find_text_nodes {
    my $self = shift;
    my $regex = shift;
    my $exclude_tables = shift;

    my $text_element_query = $exclude_tables
        ? '//w:r[child::w:t and not(ancestor::w:tbl)]'
        : '//w:r[child::w:t]';

    my @matching_nodes;

    # Find all text nodes matching $regex that are not in a table
    my $runs = $self->xpc->findnodes($text_element_query, $self->xml->documentElement);
    $runs->foreach(sub {
        my $run = shift;

        my $run_was_split = 0;

        my $text_nodes = $self->xpc->findnodes('./w:t', $run);
        $text_nodes->foreach(sub {
            my $t = shift;
            my $run = $t->parentNode;

            my @parts = split(/($regex)/, $t->textContent);

            # No match, no need to do all the DOM processing below
            return if @parts == 1;

            $run_was_split = 1;

            for (my $i = $#parts; $i >= 0; $i--) {
                my $part = $parts[$i];
                next if $part eq '';

                my $new_run = $self->_clone_run($run);
                my $new_text = $t->cloneNode(0);

                # Ensure leading/trailing whitespace is preserved
                $new_text->setAttributeNS(XML_XML_NS, 'xml:space', 'preserve');

                $new_text->appendText($part);
                $new_text->normalize();
                $new_run->appendChild($new_text);

                $run->parentNode->insertAfter($new_run, $run);

                if ($i % 2 != 0) {
                    push @matching_nodes, $new_text->childNodes;
                }
            }
        });

        $run->parentNode->removeChild($run) if $run_was_split;
    });

    for my $part ($self->referenced_parts) {
        my $nodes = $part->find_text_nodes(
            $regex,
            $exclude_tables,
        );

        push @matching_nodes, @$nodes;
    }

    return \@matching_nodes;
}


sub style_text {
    my $self = shift;
    my $regex = shift;
    my %options = @_;

    my $text_nodes = $self->find_text_nodes($regex, delete $options{exclude_tables});

    for my $text_node (@$text_nodes) {
        my ($run_props) = $self->xpc->findnodes('ancestor::w:r[1]/w:rPr', $text_node);
        if (!$run_props) {
            my ($run) = $self->xpc->findnodes('ancestor::w:r[1]', $text_node);

            my $run_ns = $run->namespaceURI;
            $run_props = $self->xml->createElement('rPr');
            $run_props->setNamespace($run_ns => $run->lookupNamespacePrefix($run_ns));
            $run->insertBefore($run_props, $run->firstChild);
        }

        if (exists $options{bold}) {
            my ($bold) = $self->xpc->findnodes('./w:b', $run_props);

            if (!$bold && $options{bold}) {
                $run_props->addNewChild($run_props->namespaceURI => 'b');
            }
            if ($bold && !$options{bold}) {
                $run_props->removeChild($bold);
            }
        }

       if (exists $options{italic}) {
            my ($italic) = $self->xpc->findnodes('./w:i', $run_props);

            if (!$italic && $options{italic}) {
                $run_props->addNewChild($run_props->namespaceURI => 'i');
            }
            if ($italic && !$options{italic}) {
                $run_props->removeChild($italic);
            }
        }

        if (exists $options{color}) {
            my $color_to_set = _check_color_syntax($options{color});

            my ($color_element) = $self->xpc->findnodes('./w:color', $run_props);

            if (!$color_element && $options{color}) {
                $color_element = $run_props->addNewChild($run_props->namespaceURI => 'color');
            }

            if ($color_element && $options{color}) {
                my $ns = $color_element->namespaceURI;

                $color_element->setAttributeNS(
                    $ns,
                    'val' => $color_to_set
                );

                # We're explicitly setting the color, so we need to remove
                # the "document theme"-based color attributes or they'll
                # take precedence.
                $color_element->removeAttributeNS($ns => 'themeColor');
                $color_element->removeAttributeNS($ns => 'themeShade');
                $color_element->removeAttributeNS($ns => 'themeTint');
            }

            if ($color_element && not defined $options{color}) {
                $run_props->removeChild($color_element);
            }
        }

        if (exists $options{underline_style}) {
            my $underline_style = _check_underline_style($options{underline_style});

            my ($underline_element) = $self->xpc->findnodes('./w:u', $run_props);

            if (!$underline_element && $options{underline_style}) {
                $underline_element = $run_props->addNewChild($run_props->namespaceURI => 'u');
            }

            if ($underline_element && $options{underline_style}) {
                $underline_element->setAttributeNS(
                    $underline_element->namespaceURI,
                    'val' => $options{underline_style}
                );

                if (exists $options{underline_color}) {
                    if (defined $options{underline_color}) {
                        my $color_to_set = _check_color_syntax($options{underline_color});

                        $underline_element->setAttributeNS(
                            $underline_element->namespaceURI,
                            'color' => $color_to_set,
                        );
                    } else {
                        $underline_element->removeAttributeNS(
                            $underline_element->namespaceURI => 'color'
                        );
                    }
                }
            }

            if ($underline_element && not defined $options{underline_style}) {
                $run_props->removeChild($underline_element);
            }
        }
    }

    return scalar @$text_nodes;
}

sub _check_color_syntax {
    my $color = shift;

    return        if not defined $color;
    return $color if $color eq 'auto';
    return uc($color) if $color =~ /^[0-9a-fA-F]{6}$/;

    croak("Invalid color value: '$color'");
}

my %underline_styles = (
    map { $_ => 1 } qw(
        dash
        dashDotDotHeavy
        dashDotHeavy
        dashedHeavy
        dashLong
        dashLongHeavy
        dotDash
        dotDotDash
        dotted
        dottedHeavy
        double
        none
        single
        thick
        wave
        wavyDouble
        wavyHeavy
        words
    )
);

sub _check_underline_style {
    my $underline_style = shift;


    return if not defined $underline_style;
    return $underline_style if exists $underline_styles{$underline_style};

    croak("Invalid underline style: '$underline_style'");
}


sub remove_spellcheck_markers {
    my $self = shift;

    my $spellcheck_nodes = $self->xpc->findnodes(
        '//w:proofErr',
        $self->xml->documentElement,
    );
    $spellcheck_nodes->foreach(sub {
        my $node = shift;
        $node->parentNode->removeChild($node);
    });

    for my $part ($self->referenced_parts) {
        $part->remove_spellcheck_markers();
    }

    return;
}


sub extract_words {
    my $self = shift;

    my @words;
    my $text_nodes = $self->xpc->findnodes(
        '//w:t',
        $self->xml->documentElement,
    );

    $text_nodes->foreach(sub {
        my $node = shift;

        # split on non-word characters
        push @words, grep { !/^\s*$/ } split(/[\W]+/, $node->textContent);
    });

    for my $part ($self->referenced_parts) {
        push @words, @{ $part->extract_words() };
    }

    return \@words;
}


sub merge_runs {
    my $self = shift;

    my $runs = $self->xpc->findnodes(
        '//w:p/w:r',
        $self->xml->documentElement,
    );

    my $active_run;
    my $active_run_last_child;
    my $active_run_props;
    $runs->foreach(sub {
        my $run = shift;

        # If there's no "active" run, or the current run is in a new paragraph,
        # start a new "active" run.
        if (   !defined $active_run
            || !$run->parentNode->isSameNode($active_run->parentNode)
        ) {
            undef $active_run;
            undef $active_run_last_child;
            undef $active_run_props;
        }

        my ($this_run_props) = $self->xpc->findnodes('./w:rPr', $run);

        $this_run_props = defined $this_run_props
            ? $this_run_props->toString
            : '';

        # If properties match, merge all non-"run properties" child nodes
        # into the active run. Then discard the (now empty) run.
        if (   defined $active_run_props
            && $this_run_props eq $active_run_props
        ) {
            my $children = $run->childNodes;
            $children->foreach(sub {
                my $node = shift;
                return if $node->nodeName eq 'w:rPr';

                # If both the current child node and the last thing added to
                # the active run are text nodes, merge contents instead of
                # adding two adjacent <w:t> elements.
                if (   $active_run_last_child
                    && $active_run_last_child->nodeName eq 'w:t'
                    && $node->nodeName eq 'w:t'
                ) {
                    $node->childNodes->foreach(sub {
                        my $child = shift;
                        $active_run_last_child->appendChild($child);
                    });

                    $node->parentNode->removeChild($node);
                }
                else {
                    $active_run->appendChild($node);
                    if (   $node->isa('XML::LibXML::Element')
                        || ($node->isa('XML::LibXML::Text') && $node->textContent !~ /^\s*$/)
                    ) {
                        $active_run_last_child = $node;
                    }
                }
            });

            $run->parentNode->removeChild($run);
        }
        else {
            $active_run            = $run;
            $active_run_props      = $this_run_props;
            $active_run_last_child = first {
                $_->isa('XML::LibXML::Element')
                && $_->nodeName ne 'w:rPr'
            } $run->childNodes->reverse->get_nodelist;
        }
    });

    for my $part ($self->referenced_parts) {
        $part->merge_runs();
    }

    return;
}


sub replace_text {
    my $self = shift;
    my $search = shift;
    my $replace = shift;

    my $text_nodes = $self->xpc->findnodes(
        '//w:t',
        $self->xml->documentElement,
    );

    $text_nodes->foreach(sub {
        my $text = shift;

        $text->childNodes->foreach(sub {
            my $child = shift;
            return unless $child->isa('XML::LibXML::Text');

            $child->replaceDataString($search, $replace, 1);
        });
    });

    for my $part ($self->referenced_parts) {
        $part->replace_text($search, $replace);
    }

    return;
}

{
    my @EXPLICIT_REFERENCE_IDS = (
        '//w:footerReference/@r:id',
        '//w:headerReference/@r:id',
    );

    my %IMPLICIT_REFERENCE_ELEMENTS = (
        strict => {
            '(//w:endnoteReference)[1]'  => 'http://purl.oclc.org/ooxml/officeDocument/relationships/endnotes',
            '(//w:footnoteReference)[1]' => 'http://purl.oclc.org/ooxml/officeDocument/relationships/footnotes',
            '(//w:commentReference)[1]'  => 'http://purl.oclc.org/ooxml/officeDocument/relationships/comments',
        },
        transitional => {
            '(//w:endnoteReference)[1]'  => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes',
            '(//w:footnoteReference)[1]' => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes',
            '(//w:commentReference)[1]'  => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments',
        },
    );

    sub referenced_parts {
        my $self = shift;

        my @parts;

        for my $ref_type (@EXPLICIT_REFERENCE_IDS) {
            my $references = $self->xpc->findnodes(
                $ref_type,
                $self->xml->documentElement,
            );

            $references->foreach(sub {
                my $ref = shift;

                push @parts, $self->find_referenced_part_by_id($ref->value);
            });
        }

        my $strict = $self->is_strict ? 'strict' : 'transitional';
        for my $ref_type (keys %{ $IMPLICIT_REFERENCE_ELEMENTS{$strict} }) {
            my $references = $self->xpc->findnodes(
                $ref_type,
                $self->xml->documentElement,
            );

            next if not $references->size();

            push @parts, $self->find_referenced_part_by_type(
                $IMPLICIT_REFERENCE_ELEMENTS{$strict}{$ref_type}
            );
        }

        return @parts;
    }
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=encoding UTF-8

=head1 NAME

Document::OOXML::Part::WordprocessingML - WordprocessingML document part handling

=head1 VERSION

version 0.181410

=head1 ATTRIBUTES

=head2 xml

L<XML::LibXML::Document> containing the parsed XML of the WordprocessingML
part.

=head2 xpc

L<XML::LibXML::XPathContext> that will be used to find elements in the
WordprocessingML.

=head1 METHODS

=head2 new_from_xml($part_name, $xml, $strict)

Create a new instance based on XML data.

=head2 find_text_nodes($regex, $exclude_tables)

Returns a list of C<< <w:t> >> elements (see L<XML::LibXML::Element>)
matching the regular expression.

First, all adjacent identical runs are merged (see L</merge_runs>), then
all text elements are matched against the regular expression. The runs
with matching text are then split into "pre-match", "match" and "post-match"
parts. The "match" parts are then returned.

This regular expression should not contain matching groups, as this will
confuse the splitting code.

If C<$exclude_tables> is true, the regular expression will not match
text in tables. This option may change in the future.

=head2 style_text($regex, %style)

Sets the style options described by C<%style> to all text parts of the document
that match regular expression C<$regex>.

Internally, this method uses L</find_text_nodes> to do the heavy lifting of
combining and splitting runs.

The regular expression should not contain matching groups, as this will confuse
the splitting code.

The following style options are recognised (all are optional, but why would you
call this method if you don't want to set/unset styling?):

=over

=item * bold

Boolean value. If true, matching text will be made B<bold>. If specified and
false, matching text will be un-bolded.

=item * italic

Boolean value. If true, matching text will be made I<italic>. If specified and
false, matching text will be un-italiced.

=item * underline_style

String value. Matching text will get an underline of the specified style. If
the key exists specified and the value is c<undef>, underline will be removed
from the matching text.

Allowed underline styles are:

    dash
    dashDotDotHeavy
    dashDotHeavy
    dashedHeavy
    dashLong
    dashLongHeavy
    dotDash
    dotDotDash
    dotted
    dottedHeavy
    double
    none
    single
    thick
    wave
    wavyDouble
    wavyHeavy
    words

=item * underline_color

Color value that will be used for the underline only.

=item * color

Color value, matching text will be given this color.

Colors should be in the format: C<RRGGBB> (red, green, blue components in
hexadecimal, like used in HTML). The special value C<auto> can be used to
let the word processor decide the color.

Note: unlike HTML, the color value should NOT be prefixed with "#". It
should just be the six hexadecimal digits.

=item * exclude_tables

Boolean value. If true, text in tables will not be touched.

=back

=head2 remove_spellcheck_markers

Remove all C<< <w:proofErr> >> elements from the document. This removes
the red "squigglies" until another spelling/grammar check is done.

=head2 extract_words

Extract a list of words form the document.

Returns a reference to an array containing the words.

=head2 merge_runs

Walks over all runs (C<< <w:r> >>) in the document. If two adjacent runs in
the same paragraph have identical properties, the contents of the second run
are merged into the first run.

This makes it easier to find stretches of text for search/replace.

=head2 replace_text($search, $replace)

Replace all occurrences of C<$search> with C<$replace> in every text
(C<< <w:t> >>) element in the document.

Does not yet follow references, so text in headers, footers and other
external parts of the document isn't changed.

=head1 SEE ALSO

=over

=item * L<Document::OOXML>

=item * L<Document::OOXML::Part>

=back

=head1 AUTHOR

Martijn van de Streek <martijn@vandestreek.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Martijn van de Streek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
