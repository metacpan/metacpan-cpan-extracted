package IRC::FromANSI::Tiny;
# ABSTRACT: Convert ANSI color codes to IRC
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY
our $VERSION = '0.02'; # VERSION

use strict;
use warnings;
use Parse::ANSIColor::Tiny;

my %irccolors = (
  black   => 1,
  red     => 5,
  green   => 3,
  yellow  => 7,
  blue    => 2,
  magenta => 6,
  cyan    => 10,
  white   => 14,
  bright_black   => 15,
  bright_red     => 4,
  bright_green   => 9,
  bright_yellow  => 8,
  bright_blue    => 12,
  bright_magenta => 13,
  bright_cyan    => 11,
  bright_white   => 0,
);

sub convert {
  my ($text) = @_;
  my $ret = "";

  my $ansi = Parse::ANSIColor::Tiny->new;
  my $data = $ansi->parse($text);
  my (%foregrounds, %backgrounds);
  $foregrounds{$_} = 1 for $ansi->foreground_colors;
  $backgrounds{$_} = 1 for $ansi->background_colors;
  my ($foreground, $background, $underline, $bold) = (undef, undef, 0, 0);

  for my $chunk (@$data) {
    my ($attrs, $text) = @$chunk;
    my ($fg) = grep $foregrounds{$_}, @$attrs;
    my ($bg) = grep $backgrounds{$_}, @$attrs;
    my $bb = (grep $_ eq 'bold', @$attrs) ? 1 : 0;
    my $u = (grep $_ eq 'underline', @$attrs) ? 1 : 0;

    my $set_color;
    if ($fg) {
      $foreground = ($b ? 'bright_' : '') . $fg;
      $set_color = "\cC$irccolors{$foreground}";
      $bb = 0;
    }
    if ($bg) {
      $background = $bg;
      $set_color = "\cC" . $irccolors{$foreground || "black"} . ",$irccolors{$background}";
    }
    if (!$fg && !$bg && ($foreground || $background)) {
      undef $foreground;
      undef $background;
      if ($text =~ /^\d/) {
        # Use "reset all" to clear color to avoid a following number
        # being interpreted as a color code 
        $set_color = "\cO";
        undef $underline;
        undef $bold;
      } else {
        $set_color = "\cC";
      }
    }
    $ret .= $set_color if length $set_color;
    if ($bb ^ $bold) {
      $bold = $bb;
      $ret .= "\cB";
    }
    if ($u ^ $underline) {
      $underline = $u;
      $ret .= "\c_";
    }
    if ($ret =~ /\D\d$/ && $text =~ /^\d/) {
      # Avoid a 1-digit color code (e.g. ^C1 or ^C12,3 running into a following
      # digit that's supposed to be part of the literal text, by making it two-digit.
      substr($ret, -1, 0, '0');
    }
    $ret .= $text;
  }
  return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IRC::FromANSI::Tiny - Convert ANSI color codes to IRC

=head1 VERSION

version 0.02

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
