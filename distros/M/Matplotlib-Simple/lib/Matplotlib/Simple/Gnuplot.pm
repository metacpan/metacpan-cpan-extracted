use strict;
use feature 'say';
use warnings FATAL => 'all';

package Matplotlib::Simple::Gnuplot;
# The gnuplot engine: "engine => 'gnuplot'" writes plt's figure as a gnuplot
# script and runs it. Matplotlib::Simple has checked the arguments, and check_engine has
# refused every plot type and keyword not listed below, before render() is
# called.
#
# Everything a figure needs -- bins, densities, quartiles, the mean and spread
# of "wide" runs -- is worked out here in Perl, and the script is given only
# numbers to draw, in datablocks, and text, through gp_str. The script does no
# arithmetic of its own on the caller's data, so what is drawn is what was
# checked.
#
# The defaults are matplotlib's, so that the same call draws the same figure:
# the "tab:" color cycle (rcParams axes.prop_cycle, matplotlib 3.11.2), 10
# bins for hist (rcParams hist.bins), whiskers at 1.5 times the interquartile
# range (rcParams boxplot.whiskers), the quartiles numpy.percentile's
# "linear" method gives, violins from scipy-style gaussian_kde densities with
# Scott's bandwidth, n ** (-1/5), as matplotlib.mlab.GaussianKDE computes
# them, scaled to half of matplotlib's default violin width of 0.5, a 6.4 by
# 4.8 inch figure (rcParams figure.figsize) and 100 dots per inch for a PNG
# (rcParams figure.dpi).
require 5.010;
our $VERSION = 0.3341;
use Scalar::Util 'looks_like_number';
use List::Util qw(max min sum);
use POSIX ();
use Encode ();
use Sys::Hostname ();
BEGIN { require Matplotlib::Simple }
BEGIN {
	no strict 'refs';
	*{$_} = \&{"Matplotlib::Simple::$_"} foreach qw(as_double axis_limits axis_scale bin_counts bool_option
	 cb_limits check_key_order check_numbers check_scatter_lengths check_scatter_values
	 check_wide_runs color_hex colormap_colors creator_note decoded_text double_literal finite_values
	 is_finite is_nan linspace logscale_axes logspace plain_text program_from_env run_script script_handle
	 svg_creator_metadata table_cells);
}
# What this engine draws: plot type => the keywords of %Matplotlib::Simple::opt it reads
# for that type. hexbin and venn_proportional_area are not here: gnuplot has
# no hexagonal binning and no area-proportional Venn layout, and neither is
# drawn rather than drawn as something else.
my @colorbar = ( 'cb_logscale', 'cb_max', 'cb_min', 'cblabel', 'cmap', 'colorbar_on' );
my @bar      = ( 'color', 'key_order', 'label', 'log', 'logscale', 'stacked', 'width', 'xerr', 'yerr' );
my @violin   = ( 'color', 'colors', 'edgecolor', 'key_order', 'logscale', 'medians', 'orientation', 'whiskers' );
our %types = (
	bar           => [@bar],
	barh          => [@bar],
	boxplot       => [ 'color', 'colors', 'key_order', 'logscale', 'orientation', 'showcaps', 'showfliers', 'showmeans' ],
	colored_table => [ @colorbar, 'col_labels', 'default_undefined', 'mirror', 'row_labels', 'show_numbers', 'undef_color' ],
	hist          => [ 'alpha', 'bins', 'color', 'key_order', 'logscale', 'orientation', 'show_legend' ],
	hist2d        => [ @colorbar, 'cmax', 'cmin', 'density', 'key_order', 'logscale', 'show_colorbar', 'vmax', 'vmin', 'xbins', 'xmax', 'xmin', 'ybins', 'ymax', 'ymin' ],
	imshow        => [ @colorbar, 'stringmap', 'vmax', 'vmin' ],
	pie           => [ 'autopct', 'key_order', 'labeldistance', 'pctdistance' ],
	plot          => [ 'key_order', 'logscale', 'show_legend' ],
	scatter       => [ @colorbar, 'color_key', 'key_order', 'keys', 'logscale', 'show_legend' ],
	violin        => [@violin],
	violinplot    => [@violin],
	wide          => [ 'color', 'show_legend' ],
);
our @plot_keywords   = ( 'set_title', 'set_xlabel', 'set_xlim', 'set_xscale', 'set_ylabel', 'set_ylim', 'set_yscale', 'title', 'xlabel', 'xscale', 'ylabel', 'ylim', 'yscale' );
our @figure_keywords = ( 'scale', 'scalex', 'scaley', 'suptitle' );

my $engine = 'gnuplot';
# 1 = style => 'native' (%Matplotlib::Simple::styles): gnuplot's own colors, palette,
# statistics and look; 0 = matplotlib's, as everywhere else in this file. Set
# by render.
my $native = 0;
# matplotlib's figure, in inches, and a PNG's dots per inch; see the header.
my ( $fig_width, $fig_height, $png_dpi ) = ( 6.4, 4.8, 100 );
# The SVG terminal's units are pixels at 100 per inch, as a PNG's, so that one
# figure is laid out the same in both. Both take a line's width in pixels, so
# matplotlib's widths in points are scaled by 100/72 for them, and a font's size
# in a unit of their own, which by eye against matplotlib's 10-point tick labels
# on the same 640 by 480 PNG is 1.1 of a point. The PDF terminal takes points.
# Both set by render.
my ( $px_per_pt, $font_scale );
# Under style => 'native', each terminal's own font, line width and
# background; the size, and "noenhanced", which makes text read as given,
# are kept.
sub pixels {
	# A size in inches as whole pixels, rounded as the ggplot2 engine rounds
	# them. "%d" cut them down, and 4.8 * 3 * 100, which is 1439.9999999999998,
	# made "scale => 3" a PNG of 1920 by 1439, where matplotlib's is 1440.
	return map { int( $_ * $png_dpi + 0.5 ) } @_;
}
my %terminal_of = (    # output_file's extension => how its terminal is set
	svg => sub { my ( $w, $h ) = pixels(@_); return "svg size $w,$h dynamic noenhanced" if $native; sprintf 'svg size %d,%d dynamic font "sans,%.1f" noenhanced linewidth %.2f background "#ffffff"', $w, $h, 10 * $font_scale, $px_per_pt },
	png => sub { my ( $w, $h ) = pixels(@_); return "pngcairo size $w,$h noenhanced" if $native; sprintf 'pngcairo size %d,%d font "sans,%.1f" noenhanced linewidth %.2f background "#ffffff"', $w, $h, 10 * $font_scale, $px_per_pt },
	pdf => sub { my ( $w, $h ) = @_; return sprintf 'pdfcairo size %.4fin,%.4fin noenhanced', $w, $h if $native; sprintf 'pdfcairo size %.4fin,%.4fin font "sans,10" noenhanced', $w, $h },
);
# matplotlib's scatter markers, in the order it cycles through them for sets
# colored by a key, as gnuplot point types: filled where matplotlib's are.
# gnuplot has no left or right triangle, hexagon or thin diamond, so those
# take the nearest shape it has.
my @marker_cycle = ( 7, 5, 9, 13, 11, 1, 2, 3, 9, 11, 15, 7, 13 );    # o s ^ D v P X * < > p h d
# matplotlib's markers are 6 points across (rcParams lines.markersize); set by
# render to the gnuplot point size that draws them so, measured by eye on the
# PNG terminal against matplotlib's own.
my $point_size;
# matplotlib's line width, 1.5 points (rcParams lines.linewidth), as gnuplot's,
# whose width 1 is about 1 point at this size.
my $line_width = 1.5;

# gnuplot's own colors, for style => 'native': "set colorsequence default",
# the eight linetypes gnuplot has used since 5.0, as "show linetype" lists them
# in gnuplot 6.0 patchlevel 0 ("dark-violet" is #9400d3 by "show colornames").
my @gnuplot_colors = ( '#9400d3', '#009e73', '#56b4e9', '#e69f00', '#f0e442', '#0072b2', '#e51e10', '#000000' );

# State of the figure being written: the script, the datablocks waiting to be
# written before the next plot command, their count, the name the caller
# called, the points drawn (for key_place), and the corners of every box drawn
# (for thin_tics).
my ( $fh, @blocks, $n_blocks, $current_sub, @points, @extent );
my %tic_labels;    # axis => the category labels tics() wrote on it, for thin_tics
# The size of one subplot, in inches, when there are several; undef for a
# figure of one plot, whose tics and fonts are left as they are. Set by render.
my ( $panel_w, $panel_h );

