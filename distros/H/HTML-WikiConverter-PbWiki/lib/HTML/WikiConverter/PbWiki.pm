package HTML::WikiConverter::PbWiki;

use warnings;
use strict;

use base 'HTML::WikiConverter';

our $VERSION = '0.01';

my $PB_IMG_DIR = "f/"; #hard-coded URI for images used by PbWiki.com. Subject to change.

=head1 NAME

HTML::WikiConverter::PbWiki - Convert HTML to PbWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'PbWiki' );
  print $wc->html2wiki( $html );

  - or -

  html2wiki --dialect PbWiki --base-uri=http://yoursite.pbwiki.com/ index.html

=head1 DESCRIPTION

This module contains rules for converting HTML into PbWiki markup, the wiki dialect used by pbwiki.com.
See L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    hr => { replace => "\n---\n" },
    br => { replace => "\n" },     
    font => { preserve => 1, attributes => [ qw/ font size color face / ] },
    center => { preserve => 1},

    h1 => { start => '! ',      block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => '!! ',     block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => '!!! ',    block => 1, trim => 'both', line_format => 'single' },
    h4 => { start => '!!!! ',   block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => '!!!!! ',  block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => '!!!!!! ', block => 1, trim => 'both', line_format => 'single' },

    pre        => { line_prefix => ' ', block => 1 },
    p          => { block => 1, trim => 'both', line_format => 'multi' },

    b      => { start => "**", end => "**" },
    strong => { alias => 'b' },
    i      => { start => "''", end => "''" },
    em     => { alias => 'i' },
    u      => { start => '__', end => '__'},
    strike => { start => ' -', end => '- '},
    s      => { alias => 'strike' },

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },

    a   => { replace => \&_link },
    img => { replace => \&_image },

    table => { start => \&_table_start, block => 1, line_format => 'single' },
    tr    => { start => "", line_format => 'single' },
    td    => { start => \&_td_start, end => \&_td_end, trim => 'both', line_format => 'single' },
    th    => { alias => 'td' }
  );

  return \%rules;
}

sub _table_start {
  my( $self, $node, $rules ) = @_;
  my @attrs = (); #qw/ border cellpadding cellspacing width bgcolor align /;
  return '| '.$self->get_attr_str( $node, @attrs );
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
  my $suffix = ( '|' ) x $colspan;

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

  my $prefix = ( $bullet ) x $depth;
  return "\n".$prefix.' ';
}

sub _link {
  my( $self, $node, $rules ) = @_;
  return $self->_anchor($node, $rules) if $node->attr('name');

  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';

  #remove '.html' and any subdirs
  $url =~ s/.*?\/?(\w+\.\w+)$/$1/; 
  $url =~ s/\.html?//;
#  $url =~ s/[\.\/]//g;

  return "[$text]" if uc($text) eq uc($url);
  return "[$url | $text]";
}

sub _anchor {
  my( $self, $node, $rules ) = @_;
  #keeping this out until PbWiki implements normal anchors.
}

sub _image {
  my( $self, $node, $rules ) = @_;

  my $str = $node->attr('src') || '';
  return "[".$str."]";
}

#PbWiki requires absolute image URIs, but by default links will be relative.
#If there is interest absolute links could also be added.
sub preprocess_node {
  my( $self, $node ) = @_;

  #TODO: This is a really bad kludge. It will be placed in the attribute() method in a PbWiki 0.53+ compatible version. This was why the attribute() method was added to begin with.
  if (!$self->base_uri) {die "The PbWiki dialect requires a base uri to create image links. Please provide one using --base_uri=something.pbwiki.com.\n";}
  #TODO: prepend base_uri with 'http://' and append '.pbwiki.com' if they did not, so you can just specify your wiki as 'wikiname' on the commandline.

  my $tag = $node->tag || ''; #gives warning if $nodes->tag is null and we try to compare it to a string
  $self->_move_aname($node) if $tag eq 'a' and $node->attr('name');
  $self->caption2para($node) if $tag eq 'caption';

  if ($tag eq 'a' and $node->attr('href')) {
      $node->attr( href => URI->new($node->attr('href'))->rel($self->base_uri)->as_string );
  }

  if ($tag eq 'img' and $node->attr('src')) {
      my $str = $node->attr('src') || '';
      $str =~ s/.*?\/?(\w+\.\w+)$/$1/; #strip of any directory info to get just the image name
      $str = $self->base_uri() . $PB_IMG_DIR . $str;
      $node->attr( src => $str);      
  }
}

#Note: feature removed until PbWiki supports anchor tags other than !Sections.
sub _move_aname {
  my( $self, $node ) = @_;

  # Keep 'a href's around
  $node->replace_with_content->delete unless $node->attr('href');
}

=head1 AUTHOR

Dave Schaefer, C<< <dschaefer at cpan.org> >>.
Many thanks to David J. Iberri, C<< <diberri at cpan.org> >> for help with and advice on writing this dialect.


=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-pmwiki at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-PbWiki>.
David J. Iberri will be notified, and then you'll automatically be notified of
progress on your bug as changes are made.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::PbWiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-PbWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-PbWiki>

=item * RT: CPAN's request tracker
    
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-PbWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-PbWiki>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dave Schaefer, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
