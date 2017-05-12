package HTML::WikiConverter::UseMod;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.50';

=head1 NAME

HTML::WikiConverter::UseMod - Convert HTML to UseMod markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'UseMod' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into UseMod markup. See
L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    br     => { replace => '<br>' },
    hr     => { replace => "\n----\n" },
    pre    => { line_prefix => ' ', block => 1 },
    p      => { block => 1, trim => 'both', line_format => 'multi' },
    i      => { start => "''", end => "''", line_format => 'single' },
    em     => { alias => 'i' },
    b      => { start => "'''", end => "'''", line_format => 'single' },
    strong => { alias => 'b' },
    tt     => { preserve => 1 },
    code   => { start => '<tt>', end => '</tt>' },

    a   => { replace => \&_link },
    img => { replace => \&_image },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    dl => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },
  );

  foreach my $level ( 1..6 ) {
    my $affix = ( '=' ) x $level;
    $rules{"h$level"} = { start => $affix.' ', end => ' '.$affix, block => 1, trim => 'both', line_format => 'single' };
  }

  return \%rules;
}

# Calculates the prefix that will be placed before each list item.
# List item include ordered, unordered, and definition list items.
sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );
  my $depth = @parent_lists;

  my $bullet = '';
  $bullet = '*' if $node->parent->tag eq 'ul';
  $bullet = '#' if $node->parent->tag eq 'ol';
  $bullet = ':' if $node->parent->tag eq 'dl';
  $bullet = ';' if $node->parent->tag eq 'dl' and $node->tag eq 'dt';

  my $prefix = "\n".( ( $bullet ) x $depth );
  $prefix = ' '.$bullet if $node->left && $node->left->tag eq 'dt';
  return $prefix.' ';
}

sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';
  return $url if $url eq $text;
  return "[$url $text]";
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return $node->attr('src') || '';
}

sub preprocess_node {
  my( $self, $node ) = @_;
  $self->strip_aname($node) if $node->tag eq 'a';
  $self->caption2para($node) if $node->tag eq 'caption';
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-usemod at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-UseMod>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::UseMod

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-UseMod>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-UseMod>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-UseMod>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-UseMod>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
