package Graphics::ColorNames::GrayScale;

=head1 NAME

Graphics::ColorNames::GrayScale - grayscale colors for Graphics::ColorNames

=head1 SYNOPSIS

  require Graphics::ColorNames::GrayScale;

  $NameTable = Graphics::ColorNames::GrayScale->NamesRgbTable();
  $RgbColor  = $NameTable->{gray80};

=head1 DESCRIPTION

This module provides grayscale colors for L<Graphics::ColorNames>.
The following are valid colors:

  Format  Example  Description

  grayHH  grey80   Gray value in hexidecimal (HH between 00 and ff)
  grayDDD gray128  Gray value in decimal (DDD between 000 and 255)
  grayP%  gray50%  Gray value in percentage (P between 0 and 100)

Besides C<gray>, on can also use the following colors:

  red
  green
  blue
  yellow
  cyan
  purple

Lower values are darker, higher values are brighter.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2004 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

require 5.006;

use strict;
use warnings;

our $VERSION = '2.00';

my %RgbColors   = ( );

my %Schemes     = ( );

sub NamesRgbTable() {
  return sub {
    my $name = shift;
    return $RgbColors{$name},
      if (exists $RgbColors{$name});

    if ($name =~ /^(gr[ae]y|red|green|blue|yellow|cyan|purple)([\da-f]+\%?)$/)
      {
	my $color  = $1;
	my $degree = $2;

	unless (keys %Schemes) {
	  %Schemes = (
            gray   => 0xffffff,
            grey   => 0xffffff,
            red    => 0xff0000,
            green  => 0x00ff00,
            blue   => 0x0000ff,
            yellow => 0xffff00,
            cyan   => 0x00ffff,
            purple => 0xff00ff,
          );
	}

	return, unless (exists $Schemes{$color});

	my $byte;
	if ($degree =~ /^\d{3}$/) {
	  $byte = $degree;
	} elsif ($degree =~ /^(\d{1,3})\%$/) {
	  $byte = int($1 / 100 * 255);
	} elsif ($degree =~ /^[\da-f]{2}$/) {
	  $byte = CORE::hex $degree;
	} else {
	  return;
	}

	return, if ($byte > 255);

	my $rgb = $Schemes{$color} & ( ($byte << 16) | ($byte << 8) | $byte );

	$RgbColors{$name} = $rgb;

	return $rgb;

      }
    else {
      return;
    }
  };
}


# sub NamesRgbTable() {
#   unless (keys %RgbColors) {
#     for my $i (0..255) {
#       my $rgb = ($i << 16) | ($i << 8) | $i;
#       my $dec = sprintf('%03d',$i);
#       my $hex = sprintf('%02x',$i);
#       my $pct = int(($i / 255) * 100) . '%';

#       $RgbColors{"gray$dec"} = $rgb;
#       $RgbColors{"gray$hex"} = $rgb;
#       $RgbColors{"gray$pct"} = $rgb,
# 	unless (exists $RgbColors{"gray$pct"});

#       $RgbColors{"red$dec"} = ($rgb & 0xff0000);
#       $RgbColors{"red$hex"} = ($rgb & 0xff0000);
#       $RgbColors{"red$pct"} = ($rgb & 0xff0000),
# 	unless (exists $RgbColors{"red$pct"});

#       $RgbColors{"green$dec"} = ($rgb & 0x00ff00);
#       $RgbColors{"green$hex"} = ($rgb & 0x00ff00);
#       $RgbColors{"green$pct"} = ($rgb & 0x00ff00),
# 	unless (exists $RgbColors{"green$pct"});

#       $RgbColors{"blue$dec"} = ($rgb & 0x0000ff);
#       $RgbColors{"blue$hex"} = ($rgb & 0x0000ff);
#       $RgbColors{"blue$pct"} = ($rgb & 0x0000ff),
# 	unless (exists $RgbColors{"blue$pct"});

#       $RgbColors{"yellow$dec"} = ($rgb & 0xffff00);
#       $RgbColors{"yellow$hex"} = ($rgb & 0xffff00);
#       $RgbColors{"yellow$pct"} = ($rgb & 0xffff00),
# 	unless (exists $RgbColors{"yellow$pct"});

#       $RgbColors{"cyan$dec"} = ($rgb & 0x00ffff);
#       $RgbColors{"cyan$hex"} = ($rgb & 0x00ffff);
#       $RgbColors{"cyan$pct"} = ($rgb & 0x00ffff),
# 	unless (exists $RgbColors{"cyan$pct"});

#       $RgbColors{"purple$dec"} = ($rgb & 0xff00ff);
#       $RgbColors{"purple$hex"} = ($rgb & 0xff00ff);
#       $RgbColors{"purple$pct"} = ($rgb & 0xff00ff),
# 	unless (exists $RgbColors{"purple$pct"});

#     }
#   }
#   return \%RgbColors;
# }

1;

