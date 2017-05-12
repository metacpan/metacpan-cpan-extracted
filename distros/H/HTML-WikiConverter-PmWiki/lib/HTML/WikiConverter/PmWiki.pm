package HTML::WikiConverter::PmWiki;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.51';

=head1 NAME

HTML::WikiConverter::PmWiki - Convert HTML to PmWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'PmWiki' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into PmWiki markup. See
L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    hr => { replace => "\n----\n" },
    br => { replace => \&_br },

    h1 => { start => '! ',      block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => '!! ',     block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => '!!! ',    block => 1, trim => 'both', line_format => 'single' },
    h4 => { start => '!!!! ',   block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => '!!!!! ',  block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => '!!!!!! ', block => 1, trim => 'both', line_format => 'single' },

    blockquote => { start => \&_blockquote_start, trim => 'both', block => 1, line_format => 'multi' },
    pre        => { line_prefix => ' ', block => 1 },
    p          => { block => 1, trim => 'both', line_format => 'multi' },

    b      => { start => "'''", end => "'''", line_format => 'single' },
    strong => { alias => 'b' },
    i      => { start => "''", end => "''", line_format => 'single' },
    em     => { alias => 'i' },
    tt     => { start => '@@', end => '@@', trim => 'both', line_format => 'single' },
    code   => { alias => 'tt' },

    big   => { start => "'+", end => "+'", line_format => 'single' },
    small => { start => "'-", end => "-'", line_format => 'single' },
    sup   => { start => "'^", end => "^'", line_format => 'single' },
    sub   => { start => "'_", end => "_'", line_format => 'single' },
    ins   => { start => '{+', end => '+}', line_format => 'single' },
    del   => { start => '{-', end => '-}', line_format => 'single' },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    li => { start => \&_li_start, trim => 'leading' },

    dl => { alias => 'ul' },
    dt => { start => \&_li_start, line_format => 'single', trim => 'both' },
    dd => { start => ': ' },

    a   => { replace => \&_link },
    img => { replace => \&_image },

    table => { start => \&_table_start, block => 1 },
    tr    => { start => "\n||", line_format => 'single' },
    td    => { start => \&_td_start, end => \&_td_end, trim => 'both' },
    th    => { alias => 'td' }
  );

  return \%rules;
}

sub _br {
  my( $self, $node, $rules ) = @_;
  return " [[<<]] " if $node->look_up( _tag => 'table' );
  return " \\\\\n";
}

sub _table_start {
  my( $self, $node, $rules ) = @_;
  my @attrs = qw/ border cellpadding cellspacing width bgcolor align /;
  return '|| '.$self->get_attr_str( $node, @attrs );
}

sub _td_start {
  my( $self, $node, $rules ) = @_;
  my $prefix = $node->tag eq 'th' ? '!' : '';

  my $align = $node->attr('align') || 'left';
  $prefix .= ' ' if $align eq 'center' or $align eq 'right';

  return $prefix;
}

sub _td_end {
  my( $self, $node, $rules ) = @_;
  my $colspan = $node->attr('colspan') || 1;
  my $suffix = ( '||' ) x $colspan;

  my $align = $node->attr('align') || 'left';
  $suffix = ' '.$suffix if $align eq 'center' or $align eq 'left';

  return $suffix;
}

sub _blockquote_start {
  my( $self, $node, $rules ) = @_;
  my @parent_bqs = $node->look_up( _tag => 'blockquote' );
  my $depth = @parent_bqs;
  
  my $start = ( '-' ) x $depth;
  return "\n".$start.'>';
}

sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );
  my $depth = @parent_lists;

  my $bullet = '';
  $bullet = '*' if $node->parent->tag eq 'ul';
  $bullet = '#' if $node->parent->tag eq 'ol';
  $bullet = ':' if $node->parent->tag eq 'dl';

  my $prefix = ( $bullet ) x $depth;
  return "\n".$prefix.' ';
}

sub _link {
  my( $self, $node, $rules ) = @_;
  return $self->_anchor($node, $rules) if $node->attr('name');

  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';

  return $url if $text eq $url;
  return "[[$url | $text]]";
}

sub _anchor {
  my( $self, $node, $rules ) = @_;
  my $name = $node->attr('name') || '';
  return "[[#$name]]";
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return $node->attr('src') || '';
}

sub preprocess_node {
  my( $self, $node ) = @_;
  my $tag = $node->tag || '';
  $self->_move_aname($node) if $tag eq 'a' and $node->attr('name');
  $self->caption2para($node) if $tag eq 'caption';
  if( $tag eq '~text' and $node->left and $node->left->tag and $node->left->tag eq 'br' and !$node->look_up(_tag => 'pre') ) {
    ( my $text = $node->attr('text') ) =~ s/^\s+//;
    $node->attr( text => $text );
  }
}

sub _move_aname {
  my( $self, $node ) = @_;

  my $name = $node->attr('name') || '';
  $node->attr( name => undef );

  my $aname = new HTML::Element( 'a', name => $name );
  $node->preinsert($aname);

  # Keep 'a href's around
  $node->replace_with_content->delete unless $node->attr('href');
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-pmwiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-PmWiki>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::PmWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-PmWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-PmWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-PmWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-PmWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
