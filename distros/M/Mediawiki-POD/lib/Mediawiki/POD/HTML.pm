
# a subclass of Pod::Simple to catch X<keyword> and =head lines

package Mediawiki::POD::HTML;

use 5.008001;
use base qw/Pod::Simple::HTML/;
use Graph::Easy;
use Graph::Easy::Parser;

$VERSION = '0.04';

use strict;

sub new
  {
  my $class = shift;

  my $self = Pod::Simple::HTML->new(@_);

  $self->{_mediawiki_pod_html} = {};
  my $storage = $self->{_mediawiki_pod_html};

  # we do not need an index, we will generate it ourselves
  $self->index(0);

  $storage->{in_headline} = 0;
  $storage->{in_x} = 0;
  $storage->{in_graph} = 0;
  $storage->{headlines} = [];
  $storage->{graph_id} = 0;

  # the text common to all graphs
  $storage->{graph_common} = '';
  # the text of the current graph
  $storage->{cur_graph} = '';

  $storage->{search} = 'http://cpan.uwinnipeg.ca/search?query=##KEYWORD##';
  $storage->{search_space} = undef;

  # we handle these, too:
  $self->accept_targets('graph', 'graph-common');

  bless $self, $class;
  }

sub _convert_graph
  {
  # when we detect the end of a "graph" section, we create CSS+HTML from it:
  my ($self) = @_;

  my $storage = $self->{_mediawiki_pod_html};

#  print "# Converting to graph:\n";
#  print "# '$storage->{graph_common}'\n";
#  print "# '$storage->{cur_graph}'\n";

  my $parser = Graph::Easy::Parser->new();

  my $graph = $parser->from_text( 
	$storage->{graph_common} . "\n" . $storage->{cur_graph} );
    
  $graph->set_attribute('gid', $storage->{graph_id}++);

  $self->_my_output( '<style type="text/css">' . $graph->css() . '</style>' );
  $self->_my_output( $graph->as_html() );

  $storage->{in_graph} = 0;
  $storage->{cur_graph} = '';
  }

#############################################################################
# overriden methods for parsing:

sub _handle_element_start
  {
  my ($self, $element_name, $attr) = @_;

#  print STDERR "start '$element_name'\n";

  my $storage = $self->{_mediawiki_pod_html};

  if ($element_name eq 'X' && $storage->{in_x} == 0)
    {
    $storage->{in_x} = 1;
    $self->_my_output( '<div class="keywords">Keywords: &nbsp;' );
    }
  if ($element_name ne 'X' && $storage->{in_x} != 0)
    {
    # broken chain of X<> keywords
    $self->_my_output( '</div>' );
    $storage->{in_x} = 0;
    }

  if ($storage->{in_graph_common} && $element_name !~ /^Data/i)
    {
    $storage->{in_graph_common} = 0;
    }

  if ($storage->{in_graph} && $element_name !~ /^Data/i)
    {
    $self->_convert_graph();
    }
  # =for graph and =begin graph sections
  if ($element_name eq 'for' && ($attr->{target} || '') eq 'graph')
    {
    $storage->{in_graph} = 1;
    $storage->{cur_graph} = '';
    return;
    }

  # =for graph-common and =begin graph sections
  if ($element_name eq 'for' && ($attr->{target} || '') eq 'graph-common')
    {
    $storage->{in_graph_common} = 1;
    $storage->{graph_common} = '';
    return;
    }

  if ($element_name =~ /^head/)
    {
    push @{ $storage->{headlines} }, $element_name . ' ';
    $storage->{in_headline} = 1;
    }

  $self->SUPER::_handle_element_start($element_name, $attr);
  }

sub _handle_element_end
  {
  my ($self, $element_name) = @_;

#  print STDERR "end '$element_name'\n";

  my $storage = $self->{_mediawiki_pod_html};

  if ($element_name =~ /^head/)
    {
    $storage->{in_headline} = 0;
    }
  if ($element_name eq 'Document')
    {
    $self->_convert_graph() if $storage->{in_graph};
    }

  $self->SUPER::_handle_element_end($element_name);
  }

