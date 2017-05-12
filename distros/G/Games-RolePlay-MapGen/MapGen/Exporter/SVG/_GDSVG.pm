# vi:filetype=perl:

package Games::RolePlay::MapGen::Exporter::SVG::_GDSVG;

# NOTE: Most of this code is ripped from GD::SVG v0.28, 
# /usr/local/share/perl/5.8.8/GD/SVG.pm on my machine.  ... why not just use
# GD::SVG directly?  It does a lot I don't need and does a lot I need in a way
# that differs from what I needed.
# 
# Why not submit patches and things?  Well, I feel like a lot of the changes
# here are going for things that are really application specific.
#
# Why not subclass?  GD::SVG seems like a work in progress, and I don't want to
# re-write this every time that changes.  This is more sane imo.
#
# -Paul

use common::sense;
use SVG;
use Carp;

### GD Emulation

# new {{{
sub new {
    my ($class, $width, $height, $debug) = @_;

    my $this = bless {}, $class;
    my $img  = SVG->new(width=>$width, height=>$height);

    $this->{img}    = $img;
    $this->{width}  = $width;
    $this->{height} = $height;

    $this->{foreground} = $this->colorAllocate(0, 0, 0);

    return $this;
}
# }}}
# svg {{{
sub svg {
    my $this = shift;

    $this->{img}->xmlify(
        -standalone => 'no',
             -sysid => "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
             -pubid => "-//W3C//DTD SVG 1.1//EN" );
}
# }}}
# colorAllocate {{{
sub colorAllocate {
    my ($this, $r, $g, $b) = @_;
    $r ||= 0;
    $g ||= 0;
    $b ||= 0;

    my $new_index = (defined $this->{colors_added}) ? scalar @{$this->{colors_added}} : 0;
    $this->{colors}->{$new_index} = [$r, $g, $b];

    push (@{$this->{colors_added}}, $new_index);
    return $new_index;
}
# }}}
# line {{{
sub line {
    my ($this, $x1, $y1, $x2, $y2, $color_index) = @_;

    my ($img, $id) = $this->_prep($x1, $y1);
    my $style      = $this->_build_style($id, $color_index, $color_index);
       $style->{'stroke-linecap'}  = 'square';
       $style->{'shape-rendering'} = 'crispEdges';

    my $result     = $img->line(
        x1    => $x1, y1=>$y1, 
        x2    => $x2, y2=>$y2, 
        id    => $id, 
        _flatten_hash($style),
    );

    return $result;
}
# }}}
# rectangle {{{
sub rectangle {
    my ($this, $x1, $y1, $x2, $y2, $color_index, $fill) = @_;

    my ($img, $id) = $this->_prep($x1, $y1);
    my $style      = $this->_build_style($id, $color_index, $fill);
       $style->{'shape-rendering'} = 'crispEdges';

    $img->rectangle( x => $x1, y => $y1, width => $x2-$x1, height => $y2-$y1, id => $id, style => $style );
}
# }}}
# filledRectangle {{{
sub filledRectangle {
    my ($this, $x1, $y1, $x2, $y2, $color) = @_;

    $this->rectangle($x1, $y1, $x2, $y2, $color, $color);
}
# }}}
# arc {{{
sub arc {
    my ($this, $cx, $cy, $width, $height, $start, $end, $color_index, $fill) = @_;

    return $this->ellipse($cx, $cy, $width, $height, $color_index, $fill)
        if ($start == 0 and $end == 360) or ($end == 360 and $start == 0);

    my ($img, $id)                              = $this->_prep($cy, $cx);
    my ($nstart, $nend, $large, $sweep, $a, $b) = _calculate_arc_params($start, $end, $width, $height);
    my ($startx, $starty)                       = _calculate_point_coords($cx, $cy, $width, $height, $nstart);
    my ($endx, $endy)                           = _calculate_point_coords($cx, $cy, $width, $height, $nend);

    my $style = $this->_build_style($id, $color_index, $fill);

    return $img->path( d => "M$startx, $starty A$a, $b 0 $large, $sweep $endx, $endy", style => $style );
}
# }}}
# ellipse {{{
sub ellipse {
    my ($this, $x1, $y1, $width, $height, $color_index, $fill) = @_;
    my ($img, $id) = $this->_prep($x1, $y1);
    my $style = $this->_build_style($id, $color_index, $fill);

    # GD uses diameters, SVG uses radii
    $width  =  $width / 2;
    $height = $height / 2;

    return $img->ellipse( cx => $x1, cy => $y1, rx => $width, ry => $height, id => $id, style => $style, );
}
# }}}

