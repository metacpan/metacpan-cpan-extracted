package HTML::WikiConverter::MediaWiki;
use base 'HTML::WikiConverter';

use warnings;
use strict;

use URI;
use File::Basename;
use HTML::Tagset;
our $VERSION = '0.59';

=head1 NAME

HTML::WikiConverter::MediaWiki - Convert HTML to MediaWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'MediaWiki' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into MediaWiki
markup. See L<HTML::WikiConverter> for additional usage details.

=head1 ATTRIBUTES

In addition to the regular set of attributes recognized by the
L<HTML::WikiConverter> constructor, this dialect also accepts the
following attributes:

=head2 preserve_bold

Boolean indicating whether bold HTML elements should be preserved as
HTML in the wiki output rather than being converted into MediaWiki
markup.

By default, E<lt>bE<gt> and E<lt>strongE<gt> elements are converted to
wiki markup identically. But sometimes you may wish E<lt>bE<gt> tags
in the HTML to be preserved in the resulting MediaWiki markup. This
attribute allows this.

For example, if C<preserve_bold> is enabled, HTML like

  <ul>
    <li> <b>Bold</b>
    <li> <strong>Strong</strong>
  </ul>

will be converted to

  * <b>Bold</b>
  * '''Strong'''

When disabled (the default), the preceding HTML markup would be
converted into

  * '''Bold'''
  * '''Strong'''

=head2 preserve_italic

Boolean indicating whether italic HTML elements should be preserved as
HTML in the wiki output rather than being converted into MediaWiki
markup.

For example, if C<preserve_italic> is enabled, HTML like

  <ul>
    <li> <i>Italic</i>
    <li> <em>Emphasized</em>
  </ul>

will be converted to

  * <i>Italic</i>
  * ''Emphasized''

When disabled (the default), the preceding HTML markup would be
converted into

  * ''Italic''
  * ''Emphasized''

=head2 preserve_templates

Boolean indicating whether C<{{template}}> calls found in HTML should
be preserved in the wiki markup. If disabled (the default), templates
calls will be wrapped in C<E<lt>nowikiE<gt>> tags.

=head2 preserve_nowiki

Boolean indicating whether C<E<lt>nowikiE<gt>> tags found in HTML
should be preserved in the wiki markup. If disabled (the default),
nowiki tags will be replaced with their content.

=head2 pad_headings

Boolean indicating whether section headings should be padded with
spaces (eg, "== Section ==" instead of "==Section=="). Default is
false (ie, not to pad).

=cut

my @common_attrs = qw/ id class lang dir title style /;
my @block_attrs = ( @common_attrs, 'align' );
my @tablealign_attrs = qw/ align char charoff valign /;
my @tablecell_attrs = qw(
  abbr axis headers scope rowspan
  colspan nowrap width height bgcolor
);

# Fix for bug 14527
my $pre_prefix = '[jsmckaoqkjgbhazkfpwijhkixh]';

sub rules {
  my $self = shift;

  my %rules = (
    hr     => { replace => "\n----\n" },
    br     => { preserve => 1, empty => 1, attributes => [ qw/id class title style clear/ ] },
    p      => { block => 1, trim => 'both', line_format => 'single' },
    em     => { start => "''", end => "''", line_format => 'single' },
    strong => { start => "'''", end => "'''", line_format => 'single' },

    i      => { alias => 'em' },
    b      => { alias => 'strong' },

    pre    => { line_prefix => $pre_prefix, block => 1 },

    table   => { start => \&_table_start, end => "|}", block => 1, line_format => 'blocks' },
    tr      => { start => \&_tr_start },
    td      => { start => \&_td_start, end => "\n", trim => 'both', line_format => 'blocks' },
    th      => { start => \&_td_start, end => "\n", trim => 'both', line_format => 'single' },
    caption => { start => \&_caption_start, end => "\n", line_format => 'single' },

    img => { replace => \&_image },
    a   => { replace => \&_link },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    dl => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },

    # Preserved elements, from MediaWiki's Sanitizer.php (http://tinyurl.com/dzj6o)
    div        => { preserve => 1, attributes => \@block_attrs },
    span       => { preserve => 1, attributes => \@block_attrs },
    blockquote => { preserve => 1, attributes => [ @common_attrs, qw/ cite / ] },
    del        => { preserve => 1, attributes => [ @common_attrs, qw/ cite datetime / ] },
    ins        => { preserve => 1, attributes => [ @common_attrs, qw/ cite datetime / ] },
    font       => { preserve => 1, attributes => [ @common_attrs, qw/ size color face / ] },

    # Headings (h1-h6)
    h1 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
    h4 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => \&_hr_start, end => \&_hr_end, block => 1, trim => 'both', line_format => 'single' },
  );

  my @preserved = qw/ center cite code var sup sub tt big small strike s u ruby rb rt rp /;
  push @preserved, 'i' if $self->preserve_italic;
  push @preserved, 'b' if $self->preserve_bold;
  push @preserved, 'nowiki' if $self->preserve_nowiki;
  $rules{$_} = { preserve => 1, attributes => \@common_attrs } foreach @preserved;

  return \%rules;
}

