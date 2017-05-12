#!/usr/bin/env perl

use strict;
use warnings;
use Games::Terrain::DiamondSquare 'create_terrain';
use Getopt::Long;

GetOptions(
    'height=i' => \( my $height = 50 ),
    'width=i'  => \( my $width  = 50 ),
    'roughness=f' => \my $roughness,
    'landscape'   => \my $landscape_wanted,
);


my $bucket  = 0;
my @buckets = map { $bucket += 1/16 } 1 .. 16;

my $landscape = create_terrain( $height, $width, $roughness );

sub get_color {
    my $value = shift;
    my $i     = 0;
    foreach (@buckets) {
        last if $value < $_;
        $i++;
    }
    return $i;
}

my ( $css, $characters )
  = $landscape_wanted
  ? get_landscape()
  : get_black_and_white();

my $table = "";
foreach my $row (@$landscape) {
    foreach my $value (@$row) {
        my $color = get_color($value);
        my $char = $characters->[$color];
        $table .= qq{<span class="c$color">$char</span>};
    }
    $table .= "<br />";
}

print <<"END";
<html>
  <head>
    <title>Diamond Square Map</title>
    <style type="text/css">
      /*<![CDATA[*/
$css
      body { 
        background-color:      #FFFFFF;
        font-family:           Courier;
      }
      /*]]>*/
    </style>
  </head>
  <body>
    $table
  </body>
</html>
END

sub get_black_and_white {
    my $black_and_white = <<'END';
          .c0  { background-color: #000000 }
          .c1  { background-color: #111111 }
          .c2  { background-color: #222222 }
          .c3  { background-color: #333333 }
          .c4  { background-color: #444444 }
          .c5  { background-color: #555555 }
          .c6  { background-color: #666666 }
          .c7  { background-color: #777777 }
          .c8  { background-color: #888888 }
          .c9  { background-color: #999999 }
          .c10 { background-color: #AAAAAA }
          .c11 { background-color: #BBBBBB }
          .c12 { background-color: #CCCCCC }
          .c13 { background-color: #DDDDDD }
          .c14 { background-color: #EEEEEE }
          .c15 { background-color: #FFFFFF }
END
    my @characters = ('&nbsp;') x 16;
    return ( $black_and_white, \@characters );
}

sub get_landscape {
    my $land_scape = <<'END';
          .c0  { background-color: #330099; color: #FFFFFF } /* deep water */
          .c1  { background-color: #3300CC; color: #FFFFFF } /* water */
          .c2  { background-color: #3300FF; color: #FFFFFF } /* shallow water */
          .c3  { background-color: #663300 }                 /* muddy bank */
          .c4  { background-color: #33FF33 }                 /* light grass */
          .c5  { background-color: #33FF33 }                 /* light grass */
          .c6  { background-color: #33FF33 }                 /* light grass */
          .c7  { background-color: #33FF33 }                 /* light grass */
          .c8  { background-color: #33FF33 }                 /* light grass */
          .c9  { background-color: #33FF33 }                 /* light grass */
          .c10 { background-color: #003300; color: #663300 } /* forest */
          .c11 { background-color: #003300; color: #663300 } /* forest */
          .c12 { background-color: #003300; color: #663300 } /* forest */
          .c13 { background-color: #686868; color: #FFFFFF } /* mountain */
          .c14 { background-color: #686868; color: #FFFFFF } /* mountain */
          .c15 { background-color: #F8F8F8 } /* clouds */
END
    my $characters = [
        '~', '~', '~',    # water
        '&nbsp;',         # muddy bank
        '&nbsp;', '&nbsp;', '&nbsp;', '&nbsp;', '&nbsp;',
        '&nbsp;',         # light grass
        'T', 'T', 'T',    # forest
        '^', '^',         # mountain
        '&nbsp;',         # cloud
    ];
    return ( $land_scape, $characters );
}

__END__

=head1 NAME

C<tohtml.pl> - Generate diamond-square fractal landscapes in HTML

=head1 SYNOSPS

 perl tohtml.pl --height 100 --width 200 --roughness .2 --landscape

=head1 DESCRIPTION

This tool shows how to use the C<Games::Terrain::DiamondSquare> module. It
will generate the HTML to display the output, though larger maps can be quite
a burden for some browsers to render.

=head1 ARGUMENTS

All arguments are optional.

=head2 C<--height, -h>

Takes a positive integer value. Default 50.

=head2 C<--width, -w>

Takes a positive integer value. Default 50.

=head2 C<--roughness, r>

A floating point value from 0.0 to 1.0. Higher numbers generate "rougher"
terrain. Default is .5.

=head2 C<--landscape, -l>

By default, we generate a 16 hue black and white plasma map. With the
C<--landscape> option, we generate an "old style" ASCII art map of terrain.
