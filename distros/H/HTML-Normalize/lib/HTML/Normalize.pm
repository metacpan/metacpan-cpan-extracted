package HTML::Normalize;

use strict;
use warnings;
use HTML::Entities;
use HTML::TreeBuilder;
use HTML::Tagset;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.0003';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

HTML::Normalize - HTML light weight cleanup

=head1 VERSION

Version 1.0003

=head1 SYNOPSIS

    my $norm = HTML::Normalize->new ();
    my $cleanHtml = $norm->cleanup (-html => $dirtyHtml);

=head1 DESCRIPTION

HTML::Normalize uses HTML::TreeBuilder to parse an HTML string then processes
the resultant tree to clean up various structural issues in the original HTML.
The result is then rendered using HTML::Element's as_HTML member.

Key structural clean ups fix tag soup (C<< <b><i>foo</b></i> >> becomes C<<
<b><i>foo</i></b> >>) and inline/block element nesting (C<<
<span><p>foo</p></span> >> becomes C<< <p><span>foo</span></p> >>). C<< <br> >>
tags at the start or end of a link element are migrated out of the element.

Note that HTML::Normalize's approach to cleaning up tag soup is different than
that used by HTML::Tidy. HTML::Tidy tends to enforce nested and swaps end tags
to achieve that. HTML::Normalize inserts extra tags to allow correctly taged
overlapped markup.

HTML::Normalize can also remove attributes set to default values and empty
elements. For example a C<< <font face="Verdana" size="1" color="#FF0000"> >>
element would become and C<< <font color="#FF0000"> >> and C<< <font
face="Verdana" size="1"> >> would be removed if Verdana size 1 is set as the
default font.

=head1 Methods

C<new> creates an HTML::Normalize instance and performs parameter validation.

C<cleanup> Validates any further parameters and check parameter consistency then
parses the HTML to generate the internal representation. It then edits the
internal representation and renders the result back into HTML.

Note that I<cleanup> may be called multiple times with different HTML strings to
process.

Generally errors are handled by carping and may be detected in both I<new> and
I<cleanup>.

=cut

=head2 new

Create a new C<HTML::Normalize> instance.

    my $norm = HTML::Normalize->new ();

=over 4

=item I<-compact>: optional

Setting C<< -compact => 1 >> suppresses generation of 'optional' close tags.
This reduces the sizeof the output slightly at the expense of breaking any hope
of XHTML compliance.

=item I<-default>: optional - multiple

Define a default attribute for an element. Default attributes are removed if the
attribute value has not been overridden in a parent node. For element such as
'font' this may result in the element being removed if no attributes remain.

C<-default> takes a string of the form 'tag attribute=value' as an argument.
For example:

    -default => 'font face="Verdana"'

would specify that the face "Verdana" is the default face attribute for font
elements.

I<value> may be a constant or a regular expression. A regular expression
matches:

    /(~|qr)\s*(.).*\1\s*$/

except that the paired delimiters [], {}, () and <> are also accepted as pattern
delimiters.

Literal match values should not encode entities, but remember that quotes around
attribute values are optional for some values so the outer pair of quote
characters will be removed if present. The match value extends to the end of the
line and is not bounded by quote qharacters (except as noted earlier) so no
quoting of "special" characters is required - there are no special characters.

Multiple default attributes may be provided but only one default value is
allowed for any one tag/attribute pair.

Default values are case sensitive. However you can use the regular expression
form to overcome this limitation.

=item I<-distribute>: optional - default true

Distribute inline elements over children if the children are block level
elements. For example:

    <span boo="foo"><p>foo</p><p>bar</p></span>

becomes:

    <p><span boo="foo">foo</span></p><p><span boo="foo">bar</span></p>

This action is only taken if all the child elements are block level elements.

=item I<-expelbr>: optional - default true