sub attributes { {
  preserve_italic => { default => 0 },
  preserve_bold => { default => 0 },
  strip_tags => { default => [ qw/ head style script ~comment title meta link object / ] },
  pad_headings => { default => 0 },
  preserve_templates => { default => 0 },
  preserve_nowiki => { default => 0 },

  # see bug #28402
# xxx  passthrough_naked_tags => { default => [ qw/ tbody thead font / ] },
  passthrough_naked_tags => { default => [ qw/ tbody thead font span / ] },
} }

sub _hr_start { 
  my( $wc, $node, $subrules ) = @_;
  ( my $level = $node->tag ) =~ s/\D//g;
  my $affix = ('=') x $level;
  return $wc->pad_headings ? "$affix " : $affix;
}

sub _hr_end {
  my( $wc, $node, $subrules ) = @_;
  ( my $level = $node->tag ) =~ s/\D//g;
  my $affix = ('=') x $level;
  return $wc->pad_headings ? " $affix" : $affix;
}

sub postprocess_output {
  my( $self, $outref ) = @_;
  $$outref =~ s/\Q$pre_prefix\E/ /g;
}

# Calculates the prefix that will be placed before each list item.
# Handles ordered, unordered, and definition list items.
sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );

  my $prefix = '';
  foreach my $parent ( @parent_lists ) {
    my $bullet = '';
    $bullet = '*' if $parent->tag eq 'ul';
    $bullet = '#' if $parent->tag eq 'ol';
    $bullet = ':' if $parent->tag eq 'dl';
    $bullet = ';' if $parent->tag eq 'dl' and $node->tag eq 'dt';
    $prefix = $bullet.$prefix;
  }

  return "\n$prefix ";
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = defined $node->attr('href') ? $node->attr('href') : '';
  my $text = $self->get_elem_contents($node);

  # Handle internal links
  if( my $title = $self->get_wiki_page( $url ) ) {
    $title =~ s/_/ /g;
    return "[[$title]]" if $text eq $title;        # no difference between link text and page title
    return "[[$text]]" if $text eq lcfirst $title; # differ by 1st char. capitalization
    return "[[$title|$text]]";                     # completely different
  }

  # Treat them as external links
  return $url if $url eq $text;
  return "[$url $text]";
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return '' unless $node->attr('src');

  my $alt = $node->attr('alt') || '';
  my $img = basename( URI->new($node->attr('src'))->path );
  my $width = $node->attr('width') || '';

  return sprintf '[[Image:%s|%spx|%s]]', $img, $width, $alt if $alt and $width;
  return sprintf '[[Image:%s|%s]]', $img, $alt if $alt;
  return sprintf '[[Image:%s]]', $img;
}

sub _table_start {
  my( $self, $node, $rules ) = @_;
  my $prefix = '{|';

  my @table_attrs = (
    @common_attrs, 
    qw/ summary width border frame rules cellspacing
        cellpadding align bgcolor frame rules /
  );

  my $attrs = $self->get_attr_str( $node, @table_attrs );
  $prefix .= ' '.$attrs if $attrs;

  return $prefix."\n";
}

sub _tr_start {
  my( $self, $node, $rules ) = @_;
  my $prefix = '|-';
  
  my @tr_attrs = ( @common_attrs, 'bgcolor', @tablealign_attrs );
  my $attrs = $self->get_attr_str( $node, @tr_attrs );
  $prefix .= ' '.$attrs if $attrs;

  return '' unless $node->left or $attrs;
  return $prefix."\n";
}

# List of tags (and pseudo-tags, in the case of '~text') that are
# considered phrasal elements. Any table cells that contain only these
# elements will be placed on a single line.
my @td_phrasals = qw/ i em b strong u tt code span font sup sub br ~text s strike del ins /;
my %td_phrasals = map { $_ => 1 } @td_phrasals;

sub _td_start {
  my( $self, $node, $rules ) = @_;
  my $prefix = $node->tag eq 'th' ? '!' : '|';

  my @td_attrs = ( @common_attrs, @tablecell_attrs, @tablealign_attrs );
  my $attrs = $self->get_attr_str( $node, @td_attrs );
  $prefix .= ' '.$attrs.' |' if $attrs;

  # If there are any non-text elements inside the cell, then the
  # cell's content should start on its own line
  my @non_text = grep !$td_phrasals{$_->tag}, $node->content_list;
  my $space = @non_text ? "\n" : ' ';

  return $prefix.$space;
}