### Internal functions

# _prep {{{
sub _prep {
    my ($this, @params) = @_;
    my $img = $this->{img};
    my $id  = $this->_create_id;

    return ($img, $id);
}
# }}}
# _build_style {{{
sub _build_style {
    my ($this, $id, $color, $fill, $stroke_opacity) = @_;
    my $fill_opacity = ($fill) ? '1.0' : 0;

    $fill = defined $fill ? $this->_get_color($fill) : 'none';
    return {
         stroke          => $this->_get_color($color),
         opacity         => 1,
         fill            => $fill,
    };
}
# }}}
# _create_id {{{
sub _create_id {
    my $this = shift;
    my $f = (caller(2))[3];
       $f = (split "::", $f)[-1];

    $f . (++ $this->{id}{$f});
}
# }}}
# _get_color {{{
sub _get_color {
    my ($this, $index) = @_;

    confess "somebody gave me a bum index!" unless length $index > 0;

    return ($index) if ($index =~ /rgb/); # Already allocated.
    return ($index) if ($index eq 'none'); # Generate by callbacks using none for fill
   
    my ($r, $g, $b) = @{$this->{colors}{$index}};
    my $color = "rgb($r, $g, $b)";

    return $color;
}
# }}}

# precalculated cyclic transcendentals {{{
# NOTE: This clever little hack is (unsurprisingly) directly from GD::SVG, he
# explains it as, "Kludge - use precalculated values of cos(theta) and
# sin(theta) so that I do no have to examine quadrants."  It may be a kluge,
# but it's good thinking.

my @cosT = (qw/1024 1023 1023 1022 1021 1020 1018 1016 1014 1011 1008
1005 1001 997 993 989 984 979 973 968 962 955 949 942 935 928 920 912
904 895 886 877 868 858 848 838 828 817 806 795 784 772 760 748 736
724 711 698 685 671 658 644 630 616 601 587 572 557 542 527 512 496
480 464 448 432 416 400 383 366 350 333 316 299 282 265 247 230 212
195 177 160 142 124 107 89 71 53 35 17 0 -17 -35 -53 -71 -89 -107 -124
-142 -160 -177 -195 -212 -230 -247 -265 -282 -299 -316 -333 -350 -366
-383 -400 -416 -432 -448 -464 -480 -496 -512 -527 -542 -557 -572 -587
-601 -616 -630 -644 -658 -671 -685 -698 -711 -724 -736 -748 -760 -772
-784 -795 -806 -817 -828 -838 -848 -858 -868 -877 -886 -895 -904 -912
-920 -928 -935 -942 -949 -955 -962 -968 -973 -979 -984 -989 -993 -997
-1001 -1005 -1008 -1011 -1014 -1016 -1018 -1020 -1021 -1022 -1023
-1023 -1024 -1023 -1023 -1022 -1021 -1020 -1018 -1016 -1014 -1011
-1008 -1005 -1001 -997 -993 -989 -984 -979 -973 -968 -962 -955 -949
-942 -935 -928 -920 -912 -904 -895 -886 -877 -868 -858 -848 -838 -828
-817 -806 -795 -784 -772 -760 -748 -736 -724 -711 -698 -685 -671 -658
-644 -630 -616 -601 -587 -572 -557 -542 -527 -512 -496 -480 -464 -448
-432 -416 -400 -383 -366 -350 -333 -316 -299 -282 -265 -247 -230 -212
-195 -177 -160 -142 -124 -107 -89 -71 -53 -35 -17 0 17 35 53 71 89 107
124 142 160 177 195 212 230 247 265 282 299 316 333 350 366 383 400
416 432 448 464 480 496 512 527 542 557 572 587 601 616 630 644 658
671 685 698 711 724 736 748 760 772 784 795 806 817 828 838 848 858
868 877 886 895 904 912 920 928 935 942 949 955 962 968 973 979 984
989 993 997 1001 1005 1008 1011 1014 1016 1018 1020 1021 1022 1023
1023/);