sub _handle_text {
  my ($self, $text) = @_;

#  print STDERR "text '$text'\n";

  my $storage = $self->{_mediawiki_pod_html};
  if ($storage->{in_headline})
    {
    $storage->{headlines}->[-1] .= $text;
    }
  if ($storage->{in_graph})
    {
    $storage->{cur_graph} .= $text;
    return;
    }
  if ($storage->{in_graph_common})
    {
    $storage->{graph_common} .= $text;
    return;
    }
  if ($storage->{in_x})
    {
    my $url = $storage->{search};
    my $t = $text;
    $t =~ s/&/&mp;/;
    $t =~ s/'/&squot;/;
    if ($url =~ /##KEYWORD##/)
      {
      $url =~ s/##KEYWORD##/$t/g;
      $url =~ s/ /_/g unless defined $storage->{search_space};
      }
    else
      {
      $url .= $t;
      $url =~ s/ /+/g unless defined $storage->{search_space};
      }
    # make spaces safe
    $url =~ s/ /$storage->{search_space}/g if defined $storage->{search_space};
    $self->_my_output( "<a class='keyword' href='$url'>$text</a>" );
    return;
    }

  $self->SUPER::_handle_text($text);
  }

sub get_headlines
  {
  my $self = shift;

  my $storage = $self->{_mediawiki_pod_html};
  $storage->{headlines};
  }

sub keyword_search_url
  {
  my $self = shift;

  my $storage = $self->{_mediawiki_pod_html};
  $storage->{search} = $_[0] if defined $_[0];
  # can be undef, too
  $storage->{search_space} = $_[1] if defined @_ == 2;
 
  wantarray ? 
    ($storage->{search}, $storage->{search_space}) : $storage->{search};
  }

sub _my_output
  {
  my $self = shift;

  print {$self->{'output_fh'}} $_[0];
  }

1;

__END__

=pod

=head1 NAME

Mediawiki::POD::HTML - a subclass to catch X keywords and =head lines

=head1 SYNOPSIS

	use Mediawiki::POD::HTML;
	
	my $parser = Mediawiki::POD::HTML->new();

	my $html = $parser->parse_string_document($POD);

=head1 DESCRIPTION

Turns a given POD (Plain Old Documentation) into HTML code.

This subclass of L<Pod::Simple::HTML> catches C<=head> directives,
and then allows you to assemble a TOC (table of contents) from
the captured headlines.

In addition, it supports C<graph-common> and C<graph> subsections, these
will be turned into HTML graphs.

=head1 GRAPH SUPPORT

Mediawiki::POD::HTML allows you to write graphs (nodes connected with edges)
in L<Graph::Easy> or L<http://www.graphviz.org|Graphviz> format and turns
these portions into HTML "graphics".

The following represents two graphs:

	=for graph [ Single ] --> [ Line ] --> [ Definition ]

	=begin graph

	node { fill: silver; }
	[ Mutli ] --> [ Line ]

	=end graph

In addition, a C<graph-common> section can be used to set a common text
for all following graphs. Each C<graph-common> section resets the common
text section:

	=for graph-common node { fill: red; }

	=for graph [ Red ]

	=for graph [ Red too ]

	=for graph-common node { fill: blue; }

	=for graph [ Blue ]

	=for graph [ Blue too ]

The attribute C<output> for graphs is not yet used, eventually it should
result in different output formats like SVG, or PNG rendered via dot.

=head1 METHODS

=head2 get_headlines()

Return all the captured headlines as an ARRAY ref.

=head2 keyword_search_url()

	# Set external search engine to search for "Foo+Bar"
	$parser->keyword_search_url('http://search.cpan.org/perldoc?');

	# Generate URLs like "Foo_Bar", perfect for relative wiki links:
	$parser->keyword_search_url('', '_');

Get/set the URL that is used to link keywords defined with C<< X&lt;&gt; >>
to a search engine. 

If the URL contains a text C<##KEYWORD##>, then this text will be replaced
with the actual keyword. Otherwise, the keyword is simple appended to the URL.

The default search URL is:

  	http://cpan.uwinnipeg.ca/search?query=##KEYWORD##

Optionally set the character that replaces a space in generated URLs.
The default space replacement character is undef, this means the
character is dependend on the search URL:

=over 2

=item * For URLS with ##KEYWORD##, it is '+'

=item * For URLS without a ##KEYWORD##, it is '_'

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL.

See the LICENSE file for information.

=head1 AUTHOR

(c) Copyright by Tels L<http://bloodgate.com/wiki> 2007

=head1 SEE ALSO

L<http://bloodgate.com/wiki/POD>, L<Graph::Easy>.

=cut