sub gp_str {
	# A Perl string as a gnuplot double-quoted string literal. Every label,
	# key and path goes through this. Backslash and double quote are escaped,
	# a newline is \n, and every other control character is left out, since
	# gnuplot has no escape for most of them. The terminals are set
	# "noenhanced", so "@", "&", "^", "_", "{" and "}" are written as they are.
	my ($str) = @_;
	$str = decoded_text( $str // '' );
	$str =~ s/\\/\\\\/g;
	$str =~ s/"/\\"/g;
	$str =~ s/\r?\n/\\n/g;
	$str =~ s/\t/\\t/g;
	$str =~ s/[\x00-\x08\x0b-\x1f\x7f]//g;
	return "\"$str\"";
}
sub gp_num {
	# A number as gnuplot reads it, with NaN for anything not finite: gnuplot
	# draws an infinite value no better than a missing one, and matplotlib
	# leaves both out. A finite one as double_literal writes it.
	my ($n) = @_;
	return 'NaN' if ( not defined $n ) || ( not looks_like_number($n) ) || ( not is_finite($n) );
	return double_literal($n);
}
sub gp_color {
	# A color from color_hex as a gnuplot rgb string. gnuplot's alpha is a
	# transparency, 00 for opaque, written before the red.
	my ($hex) = @_;
	return gp_str($hex) if length $hex == 7;
	return gp_str( sprintf '#%02x%s', 255 - hex substr( $hex, 7, 2 ), substr( $hex, 1, 6 ) );
}
sub color_int {
	# A color from color_hex as the integer "lc rgb variable" reads from a
	# datablock: transparency in the top byte, as in gp_color.
	my ($hex) = @_;
	my $v = hex substr( $hex, 1, 6 );
	$v += ( 255 - hex substr( $hex, 7, 2 ) ) * 2**24 if length $hex == 9;
	return $v;
}
sub with_alpha {
	# A color from color_hex with its alpha set, from 0 to 1.
	my ( $hex, $alpha ) = @_;
	return substr( $hex, 0, 7 ) . sprintf( '%02x', int( $alpha * 255 + 0.5 ) );
}
sub hex_of {
	# color_hex for this engine.
	my ( $color, $what ) = @_;
	return color_hex( $color, $what, $engine, $current_sub );
}
sub cycle_color {
	# The n-th color of matplotlib's default cycle, as "C0" to "C9" name it, or
	# of gnuplot's own linetypes under style => 'native'.
	return $gnuplot_colors[ $_[0] % @gnuplot_colors ] if $native;
	return hex_of( 'C' . ( $_[0] % 10 ), 'the color cycle' );
}
sub next_color {
	# The next color of an axes' cycle. matplotlib keeps two, one for lines and
	# one for bars, wedges and points ("lines" and "patches"); gnuplot moves to
	# the next linetype at every plot clause, whatever it draws, so under
	# style => 'native' the two are one.
	my ( $axes, $kind ) = @_;
	return cycle_color( $axes->{ $native ? 'native' : $kind }++ );
}
sub default_palette_color {
	# gnuplot's default palette at $x from 0 to 1, as "#rrggbb": "rgbformulae
	# 7,5,15", gnuplot's default ("help rgbformulae"), where formula 7 is
	# sqrt(x), 5 is x^3 and 15 is sin(360x), in degrees ("show palette
	# rgbformulae", gnuplot 6.0), each clipped to 0 .. 1.
	my ($x) = @_;
	my @c = ( sqrt($x), $x**3, sin( 8 * atan2( 1, 1 ) * $x ) );
	return '#' . join( '', map { sprintf '%02x', int( 255 * ( $_ < 0 ? 0 : $_ > 1 ? 1 : $_ ) + 0.5 ) } @c );
}
sub ps {
	# The point size of a points clause, followed by a space: matplotlib's
	# markers, or nothing, gnuplot's default, under style => 'native'.
	return $native ? '' : "ps $point_size ";
}
sub lw {
	# A line's width in a clause, followed by a space: matplotlib's 1.5 points,
	# or nothing, gnuplot's default, under style => 'native'.
	return $native ? '' : "lw $line_width ";
}
sub datablock {
	# Name a datablock holding these rows of numbers, to be written ahead of
	# the next plot command; undef if there are no rows, which the callers
	# leave out of the plot, since gnuplot refuses to plot an empty one.
	my ($rows) = @_;
	return undef if scalar @{$rows} == 0;
	my $name = '$d' . $n_blocks++;
	# Where the data lie, for choosing a corner for the legend (key_place):
	# each row's x and y and, for a boxxyerror row, its far corners.
	foreach my $row ( @{$rows} ) {
		push @points, [ @{$row}[ 0, 1 ] ];
		push @points, [ $row->[2], $row->[5] ], [ $row->[3], $row->[5] ] if scalar @{$row} >= 6;
		# And where the data reach, for thin_tics: a boxxyerror row's corners
		# as well, since a bar's foot, unlike its top, is not a point drawn.
		push @extent, [ @{$row}[ 0, 1 ] ];
		push @extent, [ @{$row}[ 2, 4 ] ], [ @{$row}[ 3, 5 ] ] if scalar @{$row} >= 6;
	}
	push @blocks, "$name << EOD\n" . join( '', map { join( ' ', map { gp_num($_) } @{$_} ) . "\n" } @{$rows} ) . "EOD\n";
	return $name;
}
sub key_title {
	# A legend entry for a plot clause, or none.
	my ($label) = @_;
	return defined $label ? 'title ' . gp_str($label) : 'notitle';
}
sub tics {
	# A "set xtics (...)" list of labels at positions.
	my ( $axis, $labels, $positions ) = @_;
	$tic_labels{$axis} = [ map { decoded_text($_) } @{$labels} ];    # for thin_tics
	return "set ${axis}tics (" . join( ', ', map { gp_str( $labels->[$_] ) . ' ' . gp_num( $positions->[$_] ) } 0 .. $#{$labels} ) . ')';
}
sub format_commas {
	# A count with commas between thousands, as matplotlib's boxplot and
	# violin tick labels give it.
	my $n = reverse "$_[0]";
	$n =~ s/(\d{3})(?=\d)/$1,/g;
	return scalar reverse $n;
}
sub key_order_of {
	# The keys of a plot's "data" in the order drawn: "key_order", or sorted.
	my ( $plot, $data ) = @_;
	return check_key_order({ keys => $plot->{key_order}, data => $data, option => 'key_order', sub => $current_sub }) if defined $plot->{key_order};
	return sort keys %{$data};
}
sub orientation_of {
	# "vertical" or "horizontal", vertical by default.
	my ($plot) = @_;
	my $o = $plot->{orientation} // 'vertical';
	die "$current_sub needs either \"horizontal\" or \"vertical\", not \"$o\"" if ( ref $o ) || ( $o !~ m/^(?:horizontal|vertical)$/ );
	return $o;
}
sub percentile {
	# numpy.percentile's default ("linear") of already-sorted values.
	my ( $sorted, $p ) = @_;
	my $i    = ( $p / 100 ) * $#{$sorted};
	my $lo   = POSIX::floor($i);
	my $frac = $i - $lo;
	return $sorted->[$lo] if $frac == 0;
	return $sorted->[$lo] + $frac * ( $sorted->[ $lo + 1 ] - $sorted->[$lo] );
}
sub palette {
	# The commands that color by a colormap from $lo to $hi (either undef to
	# take it from the data), on a log scale or not, with or without a
	# colorbar, labelled or not.
	# An undefined cmap is gnuplot's own palette (default_cmap).
	my ($args) = @_;
	my @set;
	if ( defined $args->{cmap} ) {
		my @colors = colormap_colors( $args->{cmap}, $engine, $current_sub );
		push @set, 'set palette defined (' . join( ', ', map { "$_ " . gp_str( $colors[$_] ) } 0 .. $#colors ) . ')';
		push @set, 'set palette maxcolors 0';
	} else {
		push @set, 'set palette rgbformulae 7,5,15', 'set palette maxcolors 0';
	}
	push @set, $args->{log} ? 'set logscale cb' : 'unset logscale cb';
	push @set, 'set cbrange [' . ( defined $args->{lo} ? gp_num( $args->{lo} ) : '*' ) . ':' . ( defined $args->{hi} ? gp_num( $args->{hi} ) : '*' ) . ']';
	push @set, $args->{colorbar} ? 'set colorbox' : 'unset colorbox';
	push @set, 'set cblabel ' . gp_str( $args->{label} ) if $args->{colorbar} && defined $args->{label};
	# A colorbar as tall as a small subplot holds fewer labels than gnuplot
	# gives it, which ran into each other in a 2 by 2 grid.
	if ( $args->{colorbar} && ( not $args->{log} ) && ( defined $panel_h ) && ( defined $args->{lo} ) && ( defined $args->{hi} ) ) {
		my $step = tick_step( $args->{lo}, $args->{hi}, tick_bins( plot_length('y'), 2 ) );
		push @set, 'set cbtics ' . gp_num($step) if defined $step;
	}
	return @set;
}
sub palette_at {
	# The color a palette() of this colormap gives $x from 0 to 1: between
	# the two nearest of its colors, or gnuplot's own palette for undef.
	my ( $cmap, $x ) = @_;
	return default_palette_color($x) unless defined $cmap;
	my @colors = colormap_colors( $cmap, $engine, $current_sub );
	my $pos = $x * $#colors;
	my $i = ( $pos >= $#colors ) ? $#colors - 1 : POSIX::floor($pos);
	my $frac = $pos - $i;
	my @a = map { hex substr( $colors[$i], $_, 2 ) } ( 1, 3, 5 );
	my @b = map { hex substr( $colors[ $i + 1 ], $_, 2 ) } ( 1, 3, 5 );
	return '#' . join( '', map { sprintf '%02x', int( $a[$_] + $frac * ( $b[$_] - $a[$_] ) + 0.5 ) } 0 .. 2 );
}
sub default_cmap {
	# The colormap a type takes when the caller gives none: matplotlib's
	# default for it, or undef, gnuplot's own palette, under style => 'native'.
	my ( $plot, $matplotlib_default ) = @_;
	return $plot->{cmap} if defined $plot->{cmap};
	return $native ? undef : $matplotlib_default;
}
# What thin_tics and palette need to place tics the way matplotlib's default
# locator, MaxNLocator(nbins = 'auto', steps = [1, 2, 2.5, 5, 10]), places them
# (matplotlib 3.11.2, ticker.py and axis.py): as many intervals as fit one
# tick label every 3 label heights along x, or every 2 along y
# (Axis.get_tick_space), at most 9, each a step of 1, 2, 2.5 or 5 times a power
# of 10.
sub plot_length {
	# The length in points of a small subplot's axes along x or y: the
	# subplot, less the margins gnuplot gives its tic labels, axis label and
	# title, which are about 0.8 inch across and 0.7 inch down at this font
	# size, as measured on the PNG terminal.
	my ($axis) = @_;
	return 72 * ( ( $axis eq 'x' ) ? $panel_w - 0.8 : $panel_h - 0.7 );
}
sub tick_bins {
	# How many intervals of tics fit an axis this many points long, with a
	# label every $per label heights; at least 1, at most 9.
	my ( $length, $per ) = @_;
	my $n = int( $length / ( 10 * $per ) );    # 10: matplotlib's tick labels are 10 points (rcParams xtick.labelsize)
	return $n < 1 ? 1 : $n > 9 ? 9 : $n;
}
sub tick_step {
	# The least step of 1, 2, 2.5, 5 or 10 times a power of 10 that covers
	# $lo .. $hi in at most $bins intervals; undef for an empty range.
	my ( $lo, $hi, $bins ) = @_;
	return undef unless ( defined $lo ) && ( defined $hi ) && is_finite($lo) && is_finite($hi) && ( $hi > $lo );
	my $raw = ( $hi - $lo ) / $bins;
	my $power = 10**POSIX::floor( log($raw) / log(10) );
	foreach my $mult ( 1, 2, 2.5, 5, 10 ) {
		my $step = $mult * $power;
		# the intervals a step this size cuts the range into, at its multiples
		my $n = POSIX::ceil( $hi / $step - 1e-9 ) - POSIX::floor( $lo / $step + 1e-9 );
		return $step if $n <= $bins;
	}
	return 10 * $power;
}
sub color_scale {
	# The ends of a color scale from "vmin" and "vmax" (or "cb_min" and
	# "cb_max", which cb_limits has turned into them) and from the values,
	# checked as matplotlib's norm_args checks them: a log scale must start
	# above 0.
	my ( $plot, $values, $log ) = @_;
	cb_limits( $plot, $current_sub );
	foreach my $v ( grep { defined $plot->{$_} } ( 'vmin', 'vmax' ) ) {
		check_numbers( [ $plot->{$v} ], "\"$v\"", $current_sub );
	}
	my ( $lo, $hi ) = ( $plot->{vmin}, $plot->{vmax} );
	my @finite = finite_values( @{$values} );
	if ($log) {
		$lo = $lo // min( grep { $_ > 0 } @finite );
		die "\"cb_logscale\" needs a color value above 0 to start the scale at, or a \"vmin\" or \"cb_min\" above 0, and $current_sub has neither" unless defined $lo;
		die "\"cb_logscale\" cannot start at $lo in $current_sub: a log scale needs a minimum above 0" if $lo <= 0;
	} else {
		$lo = $lo // min(@finite);
	}
	$hi = $hi // max(@finite);
	return ( $lo, $hi );
}
sub box_rows {
	# A bar, bin or box as the row of a boxxyerror datablock -- x, y, x low,
	# x high, y low, y high -- from its position across, its extent across,
	# and where it starts and ends along, laid across or along x.
	my ( $at, $half, $from, $to, $horizontal ) = @_;
	return $horizontal ? [ ( $from + $to ) / 2, $at, $from, $to, $at - $half, $at + $half ] : [ $at, ( $from + $to ) / 2, $at - $half, $at + $half, $from, $to ];
}
sub boxes_clause {
	# A plot clause drawing boxxyerror rows filled in one color.
	my ( $block, $color, $title, $border ) = @_;
	return () unless defined $block;
	# A color's alpha is the density of a transparent fill: given in the
	# color itself, the fill was drawn opaque.
	my $fill = ( length $color == 9 ) ? sprintf( 'transparent solid %.3f', hex( substr $color, 7, 2 ) / 255 ) : 'solid 1.0';
	return "$block using 1:2:3:4:5:6 with boxxyerror fs $fill " . ( $border ? 'border lc rgb "black"' : 'noborder' ) . ' lc rgb ' . gp_str( substr $color, 0, 7 ) . " $title";
}

sub log_base {
	# Where a bar on a log axis starts, having no 0 to start at: the power of
	# 10 below the least of the tops, strictly, so that the least bar has a
	# height; 0.1 if there is none above 0.
	my $least = ( scalar @_ ) ? min(@_) : 1;
	return 10**( POSIX::ceil( log($least) / log(10) - 1e-12 ) - 1 );    # 1e-12: so that log10(1000) read as 2.9999999999999996 is 3
}
sub log_bar_range {
	# The range of a bar plot's log axis, as ( $bottom, $top ), and so where
	# its bars start: matplotlib's autoscaling of the values above 0 -- the
	# bars' tops, and the feet of stacked ones -- with its 5% margin
	# (rcParams axes.ymargin) either side taken in decades, and a single value
	# widened by a decade each way first, as LogLocator.nonsingular widens it.
	# matplotlib draws a bar from 0, cut off where the axis starts; a bar of
	# the least value is a sliver, not nothing.
	#
	# Under style => 'native' the bars start at log_base and gnuplot chooses the
	# range, out to the decades on either side: ( log_base, undef ).
	my @v = grep { $_ > 0 } @_;
	return ( log_base(@v), undef ) if $native;
	return ( 0.1, 10 ) if scalar @v == 0;    # nothing above 0: one decade either side of 1, where matplotlib leaves an empty log axis
	my ( $lo, $hi ) = map { log($_) / log(10) } ( min(@v), max(@v) );
	( $lo, $hi ) = ( $lo - 1, $hi + 1 ) if $lo == $hi;
	my $margin = 0.05 * ( $hi - $lo );
	return ( 10**( $lo - $margin ), 10**( $hi + $margin ) );
}
sub category_range {
	# The axis of boxes or violins at 1 .. n, from half a category below the
	# first to half above the last, as matplotlib sets it.
	# Under style => 'native', nothing: gnuplot's own autoscaling.
	my ( $g, $n, $horizontal ) = @_;
	return if $native;
	my $axis = $horizontal ? 'y' : 'x';
	push @{ $g->{set} }, "set ${axis}range [0.5:" . gp_num( $n + 0.5 ) . ']';
	push @{ $g->{no_margin} }, $horizontal ? ( 'top', 'bottom' ) : ( 'left', 'right' );
}
sub key_place {
	# The corner of the axes for the legend that covers the fewest data,
	# trying them in the order matplotlib's "best" does: upper right, upper
	# left, lower left, lower right. Each corner is the third of the axes'
	# width and height nearest it.
	my @p = grep { is_finite( $_->[0] ) && is_finite( $_->[1] ) } map { [ map { looks_like_number($_) ? $_ : 'nan' } @{$_} ] } @points;
	return 'top right' if scalar @p == 0;
	my ( $x0, $x1 ) = ( min( map { $_->[0] } @p ), max( map { $_->[0] } @p ) );
	my ( $y0, $y1 ) = ( min( map { $_->[1] } @p ), max( map { $_->[1] } @p ) );
	my ( $w, $h ) = ( ( $x1 - $x0 ) || 1, ( $y1 - $y0 ) || 1 );
	my @corners = ( [ 'top right', 1, 1 ], [ 'top left', 0, 1 ], [ 'bottom left', 0, 0 ], [ 'bottom right', 1, 0 ] );
	my ( $best, $fewest );
	foreach my $corner (@corners) {
		my ( $name, $right, $top ) = @{$corner};
		my $n = grep {
			my $fx = ( $_->[0] - $x0 ) / $w;
			my $fy = ( $_->[1] - $y0 ) / $h;
			( $right ? $fx >= 2 / 3 : $fx <= 1 / 3 ) && ( $top ? $fy >= 2 / 3 : $fy <= 1 / 3 );
		} @p;
		( $best, $fewest ) = ( $name, $n ) if ( not defined $fewest ) || ( $n < $fewest );
	}
	return $best;
}
sub draw_bar {
	# bar and barh: one bar per key, or one group of bars per key, side by
	# side or stacked, as barplot_helper draws them.
	my ( $plot, $axes ) = @_;
	my $horizontal = ( $plot->{plot_type} eq 'barh' ) ? 1 : 0;
	my $data = $plot->{data};
	my %ref_counts;
	$ref_counts{ ref $data->{$_} }++ foreach keys %{$data};
	if ( scalar keys %ref_counts > 1 ) {
		die "different kinds of data were entered to $current_sub which should be simple hash or hash of arrays.";
	}
	my $form = defined $ref_counts{''} ? 'simple' : ( defined $ref_counts{ARRAY} || defined $ref_counts{HASH} ) ? 'grouped' : die "$current_sub: \"data\" is a hash of numbers, of arrays, or of hashes for $plot->{plot_type}";
	my ( @series, $colors );
	if ( defined $ref_counts{HASH} ) {
		# The inner keys are the series, as in barplot_helper.
		my %inner;
		$inner{$_}++ foreach map { keys %{$_} } values %{$data};
		@series = sort { lc $a cmp lc $b || $a cmp $b } keys %inner;
		$data = { map { my $k = $_; $k => [ @{ $data->{$k} }{@series} ] } keys %{$data} };
		if ( ref $plot->{color} eq 'HASH' ) {
			my @uncolored = grep { not defined $plot->{color}{$_} } @series;
			die 'the series ' . join( ', ', map { "\"$_\"" } @uncolored ) . " have no color defined in \"color\" in $current_sub" if scalar @uncolored;
			$colors = [ @{ $plot->{color} }{@series} ];
		}
	} elsif ( $form eq 'grouped' ) {
		if ( ref $plot->{color} eq 'HASH' ) {
			die "$current_sub: \"color\" is a HASH, but this data is a hash of arrays, whose series have no names to key it by: give one color per series as an array, e.g. color => ['red','blue']";
		}
		if ( defined $plot->{label} ) {
			die "\"label\" is an array of one name per series in $current_sub" unless ref $plot->{label} eq 'ARRAY';
			@series = @{ $plot->{label} };
		}
	}
	$colors = $plot->{color} if ( not defined $colors ) && ( ref $plot->{color} eq 'ARRAY' );
	my $stacked = bool_option( $plot->{stacked}, 'stacked', $current_sub );
	if ( defined $plot->{width} ) {
		die "\"width\" is one number for every bar in $current_sub, not a " . ref( $plot->{width} ) . ' reference' if ref $plot->{width};
		check_numbers( [ $plot->{width} ], '"width"', $current_sub );
		die "\"width\" must be a finite number for $current_sub, not \"$plot->{width}\"" unless is_finite( $plot->{width} );
	}
	if ( ( $form eq 'grouped' ) && ( defined $plot->{width} ) && ( not $stacked ) ) {
		# Left out, as the matplotlib engine leaves it: it was said to be
		# ignored, and then divided among the series all the same.
		say STDERR 'grouped, non-stacked barplots ignore width settings';
		delete $plot->{width};
	}
	my @keys = key_order_of( $plot, $data );
	foreach my $key (@keys) {
		my @values = ( $form eq 'simple' ) ? ( $data->{$key} ) : @{ $data->{$key} };
		my @bad = grep { ( defined $_ ) && ( not looks_like_number($_) ) } @values;
		die 'the values "' . join( '", "', @bad ) . "\" of \"$key\" are not numbers, which $current_sub needs" if scalar @bad;
		die "\"$key\" has an undefined value, which $current_sub cannot plot" if ( $form eq 'simple' ) && ( not defined $data->{$key} );
	}
	my $log = ( bool_option( $plot->{log}, 'log', $current_sub ) || $plot->{logscale} ) ? 1 : 0;    # "logscale" takes Perl truth, as documented
	my $value_axis = $horizontal ? 'x' : 'y';
	my %g = ( set => [], plot => [] );
	push @{ $g{set} }, "set logscale $value_axis" if $log;
	my ( @bars, @tic_at );
	if ( $form eq 'simple' ) {
		my @v = map { 0 + $data->{$_} } @keys;
		my $base = 0;
		if ($log) {
			( $base, my $top ) = log_bar_range(@v);
			push @{ $g{set} }, "set ${value_axis}range [" . gp_num($base) . ':' . gp_num($top) . ']' if defined $top;
		}
		my $half = ( $plot->{width} // 0.8 ) / 2;
		my @colors;
		if ( ref $plot->{color} eq 'HASH' ) {
			my @uncolored = grep { not defined $plot->{color}{$_} } @keys;
			die 'the keys ' . join( ', ', map { "\"$_\"" } @uncolored ) . ' were not defined in the colors hash' if scalar @uncolored;
			@colors = map { hex_of( $plot->{color}{$_}, "\"color\" of \"$_\"" ) } @keys;
		} elsif ( ref $plot->{color} eq 'ARRAY' ) {
			die "\"color\" is an empty array in $current_sub" if scalar @{ $plot->{color} } == 0;
			@colors = map { hex_of( $plot->{color}[ $_ % @{ $plot->{color} } ], '"color"' ) } 0 .. $#keys;    # matplotlib cycles a short list
		} else {
			my $one = defined $plot->{color} ? hex_of( $plot->{color}, '"color"' ) : next_color( $axes, 'patches' );
			@colors = ($one) x @keys;
		}
		my @rows = map { [ @{ box_rows( $_, $half, $base, $v[$_], $horizontal ) }, color_int( $colors[$_] ) ] } grep { ( not $log ) || ( $v[$_] > 0 ) } 0 .. $#keys;
		my $block = datablock( \@rows );
		push @{ $g{plot} }, "$block using 1:2:3:4:5:6:7 with boxxyerror fs solid 1.0 noborder lc rgb variable notitle" if defined $block;
		@tic_at = 0 .. $#keys;
		push @{ $g{plot} }, error_bars( $plot, \@keys, \@v, $horizontal );
	} else {
		my $n_series = max( map { scalar @{ $data->{$_} } } @keys );
		my %lengths  = map { scalar @{ $data->{$_} } => 1 } @keys;
		die "the keys of a grouped $plot->{plot_type} hold different numbers of values; every key needs the same number" if scalar keys %lengths > 1;
		die "every key of \"data\" holds an empty array, so $current_sub has no bars to draw" if $n_series == 0;
		foreach my $err ( grep { defined $plot->{$_} } ( 'xerr', 'yerr' ) ) {
			die "the gnuplot engine draws \"$err\" only for a bar plot of one bar per key, and this one is grouped";
		}
		my $width = $plot->{width} // 0.8;
		$width /= ( $n_series + 1 ) unless $stacked;
		my @bottom = (0) x @keys;
		my @shift  = (0) x @keys;
		my @drawn;    # [ \@rows, color, label ] of each series
		foreach my $s ( 0 .. $n_series - 1 ) {
			my $color;
			if ( ( defined $colors ) && ( defined $colors->[$s] ) ) {
				$color = hex_of( $colors->[$s], '"color"' );
			} elsif ( ( defined $plot->{color} ) && ( not ref $plot->{color} ) ) {
				$color = hex_of( $plot->{color}, '"color"' );
			} else {
				$color = next_color( $axes, 'patches' );
			}
			my @rows;
			foreach my $i ( 0 .. $#keys ) {
				my $v = $data->{ $keys[$i] }[$s] // 0;    # a missing value is no bar, as in barplot_helper
				my $from = $stacked ? $bottom[$i] : 0;
				push @rows, box_rows( $i + $shift[$i], $width / 2, $from, $from + $v, $horizontal );
				$bottom[$i] += $v if $stacked;
				$shift[$i] += $width unless $stacked;
			}
			push @drawn, [ \@rows, $color, $series[$s] ];
		}
		if ($log) {
			# A log axis has no 0, so a bar starting there starts at the foot of
			# the axis (log_bar_range), and a bar not above 0 is left out.
			my ( $from, $to ) = $horizontal ? ( 2, 3 ) : ( 4, 5 );
			my ( $base, $top ) = log_bar_range( map { @{$_}[ $from, $to ] } map { @{ $_->[0] } } @drawn );
			push @{ $g{set} }, "set ${value_axis}range [" . gp_num($base) . ':' . gp_num($top) . ']' if defined $top;
			foreach my $series (@drawn) {
				@{ $series->[0] } = grep { $_->[$to] > 0 } @{ $series->[0] };
				$_->[$from] = $base foreach grep { $_->[$from] <= 0 } @{ $series->[0] };
			}
		}
		foreach my $series (@drawn) {
			push @{ $g{plot} }, boxes_clause( datablock( $series->[0] ), $series->[1], key_title( $series->[2] ) );
			$g{legend} = 1 if defined $series->[2];
		}
		@tic_at = map { $stacked ? $_ : $_ + ( $n_series - 1 ) * $width / 2 } 0 .. $#keys;
	}
	push @{ $g{set} }, tics( $horizontal ? 'y' : 'x', \@keys, \@tic_at );
	$g{categories} = $horizontal ? 'y' : 'x';
	# matplotlib keeps the bars' base on the axis, with no margin below 0.
	$g{no_margin} = [ $horizontal ? 'left' : 'bottom' ] unless $log;
	return \%g;
}
sub error_bars {
	# The error bars of a bar plot of one bar per key: "yerr" on a bar, "xerr"
	# on a barh, in any of the shapes barplot_helper takes.
	my ( $plot, $keys, $values, $horizontal ) = @_;
	my $want = $horizontal ? 'xerr' : 'yerr';
	my $other = $horizontal ? 'yerr' : 'xerr';
	die "the gnuplot engine draws \"$other\" on " . ( $horizontal ? 'a bar plot' : 'a barh plot' ) . " but not on $plot->{plot_type}; give \"$want\"" if defined $plot->{$other};
	return () unless defined $plot->{$want};
	my $err = $plot->{$want};
	my $n = scalar @{$keys};
	my ( @low, @high );
	if ( ref $err eq '' ) {
		check_numbers( [$err], "\"$want\"", $current_sub );
		@low = @high = ($err) x $n;
	} elsif ( ref $err eq 'ARRAY' ) {
		my @rows = ( grep { ref } @{$err} ) ? @{$err} : ($err);
		die "\"$want\" is an array of one error per bar, or of two such arrays (lower, then upper), in $current_sub" if ( scalar @rows > 2 ) || ( grep { ref $_ ne 'ARRAY' } @rows );
		foreach my $row (@rows) {
			die "\"$want\" has " . scalar( @{$row} ) . " values in a row, but $current_sub has $n bars" if scalar @{$row} != $n;
			check_numbers( $row, "\"$want\"", $current_sub );
		}
		@low  = @{ $rows[0] };
		@high = @{ $rows[-1] };
	} elsif ( ref $err eq 'HASH' ) {
		foreach my $key ( @{$keys} ) {
			my $e = $err->{$key};
			die "\"$key\" has no \"$want\" in $current_sub" unless defined $e;
			my @pair = ( ref $e eq 'ARRAY' ) ? @{$e} : ( ref $e eq '' ) ? ( $e, $e ) : ();
			die "$want/$key should be one number, or exactly 2 items: low and high error bars" if scalar @pair != 2;
			check_numbers( \@pair, "\"$want\" of \"$key\"", $current_sub );
			push @low,  $pair[0];
			push @high, $pair[1];
		}
	} else {
		die ref($err) . " for $want isn't acceptable";
	}
	my @rows = map { $horizontal ? [ $values->[$_], $_, $values->[$_] - $low[$_], $values->[$_] + $high[$_] ] : [ $_, $values->[$_], $values->[$_] - $low[$_], $values->[$_] + $high[$_] ] } 0 .. $n - 1;
	my $block = datablock( \@rows );
	return ( "$block using 1:2:3:4 with " . ( $horizontal ? 'xerrorbars' : 'yerrorbars' ) . ' lc rgb "black" lw 1.5 pt 0 notitle' );
}
sub sets_of {
	# The sets of a boxplot or violin, an array being one set with no name.
	my ($plot) = @_;
	return ( ref $plot->{data} eq 'ARRAY' ) ? { '' => $plot->{data} } : $plot->{data};
}
sub draw_boxplot {
	# Boxes from the quartiles, whiskers to the furthest value within 1.5
	# interquartile ranges, the values beyond them, the median and the mean,
	# as matplotlib's boxplot draws them with this module's defaults.
	my ( $plot, $axes ) = @_;
	return draw_boxplot_native( $plot, $axes ) if $native;
	my $horizontal = ( orientation_of($plot) eq 'horizontal' ) ? 1 : 0;
	my $sets = sets_of($plot);
	my @keys = key_order_of( $plot, $sets );
	my %show = map { $_ => bool_option( $plot->{$_} // 1, $_, $current_sub ) } ( 'showcaps', 'showfliers', 'showmeans' );
	if ( ref $plot->{color} ) {
		die "\"color\" is one color for every box in $current_sub, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	my @face;
	if ( defined $plot->{colors} ) {
		die "\"colors\" is a hash of one color per key in $current_sub" unless ref $plot->{colors} eq 'HASH';
		my @bad = grep { not defined $plot->{colors}{$_} } sort keys %{$sets};
		die 'the data keys ' . join( ', ', map { "\"$_\"" } @bad ) . ' have no defined color' if scalar @bad;
		@face = map { hex_of( $plot->{colors}{$_}, "\"colors\" of \"$_\"" ) } @keys;
	} else {
		@face = ( defined $plot->{color} ? hex_of( $plot->{color}, '"color"' ) : cycle_color(0) ) x @keys;
	}
	my %g = ( set => [], plot => [] );
	push @{ $g{set} }, "set logscale $_" foreach logscale_axes( $plot->{logscale}, $current_sub );
	my ( @boxes, @medians, @whiskers, @caps, @fliers, @means, @labels );
	# Half of bxp's default width, 0.15 of the span of the positions, kept
	# between 0.15 and 0.5 (Axes.bxp in matplotlib 3.11.2); its caps are half
	# as wide as the box. It was 0.5 for any number of boxes, where matplotlib
	# draws one box or two 0.15 wide, and three 0.3 wide.
	my $half = max( 0.15, min( 0.5, 0.15 * $#keys ) ) / 2;
	foreach my $i ( 0 .. $#keys ) {
		my $at = $i + 1;
		my @v = grep { ( defined ) && ( not is_nan($_) ) } @{ $sets->{ $keys[$i] } };
		my @bad = grep { not looks_like_number($_) } @v;
		die "$keys[$i] has non-numeric values" if scalar @bad;
		push @labels, "$keys[$i] (" . format_commas( scalar @v ) . ')';
		next if scalar @v == 0;
		my @s = sort { $a <=> $b } @v;
		my ( $q1, $med, $q3 ) = map { percentile( \@s, $_ ) } ( 25, 50, 75 );
		my $iqr = $q3 - $q1;
		my ($lo) = grep { $_ >= $q1 - 1.5 * $iqr } @s;
		my ($hi) = reverse grep { $_ <= $q3 + 1.5 * $iqr } @s;
		push @boxes, [ @{ box_rows( $at, $half, $q1, $q3, $horizontal ) }, color_int( $face[$i] ) ];
		my $seg = sub { my ( $a1, $b1, $a2, $b2 ) = @_; return $horizontal ? [ $b1, $a1, $b2 - $b1, $a2 - $a1 ] : [ $a1, $b1, $a2 - $a1, $b2 - $b1 ] };
		push @medians, $seg->( $at - $half, $med, $at + $half, $med );
		push @whiskers, $seg->( $at, $q1, $at, $lo ), $seg->( $at, $q3, $at, $hi );
		push @caps, $seg->( $at - $half / 2, $lo, $at + $half / 2, $lo ), $seg->( $at - $half / 2, $hi, $at + $half / 2, $hi ) if $show{showcaps};
		push @fliers, map { $horizontal ? [ $_, $at ] : [ $at, $_ ] } grep { ( $_ < $lo ) || ( $_ > $hi ) } @s if $show{showfliers};
		my $mean = sum(@s) / @s;
		push @means, $horizontal ? [ $mean, $at ] : [ $at, $mean ] if $show{showmeans};
	}
	my $block = datablock( \@boxes );
	push @{ $g{plot} }, "$block using 1:2:3:4:5:6:7 with boxxyerror fs solid 1.0 border lc rgb \"black\" lc rgb variable notitle" if defined $block;
	foreach my $lines ( [ \@whiskers, 'black' ], [ \@caps, 'black' ], [ \@medians, cycle_color(1) ] ) {
		my $b = datablock( $lines->[0] );
		push @{ $g{plot} }, "$b using 1:2:3:4 with vectors nohead lc rgb " . gp_color( $lines->[1] =~ m/^#/ ? $lines->[1] : hex_of( $lines->[1], 'a line' ) ) . ' lw 1 notitle' if defined $b;
	}
	my $b = datablock( \@fliers );
	push @{ $g{plot} }, "$b using 1:2 with points pt 6 ps $point_size lc rgb \"black\" notitle" if defined $b;
	$b = datablock( \@means );
	push @{ $g{plot} }, "$b using 1:2 with points pt 9 ps $point_size lc rgb " . gp_color( cycle_color(2) ) . ' notitle' if defined $b;
	push @{ $g{set} }, tics( $horizontal ? 'y' : 'x', \@labels, [ 1 .. scalar @keys ] );
	$g{categories} = $horizontal ? 'y' : 'x';
	category_range( \%g, scalar @keys, $horizontal );
	return \%g;
}
sub kde {
	# Gaussian kernel density of sorted values at 100 points from the least to
	# the greatest, with Scott's bandwidth factor, n ** (-1/5), times the
	# standard deviation with n - 1 below the line: matplotlib.mlab.GaussianKDE,
	# which violinplot uses, evaluated as violin_stats does.
	my ($s) = @_;
	my $n    = scalar @{$s};
	my $mean = sum( @{$s} ) / $n;
	my $sd   = sqrt( sum( map { ( $_ - $mean )**2 } @{$s} ) / ( $n - 1 ) );
	my $h    = $sd * $n**( -1 / 5 );
	my ( $lo, $hi ) = ( $s->[0], $s->[-1] );
	my $norm = 1 / ( $n * $h * sqrt( 8 * atan2( 1, 1 ) ) );
	my @at = linspace( $lo, $hi, 100 );    # violin_stats's np.linspace(min, max, 100)
	return ( \@at, [ map { my $y = $_; $norm * sum( map { exp( -0.5 * ( ( $y - $_ ) / $h )**2 ) } @{$s} ) } @at ] );
}
sub draw_violin {
	# Violins as matplotlib's violinplot draws them here: the density, its
	# extremes and median, the quartile box and whiskers, and the mean.
	my ( $plot, $axes ) = @_;
	return draw_violin_native( $plot, $axes ) if $native;
	my $horizontal = ( orientation_of($plot) eq 'horizontal' ) ? 1 : 0;
	my $sets = sets_of($plot);
	my @keys = key_order_of( $plot, $sets );
	my $medians  = bool_option( $plot->{medians}  // 1, 'medians',  $current_sub );
	my $whiskers = bool_option( $plot->{whiskers} // 1, 'whiskers', $current_sub );
	if ( ref $plot->{color} ) {
		die "\"color\" is one color for every violin in $current_sub, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	my $edge = hex_of( $plot->{edgecolor} // 'black', '"edgecolor"' );
	my @face;
	if ( defined $plot->{colors} ) {
		die "\"colors\" is a hash of one color per key in $current_sub" unless ref $plot->{colors} eq 'HASH';
		my @bad = grep { not defined $plot->{colors}{$_} } sort keys %{$sets};
		die 'the data keys ' . join( ', ', map { "\"$_\"" } @bad ) . ' have no defined color' if scalar @bad;
		@face = map { hex_of( $plot->{colors}{$_}, "\"colors\" of \"$_\"" ) } @keys;
	} else {
		@face = ( defined $plot->{color} ? hex_of( $plot->{color}, '"color"' ) : cycle_color(0) ) x @keys;
	}
	my %g = ( set => [], plot => [] );
	push @{ $g{set} }, "set logscale $_" foreach logscale_axes( $plot->{logscale}, $current_sub );
	my $xy = sub { my ( $at, $v ) = @_; return $horizontal ? ( $v, $at ) : ( $at, $v ) };
	my ( @lines, @quartiles, @whisk, @means, @labels );
	foreach my $i ( 0 .. $#keys ) {
		my $key = $keys[$i];
		my $at = $i + 1;
		my @v = grep { ( defined ) && looks_like_number($_) && ( not is_nan($_) ) } @{ $sets->{$key} };
		die "\"$key\" has no numeric values for $current_sub to plot (" . scalar( @{ $sets->{$key} } ) . ' value(s) given, all undefined, NaN or non-numeric)' if scalar @v == 0;
		my @inf = grep { not is_finite($_) } @v;
		die "\"$key\" has infinite values, which $current_sub cannot draw a density for" if scalar @inf;
		my @s = sort { $a <=> $b } @v;
		die "\"$key\" has no spread -- every value is $s[0] -- so $current_sub has no density to draw" if $s[0] == $s[-1];
		push @labels, "$key (" . format_commas( scalar @s ) . ')';
		my ( $y, $d ) = kde( \@s );
		my $peak = max( @{$d} );
		my @w = map { 0.25 * $_ / $peak } @{$d};    # half of matplotlib's width of 0.5 at the peak
		my @outline = ( ( map { [ $xy->( $at - $w[$_], $y->[$_] ) ] } 0 .. 99 ), ( map { [ $xy->( $at + $w[$_], $y->[$_] ) ] } reverse 0 .. 99 ) );
		push @outline, $outline[0];
		my $body = datablock( \@outline );
		push @{ $g{plot} }, "$body using 1:2 with filledcurves closed fs transparent solid 0.3 noborder lc rgb " . gp_color( substr( $face[$i], 0, 7 ) ) . ' notitle';
		push @{ $g{plot} }, "$body using 1:2 with lines lc rgb " . gp_color( with_alpha( $edge, 0.3 ) ) . ' lw 1 notitle';    # the edge takes the body's alpha, as in matplotlib
		my $seg = sub { my ( $a1, $v1, $a2, $v2 ) = @_; my @p = $xy->( $a1, $v1 ); my @q = $xy->( $a2, $v2 ); return [ @p, $q[0] - $p[0], $q[1] - $p[1] ] };
		push @lines, $seg->( $at - 0.125, $s[0], $at + 0.125, $s[0] ), $seg->( $at - 0.125, $s[-1], $at + 0.125, $s[-1] ), $seg->( $at, $s[0], $at, $s[-1] );
		push @lines, $seg->( $at - 0.125, percentile( \@s, 50 ), $at + 0.125, percentile( \@s, 50 ) ) if $medians;
		if ($whiskers) {
			my ( $q1, $q3 ) = map { percentile( \@s, $_ ) } ( 25, 75 );
			my $up = min( max( $q3 + 1.5 * ( $q3 - $q1 ), $q3 ), $s[-1] );
			my $dn = max( min( $q1 - 1.5 * ( $q3 - $q1 ), $q1 ), $s[0] );
			push @quartiles, $seg->( $at, $q1, $at, $q3 );
			push @whisk, $seg->( $at, $dn, $at, $up );
		}
		push @means, [ $xy->( $at, sum(@s) / @s ) ];
	}
	foreach my $set ( [ \@lines, cycle_color(0), 1.5 ], [ \@whisk, '#000000', 1 ], [ \@quartiles, '#000000', 5 ] ) {
		my $b = datablock( $set->[0] );
		push @{ $g{plot} }, "$b using 1:2:3:4 with vectors nohead lc rgb " . gp_color( $set->[1] ) . " lw $set->[2] notitle" if defined $b;
	}
	my $b = datablock( \@means );
	push @{ $g{plot} }, "$b using 1:2 with points pt 7 ps $point_size lc rgb \"#ff0000\" notitle";
	push @{ $g{set} }, tics( $horizontal ? 'y' : 'x', \@labels, [ 1 .. scalar @keys ] );
	$g{categories} = $horizontal ? 'y' : 'x';
	category_range( \%g, scalar @keys, $horizontal );
	return \%g;
}
# style => 'native': the boxplot, violin and hist that gnuplot computes for
# itself. Each set is written as one column of its values, and gnuplot's
# "with boxplot", "smooth kdensity" and "bins" work out the quartiles, the
# density and the bins from it, with gnuplot's own rules and defaults. The
# other types have no statistic of their own in gnuplot -- hist2d's bins, the
# mean and spread of "wide", a pie's angles -- and are computed in Perl under
# either style.
sub given_faces {
	# The colors given for the sets of a boxplot or violin: "colors", one per
	# key, or one "color" for all, as #rrggbb; ( undef ) x n where none is.
	my ( $plot, $sets, $keys, $what ) = @_;
	if ( ref $plot->{color} ) {
		die "\"color\" is one color for every $what in $current_sub, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	if ( defined $plot->{colors} ) {
		die "\"colors\" is a hash of one color per key in $current_sub" unless ref $plot->{colors} eq 'HASH';
		my @bad = grep { not defined $plot->{colors}{$_} } sort keys %{$sets};
		die 'the data keys ' . join( ', ', map { "\"$_\"" } @bad ) . ' have no defined color' if scalar @bad;
		return map { hex_of( $plot->{colors}{$_}, "\"colors\" of \"$_\"" ) } @{$keys};
	}
	return ( defined $plot->{color} ? hex_of( $plot->{color}, '"color"' ) : undef ) x @{$keys};
}
sub column_of {
	# The numbers of one set, NaN and undef left out, as a datablock of one
	# column; dies naming the set if any is not a number.
	my ( $values, $key ) = @_;
	my @v = grep { ( defined ) && ( not is_nan($_) ) } @{$values};
	my @bad = grep { not looks_like_number($_) } @v;
	die "$key has non-numeric values" if scalar @bad;
	return ( datablock( [ map { [$_] } @v ] ), scalar @v );
}
sub draw_boxplot_native {
	# gnuplot's "with boxplot", one per key at 1 .. n: its own quartiles, and
	# whiskers to the furthest value within 1.5 interquartile ranges ("set
	# style boxplot range 1.5", its default), and its own outliers.
	my ( $plot, $axes ) = @_;
	if ( orientation_of($plot) eq 'horizontal' ) {
		die "$current_sub: gnuplot's boxplot style draws its boxes upright only, so style => 'native' cannot draw orientation => 'horizontal'; style => 'matplotlib' can";
	}
	my $sets = sets_of($plot);
	my @keys = key_order_of( $plot, $sets );
	my @face = given_faces( $plot, $sets, \@keys, 'box' );
	# Each as the caller gave it, or as gnuplot draws it: caps on the whiskers
	# and the outliers, and no mean, which gnuplot's boxplot does not mark.
	my %show = map { $_ => bool_option( $plot->{$_} // ( $_ eq 'showmeans' ? 0 : 1 ), $_, $current_sub ) } ( 'showcaps', 'showfliers', 'showmeans' );
	my %g = ( set => [], plot => [] );
	push @{ $g{set} }, "set logscale $_" foreach logscale_axes( $plot->{logscale}, $current_sub );
	push @{ $g{set} }, 'set style boxplot nooutliers' unless $show{showfliers};
	push @{ $g{set} }, 'set errorbars 0' unless $show{showcaps};    # the caps of the whiskers are gnuplot's error bars ("help boxplot")
	my @labels;
	foreach my $i ( 0 .. $#keys ) {
		my $at = $i + 1;
		my ( $block, $n ) = column_of( $sets->{ $keys[$i] }, $keys[$i] );
		push @labels, "$keys[$i] (" . format_commas($n) . ')';
		next unless defined $block;
		my $color = $face[$i] // next_color( $axes, 'patches' );
		my $fill = defined $face[$i] ? 'fs solid 1.0 border lc rgb "black" ' : '';    # a color given fills the box, as matplotlib's does; gnuplot's own is empty
		push @{ $g{plot} }, "$block using ($at):1 with boxplot ${fill}lc rgb " . gp_color($color) . ' notitle';
		if ( $show{showmeans} ) {
			# The mean as gnuplot's "stats" works it out, marked as matplotlib
			# marks it, since gnuplot's boxplot has no mark of its own for it.
			push @{ $g{set} }, "stats $block using 1 name \"box$at\" nooutput";
			push @{ $g{plot} }, "$block every ::0::0 using ($at):(box${at}_mean) with points pt 9 lc rgb " . gp_color($color) . ' notitle';
		}
	}
	push @{ $g{set} }, tics( 'x', \@labels, [ 1 .. scalar @keys ] );
	$g{categories} = 'x';
	return \%g;
}
sub draw_violin_native {
	# gnuplot's "smooth kdensity" of each set, with its own bandwidth
	# ("help kdensity": sigma * (4/3N) ** 0.2), mirrored about the set's place
	# at 1 .. n, with a narrow "with boxplot" inside for the quartiles and the
	# median. gnuplot has no violin style: the density is written out with
	# "set table" and drawn as two filled curves, as gnuplot's own violin demo
	# (violinplot.dem) builds one. Each is 0.4 either side at its widest, so
	# that neighbours 1 apart do not touch.
	my ( $plot, $axes ) = @_;
	my $horizontal = ( orientation_of($plot) eq 'horizontal' ) ? 1 : 0;
	my $sets = sets_of($plot);
	my @keys = key_order_of( $plot, $sets );
	my $medians  = bool_option( $plot->{medians}  // 1, 'medians',  $current_sub );
	my $whiskers = bool_option( $plot->{whiskers} // 1, 'whiskers', $current_sub );
	if ( $whiskers && ( not $medians ) ) {
		die "$current_sub: under style => 'native' the whiskers are gnuplot's boxplot, which always draws its median, so \"medians\" => 0 with \"whiskers\" cannot be drawn; style => 'matplotlib' can";
	}
	if ( $whiskers && $horizontal ) {
		die "$current_sub: under style => 'native' the whiskers are gnuplot's boxplot, which draws upright only, so orientation => 'horizontal' needs \"whiskers\" => 0; style => 'matplotlib' draws both";
	}
	my @face = given_faces( $plot, $sets, \@keys, 'violin' );
	my $edge = defined $plot->{edgecolor} ? hex_of( $plot->{edgecolor}, '"edgecolor"' ) : undef;
	my %g = ( set => [], plot => [] );
	push @{ $g{set} }, "set logscale $_" foreach logscale_axes( $plot->{logscale}, $current_sub );
	push @{ $g{set} }, 'set style boxplot nooutliers' if $whiskers;    # the violin is the distribution; the boxplot inside shows its middle
	my @labels;
	foreach my $i ( 0 .. $#keys ) {
		my ( $key, $at ) = ( $keys[$i], $i + 1 );
		my @v = grep { ( defined ) && looks_like_number($_) && ( not is_nan($_) ) } @{ $sets->{$key} };
		die "\"$key\" has no numeric values for $current_sub to plot (" . scalar( @{ $sets->{$key} } ) . ' value(s) given, all undefined, NaN or non-numeric)' if scalar @v == 0;
		die "\"$key\" has infinite values, which $current_sub cannot draw a density for" if grep { not is_finite($_) } @v;
		die "\"$key\" has no spread -- every value is $v[0] -- so $current_sub has no density to draw" if min(@v) == max(@v);
		push @labels, "$key (" . format_commas( scalar @v ) . ')';
		my $block = datablock( [ map { [$_] } @v ] );
		my $density = '$kd' . $n_blocks++;
		push @{ $g{set} }, "set table $density", "plot $block using 1:(1) smooth kdensity", 'unset table', "stats $density using 2 name \"kd$at\" nooutput";
		my $color = gp_color( $face[$i] // next_color( $axes, 'patches' ) );
		my $edge_clause = defined $edge ? 'border lc rgb ' . gp_color($edge) . ' ' : 'noborder ';
		foreach my $side ( '+', '-' ) {
			my $across = "($at $side 0.4 * \$2 / kd${at}_max)";
			push @{ $g{plot} }, $horizontal
			 ? "$density using 1:$across with filledcurves y=$at fs solid 0.5 ${edge_clause}lc rgb $color notitle"
			 : "$density using $across:1 with filledcurves x=$at fs solid 0.5 ${edge_clause}lc rgb $color notitle";
		}
		if ($whiskers) {
			push @{ $g{plot} }, "$block using ($at):1:(0.08) with boxplot fs solid 1.0 lc rgb \"black\" notitle";
		} elsif ($medians) {
			push @{ $g{set} }, "stats $block using 1 name \"vm$at\" nooutput";
			my $median = $horizontal ? "(vm${at}_median):($at - 0.1):(0):(0.2)" : "($at - 0.1):(vm${at}_median):(0.2):(0)";
			push @{ $g{plot} }, "$block every ::0::0 using $median with vectors nohead lc rgb \"black\" notitle";
		}
	}
	push @{ $g{set} }, tics( $horizontal ? 'y' : 'x', \@labels, [ 1 .. scalar @keys ] );
	$g{categories} = $horizontal ? 'y' : 'x';
	return \%g;
}
sub draw_hist_native {
	# gnuplot's "bins" filter, one histogram per set: its own bin edges
	# ("help bins": NBINS bins of width (HIGH - LOW) / (NBINS - 1), centered on
	# the least and the greatest value). With no "bins" given there are 10,
	# matplotlib's default and the ggplot2 engine's under this style: gnuplot's
	# own number is "set samples", which is how finely it draws a function, not
	# a rule for binning, and its 100 left a set of 300 values a row of spikes.
	my ( $plot, $axes ) = @_;
	if ( orientation_of($plot) eq 'horizontal' ) {
		die "$current_sub: gnuplot's \"bins\" are drawn upright only, so style => 'native' cannot draw orientation => 'horizontal'; style => 'matplotlib' can";
	}
	my $sets = ( ref $plot->{data} eq 'ARRAY' ) ? { A => $plot->{data} } : $plot->{data};
	foreach my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) ) {
		my @stray = sort grep { not exists $sets->{$_} } keys %{ $plot->{$arg} };
		die 'the keys ' . join( ', ', map { "\"$_\"" } @stray ) . " of \"$arg\" are not sets of \"data\" in $current_sub" if scalar @stray;
	}
	if ( ( ref $plot->{color} ) && ( ref $plot->{color} ne 'HASH' ) ) {
		die "\"color\" for $current_sub is one color for every set, or a hash of one color per set, not a " . ref( $plot->{color} ) . ' reference';
	}
	my $alpha = $plot->{alpha};    # undef: gnuplot's own fill, which is none
	if ( defined $alpha ) {
		check_numbers( [$alpha], '"alpha"', $current_sub );
		die "\"alpha\" is from 0 to 1 in $current_sub, not $alpha" if ( $alpha < 0 ) || ( $alpha > 1 );
	}
	my @keys = key_order_of( $plot, $sets );
	my $legend = bool_option( $plot->{show_legend} // ( scalar keys %{$sets} > 1 ? 1 : 0 ), 'show_legend', $current_sub );
	my %g = ( set => [ map { "set logscale $_" } logscale_axes( $plot->{logscale}, $current_sub ) ], plot => [] );
	foreach my $set (@keys) {
		my @inf = grep { looks_like_number($_) && ( not( is_nan($_) || is_finite($_) ) ) } @{ $sets->{$set} };
		die "$set has infinite values, which $current_sub cannot bin" if scalar @inf;
		my @bad = grep { not looks_like_number($_) } @{ $sets->{$set} };
		die "$set has non-numeric values; which for hist must be numeric" if scalar @bad;
		my ($block) = column_of( $sets->{$set}, $set );
		next unless defined $block;
		my $bins = ( ref $plot->{bins} eq 'HASH' ) ? $plot->{bins}{$set} : $plot->{bins};
		my $given = ( ref $plot->{color} eq 'HASH' ) ? $plot->{color}{$set} : $plot->{color};
		die "\"color\" for set \"$set\" is an array, but $current_sub draws each set in one color" if ref $given;
		push @extent, [ undef, 0 ], [ undef, native_bin_peak( $sets->{$set}, $bins ) ];
		my $color = defined $given ? hex_of( $given, "\"color\" of \"$set\"" ) : next_color( $axes, 'patches' );
		my $fill = defined $alpha ? sprintf( 'fs transparent solid %s ', gp_num($alpha) ) : '';
		push @{ $g{plot} }, "$block using 1 " . native_bins( $bins, $set ) . " with boxes ${fill}lc rgb " . gp_color($color) . ' ' . key_title( $legend ? $set : undef );
		$g{legend} = 1 if $legend;
	}
	return \%g;
}
sub native_bin_peak {
	# The count in the fullest of the bins native_bins asks gnuplot for, for
	# thin_tics, which spaces the tics of a small subplot over the range of the
	# data: gnuplot bins these itself, so the counts were nowhere in Perl, and
	# a native hist in a 2 by 2 grid kept gnuplot's tic every 10 from 0 to 80.
	# The rule is gnuplot's ("help bins"): N centers from the least value to
	# the greatest, or from "binrange" by "binwidth", each value counted at the
	# nearest. Only the tics read this; gnuplot still draws the bars.
	my ( $values, $bins ) = @_;
	my @v = grep { ( defined ) && looks_like_number($_) && is_finite($_) } @{$values};
	return 0 if scalar @v == 0;
	my ( $first, $width );
	if ( ref $bins eq 'ARRAY' ) {
		$width = ( $bins->[-1] - $bins->[0] ) / $#{$bins};
		$first = $bins->[0] + $width / 2;
	} else {
		my $n = $bins // 10;    # native_bins' default
		$first = min(@v);
		$width = ( $n > 1 ) ? ( max(@v) - $first ) / ( $n - 1 ) : 0;
	}
	return scalar @v if $width <= 0;    # every value at one center
	my %count;
	$count{ POSIX::floor( ( $_ - $first ) / $width + 0.5 ) }++ foreach @v;
	return max( values %count );
}
sub native_bins {
	# The "bins" option of a plot clause for a hist's "bins": 10 for none, as
	# draw_hist_native says, "bins=N" for a count, and for edges, which must be
	# evenly spaced since gnuplot's bins are all one width, that width over
	# the centers of the first and the last.
	my ( $bins, $set ) = @_;
	return 'bins=10' unless defined $bins;
	if ( ref $bins eq 'ARRAY' ) {
		check_numbers( $bins, '"bins"', $current_sub );
		die "\"bins\" has fewer than 2 edges in $current_sub" if scalar @{$bins} < 2;
		die "\"bins\" must rise from edge to edge in $current_sub" if grep { $bins->[$_] <= $bins->[ $_ - 1 ] } 1 .. $#{$bins};
		my $width = ( $bins->[-1] - $bins->[0] ) / $#{$bins};
		# 1e-9 of the width: edges written to 10 significant figures are even
		my @uneven = grep { abs( $bins->[$_] - $bins->[ $_ - 1 ] - $width ) > 1e-9 * abs($width) } 1 .. $#{$bins};
		die "\"bins\" for \"$set\" has edges of different widths, but gnuplot's bins under style => 'native' are all one width; style => 'matplotlib' draws them" if scalar @uneven;
		return sprintf 'bins binrange [%s:%s] binwidth=%s', gp_num( $bins->[0] + $width / 2 ), gp_num( $bins->[-1] - $width / 2 ), gp_num($width);
	}
	if ( ( ref $bins ) || ( not looks_like_number($bins) ) || ( not is_finite($bins) ) || ( int($bins) != $bins ) || ( $bins < 1 ) ) {
		die "\"bins\" is a whole number of bins, or an array of their edges, for the gnuplot engine, not \"" . ( ref $bins || $bins ) . '"';
	}
	# gnuplot's own bin width is (HIGH - LOW) / (NBINS - 1) ("help bins"), and with
	# one bin it refuses the plot: "x range is invalid", gnuplot 6.0.
	die "\"bins\" => 1 for \"$set\": gnuplot's bins under style => 'native' are at least 2, its bin width being the range over one fewer than their number; style => 'matplotlib' draws one" if int($bins) == 1;
	return 'bins=' . int $bins;
}
sub bin_edges {
	# The edges of a hist's bins: "bins" given as edges, or as a count of
	# equal bins over the values' range, as numpy.histogram makes them.
	my ( $values, $bins, $what ) = @_;
	if ( ref $bins eq 'ARRAY' ) {
		check_numbers( $bins, $what, $current_sub );
		die "$what has fewer than 2 edges in $current_sub" if scalar @{$bins} < 2;
		# Two equal edges are a bin of no width, which holds nothing, as numpy
		# allows them; edges that fall are refused, as numpy refuses them.
		die "$what must not fall from edge to edge in $current_sub" if grep { $bins->[$_] < $bins->[ $_ - 1 ] } 1 .. $#{$bins};
		return map { as_double($_) } @{$bins};    # see bin_count
	}
	if ( ( ref $bins ) || ( not looks_like_number($bins) ) || ( not is_finite($bins) ) || ( int($bins) != $bins ) || ( $bins < 1 ) ) {
		die "$what is a whole number of bins, or an array of their edges, for the gnuplot engine, not \"" . ( ref $bins || $bins ) . '"';
	}
	# numpy's range for no values at all, as for a set that was all NaN, is
	# 0 .. 1; min() of an empty list was undef, and died comparing it.
	my ( $lo, $hi ) = scalar @{$values} ? ( min( @{$values} ), max( @{$values} ) ) : ( 0, 1 );
	( $lo, $hi ) = ( $lo - 0.5, $hi + 0.5 ) if $lo == $hi;
	return linspace( $lo, $hi, $bins + 1 );
}
sub bin_count {
	# How many values fall in each bin; the last bin holds its right edge.
	# The edges are doubles, and each value is rounded to one before it is
	# compared with them, as numpy compares them; see as_double.
	my ( $values, $edges ) = @_;
	my @n = (0) x ( scalar @{$edges} - 1 );
	foreach my $v ( map { as_double($_) } @{$values} ) {
		next if ( $v < $edges->[0] ) || ( $v > $edges->[-1] );
		my ( $l, $r ) = ( 0, $#n );
		while ( $l < $r ) {    # the last edge at or below $v
			my $m = int( ( $l + $r + 1 ) / 2 );
			if ( $edges->[$m] <= $v ) { $l = $m } else { $r = $m - 1 }
		}
		$n[$l]++;
	}
	return @n;
}
sub draw_hist {
	# One histogram per set, each binned over its own range, drawn see-through
	# so that the sets overlap, as hist_helper draws them.
	my ( $plot, $axes ) = @_;
	return draw_hist_native( $plot, $axes ) if $native;
	my $horizontal = ( orientation_of($plot) eq 'horizontal' ) ? 1 : 0;
	my $alpha = $plot->{alpha} // 0.5;
	check_numbers( [$alpha], '"alpha"', $current_sub );
	die "\"alpha\" is from 0 to 1 in $current_sub, not $alpha" if ( $alpha < 0 ) || ( $alpha > 1 );
	my $sets = ( ref $plot->{data} eq 'ARRAY' ) ? { A => $plot->{data} } : $plot->{data};
	foreach my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) ) {
		my @stray = sort grep { not exists $sets->{$_} } keys %{ $plot->{$arg} };
		die 'the keys ' . join( ', ', map { "\"$_\"" } @stray ) . " of \"$arg\" are not sets of \"data\" in $current_sub" if scalar @stray;
	}
	if ( ( ref $plot->{color} ) && ( ref $plot->{color} ne 'HASH' ) ) {
		die "\"color\" for $current_sub is one color for every set, or a hash of one color per set, not a " . ref( $plot->{color} ) . ' reference';
	}
	my @keys = key_order_of( $plot, $sets );
	my $legend = bool_option( $plot->{show_legend} // ( scalar keys %{$sets} > 1 ? 1 : 0 ), 'show_legend', $current_sub );
	my %log = map { $_ => 1 } logscale_axes( $plot->{logscale}, $current_sub );
	my %g = ( set => [ map { "set logscale $_" } sort keys %log ], plot => [] );
	my $count_axis = $horizontal ? 'x' : 'y';
	foreach my $set (@keys) {
		my @bad = grep { not looks_like_number($_) } @{ $sets->{$set} };
		die "$set has non-numeric values; which for hist must be numeric" if scalar @bad;
		my @inf = grep { not( is_nan($_) || is_finite($_) ) } @{ $sets->{$set} };
		die "$set has infinite values, which $current_sub cannot bin" if scalar @inf;
		my @v = grep { not is_nan($_) } @{ $sets->{$set} };
		my $bins = ( ref $plot->{bins} eq 'HASH' ) ? $plot->{bins}{$set} // 10 : $plot->{bins} // 10;
		my @edges = bin_edges( \@v, $bins, '"bins"' );
		my @n = bin_count( \@v, \@edges );
		my $color;
		my $given = ( ref $plot->{color} eq 'HASH' ) ? $plot->{color}{$set} : $plot->{color};
		if ( ref $given ) {
			die "\"color\" for set \"$set\" is an array, but $current_sub draws each set in one color";
		}
		$color = defined $given ? hex_of( $given, "\"color\" of \"$set\"" ) : next_color( $axes, 'patches' );
		my $base = $log{$count_axis} ? 0.5 : 0;    # a log axis of counts starts below the least, which is 1
		my @rows = map { box_rows( ( $edges[$_] + $edges[ $_ + 1 ] ) / 2, ( $edges[ $_ + 1 ] - $edges[$_] ) / 2, $base, $n[$_], $horizontal ) } grep { $n[$_] > 0 || not $log{$count_axis} } 0 .. $#n;
		push @{ $g{plot} }, boxes_clause( datablock( \@rows ), with_alpha( $color, $alpha ), key_title( $legend ? $set : undef ) );
		$g{legend} = 1 if $legend;
	}
	$g{no_margin} = [ $horizontal ? 'left' : 'bottom' ] unless $log{$count_axis};
	return \%g;
}
sub draw_hist2d {
	# Counts of points in a grid of bins, colored by a colormap, as
	# hist2d_helper draws them; the bins are counted here.
	my ( $plot, $axes ) = @_;
	my $log_cb = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	my $show = bool_option( $plot->{show_colorbar} // 1, 'show_colorbar', $current_sub ) && bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $current_sub );
	bin_counts( $plot, $current_sub );
	my @keys = key_order_of( $plot, $plot->{data} );
	die "There must be exactly 2 keys for $current_sub" if scalar @keys != 2;
	my ( $x, $y ) = @{ $plot->{data} }{@keys};
	die 'The length of both keys must be equal.' if scalar @{$x} != scalar @{$y};
	foreach my $i ( 0, 1 ) {
		my $vals = $plot->{data}{ $keys[$i] };
		my @bad = grep { ( not defined $vals->[$_] ) || ( not looks_like_number( $vals->[$_] ) ) } 0 .. $#{$vals};
		die "\"$keys[$i]\" is undefined or not a number at index " . join( ', ', @bad ) . " in $current_sub" if scalar @bad;
	}
	my %log = map { $_ => 1 } logscale_axes( $plot->{logscale}, $current_sub );
	my ( %edges, %g );
	$g{set} = [ map { "set logscale $_" } sort keys %log ];
	foreach my $i ( 0, 1 ) {
		my $axis = ( 'x', 'y' )[$i];
		my @finite = finite_values( @{ $plot->{data}{ $keys[$i] } } );
		foreach my $end ( 'min', 'max' ) {
			my $opt = "$axis$end";
			if ( defined $plot->{$opt} ) {
				check_numbers( [ $plot->{$opt} ], "\"$opt\"", $current_sub );
				die "\"$opt\" must be a finite number for $current_sub, not \"$plot->{$opt}\"" unless is_finite( $plot->{$opt} );
			} elsif ( scalar @finite == 0 ) {
				die "\"$keys[$i]\" has no finite value, so $current_sub has no range to bin it over; give \"${axis}min\" and \"${axis}max\"";
			}
		}
		my $lo = $plot->{"${axis}min"} // min(@finite);
		my $hi = $plot->{"${axis}max"} // max(@finite);
		die "\"${axis}min\" = $lo is above \"${axis}max\" = $hi in $current_sub" if $lo > $hi;
		die "\"logscale\" puts $axis on a log scale, which cannot start at $lo in $current_sub: give a \"${axis}min\" above 0" if $log{$axis} && ( $lo <= 0 );
		# Refused on a log axis, where widening by 0.5 each way could reach 0 or
		# below, and died taking its log ("Can't take log of -0.2"); matplotlib's
		# np.logspace of one value has edges that do not rise, and fails too.
		die "\"logscale\" puts $axis on a log scale, but every $axis is $lo, a range of nothing, in $current_sub; give \"${axis}min\" and \"${axis}max\"" if $log{$axis} && ( $lo == $hi );
		( $lo, $hi ) = ( $lo - 0.5, $hi + 0.5 ) if $lo == $hi;    # numpy's histogram2d does the same with an empty range
		my $n = $plot->{"${axis}bins"};
		$edges{$axis} = $log{$axis} ? [ logspace( $lo, $hi, $n + 1 ) ] : [ linspace( $lo, $hi, $n + 1 ) ];    # as the matplotlib engine writes them
		push @{ $g{set} }, "set ${axis}range [" . gp_num($lo) . ':' . gp_num($hi) . ']';
	}
	my @count;
	my $in_range = 0;
	foreach my $p ( 0 .. $#{$x} ) {
		next unless is_finite( $x->[$p] ) && is_finite( $y->[$p] );
		my ($xi) = bin_index( $x->[$p], $edges{x} );
		my ($yi) = bin_index( $y->[$p], $edges{y} );
		next unless defined $xi && defined $yi;
		$count[$xi][$yi]++;
		$in_range++;
	}
	foreach my $c ( grep { defined $plot->{$_} } ( 'cmin', 'cmax' ) ) {
		check_numbers( [ $plot->{$c} ], "\"$c\"", $current_sub );
	}
	my $density = bool_option( $plot->{density}, 'density', $current_sub );
	my ( @rows, @values );
	foreach my $i ( 0 .. $plot->{xbins} - 1 ) {
		foreach my $j ( 0 .. $plot->{ybins} - 1 ) {
			my $c = $count[$i][$j] // 0;
			next if ( defined $plot->{cmin} ) && ( $c < $plot->{cmin} );    # left undrawn, as matplotlib masks them
			next if ( defined $plot->{cmax} ) && ( $c > $plot->{cmax} );
			my ( $x0, $x1, $y0, $y1 ) = ( $edges{x}[$i], $edges{x}[ $i + 1 ], $edges{y}[$j], $edges{y}[ $j + 1 ] );
			my $v = ( $density && $in_range ) ? $c / ( $in_range * ( $x1 - $x0 ) * ( $y1 - $y0 ) ) : $c;
			next if $log_cb && ( $v <= 0 );    # LogNorm leaves these undrawn
			push @values, $v;
			push @rows, [ ( $x0 + $x1 ) / 2, ( $y0 + $y1 ) / 2, $x0, $x1, $y0, $y1, $v ];
		}
	}
	my ( $lo, $hi ) = color_scale( $plot, \@values, $log_cb );
	push @{ $g{set} }, palette({ cmap => default_cmap( $plot, 'gist_rainbow' ), lo => $lo, hi => $hi, log => $log_cb, colorbar => $show, label => $plot->{cblabel} // 'Density' });
	my $block = datablock( \@rows );
	$g{plot} = [ defined $block ? "$block using 1:2:3:4:5:6:7 with boxxyerror fs solid 1.0 noborder lc palette notitle" : () ];
	@g{ 'palette', 'default_xlabel', 'default_ylabel' } = ( 1, @keys );
	$g{no_margin} = [ 'left', 'right', 'top', 'bottom' ];
	return \%g;
}
sub bin_index {
	# The bin of a value among edges, the last holding its right edge; undef
	# outside them. $v is rounded to a double, as the edges are; see bin_count.
	my ( $v, $edges ) = @_;
	$v = as_double($v);
	return undef if ( $v < $edges->[0] ) || ( $v > $edges->[-1] );
	my ( $l, $r ) = ( 0, $#{$edges} - 1 );
	while ( $l < $r ) {
		my $m = int( ( $l + $r + 1 ) / 2 );
		if ( $edges->[$m] <= $v ) { $l = $m } else { $r = $m - 1 }
	}
	return $l;
}
sub image_clause {
	# A matrix of values drawn as an image, row 0 at the top, as matplotlib's
	# imshow draws it.
	my ( $matrix, $g ) = @_;
	my ( $nr, $nc ) = ( scalar @{$matrix}, scalar @{ $matrix->[0] } );
	my $block = datablock($matrix);
	push @{ $g->{set} }, sprintf( 'set xrange [-0.5:%s]', gp_num( $nc - 0.5 ) ), sprintf( 'set yrange [%s:-0.5]', gp_num( $nr - 0.5 ) );
	$g->{no_margin} = [ 'left', 'right', 'top', 'bottom' ];
	return "$block matrix using 1:2:3 with image notitle";
}
sub draw_imshow {
	# A 2-D array as an image, numbers by a colormap, or strings by a
	# "stringmap" as categories, as imshow_helper draws them.
	my ( $plot, $axes ) = @_;
	my $data = $plot->{data};
	die "$current_sub can only accept 2-D arrays as input in \"data\", but received " . ref($data) if ref $data ne 'ARRAY';
	my @bad_rows = grep { ref $data->[$_] ne 'ARRAY' } 0 .. $#{$data};
	die 'rows ' . join( ', ', @bad_rows ) . " of \"data\" are not array references, which $current_sub needs" if scalar @bad_rows;
	die "$current_sub was given no data to draw" if ( scalar @{$data} == 0 ) || ( not grep { scalar @{$_} > 0 } @{$data} );
	my %lengths = map { scalar @{$_} => 1 } @{$data};
	die "the rows of \"data\" have different lengths, but $current_sub draws a rectangle of cells" if scalar keys %lengths > 1;
	foreach my $r ( 0 .. $#{$data} ) {
		my @undef = grep { not defined $data->[$r][$_] } 0 .. $#{ $data->[$r] };
		die "$current_sub cannot draw an undefined cell, and \"data\" has one at [$r][$undef[0]]; a NaN is drawn as an empty cell" if scalar @undef;
	}
	my $strings = grep { grep { not looks_like_number($_) } @{$_} } @{$data};
	my $log = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	my $colorbar = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $current_sub );
	my %g = ( set => [], palette => 1 );
	if ($strings) {
		die "$current_sub needs a map to translate strings to integers" unless ref $plot->{stringmap} eq 'HASH';
		die "\"cb_logscale\" means nothing for $current_sub with a \"stringmap\": its colors are categories, not a scale" if $log;
		die "\"cmap\" means nothing for $current_sub with a \"stringmap\": its colors are matplotlib's color cycle" if defined $plot->{cmap};
		my @strings = sort keys %{ $plot->{stringmap} };
		my %int = map { $strings[$_] => $_ } 0 .. $#strings;
		my %unmapped;
		$unmapped{$_} = 1 foreach grep { not defined $int{$_} } map { @{$_} } @{$data};
		die 'the values ' . join( ', ', map { "\"$_\"" } sort keys %unmapped ) . " of \"data\" are not keys of \"stringmap\", which $current_sub needs to give each one a color" if scalar keys %unmapped;
		my $n = scalar @strings;
		# The color cycle for up to 10 categories, and gist_rainbow sampled
		# once per category beyond that, as imshow_helper chooses. Under style
		# => 'native', gnuplot's eight linetype colors, and its own palette
		# sampled beyond them.
		my @colors;
		if ($native) {
			@colors = ( $n <= @gnuplot_colors ) ? map { cycle_color($_) } 0 .. $n - 1 : map { default_palette_color( $_ / ( $n - 1 ) ) } 0 .. $n - 1;
		} else {
			@colors = ( $n <= 10 ) ? map { cycle_color($_) } 0 .. $n - 1 : map { my @c = colormap_colors( 'gist_rainbow', $engine, $current_sub ); $c[ int( $_ * $#c / ( $n - 1 ) + 0.5 ) ] } 0 .. $n - 1;
		}
		push @{ $g{set} }, 'set palette defined (' . join( ', ', map { ( $_ . ' ' . gp_str( $colors[$_] ), ( $_ + 1 ) . ' ' . gp_str( $colors[$_] ) ) } 0 .. $n - 1 ) . ')';
		push @{ $g{set} }, 'unset logscale cb', sprintf( 'set cbrange [-0.5:%s]', gp_num( $n - 0.5 ) );
		push @{ $g{set} }, $colorbar ? ( 'set colorbox', tics( 'cb', [ map { $plot->{stringmap}{$_} } @strings ], [ 0 .. $n - 1 ] ) ) : 'unset colorbox';
		push @{ $g{set} }, 'set cblabel ' . gp_str( $plot->{cblabel} ) if $colorbar && defined $plot->{cblabel};
		# gnuplot leaves no room right of the colorbar for labels of its own
		# tics: a margin in characters as wide as the longest, the colorbar
		# and its gap, measured on the PNG terminal.
		push @{ $g{set} }, 'set rmargin ' . ( max( map { length $plot->{stringmap}{$_} } @strings ) + 8 + ( defined $plot->{cblabel} ? 3 : 0 ) ) if $colorbar;
		$g{plot} = [ image_clause( [ map { [ map { $int{$_} } @{$_} ] } @{$data} ], \%g ) ];
	} else {
		my ( $lo, $hi ) = color_scale( $plot, [ map { @{$_} } @{$data} ], $log );
		push @{ $g{set} }, palette({ cmap => default_cmap( $plot, 'viridis' ), lo => $lo, hi => $hi, log => $log, colorbar => $colorbar, label => $plot->{cblabel} });
		$g{plot} = [ image_clause( $data, \%g ) ];
	}
	$g{solo} = 'imshow';
	return \%g;
}
sub draw_colored_table {
	# A table of cells colored by their values, with the row labels down the
	# left, the column labels along the top, and the numbers if asked for, as
	# colored_table_helper draws it.
	my ( $plot, $axes ) = @_;
	my ( $row_keys, $cols, $cells ) = table_cells( $plot, $current_sub );
	my @rows = @{$row_keys};
	if ( defined $plot->{row_labels} ) {
		die "\"row_labels\" is an array of one label per row in $current_sub" unless ref $plot->{row_labels} eq 'ARRAY';
		die '"row_labels" has ' . scalar( @{ $plot->{row_labels} } ) . ' labels, but the table has ' . scalar(@rows) . " rows in $current_sub" if scalar @{ $plot->{row_labels} } != scalar @rows;
		@rows = @{ $plot->{row_labels} };
	}
	if ( defined $plot->{default_undefined} ) {
		die "\"default_undefined\" = $plot->{default_undefined} must be a number" unless looks_like_number( $plot->{default_undefined} );
	}
	my @non_numeric;
	foreach my $k1 ( @{$row_keys} ) {
		push @non_numeric, map { "$k1/$_ = \"$cells->{$k1}{$_}\"" } grep { ( defined $cells->{$k1}{$_} ) && ( not looks_like_number( $cells->{$k1}{$_} ) ) } @{$cols};
	}
	die 'the cells ' . join( ', ', @non_numeric ) . " are not numbers, which $current_sub needs; leave a cell out, or undefined, to draw it in \"undef_color\"" if scalar @non_numeric;
	foreach my $opt ( grep { defined $plot->{$_} } ( 'cb_min', 'cb_max' ) ) {
		die "\"$opt\" = $plot->{$opt} must be a finite number" unless looks_like_number( $plot->{$opt} ) && is_finite( $plot->{$opt} );
	}
	my @matrix = map { my $k1 = $_; [ map { $cells->{$k1}{$_} // $plot->{default_undefined} } @{$cols} ] } @{$row_keys};
	my @values = finite_values( map { @{$_} } @matrix );
	if ( ( scalar @values == 0 ) && ( ( not defined $plot->{cb_min} ) || ( not defined $plot->{cb_max} ) ) ) {
		die "no cell of the data holds a number, so $current_sub has nothing to color by";
	}
	my $log = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	my $colorbar = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $current_sub );
	my ( $lo, $hi ) = color_scale( $plot, \@values, $log );
	my $undef_color = hex_of( $plot->{undef_color} // 'gray', '"undef_color"' );
	my ( $nr, $nc ) = ( scalar @rows, scalar @{$cols} );
	my %g = ( set => [], palette => 1, solo => 'colored_table' );
	push @{ $g{set} }, palette({ cmap => default_cmap( $plot, 'gist_rainbow' ), lo => $lo, hi => $hi, log => $log, colorbar => $colorbar, label => $plot->{cblabel} });
	push @{ $g{set} }, sprintf( 'set object 1 rectangle from -0.5,-0.5 to %s,%s behind fc rgb %s fs solid 1.0 noborder', gp_num( $nc - 0.5 ), gp_num( $nr - 0.5 ), gp_color($undef_color) );
	push @{ $g{set} }, 'unset xtics', 'set link x2', 'set x2tics scale 0', tics( 'x2', $cols, [ 0 .. $nc - 1 ] ), 'set ytics scale 0', tics( 'y', \@rows, [ 0 .. $nr - 1 ] );
	$g{plot} = [ image_clause( \@matrix, \%g ) ];
	my $grid = datablock( [ map { my $r = $_; map { [ $_, $r, $_ - 0.5, $_ + 0.5, $r - 0.5, $r + 0.5 ] } 0 .. $nc - 1 } 0 .. $nr - 1 ] );
	push @{ $g{plot} }, "$grid using 1:2:3:4:5:6 with boxxyerror fs empty lc rgb \"black\" lw 1 notitle";
	# Each number to 15 significant digits, as Perl writes it into the JSON that
	# matplotlib's table shows as it stands; gnuplot's "%g" kept 6, and drew
	# 1234567 as 1.23457e+06.
	my $number_format = 'sprintf("%.15g", $3)';
	if ( bool_option( $plot->{show_numbers}, 'show_numbers', $current_sub ) && $native ) {
		# gnuplot's own palette runs from black, so a number written in black,
		# as matplotlib writes it, could not be read on the darkest cells: each
		# is written in white on a cell darker than mid-gray, by the cell's
		# luminance (ITU-R BT.709 weights, as in WCAG's relative luminance).
		my @cells = map { my $r = $_; map { [ $_, $r, $matrix[$r][$_] ] } grep { ( defined $matrix[$r][$_] ) && is_finite( $matrix[$r][$_] ) } 0 .. $nc - 1 } 0 .. $nr - 1;
		foreach my $cell (@cells) {
			my $at = ( $hi == $lo ) ? 0 : $log ? ( log( $cell->[2] > 0 ? $cell->[2] : $lo ) - log($lo) ) / ( log($hi) - log($lo) ) : ( $cell->[2] - $lo ) / ( $hi - $lo );
			$at = $at < 0 ? 0 : $at > 1 ? 1 : $at;
			my $hex = palette_at( default_cmap( $plot, 'gist_rainbow' ), $at );
			my ( $r, $gr, $b ) = map { hex( substr $hex, $_, 2 ) / 255 } ( 1, 3, 5 );
			push @{$cell}, ( 0.2126 * $r + 0.7152 * $gr + 0.0722 * $b < 0.5 ) ? 0xffffff : 0;
		}
		my $numbers = datablock( \@cells );
		push @{ $g{plot} }, "$numbers using 1:2:($number_format):4 with labels center tc rgb variable notitle" if defined $numbers;
	} elsif ( bool_option( $plot->{show_numbers}, 'show_numbers', $current_sub ) ) {
		my $numbers = datablock( [ map { my $r = $_; map { [ $_, $r, $matrix[$r][$_] ] } grep { ( defined $matrix[$r][$_] ) && is_finite( $matrix[$r][$_] ) } 0 .. $nc - 1 } 0 .. $nr - 1 ] );
		push @{ $g{plot} }, "$numbers using 1:2:($number_format) with labels center notitle" if defined $numbers;
	}
	return \%g;
}
sub draw_pie {
	# Wedges in matplotlib's order and colors, counterclockwise from 3
	# o'clock, labelled outside and, with "autopct", inside.
	my ( $plot, $axes ) = @_;
	my @keys = key_order_of( $plot, $plot->{data} );
	foreach my $key (@keys) {
		my $v = $plot->{data}{$key};
		die "\"$key\" is not a number, which $current_sub needs to size a wedge" unless looks_like_number($v);
		die "\"$key\" is not a finite number, which $current_sub needs to size a wedge" unless is_finite($v);
		die "\"$key\" is $v, but $current_sub cannot size a wedge below 0" if $v < 0;
	}
	my $total = sum( map { $plot->{data}{$_} } @keys );
	die "every wedge of $current_sub is 0, so there is no pie to divide between them" unless $total > 0;
	my %at;
	foreach my $arg ( [ 'labeldistance', 1.1 ], [ 'pctdistance', 0.6 ] ) {    # matplotlib's defaults
		my ( $name, $default ) = @{$arg};
		$at{$name} = $plot->{$name} // $default;
		check_numbers( [ $at{$name} ], "\"$name\"", $current_sub );
	}
	my $pct = $plot->{autopct} // '';
	if ( ( $pct ne '' ) && ( ( ref $pct ) || ( $pct !~ m/^(?:[^%]|%%)*%[-+ 0#]*\d*(?:\.\d+)?[dieEfFgG](?:[^%]|%%)*$/ ) ) ) {
		die "\"autopct\" is a format with one number in it, such as '%1.1f%%', for the gnuplot engine, not \"$pct\": a Python function is matplotlib's alone";
	}
	my %g = ( set => [ 'set size ratio -1', 'unset border', 'unset xtics', 'unset ytics', 'set xrange [-1.25:1.25]', 'set yrange [-1.25:1.25]' ], solo => 'pie', no_margin => [ 'left', 'right', 'top', 'bottom' ] );
	my ( @wedges, $angle );
	$angle = 0;
	my $pi = 4 * atan2( 1, 1 );
	foreach my $i ( 0 .. $#keys ) {
		my $sweep = 360 * $plot->{data}{ $keys[$i] } / $total;
		push @wedges, [ 0, 0, 1, $angle, $angle + $sweep, color_int( next_color( $axes, 'patches' ) ) ];
		my $mid = ( $angle + $sweep / 2 ) * $pi / 180;
		my ( $cx, $cy ) = ( cos $mid, sin $mid );
		my $align = ( $cx * $at{labeldistance} < 0 ) ? 'right' : 'left';    # as matplotlib aligns them
		push @{ $g{set} }, sprintf( 'set label %s at %s,%s %s front', gp_str( $keys[$i] ), gp_num( $cx * $at{labeldistance} ), gp_num( $cy * $at{labeldistance} ), $align );
		if ( $pct ne '' ) {
			my $text = sprintf $pct, 100 * $plot->{data}{ $keys[$i] } / $total;
			push @{ $g{set} }, sprintf( 'set label %s at %s,%s center front', gp_str($text), gp_num( $cx * $at{pctdistance} ), gp_num( $cy * $at{pctdistance} ) );
		}
		$angle += $sweep;
	}
	my $block = datablock( [ grep { $_->[4] > $_->[3] } @wedges ] );
	$g{plot} = ["$block using 1:2:3:4:5:6 with circles fs solid 1.0 noborder lc rgb variable notitle"];
	return \%g;
}
sub check_xy {
	# Die unless x and y are arrays of numbers of one length, naming the line.
	my ( $xy, $what ) = @_;
	die "$what must be [ \\\@x, \\\@y ] in $current_sub" unless ( ref $xy eq 'ARRAY' ) && ( scalar @{$xy} == 2 ) && ( ref $xy->[0] eq 'ARRAY' ) && ( ref $xy->[1] eq 'ARRAY' );
	die "$what has " . scalar( @{ $xy->[0] } ) . ' x values but ' . scalar( @{ $xy->[1] } ) . " y values in $current_sub: x & y must be of equal length" if scalar @{ $xy->[0] } != scalar @{ $xy->[1] };
	foreach my $axis ( 0, 1 ) {
		my @bad = grep { ( not defined ) || ( not looks_like_number($_) ) } @{ $xy->[$axis] };
		die "$what has " . ( $axis ? 'y' : 'x' ) . ' values that are undefined or not numbers ("' . join( '", "', map { $_ // 'undef' } @bad[ 0 .. min( $#bad, 4 ) ] ) . "\") in $current_sub" if scalar @bad;
	}
}
sub draw_plot {
	# Lines: one [ \@x, \@y ] pair, an array of them, or a hash of them (or of
	# y values alone, against 0 .. n-1), each in the next color of the cycle,
	# as plot_helper draws them.
	my ( $plot, $axes ) = @_;
	my $legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
	my %g = ( set => [ map { "set logscale $_" } logscale_axes( $plot->{logscale}, $current_sub ) ], plot => [] );
	my $data = $plot->{data};
	my @lines;    # [ \@x, \@y, label ]
	if ( ref $data eq 'ARRAY' ) {
		$data = [$data] if ( scalar @{$data} == 2 ) && ( ref $data->[0] eq 'ARRAY' ) && ( ref $data->[1] eq 'ARRAY' ) && ( ref $data->[0][0] ne 'ARRAY' );
		foreach my $i ( 0 .. $#{$data} ) {
			check_xy( $data->[$i], "index $i" );
			push @lines, [ @{ $data->[$i] }, undef ];
		}
	} elsif ( ref $data eq 'HASH' ) {
		foreach my $set ( key_order_of( $plot, $data ) ) {
			my $xy = $data->{$set};
			die "$set must have two arrays, x and y coordinates, or one array of y values" unless ref $xy eq 'ARRAY';
			my $n_refs = grep { ref } @{$xy};
			if ( ( $n_refs == 0 ) && ( scalar @{$xy} > 0 ) ) {
				$xy = [ [ 0 .. $#{$xy} ], $xy ];
			} elsif ( $n_refs < scalar @{$xy} ) {
				die "$current_sub: set \"$set\" mixes arrays with plain values: it must be [ \\\@x, \\\@y ] or one array of y values";
			}
			check_xy( $xy, "set \"$set\"" );
			push @lines, [ @{$xy}, $legend ? $set : undef ];
		}
	} else {
		die "$current_sub: \"data\" is a [ \\\@x, \\\@y ] pair, an array of them, or a hash of them";
	}
	foreach my $line (@lines) {
		my ( $x, $y, $label ) = @{$line};
		my $block = datablock( [ map { [ $x->[$_], $y->[$_] ] } 0 .. $#{$x} ] );
		my $color = next_color( $axes, 'lines' );
		next unless defined $block;
		push @{ $g{plot} }, "$block using 1:2 with lines " . lw() . "lc rgb " . gp_color($color) . ' ' . key_title($label);
		$g{legend} = 1 if defined $label;
	}
	return \%g;
}
sub draw_scatter {
	# Points: one set of 2 or 3 keys, the third coloring the points by a
	# colormap, or a hash of such sets, each in its own color or, colored by a
	# key, its own marker, as scatter_helper draws them.
	my ( $plot, $axes ) = @_;
	my $data = $plot->{data};
	die "scatter only takes 1) hashes of arrays (single or 2) hash of hash of arrays; but " . ref($data) . ' was entered' unless ref $data eq 'HASH';
	my %ref_counts;
	$ref_counts{ ref $data->{$_} }++ foreach keys %{$data};
	die "different kinds of data were entered to $current_sub; should be simple hash or hash of arrays." if scalar keys %ref_counts > 1;
	my $single = defined $ref_counts{ARRAY} ? 1 : defined $ref_counts{HASH} ? 0 : die 'Could not determine scatter type for the data.';
	die "$current_sub: \"key_order\" orders the sets of a hash of sets; for the axes of a single set, use \"keys\"" if $single && defined $plot->{key_order};
	my $log_cb = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	my $colorbar = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $current_sub );
	my %g = ( set => [ map { "set logscale $_" } logscale_axes( $plot->{logscale}, $current_sub ) ], plot => [] );
	my $by_case = sub { lc $a cmp lc $b || $a cmp $b };
	my $axes_of = sub {    # ( \@x_and_y_keys, $color_key ) of one set
		my ( $set, $where ) = @_;
		my @keys = defined $plot->{keys} ? check_key_order({ keys => $plot->{keys}, data => $set, option => 'keys', sub => $current_sub . $where }) : sort $by_case keys %{$set};
		my $n = scalar keys %{$set};
		die "scatterplots can only take 2 or 3 keys as data, but $current_sub received $n$where" if ( $n != 2 ) && ( $n != 3 );
		my $color_key;
		if ( defined $plot->{color_key} ) {
			$color_key = $plot->{color_key};
			die "\"$color_key\" isn't defined for this scatter$where" unless defined $set->{$color_key};
			@keys = grep { $_ ne $color_key } @keys;
		} elsif ( scalar @keys == 3 ) {
			$color_key = pop @keys;
		} elsif ( $n == 3 ) {
			my %named = map { $_ => 1 } @keys;
			($color_key) = grep { not $named{$_} } sort $by_case keys %{$set};
		}
		die "$current_sub needs one key for x and one for y$where, but \"keys\" and \"color_key\" leave " . scalar(@keys) if scalar @keys != 2;
		check_scatter_values( $set->{$_}, "\"$_\"$where", $current_sub ) foreach ( @keys, defined $color_key ? $color_key : () );
		check_scatter_lengths( $set, [ @keys, defined $color_key ? $color_key : () ], $where, $current_sub );
		return ( \@keys, $color_key );
	};
	my @drawn;    # [ label, \%set, \@keys, $color_key ]
	if ($single) {
		push @drawn, [ undef, $data, $axes_of->( $data, '' ) ];
	} else {
		my $legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
		my @order = key_order_of( $plot, $data );
		foreach my $name (@order) {
			my $inner = $data->{$name};
			my $set = ( ( scalar keys %{$inner} > 0 ) && ( not grep { ref } values %{$inner} ) ) ? { map { $_ => [ $inner->{$_} ] } keys %{$inner} } : $inner;
			push @drawn, [ $legend ? $name : undef, $set, $axes_of->( $set, " of set \"$name\"" ) ];
		}
	}
	my @z = map { finite_values( @{ $_->[1]{ $_->[3] } } ) } grep { defined $_->[3] } @drawn;
	my $colored = grep { defined $_->[3] } @drawn;
	if ($colored) {
		my ( $lo, $hi ) = color_scale( $plot, \@z, $log_cb );
		my ($cb_key) = map { $_->[3] } grep { defined $_->[3] } @drawn;
		push @{ $g{set} }, palette({ cmap => default_cmap( $plot, 'gist_rainbow' ), lo => $lo, hi => $hi, log => $log_cb, colorbar => $colorbar, label => $plot->{cblabel} // $cb_key });
		$g{palette} = 1;
	}
	my $marker_i = 0;
	foreach my $d (@drawn) {
		my ( $label, $set, $keys, $color_key ) = @{$d};
		my ( $x, $y ) = @{$set}{ @{$keys} };
		if ( defined $color_key ) {
			my $c = $set->{$color_key};
			my $pt = $single ? 7 : $marker_cycle[ $marker_i++ % @marker_cycle ];
			my $block = datablock( [ map { [ $x->[$_], $y->[$_], ( $log_cb && $c->[$_] <= 0 ) ? 'NaN' : $c->[$_] ] } 0 .. $#{$x} ] );
			push @{ $g{plot} }, "$block using 1:2:3 with points " . ( $native ? '' : "pt $pt " ) . ps() . "lc palette " . key_title($label) if defined $block;
		} else {
			my $block = datablock( [ map { [ $x->[$_], $y->[$_] ] } 0 .. $#{$x} ] );
			my $color = next_color( $axes, 'patches' );
			push @{ $g{plot} }, "$block using 1:2 with points " . ( $native ? '' : 'pt 7 ' ) . ps() . "lc rgb " . gp_color($color) . ' ' . key_title($label) if defined $block;
		}
		$g{legend} = 1 if defined $label;
	}
	@g{ 'default_xlabel', 'default_ylabel' } = @{ $drawn[0][2] };
	return \%g;
}
sub interpolate {
	# numpy.interp of sorted x and y at each of @at, NaN outside x's range or
	# beside a NaN y.
	my ( $x, $y, $at ) = @_;
	my @out;
	foreach my $v ( @{$at} ) {
		my $j = bin_index( $v, $x );    # the segment $v is in; undef outside x's range
		if ( not defined $j ) {
			push @out, 'nan';
		} elsif ( ( $j == $#{$x} ) || ( $x->[ $j + 1 ] == $x->[$j] ) ) {
			push @out, $y->[$j];
		} else {
			push @out, $y->[$j] + ( $y->[ $j + 1 ] - $y->[$j] ) * ( $v - $x->[$j] ) / ( $x->[ $j + 1 ] - $x->[$j] );
		}
	}
	return @out;
}
sub draw_wide {
	# Repeated runs of a curve: each run faintly, their mean, and a band one
	# standard deviation either side of it, as write_wide_group draws them.
	my ( $plot, $axes ) = @_;
	my $legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
	my %g = ( set => [], plot => [] );
	my @groups;    # [ \@runs, color, label ]
	if ( ref $plot->{data} eq 'HASH' ) {
		die "$current_sub: \"data\" is a HASH of groups, so \"color\" must be a HASH of one color per group" if ( defined $plot->{color} ) && ( ref $plot->{color} ne 'HASH' );
		my $i = 0;
		foreach my $group ( sort keys %{ $plot->{data} } ) {
			check_wide_runs( $plot->{data}{$group}, "group \"$group\"", $current_sub );
			my $color = defined $plot->{color}{$group} ? hex_of( $plot->{color}{$group}, "\"color\" of \"$group\"" ) : cycle_color($i);
			push @groups, [ $plot->{data}{$group}, $color, $legend ? $group : undef ];
			$i++;
		}
	} elsif ( ref $plot->{data} eq 'ARRAY' ) {
		die "$current_sub: \"data\" is one unlabelled group, so \"color\" must be a single color, not a " . ref( $plot->{color} ) . ' reference' if ref $plot->{color};
		check_wide_runs( $plot->{data}, '"data"', $current_sub );
		push @groups, [ $plot->{data}, ( defined $plot->{color} ? hex_of( $plot->{color}, '"color"' ) : $native ? cycle_color(0) : hex_of( 'b', '"color"' ) ), undef ];
	} else {
		die "$current_sub cannot take ref type \"" . ref( $plot->{data} ) . '" for "data"';
	}
	foreach my $group (@groups) {
		my ( $runs, $color, $label ) = @{$group};
		my @xs = map { finite_values( @{ $_->[0] } ) } @{$runs};
		my ( $lo, $hi ) = ( min(@xs), max(@xs) );
		my @at = linspace( $lo, $hi, 101 );    # as the matplotlib engine's np.linspace(min, max, 101)
		my @ys;
		foreach my $run ( @{$runs} ) {
			my @order = sort { $run->[0][$a] <=> $run->[0][$b] } 0 .. $#{ $run->[0] };    # Perl's sort is stable, as argsort(kind = 'stable')
			my @x = @{ $run->[0] }[@order];
			my @y = @{ $run->[1] }[@order];
			my $block = datablock( [ map { [ $x[$_], $y[$_] ] } 0 .. $#x ] );
			push @{ $g{plot} }, "$block using 1:2 with lines " . lw() . "lc rgb " . gp_color( with_alpha( $color, 0.15 ) ) . ' notitle';
			push @ys, [ interpolate( \@x, \@y, \@at ) ];
		}
		my ( @mean_rows, @band_rows );
		foreach my $k ( 0 .. $#at ) {
			my @v = grep { not is_nan($_) } map { $_->[$k] } @ys;
			if ( scalar @v == 0 ) {    # no run reaches here: a gap, as matplotlib leaves it
				push @mean_rows, [ $at[$k], 'nan' ];
				push @band_rows, [ $at[$k], 'nan', 'nan' ];
				next;
			}
			my $mean = sum(@v) / @v;
			my $sd = sqrt( sum( map { ( $_ - $mean )**2 } @v ) / @v );    # numpy's std, n below the line
			push @mean_rows, [ $at[$k], $mean ];
			push @band_rows, [ $at[$k], $mean - $sd, $mean + $sd ];
		}
		my $band = datablock( \@band_rows );
		push @{ $g{plot} }, "$band using 1:2:3 with filledcurves fs transparent solid 0.3 noborder lc rgb " . gp_color($color) . ' notitle' if defined $band;
		my $mean = datablock( \@mean_rows );
		push @{ $g{plot} }, "$mean using 1:2 with lines " . lw() . "lc rgb " . gp_color($color) . ' ' . key_title($label) if defined $mean;
		$g{legend} = 1 if defined $label;
	}
	return \%g;
}
my %draw = (
	bar => \&draw_bar, barh => \&draw_bar, boxplot => \&draw_boxplot, colored_table => \&draw_colored_table,
	hist => \&draw_hist, hist2d => \&draw_hist2d, imshow => \&draw_imshow, pie => \&draw_pie,
	plot => \&draw_plot, scatter => \&draw_scatter, violin => \&draw_violin, violinplot => \&draw_violin,
	wide => \&draw_wide,
);
sub one_text {
	# A text option as plain_text reads it; one value, not one per call.
	my ( $plot, $option ) = @_;
	my $value = $plot->{$option};
	die "$current_sub: \"$option\" is one piece of text for the gnuplot engine, not a " . ref($value) . ' reference' if ref $value;
	return plain_text( $value, $option, $engine, $current_sub );
}
sub thin_tics {
	# In a subplot of several, the tic commands that leave room between the
	# labels, as matplotlib's locator does (tick_step): gnuplot chooses its
	# tics by the range alone, and a 2 by 2 grid of a 6.4 by 4.8 inch figure
	# had a count axis labelled every 10 from 0 to 80, the labels touching. A
	# number axis gets a step; an axis of category labels too long for the
	# room between them gets a smaller font, as small as 6 points. None for a
	# figure of one plot or a log axis. Under style => 'native' too, since a
	# label running into the next is no part of gnuplot's look: in a native
	# 2 by 2 grid the counts up a hist and "Mark" and "Matthew" overlapped.
	my ( $graphs, $plot, $margin ) = @_;
	return () unless defined $panel_w;
	my @set = map { @{ $_->[1]{set} } } @{$graphs};
	my @out;
	foreach my $axis ( 'x', 'y' ) {
		my $i = ( $axis eq 'x' ) ? 0 : 1;
		next if grep { m/^(?:set logscale \Q$axis\E|unset \Q$axis\Etics)$/ } @set;
		next if grep { ( defined $plot->{$_} ) && ( axis_scale( $plot->{$_}, $_, $engine, $current_sub ) eq 'log' ) } ( $axis eq 'x' ) ? ( 'xscale', 'set_xscale' ) : ( 'yscale', 'set_yscale' );
		my $labels = $tic_labels{$axis};
		if ( defined $labels ) {
			# Category labels. Measured on the PNG of a 2 by 2 grid, where
			# "Mark" and "Matthew" ran together: a character is 0.55 of the
			# font size across on average, neighbours need 0.6 of a character
			# between them, and the n categories of a bar plot, with its bars'
			# widths and margins, span about n + 1 of the room between two;
			# up the side, a label needs 1.3 of the font size.
			next if scalar @{$labels} < 2;
			my $room = plot_length($axis) / ( scalar( @{$labels} ) + 1 );
			my $need = ( $axis eq 'x' )
			 ? 0.55 * max( map { ( length( $labels->[$_] ) + length( $labels->[ $_ - 1 ] ) ) / 2 + 0.6 } 1 .. $#{$labels} )
			 : 1.3;
			my $points = $room / ( $need * $font_scale );    # the size that fits, as matplotlib's 10-point tick labels are sized here
			push @out, sprintf( 'set %stics font ",%.1f"', $axis, max( 6, $points ) * $font_scale ) if $points < 10;
			next;
		}
		# The range: as set, by the plot or the caller, or the data's with the
		# margins write_axes gives it.
		my ( $lo, $hi );
		foreach my $line (@set) {
			( $lo, $hi ) = ( $1, $2 ) if $line =~ m/^set \Q$axis\Erange \[([-+0-9.eE]+):([-+0-9.eE]+)\]$/;
		}
		foreach my $option ( ( $axis eq 'x' ) ? ('set_xlim') : ( 'set_ylim', 'ylim' ) ) {
			next unless defined $plot->{$option};
			my ( $l, $h ) = axis_limits( $plot->{$option}, $option, $engine, $current_sub );
			$lo = $l if defined $l;
			$hi = $h if defined $h;
		}
		if ( ( not defined $lo ) || ( not defined $hi ) ) {
			my @v = grep { ( defined ) && looks_like_number($_) && is_finite($_) } map { $_->[$i] } @extent;
			next if scalar @v == 0;
			my ( $dlo, $dhi ) = ( min(@v), max(@v) );
			my ( $low_side, $high_side ) = ( $axis eq 'x' ) ? ( 'left', 'right' ) : ( 'bottom', 'top' );
			$lo //= $dlo - ( $margin->{$low_side} ? 0.05 * ( $dhi - $dlo ) : 0 );
			$hi //= $dhi + ( $margin->{$high_side} ? 0.05 * ( $dhi - $dlo ) : 0 );
		}
		( $lo, $hi ) = ( $hi, $lo ) if $lo > $hi;    # imshow's y runs downward
		my $step = tick_step( $lo, $hi, tick_bins( plot_length($axis), ( $axis eq 'x' ) ? 3 : 2 ) );
		push @out, "set ${axis}tics " . gp_num($step) if defined $step;
	}
	return @out;
}
sub write_axes {
	# One plot, with its "add" graphs drawn first, on the same axes, as
	# matplotlib draws them.
	my ( $plot, $where ) = @_;
	my $axes = { lines => 0, patches => 0, native => 0 };    # matplotlib's two color cycles are the axes': one for lines, one for bars, wedges and scatter points; gnuplot's one, under style => 'native' (next_color)
	@points = ();
	@extent = ();
	%tic_labels = ();
	my @graphs = map { [ $_, $draw{ $_->{plot_type} }->( $_, $axes ) ] } ( @{ $plot->{add} // [] }, $plot );
	if ( scalar @graphs > 1 ) {
		my @solo = grep { defined $_->[1]{solo} } @graphs;
		die "$current_sub: the gnuplot engine draws plot_type \"$solo[0][1]{solo}\" on axes of its own, so it cannot share them with an \"add\" graph$where" if scalar @solo;
		foreach my $kind ( 'palette', 'categories' ) {
			my @with = grep { $_->[1]{$kind} } @graphs;
			next if scalar @with < 2;
			die "$current_sub: the gnuplot engine has one " . ( $kind eq 'palette' ? 'color scale' : 'set of category labels' ) . ' per plot, and plot types ' . join( ' and ', map { "\"$_->[0]{plot_type}\"" } @with ) . " each have their own$where";
		}
	}
	say {$fh} 'reset';
	print {$fh} @blocks;
	@blocks = ();
	say {$fh} 'set encoding utf8';
	# matplotlib's 5% margin round the data (rcParams axes.xmargin and
	# ymargin), but none below a bar or a bin, which sit on the axis.
	my %margin = map { $_ => 'graph 0.05' } ( 'left', 'right', 'top', 'bottom' );
	$margin{$_} = 0 foreach map { @{ $_->[1]{no_margin} // [] } } @graphs;
	# Under style => 'native', none of matplotlib's look: gnuplot's own tics,
	# fill, error bar caps, and autoscaling out to the next tic.
	if ( not $native ) {
		say {$fh} 'set tics out nomirror';
		say {$fh} 'set style fill solid 1.0 noborder';
		say {$fh} 'set errorbars 0';    # matplotlib's error bars have no caps (rcParams errorbar.capsize)
		say {$fh} 'set autoscale fix';
		say {$fh} 'set offsets ' . join( ', ', @margin{ 'left', 'right', 'top', 'bottom' } );
	}
	say {$fh} $_ foreach map { @{ $_->[1]{set} } } @graphs;
	my %text;
	foreach my $pair ( [ 'title', 'set_title' ], [ 'xlabel', 'set_xlabel' ], [ 'ylabel', 'set_ylabel' ] ) {
		my ( $short, $long ) = @{$pair};
		# "title" wins over "set_title", as plt's rename of one to the other
		my $given = defined $plot->{$short} ? $short : defined $plot->{$long} ? $long : undef;
		$text{$short} = one_text( $plot, $given ) if defined $given;
	}
	foreach my $axis ( 'x', 'y' ) {
		next if defined $text{"${axis}label"};
		my ($default) = grep { defined } map { $_->[1]{"default_${axis}label"} } @graphs;
		$text{"${axis}label"} = $default if defined $default;
	}
	say {$fh} "set title " . gp_str( $text{title} ) . ( $native ? '' : sprintf( ' font ",%.1f"', 12 * $font_scale ) ) if defined $text{title};    # matplotlib's title is 12 points (rcParams axes.titlesize)
	say {$fh} "set ${_} " . gp_str( $text{$_} ) foreach grep { defined $text{$_} } ( 'xlabel', 'ylabel' );
	foreach my $range ( [ 'set_xlim', 'x' ], [ 'set_ylim', 'y' ], [ 'ylim', 'y' ] ) {
		my ( $option, $axis ) = @{$range};
		next unless defined $plot->{$option};
		my ( $lo, $hi ) = axis_limits( $plot->{$option}, $option, $engine, $current_sub );
		say {$fh} "set ${axis}range [" . ( defined $lo ? gp_num($lo) : '*' ) . ':' . ( defined $hi ? gp_num($hi) : '*' ) . ']';
	}
	foreach my $option ( grep { defined $plot->{$_} } ( 'xscale', 'set_xscale', 'yscale', 'set_yscale' ) ) {
		my $axis = ( $option =~ m/x/ ) ? 'x' : 'y';
		say {$fh} ( ( axis_scale( $plot->{$option}, $option, $engine, $current_sub ) eq 'log' ) ? "set logscale $axis" : "unset logscale $axis" );
	}
	say {$fh} $_ foreach thin_tics( \@graphs, $plot, \%margin );
	if ( ( grep { $_->[1]{legend} } @graphs ) && $native ) {
		# gnuplot's own place for the key, but opaque: gnuplot draws each entry
		# as it draws that clause, so later bars covered the earlier entries of a
		# grouped or stacked bar plot, and its legend could not be read.
		say {$fh} 'set key default';
		say {$fh} 'set key opaque';
	} elsif ( grep { $_->[1]{legend} } @graphs ) {
		say {$fh} 'set key inside ' . key_place() . ' opaque box reverse Left samplen 2 spacing 1.1 width 1 vertical maxcols 1';
	} else {
		say {$fh} 'unset key';
	}
	my @clauses = map { @{ $_->[1]{plot} } } @graphs;
	if ( scalar @clauses == 0 ) {    # nothing finite to draw: the axes alone, as matplotlib leaves them
		say {$fh} 'set xrange [0:1]' unless grep { /^set xrange/ } map { @{ $_->[1]{set} } } @graphs;
		say {$fh} 'set yrange [0:1]';
		@clauses = ('NaN notitle');
	}
	say {$fh} 'plot ' . join( ", \\\n\t", @clauses );
}
# The SVGs each script draws, which are given their creator note once it has
# run: script's path => [ [ output_file, creator_note ], ... ]. A shared "fh"
# gathers every figure written into it, and is run by the last.
my %svg_notes;
sub creator_user {
	# Who is running gnuplot, found as Python's getpass.getuser() finds the user
	# for the matplotlib engine's note (Python 3.14, Lib/getpass.py): the first
	# of these variables that is set, then the password database.
	foreach my $name ( 'LOGNAME', 'USER', 'LNAME', 'USERNAME' ) {
		return decoded_text( $ENV{$name} ) if ( defined $ENV{$name} ) && ( $ENV{$name} ne '' );
	}
	my $user = eval { ( getpwuid $< )[0] };    # getpwuid dies as unimplemented on MSWin32
	return ( ( defined $user ) && ( $user ne '' ) ) ? decoded_text($user) : 'unknown user';
}
sub creator_svg {
	# Give an SVG gnuplot has drawn the note matplotlib gives its own, in
	# <dc:title>. gnuplot has no way to write metadata, nor to read the user or
	# the host, so this is done here once it has run, and not by a script
	# written with "execute => 0" and run later. gnuplot's own <title>Gnuplot</title>,
	# which a browser shows as the figure's name, and its <desc>, whose version
	# this note now carries, are taken out: the note is all the metadata an
	# SVG from matplotlib has.
	my ( $file, $note, $version ) = @_;
	my $host = eval { Sys::Hostname::hostname() };    # dies when it cannot find the name
	$host = ( ( defined $host ) && ( $host ne '' ) ) ? decoded_text($host) : 'unknown host';
	$note = decoded_text($note) . ", gnuplot $version, by " . creator_user() . " on $host";
	$note =~ s/&/&amp;/g;    # first, or the escapes below would be escaped again
	$note =~ s/</&lt;/g;
	$note =~ s/>/&gt;/g;
	open my $in, '<:raw', $file or die "$current_sub: can't read \"$file\", which gnuplot was to write: $!";
	my $svg = do { local $/; <$in> };
	close $in or die "$current_sub: can't close \"$file\": $!";
	$svg =~ s{<title>Gnuplot</title>\n}{};
	$svg =~ s{<desc>Produced by GNUPLOT[^<]*</desc>\n}{};
	my ( $before, $after ) = svg_creator_metadata();
	$svg =~ s{(<svg\b[^>]*>)}{$1 . Encode::encode( 'UTF-8', $before . $note . $after )}e
	 or die "$current_sub: \"$file\" has no <svg> tag for the creator note to follow";
	open my $out, '>:raw', $file or die "$current_sub: can't write \"$file\": $!";
	print {$out} $svg;
	close $out or die "$current_sub: can't close \"$file\": $!";
}
sub render {
	# plt's figure as a gnuplot script, which is run unless "execute" is false.
	# Returns the script's path. Takes what Matplotlib::Simple::Matplotlib::render does.
	my ( $args, $context ) = @_;
	$current_sub = $context->{sub};
	$native = ( ( $context->{style} // 'native' ) eq 'native' ) ? 1 : 0;
	( $n_blocks, @blocks ) = (0);
	my $file = $args->{output_file};
	my ($ext) = ( $file =~ m/\.([^.\/\\]+)\z/ );
	$ext = lc( $ext // '' );
	$px_per_pt  = ( $ext eq 'pdf' ) ? 1 : 100 / 72;
	$font_scale = ( $ext eq 'pdf' ) ? 1 : 1.1;
	# In 15 digits, as a double perl stringifies it; a quadmath perl wrote all 36.
	$point_size = sprintf '%.15g', 1.1 * $px_per_pt;
	if ( not defined $terminal_of{$ext} ) {
		die "$current_sub: the gnuplot engine writes " . join( ', ', map { ".$_" } sort keys %terminal_of ) . " files, and \"$file\" is none of them; engine => 'matplotlib' writes the rest";
	}
	my ( $w, $h ) = ( $fig_width, $fig_height );
	$w *= $args->{scale}  // 1;
	$h *= $args->{scale}  // 1;
	$w *= $args->{scalex} // 1;
	$h *= $args->{scaley} // 1;
	my @plots = $context->{single_plot} ? ( [ $args, '' ] ) : map { [ $args->{plots}[$_], " at subplot $_" ] } 0 .. $#{ $args->{plots} };
	( $panel_w, $panel_h ) = ( $args->{nrows} * $args->{ncols} > 1 ) ? ( $w / $args->{ncols}, $h / $args->{nrows} ) : ( undef, undef );
	# Everything is drawn into a string first, so that a plot refused part
	# way leaves nothing of the figure in a shared "fh".
	my $script = '';
	open $fh, '>:encoding(UTF-8)', \$script or die "can't write to a string: $!";
	foreach my $plot (@plots) {
		write_axes( @{$plot} );
	}
	close $fh;
	my $suptitle = defined $args->{suptitle} ? one_text( $args, 'suptitle' ) : undef;
	my $multiplot = ( ( scalar @plots > 1 ) || ( defined $suptitle ) ) ? 1 : 0;
	# A lexical, not $fh: the file is flushed and closed when it goes out of
	# scope, as Matplotlib::Simple::Matplotlib's is, so that the script is whole when the
	# caller reads it.
	my $out = script_handle( $args, '.gp', $current_sub );
	( my $note = creator_note($current_sub) ) =~ s/[\r\n]+/ /g;    # a comment ends at the line's end
	say {$out} "# $note";
	# Each figure from a clean slate: a shared "fh" holds several, and gnuplot
	# keeps every setting from one plot to the next.
	say {$out} 'reset session';
	say {$out} 'set encoding utf8';
	say {$out} 'set terminal ' . $terminal_of{$ext}->( $w, $h );
	say {$out} 'set output ' . gp_str($file);
	say {$out} "set multiplot layout $args->{nrows},$args->{ncols}" . ( defined $suptitle ? ' title ' . gp_str($suptitle) : '' ) if $multiplot;
	print {$out} Encode::decode( 'UTF-8', $script );
	say {$out} 'unset multiplot' if $multiplot;
	say {$out} 'unset output';
	# To STDERR, where "print" writes, for creator_svg to read once the script
	# has run. GPVAL_VERSION is a number, such as 6.0, and the patch level text.
	say {$out} 'print sprintf("Matplotlib::Simple gnuplot %.1f.%s", GPVAL_VERSION, GPVAL_PATCHLEVEL)';
	push @{ $svg_notes{ $out->filename } }, [ $file, creator_note($current_sub) ] if $ext eq 'svg';
	if ( $args->{execute} ) {
		my $stderr = run_script( [ program_from_env('MATPLOTLIB_SIMPLE_GNUPLOT') // 'gnuplot', $out->filename ] );
		my ($version) = $stderr =~ m/^Matplotlib::Simple gnuplot (\S+)$/m;
		foreach my $svg ( @{ delete $svg_notes{ $out->filename } // [] } ) {
			creator_svg( @{$svg}, $version // 'of unknown version' );
		}
	}
	say 'will write ' . "\e[36;103m$file\e[0m";
	return $out->filename;
}
1;
