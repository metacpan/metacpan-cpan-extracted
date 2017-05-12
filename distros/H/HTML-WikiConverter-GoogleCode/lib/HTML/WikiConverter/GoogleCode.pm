package HTML::WikiConverter::GoogleCode;

use warnings;
use strict;

use base 'HTML::WikiConverter';
use Params::Validate ':types';
use URI;

=head1 NAME

HTML::WikiConverter::GoogleCode - Convert HTML to Google Code wiki markup.

=head1 SYNOPSIS

  use HTML::WikiConverter;
  my $wc = new HTML::WikiConverter( dialect => 'GoogleCode' );
  print $wc->html2wiki( $html );

=head1 DESCRIPTION

This module contains rules for converting HTML into Google Code wiki
markup. See L<HTML::WikiConverter> for additional usage details.

=head1 VERSION

Version 0.12

=cut 

our $VERSION = '0.12';


=head1 FUNCTIONS

=head2 rules

Returns the HTML to wiki conversion rules

=cut

sub rules {
  my %rules = (
    p   => { block => 1, trim => 'both', line_format => 'multi' },
    pre => { block => 1, start => "{{{\n", end => "\n}}}" },

    i      => { start => "_", end => "_", line_format => 'single' },
    em     => { alias => 'i' },
    b      => { start => "*", end => "*", line_format => 'single' },
    strong => { alias => 'b' },
    #u      => { start => '__', end => '__', line_format => 'single' },

    sup   => { start => '^', end => '^', line_format => 'single' },
    sub   => { start => ',,', end => ',,', line_format => 'single' },
    code  => { start => '`', end => '`', line_format => 'single' },
    tt    => { alias => 'code' },
    #small => { start => '~-', end => '-~', line_format => 'single' },
    #big   => { start => '~+', end => '+~', line_format => 'single' },

    a => { replace => \&_link },
    img => { replace => \&_image },

    ul => { line_format => 'multi', block => 1, line_prefix => '  ' },
    ol => { alias => 'ul' },

    li => { start => \&_li_start, trim => 'leading' },

    #dl => { line_format => 'multi' },
    #dt => { trim => 'both', end => ':: ' },
    #dd => { trim => 'both' },

    hr => { replace => "\n----\n"},
    br => { replace => "\n" },

    table => { block => 1, line_format => 'multi' },
    tr => { end => "||\n", line_format => 'single' },
    td => { start => '|| ', end => ' ', trim => 'both' },
    th => { alias => 'td' },
  );

  # Headings (h1-h6)
  my @headings = ( 1..6 );
  foreach my $level ( @headings ) {
    my $tag = "h$level";
    my $affix = ( '=' ) x ($level);
    $affix = '======' if $level == 6;
    $rules{$tag} = { start => $affix.' ', end => ' '.$affix, block => 1, trim => 'both', line_format => 'single' };
  }

  return \%rules;
}

=head2 attributes

Returns the conversion L</ATTRIBUTES> particular to the GoogleCode dialect

=cut

sub attributes { {
  escape_autolink => {default => [], type => ARRAYREF},
  summary => {default => 0, type => SCALAR},
  labels => {default => [], type => ARRAYREF}
}}

sub _li_start {
  my( $self, $node, $rules ) = @_;
  my $bullet = '';
  $bullet = '*'  if $node->parent->tag eq 'ul';
  $bullet = '#' if $node->parent->tag eq 'ol';
  return "\n$bullet ";
}

sub _link {
  my( $self, $node, $rules ) = @_;

  # (bug #17813)
  my $name = $node->attr('name');

  my $url = $node->attr('href') || '';
  my $text = $self->get_elem_contents($node) || '';

  # (bug #17813)
  if( $self->_abs2rel($url) =~ /^#/ ) {
    $url = $self->_abs2rel($url);
  }

  return $url if $url eq $text;
  return "[$url $text]";
}

sub _abs2rel {
  my( $self, $uri ) = @_;
  return $uri unless $self->base_uri;
  return URI->new($uri)->rel($self->base_uri)->as_string;
}

