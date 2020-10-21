#############################################################################
# output the a Graph::Easy as SVG (Scalable Vector Graphics)
#
#############################################################################

package Graph::Easy::As_svg;
$Graph::Easy::As_svg::VERSION = '0.28';
use 5.010;


use strict;
use warnings;
use utf8;

sub _text_length
  {
  # Take a string, and return its length, based on the font-size and the
  # contents ("iii" is shorter than "WWW")
  my ($em, $text) = @_;

  # For each len entry, count how often it matches the string
  # if it matches 2 times "[Ww]", and 3 times "[i]" then we have
  # (X - (2+3)) * EM + 2*$W*EM + 3*$I*EM where X is length($text), and
  # $W and $I are sizes of "[Ww]" and "[i]", respectively.

  my $count = length($text);
  my $len = 0; my $match;

  $match = $text =~ tr/'`//;
  $len += $match * 0.25 * $em; $count -= $match;

  $match = $text =~ tr/Iijl!.,;:\|//;
  $len += $match * 0.33 * $em; $count -= $match;

  $match = $text =~ tr/"Jft\(\)\[\]\{\}//;
  $len += $match * 0.4 * $em; $count -= $match;

  $match = $text =~ tr/?//;
  $len += $match * 0.5 * $em; $count -= $match;

  $match = $text =~ tr/crs_//;
  $len += $match * 0.55 * $em; $count -= $match;

  $match = $text =~ tr/ELPaäevyz\\\/-//;
  $len += $match * 0.6 * $em; $count -= $match;

  $match = $text =~ tr/1BZFbdghknopqux~üö//;
  $len += $match * 0.65 * $em; $count -= $match;

  $match = $text =~ tr/KCVXY%023456789//;
  $len += $match * 0.7 * $em; $count -= $match;

  $match = $text =~ tr/§€//;
  $len += $match * 0.75 * $em; $count -= $match;

  $match = $text =~ tr/ÜÖÄßHGDSNQU$&//;
  $len += $match * 0.8 * $em; $count -= $match;

  $match = $text =~ tr/AwO=+<>//;
  $len += $match * 0.85 * $em; $count -= $match;

  $match = $text =~ tr/W//;
  $len += $match * 0.90 * $em; $count -= $match;

  $match = $text =~ tr/M//;
  $len += $match * 0.95 * $em; $count -= $match;

  $match = $text =~ tr/m//;
  $len += $match * 1.03 * $em; $count -= $match;

  $match = $text =~ tr/@//;
  $len += $match * 1.15 * $em; $count -= $match;

  $match = $text =~ tr/æ//;
  $len += $match * 1.25 * $em; $count -= $match;

  $len += $count * $em;					# anything else is 1.0

  # return length in "characters"
  $len / $em;
  }

sub _quote_name
  {
  my $name = shift;
  my $out_name = $name;

  # "--" is not allowed inside comments:
  $out_name =~ s/--/- - /g;

  # "&", "<" and ">" will not work in comments, so quote them
  $out_name =~ s/&/&amp;/g;
  $out_name =~ s/</&lt;/g;
  $out_name =~ s/>/&gt;/g;

  $out_name;
  }

sub _quote
  {
  my ($txt) = @_;

  # "&", ,'"', "<" and ">" will not work in hrefs or texts
  $txt =~ s/&/&amp;/g;
  $txt =~ s/</&lt;/g;
  $txt =~ s/>/&gt;/g;
  $txt =~ s/"/&quot;/g;

  # remove "\n"
  $txt =~ s/(^|[^\\])\\[lcnr]/$1 /g;

  $txt;
  }