sub _caption_start {
  my( $self, $node, $rules ) = @_;
  my $prefix = '|+ ';

  my @caption_attrs = ( @common_attrs, 'align' );
  my $attrs = $self->get_attr_str( $node, @caption_attrs );
  $prefix .= $attrs.' |' if $attrs;

  return $prefix;
}

sub preprocess_node {
  my( $self, $node ) = @_;
  my $tag = defined $node->tag ? $node->tag : '';
  $self->strip_aname($node) if $tag eq 'a';
  $self->_strip_extra($node);
  $self->_nowiki_text($node) if $tag eq '~text';
  
#  # XXX font-to-span convers
#  $node->tag('span') if $tag eq 'font';
}

my $URL_PROTOCOLS = 'http|https|ftp|irc|gopher|news|mailto';
my $EXT_LINK_URL_CLASS = '[^]<>"\\x00-\\x20\\x7F]';
my $EXT_LINK_TEXT_CLASS = '[^\]\\x00-\\x1F\\x7F]';

# Text nodes matching one or more of these patterns will be enveloped
# in <nowiki> and </nowiki>

sub _wikitext_patterns {
  my $self = shift;

  # the caret in "qr/^/" seems redundant with "start_of_line" but both
  # are necessary
  my %wikitext_patterns = (
    misc     => { pattern => qr/^(?:\*|\#|\;|\:|\=|\!|\|)/m, location => 'start_of_line' },
    italic   => { pattern => qr/''/,     location => 'anywhere' },
    rule     => { pattern => qr/^----/m, location => 'start_of_line' },
    table    => { pattern => qr/^\{\|/m, location => 'start_of_line' },
    link     => { pattern => qr/\[\[/m,  location => 'anywhere' },
    template => { pattern => qr/{{/m,    location => 'anywhere' },
  );

  delete $wikitext_patterns{template} if $self->preserve_templates;
  return \%wikitext_patterns;
}

sub _nowiki_text {
  my( $self, $node ) = @_;

  my $text = defined $node->attr('text') ? $node->attr('text') : '';
  return unless $text;

  my $wikitext_patterns = $self->_wikitext_patterns;
  my $found_nowiki_text = 0;

  ANYWHERE: {
    my @anywhere_patterns =
      map { $_->{pattern} } grep { $_->{location} eq 'anywhere' } values %$wikitext_patterns;

    $found_nowiki_text++ if $self->_match( $text, \@anywhere_patterns );
  };

  START_OF_LINE: {
    last if $found_nowiki_text;

    my @sol_patterns =
      map { $_->{pattern} } grep { $_->{location} eq 'start_of_line' } values %$wikitext_patterns;

    # find closest parent that is a block-level node
    my $nearest_parent_block = $self->elem_search_lineage( $node, { block => 1 } );

    if( $nearest_parent_block ) {
      my $leftmostish_text_node = $self->_get_leftmostish_text_node( $nearest_parent_block );
      if( $leftmostish_text_node and $node == $leftmostish_text_node ) {
        # I'm the first child in this block element, so let's apply start_of_line nowiki fixes
        $found_nowiki_text++ if $self->_match( $text, \@sol_patterns );
      }
    }
  };

  if( $found_nowiki_text ) {
    $text = "<nowiki>$text</nowiki>";
  } else {
    $text =~ s~(\[\b(?:$URL_PROTOCOLS):$EXT_LINK_URL_CLASS+ *$EXT_LINK_TEXT_CLASS*?\])~<nowiki>$1</nowiki>~go;
  }

  $node->attr( text => $text );
}

sub _get_leftmostish_text_node {
  my( $self, $node ) = @_;
  return unless $node;
  return $node if $node->tag eq '~text';
  return $self->_get_leftmostish_text_node( ($node->content_list)[0] )
}

sub _match {
  my( $self, $text, $patterns ) = @_;
  $text =~ $_ && return 1 for @$patterns;
  return 0;
}

my %extra = (
 id => qr/catlinks/,
 class => qr/urlexpansion|printfooter|editsection/
);

# Delete <span class="urlexpansion">...</span> et al
sub _strip_extra {
  my( $self, $node ) = @_;
  my $tag = defined $node->tag ? $node->tag : '';

  foreach my $att_name ( keys %extra ) {
    my $att_value = defined $node->attr($att_name) ? $node->attr($att_name) : '';
    if( $att_value =~ $extra{$att_name} ) {
      $node->detach();
      $node->delete();
      return;
    }
  }
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-mediawiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-MediaWiki>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::MediaWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-MediaWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-MediaWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-MediaWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-MediaWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
