package HTML::WikiConverter::Markdown;

use warnings;
use strict;

use base 'HTML::WikiConverter';
our $VERSION = '0.06';

use Params::Validate ':types';
use HTML::Entities;
use HTML::Tagset;
use URI;

=head1 NAME

HTML::WikiConverter::Markdown - Convert HTML to Markdown markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'Markdown' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into Markdown markup.
You should not use this module directly; HTML::WikiConverter is the
entry point for html->wiki conversion (eg, see synopsis above). See
L<HTML::WikiConverter> for additional usage details.

=head1 ATTRIBUTES

In addition to the regular set of attributes recognized by the
L<HTML::WikiConverter> constructor, this dialect also accepts the
following attributes that can be passed into the C<new()>
constructor. See L<HTML::WikiConverter/ATTRIBUTES> for usage details.

=head2 header_style

Possible values: C<'setext'>, C<'atx'>. Determines how headers
C<h1>-C<h6> will be formatted. See
L<http://daringfireball.net/projects/markdown/syntax#header> for more
information. Default is C<'atx'>.

=head2 link_style

Possible values: C<'inline'>, C<'reference'>. See
L<http://daringfireball.net/projects/markdown/syntax#link> for more
information. Default is C<'reference'>.

=head2 force_inline_anchor_links