sub _sprintf
  {
  my $form = '%0.2f';

  my @rc;
  for my $x (@_)
    {
    push @rc, undef and next unless defined $x;

    my $y = sprintf($form, $x);

    # convert "10.00" to "10"
    $y =~ s/\.0+\z//;
    # strip tailing zeros on "0.10", but not from "100"
    $y =~ s/(\.[0-9]+?)0+\z/$1/;

    push @rc, $y;
    }

  wantarray ? @rc : $rc[0];
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy;

use strict;

BEGIN
  {
  *_quote = \&Graph::Easy::As_svg::_quote;
  *_svg_attributes_as_txt = \&Graph::Easy::Node::_svg_attributes_as_txt;
  }

sub EM
  {
  # return the height of one line in pixels, taking the font-size into account
  my $self = shift;

  # default is 16 pixels (and 0.5 of that is a nice round number, like, oh, 8)
  $self->_font_size_in_pixels( 16 );
  }

sub LINE_HEIGHT
  {
  # return the height of one line in pixels, taking the font-size into account
  my $self = shift;

  # default is 20% bigger than EM (to make a bit more space on multi-line
  # labels for underlines etc)
  $self->_font_size_in_pixels( 16 ) * 18 / 16;
  }

my $devs = {
  'ah' =>
     " <!-- open arrow -->\n <g id="
   . '"ah" stroke-linecap="round" stroke-width="1">' . "\n"
   . '  <line x1="-8" y1="-4" x2="1" y2="0" />'. "\n"
   . '  <line x1="1" y1="0" x2="-8" y2="4" />'. "\n"
   . " </g>\n",

  'ahb' =>
     " <!-- open arrow for bold edges -->\n <g id="
   . '"ahb" stroke-linecap="round" stroke-width="1">' . "\n"
   . '  <line x1="-8" y1="-4" x2="1" y2="0" />'. "\n"
   . '  <line x1="1" y1="0" x2="-8" y2="4" />'. "\n"
   . '  <polygon points="1,0, -4,-2, -4,2" />'. "\n"
   . " </g>\n",

  'ahc' =>
     " <!-- closed arrow -->\n <g id="
   . '"ahc" stroke-linecap="round" stroke-width="1">' . "\n"
   . '  <polygon points="-8,-4, 1,0, -8,4"/>'. "\n"
   . " </g>\n",

  'ahf' =>
     " <!-- filled arrow -->\n <g id="
   . '"ahf" stroke-linecap="round" stroke-width="1">' . "\n"
   . '  <polygon points="-8,-4, 1,0, -8,4"/>'. "\n"
   . " </g>\n",

  # point-shapes
  'diamond' =>
     " <g id="
   . '"diamond">' . "\n"
   . '  <polygon points="0,-6, 6,0, 0,6, -6,0"/>'. "\n"
   . " </g>\n",
  'circle' =>
     " <g id="
   . '"circle">' . "\n"
   . '  <circle r="6" />'. "\n"
   . " </g>\n",
  'star' =>
     " <g id="
   . '"star">' . "\n"
   . '  <polygon points="0,-6, 1.5,-2, 6,-2, 2.5,1, 4,6, 0,3, -4,6, -2.5,1, -6,-2, -1.5,-2"/>'. "\n"
   . " </g>\n",
  'square' =>
     " <g id="
   . '"square">' . "\n"
   . '  <rect width="10" height="10" />'. "\n"
   . " </g>\n",
  'dot' =>
     " <g id="
   . '"dot">' . "\n"
   . '  <circle r="1" />'. "\n"
   . " </g>\n",
  'cross' =>
     " <g id="
   . '"cross">' . "\n"
   . '  <line x1="0" y1="-5" x2="0" y2="5" />'. "\n"
   . '  <line x1="-5" y1="0" x2="5" y2="0" />'. "\n"
   . " </g>\n",

  # point-shapes with double border
  'd-diamond' =>
     " <g id="
   . '"d-diamond">' . "\n"
   . '  <polygon points="0,-6, 6,0, 0,6, -6,0"/>'. "\n"
   . '  <polygon points="0,-3, 3,0, 0,3, -3,0"/>'. "\n"
   . " </g>\n",
  'd-circle' =>
     " <g id="
   . '"d-circle">' . "\n"
   . '  <circle r="6" />'. "\n"
   . '  <circle r="3" />'. "\n"
   . " </g>\n",
  'd-square' =>
     " <g id="
   . '"d-square">' . "\n"
   . '  <rect width="10" height="10" />'. "\n"
   . '  <rect width="6" height="6" transform="translate(2,2)" />'. "\n"
   . " </g>\n",
  'd-star' =>
     " <g id="
   . '"d-star">' . "\n"
   . '  <polygon points="0,-6, 1.5,-2, 6,-2, 2.5,1, 4,6, 0,3, -4,6, -2.5,1, -6,-2, -1.5,-2"/>'. "\n"
   . '  <polygon points="0,-4, 1,-1, 4,-1.5, 1.5,0.5, 2.5,3.5, 0,1, -2.5,3.5, -1.5,0.5, -4,-1.5, -1,-1"/>'. "\n"
   . " </g>\n",
  };

my $strokes = {
  'dashed' => '3, 1',
  'dotted' => '1, 1',
  'dot-dash' => '1, 1, 3, 1',
  'dot-dot-dash' => '1, 1, 1, 1, 3, 1',
  'double-dash' => '3, 1',
  'bold-dash' => '3, 1',
  };

sub _svg_use_def
  {
  # mark a certain def as used (to output it's definition later)
  my ($self, $def_name) = @_;

  $self->{_svg_defs}->{$def_name} = 1;
  }

sub text_styles_as_svg
  {
  my $self = shift;

  my $style = '';
  my $ts = $self->text_styles();

  $style .= ' font-style="italic"' if $ts->{italic};
  $style .= ' font-weight="bold"' if $ts->{bold};

  if ($ts->{underline} || $ts->{none} || $ts->{overline} || $ts->{'line-through'})
    {
    # XXX TODO: HTML does seem to allow only one of them
    my @s;
    foreach my $k (qw/underline overline line-through none/)
      {
      push @s, $k if $ts->{$k};
      }
    my $s = join(' ', @s);
    $style .= " text-decoration=\"$s\"" if $s;
    }

  my @styles;

  # XXX TODO: this will needless include the font-family if set via
  # "node { font: X }:
  my $ff = $self->attribute('font');
  push @styles, "font-family:$ff" if $ff;

  # XXX TODO: this will needless include the font-size if set via
  # "node { font-size: X }:

  my $fs = $self->_font_size_in_pixels( 16 ); $fs = '' if $fs eq '16';

  # XXX TODO:
  # the 'style="font-size:XXpx"' is nec. for Batik 1.5 (Firefox and Opera also
  # handle 'font-size="XXpx"'):
  push @styles, "font-size:${fs}px" if $fs;

  $style .= ' style="' . (join(";", @styles)) . '"' if @styles > 0;

  $style;
  }

my $al_map = {
  'c' => 'middle',
  'l' => 'start',
  'r' => 'end',
  };

sub _svg_text
  {
  # create a text via <text> at pos x,y, indented by "$indent"
  my ($self, $color, $indent, $x, $y, $style, $xl, $xr) = @_;

  my $align = $self->attribute('align');

  my $text_wrap = $self->attribute('textwrap');
  my ($lines, $aligns) = $self->_aligned_label($align, $text_wrap);

  # We can't just join them togeter with 'x=".." dy="1em"' because Firefox 1.5
  # doesn't support this (Batik does, tho). So calculate x and y on each tspan:

  #print STDERR "# xl $xl xr $xr\n";

  my $label = '';
  if (@$lines > 1)
    {
    my $lh = $self->LINE_HEIGHT(); my $em = $self->EM();
    my $in = $indent . $indent;
    my $dy = $y - $lh + $em;
    $label = "\n$in<tspan x=\"$x\" y=\"$dy\">"; $dy += $lh;
    my $i = 0;
    for my $line (@$lines)
      {
      # quote "<" and ">", "&" and also '"'
      $line = _quote($line);
      my $all = $aligns->[$i+1] || substr($align,0,1);
      my $al = ' text-anchor="' . $al_map->{$all} . '"';
      #print STDERR "$line $al $all $align\n";
      $al = '' if $all eq substr($align,0,1);
      my $xc = $x;
      $xc = $xl if ($all eq 'l');
      $xc = $xr if ($all eq 'r');
      my $join = "</tspan>"; $join .= "\n$in<tspan x=\"$xc\" y=\"$dy\"$al>" if $i < @$lines - 1;
      $dy += $lh;
      $label .= $line . $join;
      $i++;
      }
    $label .= "\n ";
    }
  else
    {
    $label = _quote($lines->[0]) if @$lines;
    }

  my $fs; $fs = $self->text_styles_as_svg() if $label ne '';
  $fs = '' unless defined $fs;

  # For an edge, the default stroke is black, but this will render a black
  # outline around colored text. So disable the stroke with "none".
  my $stroke = ''; $stroke = ' stroke="none"' if ref($self) =~ /Edge/;

  if (!defined $style)
    {
    $x = $xl if $align eq 'left';
    $x = $xr if $align eq 'right';
    $style = '';
    my $def_align = $self->default_attribute('align');
    $style = ' text-anchor="' . $al_map->{substr($align,0,1)} . '"';
    }
  my $svg = "$indent<text x=\"$x\" y=\"$y\"$fs fill=\"$color\"$stroke$style>$label</text>\n";

  $svg . "\n"
  }

sub _remap_align
  {
  my ($self, $att, $val) = @_;

  # align: center; => text-anchor: middle; => supress as it is the default?
  # return (undef,undef)if $val eq 'center';

  $val = 'middle' if $val eq 'center';

  # align: center; => text-anchor: middle;
  ('text-anchor', $val);
  }

sub _remap_font_size

  {
  my ($self, $att, $val) = @_;

  # "16" to "16px"
  $val .= 'px' if $val =~ /^\d+\z/;

  if ($val =~ /em\z/)
    {
    $val = $self->_font_size_in_pixels( 16, $val ) . 'px';
    }

  ('font-size', $val);
  }

sub _adjust_dasharray
  {
  # If the border is bigger than 1px, we need to adjust the dasharray to
  # match it.
  my ($self,$att) = @_;

  # convert "20px" to "20"
  # convert "2em" to "xx"
  my $s = $att->{'stroke-width'} || 1;

  $s =~ s/px//;

  if ($s =~ /(\d+)em/)
    {
    my $em = $self->EM();
    $s = $1 * $em;
    }
  $att->{'stroke-width'} = $s;

  delete $att->{'stroke-width'} if $s eq '1';

  return $att unless exists $att->{'stroke-dasharray'};

  # for very thin line, make it a bit bigger as to be actually visible
  $s = 2 if $s < 2;

  my @dashes = split /\s*,\s*/, $att->{'stroke-dasharray'};
  for my $d (@dashes)
    {
    $d *= $s;	# modify in place
    }
  $att->{'stroke-dasharray'} = join (',', @dashes);
  $att;
  }

sub _as_svg
  {
  # convert the graph to SVG
  my ($self, $options) = @_;

  # set the info fields to defaults
  $self->{svg_info} = { width => 0, height => 0 };

  $self->layout() unless defined $self->{score};

  my ($rows,$cols,$max_x,$max_y) = $self->_prepare_layout('svg');
  my $cells = $self->{cells};
  my $txt;

  if ($options->{standalone})
    {
    $txt .= <<EOSVG
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

EOSVG
;
    }

  my $em = $self->EM();
  my $LINE_HEIGHT = $self->LINE_HEIGHT();

  # XXX TODO: that should use the padding/margin attribute from the graph
  my $xl = int($em / 2); my $yl = int($em / 2);
  my $xr = int($em / 2); my $yr = int($em / 2);

  my $mx = $max_x + $xl + $xr;
  my $my = $max_y + $yl + $yr;

  # we need both xmlns= and xmlns:xlink to make Firefix 1.5 happy :-(
  $txt .=
#     '<svg viewBox="0 0 ##MX## ##MY##" width="##MX##" height="##MY##" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
     '<svg width="##MX##" height="##MY##" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
    ."\n<!-- Generated at " . scalar localtime() . " by:\n  " .
     "Graph::Easy v$Graph::Easy::VERSION\n  Graph::Easy::As_svg v$Graph::Easy::As_svg::VERSION\n-->\n\n";

  my $title = _quote($self->title());

  $txt .= "<title>$title</title>\n" if $title ne '';

  $txt .= "<defs>\n##devs##";

  # clear used definitions
  $self->{_svg_defs} = {};

  # which attributes must be output as what name:
  my $mutator = {
    background => 'fill',
    'align' => \&_remap_align,
    'color' => 'stroke',
    'fontsize' => \&_remap_font_size,
    'font' => 'font-family',
    };
  my $skip = qr/^(
   arrow(style|shape)|
   (auto)?(link|title|label)|
   bordercolor|
   borderstyle|
   borderwidth|
   border|
   color|
   colorscheme|
   comment|
   columns|
   flow|
   format|
   gid|
   labelpos|
   labelcolor|
   linkbase|
   line-height|
   letter-spacing|
   margin.*|
   nodeclass|
   padding.*|
   rows|
   root|
   size|
   style|
   shape|
   title|
   type|
   textstyle|
   width|
   rotate|
   )\z/x;

  my $overlay = {
    edge => {
      "stroke" => 'black',
      "text-align" => 'center',
      "font-size" => '13px',
    },
    node => {
      "font-size" => '16px',
      "text-align" => 'center',
    },
  };
  $overlay->{graph} =
    {
    "font-size" => '16px',
    "text-align" => 'center',
    "border" => '1px dashed #808080',
    };
  # generate the class attributes first
  my $style = $self->_class_styles( $skip, $mutator, '', ' ', $overlay);

  $txt .=
    "\n <!-- class definitions -->\n"
   ." <style type=\"text/css\"><![CDATA[\n$style ]]></style>\n"
    if $style ne '';

  $txt .="</defs>\n\n";

  ###########################################################################
  # prepare graph label output

  my $lp = 'top';
  my ($lw,$lh) = Graph::Easy::Node::_svg_dimensions($self);
  # some padding on the label
  $lw = int($em*$lw + $em + 0.5); $lh = int($LINE_HEIGHT*$lh+0.5);

  my $label = $self->label();
  if ($label ne '')
    {
    $lp = $self->attribute('labelpos');

    # handle the case where the graph label is bigger than the graph itself
    if ($mx < ($lw+$em))
      {
      # move the content to the right to center it
      $xl += (($lw+$em) - $mx) / 2;
      # and then make the graph more wide
      $mx = $em + $lw;
      }

    $my += $lh;
    }

  ###########################################################################
  # output the graph's background and border

  my $em2 = $em / 2;

  {
    # 'inherit' only works for HTML, not for SVG
    my $bg = $self->color_attribute('fill'); $bg = 'white' if $bg eq 'inherit';
    my $bs = $self->attribute('borderstyle');
    my $cl = $self->color_attribute('bordercolor'); $cl = $bg if $bs eq 'none';
    my $bw = $self->attribute('borderwidth') || 1;

    $bw =~ s/px//;

    # We always need to output a background rectangle, otherwise printing the
    # SVG from Firefox ends you up with a black background, which rather ruins
    # the day:

    # XXX TODO adjust dasharray
    my $att = {
      'stroke-dasharray' => $strokes->{$bs} || '',
      'stroke-width' => $bw,
      'stroke' => $cl,
      'fill' => $bg,
      };
    # avoid stroke-dasharray="":
    delete $att->{'stroke-dasharray'} unless $att->{'stroke-dasharray'} ne '';

    my $d = $self->_svg_attributes_as_txt($self->_adjust_dasharray($att));

    my $xr = $mx + $em2;
    my $yr = $my + $em2;

    if ($bs ne '')
      {
      # Provide some padding around the graph to avoid that the border sticks
      # very close to the edge
      $xl += $em2 + $bw;
      $yl += $em2 + $bw;

      $xr += $em2 + 2 * $bw;
      $yr += $em2 + 2 * $bw;

      $mx += $em + 4 * $bw;
      $my += $em + 4 * $bw;
      }

    my $bw_2 = $bw / 2;
    $txt .= '<!-- graph background with border (mainly for printing) -->' .
        "\n<rect x=\"$bw_2\" y=\"$bw_2\" width=\"$xr\" height=\"$yr\"$d />\n\n";

    } # end outpuf of background

  ###########################################################################
  # adjust space for the graph label and output the label

  if ($label ne '')
    {
    my $y = $yl + $em2; $y = $my - $lh + $em2 if $lp eq 'bottom';

    # also include a link on the label if nec.
    my $link = _quote($self->link());

    my $l = Graph::Easy::Node::_svg_text($self,
		$self->color_attribute('color') || 'black', '  ',
		$mx / 2, $y, undef, $em2, $mx - $em2);

    $l =~ s/<text /<text class="graph" /;
    $l = "  <!-- graph label -->\n" . $l;

    $l = Graph::Easy::Node::_link($self, $l, '', $title, $link) if $link ne '';

    $txt .= $l;

    # push content down if label is at top
    $yl += $lh if $lp eq 'top';
    }

  # Now output cells that belong to one edge/node together.
  # But do the groups first, because edges/nodes are drawn on top of them.
  for my $n ($self->groups(), $self->edges(), $self->sorted_nodes())
    {
    my $x = $xl; my $y = $yl;
    if ((ref($n) eq 'Graph::Easy::Node')
       || (ref($n) eq 'Graph::Easy::Node::Anon'))
      {
      # get position from cell
      $x += $cols->{ $n->{x} };
      $y += $rows->{ $n->{y} };
      }

    my $class = $n->class(); $class =~ s/\./_/;	# node.city => node-city
    my $obj_txt = $n->as_svg($x,$y,' ', $rows, $cols);
    if ($obj_txt ne '')
      {
      $obj_txt =~ s/\n\z/<\/g>\n\n/;
      my $id = $n->attribute('id');
      $id = $n->{id} if $id eq '';
      $id =~ s/([\"\\])/\\$1/g;
      $txt .= "<g id=\"$id\" class=\"$class\">\n" . $obj_txt;
      }
    }

  # include the used definitions into <devs>
  my $d = '';
  for my $key (keys %{$self->{_svg_defs}})
    {
    $d .= $devs->{$key};
    }
  $txt =~ s/##devs##/$d/;

  $txt =~ s/##MX##/$mx/;
  $txt =~ s/##MY##/$my/;

  $txt .= "</svg>";			# finish

  $txt .= "\n" if $options->{standalone};

  # set the info fields:
  $self->{svg_info}->{width} = $mx;
  $self->{svg_info}->{height} = $my;

  $txt;
  }


#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Node::Cell;

sub as_svg
  {
  '';
  }

sub _correct_size_svg
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;
  $self;
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Group::Cell;

sub as_svg
  {
  my ($self,$x, $y, $indent) = @_;

  my $svg = $self->_svg_background($x,$y,$indent);

  $svg .= $self->SUPER::as_svg($x,$y,$indent) if $self->{has_label};

  $svg;
  }

my $coords = {
  'gl' => 'x1="XX0" y1="YY0" x2="XX0" y2="YY1"',
  'gt' => 'x1="XX0" y1="YY0" x2="XX1" y2="YY0"',
  'gb' => 'x1="XX0" y1="YY1" x2="XX1" y2="YY1"',
  'gr' => 'x1="XX1" y1="YY0" x2="XX1" y2="YY1"',
  };

sub _svg_background
  {
  # draw the background for this node/cell, if nec.
  my ($self, $x, $y, $indent) = @_;

  my $bg = $self->background();

  $bg = $self->{group}->default_attribute('fill') if $bg eq '';

  my $svg = '';
  if ($bg ne '')
    {
    $bg = $self->{group}->color_attribute('fill') if $bg eq 'inherit';
    $bg = '' if $bg eq 'inherit';
    if ($bg ne '')
      {
      my $w = $self->{w};
      my $h = $self->{h};
      $svg .= "$indent<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" fill=\"$bg\"/>\n";
      }
    }

  # draw the border pieces
  my $x2 = $x + $self->{w} - 0.5;
  my $y2 = $y + $self->{h} - 0.5;

  my $style = $self->attribute('border-style')||'dashed';
  my $att = {
    'stroke'  => $self->color_attribute('bordercolor'),
    'stroke-dasharray' => $strokes->{$style}||'3, 1',
    'stroke-width' => $self->attribute('borderwidth') || 1,
    };
  $self->_adjust_dasharray($att);

  my $stroke = $self->_svg_attributes_as_txt($att, 0, 0);  # x,y are not used

  my $c = $self->{cell_class}; $c =~ s/^\s+//; $c =~ s/\s+\z//;

  $x += 0.5;
  $y += 0.5;
  for my $class (split /\s+/, $c)
    {
    last if $class =~ /^(\s+|gi)\z/;		# inner => no border, skip empty

    my $l = "$indent<line " . $coords->{$class} . " $stroke/>\n";

    $l =~ s/XX0/$x/g;
    $l =~ s/XX1/$x2/g;
    $l =~ s/YY0/$y/g;
    $l =~ s/YY1/$y2/g;

    $svg .= $l;
    }
  $svg .= "\n";

  $svg;
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Group;

sub as_svg
  {
  # output all cells of the group as svg
  my ($self, $xl, $yl, $indent, $rows, $cols) = @_;

  my $txt = '';
  for my $cell (values %{$self->{_cells}})
    {
    # get position from cell
    my $x = $cols->{ $cell->{x} } + $xl;
    my $y = $rows->{ $cell->{y} } + $yl;
    $txt .= $cell->as_svg($x,$y,$indent);
    }
  $txt;
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Edge;

use Graph::Easy::Edge::Cell qw/EDGE_HOLE/;

sub as_svg
  {
  # output all cells of the edge as svg
  my ($self, $xl, $yl, $indent, $rows, $cols) = @_;

  my $cells = $self->{cells};

  my $from = Graph::Easy::As_svg::_quote_name($self->{from}->{name});
  my $to = Graph::Easy::As_svg::_quote_name($self->{to}->{name});
  my $txt = " <!-- from $from to $to -->\n";
  my $done_cells = 0;
  for my $cell (@$cells)
    {
    next if $cell->{type} == EDGE_HOLE;
    $done_cells++;
    # get position from cell
    my $x = $cols->{ $cell->{x} } + $xl;
    my $y = $rows->{ $cell->{y} } + $yl;
    $txt .= $cell->as_svg($x,$y,$indent);
    }

  # had no cells or only one "HOLE"
  return '' if $done_cells == 0;

  $txt;
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Node::Empty;

sub as_svg
  {
  # empty nodes are not rendered at all
  '';
  }

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Node;

BEGIN
  {
  *_sprintf = \&Graph::Easy::As_svg::_sprintf;
  *_quote = \&Graph::Easy::As_svg::_quote;
  *LINE_HEIGHT = \&Graph::Easy::LINE_HEIGHT;
  }

sub _svg_dimensions
  {
  # Returns the dimensions of the node/cell derived from the label (or name) in characters.
  my ($self) = @_;

#  my $align = $self->attribute('align') || $self->default_attribute('align') || 'center';
#  my $text_wrap = $self->attribute('text-wrap') || 'none';
  my $align = $self->attribute('align');
  my $text_wrap = $self->attribute('textwrap');
  my ($lines, $aligns) = $self->_aligned_label($align, $text_wrap);

  my $w = 0; my $h = scalar @$lines;
  my $em = $self->EM();
  foreach my $line (@$lines)
    {
    $line =~ s/^\s+//; $line =~ s/\s+$//;               # rem spaces
    my $line_length = Graph::Easy::As_svg::_text_length($em, $line);
    $w = $line_length if $line_length > $w;
    }
  ($w,$h);
  }

sub _svg_background
  {
  # draw the background for this node/cell, if nec.
  my ($self, $x, $y, $indent) = @_;

  my $bg = $self->background();

  my $s = '';
  if (ref $self->{edge})
    {
    $bg = $self->{edge}->{group}->default_attribute('fill')||'#a0d0ff'
      if $bg eq '' && ref $self->{edge}->{group};
    $s = ' stroke="none"';
    }

  my $svg = '';
  if ($bg ne 'inherit' && $bg ne '')
    {
    my $w = $self->{w};
    my $h = $self->{h};
    $svg .= "$indent<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" fill=\"$bg\"$s />\n";
    }
  $svg;
  }

BEGIN
  {
  *EM = \&Graph::Easy::EM;
  *text_styles_as_svg = \&Graph::Easy::text_styles_as_svg;
  *_svg_text = \&Graph::Easy::_svg_text;
  *_adjust_dasharray = \&Graph::Easy::_adjust_dasharray;
  }

sub as_svg
  {
  # output a node as SVG
  my ($self,$x,$y,$indent) = @_;

  my $name = $self->{att}->{label};
  $name = $self->{name} if !defined $name;
  $name = 'anon node ' . $self->{name} if $self->{class} eq 'node.anon';

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes($x,$y);

  # the output shape as svg-tag
  my $shape = $att->{shape};				# rect, circle etc
  delete $att->{shape};

  return '' if $shape eq 'invisible';

  # set a potential title
  my $title = _quote($self->title());
  $att->{title} = $title if $title ne '';

  # the original shape
  my $s = ''; $s = $self->attribute('shape') unless $self->isa_cell();

  my $link = _quote($self->link());
  my $old_indent = $indent; $indent = $indent x 2 if $link ne '';

  my $out_name = Graph::Easy::As_svg::_quote_name($name);
  my $svg = "$indent<!-- $out_name, $s -->\n";

  # render the background, except for "rect" where it is not visible
  # (use the original shape in $s, or "rounded" will be wrong)
  $svg .= $self->_svg_background($x,$y, $indent) if $s ne 'rect';

  my $bs = $self->attribute('borderstyle');

  my $xt = int($x + $self->{w} / 2);
  my $yt = int($y + $self->{h} / 2);

  # render the node shape itself
  if ($shape eq 'point')
    {
    # include the point-shape
    my $s = $self->attribute('pointshape');

    if ($s ne 'invisible')
      {
      $s = 'd-' . $s if $bs =~ /^double/ && $s =~ /^(square|diamond|circle|star)\z/;

      my $ps = $self->attribute('pointstyle');

      # circle => filledcircle
      #$s = 'f-' . $s if $ps eq 'filled' && $s =~ /^(square|diamond|circle|star)\z/;

      my $a = { };
      for my $key (keys %$att)
        {
        $a->{$key} = $att->{$key};
        }
      $a->{stroke} = $self->color_attribute('bordercolor');
      if ($s eq 'dot' || $ps eq 'filled')
	{
        $a->{fill} = $a->{stroke};
        }

      my $att_txt = $self->_svg_attributes_as_txt($a, $xt, $yt);

      # center a square point-node
      $yt -= 5 if $s =~ 'square';
      $xt -= 5 if $s =~ 'square';

      $self->{graph}->_svg_use_def($s);

      $svg .= "$indent<use$att_txt xlink:href=\"#$s\" x=\"$xt\" y=\"$yt\"/>\n\n";
      }
    else { $svg .= "\n"; }
    }
  elsif ($shape eq 'img')
    {
    require Image::Info;

    my $label = $self->label();
    my $info = Image::Info::image_info($label);
    my $w = $info->{width};
    my $h = $info->{height};
    if ($info->{error})
      {
      $self->_croak("Couldn't determine image dimensions from '$label': $info->{error}");
      }
    # center the image
    my $x1 = $xt - $w / 2;
    my $y1 = $yt - $h / 2;

    $label = _quote($label);
    $svg .= "<image x=\"$x1\" y=\"$y1\" xlink:href=\"$label\" width=\"$w\" height=\"$h\" />\n";
    }
  else
    {
    # no border/shape for Group cells (we need to draw the border in pieces)
    if ($shape ne 'none' && !$self->isa('Graph::Easy::Group::Cell'))
      {
      # If we need to draw the border shape twice, put common attributes on
      # a <g> around it. (In the case there is only "stroke: #000000;" it will
      # waste 4 bytes, but in all other cases save quite a few.

      my $group = {};
      if ($bs =~ /^double/)
        {
        for my $a (qw/fill stroke stroke-dasharray/)
          {
          $group->{$a} = $att->{$a} if exists $att->{$a}; delete $att->{$a};
          }
        }

      my $att_txt = $self->_svg_attributes_as_txt($att, $xt, $yt);

      my $shape_svg = "$indent<$shape$att_txt />\n";

      # if border-style is double, do it again, sam.
      if ($bs =~ /^double/)
        {
        my $group_txt = $self->_svg_attributes_as_txt($group, $xt, $yt);

        $shape_svg = "$indent<g$group_txt>\n$indent" . $shape_svg;

        my $att = $self->_svg_attributes($x,$y, 3);
        for my $a (qw/fill stroke stroke-dasharray/)
          {
          delete $att->{$a};
          }

        my $shape = $att->{shape};				# circle etc
        delete $att->{shape};

        my $att_txt = $self->_svg_attributes_as_txt( $att, $xt, $yt );

        $shape_svg .= "$indent$indent<$shape$att_txt />\n";

        $shape_svg .= "$indent</g>\n";				# close group
        }
      $svg .= $shape_svg;
      }

    ###########################################################################
    # include the label/name/text

    my ($w,$h) = $self->_svg_dimensions();
    my $lh = $self->LINE_HEIGHT();

    my $yt = int($y + $self->{h} / 2 + $lh / 3 - ($h -1) * $lh / 2);

    $yt += $self->{h} * 0.25 if $s =~ /^(triangle|trapezium)\z/;
    $yt -= $self->{h} * 0.25 if $s =~ /^inv(triangle|trapezium)\z/;
    $yt += $self->{h} * 0.10 if $s eq 'house';
    $yt -= $self->{h} * 0.10 if $s eq 'invhouse';

    my $color = $self->color_attribute('color') || 'black';

    $svg .= $self->_svg_text($color, $indent, $xt, $yt,
		       # left    # right
		undef, int($x + $em/2), int($x + $self->{w} - $em/2));
    }

  # Create the link
  $svg = $self->_link($svg, $old_indent, $title, $link) if $link ne '';

  $svg;
  }

sub _link
  {
  # put a link around a shape (including onclick handler to work around bugs)
  my ($self, $svg, $indent, $title, $link) = @_;

  # although the title is already included on the outer shape, we need to
  # add it to the link, too (for shape: none, and some user agents like
  # FF 1.5 display the title only while outside the text-area)
  $title = ' xlink:title="' . $title . '"' if $title ne '';

  $svg =~ s/\n\z//;
  $svg =
         $indent . "<a xlink:target=\"_top\" xlink:href=\"$link\"$title>\n" . $svg .
         $indent . "</a>\n\n";

  $svg;
  }

sub _svg_attributes
  {
  # Return a hash with attributes for the node, like "x => 1, y => 1, w => 1, h => 1"
  # Especially usefull for shapes other than boxes.
  my ($self,$x,$y, $sub) = @_;

  # subtract factor, 0 or 2 for border-style: double
  $sub ||= 0;

  my $att = {};

  my $shape = $self->shape();

  my $em = $self->EM();
  my $border_width = Graph::Easy::_border_width_in_pixels($self,$em);

  # subtract half of our border-width because the border-center would otherwise
  # be on the node's border-line and thus extending outward:
  my $bw2 = $border_width / 2; $sub += $bw2;

  my $w2 = $self->{w} / 2;
  my $h2 = $self->{h} / 2;

  # center
  my $cx = $x + $self->{w} / 2;
  my $cy = $y + $self->{h} / 2;

  my $double = 0; $double = 1 if ($self->attribute('border-style') || '') eq 'double';

  my $x2 = $x + $self->{w} - $sub;
  my $y2 = $y + $self->{h} - $sub;

  $x += $sub; $y += $sub;

  my $sub3 = $sub / 3;		# 0.333 * $sub
  my $sub6 = 2 * $sub / 3;	# 0.666 * $sub

  if ($shape =~ /^(point|none)\z/)
    {
    }
  elsif ($shape eq 'circle')
    {
    $att->{cx} = $cx;
    $att->{cy} = $cy;
    $att->{r} = $self->{minw} > $self->{minh} ? $self->{minw} : $self->{minh};
    $att->{r} /= 2;
    $att->{r} -= $sub;
    }
  elsif ($shape eq 'parallelogram')
    {
    my $xll = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xrl = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl = _sprintf($x + $sub6);
    my $xr = _sprintf($x2 - $sub6);

    $shape = "polygon points=\"$xll,$y, $xr,$y, $xrl,$y2, $xl,$y2\"";
    }
  elsif ($shape eq 'trapezium')
    {
    my $xl = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xr = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl1 = _sprintf($x + $sub3);
    my $xr1 = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y, $xr,$y, $xr1,$y2, $xl1,$y2\"";
    }
  elsif ($shape eq 'invtrapezium')
    {
    my $xl = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $xr = _sprintf($x2 + $sub3 - $self->{w} * 0.25);

    my $xl1 = _sprintf($x + $sub3);
    my $xr1 = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl1,$y, $xr1,$y, $xr,$y2, $xl,$y2\"";
    }
  elsif ($shape eq 'diamond')
    {
    my $x1 = $cx;
    my $y1 = $cy;

    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y1, $x1,$y, $xr,$y1, $x1,$y2\"";
    }
  elsif ($shape eq 'house')
    {
    my $x1 = $cx;
    my $y1 = _sprintf($y - $sub3 + $self->{h} * 0.333);

    $shape = "polygon points=\"$x1,$y, $x2,$y1, $x2,$y2, $x,$y2, $x,$y1\"";
    }
  elsif ($shape eq 'pentagon')
    {
    my $x1 = $cx;
    my $x11 = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub3 - $self->{w} * 0.25);
    my $y1 = _sprintf($y - $sub6 + $self->{h} * 0.333);

    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$x1,$y, $xr,$y1, $x12,$y2, $x11,$y2, $xl,$y1\"";
    }
  elsif ($shape eq 'invhouse')
    {
    my $x1 = $cx;
    my $y1 = _sprintf($y - (1.4 * $sub) + $self->{h} * 0.666);

    $shape = "polygon points=\"$x,$y, $x2,$y, $x2,$y1, $x1,$y2, $x,$y1\"";
    }
  elsif ($shape eq 'septagon')
    {
    my $x15 = $cx;

    my $x11 = _sprintf($x2 + $sub3 - $self->{w} * 0.10);
    my $x14 = _sprintf($x - $sub3 + $self->{w} * 0.10);

    my $y11 = _sprintf($y - $sub3 + $self->{h} * 0.15);
    my $y13 = _sprintf($y2 + 0.85 * $sub - $self->{h} * 0.40);

    my $x12 = _sprintf($x2 + $sub6 - $self->{w} * 0.25);
    my $x13 = _sprintf($x - $sub6 + $self->{w} * 0.25);

    my $xl = _sprintf($x - 0.15 * $sub);
    my $xr = _sprintf($x2 + 0.15 * $sub);

    $shape = "polygon points=\"$x15,$y, $x11,$y11, $xr,$y13, $x12,$y2, $x13,$y2, $xl,$y13, $x14, $y11\"";
    }
  elsif ($shape eq 'octagon')
    {
    my $x11 = _sprintf($x - $sub3 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub3 - $self->{w} * 0.25);
    my $y11 = _sprintf($y - $sub6 + $self->{h} * 0.25);
    my $y12 = _sprintf($y2 + $sub6 - $self->{h} * 0.25);

    my $xl = _sprintf($x + $sub * 0.133);
    my $xr = _sprintf($x2 - $sub * 0.133);

    $shape = "polygon points=\"$xl,$y11, $x11,$y, $x12,$y, $xr,$y11, $xr,$y12, $x12,$y2, $x11,$y2, $xl,$y12\"";
    }
  elsif ($shape eq 'hexagon')
    {
    my $y1 = $cy;
    my $x11 = _sprintf($x - $sub6 + $self->{w} * 0.25);
    my $x12 = _sprintf($x2 + $sub6 - $self->{w} * 0.25);

    my $xl = _sprintf($x + $sub3);
    my $xr = _sprintf($x2 - $sub3);

    $shape = "polygon points=\"$xl,$y1, $x11,$y, $x12,$y, $xr,$y1, $x12,$y2, $x11,$y2\"";
    }
  elsif ($shape eq 'triangle')
    {
    my $x1 = $cx;

    my $xl = _sprintf($x + $sub);
    my $xr = _sprintf($x2 - $sub);

    my $yd = _sprintf($y2 + ($sub * 0.2 ));

    $shape = "polygon points=\"$x1,$y, $xr,$yd, $xl,$yd\"";
    }
  elsif ($shape eq 'invtriangle')
    {
    my $x1 = $cx;

    my $xl = _sprintf($x + $sub);
    my $xr = _sprintf($x2 - $sub);

    my $yd = _sprintf($y - ($sub * 0.2));

    $shape = "polygon points=\"$xl,$yd, $xr,$yd, $x1,$y2\"";
    }
  elsif ($shape eq 'ellipse')
    {
    $att->{cx} = $cx;
    $att->{cy} = $cy;
    $att->{rx} = $w2 - $sub;
    $att->{ry} = $h2 - $sub;
    }
  else
    {
    if ($shape eq 'rounded')
      {
      # round corners by a fixed value
      $att->{ry} = '15';
      $att->{rx} = '15';
      $shape = 'rect';
      }
    $att->{x} = $x;
    $att->{y} = $y;
    $att->{width} = _sprintf($self->{w} - $sub * 2);
    $att->{height} = _sprintf($self->{h} - $sub * 2);
    }
  $att->{shape} = $shape;

  my $border_style = $self->attribute('border-style') || 'solid';
  my $border_color = $self->color_attribute('border-color') || 'black';

  $att->{'stroke-width'} = $border_width if $border_width ne '1';
  $att->{stroke} = $border_color;

  if ($border_style !~ /^(none|solid)/)
    {
    $att->{'stroke-dasharray'} = $strokes->{$border_style}
     if exists $strokes->{$border_style};
    $self->_adjust_dasharray($att);
    }

  if ($border_style eq 'none')
    {
    delete $att->{'stroke-width'};
    delete $att->{stroke};
    }

  $att->{fill} = $self->color_attribute('fill') || 'white';
  # include the fill for renderers that can't cope with CSS styles
  # delete $att->{fill} if $att->{fill} eq 'white';	# white is default

  $att->{rotate} = $self->angle();
  $att;
  }

sub _svg_attributes_as_txt
  {
  # convert hash with attributes to text to be included in SVG tag
  my ($self, $att, $x, $y) = @_;

  my $att_line = '';				# attributes as text (cur line)
  my $att_txt = '';				# attributes as text (all)
  foreach my $e (sort keys %$att)
    {
    # skip these
    next if $e =~
	/^(arrow-?style|arrow-?shape|text-?style|label-?color|
	  rows|columns|size|offset|origin|rotate|colorscheme)\z/x;

    $att_line .= " $e=\"$att->{$e}\"";
    if (length($att_line) > 75)
      {
      $att_txt .= "$att_line\n  "; $att_line = '';
      }
    }

  ###########################################################################
  # include the rotation

  my $r = $att->{rotate} || 0;

  $att_line .= " transform=\"rotate($r, $x, $y)\"" if $r != 0;
  if (length($att_line) > 75)
    {
    $att_txt .= "$att_line\n  "; $att_line = '';
    }

  $att_txt .= $att_line;
  $att_txt =~ s/\n  \z//;		# avoid a "  >" on last line
  $att_txt;
  }

sub _correct_size_svg
  {
  # Correct {w} and {h} for the node after parsing.
  my $self = shift;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  return if defined $self->{w};

  my $shape = $self->shape();
  if ($shape eq 'point')
    {
    $self->{w} = $em * 3;
    $self->{h} = $em * 3;
    return;
    }

  my ($w,$h) = $self->_svg_dimensions();

  my $lh = $self->LINE_HEIGHT();
  # XXX TODO: that should use a changable padding factor (like "0.2 em" or "4")
  $self->{w} = int($w * $em + $em);
  $self->{h} = int($h * $lh + $em);

  my $border = 'none';
  $border = $self->attribute('borderstyle') || '' if $shape ne 'none';

  if ($border ne 'none')
    {
    my $bw = Graph::Easy::_border_width_in_pixels($self,$em);
    $self->{w} += $bw * 2;	# *2 due to left/right and top/bottom
    $self->{h} += $bw * 2;
    }

  # for triangle or invtriangle:
  $self->{w} *= 1.4 if $shape =~ /triangle/;
  $self->{h} *= 1.8 if $shape =~ /triangle|trapezium/;
  $self->{w} *= 1.2 if $shape =~ /(parallelogram|trapezium|pentagon)/;

  if ($shape =~ /^(diamond|circle|octagon|hexagon|triangle)\z/)
    {
    # the min size is either w or h, depending on which is bigger
    my $max = $self->{w}; $max = $self->{h} if $self->{h} > $max;
    $self->{h} = $max;
    $self->{w} = $max;
    }
  }

1;

#############################################################################
#############################################################################

package # hide from PAUSE
  Graph::Easy::Edge::Cell;

BEGIN
  {
  *_sprintf = \&Graph::Easy::As_svg::_sprintf;
  *_quote = \&Graph::Easy::As_svg::_quote;
  }

#############################################################################
#############################################################################
# Line drawing code for edges

# define the line lengths for the different edge types

sub LINE_HOR () { 0x0; }
sub LINE_VER () { 0x1; }
sub LINE_PATH() { 0x2; }

sub LINE_MASK () { 0x0F; }
sub LINE_DOUBLE () { 0x10; }

  # edge type       line type  spacing left/top
  #				    spacing right/bottom

my $draw_lines = {
  # for selfloops, we use paths
  EDGE_N_W_S()	=> [ LINE_PATH, 'M', -1, -0.5, 'L', -1, -1.5, 'L',  1, -1.5, 'L', 1,  -0.5 ], # v--|
  EDGE_S_W_N()	=> [ LINE_PATH, 'M', -1,  0.5, 'L', -1, 1.5,  'L',  1,  1.5, 'L', 1,   0.5 ], # ^--|
  EDGE_E_S_W()	=> [ LINE_PATH, 'M',  0.5, 1,  'L',  1.5, 1,  'L',  1.5, -1, 'L',  0.5, -1 ], # [_
  EDGE_W_S_E()	=> [ LINE_PATH, 'M', -0.5, 1,  'L', -1.5, 1,  'L', -1.5, -1, 'L', -0.5, -1 ], # _]

  # everything else draws straight lines
  EDGE_VER()	=> [ LINE_VER, 0, 0 ],				# |	vertical line
  EDGE_HOR()	=> [ LINE_HOR, 0, 0 ],				# --	vertical line

  EDGE_CROSS()	=> [ LINE_HOR, 0, 0, LINE_VER, 0, 0  ],		# + crossing

  EDGE_S_E()	=> [ LINE_VER, 0.5, 0, LINE_HOR, 0.5, 0 ],	# |_    corner (N to E)
  EDGE_N_W()	=> [ LINE_VER, 0, 0.5, LINE_HOR, 0, 0.5 ],	# _|    corner (N to W)
  EDGE_N_E()	=> [ LINE_VER, 0, 0.5, LINE_HOR, 0.5, 0 ],	# ,-    corner (S to E)
  EDGE_S_W()	=> [ LINE_VER, 0.5, 0, LINE_HOR, 0, 0.5 ],	# -,    corner (S to W)

  EDGE_S_E_W()	=> [ LINE_HOR, 0, 0, LINE_VER, 0.5, 0 ],	# joint
  EDGE_N_E_W()	=> [ LINE_HOR, 0, 0, LINE_VER, 0, 0.5 ],	# joint
  EDGE_E_N_S()	=> [ LINE_HOR, 0.5, 0, LINE_VER, 0, 0 ],	# joint
  EDGE_W_N_S()	=> [ LINE_HOR, 0, 0.5, LINE_VER, 0, 0 ],	# joint
 };

my $dimensions = {
  EDGE_VER()	=> [ 1, 2 ],	# |
  EDGE_HOR()	=> [ 2, 1 ],	# -

  EDGE_CROSS()	=> [ 2, 2 ],	# +	crossing

  EDGE_N_E()	=> [ 2, 2 ],	# |_    corner (N to E)
  EDGE_N_W()	=> [ 2, 2 ],	# _|    corner (N to W)
  EDGE_S_E()	=> [ 2, 2 ],	# ,-    corner (S to E)
  EDGE_S_W()	=> [ 2, 2 ],	# -,    corner (S to W)

  EDGE_S_E_W	=> [ 2, 2 ],	# -,-   three-sided corner (S to W/E)
  EDGE_N_E_W	=> [ 2, 2 ],	# -'-   three-sided corner (N to W/E)
  EDGE_E_N_S	=> [ 2, 2 ],	#  |-   three-sided corner (E to S/N)
  EDGE_W_N_S	=> [ 2, 2 ], 	# -|    three-sided corner (W to S/N)

  EDGE_N_W_S()	=> [ 4, 2 ],	# loops
  EDGE_S_W_N()	=> [ 4, 2 ],
  EDGE_E_S_W()	=> [ 2, 4 ],
  EDGE_W_S_E()	=> [ 2, 4 ],
 };

my $arrow_pos = {
  EDGE_N_W_S()	=> [ 1, -0.5  ],
  EDGE_S_W_N()	=> [ 1,  0.5  ],
  EDGE_E_S_W()	=> [  0.5, -1 ],
  EDGE_W_S_E()	=> [ -0.5, -1 ],
  };

my $arrow_correct = {
  EDGE_END_S()		=> [ 'h', 1.5 ],
  EDGE_END_N()		=> [ 'h', 1.5 ],
  EDGE_START_S()	=> [ 'h', 1 ],
  EDGE_START_N()	=> [ 'h', 1 ],
  EDGE_END_W()		=> [ 'w', 1.5 ],
  EDGE_END_E()		=> [ 'w', 1.5 ],
  EDGE_START_W()	=> [ 'w', 1, ],
  EDGE_START_E()	=> [ 'w', 1, ],
#  EDGE_END_S()		=> [ 'h', 3.5, 'w', 2 ],
#  EDGE_END_N()		=> [ 'h', 3.5, 'w', 2 ],
#  EDGE_START_S()	=> [ 'h', 3 ],
#  EDGE_START_N()	=> [ 'h', 3 ],
#  EDGE_END_W()		=> [ 'w', 1.5, 'h', 2 ],
#  EDGE_END_E()		=> [ 'w', 1.5, 'h', 2 ],
#  EDGE_START_W()	=> [ 'w', 1, ],
#  EDGE_START_E()	=> [ 'w', 1, ],
  };

sub _arrow_pos
  {
  # compute the position of the arrow
  my ($self, $x, $w, $y, $h, $ddx, $ddy, $dx, $dy) = @_;

  my $em = $self->EM();
  my $cell_type = $self->{type} & EDGE_TYPE_MASK;
  if (exists $arrow_pos->{$cell_type})
    {
    $dx = $arrow_pos->{$cell_type}->[0] * $em;
    $dy = $arrow_pos->{$cell_type}->[1] * $em;

    $dx = $w + $dx if $dx < 0;
    $dy = $h + $dy if $dy < 0;

    $dx += $x;
    $dy += $y;
    }

  _sprintf($dx,$dy);
  }

sub _svg_arrow
  {
  my ($self, $att, $x, $y, $type, $indent, $s) = @_;

  my $w = $self->{w};
  my $h = $self->{h};
  $s ||= 0;

  my $arrow_style = $self->attribute('arrow-style') || '';
  return '' if $arrow_style eq 'none';

  my $class = 'ah' . substr($arrow_style,0,1);
  # aho => ah
  $class = 'ah' if $class eq 'aho';
  # ah => ahb for bold/broad/wide edges with open arrows
  $class .= 'b' if $s > 1 && $class eq 'ah';

  # For the things to be "used" define these attributes, so if they
  # match, we can skip them, generating shorter output:
  my $DEF = {
    "stroke-linecap" => 'round',
    };

  my $a = {};
  for my $key (keys %$att)
    {
    next if $key =~ /^(stroke-dasharray|arrow-style|stroke-width)\z/;
    $a->{$key} = $att->{$key}
     unless exists $DEF->{$key} && $DEF->{$key} eq $att->{$key};
    }
  if ($arrow_style eq 'closed')
    {
    $a->{fill} = $self->color_attribute('background') || 'inherit';
    $a->{fill} = $self->{graph}->color_attribute('graph', 'background') || 'inherit' if $a->{fill} eq 'inherit';
    $a->{fill} = 'white' if $a->{fill} eq 'inherit';
    }
  elsif ($arrow_style eq 'filled')
    {
    # if fill is not defind, use the color
    my $fill = $self->raw_attribute('fill');
    if (defined $fill)
      {
      $a->{fill} = $self->color_attribute('fill');
      }
    else
      {
      $a->{fill} = $self->color_attribute('color');
      }
    }
  elsif ($class eq 'ahb')
    {
    $a->{fill} = $self->color_attribute('color'); delete $a->{fill} unless $a->{fill};
    }

  my $att_txt = $self->_svg_attributes_as_txt($a);

  $self->{graph}->_svg_use_def($class) if ref $self->{graph};

  my $ar = "$indent<use$att_txt xlink:href=\"#$class\" ";

  my $svg = '';

  my $ss = int($s / 4 + 1); #ss = 1 if $ss < 1;
  my $scale = ''; $scale = "scale($ss)" if $ss > 1;

  # displacement of the arrow, to account for wider lines
  my $dis = 0.1;

  my ($x1,$x2, $y1,$y2);

  if ($type & EDGE_END_N)
    {
    my $d = $dis; $d += $ss/150 if $ss > 1; $d *= $h if $d < 1;
    ($x1, $y1) = $self->_arrow_pos($x,$w,$y,$h, 0, $d, $x + $w / 2, $y + $d);
    $svg .= $ar . "transform=\"translate($x1 $y1)rotate(-90)$scale\"/>\n";
    }
  if ($type & EDGE_END_S)
    {
    my $d = $dis; $d += $ss/150 if $ss > 1; $d *= $h if $d < 1;

    ($x1, $y1) = $self->_arrow_pos($x,$w,$y,$h, 0, $d, $x + $w / 2, $y + $h - $d);
    $svg .= $ar . "transform=\"translate($x1 $y1)rotate(90)$scale\"/>\n";
    }
  if ($type & EDGE_END_W)
    {
    my $d = $dis; $d += $ss/50 if $ss > 1; $d *= $w if $d < 1;

    ($x1, $y1) = $self->_arrow_pos($x,$w,$y,$h, $d, 0, $x + $d, $y + $h / 2);
    $svg .= $ar . "transform=\"translate($x1 $y1)rotate(180)$scale\"/>\n";
    }
  if ($type & EDGE_END_E)
    {
    my $d = $dis; $d += $ss/50 if $ss > 1; $d *= $w if $d < 1;

    ($x1, $y1) = $self->_arrow_pos($x,$w,$y,$h, $d, 0, $x + $w - $d, $y + $h / 2);
    my $a = $ar . "x=\"$x1\" y=\"$y1\"/>\n";
    $a = $ar . "transform=\"translate($x1 $y1)$scale\"/>\n" if $scale;
    $svg .= $a;
    }

  $svg;
  }

sub _svg_line_straight
  {
  # Generate SVG tags for a vertical/horizontal line, bounded by (x,y), (x+w,y+h).
  # $l and $r shorten the line left/right, or top/bottom, respectively. If $l/$r < 1,
  # in % (aka $l * w), otherwise in units.
  # "$s" means there is a starting point, so the line needs to be shorter. Likewise
  # for "$e", only on the "other" side.
  # VER: s = north, e = south, HOR: s = left, e= right
  my ($self, $x, $y, $type, $l, $r, $s, $e, $add, $lw) = @_;

  my $w = $self->{w};
  my $h = $self->{h};

  $add = '' unless defined $add;	# additinal styles?

  my ($x1,$x2, $y1,$y2, $x3, $x4, $y3, $y4);

  $lw ||= 1;				# line-width

  my $ltype = $type & LINE_MASK;
  if ($ltype == LINE_HOR)
    {
    $l += $s if $s;
    $r += $e if $e;
    # +/-$lw to close the gaps at corners
    $l *= $w - $lw if $l == 0.5;
    $r *= $w - $lw if $r == 0.5;
    $l *= $w if $l < 1;
    $r *= $w if $r < 1;

    $x1 = $x + $l; $x2 = $x + $w - $r;
    $y1 = $y + $h / 2; $y2 = $y1;
    if (($type & LINE_DOUBLE) != 0)
      {
      $y1--; $y2--; $y3 = $y1 + 2; $y4 = $y3;
      # shorten the line for end/start points
      $x1 += 1.5 if $s; $x2 -= 1.5 if $e;
      $x3 = $x1; $x4 = $x2;
      }
    }
  else
    {
    $l += $s if $s;
    $r += $e if $e;
    # +/-$lw to close the gaps at corners
    $l *= $h - $lw if $l == 0.5;
    $r *= $h - $lw if $r == 0.5;
    $l *= $h if $l < 1;
    $r *= $h if $r < 1;

    $x1 = $x + $w / 2; $x2 = $x1;
    $y1 = $y + $l; $y2 = $y + $h - $r;
    if (($type & LINE_DOUBLE) != 0)
      {
      $x1--; $x2--; $x3 = $x1 + 2; $x4 = $x3;
      # shorten the line for end/start points
      $y1 += 1.5 if $s; $y2 -= 1.5 if $e;
      $y3 = $y1; $y4 = $y2;
      }
    }

  ($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4) = _sprintf($x1,$y1,$x2,$y2,$x3,$y3,$x4,$y4);

  my @r = ( "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" $add/>" );

  # for a double line
  push @r, "<line x1=\"$x3\" y1=\"$y3\" x2=\"$x4\" y2=\"$y4\" $add/>"
   if defined $x3;

  @r;
  }

sub _svg_path
  {
  # Generate SVG tags for a path, bounded by (x,y), (x+w,y+h).
  # "$s" means there is a starting point, so the line needs to be shorter. Likewise
  # for "$e", only on the "other" end side.
  # The passed coords are relative to x,y, and in EMs.
  my ($self, $x, $y, $s, $e, $add, $lw, @coords) = @_;

  my $em = $self->EM();

  my $w = $self->{w};
  my $h = $self->{h};

  $add = '' unless defined $add;	# additinal styles?
  $lw ||= 1;				# line-width
  my $d = '';

  while (@coords)
    {
    my ($t, $xa, $ya) = splice (@coords,0,3);	# 'M', '1', '-1'

    $xa *= $em; $xa += $w if $xa < 0;
    $ya *= $em; $ya += $h if $ya < 0;

    ($xa,$ya) = _sprintf($xa+$x,$ya+$y);

    $d .= "$t$xa $ya";
    }
  "<path d=\"$d\"$add fill=\"none\" />";
  }

#############################################################################
#############################################################################

sub _correct_size_svg
  {
  # correct the size for the edge cell
  my ($self,$format) = @_;

  return if defined $self->{w};

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)

  #my $border = $self->{edge}->attribute('borderstyle');

  # set the minimum width/height
  my $type = $self->{type} & EDGE_TYPE_MASK();
  my $dim = $dimensions->{$type} || [ 3, 3 ];
  ($self->{w}, $self->{h}) = ($dim->[0], $dim->[1]);

#  print STDERR "# min size at ($self->{x},$self->{y}): $self->{w} $self->{h} for $self->{type}\n";

  # make it bigger for cells with the label
  if ($self->{type} & EDGE_LABEL_CELL)
    {
    my ($w,$h) = $self->_svg_dimensions();

    # for vertical edges, multiply $w * 2
    $w = $w * 2 + 2 if ($type == EDGE_VER);
    # add a bit for HOR edges
    $w = $w + 1 if ($type == EDGE_HOR);
    $self->{w} += $w;
    my $lh = $self->LINE_HEIGHT();
    $self->{h} += $h * ($lh - $em) + 0.5;
    # add a bit for HOR edges
    $self->{h} += 2 if ($type == EDGE_HOR);
    }

  my $style = $self->{style};

  # correct for bigger arrows
  my $ac = $self->arrow_count();
#  if ($style =~ /^(broad|wide)/)
    {
    # for each end point, correct the size
    my $flags = ($self->{type} & EDGE_ARROW_MASK);

    # select the first bit (hopefully EDGE_ARROW_MASK == 0xFF
    my $start_bit = 0x800;

    while ($start_bit > 0x8)
      {
      my $a = $flags & $start_bit; $start_bit >>= 1;
      if ($a != 0)
	{
        my $ac = $arrow_correct->{$a};
        my $idx = 0;
	while ($idx < @$ac)
          {
          my ($where, $add) = ($ac->[$idx], $ac->[$idx+1]); $idx +=2;
          $add += 0.5 if $style =~ /^wide/;
          $self->{$where} += $add;
          }
	}
      }
    }

  ($self->{w}, $self->{h}) = ($self->{w} * $em, $self->{h} * $em);
  }

#############################################################################
#############################################################################

sub _svg_attributes
  {
  # Return a hash with attributes for the cell.
  my ($self, $em) = @_;

  my $att = {};

  $att->{stroke} = $self->color_attribute('color') || 'black';
  # include the stroke for renderers that can't cope with CSS styles
  # delete $att->{stroke} if $att->{stroke} eq 'black';	# black is default

  $att->{'stroke-width'} = 1;

  my $style = $self->{style};
  if ($style ne 'solid')				# solid line
    {
    $att->{'stroke-dasharray'} = $strokes->{$style}
     if exists $strokes->{$style};
    }

  $att->{'stroke-width'} = 3 if $style =~ /^bold/;
  $att->{'stroke-width'} = $em / 2 if $style =~ /^broad/;
  $att->{'stroke-width'} = $em if $style =~ /^wide/;

  $self->_adjust_dasharray($att);

  $att->{'arrow-style'} = $self->attribute('arrow-style') || '';
  $att;
  }

sub _draw_edge_line_and_arrows
  {
  }

sub as_svg
  {
  my ($self,$x,$y, $indent) = @_;

  my $em = $self->EM();		# multiplication factor chars * em = units (pixels)
  my $lh = $self->LINE_HEIGHT();

  # the attributes of the element we will finally output
  my $att = $self->_svg_attributes($em);

  # set a potential title
  my $title = _quote($self->title());
  $att->{title} = $title if $title ne '';

  my $att_txt = $self->_svg_attributes_as_txt($att);

  my $type = $self->{type} & EDGE_TYPE_MASK();
  my $end = $self->{type} & EDGE_END_MASK();
  my $start = $self->{type} & EDGE_START_MASK();

  my $svg = "$indent<!-- " . edge_type($type) . " -->\n";

  $svg .= $self->_svg_background($x,$y, $indent);

  my $style = $self->{style};

  # dont render invisible edges
  return $svg if $style eq 'invisible';

  my $sw = $att->{'stroke-width'} || 1;

  # for each line, include one SVG tag
  my $lines = [ @{$draw_lines->{$type}} ];	# make copy

  my $cross = ($self->{type} & EDGE_TYPE_MASK) == EDGE_CROSS;	# we are a cross section?
  my $add;

  my @line_tags;
  while (@$lines > 0)
    {
    my ($type) = shift @$lines;

    my @coords;
    if ($type != LINE_PATH)
      {
      @coords = splice (@$lines, 0, 2);
      }
    else
      {
      # eat all
      @coords = @$lines; @$lines = ();
      }

    # start/end points
    my ($s,$e) = (undef,undef);

    # LINE_VER must come last
    if ($cross && $type == LINE_VER)
      {
      $style = $self->{style_ver};
      my $sn = 1;
      $sn = 3 if $style =~ /^bold/;
      $sn = $em / 2 if $style =~ /^broad/;
      $sn = $em if $style =~ /^wide/;

      # XXX adjust dash array
      $add = ' stroke="' . $self->{color_ver} . '"' if $self->{color_ver};
      $add .= ' stroke-dasharray="' . ($strokes->{$style}||'1 0') .'"';
      $add .= ' stroke-width="' . $sn . '"' if $sn ne $sw;
      $add =~ s/^\s//;
      }

    my $bw  = $self->{w} * 0.1;
    my $bwe = $self->{w} * 0.1 + $sw;
    my $bh  = $em * 0.5;			# self->{h}
    my $bhe = $self->{h} * 0.1 + $sw * 1;

    # VER: s = north, e = south, HOR: s = left, e= right
    if ($type == LINE_VER)
      {
      $e = $bhe if ($end & EDGE_END_S);
      $s = $bhe if ($end & EDGE_END_N);
      $e = $bh if ($start & EDGE_START_S);
      $s = $bh if ($start & EDGE_START_N);
      }
    else # $type == LINE_HOR
      {
      $e = $bwe if ($end & EDGE_END_E);
      $s = $bwe if ($end & EDGE_END_W);
      $e = $bw if ($start & EDGE_START_E);
      $s = $bw if ($start & EDGE_START_W);
      }

    if ($type != LINE_PATH)
      {
      $type += LINE_DOUBLE if $style =~ /^double/;
      push @line_tags, $self->_svg_line_straight($x, $y, $type, $coords[0], $coords[1], $s, $e, $add, $sw);
      }
    else
      {
      push @line_tags, $self->_svg_path($x, $y, $s, $e, $add, $sw, @coords);
      }
    } # end lines

  # XXX TODO: put these on the edge group, not on each cell

  # we can put the line tags into a <g> and put stroke attributes on the g,
  # this will shorten the output

  $lines = ''; my $p = "\n"; my $i = $indent;
  if (@line_tags > 1)
    {
    $lines = "$indent<g$att_txt>\n";
    $i .= $indent;
    $p = "\n$indent</g>\n";
    }
  else
    {
    $line_tags[0] =~ s/ \/>/$att_txt \/>/;
    }
  $lines .= $i . join("\n$i", @line_tags) . $p;

  $svg .= $lines;

  my $arrow = $end;

  # depending on end points, add the arrows
  my $scale = $att->{'stroke-width'}||1;
  $svg .= $self->_svg_arrow($att, $x, $y, $arrow, $indent, $scale)
	unless $arrow == 0 || $self->{edge}->undirected();

  ###########################################################################
  # include the label/name/text if we are the label cell

  if (($self->{type} & EDGE_LABEL_CELL()))
    {
    my $label = $self->label(); $label = '' unless defined $label;

    if ($label ne '')
      {
      my ($w,$h) = $self->dimensions();
      my $em2 = $em / 2;
      my $xt = int($x + $self->{w} / 2);
      my $yt = int($y + $self->{h} / 2 - $lh / 3 - ($h - 1) * $lh);
#      my $yt = int($y + ($self->{h} / 2) - $em2);

      my $style = '';

      my $stype = $self->{type};

      # for HOR edges
      if ($type == EDGE_HOR)
        {
        # put the edge text left-aligned on the line
        $xt = $x + 2 * $em;

        # if we have only one big arrow, shift the text left/right
        my $ac = $self->arrow_count();
        my $style = $self->{style};

        if ($ac == 1)
          {
          my $shift = 0.2;
          $shift = 0.5 if $style =~ /^broad/;
          $shift = 0.8 if $style =~ /^wide/;
          # <-- edges, shift right, otherwise left
          $shift = -$shift if ($end & EDGE_END_E) != 0;
          #print STDERR "# shift=$shift \n";
          $xt = int($xt + 2 * $em * $shift);
          }
        }
      elsif ($type == EDGE_VER)
        {
	# put label on the right side of the edge
	$xt = $xt + $em2;
	my ($w,$h) = $self->dimensions();
        $yt = int($y + $self->{h} / 2 - $h * $em2 + $em2);
	$style = ' text-anchor="start"';
        }
      # selfloops
      else
        {
	# put label right of the edge
#	my ($w,$h) = $self->dimensions();

	# hor loops:
	$yt += $em2 if $stype & EDGE_START_N;
	$yt -= $em2 if $stype & EDGE_START_S;
        $yt += $em
	  if ($h > 1) && ($stype & EDGE_START_S);

	# vertical loops
        $yt = int($y + $self->{h} / 2)
	  if ($stype & EDGE_START_E) || ($stype & EDGE_START_W);

        $xt = int($x + $em * 2) if ($stype & EDGE_START_E);
        $xt = int($x + $self->{w} - 2*$em) if ($stype & EDGE_START_W);

	$style = ' text-anchor="start"';
	$style = ' text-anchor="middle"'
	  if ($stype & EDGE_START_N) || ($stype & EDGE_START_S);
        $style = ' text-anchor="end"' if ($stype & EDGE_START_W);
        }

      my $color = $self->raw_attribute('labelcolor');

      # fall back to color if label-color not defined
      $color = $self->color_attribute('color') if !defined $color;

      my $text = $self->_svg_text($color, $indent, $xt, $yt, $style, $xt, $x + $self->{w} - $em);

      my $link = _quote($self->link());
      $text = Graph::Easy::Node::_link($self, $indent.$text, $indent, $title, $link) if $link ne '';

      $svg .= $text;

      }
    }

  $svg .= "\n" unless $svg =~ /\n\n\z/;

  $svg;
  }

__END__

=pod

=encoding UTF-8

=head1 NAME

Graph::Easy::As_svg - Output a Graph::Easy as Scalable Vector Graphics (SVG)

=head1 VERSION

version 0.28

=head1 SYNOPSIS

	use Graph::Easy;

	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');

	print $graph->as_svg_file();

=head1 DESCRIPTION

C<Graph::Easy::As_svg> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a SVG text.

X<graph::easy>
X<graph>
X<drawing>
X<svg>
X<scalable>
X<vector>
X<grafics>

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

X<tels>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Graph-Easy-As_svg>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graph-Easy-As_svg>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Graph-Easy-As_svg>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Graph-Easy-As_svg>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Graph-Easy-As_svg>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Graph::Easy::As_svg>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-graph-easy-as_svg at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Graph-Easy-As_svg>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Graph-Easy-As_svg>

  git clone https://github.com/shlomif/Graph-Easy-As_svg.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Graph-Easy-As_svg/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2004 by Tels.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
