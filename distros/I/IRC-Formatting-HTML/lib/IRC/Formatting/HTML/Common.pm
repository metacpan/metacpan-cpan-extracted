package IRC::Formatting::HTML::Common;

use warnings;
use strict;

use Exporter 'import';

our @EXPORT = qw/$BOLD $COLOR $COLORM $RESET $INVERSE $UNDERLINE
                $COLOR_SEQUENCE $FORMAT_SEQUENCE @COLORS/;

our @EXPORT_OK = qw/html_color_to_irc color_distance hex_color_to_dec rgb_str_to_dec style_tag/;

our $BOLD      = "\002",
our $COLOR     = "\003";
our $COLORM    = qr/^$COLOR/;
our $RESET     = "\017";
our $INVERSE   = "\026";
our $UNDERLINE = "\037";

our $COLOR_SEQUENCE    = qr/([0-9]{1,2})(?:,([0-9]{1,2}))?/;
my $COLOR_SEQUENCE_NC = qr/[0-9]{1,2}(?:,[0-9]{1,2})?/;
our $FORMAT_SEQUENCE   = qr/(
      $BOLD
    | $COLOR$COLOR_SEQUENCE_NC?  | $RESET
    | $INVERSE
    | $UNDERLINE)
    /x;

our @COLORS = ( qw/fff 000 008 080 f00 800 808 f80
                   ff0 0f0 088 0ff 00f f0f 888 ccc/ );

my @colors_dec = do { map {hex_color_to_dec($_)} @COLORS };

sub html_color_to_irc {
  my $color = shift;
  my $rgb;
  if ($color =~ /^#?[a-f0-9]+$/i) {
    $rgb = hex_color_to_dec($color);
  } elsif ($color =~ /^rgb/) {
    $rgb = rgb_str_to_dec($color);
  }

  return () unless $rgb;

  my ($closest, $dist) = (1, 500);
  for my $i (0 .. @colors_dec - 1) {
    my $_rgb = $colors_dec[$i];
    my $_dist = color_distance($rgb, $_rgb);
    if ($_dist < $dist) {
      ($closest, $dist) = ($i, $_dist);
    }
    last if $dist == 0;
  }
  return sprintf "%02s", $closest;
}

sub color_distance {
  my ($a, $b) = @_;
  my $distance = 0;
  for (0 .. 2) {
    my $_a = $a->[$_];
    my $_b = $b->[$_];
    $distance += ($_b - $_a) ** 2;
  }
  return (int (sqrt($distance) * 10)) / 10;
}

sub rgb_str_to_dec {
  my $color = shift;
  if ($color =~ /^rgba? \s* \( \s* (\d+) \s* , \s* (\d+) \s* , \s* (\d+) \s* \)/xi) {
    return [$1, $2, $3];
  }
  return ();
}

sub hex_color_to_dec {
  my $color = shift;

  if (substr($color, 0, 1) eq "#") {
    $color = substr $color, 1;
  }

  if (length $color == 3) {
    $color = join "", map {$_ x 2} split "", $color;
  }

  my @rgb = ($color =~ /([a-f0-9]{2})/gi);
  if (@rgb == 3) {
    return [ map {hex $_} @rgb ];
  }
  
  return ();
}

sub style_tag {
  my $style = "<style type=\"text/css\">\n"
            . " .bold { font-weight: bold }\n"
            . " .ul { text-decoration: underline }\n"
            . " .italic { font-style: italic }\n";
            
  for (@COLORS) {
    $style .= " .fg-$_ { color: #$_; }\n";
    $style .= " .bg-$_ { background-color: #$_; }\n";
  }

  $style .= "</style>";

  return $style;
}

1;