Possible values: C<0>, C<1>. If enabled, links to anchors within the
same page (eg, C<#some-anchor>) will always produce inline Markdown
links, even under reference link style. This might be useful for
building tables of contents. Default is C<0>.

=head2 image_style

Possible values: C<'inline'>, C<'reference'>. See
L<http://daringfireball.net/projects/markdown/syntax#img> for more
information. Default is C<'reference'>.

=head2 image_tag_fallback

Possible values: C<0>, C<1>. Markdown's image markup does not
support image dimensions. If C<image_tag_fallback> is enabled, image
tags containing dimensional information (ie, width or height) will not
be converted into Markdown markup. Rather, they will be roughly
preserved in their HTML form. Default is C<1>.

=head2 unordered_list_style

Possible values: C<'asterisk'>, C<'plus'>, C<'dash'>. See
L<http://daringfireball.net/projects/markdown/syntax#list> for more
information. Default is C<'asterisk'>.

=head2 ordered_list_style

Possible values: C<'sequential'>, C<'one-dot'>. Markdown supports two
different markups for ordered lists. Sequential style gives each list
element its own ordinal number (ie, C<'1.'>, C<'2.'>, C<'3.'>,
etc.). One-dot style gives each list element the same ordinal number
(ie, C<'1.'>). See
L<http://daringfireball.net/projects/markdown/syntax#list> for more
information. Default is C<'sequential'>.

=head2 md_extra

Possible values: C<0>, C<1>. Support MarkDown Extra
L<https://github.com/jmcmanus/pagedown-extra> extensions. Default is C<0>.

This support is incomplete.

    # Tables				Supported
    # Fenced Code Blocks
    # Definition Lists		Supported
    # Footnotes
    # Special Attributes
    # SmartyPants
    # Newlines
    # Strikethrough

=cut

sub attributes {
    {
        header_style              => { default => 'atx',        type => SCALAR },
        link_style                => { default => 'reference',  type => SCALAR },
        force_inline_anchor_links => { default => 0,            type => BOOLEAN },
        image_style               => { default => 'reference',  type => SCALAR },
        image_tag_fallback        => { default => 1,            type => BOOLEAN },
        unordered_list_style      => { default => 'asterisk',   type => SCALAR },
        ordered_list_style        => { default => 'sequential', type => SCALAR },

        # Requires H::WC version 0.67
        p_strict => { default => 0 },
        md_extra => { default => 0, type => BOOLEAN },
    };
}

my @common_attrs = qw/ id class lang dir title style /;

# Hack to accommodate bug #43997 - multiline code blocks
my $code_block_prefix = 'bqwegsdfbwegadfbnsdfbahwerfgkjnsdfbohqw34t927398y5jnwrteb8uq34inb';

sub rules {
    my $self = shift;

    my %rules = (
        hr => { replace  => "\n\n----\n\n" },
        br => { preserve => 1, empty => 1, end => \&_br_end },
        p => {
            block       => 1,
            trim        => 'both',
            line_format => 'multi',
            line_prefix => \&_p_prefix
        },
        blockquote => {
            block       => 1,
            trim        => 'both',
            line_format => 'blocks',
            line_prefix => '> '
        },
        ul => { block => 1,           line_format => 'multi' },
        ol => { alias => 'ul' },
        li => { start => \&_li_start, trim        => 'leading' },

        i          => { start       => '_',                end   => '_' },
        em         => { alias       => 'i' },
        b          => { start       => '**',               end   => '**' },
        strong     => { alias       => 'b' },
        code       => { start       => \&_code_delim,      end   => \&_code_delim },
        code_block => { line_prefix => $code_block_prefix, block => 1 },

        a   => { replace     => \&_link },
        img => { replace     => \&_img },
        div => { block       => 1, line_format => 'blocks' },
        pre => { line_prefix => "\t", block => 1, line_format => 'blocks' },
    );

    for ( 1 .. 6 ) {
        $rules{"h$_"} = {
            start => \&_header_start,
            end   => \&_header_end,
            trim  => 'both',
            block => 1
        };
    }

    for (qw/ table caption tr th td /) {
        $rules{$_} = {
            preserve    => 1,
            attrs       => \@common_attrs,
            start       => "\n",
            end         => "\n",
            line_format => 'multi'
        };
    }

    # MarkDown Extra https://github.com/jmcmanus/pagedown-extra
    # Tables				Supported
    # Fenced Code Blocks
    # Definition Lists		Supported
    # Footnotes
    # Special Attributes
    # SmartyPants
    # Newlines
    # Strikethrough
    if ( $self->md_extra ) {
        $rules{dt} = { start => "\n",    end => "\n", trim => 'both', };
        $rules{dd} = { start => ":    ", end => "\n", trim => 'both', };
        delete( $rules{table} );
        delete( $rules{caption} );
        $rules{tr}    = { start => "\n",    end  => "|", trim => 'both' };
        $rules{td}    = { start => "|",     trim => 'both' };
        $rules{th}    = { alias => 'td' };
        $rules{thead} = { end   => "\n|-|", trim => 'both' };
        # need an extra line here as some lists can contain complex block structures.
        $rules{ul} = { block => 1, line_format => 'blocks' };
        $rules{li} = { start => \&_li_start, blocks => 1, trim => 'leading' };
    }

    return \%rules;
}

sub _br_end {
    my ( $self, $node, $rules ) = @_;
    return "\n";
}

sub _header_start {
    my ( $self, $node, $rules ) = @_;
    return '' unless $self->header_style eq 'atx';

    ( my $level = $node->tag ) =~ s/\D//g;
    return unless $level;

    my $hr = ('#') x $level;
    return "$hr ";
}

sub _header_end {
    my ( $self, $node, $rules ) = @_;
    my $anchor = '';

    if ( $node->id() ) {
        $anchor = "\t{#" . $node->id() . "}";
    }

    return $anchor unless $self->header_style eq 'setext';
    ( my $level = $node->tag ) =~ s/\D//g;
    return $anchor unless $level;

    my $symbol = $level == 1 ? '=' : '-';
    my $len    = length $self->get_elem_contents($node);
    my $bar    = ($symbol) x $len;
    return "$anchor\n$bar\n";
}

sub _link {
    my ( $self, $node, $rules ) = @_;

    my $url   = $self->_abs2rel( $node->attr('href') || '' );
    my $text  = $self->get_elem_contents($node);
    my $title = $node->attr('title') || '';

    my $style = $self->link_style;
    $style = 'inline' if $url =~ /^\#/ and $self->force_inline_anchor_links;

    if ( $url eq $text ) {
        return sprintf "<%s>", $url;
    }
    elsif ( $style eq 'inline' ) {
        return sprintf "[%s](%s \"%s\")", $text, $url, $title if $title;
        return sprintf "[%s](%s)", $text, $url;
    }
    elsif ( $style eq 'reference' ) {
        my $id = $self->_next_link_id;
        $self->_add_link( { id => $id, url => $url, title => $title } );
        return sprintf "[%s][%s]", $text, $id;
    }
}

sub _last_link_id { shift->_attr( { internal => 1 }, _last_link_id => @_ ) }

sub _links { shift->_attr( { internal => 1 }, _links => @_ ) }

sub _next_link_id {
    my $self = shift;
    my $next_id = ( $self->_last_link_id || 0 ) + 1;
    $self->_last_link_id($next_id);
    return $next_id;
}

sub _add_link {
    my ( $self, $link ) = @_;
    $self->_links( [ @{ $self->_links || [] }, $link ] );
}

sub _img {
    my ( $self, $node, $rules ) = @_;

    my $url    = $node->attr('src')    || '';
    my $text   = $node->attr('alt')    || '';
    my $title  = $node->attr('title')  || '';
    my $width  = $node->attr('width')  || '';
    my $height = $node->attr('height') || '';

    if ( $width || $height and $self->image_tag_fallback ) {
        return "<img " . $self->get_attr_str( $node, qw/ src width height alt /, @common_attrs ) . " />";
    }
    elsif ( $self->image_style eq 'inline' ) {
        return sprintf "![%s](%s \"%s\")", $text, $url, $title if $title;
        return sprintf "![%s](%s)", $text, $url;
    }
    elsif ( $self->image_style eq 'reference' ) {
        my $id = $self->_next_link_id;
        $self->_add_link( { id => $id, url => $url, title => $title } );
        return sprintf "![%s][%s]", $text, $id;
    }
}

sub _li_start {
    my ( $self, $node, $rules ) = @_;
    my @parent_lists = $node->look_up( _tag => qr/ul|ol/ );

    my $prefix = ('  ') x ( @parent_lists - 1 );

    my $bullet = '';
    $bullet = $self->_ul_li_start if $node->parent and $node->parent->tag eq 'ul';
    $bullet = $self->_ol_li_start( $node->parent )
        if $node->parent and $node->parent->tag eq 'ol';
    return "\n$prefix$bullet ";
}

sub _ul_li_start {
    my $self  = shift;
    my $style = $self->unordered_list_style;
    return '*' if $style eq 'asterisk';
    return '+' if $style eq 'plus';
    return '-' if $style eq 'dash';
    die "no such unordered list style: '$style'";
}

my %ol_count = ();

sub _ol_li_start {
    my ( $self, $ol ) = @_;
    my $style = $self->ordered_list_style;

    if ( $style eq 'one-dot' ) {
        return '1.';
    }
    elsif ( $style eq 'sequential' ) {
        my $count = ++$ol_count{$ol};
        return "$count.";
    }
    else {
        die "no such ordered list style: $style";
    }
}

sub _p_prefix {
    my ( $wc, $node, $rules ) = @_;
    return $node->look_up( _tag => 'li' ) ? '    ' : '';
}

sub preprocess_node {
    my ( $self, $node ) = @_;
    return unless $node->tag and $node->parent and $node->parent->tag;

    if ( $node->tag eq 'blockquote' ) {
        my @non_phrasal_children = grep { !$self->_is_phrase_tag( $_->tag ) } $node->content_list;
        unless (@non_phrasal_children)
        {    # ie, we have things like <blockquote>blah blah blah</blockquote>, without a <p> or something
            $self->_envelop_children( $node, HTML::Element->new('p') );
        }
    }
    elsif ( $node->tag eq '~text' ) {
        $self->_escape_text($node);

        # bug #43998
        $self->_decode_entities_in_code($node)
            if $node->parent->tag eq 'code'
            or $node->parent->tag eq 'code_block';
    }
}

sub preprocess_tree {
    my ( $self, $root ) = @_;
    foreach my $node ( $root->descendants ) {

        # bug #43997 - multiline code blocks
        if ( $self->_text_is_within_code_pre($node) ) {
            $self->_convert_to_code_block($node);
        }
    }
}

sub _text_is_within_code_pre {
    my ( $self, $node ) = @_;
    return unless $node->parent->parent and $node->parent->parent->tag;

    # Must be <code><pre>...</pre></code> (or <pre><code>...</code></pre>)
    my $code_pre = $node->parent->tag eq 'code' && $node->parent->parent->tag eq 'pre';
    my $pre_code = $node->parent->tag eq 'pre'  && $node->parent->parent->tag eq 'code';
    return unless $code_pre or $pre_code;

    # Can't be any other nodes in a code block
    return if $node->left or $node->right;
    return if $node->parent->left or $node->parent->right;

    return 1;
}

sub _convert_to_code_block {
    my ( $self, $node ) = @_;
    $node->parent->parent->replace_with_content->delete;
    $node->parent->tag("code_block");
}

sub _envelop_children {
    my ( $self, $node, $new_child ) = @_;

    my @children = $node->detach_content;
    $node->push_content($new_child);
    $new_child->push_content(@children);
}

# special handling for: ` _ # . [ !
my @escapes = qw( \\ * { } _ ` );

my %backslash_escapes = (
    '\\' => [ '0923fjhtml2wikiescapedbackslash',  "\\\\" ],
    '*'  => [ '0923fjhtml2wikiescapedasterisk',   "\\*" ],
    '{'  => [ '0923fjhtml2wikiescapedopenbrace',  "\\{" ],
    '}'  => [ '0923fjhtml2wikiescapedclosebrace', "\\}" ],
    '_'  => [ '0923fjhtml2wikiescapedunderscore', "\\_" ],
    '`'  => [ '0923fjhtml2wikiescapedbacktick',   "\\`" ],
);

sub _escape_text {
    my ( $self, $node ) = @_;
    my $text = $node->attr('text') || '';

    #
    # (bug #43998)
    # Only backslash-escape backticks that don't occur within <code>
    # tags. Those within <code> tags are left alone and the backticks to
    # signal a <code> tag get upgraded to a double-backtick by
    # _code_delim().
    #
    # (bug #43993)
    # Likewise, only backslash-escape underscores that occur outside
    # <code> tags.
    #

    my $inside_code
        = $node->look_up( _tag => 'code' )
        || $node->look_up( _tag => 'code_block' )
        || $node->look_up( _tag => 'pre' );

    if ( not $inside_code ) {
        my $escapes = join '', @escapes;
        $text =~ s/([\Q$escapes\E])/$backslash_escapes{$1}->[0]/g;
        $text =~ s/^([\d]+)\./$1\\./;
        $text =~ s/^\#/\\#/;
        $text =~ s/\!\[/\\![/g;
        $text =~ s/\]\[/]\\[/g;

        $node->attr( text => $text );
    }
}

# bug #43998
sub _code_delim {
    my ( $self, $node, $rules ) = @_;
    my $contents = $self->get_elem_contents($node);
    return $contents =~ /\`/ ? '``' : '`';
}

# bug #43996
sub _decode_entities_in_code {
    my ( $self, $node ) = @_;
    my $text = $node->attr('text') || '';
    return unless $text;

    HTML::Entities::_decode_entities( $text, { 'amp' => '&', 'lt' => '<', 'gt' => '>' } );
    $node->attr( text => $text );
}

sub postprocess_output {
    my ( $self, $outref ) = @_;
    $$outref =~ s/\Q$code_block_prefix\E/    /gm;
    $self->_unescape_text($outref);
    $self->_add_references($outref);
}

sub _unescape_text {
    my ( $self, $outref ) = @_;
    foreach my $escape ( values %backslash_escapes ) {
        $$outref =~ s/$escape->[0]/$escape->[1]/g;
    }
}

sub _add_references {
    my ( $self, $outref ) = @_;
    my @links = @{ $self->_links || [] };
    return unless @links;

    my $links = '';
    foreach my $link (@links) {
        my $id    = $link->{id}    || '';
        my $url   = $link->{url}   || '';
        my $title = $link->{title} || '';
        if ($title) {
            $links .= sprintf "  [%s]: %s \"%s\"\n", $id, $url, $title;
        }
        else {
            $links .= sprintf "  [%s]: %s\n", $id, $url;
        }
    }

    $self->_links( [] );
    $self->_last_link_id(0);

    $$outref .= "\n\n$links";
    $$outref =~ s/\s+$//gs;
}

sub _is_phrase_tag {
    my $tag = pop || '';
    return $HTML::Tagset::isPhraseMarkup{$tag} || $tag eq '~text';
}

sub _abs2rel {
    my ( $self, $uri ) = @_;
    return $uri unless $self->base_uri;
    return URI->new($uri)->rel( $self->base_uri )->as_string;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-markdown at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-Markdown>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::Markdown

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-Markdown>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-Markdown>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-Markdown>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-Markdown>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