If C<-expelbr> is true (the default) break elements at the edges of link
elements are expelled from the link element. Thus:

    <a href="linkto"><br>link text<br></a>

becomes

    <br><a href="linkto">link text</a><br>

=item I<-html>: required

the HTML string to clean.

=item I<-indent>: optional - default '   '

String used to indent formatted output. Ignored if I<-unformatted> is true.

=item I<-keepimplicit>: optional

as_HTML adds various HTML required sections such as head and body elements. By
default HTML::Normalize removes these elements so that it is suitable for
processing HTML fragments. Set C<-keepimplicit => 1> to render the implicit
elements.

Note that if this option is true, the extra nodes will be generated regardless
of their presence in the original HTML.

=item I<-maxlinelen>: optional - default 80

Notional maximum line length if I<-selfrender> is true. The line length may be
exceeded if no suitable break position is found. Note that the current indent is
included in the line length.

=item I<-selfrender>: optional

Use the experimental HTML::Normalize code to render HTML rather than using
HTML::Element's renderer. This code has not been tested against a wide range of
HTML and may be unreliable. It's advantage is that it produces (in the author's
opinion) prettier output than HTML::Element's as_HTML member.

=item I<-unformatted>: optional

Suppress output formatting. By default as_HTML is called as

    as_HTML (undef, '   ', {})

which wraps and indents elements. Setting C<< -unformatted => 1 >> suppresses
generation of line breaks and indentation reducing the size of the output
slightly.

=back

=cut

my %paramTypes = (

    # 0: optional once
    # 1: required once
    # 2: optional, many allowed
    -compact      => [0, 0],
    -default      => [2, undef],
    -distribute   => [0, 1],
    -expelbr      => [0, 1],
    -html         => [1, undef],
    -indent       => [0, '   '],
    -keepimplicit => [0, 0],
    -maxlinelen   => [0, 80],
    -selfrender   => [0, 0],
    -unformatted  => [0, 0],
);
my $regex = '
    (?:~|qr)\s*
    (?:
         (.).*\4  # regex quote char delimited
        |<.*>     # regex <> delimited
        |{.*}     # regex {} delimited
        |\[.*\]   # regex [] delimited
        |\(.*\)   # regex () delimited
    )i?               # Regex match
    ';

sub new {
    my ($self, @params) = @_;

    unless (ref $self) {
        $self = bless {}, $self;
        $self->{both}     = qr/^(del|ins)$/i;
        $self->{inline}   = qr/^(b|i|s|font|span)$/i;
        $self->{block}    = qr/^(p|table|div)$/i;
        $self->{needattr} = qr/^(font|span)$/i;
        $self->{selfclose} = qr/^(br)$/i;
    }

    $self->_validateParams (
        \@params,
        [
            qw(-compact -default -distribute -expelbr -keepimplicit -unformatted )
        ],
        []
    );

    # Add 'div' to the closure barriers list to avoid changing:
    #   <p><div><p>foo</p></div></p>
    # into:
    #   <p><div></div></p><p>foo</p>
    my $bar = \@HTML::Tagset::p_closure_barriers;
    push @$bar, 'div' unless grep { $_ eq 'div' } @$bar;

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->{root}->delete if $self->{root};
}

sub _validateParams {
    my ($self, $params, $okParams, $requiredParams) = @_;

    $params         ||= [];
    $okParams       ||= [];
    $requiredParams ||= [];

    # Validate parameters
    while (@$params) {
        my ($key, $value) = splice @$params, 0, 2;

        $key = lc $key;
        croak "$key is not a valid parameter name" if !exists $paramTypes{$key};
        croak "$key parameter may only be used once"
          if $paramTypes{$key}[0] < 2 && exists $self->{$key};

        if ($paramTypes{$key}[0] < 2) {
            $self->{$key} = $value;
            next;
        }

        push @{$self->{$key}}, $value;
    }

    # Ensure we got required parameters
    for my $key (@$requiredParams) {
        croak "Invalid parameter name: $key" unless exists $paramTypes{$key};
        $self->{$key} = $paramTypes{$key}[1] unless exists $self->{$key};
        next if $paramTypes{$key}[0] != 1 or exists $self->{$key};
        croak "The $key parameter is missing. It is required.";
    }
}

