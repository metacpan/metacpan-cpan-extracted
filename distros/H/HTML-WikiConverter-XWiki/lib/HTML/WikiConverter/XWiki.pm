package HTML::WikiConverter::XWiki;
use base 'HTML::WikiConverter';

use warnings;
use strict;

use URI;
our $VERSION = '0.02';

=head1 NAME

HTML::WikiConverter::XWiki - Convert HTML to XWiki markup

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( 
     dialect => 'XWiki',
     space_identifier => 'MySpace'
  );
  print $wc->html2wiki( $html );

  - or -

  html2wiki --dialect XWiki --base-uri=http://yoursite.xwiki.org/ index.html

=head1 DESCRIPTION

This module contains rules for converting HTML into XWiki markup, the wiki dialect used by xwiki.org.
See L<HTML::WikiConverter> for additional usage details.

=head1 ATTRIBUTES

The XWiki converter introduces a new attribute C<space_identifier>.

=head2 space_identifier

The value of this attribute is used to generate local links. The default value is C<'Main'>.

C<E<lt>a href="http://www.xwiki.org/Test"E<gt>TestE<lt>/aE<gt>> would result as C<[Test|Main.Test]>.

=cut

sub rules {
  my %rules = (
	  b => { start => '*', end => '*' },
	  i => { start => '~~', end => '~~' },
	  strong => { alias => 'b' },
	  s => { start => '--', end => '--' },
	  del => { alias => 's' },
	  em => { alias => 'i' },
	  hr => { replace => "\n----\n" },

      ul => { line_format => 'multi', block => 1 },
      ol => { alias => 'ul' },
      li => { start => \&_li_start, trim => 'leading' },
	  code => { start => '{code}', end => '{code}', },
	  pre => { start => '<pre>{pre}', end => '{/pre}</pre>', block => 1 },

 	  table => { start => "{table}\n", end => '{table}', block => 0, line_format => 'multi' },
	  tr => { line_format => 'single', end => "\n" },
	  td => { end => \&_td_end },
	  th => { alias => 'td' },
	  dl => { line_format => 'multi', block => 1, preserve => 1 },
	  dd => { preserve => 1 },
	  dt => { preserve => 1 },

      p => { block => 1, line_format => 'multi', trim => 'both' },
      br => { start => "\n" },
	  

      a => { replace => \&_link }
  );
  
  my @arr = ();
  for( 1..6 ) {
    push( @arr, '1' );
    my $str = join( ".", @arr );
    $rules{"h$_"} = { start => "$str ", block => 1, trim => 'both', line_format => 'single' };
  }

  return \%rules;
}


sub attributes {
  my %attributes = (
    space_identifier => { default => 'Main', optional => 0 }
  );
  return \%attributes;
}


sub _li_start {
  my( $self, $node, $rules ) = @_;

  my @parents = $node->look_up( _tag => qr/ul|ol/ );
  my $prefix = join '', map{ $_->tag eq 'ol' ? '1' : '*' } reverse @parents; 
  $prefix .= '.' if $node->parent->tag eq 'ol';

  return "\n$prefix ";
}


sub _td_end {
  my( $self, $node, $rules ) = @_;
  my @right_cells = grep { $_->tag && $_->tag =~ /th|td/ } $node->right;
  return ' | ' if @right_cells;
  return '';
}


sub _link {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';  
  my $space = $self->_attr( 'space_identifier' ) || 'Main';
  
  if( my $title = $self->get_wiki_page( $url ) ) {
    $text =~ s~\+~ ~g; # replace '+' by ' '
    return "[$space.$text]" if lc $text eq lc $title;
    return "[$text|$space.$title]";
  } else {
    return $url if $url eq $text;
    return "[$text>$url]";
  }
}


=head1 AUTHOR

Patrick Stählin, C<< <packi at cpan.org> >>.
Many thanks to David J. Iberri, C<< <diberri at cpan.org> >> for writing L<HTML::WikiConverter>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::XWiki

=head1 COPYRIGHT & LICENSE

Copyright 2006 Encodo Systems AG, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
