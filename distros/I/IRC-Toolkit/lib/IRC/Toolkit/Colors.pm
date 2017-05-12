package IRC::Toolkit::Colors;
$IRC::Toolkit::Colors::VERSION = '0.092002';
use strictures 2;
use Carp;

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  color
  has_color
  strip_color
/;

our %COLORS = (
  NORMAL      => "\x0f",

  BOLD        => "\x02",
  UNDERLINE   => "\x1f",
  REVERSE     => "\x16",
  ITALIC      => "\x1d",

  WHITE       => "\x0300",
  BLACK       => "\x0301",
  BLUE        => "\x0302",
  GREEN       => "\x0303",
  RED         => "\x0304",
  BROWN       => "\x0305",
  PURPLE      => "\x0306",
  ORANGE      => "\x0307",
  YELLOW      => "\x0308",
  TEAL        => "\x0310",
  PINK        => "\x0313",
  GREY        => "\x0314",
  GRAY        => "\x0314",

  LIGHT_BLUE  => "\x0312",
  LIGHT_CYAN  => "\x0311",
  CYAN        => "\x0311",
  LIGHT_GREEN => "\x0309",
  LIGHT_GRAY  => "\x0315",
  LIGHT_GREY  => "\x0315",
);

sub color {
  my ($fmt, $str) = @_;
  $fmt = uc($fmt || 'normal');
  my $slct = $COLORS{$fmt};
  unless (defined $slct) {
    carp "Invalid format $fmt passed to color()";
    return $str || $COLORS{NORMAL}
  }
  $str ? join('', $slct, $str, $COLORS{NORMAL}) : $slct
}

sub has_color {
  !! ( $_[0] =~ /[\x02\x03\x04\x1B\x1f\x16\x1d\x11\x06]/ )
}

sub strip_color {
  my ($str) = @_;
  # Borrowed from IRC::Utils;
  # mIRC:
  $str =~ s/\x03(?:,\d{1,2}|\d{1,2}(?:,\d{1,2})?)?//g;
  # RGB:
  $str =~ s/\x04[0-9a-fA-F]{0,6}//ig;
  # ECMA-48:
  $str =~ s/\x1B\[.*?[\x00-\x1F\x40-\x7E]//g;
  # Formatting codes:
  $str =~ s/[\x02\x1f\x16\x1d\x11\x06]//g;
  # Cancellation code:
  $str =~ s/\x0f//g;
  $str
}


1;

=pod

=head1 NAME

IRC::Toolkit::Colors - IRC color code utilities

=head1 SYNOPSIS

  my $str = color('red', "red text") ." other text";

  if (has_color($str)) {
    # ...
  }

  my $stripped = strip_color($str);

=head1 DESCRIPTION

IRC utilities for adding color/formatting codes to a string.

=head2 color

  my $code = color('red');
  my $str = color('bold') . "bold text" . color() . "normal text";
  my $str = color('bold', "bold text");

Add mIRC formatting/color codes to a string.

Valid formatting codes are:

  normal 
  bold 
  underline 
  reverse 
  italic

Valid color codes are:

  white
  black
  blue
  light_blue
  cyan
  green
  light_green
  red
  brown
  purple
  orange
  yellow
  teal
  pink
  gray
  light_gray

=head2 has_color

Returns true if the given string contains color or formatting codes.

=head2 strip_color

Strips all color and formatting codes from the string.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Much of this code is primarily derived from L<IRC::Utils>, authored by HINRIK &
BINGOS.

Licensed under the same terms as Perl.

=cut