sub _image {
  my( $self, $node, $rules ) = @_;
  return $node->attr('src') ? ('[' . $node->attr('src') . ']')  : '';
}

=head2 preprocess_node

HTML element specific pre-processing

=cut

sub preprocess_node {
  my( $self, $node ) = @_;

  $self->strip_aname($node) if $node->tag and $node->tag eq 'a';
  $self->caption2para($node) if $node->tag and $node->tag eq 'caption';

  # (bug #17813)
  if($node->tag and $node->tag eq 'a' and $node->attr('name') ) {
    my $name = $node->attr('name');
    $node->preinsert( new HTML::Element('a', name => $name) );
    $node->attr( name => undef );
  }
    
}

=head2 preprocess_tree

HTML document specific pre-processing

=cut

sub preprocess_tree {
	my ($self, $root) = @_;
	$self->_escape_autolink($root);
}

# escape Google wiki autolinking of specific CamelCase words
# words in attribute escape_autolink
sub _escape_autolink {
	my ($self, $parent) = @_;
  foreach my $child ($parent->content_list) {
  	if($child->tag eq '~text') {
  		my %toChange;
  		my $theText = $child->attr('text');
  		while($theText =~ /\b(\w+)\b/g) {
  			if ($self->is_camel_case($1)) {
  				if(grep(/^$1$/, @{$self->escape_autolink})) {
  					$toChange{$1} = undef;
  				}
  			}
  		}
  		foreach my $val (keys %toChange) {
  			$theText =~ s/$val/!$val/g;
  		}
  		$child->attr('text', $theText);
  	} else {
  		unless($child->tag eq 'pre') {
 				$self->_escape_autolink($child);
 			}
  	}
  }
}	

my @protocols = qw( http https mailto );
my $urls  = '(' . join('|', @protocols) . ')';
my $ltrs  = '\w';
my $gunk  = '\/\#\~\:\.\?\+\=\&\%\@\!\-';
my $punc  = '\.\:\?\-\{\(\)\}';
my $any   = "${ltrs}${gunk}${punc}";
my $url_re = "\\b($urls:\[$any\]+?)(?=\[$punc\]*\[^$any\])";

=head2 postprocess_output

Wiki document post-processing

=cut

sub postprocess_output {
  my( $self, $outref ) = @_;
  $$outref =~ s/($url_re)\[\[BR\]\]/$1 [[BR]]/go;

	# add 'summary' and 'labels' wiki markup elements
	my $additional_markup = '';
	if($self->summary) {
		$additional_markup = '#summary ' . $self->summary . "\n";
	}
	if(@{$self->labels}) {
		$additional_markup .= '#labels ' . join(',', @{$self->labels}) . "\n";
	}
	$$outref = $additional_markup . $$outref;
}


=head1 ATTRIBUTES

In addition to the regular set of attributes recognized by the
HTML::WikiConverter constructor, this dialect also accepts the
following attributes that can be passed into the C<new()>
constructor. See L<HTML::WikiConverter/ATTRIBUTES> for usage details.

=head2 escape_autolink

A reference to an array of CamelCase words for which Google Code wiki
autolink-ing should be escaped by preceeding the word with a !.

=head2 summary

Text to be produced in the 'summary' wiki markup element.  The summary element 
appears in the index page of the project's wiki.

=head2 labels

A reference to an array of text values to be produced in the 'labels' wiki markup 
element.  Allowed values for a project can be found on the project's Google 
Code web-site on the C<Administer/Wiki> tab.

=head1 AUTHOR

Marty Kube, C<< <martykube at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-wikiconverter-googlecode at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter-GoogleCode>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::WikiConverter::GoogleCode

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-GoogleCode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-GoogleCode>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-GoogleCode>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-GoogleCode>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on the L<HTML::WikiConverter::MoinMoin> module by 
David J. Iberri, C<< <diberri at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Marty Kube, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::WikiConverter::GoogleCode
