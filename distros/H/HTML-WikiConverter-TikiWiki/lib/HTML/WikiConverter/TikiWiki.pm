package HTML::WikiConverter::TikiWiki;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.50';

=head1 NAME

HTML::WikiConverter::TikiWiki - Convert HTML to TikiWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'TikiWiki' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into TikiWiki
markup. See L<HTML::WikiConverter> for additional usage details.

Formatting rule documentation:

  * Markup: http://doc.tikiwiki.org/tiki-index.php?page_ref_id=268
  * Images: http://doc.tikiwiki.org/tiki-index.php?page_ref_id=277
  * Links:  http://doc.tikiwiki.org/tiki-index.php?page_ref_id=270

Unsupported formatting rules:

  * text boxes

=cut

sub rules {
  my %rules = (
    b => { start => '__', end => '__' },
    strong => { alias => 'b' },
    i => { start => "''", end => "''" },
    em => { alias => 'i' },
    center => { start => '::', end => '::' },
    code => { start => '-+', end => '+-' },
    tt => { alias => 'code' },
    u => { start => '===', end => '===' },
    
    a => { replace => \&_link },
    img => { replace => \&_image },    

    p => { block => 1, trim => 'both', line_format => 'multi' },

    ul => { line_format => 'multi', block => 1 },
    li => { start => \&_li_start, trim => 'leading' },
    ol => { alias => 'ul' },
    dl => { alias => 'ul' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },
  );

  return \%rules;
}

sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );

  my $bullet = '';
  $bullet = '*' if $node->parent->tag eq 'ul';
  $bullet = '#' if $node->parent->tag eq 'ol';
  $bullet = ':' if $node->parent->tag eq 'dl';
  $bullet = ';' if $node->parent->tag eq 'dl' and $node->tag eq 'dt';
  $bullet = ( $bullet ) x scalar @parent_lists;

  my $prefix = $node->tag eq 'dd' ? ' ' : "\n";
  return $prefix.$bullet.' ';
}

sub _image {
  my( $self, $node, $rules ) = @_;
  my $src = $node->attr('src') || '';
  return '' unless $src;
  my $img_attrs = $self->get_attr_str( $node, qw/ src width height align desc link / );
  $img_attrs =~ s/"//g; # no quotes allowed!                                  #" emacs
  return "{img $img_attrs}";
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';

  if( my $title = $self->get_wiki_page($url) ) {
    $title =~ s/_/ /g;
    return $text if lc $title eq lc $text and $self->is_camel_case($text);
    return "(($text))" if lc $text eq lc $title;
    return "(($title|$text))";
  } else {
    return "[$url]" if $url eq $text;
    return "[$url|$text]";
  }
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-tikiwiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-TikiWiki>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::TikiWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-TikiWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-TikiWiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-TikiWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-TikiWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