my @sinT = (qw/0 17 35 53 71 89 107 124 142 160 177 195 212 230 247
265 282 299 316 333 350 366 383 400 416 432 448 464 480 496 512 527
542 557 572 587 601 616 630 644 658 671 685 698 711 724 736 748 760
772 784 795 806 817 828 838 848 858 868 877 886 895 904 912 920 928
935 942 949 955 962 968 973 979 984 989 993 997 1001 1005 1008 1011
1014 1016 1018 1020 1021 1022 1023 1023 1024 1023 1023 1022 1021 1020
1018 1016 1014 1011 1008 1005 1001 997 993 989 984 979 973 968 962 955
949 942 935 928 920 912 904 895 886 877 868 858 848 838 828 817 806
795 784 772 760 748 736 724 711 698 685 671 658 644 630 616 601 587
572 557 542 527 512 496 480 464 448 432 416 400 383 366 350 333 316
299 282 265 247 230 212 195 177 160 142 124 107 89 71 53 35 17 0 -17
-35 -53 -71 -89 -107 -124 -142 -160 -177 -195 -212 -230 -247 -265 -282
-299 -316 -333 -350 -366 -383 -400 -416 -432 -448 -464 -480 -496 -512
-527 -542 -557 -572 -587 -601 -616 -630 -644 -658 -671 -685 -698 -711
-724 -736 -748 -760 -772 -784 -795 -806 -817 -828 -838 -848 -858 -868
-877 -886 -895 -904 -912 -920 -928 -935 -942 -949 -955 -962 -968 -973
-979 -984 -989 -993 -997 -1001 -1005 -1008 -1011 -1014 -1016 -1018
-1020 -1021 -1022 -1023 -1023 -1024 -1023 -1023 -1022 -1021 -1020
-1018 -1016 -1014 -1011 -1008 -1005 -1001 -997 -993 -989 -984 -979
-973 -968 -962 -955 -949 -942 -935 -928 -920 -912 -904 -895 -886 -877
-868 -858 -848 -838 -828 -817 -806 -795 -784 -772 -760 -748 -736 -724
-711 -698 -685 -671 -658 -644 -630 -616 -601 -587 -572 -557 -542 -527
-512 -496 -480 -464 -448 -432 -416 -400 -383 -366 -350 -333 -316 -299
-282 -265 -247 -230 -212 -195 -177 -160 -142 -124 -107 -89 -71 -53 -35
-17 /);
# }}}
# _calculate_arc_params {{{
sub _calculate_arc_params {
    my ($start, $end, $width, $height) = @_;

    # GD uses diameters, SVG uses radii
    my $a = $width  / 2;
    my $b = $height / 2;
  
    while ($start < 0 )    { $start += 360; }
    while ($end < 0 )      { $end   += 360; }
    while ($end < $start ) { $end   += 360; }

    my $large = (abs $start - $end > 180) ? 1 : 0;
    my $sweep = 1; # Always CW with GD

    return ($start, $end, $large, $sweep, $a, $b);
}
# }}}
# _calculate_point_coords {{{
sub _calculate_point_coords {
    my ($cx, $cy, $width, $height, $angle) = @_;

    my $x = ( $cosT[$angle % 360] * $width)  / (2 * 1024) + $cx;
    my $y = ( $sinT[$angle % 360] * $height) / (2 * 1024) + $cy;

    return ($x, $y);
}
# }}}

# _flatten_hash {{{
sub _flatten_hash {
    my $hash = shift;

    map {($_=>$hash->{$_})} keys %$hash;
}
# }}}

"true";
