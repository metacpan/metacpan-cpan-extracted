package Mediawiki::POD;

our $VERSION = '0.06';

use strict;
use Pod::Simple::HTML;
use Mediawiki::POD::HTML;

sub new
  {
  my $class = shift;

  my $self = bless {}, $class;

  # some defaults
  $self->{remove_newlines} = 1;
  $self->{body_only} = 1;

  $self;
  }

sub remove_newlines
  {
  my $self = shift;

  $self->{remove_newlines} = ( $_[0] ? 1 : 0 ) if @_ > 0;
  $self->{remove_newlines};
  }

sub body_only
  {
  my $self = shift;

  $self->{body_only} = ( $_[0] ? 1 : 0 ) if @_ > 0;
  $self->{body_only};
  }

sub as_html
  {
  my ($self, $input) = @_;

  my $parser = Mediawiki::POD::HTML->new();

  my ($html, $headlines);

  $parser->output_string( \$html );

  $parser->parse_string_document( $input );

  # remove form-feeds and tabs
  $html =~ s/[\f\t]+//g;

  # remove comments
  $html =~ s/<!--(.|\n)*?-->//g;

  if ($self->{body_only})
    {
    # remove the unwanted HTML sections
    $html =~ s/<head>(.|\n)*<\/head>//;

    $html =~ s/<\/?(html|body).*?>//g;
    }

  # clean up some crazy tags
  # converting "<code lang='und' xml:lang='und'>" to "<code>
  $html =~ s/<(pre|code|p)\s.*?>/<$1>/g;

  # insert a class for <a name="">
  $html =~ s/<a name="/<a class="u" name="/g;

  # make it readable again :)
  $html =~ s/\&#39;/'/g;
  $html =~ s/\&#34;/"/g;

  # remove empty paragraphs before a closing </div> (for instance for X keywords)
  $html =~ s/<p><\/p>\n<\/div>/<\/div>/g;

  # if the last item is a keyword, we need to add a closing </div>
  $html =~ s/<p><\/p>\s*\z/<\/div>/;

  # make '>"foo"</a>' to '>foo</a>'
  $html =~ s/class="podlinkpod"\s*>"(.*?)"<\/a>/class="podlinkpod">$1<\/a>/g;

  # convert newlines between <pre> tags to <br>
  # remove all new lines and tabs
  $html = $self->_parse_output($html) if $self->{remove_newlines};

  $html = $self->_generate_toc( $parser->get_headlines() ) . $html;

  # return the result
  $html;
  };

###########################################################################
# We need to remove all new lines, other Mediawiki will insert spurious
# linebreaks. However, inside <pre></pre> we need to replace them with
# <br> so that verbatim sections render properly. A nested regexp could
# solve this, but is not possible. So we implement a very basic parser
# that recognizes three things: <tag>, </tag>, anything else.

# This routine assumes that the <pre> tags are not nested.

sub _parse_output
  {
  my ($self, $input) = @_;

  my $in_pre = 0;

  my $qr_tag = qr/^(<\w+(.|\n)*?>)/;
  my $qr_end_tag = qr/^(<\/\w+>)/;
  my $qr_else = qr/^((?:.|\n)+?)(<|\z)/;

  my $last_len = 1;
  my $output = '';
  while (length($input) > 0)
    {
    $last_len = length($input);
    # math the start of the input, and remove the matching part
    if ($input =~ $qr_tag)
      {
      $input =~ s/$qr_tag//;
      my $tag = $1;
      $tag =~ s/[\n\r\t]/ /g;
      $output .= $tag;
      if ($tag =~ /^<pre.*?>/i)
        {
	$in_pre++;
	}
      }
    elsif ($input =~ $qr_end_tag)
      {
      $input =~ s/$qr_end_tag//;
      my $tag = $1;
      $tag =~ s/[\n\r\t]/ /g;
      $output .= $tag;
      if ($tag =~ /^<\/pre.*?>/i)
        {
	$in_pre--;
	}
      }
    else
      {
      $input =~ s/$qr_else/$2/;
      # remove newlines
      my $else = $1;
      if ($in_pre > 0)
        {
        # also remove excessive leading whitespace
        $else =~ s/[\n\r\t]\s*/<br> /g;
        $else =~ s/^\s*/ /;
        }
      else
        {
        $else =~ s/[\n\r\t]/ /g;
        }
      $output .= $else;
      }
    }  
  $output;
  }

