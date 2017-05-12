package HTML::WikiConverter::Wikispaces;
use base 'HTML::WikiConverter';

use warnings;
use strict;

use URI;
use File::Basename;
our $VERSION = '0.02';

=head1 NAME

HTML::WikiConverter::Wikispaces - Convert HTML to Wikispaces markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'Wikispaces' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into Wikispaces
markup. See L<HTML::WikiConverter> for additional usage details.

=cut

sub rules {
  my %rules = (
    hr => { replace => "\n----\n" },

    h1 => { start => '= ',      end => ' =',      block => 1, trim => 'both', line_format => 'single' },
    h2 => { start => '== ',     end => ' ==',     block => 1, trim => 'both', line_format => 'single' },
    h3 => { start => '=== ',    end => ' ===',    block => 1, trim => 'both', line_format => 'single' },
# wikispaces does not support H4-H6, so just map to H3
    h4 => { start => '=== ',    end => ' ===',    block => 1, trim => 'both', line_format => 'single' },
    h5 => { start => '=== ',    end => ' ===',    block => 1, trim => 'both', line_format => 'single' },
    h6 => { start => '=== ',    end => ' ===',    block => 1, trim => 'both', line_format => 'single' },

    img => { replace => \&_image },

    b      => { start => "**", end => "**", trim => 'leading'},
    strong => { alias => 'b' },
    i      => { start => "//", end => "//" },
    em     => { alias => 'i' },
    u      => { start => "__", end => "__"},
    code   => { start => "\n[[code]]\n", end => "\n[[code]]\n"},
    tt     => { start => "{{", end => "}}"},

# from PhpWiki
    blockquote => { start => \&_blockquote_start, block => 1, line_format => 'multi' },
    p => { block => 1, trim => 'both', line_format => 'multi' },

    a => { replace => \&_link},

    ul => { line_format => 'multi', block => 1 },
    ol => { alias => 'ul' },
    dl => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },
    dt => { alias => 'li' },
    dd => { alias => 'li' },

# from PmWiki
    table => { block => 1 },
    tr    => { start => "\n||", line_format => 'multi' },
    td    => { start => \&_td_start, end => \&_td_end, trim => 'both' },
    th    => { alias => 'td' },

    pre => { preserve => 1 }
  );

  return \%rules;
}

# Calculates the prefix that will be placed before each list item.
# List item include ordered and unordered list items.
sub _li_start {
  my( $self, $node, $rules ) = @_;
  my @parent_lists = $node->look_up( _tag => qr/ul|ol|dl/ );

  my $prefix = '';
  foreach my $parent ( @parent_lists ) {
    my $bullet = '';
    $bullet = '*' if $parent->tag eq 'ul';
    $bullet = '#' if $parent->tag eq 'ol';
    # just map definition lists onto unordered lists
    $bullet = '*' if $parent->tag eq 'dl';
    $bullet = '*' if $parent->tag eq 'dl' and $node->tag eq 'dt';
    $prefix = $bullet.$prefix;
  }

  return "\n$prefix ";
}

# derived from MediaWiki
sub _image {
  my( $self, $node, $rules ) = @_;
  return '' unless $node->attr('src');

  my $img = $node->attr('src');
  # if it's not an absolute path then strip to just the base name
  if($img !~ m/^https?:\/\//) {
  	$img = basename( URI->new($node->attr('src'))->path );
  }
  my $alt = $node->attr('alt') || '';
  my $align = $node->attr('align') || '';
  my $title = $node->attr('title') || '';
  my $width = $node->attr('width') || '';
  my $height = $node->attr('height') || '';
  
  my $ret = "[[image:$img";
  $ret .= " alt=\"$alt\"" if $alt;
  $ret .= " align=\"$align\"" if $align;
  $ret .= " width=\"$width\"" if $width;
  $ret .= " height=\"$height\"" if $height;
  $ret .= " caption=\"$title\"" if $title;
  $ret .= "]]";
  return $ret;
}

# derived from PmWiki
sub _anchor {
  my( $self, $node, $rules ) = @_;
  my $name = $node->attr('name') || '';
  # Wikispaces does not support anchors begining with non-alphabetic characters, so prefix all anchors with ws_
  $name = 'ws_'.$name if $name;
  my $text = $self->get_elem_contents($node);
  my $ret = "[[#$name]]";
  $ret .= "$text" if $text;
  return $ret;
}

# derived from PmWiki
sub _link {
  my( $self, $node, $rules ) = @_;
  return $self->_anchor($node, $rules) if $node->attr('name');

  my $url = $node->attr('href') || '';
  # if it's not an absolute path then strip to just the base name
  if($url !~ m/^https?:\/\//) {
  	my($link,$path,$suffix) = fileparse($url,qr{\..*});
  	my $r = rindex($suffix,'#');
  	if($r!=-1) {
  		$suffix = substr $suffix, $r+1;
  		$link .= '#ws_'.$suffix;
  	}
	my $text = $self->get_elem_contents($node) || '';
	
	return "[[$link]]" if $text eq $link;
	return "[[$link|$text]]";
  } else {
  	return $url;
  }
}

# tables derived from PmWiki
sub _td_start {
  my( $self, $node, $rules ) = @_;
  my $colspan = $node->attr('colspan') || 1;
  my $prefix = ( '||' ) x ($colspan-1);
  $prefix .= $node->tag eq 'th' ? '~' : '';

  my $align = $node->attr('align') || 'left';
  my $style = $node->attr('style') || '';
  $align = 'center' if $style eq 'text-align: center;';
  $align = 'right' if $style eq 'text-align: right;';

  $prefix .= '= ' if $align eq 'center';
  $prefix .= '> ' if $align eq 'right';
  $prefix .= ' ' if $align eq 'left';

  return $prefix;
}

sub _td_end {
  my( $self, $node, $rules ) = @_;
  my $suffix = ' ||';
 
  return $suffix;
}

# blockquote derived from PmWiki
sub _blockquote_start {
  my( $self, $node, $rules ) = @_;
  my @parent_bqs = $node->look_up( _tag => 'blockquote' );
  my $depth = @parent_bqs;
  
  my $start = ( '>' ) x $depth;
  return "\n".$start.' ';
}

=head1 AUTHOR

Martin Budden, C<< <mjbudden at gmail.com> >>

Heavily based on other HTML to wikitext modules written by David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-wikispaces at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-Wikispaces>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::Wikispaces

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-Wikispaces>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-Wikispaces>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-Wikispaces>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-Wikispaces>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Martin Budden, all rights reserved.

Heavily based on other HTML to wikitext modules written by David J. Iberri

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
