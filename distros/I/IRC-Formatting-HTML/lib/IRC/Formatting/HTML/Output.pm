package IRC::Formatting::HTML::Output;

use warnings;
use strict;

use IRC::Formatting::HTML::Common;

my ($b, $i, $u, $fg, $bg);
my $italic_invert = 0;
my $use_classes = 0;

sub _parse_formatted_string {
  my $line = shift;
  _reset();
  my @segments;
  my @chunks = ("", split($FORMAT_SEQUENCE, $line));
  $line = "";
  while (scalar(@chunks)) {
    my $format_sequence = shift(@chunks);
    my $text = shift(@chunks);
    _accumulate($format_sequence);
    next unless defined $text and length $text;
    $text =~ s/ {2}/ &#160;/g;
    if ($use_classes) {
      $line .= "<span class=\"" . _to_classes()."\">$text</span>";
    } else {
      $line .= "<span style=\"" . _to_css()."\">$text</span>"; 
    }
  }
  return $line;
}


sub _reset {
  ($b, $i, $u) = (0, 0, 0);
  undef $fg;
  undef $bg;
}

sub _accumulate {
  my $format_sequence = shift;
  if ($format_sequence eq $BOLD) {
    $b = !$b;
  }
  elsif ($format_sequence eq $UNDERLINE) {
    $u = !$u;
  }
  elsif ($format_sequence eq $INVERSE) {
    $i = !$i;
  }
  elsif ($format_sequence eq $RESET) {
    _reset;
  }
  elsif ($format_sequence =~ $COLORM) {
    ($fg, $bg) = _extract_colors_from($format_sequence);
  }
}

sub _extract_colors_from {
  my $format_sequence = shift;
  $format_sequence = substr($format_sequence, 1);
  my ($_fg, $_bg) = ($format_sequence =~ $COLOR_SEQUENCE);
  if (! defined $_fg) {
    return undef, undef;
  }
  elsif (! defined $_bg) {
    return $_fg, $bg;
  }
  else {
    return $_fg, $_bg;
  }
}

sub _to_css {
  my $styles = "";

  my ($_fg, $_bg);

  # italicize inverted text if that option is set
  if ($i) {
    if ($italic_invert) {
      $styles .= "font-style: italic;";
      ($_fg, $_bg) = ($fg, $bg);
    } else {
      ($_fg, $_bg) = ($bg || 0, $fg || 1);
    }
  } else {
    ($_fg, $_bg) = ($fg, $bg);
  }

  $styles .= "color: #$COLORS[$_fg];" if defined $_fg and $COLORS[$_fg];
  $styles .= "background-color: #$COLORS[$_bg];" if defined $_bg and $COLORS[$_bg];
  $styles .= "font-weight: bold;" if $b;
  $styles .= "text-decoration: underline;" if $u;
  return $styles;
}

sub _to_classes {
  my @classes;

  my ($_fg, $_bg);

  # italicize inverted text if that option is set
  if ($i) {
    if ($italic_invert) {
      push @classes, "italic";
      ($_fg, $_bg) = ($fg, $bg);
    } else {
      ($_fg, $_bg) = ($bg || 0, $fg || 1);
    }
  } else {
    ($_fg, $_bg) = ($fg, $bg);
  }

  push @classes, "fg-$COLORS[$_fg]" if defined $_fg and $COLORS[$_fg];
  push @classes, "bg-$COLORS[$_bg]" if defined $_bg and $COLORS[$_bg];
  push @classes, "bold" if $b;
  push @classes, "ul" if $u;
  return join " ", @classes;
}

sub parse {
  my ($string, $italic, $classes) = @_;

  $italic_invert = 1 if $italic;
  $use_classes = 1 if $classes;
  _encode_entities(\$string);

  my $text = join "\n",
       map {_parse_formatted_string($_)}
       split "\n", $string;

  $italic_invert = 0;
  $use_classes = 0;

  return $text;
}

sub _encode_entities {
  my $string = shift;
  return unless $string;
  $$string =~ s/&/&amp;/g;
  $$string =~ s/</&lt;/g;
  $$string =~ s/>/&gt;/g;
  $$string =~ s/"/&quot;/g;
}

1;