sub _generate_toc
  {
  my ($self, $headlines) = @_;

  my $toc = '<table id="toc" class="toc" summary="Contents"><tr><td><div id="toctitle"><h2>Contents</h2></div>';
  $toc .= "\n<ul>\n";

  my $level = 1;
  my @cur_nr = ( 0 );
  for my $headline (@$headlines)
    {
    $headline =~ /^head([1-9]) (.*)/;

    my $cur_level = $1;
    my $txt = $2;
    my $link = $txt; $link =~ s/ /_/g; $link =~ s/"<>//g;
    #print STDERR "$headline $cur_level $level\n";

    # we enter a scope
    if ($cur_level > $level)
      {
      my $levels_up = $cur_level - $level;
      for (1..$levels_up)
	{
	push @cur_nr, 0;
	$toc .= '<ul>';
	}
      }
    elsif ($cur_level < $level)
      {
      my $levels_down = $level - $cur_level;
      for (1..$levels_down)
        {
        pop @cur_nr;
        $toc .= '</ul>';
        }
      }
    $cur_nr[-1]++;
    my $tnr = join ('.', @cur_nr);
    $toc .= "<li class='toclevel-$cur_level'><a href=\"#$link\"><span class='tocnumber'>$tnr</span> <span class='toctext'>$txt</span></a></li>\n";
    $level = $cur_level;
    }

  $toc .= "</ul></td></tr></table>\n";
  $toc .= '<script type="text/javascript">' . "\n" .
	  'if (window.showTocToggle) {var tocShowText="show";var tocHideText="hide";showTocToggle();}' .
	  "\n</script>\n";

  $toc =~ s/[\n\r\t]/ /g if $self->{remove_newlines};
  $toc;
  }

1;

__END__

=pod

=head1 NAME

Mediawiki::POD - convert POD to HTML suitable for a MediaWiki wiki

=head1 SYNOPSIS

	use Mediawiki::POD;
	
	my $converter = Mediawiki::POD->new();

	my $html = $converter->as_thml($POD);

=head1 DESCRIPTION

Turns a given POD (Plain Old Documentation) into HTML code.

This subclass of L<Pod::Simple::HTML> catches C<=head> directives,
and then allows you to assemble a TOC (table of contents) from
the captured headlines.

In addition, it supports C<graph-common> and C<graph> subsections, these
will be turned into HTML graphs.

=head1 GRAPH SUPPORT

C<Mediawiki::POD> allows you to write graphs (nodes connected with edges)
in L<Graph::Easy> or L<http://www.graphviz.org|Graphviz> format inside
the POD itself, and turns these portions into HTML "graphics".

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

=head1 VERSIONS

Please see the CHANGES file for a complete version history.

=head1 METHODS

=head2 new()

	my $converter = Mediawiki::POD->new();

Create a new converter object.

=head2 as_html()

	my $html = $converter->as_html( $pod_text);

Take the given POD text and return HTML suitable for embedding into
an Mediawiki page.

The returned HTML contains no newlines (as these would confuse the
Mdiawiki parser) and a table of contents.

=head2 remove_newlines()

	$self->remove_newlines(0);	# output contains \n

Set/get the flag that indicates that newlines should be removed from
the output. For Mediawiki integration, the output must be stripped
of newlines completely. Otherwise you might want to leave them in
to generated more readable HTML.

Default is true.

=head2 body_only()

	$self->body_only(0);		# output contains <head> etc.

Set/get the flag that indicates that only the body part should be
returned by L<as_html()>. The default means that the head section
as well as the body tags are removed from the output.

Default is true.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms of the GPL.

See the LICENSE file for information.

=head1 AUTHOR

(c) Copyright by Tels L<http://bloodgate.com/wiki> 2007

=head1 SEE ALSO

L<http://bloodgate.com/wiki/>.

=cut