=head2 cleanup

C<cleanup> takes no parameters and returns the cleaned up version of the HTML.

    my $cleanHtml = $norm->cleanup ();

=cut

sub cleanup {
    my ($self, @params) = @_;

    $self->_validateParams (\@params, [keys %paramTypes], ['-html']);

    # Check we got all required parameters and set any defaults
    for my $param (keys %paramTypes) {
        next if exists $self->{$param};
        next if $paramTypes{$param}[0] > 1;

        croak "A $param parameter must be provided. None was."
          if $paramTypes{$param}[0] == 1;

        # Set missing param to default
        $self->{$param} = $paramTypes{$param}[1];
    }

    # Unpack any -default parameters
    for my $default (@{$self->{-default}}) {
        my ($tag, $attrib, $value) =
          $default =~ /
            (\w+)\s+                    # Tag
            (\w+)\s*                    # Attribute
            (?:=\s*(?=[\w'"])|=(?=~))
            (   '[^']*'             # Single quoted
               |"[^"]*"             # Double quoted
               |\w+                 # Unquoted
               |$regex              # regex match
            )\s*                        # Value
            $/x;

        croak "Badly formed default attribute string: $default"
          unless defined $value;
        $_ = lc for $tag, $attrib;

        croak "Conflicting defaults given:\n"
          . "   $tag $attrib=$self->{defaults}{$tag}{$attrib}\n"
          . "and\n   $tag $attrib=$value\n"
          if exists $self->{defaults}{$tag}{$attrib}
              and $self->{defaults}{$tag}{$attrib} ne $value;

        if ($value =~ /^()()()$regex$/x) {
            # Compile regex
            $value =~ s/^~\s*/qr/;
            $value = eval $value;
        } else {
            # Strip quotes if present from match value
            $value =~ s/^(['"])(.*)\1$/$2/;
    }

        $self->{defaults}{$tag}{$attrib} = $value;
    }

    $self->{root} = HTML::TreeBuilder->new;
    $self->{root}->parse_content ($self->{-html});
    $self->{root}->elementify    ();

    1 while $self->_cleanedupElt ($self->{root});

    my $str = '';

    if ($self->{-selfrender}) {
        $self->{line} = '';
        $str = $self->_render ($self->{root}, '');
    } else {
        my @renderOptions = (undef, '   ', {});

        $renderOptions[1] = undef if $self->{-unformatted};
        $renderOptions[2] = undef if $self->{-compact};

        my $elt = $self->{root};

        if (! $self->{-keepimplicit}) {
            ($elt) = grep {$_->{_tag} eq 'body'} $self->{root}->descendents ();
        }

        $str .= ref $_ ? $_->as_HTML (@renderOptions) : $_
            for @{$elt->{_content}};
    }

    return $str;
}

sub _cleanedupElt {
    my ($self, $parent) = @_;

    return 0 unless ref $parent && ref $parent->{_content};

    my $rescan = 1;    # Set true to rescan the child element list
    my $touched;

    while ($rescan) {
        $rescan = 0;    # Assume another scan not required after current scan
        ++$touched;

        for my $elt ($parent->content_list ()) {
            next unless ref $elt;

            ++$rescan, last if $self->_cleanedupElt ($elt);
            next if exists $elt->{_implicit};

            ++$rescan, last if $self->_removedDefaults     ($elt);
            ++$rescan, last if $self->_distributedElements ($elt);
            ++$rescan, last if $self->_normalizedElements  ($elt);
            ++$rescan, last if $self->_expeledBr           ($elt);
            ++$rescan, last if $self->_removedEmpty        ($elt);
        }
    }

    return $touched > 1;
}

sub _distributedElements {
    my ($self, $elt) = @_;

    return 0 unless $self->{-distribute};
    return 0
      unless $elt->{_tag} =~ $self->{inline}
          && $elt->{_tag} =~ $self->{needattr};

    my @elts = $elt->content_list ();
    my $blockElts = grep {ref $_ && $_->{_tag} =~ $self->{block}} @elts;

    # Done unless all child elements are block level elements
    return 0 unless @elts && @elts == $blockElts;

    # Distribute inline element over and block elements
    $elt->replace_with_content ();

    for my $block (@elts) {
        my @nested = $block->detach_content ();
        my $clone  = $elt->clone            ();

        $block->push_content ($clone);
        $clone->push_content (@nested);
    }

    $elt->delete ();
    return 1;
}

sub _normalizedElements {
    my ($self, $elt) = @_;

    return 0 unless $elt->{_tag} =~ $self->{inline};

    my @elts = $elt->content_list ();

    # Ok unless element contains single block level child
    return 0
      unless @elts == 1
          && ref $elts[0]
          && $elts[0]->{_tag} =~ $self->{block};

    # Invert order of inline and block elements
    my @nested = $elts[0]->detach_content ();

    $elt->replace_with ($elts[0]);
    $elts[0]->push_content ($elt);
    $elt->push_content (@nested);
    $elt = $elts[0];

    $_->replace_with_content ()->delete ()
      for grep {$self->_removedEmpty ($_)} @elts;

    return 1;
}

sub _expeledBr {
    my ($self, $elt) = @_;

    return 0 unless $elt->{_tag} eq 'a' && $self->{-expelbr};
    return 0 unless exists $elt->{_content};

    my $adjusted;
    for my $index (0, -1) {
        my $br = $elt->{_content}[$index];

        next unless ref $br && $br->{_tag} eq 'br';
        $index == 0
          ? $br->detach ()->preinsert ($br)
          : $br->detach ()->postinsert ($br);
        ++$adjusted;
    }

    return $adjusted;
}

sub _removedDefaults {
    my ($self, $elt) = @_;

    return 0 unless exists $self->{defaults}{$elt->{_tag}};

    my $delAttribs = $self->{defaults}{$elt->{_tag}};

    for my $attrib (keys %$delAttribs) {
        next unless exists $elt->{$attrib};

        my $value = $delAttribs->{$attrib};
        my @parentAttribs;
        my @criteria = (_tag  => $elt->{_tag});

        if ('Regexp' eq ref $value) {
            next unless $elt->{$attrib} =~ $value;
            push @criteria, sub {
                my $attr = $_[0]->attr("$attrib");
                return 0 unless defined $attr;
                return $attr !~ $value;
                };
        } else {
            my $value = $delAttribs->{$attrib};

            next unless $elt->{$attrib} eq $value;
            push @criteria, ($attrib => qr/^(?!\Q$value\E)/i);
        }

        @parentAttribs = $elt->look_up (@criteria);

        # Don't delete attribute required to restore default
        next if @parentAttribs;
        delete $elt->{$attrib};
    }

    return $self->_removedEmpty ($elt);
}

sub _removedEmpty {
    my ($self, $elt) = @_;

    return 0 if grep {!/^_/} $elt->all_attr_names ();
    return 0 unless $elt->{_tag} =~ $self->{needattr};

    # Remove redundant element - no attributes left
    $elt->replace_with ($elt->detach_content ());
    $elt->delete ();
    return 1;
}

sub _render {
    my ($self, $elt, $indent) = @_;

    return ''
      unless $self->{-keepimplicit} || !$elt->{_implicit} || $elt->{_content};

    my $str = '';

    if (! $self->{-keepimplicit} && $elt->{_implicit}) {
        return $self->_renderContents ($elt, $indent);

    } elsif ($elt->{_tag} =~ $self->{selfclose}) {
        $str .= $self->_append ("<$elt->{_tag} />", $indent);

    } elsif ($HTML::Tagset::isPhraseMarkup{$elt->{_tag}}) {
        $str .= $self->_append ("<$elt->{_tag}", $indent);
        $str .= $self->_renderAttrs ($elt, $indent);
        $str .= $self->_renderContents ($elt, $indent);
        $str .= $self->_append ("</$elt->{_tag}>",$indent);

    } else {
        my $indented = "$indent$self->{-indent}";

        $str = $self->_flushLine ($indent);
        $self->{line} .= "<$elt->{_tag}";
        $self->{ishead} = 1;
        $str .= $self->_renderAttrs ($elt, $indented);
        $str .= $self->_renderContents ($elt, $indented);
        $str .= $self->_append ("</$elt->{_tag}>", $indented);
        $str .= $self->_flushLine ($indented);
    }

    return $str;
}

sub _append {
    my ($self, $tail, $indent) = @_;

    if ((length ($self->{line}) + length ($tail) + length ($indent)) > $self->{-maxlinelen}) {
        my $str = $self->_flushLine ($indent);

        $self->{line} = $tail;
        return $str;
    } else {
        $self->{line} .= $tail;
        return '';
    }
}

sub _flushLine {
    my ($self, $indent) = @_;

    return '' unless length $self->{line};

    my $str;

    if ($self->{-unformatted}) {
        $str = $self->{line};

    } else {
        if ($self->{ishead}) {
            substr ($indent, -length $self->{-indent}) = '';
            $self->{isHead} = undef;
        }

        $str = "$indent$self->{line}\n";
    }

    $self->{line} = '';
    return $str;
}

sub _renderAttrs {
    my ($self, $elt, $indent) = @_;
    my $str = '';
    my @attrs = grep {! /^_/} keys %$elt;

    $str .= $self->_append (
        qq( $_=") . encode_entities ($elt->{$_}) . qq("),
        $indent
        )
        for sort @attrs;
    $self->{line} .= '>';
    return $str;
}

sub _renderContents {
    my ($self, $elt, $indent) = @_;
    my $str = '';

    for my $subElt (@{$elt->{_content}}) {
        if (! ref $subElt) {
            $str .= $self->_renderText ($subElt, $indent);
        } else {
            $str .= $self->_render ($subElt, $indent);
        }
    }

    return $str;
}


sub _renderText {
    my ($self, $elt, $indent) = @_;
    my $str = $self->{line} . encode_entities ($elt);

    if ($self->{-unformatted}) {
        $self->{line} = '';

    } else {
        my $maxLen = $self->{-maxlinelen} - length $indent;

        $str =~ s/(.{,$maxLen})\s+/$indent$1\n/g;
        ($str, $self->{line}) = $str =~ /(.*\n)?(.*)/;
        $str = '' unless defined $str;
        $self->{line} = '' unless defined $self->{line};
    }

    return $str;
}


1;

=head1 BUGS

=head3 p/div/p parsing issue

HTML::TreeBuilder 3.23 and earlier misparses:

    <p><div><p>foo</p></div></p>

as:

    <p><div></div></p> <p>foo</p>

A work around in HTML::Normalize turns that into

    <p><div><p>foo</p></div></p>

which is probably still incorrect - div elements should not nest within p
elements. A better fix for the problem requires HTML::TreeBuilder to be fixed.

=head3 Bug reports and feature requests

Please report any other bugs or feature requests to
C<bug-html-normalize at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Normalize>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

This module is supported by the author through CPAN. The following links may be
of assistance:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-Normalize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-Normalize>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Normalize>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-Normalize>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by Bart Lateur's PerlMonks node 'Cleaning up HTML'
(L<http://perlmonks.org/?node_id=658103>) and is a collaboration between Bart
and the author.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

