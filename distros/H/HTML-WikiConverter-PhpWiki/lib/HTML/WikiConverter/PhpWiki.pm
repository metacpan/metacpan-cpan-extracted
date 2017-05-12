package HTML::WikiConverter::PhpWiki;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.51';

=head1 NAME

HTML::WikiConverter::PhpWiki - Convert HTML to PhpWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'PhpWiki' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into PhpWiki
markup. See L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    hr => { replace => "\n----\n" },
    br => { replace => '%%%' },

    blockquote => { start => \&_blockquote_start, block => 1, line_format => 'multi' },
    p => { block => 1, trim => 'both', line_format => 'multi' },
    i => { start => "_", end => "_" },
    em => { alias => 'i' },
    b => { start => "*", end => "*" },
    strong => { alias => 'b' },

    img => { replace => \&_image },
    a => { replace => \&_link },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    dl => { line_format => 'blocks', block => 1 },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { trim => 'both', end => ":\n" },
    dd => { line_prefix => '  ' },

    td => { start => \&_td_start, end => \&_td_end, trim => 'both' },
    th => { alias => 'td' },

    h1 => { start => '!!! ', block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => '!!! ', block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => '!! ',  block => 1, trim => 'both', line_format => 'single' },
    h4 => { start => '! ',   block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => '! ',   block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => '! ',   block => 1, trim => 'both', line_format => 'single' },

    pre => { preserve => 1 },
  );

  $rules{$_} = { preserve => 1 } for qw/ big small tt abbr acronym cite code dfn kbd samp var sup sub /;
  return \%rules;
}

# Calculates the prefix that will be placed before each list item.
# List item include ordered and unordered list items.
sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol/ );
  my $depth = @parent_lists;

  my $bullet = '';
  $bullet = '*' if $node->parent->tag eq 'ul';
  $bullet = '#' if $node->parent->tag eq 'ol';

  my $prefix = ( $bullet ) x $depth;
  return "\n$prefix ";
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return $node->attr('src') || '';
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';
  return "[$text|$url]";
}

# XXX doesn't handle rowspan
sub _td_start {
  my( $self, $node, $rules ) = @_;
  my @left = $node->left;
  return '' unless @left;
  return ( ( '  ' ) x scalar(@left) );
}

sub _td_end {
  my( $self, $node, $rules ) = @_;
  my $right_tag = $node->right && $node->right->tag ? $node->right->tag : '';
  return $right_tag =~ /td|th/ ? " |\n" : "\n";
}

sub _blockquote_start {
  my( $self, $node, $rules ) = @_;
  my @bq_lineage = $node->look_up( _tag => 'blockquote' );
  my $depth = @bq_lineage;
  return "\n" . ( ( '  ' ) x $depth );
}

sub preprocess_node {
  my( $self, $node ) = @_;
  $self->strip_aname($node) if $node->tag eq 'a';
  $self->caption2para($node) if $node->tag eq 'caption';

  # Bug 17550 (https://rt.cpan.org/Public/Bug/Display.html?id=17550)
  $node->postinsert(' ') if $node->tag eq 'br' and $node->right and $node->right->tag eq 'br';
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-phpwiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-PhpWiki>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::PhpWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-PhpWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-PhpWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-PhpWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-PhpWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
