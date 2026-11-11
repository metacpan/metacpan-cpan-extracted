use strict;
use feature 'say';
use warnings FATAL => 'all';

package Matplotlib::Simple::Ggplot2;
# The ggplot2 engine: it writes plt's figure as an R script that draws it with
# ggplot2, and runs that script with Rscript. Matplotlib::Simple checks the arguments and
# refuses, by name, every plot type and keyword not listed below; render() is
# given what is left.
#
# The figure is meant to be the one matplotlib draws from the same arguments,
# so the semantics of each type -- the shapes of "data", the order of the keys,
# the defaults -- are those of the matching *_helper in Matplotlib::Simple::Matplotlib,
# and the binning, the box and whisker statistics, the pie's wedges and the
# summaries of "wide" are worked out here, in Perl, as numpy and matplotlib
# work them out, rather than left to ggplot2's own stats, which differ: a
# ggplot2 histogram bins every set over one shared range, where matplotlib bins
# each set over its own; geom_violin's default bandwidth is R's bw.nrd0, where
# matplotlib uses Scott's rule. Every position is numeric, at the place
# matplotlib puts it -- bars at 0 .. n-1, boxes and violins at 1 .. n -- so that
# an "add" graph lands where it would under matplotlib.
#
# That is "style => 'matplotlib'", the default. Under "style => 'native'"
# (%Matplotlib::Simple::styles) ggplot2 decides instead: series given no color take its
# default hue scale and a colormap not asked for its default gradient; hist,
# boxplot, violin and hist2d are drawn by its own stats -- stat_bin,
# stat_boxplot, stat_ydensity, stat_bin_2d -- with their defaults; bars,
# boxes and violins stand on a discrete axis of their keys; and the theme is
# its default, theme_grey. wide and pie have no stat of ggplot2's to compute
# them, so their summaries and wedges are still worked out here.
#
# Only ggplot2 and base R (grid, grDevices, stats) are used: the data is
# written into the script as R literals, and the subplots of a grid are placed
# with grid's own layouts, not patchwork or cowplot, which ggplot2 does not
# depend on.
require 5.010;
our $VERSION = 0.3343;
use Scalar::Util 'looks_like_number';
use List::Util qw(max min sum);
BEGIN { require Matplotlib::Simple }
BEGIN {
	no strict 'refs';
	*{$_} = \&{"Matplotlib::Simple::$_"} foreach qw(as_double axis_limits axis_scale bin_counts bool_option
	 cb_limits check_key_order check_numbers check_scatter_lengths check_scatter_values
	 check_wide_runs color_hex colormap_colors creator_note decoded_text double_literal finite_values
	 is_finite is_nan linspace logscale_axes logspace nonfinite_name plain_text program_from_env
	 run_script script_handle svg_creator_metadata table_cells);
}
# The plot types drawn, each with the keywords of Matplotlib::Simple's %opt that are
# read for it. hexbin is not here because geom_hex needs the hexbin package,
# which ggplot2 does not depend on; venn_proportional_area is not here because
# ggplot2 has no area-proportional Venn diagram. Neither is any keyword whose
# meaning is matplotlib's own: "set_options" and "legend" are Python argument
# lists, "tooltips" are drawn into the SVG matplotlib writes, "twinx" is a
# second y axis, which ggplot2 has only as a transform of the first.
our %types = (
	bar           => [qw(color edgecolor key_order label log logscale stacked width xerr yerr)],
	barh          => [qw(color edgecolor key_order label log logscale stacked width xerr yerr)],
	boxplot       => [qw(color colors key_order logscale notch orientation showcaps showfliers showmeans)],
	colored_table => [qw(cb_logscale cb_max cb_min cblabel cmap col_labels colorbar_on default_undefined mirror row_labels show_numbers undef_color)],
	hist          => [qw(alpha bins color key_order logscale orientation show_legend)],
	hist2d        => [qw(cb_logscale cb_max cb_min cblabel cmap cmax cmin colorbar_on density key_order logscale show_colorbar vmax vmin xbins xmax xmin ybins ymax ymin)],
	imshow        => [qw(cb_logscale cb_max cb_min cblabel cmap colorbar_on stringmap vmax vmin)],
	pie           => [qw(autopct key_order labeldistance pctdistance)],
	plot          => [qw(key_order logscale show_legend)],
	scatter       => [qw(cb_logscale cb_max cb_min cblabel cmap color_key colorbar_on key_order keys logscale show_legend)],
	violin        => [qw(color colors edgecolor key_order logscale medians orientation whiskers)],
	violinplot    => [qw(color colors edgecolor key_order logscale medians orientation whiskers)],
	wide          => [qw(color show_legend)],
);
our @plot_keywords = qw(set_title set_xlabel set_xlim set_xscale set_ylabel set_ylim
 set_yscale title xlabel xscale ylabel ylim yscale);
# No "show": Rscript runs the script and exits, so a window it opened would
# close as soon as it was drawn.
our @figure_keywords = qw(scale scalex scaley suptitle);
my $engine = 'ggplot2';
# The oldest ggplot2 the script runs with: 3.5.0 brought the "transform"
# argument of the position scales (before it, "trans") and geom_boxplot's
# "staplewidth", which draws the caps matplotlib draws on every whisker. The
# script checks it before it draws, and t/18.ggplot2.t gates its render checks
# on it.
our $min_ggplot2 = '3.5.0';
# matplotlib's default property cycle, "C0" to "C9", from Matplotlib::Simple::Colors: an
# artist given no color takes the next of these, per subplot.
my @cycle = map { color_hex( "C$_", 'the color cycle', $engine, 'Matplotlib::Simple::Ggplot2' ) } 0 .. 9;
# matplotlib's default sizes, in ggplot2's units: lines 1.5 pt wide, and
# markers 6 pt across, as ggplot2's "size" (3, measured against matplotlib's
# markers in PNGs of the same data at the same size) and
# "linewidth" (a millimetre per unit, so 1.5 pt / 2.845 pt per mm).
my $line_mm   = 0.53;
my $marker_mm = 3;
# The figure, as matplotlib sizes it: 6.4 x 4.8 inches, at 100 dots per inch
# for a PNG (matplotlib's rcParams figure.figsize and figure.dpi).
my ( $fig_w, $fig_h, $png_dpi ) = ( 6.4, 4.8, 100 );

sub r_str {
	# A Perl string as an R string literal, in ASCII: every character that is
	# not printable ASCII is an escape, so the script reads the same in
	# whatever encoding Rscript takes it to be in -- on Windows that is not
	# always UTF-8. R has no way to write a NUL in a string, so one is refused.
	my ($str) = @_;
	$str = decoded_text( $str // '' );
	die "Matplotlib::Simple: the $engine engine cannot write text holding a NUL character into R" if $str =~ m/\x00/;
	$str =~ s/\\/\\\\/g;    # first, or the escapes below would be doubled
	$str =~ s/"/\\"/g;
	$str =~ s/\n/\\n/g;
	$str =~ s/\r/\\r/g;
	$str =~ s/\t/\\t/g;
	$str =~ s/([^\x20-\x7e])/ord($1) > 0xffff ? sprintf( '\\U{%x}', ord $1 ) : sprintf( '\\u{%x}', ord $1 )/ge;
	return qq{"$str"};
}
sub r_num {
	# A number as an R numeric literal: NA for undef, NaN, Inf and -Inf for
	# the values Perl and numpy call nan and inf, and a finite value as
	# double_literal writes it, as gp_num does for gnuplot. A value already
	# written as R would write it was passed through as it stood, but Perl
	# stringifies a computed number to 15 digits, so 1/3 lost its last two.
	my ($n) = @_;
	return 'NA' unless defined $n;
	my $nonfinite = nonfinite_name($n);
	return { nan => 'NaN', inf => 'Inf', '-inf' => '-Inf' }->{$nonfinite} if defined $nonfinite;
	return double_literal($n);
}
sub r_nums { return 'c(' . join( ', ', map { r_num($_) } @_ ) . ')' }
sub r_strs { return 'c(' . join( ', ', map { r_str($_) } @_ ) . ')' }
sub r_frame {
	# A data.frame literal from ( name => R vector, ... ), in that order.
	my @cols = @_;
	my @parts;
	while ( my ( $name, $vector ) = splice @cols, 0, 2 ) {
		push @parts, "$name = $vector";
	}
	return 'data.frame(' . join( ', ', @parts, 'stringsAsFactors = FALSE' ) . ')';
}
sub next_color {
	# The next color of matplotlib's cycle for this subplot, for an artist of
	# the kind given: 'line' (plot, violinplot) or 'patch' (bar, hist, pie,
	# scatter). matplotlib keeps one cycle of each per axes -- _get_lines and
	# _get_patches_for_fill -- so a scatter over a line both start at C0.
	# Under "native" there is no cycle, and undef leaves the color to ggplot2.
	my ( $s, $kind ) = @_;
	return undef if $s->{native};
	return $cycle[ $s->{cycle}{$kind}++ % scalar @cycle ];
}
sub color_of {
	# color_hex, naming the option, the key and the plot in what it refuses.
	my ( $color, $what, $sub ) = @_;
	return color_hex( $color, $what, $engine, $sub );
}
sub percentile {
	# numpy.percentile's default, "linear", of a sorted list: the value at
	# rank (n - 1) * p, interpolated. R's quantile() type 7, which
	# geom_boxplot uses, is the same rule.
	my ( $sorted, $p ) = @_;
	my $h  = ( scalar @{$sorted} - 1 ) * $p;
	my $lo = int $h;
	return $sorted->[$lo] if $lo >= $#{$sorted};
	return $sorted->[$lo] + ( $h - $lo ) * ( $sorted->[ $lo + 1 ] - $sorted->[$lo] );
}
sub with_commas {
	# A whole number with a comma every three digits, as format_commas in
	# Matplotlib::Simple::Matplotlib writes the counts under a box or a violin.
	my ($n) = @_;
	1 while $n =~ s/^(\d+)(\d{3})/$1,$2/;
	return $n;
}
sub colormap_at {
	# A colormap's color at a point from 0 to 1, interpolated between the
	# stops Matplotlib::Simple::Colors keeps, as "#rrggbb".
	my ( $stops, $t ) = @_;
	my $pos = $t * ( scalar @{$stops} - 1 );
	my $i   = min( int $pos, $#{$stops} - 1 );
	my $f   = $pos - $i;
	my @a   = map { hex } substr( $stops->[$i], 1 ) =~ m/(..)(..)(..)/;
	my @b   = map { hex } substr( $stops->[ $i + 1 ], 1 ) =~ m/(..)(..)(..)/;
	return '#' . join '', map { sprintf '%02x', int( $a[$_] + $f * ( $b[$_] - $a[$_] ) + 0.5 ) } 0 .. 2;
}
sub bin_index {
	# The bin of $v among ascending $edges, numpy.histogram's way: each bin
	# holds its left edge, the last holds its right edge too, and a value
	# outside them all is in none (undef). The edges are doubles, and $v is
	# rounded to one before it is compared with them; see as_double.
	my ( $edges, $v ) = @_;
	$v = as_double($v);
	return undef if ( $v < $edges->[0] ) || ( $v > $edges->[-1] );
	return $#{$edges} - 1 if $v == $edges->[-1];
	my ( $lo, $hi ) = ( 0, $#{$edges} );
	while ( $hi - $lo > 1 ) {
		my $mid = int( ( $lo + $hi ) / 2 );
		if ( $v >= $edges->[$mid] ) { $lo = $mid } else { $hi = $mid }
	}
	return $lo;
}
sub new_panel {
	# One subplot as it is built up: its layers, in the order they are drawn,
	# and what its scales, legend and labels need to say.
	return {
		layers   => [],
		colour_d => [],    # [ legend name, color ] of lines and points
		fill_d   => [],    # [ legend name, color ] of areas
		shape_d  => [],    # [ legend name, R point shape ]
		gradient => undef, # the one continuous color scale, if any
		axis     => { x => {}, y => {} },
		default_label => {},
		cycle    => { line => 0, patch => 0 },
		kind     => 'cartesian',    # 'cartesian', 'pie' or 'table'
		native   => $_[0] ? 1 : 0,  # 1 = style "native", 0 = style "matplotlib"
	};
}
sub add_legend {
	# Add a series to a legend, once: a name already there keeps its color.
	# Under "native" a color may be undef, for ggplot2's hue scale to fill in.
	my ( $list, $name, $value ) = @_;
	push @{$list}, [ $name, $value ] unless grep { $_->[0] eq $name } @{$list};
}
sub set_gradient {
	# The subplot's continuous color scale. ggplot2 has one per aesthetic, so
	# a second -- an "add" graph that colors by value over a plot that already
	# does -- is refused rather than drawn against the first one's colors.
	my ( $s, $gradient, $where, $sub ) = @_;
	if ( defined $s->{gradient} ) {
		die "$sub: the $engine engine draws one color scale per plot, and $gradient->{type}$where would be a second one beside $s->{gradient}{type}'s";
	}
	$s->{gradient} = $gradient;
}
sub key_order_of {
	# The keys in the order drawn: "key_order", or sorted.
	my ( $plot, $data, $option, $sub ) = @_;
	return check_key_order({ keys => $plot->{$option}, data => $data, option => $option, sub => $sub }) if defined $plot->{$option};
	return sort keys %{$data};
}
sub value_axis_log {
	# The axes "logscale" names, refusing the one that holds the keys of a
	# boxplot or violin, which are categories, not a scale.
	my ( $plot, $key_axis, $sub ) = @_;
	my @axes = logscale_axes( $plot->{logscale}, $sub );
	if ( grep { $_ eq $key_axis } @axes ) {
		die "$sub: \"logscale\" asks for a log $key_axis axis, but the $key_axis axis of this $plot->{plot_type} holds its keys; the $engine engine puts only the axis of values on a log scale";
	}
	return @axes;
}
sub line_width {
	# The width of a line, as an argument: matplotlib's 1.5 pt, or nothing,
	# for ggplot2's own 0.5 mm, under "native".
	my ($s) = @_;
	return $s->{native} ? '' : ", linewidth = $line_mm";
}
sub marker_size {
	# The size of a marker, as line_width gives a line's.
	my ($s) = @_;
	return $s->{native} ? '' : ", size = $marker_mm";
}
sub category_ticks {
	# Tick positions and labels for the axis that holds the keys.
	my ( $s, $axis, $positions, $labels ) = @_;
	$s->{axis}{$axis}{breaks} = $positions;
	$s->{axis}{$axis}{labels} = $labels;
}

# ---------------------------------------------------------------------------
# One drawer per plot type, each adding its layers to the subplot $s. Each is
# barplot_helper, boxplot_helper and the rest of Matplotlib::Simple::Matplotlib over
# again, with the same checks, which die before anything is written.
# ---------------------------------------------------------------------------
sub draw_bar {
	my ( $plot, $s, $where, $sub ) = @_;
	my $horizontal = ( $plot->{plot_type} eq 'barh' ) ? 1 : 0;
	my ( $pos_axis, $val_axis ) = $horizontal ? ( 'y', 'x' ) : ( 'x', 'y' );
	my $data = $plot->{data};
	my %ref_counts;
	$ref_counts{ ref $data->{$_} }++ foreach keys %{$data};
	if ( scalar keys %ref_counts > 1 ) {
		die "$sub: different kinds of data were entered$where, which should be a simple hash, a hash of arrays or a hash of hashes";
	}
	my ( $form, @series_names, %series_color );
	my %values;    # key => array of one value per series
	if ( defined $ref_counts{''} ) {
		$form = 'simple';
		$values{$_} = [ $data->{$_} ] foreach keys %{$data};
	} elsif ( defined $ref_counts{ARRAY} ) {
		$form = 'grouped';
		$values{$_} = $data->{$_} foreach keys %{$data};
		if ( defined $plot->{label} ) {
			die "$sub: \"label\"$where is an array of one label per series" unless ref $plot->{label} eq 'ARRAY';
			@series_names = @{ $plot->{label} };
		}
	} elsif ( defined $ref_counts{HASH} ) {
		$form = 'grouped';
		my %inner;
		foreach my $k1 ( keys %{$data} ) {
			$inner{$_}++ foreach keys %{ $data->{$k1} };
		}
		@series_names = sort { lc $a cmp lc $b || $a cmp $b } keys %inner;
		foreach my $k1 ( keys %{$data} ) {
			$values{$k1} = [ @{ $data->{$k1} }{@series_names} ];
		}
		if ( ref $plot->{color} eq 'HASH' ) {
			my @uncolored = grep { not defined $plot->{color}{$_} } @series_names;
			die "$sub: the series " . join( ', ', map { "\"$_\"" } @uncolored ) . " have no color in \"color\"$where" if scalar @uncolored > 0;
			%series_color = map { $_ => $plot->{color}{$_} } @series_names;
		}
	} else {
		die "$sub: \"data\"$where holds " . join( ', ', sort keys %ref_counts ) . ' references, which bar and barh do not draw';
	}
	my $stacked = bool_option( $plot->{stacked}, 'stacked', $sub );
	if ( defined $plot->{width} ) {
		die "$sub: \"width\" is one number for every bar, not a " . ref( $plot->{width} ) . ' reference' if ref $plot->{width};
		check_numbers( [ $plot->{width} ], '"width"', $sub );
		die "$sub: \"width\" must be a finite number, not \"$plot->{width}\"" unless is_finite( $plot->{width} );
	}
	if ( ( $form eq 'grouped' ) && ( defined $plot->{width} ) && ( not $stacked ) ) {
		# Left out, as the matplotlib engine leaves it; reset only here, the
		# native style's geom_col and a log axis's bars still drew it.
		say STDERR 'grouped, non-stacked barplots ignore width settings';    # as matplotlib's engine says
		delete $plot->{width};
	}
	my $width = $plot->{width} // 0.8;
	my @keys = key_order_of( $plot, $data, 'key_order', $sub );
	if ( ( $form eq 'grouped' ) && ( ref $plot->{color} eq 'HASH' ) && ( not %series_color ) ) {
		die "$sub: \"color\" is a HASH, but this data is a hash of arrays, whose series have no names to key it by: give one color per series as an array, e.g. color => ['red','blue']";
	}
	foreach my $key (@keys) {
		my @bad = grep { ( defined $_ ) && ( not looks_like_number($_) ) } @{ $values{$key} };
		die "$sub: \"$key\"$where has values that are not numbers: \"" . join( '", "', @bad ) . '"' if scalar @bad > 0;
		die "$sub: \"$key\" has an undefined value, which $plot->{plot_type} cannot draw" if ( $form eq 'simple' ) && ( not defined $values{$key}[0] );
	}
	my $n_series = 1;
	if ( $form eq 'grouped' ) {
		my %lengths = map { scalar @{ $values{$_} } => 1 } @keys;
		die "$sub: every key of a grouped $plot->{plot_type} needs the same number of values$where" if scalar keys %lengths > 1;
		($n_series) = keys %lengths;
		die "$sub: every key of \"data\" holds an empty array, so $plot->{plot_type} has no bars to draw" if $n_series == 0;
	}
	my $log = bool_option( $plot->{log}, 'log', $sub ) || $plot->{logscale};    # "logscale" takes Perl truth, as documented
	$s->{axis}{$val_axis}{log} = 1 if $log;
	my $n = scalar @keys;
	# Edge colors: one for all, an array cycled over the bars, or a hash by key
	# (a simple hash alone has a bar per key to key it by).
	my $edge_of = sub { 'NA' };
	if ( defined $plot->{edgecolor} ) {
		my $edge = $plot->{edgecolor};
		if ( ref $edge eq 'ARRAY' ) {
			die "$sub: \"edgecolor\"$where is an empty array" if scalar @{$edge} == 0;
			my @hex = map { r_str( color_of( $_, '"edgecolor"', $sub ) ) } @{$edge};
			$edge_of = sub { $hex[ $_[0] % scalar @hex ] };
		} elsif ( ref $edge eq 'HASH' ) {
			die "$sub: \"edgecolor\" is a HASH, which is keyed by bar and so only fits a simple hash of one bar per key: give a grouped plot one color, or an array of one per key" if $form eq 'grouped';
			my @uncolored = grep { not defined $edge->{$_} } @keys;
			die "$sub: the keys " . join( ', ', map { "\"$_\"" } @uncolored ) . " have no color in \"edgecolor\"" if scalar @uncolored > 0;
			my @hex = map { r_str( color_of( $edge->{$_}, "\"edgecolor\" of \"$_\"", $sub ) ) } @keys;
			$edge_of = sub { $hex[ $_[0] ] };
		} else {
			my $hex = r_str( color_of( $edge, '"edgecolor"', $sub ) );
			$edge_of = sub { $hex };
		}
	}
	if ( ( $form eq 'grouped' ) && ( grep { defined $plot->{$_} } ( 'xerr', 'yerr' ) ) ) {
		my ($err) = grep { defined $plot->{$_} } ( 'xerr', 'yerr' );
		die "$sub: \"$err\"$where: the $engine engine draws error bars on a bar chart of one bar per key, not on a grouped or stacked one";
	}
	if ( $s->{native} ) {
		draw_bar_native({ plot => $plot, s => $s, keys => \@keys, values => \%values, form => $form, n_series => $n_series,
			series_names => \@series_names, series_color => \%series_color, stacked => $stacked, edge_of => $edge_of,
			horizontal => $horizontal, where => $where, sub => $sub });
		return;
	}
	my ( @rects, @fills, @edges, @legend_names );
	if ( $form eq 'simple' ) {
		my @colors = simple_bar_colors( $plot, \@keys, $where, $sub );
		@colors = (next_color( $s, 'patch' )) x $n if scalar @colors == 0;
		foreach my $i ( 0 .. $n - 1 ) {
			push @rects, [ $i - $width / 2, $i + $width / 2, 0, $values{ $keys[$i] }[0] ];
			push @fills, $colors[$i];
			push @edges, $edge_of->($i);
		}
		draw_bar_errors( $plot, $s, \@keys, $horizontal, $where, $sub );
		category_ticks( $s, $pos_axis, [ 0 .. $n - 1 ], \@keys );
	} else {
		my $bar_w = $stacked ? $width : $width / ( $n_series + 1 );
		my @bottom = (0) x $n;
		my @tick = (0) x $n;
		foreach my $i ( 0 .. $n_series - 1 ) {
			my $color;
			if (%series_color) {
				$color = color_of( $series_color{ $series_names[$i] }, "\"color\" of \"$series_names[$i]\"", $sub );
			} elsif ( ( ref $plot->{color} eq 'ARRAY' ) && ( defined $plot->{color}[$i] ) ) {
				$color = color_of( $plot->{color}[$i], '"color"', $sub );
			} elsif ( ( defined $plot->{color} ) && ( not ref $plot->{color} ) ) {
				$color = color_of( $plot->{color}, '"color"', $sub );
			} else {
				$color = next_color( $s, 'patch' );
			}
			my $label = $series_names[$i];
			add_legend( $s->{fill_d}, $label, $color ) if defined $label;
			foreach my $k ( 0 .. $n - 1 ) {
				my $v = $values{ $keys[$k] }[$i] // 0;    # every series has a bar at every key
				my $centre = $stacked ? $k : $k + $i * $bar_w;
				$tick[$k] += $centre;
				push @rects, [ $centre - $bar_w / 2, $centre + $bar_w / 2, $bottom[$k], $bottom[$k] + $v ];
				$bottom[$k] += $v if $stacked;
				push @fills, $color;
				push @edges, $edge_of->($k);
				push @legend_names, $label;
			}
		}
		category_ticks( $s, $pos_axis, [ map { $_ / $n_series } @tick ], \@keys );
	}
	if ($log) {
		# A bar stands on 0, which a log axis cannot place: log10(0) is -Inf,
		# which ggplot2 leaves out of the axis's range, so a bar of 1 had no
		# height above an axis that started at 1. matplotlib's axis starts its
		# 5% margin below the lowest bar top, in log units, with each bar drawn
		# up from the bottom edge; so each bar here stands on that point, and
		# the axis is given no margin below it.
		my @tops = grep { $_ > 0 } map { $_->[3] } @rects;
		if (@tops) {
			my ( $lo, $hi ) = ( log10( min(@tops) ), log10( max(@tops) ) );
			my $floor = ( $hi > $lo ) ? 10**( $lo - 0.05 * ( $hi - $lo ) ) : 10**( $lo - 1 );    # a decade below, for bars all of one height
			$_->[2] = $floor foreach grep { $_->[2] <= 0 } @rects;
			$s->{axis}{$val_axis}{floor} = 1;
		}
	}
	my ( $p_lo, $p_hi, $v_lo, $v_hi ) = $horizontal ? ( 'ymin', 'ymax', 'xmin', 'xmax' ) : ( 'xmin', 'xmax', 'ymin', 'ymax' );
	my @cols = (
		$p_lo => r_nums( map { $_->[0] } @rects ),
		$p_hi => r_nums( map { $_->[1] } @rects ),
		$v_lo => r_nums( map { $_->[2] } @rects ),
		$v_hi => r_nums( map { $_->[3] } @rects ),
	);
	my $aes = 'xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax';
	my $fill;
	if ( grep { defined } @legend_names ) {
		# The bars of a labelled series are mapped to the legend; matplotlib
		# leaves a series out of it when "label" has no name for it.
		my @mapped = grep { defined $legend_names[$_] } 0 .. $#rects;
		my @plain  = grep { not defined $legend_names[$_] } 0 .. $#rects;
		push @{ $s->{layers} }, rect_layer( \@rects, [ @fills[@plain] ], [ @edges[@plain] ], \@plain, $horizontal ) if @plain;
		push @{ $s->{layers} }, 'ggplot2::geom_rect(data = ' . r_frame( map_rects( \@rects, \@mapped, $horizontal ), s => r_strs( @legend_names[@mapped] ) )
		 . ", ggplot2::aes($aes, fill = s), colour = c(" . join( ', ', @edges[@mapped] ) . '), na.rm = TRUE)';
		return;
	}
	push @{ $s->{layers} }, rect_layer( \@rects, \@fills, \@edges, [ 0 .. $#rects ], $horizontal );
}
sub simple_bar_colors {
	# The fill of each bar of a bar chart of one bar per key, from "color": a
	# hash by key, an array cycled over the bars, or one for all. An empty list
	# where "color" is not given, for the caller's default.
	my ( $plot, $keys, $where, $sub ) = @_;
	my $color = $plot->{color};
	my $n = scalar @{$keys};
	if ( ref $color eq 'HASH' ) {
		my @uncolored = grep { not defined $color->{$_} } @{$keys};
		die "$sub: the keys " . join( ', ', map { "\"$_\"" } @uncolored ) . ' were not defined in the colors hash' if scalar @uncolored > 0;
		return map { color_of( $color->{$_}, "\"color\" of \"$_\"", $sub ) } @{$keys};
	} elsif ( ref $color eq 'ARRAY' ) {
		die "$sub: \"color\"$where is an empty array" if scalar @{$color} == 0;
		my @hex = map { color_of( $_, '"color"', $sub ) } @{$color};
		return map { $hex[ $_ % scalar @hex ] } 0 .. $n - 1;
	} elsif ( defined $color ) {
		return (color_of( $color, '"color"', $sub )) x $n;
	}
	return ();
}
sub r_factor {
	# An R factor of the values given, its levels the distinct values in the
	# order first given, so that a discrete axis or legend keeps that order
	# rather than R's alphabetical one.
	my @values = @_;
	my %seen;
	my @levels = grep { not $seen{$_}++ } @values;
	return 'factor(' . r_strs(@values) . ', levels = ' . r_strs(@levels) . ')';
}
sub draw_bar_native {
	# A bar chart as ggplot2 draws one: geom_col on a discrete axis of the
	# keys, at its own width and fill unless "width" or "color" is given, a
	# grouped chart dodged and a stacked one stacked, in ggplot2's order, its
	# series in the hue scale. The checks are draw_bar's, already made.
	my ($a) = @_;
	my ( $plot, $s, $keys, $values, $where, $sub ) = @{$a}{qw(plot s keys values where sub)};
	my $horizontal = $a->{horizontal};
	my $pos_axis = $horizontal ? 'y' : 'x';
	$s->{discrete}{$pos_axis} = 1;
	my $aes = $horizontal ? 'x = v, y = k' : 'x = k, y = v';
	my $extra = ( defined $plot->{width} ? ', width = ' . r_num( $plot->{width} ) : '' ) . ( $horizontal ? ', orientation = "y"' : '' );
	my $n = scalar @{$keys};
	my $edges = defined $plot->{edgecolor};
	# On a log value axis geom_col stands its bars on 0 of the transformed
	# scale, which is 1, so a bar of 1 had no height at all, and one below 1
	# hung down from it. There the bars are rectangles from a tenth of the
	# least value -- the decade below it, where the gnuplot engine's native
	# bars start -- laid out as geom_col would lay them (log_bar_layer).
	my $log = $s->{axis}{ $horizontal ? 'x' : 'y' }{log};
	if ( $a->{form} eq 'simple' ) {
		my @colors = simple_bar_colors( $plot, $keys, $where, $sub );
		if ($log) {
			# "grey35" is geom_col's own fill, which a rectangle does not have
			log_bar_layer( $a, [ map { [ $_, 0, $values->{ $keys->[$_] }[0] ] } 0 .. $n - 1 ], 1, [ @colors ? @colors : ('grey35') ], [ map { $a->{edge_of}->($_) } 0 .. $n - 1 ] );
			draw_bar_errors( $plot, $s, $keys, $horizontal, $where, $sub );
			return;
		}
		$extra .= ', fill = ' . r_strs(@colors) if @colors;
		$extra .= ', colour = c(' . join( ', ', map { $a->{edge_of}->($_) } 0 .. $n - 1 ) . ')' if $edges;
		push @{ $s->{layers} }, 'ggplot2::geom_col(data = ' . r_frame( k => r_factor( @{$keys} ), v => r_nums( map { $values->{$_}[0] } @{$keys} ) ) . ", ggplot2::aes($aes)$extra, na.rm = TRUE)";
		draw_bar_errors( $plot, $s, $keys, $horizontal, $where, $sub );
		return;
	}
	# Series with no name -- a hash of arrays without "label" -- are still told
	# apart by color, by their place, with no legend to name them.
	my @names = map { $a->{series_names}[$_] // ( $_ + 1 ) } 0 .. $a->{n_series} - 1;
	$s->{guide_none}{fill} = 1 unless grep { defined } @{ $a->{series_names} };
	foreach my $i ( 0 .. $#names ) {
		my $color;
		if ( %{ $a->{series_color} } ) {
			$color = color_of( $a->{series_color}{ $names[$i] }, "\"color\" of \"$names[$i]\"", $sub );
		} elsif ( ( ref $plot->{color} eq 'ARRAY' ) && ( defined $plot->{color}[$i] ) ) {
			$color = color_of( $plot->{color}[$i], '"color"', $sub );
		} elsif ( ( defined $plot->{color} ) && ( not ref $plot->{color} ) ) {
			$color = color_of( $plot->{color}, '"color"', $sub );
		}
		add_legend( $s->{fill_d}, $names[$i], $color );
	}
	my ( @k, @series, @v, @edge );
	foreach my $i ( 0 .. $#names ) {
		foreach my $j ( 0 .. $n - 1 ) {
			push @k, $keys->[$j];
			push @series, $names[$i];
			push @v, $values->{ $keys->[$j] }[$i] // 0;    # every series has a bar at every key
			push @edge, $a->{edge_of}->($j);
		}
	}
	if ($log) {
		my @rows = map { my $i = $_; map { [ $_, $i, $values->{ $keys->[$_] }[$i] // 0 ] } 0 .. $n - 1 } 0 .. $#names;
		log_bar_layer( $a, \@rows, scalar @names, undef, \@edge, \@names );
		return;
	}
	$extra .= ', colour = c(' . join( ', ', @edge ) . ')' if $edges;
	push @{ $s->{layers} }, 'ggplot2::geom_col(data = ' . r_frame( k => 'factor(' . r_strs(@k) . ', levels = ' . r_strs( @{$keys} ) . ')', s => 'factor(' . r_strs(@series) . ', levels = ' . r_strs(@names) . ')', v => r_nums(@v) )
	 . ", ggplot2::aes($aes, fill = s), position = " . ( $a->{stacked} ? '"stack"' : '"dodge"' ) . "$extra, na.rm = TRUE)";
}
sub log_bar_layer {
	# Native bars on a log value axis, as rectangles laid out the way geom_col
	# lays out its bars -- 0.9 of a category wide, or "width", dodged side by
	# side or stacked -- but standing on a tenth of the least value rather than
	# on 1 (see draw_bar_native). The categories are still a discrete axis,
	# which a geom_blank of the keys sets out in their order.
	#
	# rows:   [ key index, series index, value ], one per bar
	# n:      the number of series, which share each category when dodged
	# fills:  one fill per bar, or undef to map the series to the fill scale
	# edges:  one R color per bar, NA for none
	# names:  the series' names, for the fill scale, when fills is undef
	my ( $a, $rows, $n, $fills, $edges, $names ) = @_;
	my ( $s, $keys, $horizontal ) = @{$a}{qw(s keys horizontal)};
	my $width = $a->{plot}{width} // 0.9;    # geom_col's own width
	my @drawn = grep { looks_like_number( $rows->[$_][2] ) && is_finite( $rows->[$_][2] ) && ( $rows->[$_][2] > 0 ) } 0 .. $#{$rows};    # what a log axis can show
	my $least = min( map { $rows->[$_][2] } @drawn );
	return unless defined $least;
	my $base = $least / 10;
	my ( %top, @rect );
	foreach my $r (@drawn) {
		my ( $j, $i, $v ) = @{ $rows->[$r] };
		my ( $lo, $hi ) = ( $j + 1 - $width / 2, $j + 1 + $width / 2 );    # ggplot2 places category j at j + 1
		( $lo, $hi ) = ( $lo + $i * $width / $n, $lo + ( $i + 1 ) * $width / $n ) unless $a->{stacked} || ( $n == 1 );
		# a bar reaches its value, and in a stack the running sum of the values,
		# as on a linear axis; only the first stands on $base
		my $bottom = $a->{stacked} ? ( $top{$j} // $base ) : $base;
		my $top    = $a->{stacked} ? ( $top{$j} // 0 ) + $v : $v;
		$top{$j} = $top if $a->{stacked};
		push @rect, [ $lo, $hi, $bottom, $top, $r ];
	}
	my @column = map_rects( \@rect, [ 0 .. $#rect ], $horizontal );    # a list, not a hash: the script is the same from run to run
	my $fill = '';
	if ( defined $fills ) {
		$fill = ', fill = ' . r_strs( map { $fills->[ $_->[4] % scalar @{$fills} ] } @rect );
	} else {
		push @column, s => 'factor(' . r_strs( map { $names->[ $rows->[ $_->[4] ][1] ] } @rect ) . ', levels = ' . r_strs( @{$names} ) . ')';
	}
	my $colour = ( defined $a->{plot}{edgecolor} ) ? ', colour = c(' . join( ', ', map { $edges->[ $_->[4] ] } @rect ) . ')' : '';
	push @{ $s->{layers} }, 'ggplot2::geom_blank(data = ' . r_frame( k => r_factor( @{$keys} ) ) . ', ggplot2::aes(' . ( $horizontal ? 'y' : 'x' ) . ' = k))';
	push @{ $s->{layers} }, 'ggplot2::geom_rect(data = ' . r_frame(@column)
	 . ', ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax' . ( defined $fills ? '' : ', fill = s' ) . ")$fill$colour)";
}
sub map_rects {
	# The columns of a rectangle data.frame for the rectangles at @$idx, with
	# the position and value axes swapped for a horizontal chart.
	my ( $rects, $idx, $horizontal ) = @_;
	my ( $p_lo, $p_hi, $v_lo, $v_hi ) = $horizontal ? ( 'ymin', 'ymax', 'xmin', 'xmax' ) : ( 'xmin', 'xmax', 'ymin', 'ymax' );
	return (
		$p_lo => r_nums( map { $rects->[$_][0] } @{$idx} ),
		$p_hi => r_nums( map { $rects->[$_][1] } @{$idx} ),
		$v_lo => r_nums( map { $rects->[$_][2] } @{$idx} ),
		$v_hi => r_nums( map { $rects->[$_][3] } @{$idx} ),
	);
}
sub rect_layer {
	# Rectangles each in its own fill and edge color, out of any legend.
	my ( $rects, $fills, $edges, $idx, $horizontal ) = @_;
	return 'ggplot2::geom_rect(data = ' . r_frame( map_rects( $rects, $idx, $horizontal ) )
	 . ', ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), fill = ' . r_strs( @{$fills} )
	 . ', colour = c(' . join( ', ', @{$edges} ) . '), na.rm = TRUE)';
}
sub draw_bar_errors {
	# "yerr" on a bar chart and "xerr" on a barh, in matplotlib's shapes: one
	# number for every bar, an array of one per bar, two such arrays (lower,
	# then upper), or a hash by key of one number or a [ lower, upper ] pair.
	# Drawn without caps, as matplotlib draws them by default.
	my ( $plot, $s, $keys, $horizontal, $where, $sub ) = @_;
	my $along = $horizontal ? 'xerr' : 'yerr';
	my $across = $horizontal ? 'yerr' : 'xerr';
	if ( defined $plot->{$across} ) {
		die "$sub: \"$across\"$where would be an error bar across the bars of a $plot->{plot_type}; the $engine engine draws \"$along\", along them";
	}
	return unless defined $plot->{$along};
	my $err = $plot->{$along};
	my $n   = scalar @{$keys};
	my ( @low, @high );
	if ( ref $err eq '' ) {
		check_numbers( [$err], "\"$along\"", $sub );
		@low = @high = ($err) x $n;
	} elsif ( ref $err eq 'ARRAY' ) {
		my @rows = ( grep { ref } @{$err} ) ? @{$err} : ($err);
		if ( ( scalar @rows > 2 ) || ( grep { ref $_ ne 'ARRAY' } @rows ) ) {
			die "$sub: \"$along\" is an array of one error per bar, or of two such arrays (lower, then upper)";
		}
		foreach my $row (@rows) {
			die "$sub: \"$along\" has " . scalar( @{$row} ) . " values in a row, but there are $n bars" if scalar @{$row} != $n;
			check_numbers( $row, "\"$along\"", $sub );
		}
		@low  = @{ $rows[0] };
		@high = @{ $rows[-1] };
	} elsif ( ref $err eq 'HASH' ) {
		my @missing = grep { not defined $err->{$_} } @{$keys};
		die "$sub: the keys " . join( ', ', map { "\"$_\"" } @missing ) . " have no \"$along\"" if scalar @missing > 0;
		foreach my $key ( @{$keys} ) {
			my $e = $err->{$key};
			my @pair = ( ref $e eq 'ARRAY' ) ? @{$e} : ( ref $e eq '' ) ? ( $e, $e ) : ();
			die "$sub: $along/$key should be one number, or exactly 2 items: low and high error bars" if scalar @pair != 2;
			check_numbers( \@pair, "\"$along\" of \"$key\"", $sub );
			push @low,  $pair[0];
			push @high, $pair[1];
		}
	} else {
		die "$sub: \"$along\" is a number, an array or a hash, not a " . ref($err) . ' reference';
	}
	my @v = map { $plot->{data}{$_} } @{$keys};
	if ( $s->{native} ) {
		# ggplot2's own error bar, capped, on the discrete axis of the keys
		my $aes = $horizontal ? 'y = p, xmin = lo, xmax = hi' : 'x = p, ymin = lo, ymax = hi';
		push @{ $s->{after} }, 'ggplot2::geom_errorbar(data = ' . r_frame( p => r_factor( @{$keys} ), lo => r_nums( map { $v[$_] - $low[$_] } 0 .. $n - 1 ), hi => r_nums( map { $v[$_] + $high[$_] } 0 .. $n - 1 ) )
		 . ", ggplot2::aes($aes), width = 0.25" . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
		return;
	}
	my %cols = (
		p  => r_nums( 0 .. $n - 1 ),
		lo => r_nums( map { $v[$_] - $low[$_] } 0 .. $n - 1 ),
		hi => r_nums( map { $v[$_] + $high[$_] } 0 .. $n - 1 ),
	);
	my $aes = $horizontal ? 'y = p, xmin = lo, xmax = hi' : 'x = p, ymin = lo, ymax = hi';
	push @{ $s->{after} }, 'ggplot2::geom_linerange(data = ' . r_frame( map { $_ => $cols{$_} } qw(p lo hi) ) . ", ggplot2::aes($aes), colour = \"#000000\", linewidth = $line_mm"
	 . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
}
sub sets_of {
	# The sets of a boxplot, violin or hist as ( \@keys, \%values ): a single
	# array is one set, named '' for the boxes and violins, 'A' for a hist, as
	# matplotlib's engine names them.
	my ( $plot, $single_name, $sub ) = @_;
	my $data = ( ref $plot->{data} eq 'ARRAY' ) ? { $single_name => $plot->{data} } : $plot->{data};
	return ( [ key_order_of( $plot, $data, 'key_order', $sub ) ], $data );
}
sub distribution_colors {
	# The fill of each box or violin: "colors", a hash by key, else "color"
	# for all, else $default.
	my ( $plot, $keys, $default, $sub ) = @_;
	if ( ref $plot->{color} ) {
		die "$sub: \"color\" is one color for every $plot->{plot_type}, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	if ( defined $plot->{colors} ) {
		die "$sub: \"colors\" is a hash of one color per key" unless ref $plot->{colors} eq 'HASH';
		# The keys sets_of named, not those of "data", which as one array has
		# none: that died as "Not a HASH reference".
		my @uncolored = grep { not defined $plot->{colors}{$_} } @{$keys};
		die "$sub: the data keys " . join( ', ', map { "\"$_\"" } sort @uncolored ) . ' have no defined color' if scalar @uncolored > 0;
		return map { color_of( $plot->{colors}{$_}, "\"colors\" of \"$_\"", $sub ) } @{$keys};
	}
	return (color_of( $plot->{color}, '"color"', $sub )) x scalar @{$keys} if defined $plot->{color};
	return ($default) x scalar @{$keys};
}
sub orientation_of {
	my ( $plot, $sub ) = @_;
	my $o = $plot->{orientation} // 'vertical';
	die "$sub needs either \"horizontal\" or \"vertical\", not \"$o\"" if ( ref $o ) || ( $o !~ m/^(?:horizontal|vertical)$/ );
	return $o;
}
sub draw_boxplot {
	my ( $plot, $s, $where, $sub ) = @_;
	my $horizontal = ( orientation_of( $plot, $sub ) eq 'horizontal' ) ? 1 : 0;
	my ( $pos_axis, $val_axis ) = $horizontal ? ( 'y', 'x' ) : ( 'x', 'y' );
	my ( $keys, $data ) = sets_of( $plot, '', $sub );
	my %switch = map { $_ => bool_option( $plot->{$_} // ( $_ eq 'notch' ? 0 : 1 ), $_, $sub ) } qw(notch showcaps showfliers showmeans);
	$s->{axis}{$val_axis}{log} = 1 foreach value_axis_log( $plot, $pos_axis, $sub );
	my @fills = distribution_colors( $plot, $keys, ( $s->{native} ? undef : $cycle[0] ), $sub );    # patch_artist boxes take "patch.facecolor", C0, without advancing the cycle; ggplot2's are white
	my $n = scalar @{$keys};
	my ( @native_k, @native_v, @native_fill );    # under "native": the rows of one geom_boxplot, and the fill of each box drawn
	# bxp's default widths: 0.15 of the span of the positions, kept between
	# 0.15 and 0.5.
	my $width = max( 0.15, min( 0.5, 0.15 * ( $n - 1 ) ) );
	my @labels;
	foreach my $i ( 0 .. $n - 1 ) {
		my $key = $keys->[$i];
		my @v = grep { ( defined ) && ( not is_nan($_) ) } @{ $data->{$key} };    # NaN is a missing value, as undef is
		my @bad = grep { not looks_like_number($_) } @v;
		die "$sub: $key has non-numeric values: \"" . join( '", "', @bad ) . '"' if scalar @bad > 0;
		push @labels, "$key (" . with_commas( scalar @v ) . ')';
		next if scalar @v == 0;
		if ( $s->{native} ) {
			push @native_k, ($key) x scalar @v;
			push @native_v, @v;
			push @native_fill, $fills[$i];
			next;
		}
		my $p = $i + 1;
		my $aes = $horizontal ? 'x = v, y = p, group = p' : 'x = p, y = v, group = p';
		push @{ $s->{layers} }, 'ggplot2::geom_boxplot(data = ' . r_frame( p => r_num($p), v => r_nums(@v) ) . ", ggplot2::aes($aes), fill = " . r_str( $fills[$i] )
		 . ", colour = \"#000000\", width = $width, notch = " . ( $switch{notch} ? 'TRUE' : 'FALSE' )
		 . ', staplewidth = ' . ( $switch{showcaps} ? 0.5 : 0 )
		 . ', outlier.shape = ' . ( $switch{showfliers} ? 1 : 'NA' ) . ', outlier.size = 2'
		 . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
		my @sorted = sort { $a <=> $b } @v;
		my $median = percentile( \@sorted, 0.5 );
		# matplotlib's median line is C1, orange, where ggplot2 draws it in the
		# box's own outline color
		push @{ $s->{layers} }, segment_layer( [ [ $p - $width / 2, $p + $width / 2, $median, $median ] ], $horizontal, r_str( $cycle[1] ), $line_mm * 2 / 3 );
		if ( $switch{showmeans} ) {
			my $mean = sum(@v) / scalar @v;
			my @xy = $horizontal ? ( x => r_num($mean), y => r_num($p) ) : ( x => r_num($p), y => r_num($mean) );
			push @{ $s->{layers} }, 'ggplot2::geom_point(data = ' . r_frame(@xy) . ', ggplot2::aes(x = x, y = y), shape = 17, colour = ' . r_str( $cycle[2] ) . ", size = $marker_mm)";
		}
	}
	if ( $s->{native} ) {
		# stat_boxplot's own quartiles, whiskers and outliers, on a discrete axis
		# of the keys, each labelled by its key alone. The switches change
		# ggplot2's defaults only where they are given: it draws no caps and no
		# mean, and draws the outliers.
		$s->{discrete}{$pos_axis} = 1;
		return unless @native_v;
		my $aes = $horizontal ? 'x = v, y = k' : 'x = k, y = v';
		my $frame = r_frame( k => 'factor(' . r_strs(@native_k) . ', levels = ' . r_strs( @{$keys} ) . ')', v => r_nums(@native_v) );
		my $extra = ( defined $native_fill[0] ? ', fill = ' . r_strs(@native_fill) : '' ) . ( $horizontal ? ', orientation = "y"' : '' );
		$extra .= ', notch = ' . ( $switch{notch} ? 'TRUE' : 'FALSE' ) if defined $plot->{notch};
		$extra .= ', staplewidth = ' . ( $switch{showcaps} ? 0.5 : 0 ) if defined $plot->{showcaps};
		$extra .= ', outlier.shape = NA' if ( defined $plot->{showfliers} ) && ( not $switch{showfliers} );
		push @{ $s->{layers} }, "ggplot2::geom_boxplot(data = $frame, ggplot2::aes($aes)$extra, na.rm = TRUE)";
		if ( ( defined $plot->{showmeans} ) && $switch{showmeans} ) {
			push @{ $s->{layers} }, "ggplot2::stat_summary(data = $frame, ggplot2::aes($aes), fun = mean, geom = \"point\"" . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
		}
		return;
	}
	category_ticks( $s, $pos_axis, [ 1 .. $n ], \@labels );
}
sub draw_violin {
	my ( $plot, $s, $where, $sub ) = @_;
	my $horizontal = ( orientation_of( $plot, $sub ) eq 'horizontal' ) ? 1 : 0;
	my ( $pos_axis, $val_axis ) = $horizontal ? ( 'y', 'x' ) : ( 'x', 'y' );
	my ( $keys, $data ) = sets_of( $plot, '', $sub );
	my $medians  = bool_option( $plot->{medians}  // 1, 'medians',  $sub );
	my $whiskers = bool_option( $plot->{whiskers} // 1, 'whiskers', $sub );
	$s->{axis}{$val_axis}{log} = 1 foreach value_axis_log( $plot, $pos_axis, $sub );
	my $line_color = next_color( $s, 'line' );    # the bodies and the lines of a violinplot take one color of the cycle
	my @fills = distribution_colors( $plot, $keys, $line_color, $sub );
	# The bodies of a violinplot have an alpha of 0.3, which matplotlib applies
	# to the edge as well as the fill; ggplot2's "alpha" reaches only the fill.
	my $edge_hex = color_of( $plot->{edgecolor} // 'black', '"edgecolor"', $sub );
	my $edge = r_str( length $edge_hex == 7 ? $edge_hex . '4d' : $edge_hex );
	my $width = 0.5;    # violinplot's default widths
	my @labels;
	my ( @native_k, @native_v, @native_fill );    # under "native": the rows of one geom_violin, and the fill of each violin
	foreach my $i ( 0 .. $#{$keys} ) {
		my $key = $keys->[$i];
		my @v = grep { ( defined ) && looks_like_number($_) && ( not is_nan($_) ) } @{ $data->{$key} };
		if ( scalar @v == 0 ) {
			die "$sub: \"$key\" has no numeric values to plot (" . scalar( @{ $data->{$key} } ) . ' value(s) given, all undefined, NaN or non-numeric)';
		}
		my @infinite = grep { not is_finite($_) } @v;
		die "$sub: \"$key\" has infinite values, which $plot->{plot_type} cannot draw a density for" if scalar @infinite > 0;
		my $n = scalar @v;
		if ( $s->{native} ) {
			# stat_ydensity's own bandwidth, bw.nrd0, which gives a sample with no
			# spread a width of its own, so nothing is refused for it here
			push @native_k, ($key) x $n;
			push @native_v, @v;
			push @native_fill, $fills[$i];
			next;
		}
		my $mean = sum(@v) / $n;
		my $sd = ( $n > 1 ) ? sqrt( sum( map { ( $_ - $mean )**2 } @v ) / ( $n - 1 ) ) : 0;
		# scipy's gaussian_kde, which matplotlib's violinplot uses, has a
		# bandwidth of Scott's factor, n ** (-1/5), times the sample's standard
		# deviation; geom_violin's "bw" is that same kernel standard deviation.
		# A sample with no spread has no density, and gaussian_kde refuses it.
		die "$sub: \"$key\" has no spread -- every value is $v[0] -- so there is no density to draw a violin from" if $sd == 0;
		my $bw = $sd * $n**( -1 / 5 );
		my $p = $i + 1;
		push @labels, "$key (" . with_commas($n) . ')';
		my $aes = $horizontal ? 'x = v, y = p, group = p' : 'x = p, y = v, group = p';
		push @{ $s->{layers} }, 'ggplot2::geom_violin(data = ' . r_frame( p => r_num($p), v => r_nums(@v) ) . ", ggplot2::aes($aes), fill = " . r_str( $fills[$i] )
		 . ", colour = $edge, alpha = 0.3, width = $width, scale = \"width\", trim = TRUE, bw = " . r_num($bw)
		 . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
		my @sorted = sort { $a <=> $b } @v;
		my $half = $width / 4;    # the caps of the extrema and the median line span a quarter of the width each side
		my @segs = ( [ $p, $p, $sorted[0], $sorted[-1] ], [ $p - $half, $p + $half, $sorted[0], $sorted[0] ], [ $p - $half, $p + $half, $sorted[-1], $sorted[-1] ] );
		push @segs, [ $p - $half, $p + $half, ( percentile( \@sorted, 0.5 ) ) x 2 ] if $medians;
		push @{ $s->{layers} }, segment_layer( \@segs, $horizontal, r_str($line_color), $line_mm * 2 / 3 );
		if ($whiskers) {
			my ( $q1, $q3 ) = ( percentile( \@sorted, 0.25 ), percentile( \@sorted, 0.75 ) );
			# matplotlib's "customized violin" example: the whiskers reach 1.5
			# interquartile ranges past the quartiles, but no further than the
			# data.
			my $upper = min( max( $q3 + ( $q3 - $q1 ) * 1.5, $q3 ), $sorted[-1] );
			my $lower = max( min( $q1 - ( $q3 - $q1 ) * 1.5, $q1 ), $sorted[0] );
			# 5 pt and 1 pt at 2.845 pt per mm, as 5000 / 2845 rather than
			# 5 / 2.845: perl 5.10.1 reads the literal 2.845 a double low, and
			# wrote the width with a different last digit.
			push @{ $s->{layers} }, segment_layer( [ [ $p, $p, $q1, $q3 ] ], $horizontal, '"#000000"', 5000 / 2845 );
			push @{ $s->{layers} }, segment_layer( [ [ $p, $p, $lower, $upper ] ], $horizontal, '"#000000"', 1000 / 2845 );
		}
		my @xy = $horizontal ? ( x => r_num($mean), y => r_num($p) ) : ( x => r_num($p), y => r_num($mean) );
		push @{ $s->{layers} }, 'ggplot2::geom_point(data = ' . r_frame(@xy) . ", ggplot2::aes(x = x, y = y), shape = 16, colour = \"#ff0000\", size = $marker_mm)";    # "ro", the red mean
	}
	if ( $s->{native} ) {
		# geom_violin with its defaults -- bw.nrd0, trimmed to the data, scaled
		# so that every violin has the same area -- on a discrete axis of the
		# keys. It draws no median and no whiskers of its own, so those are drawn
		# only when asked for: the median as a short line across each violin,
		# the whiskers as a narrow geom_boxplot inside it, which is how they are
		# drawn with ggplot2.
		$s->{discrete}{$pos_axis} = 1;
		my $aes = $horizontal ? 'x = v, y = k' : 'x = k, y = v';
		my $orient = $horizontal ? ', orientation = "y"' : '';
		my @columns = ( k => 'factor(' . r_strs(@native_k) . ', levels = ' . r_strs( @{$keys} ) . ')', v => r_nums(@native_v) );
		# A given fill is a column of the frame, one color per row, mapped
		# through I() so that no scale reads it (ggplot2 3.5.0's NEWS: "Plot
		# scales now ignore AsIs objects"). As a parameter, "fill = c(...)" with
		# one color per violin, it died in R as "Aesthetics must be either length
		# 1 or the same as the data (1030)", since stat_ydensity draws each
		# violin from hundreds of rows; geom_boxplot's one row per box took it.
		my $fill_aes = '';
		if ( defined $native_fill[0] ) {
			my %fill_of = map { $keys->[$_] => $fills[$_] } 0 .. $#{$keys};
			push @columns, f => r_strs( map { $fill_of{$_} } @native_k );
			$fill_aes = ', fill = I(f)';
		}
		my $frame = r_frame(@columns);
		my $extra = defined $plot->{edgecolor} ? ', colour = ' . r_str( color_of( $plot->{edgecolor}, '"edgecolor"', $sub ) ) : '';
		push @{ $s->{layers} }, "ggplot2::geom_violin(data = $frame, ggplot2::aes($aes$fill_aes)$extra$orient, na.rm = TRUE)";
		if ( ( defined $plot->{whiskers} ) && $whiskers ) {
			push @{ $s->{layers} }, "ggplot2::geom_boxplot(data = $frame, ggplot2::aes($aes), width = 0.1, outlier.shape = NA$orient, na.rm = TRUE)";
		}
		if ( ( defined $plot->{medians} ) && $medians ) {
			push @{ $s->{layers} }, "ggplot2::stat_summary(data = $frame, ggplot2::aes($aes), fun = stats::median, fun.min = stats::median, fun.max = stats::median, geom = \"crossbar\", width = 0.25$orient, na.rm = TRUE)";
		}
		return;
	}
	category_ticks( $s, $pos_axis, [ 1 .. scalar @{$keys} ], \@labels );
}
sub segment_layer {
	# Line segments given as [ p0, p1, v0, v1 ] along the position and value
	# axes, swapped for a horizontal plot.
	# The width is written in 15 digits, as a double perl stringifies it; a
	# quadmath perl wrote all 36 of its own.
	my ( $segs, $horizontal, $colour, $width ) = @_;
	my ( $px, $vx ) = $horizontal ? ( 'y', 'x' ) : ( 'x', 'y' );
	return 'ggplot2::geom_segment(data = ' . r_frame(
		$px => r_nums( map { $_->[0] } @{$segs} ), "${px}end" => r_nums( map { $_->[1] } @{$segs} ),
		$vx => r_nums( map { $_->[2] } @{$segs} ), "${vx}end" => r_nums( map { $_->[3] } @{$segs} ),
	) . ", ggplot2::aes(x = x, xend = xend, y = y, yend = yend), colour = $colour, linewidth = " . sprintf( '%.15g', $width ) . ')';
}
sub draw_hist {
	my ( $plot, $s, $where, $sub ) = @_;
	my $alpha = $plot->{alpha} // 0.5;
	check_numbers( [$alpha], '"alpha"', $sub );
	die "$sub: \"alpha\" is an opacity from 0 to 1, not $alpha" unless is_finite($alpha) && ( $alpha >= 0 ) && ( $alpha <= 1 );
	if ( ref $plot->{orientation} ) {
		die "$sub: \"orientation\" is one of \"vertical\" or \"horizontal\" for every set, not a " . ref( $plot->{orientation} ) . ' reference';
	}
	my $horizontal = ( orientation_of( $plot, $sub ) eq 'horizontal' ) ? 1 : 0;
	$s->{axis}{$_}{log} = 1 foreach logscale_axes( $plot->{logscale}, $sub );
	my ( $keys, $data ) = sets_of( $plot, 'A', $sub );
	foreach my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) ) {
		my @stray = sort grep { not exists $data->{$_} } keys %{ $plot->{$arg} };
		die "$sub: the keys " . join( ', ', map { "\"$_\"" } @stray ) . " of \"$arg\" are not sets of \"data\"" if scalar @stray > 0;
	}
	if ( ( ref $plot->{color} ) && ( ref $plot->{color} ne 'HASH' ) ) {
		die "$sub: \"color\" is one color for every set, or a hash of one color per set, not a " . ref( $plot->{color} ) . ' reference';
	}
	my $show_legend = bool_option( $plot->{show_legend} // ( ( scalar keys %{$data} > 1 ) ? 1 : 0 ), 'show_legend', $sub );
	my ( @rects, @names, @colors );
	my @native;    # under "native": [ set, \@values, bins, color or undef ] of each set
	foreach my $set ( @{$keys} ) {
		my @bad = grep { not looks_like_number($_) } @{ $data->{$set} };
		die "$sub: $set has non-numeric values, which for hist must be numeric: \"" . join( '", "', map { $_ // 'undef' } @bad ) . '"' if scalar @bad > 0;
		my @infinite = grep { not( is_nan($_) || is_finite($_) ) } @{ $data->{$set} };
		die "$sub: $set has infinite values, which hist cannot bin" if scalar @infinite > 0;
		my @v = grep { not is_nan($_) } @{ $data->{$set} };    # numpy bins around a NaN
		my $bins = ( ref $plot->{bins} eq 'HASH' ) ? ( $plot->{bins}{$set} // 10 ) : ( $plot->{bins} // 10 );    # rcParams hist.bins
		my @edges;
		if ( ref $bins eq 'ARRAY' ) {
			check_numbers( $bins, "\"bins\" of \"$set\"", $sub );
			# Two equal edges are a bin of no width, which holds nothing, as numpy
			# allows them; edges that fall are refused, as numpy refuses them.
			# R's cut() refuses equal breaks, so the native style does too.
			die "$sub: \"bins\" of \"$set\" are bin edges, so at least 2, never falling" if ( scalar @{$bins} < 2 ) || grep { $bins->[$_] < $bins->[ $_ - 1 ] } 1 .. $#{$bins};
			if ( $s->{native} && grep { $bins->[$_] == $bins->[ $_ - 1 ] } 1 .. $#{$bins} ) {
				die "$sub: \"bins\" of \"$set\" has two equal edges, a bin of no width, which ggplot2's stat_bin refuses under style => 'native'; style => 'matplotlib' draws it";
			}
			@edges = map { as_double($_) } @{$bins};    # see bin_index
		} elsif ( ( not ref $bins ) && looks_like_number($bins) && is_finite($bins) && ( $bins == int $bins ) && ( $bins >= 1 ) ) {
			my ( $lo, $hi ) = scalar @v ? ( min(@v), max(@v) ) : ( 0, 1 );
			( $lo, $hi ) = ( $lo - 0.5, $hi + 0.5 ) if $lo == $hi;    # numpy's range for data of one value
			@edges = linspace( $lo, $hi, $bins + 1 );
		} else {
			die "$sub: \"bins\" is a whole number of bins, or an array of bin edges, for the $engine engine, not \"" . ( ref $bins || $bins ) . '"; a numpy estimator such as "auto" is matplotlib\'s alone';
		}
		if ( $s->{native} ) {
			my $c = ( ref $plot->{color} eq 'HASH' ) ? $plot->{color}{$set} : $plot->{color};
			push @native, [ $set, \@v, $bins, defined $c ? color_of( $c, "\"color\" of \"$set\"", $sub ) : undef ];
			next;
		}
		my @counts = (0) x ( scalar @edges - 1 );
		foreach my $x (@v) {
			my $i = bin_index( \@edges, $x );
			$counts[$i]++ if defined $i;
		}
		my $c = ( ref $plot->{color} eq 'HASH' ) ? $plot->{color}{$set} : $plot->{color};
		my $color = defined $c ? color_of( $c, "\"color\" of \"$set\"", $sub ) : next_color( $s, 'patch' );
		foreach my $i ( 0 .. $#counts ) {
			push @rects, [ $edges[$i], $edges[ $i + 1 ], 0, $counts[$i] ];
			push @names, $set;
			push @colors, $color;
		}
		add_legend( $s->{fill_d}, $set, $color ) if $show_legend;
	}
	if ( $s->{native} ) {
		draw_hist_native( $plot, $s, \@native, $show_legend, $horizontal );
		return;
	}
	my ( $b_lo, $b_hi, $c_lo, $c_hi ) = $horizontal ? ( 'ymin', 'ymax', 'xmin', 'xmax' ) : ( 'xmin', 'xmax', 'ymin', 'ymax' );
	my $frame = r_frame(
		$b_lo => r_nums( map { $_->[0] } @rects ), $b_hi => r_nums( map { $_->[1] } @rects ),
		$c_lo => r_nums( map { $_->[2] } @rects ), $c_hi => r_nums( map { $_->[3] } @rects ),
		s => r_strs(@names),
	);
	my $aes = 'xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax';
	if ($show_legend) {
		push @{ $s->{layers} }, "ggplot2::geom_rect(data = $frame, ggplot2::aes($aes, fill = s), alpha = " . r_num($alpha) . ', colour = NA, na.rm = TRUE)';
	} else {
		push @{ $s->{layers} }, "ggplot2::geom_rect(data = $frame, ggplot2::aes($aes), fill = " . r_strs(@colors) . ', alpha = ' . r_num($alpha) . ', colour = NA, na.rm = TRUE)';
	}
}
sub draw_hist_native {
	# The sets of a hist as geom_histogram bins them, with stat_bin: over the
	# range of the data its layer holds, which is every set at once unless
	# "bins" is a hash of one per set, when each set is a layer of its own. A
	# "bins" that is a count is passed as "bins", and one that is edges as
	# "breaks". With no "bins", 10 is passed, matplotlib's default: stat_bin's
	# own is 30, which it warns about every time ("Pick better value"), asking
	# for exactly this choice to be made.
	#
	# Sets are overlaid, not stacked as geom_histogram stacks them by default:
	# a hist of several sets compares their distributions, which stacking
	# would change into a distribution of them all. So that the overlap shows,
	# each takes "alpha", 0.5 where several sets are drawn and none is given.
	my ( $plot, $s, $sets, $show_legend, $horizontal ) = @_;
	my $several = ( scalar @{$sets} > 1 ) ? 1 : 0;
	my $alpha = $plot->{alpha} // ( $several ? 0.5 : undef );
	my $aes = $horizontal ? 'y = v' : 'x = v';
	my $mapped = ( $show_legend || $several ) ? 1 : 0;    # one set alone, unlabelled, is ggplot2's own grey
	if ($mapped) {
		add_legend( $s->{fill_d}, $_->[0], $_->[3] ) foreach @{$sets};
		$s->{guide_none}{fill} = 1 unless $show_legend;
	}
	my $bins_of = sub {
		my ($bins) = @_;
		return ( ref $bins eq 'ARRAY' ) ? 'breaks = ' . r_nums( @{$bins} ) : 'bins = ' . r_num($bins);
	};
	my @layers = ( ref $plot->{bins} eq 'HASH' ) ? map { [$_] } @{$sets} : ( $sets );
	foreach my $layer (@layers) {
		my @v = map { @{ $_->[1] } } @{$layer};
		next if scalar @v == 0;    # nothing to bin, as matplotlib bins nothing; c() would be NULL, and no column at all in R
		my @s = map { ( $_->[0] ) x scalar @{ $_->[1] } } @{$layer};
		my $frame = r_frame( v => r_nums(@v), s => 'factor(' . r_strs(@s) . ', levels = ' . r_strs( map { $_->[0] } @{$sets} ) . ')' );
		my $extra = $mapped ? '' : ( defined $layer->[0][3] ? ', fill = ' . r_str( $layer->[0][3] ) : '' );
		$extra .= ', alpha = ' . r_num($alpha) if defined $alpha;
		push @{ $s->{layers} }, "ggplot2::geom_histogram(data = $frame, ggplot2::aes($aes" . ( $mapped ? ', fill = s' : '' ) . '), ' . $bins_of->( $layer->[0][2] )
		 . ', position = "identity"' . $extra . ( $horizontal ? ', orientation = "y"' : '' ) . ', na.rm = TRUE)';
	}
}
sub gradient_of {
	# A continuous color scale, checked: the colormap, the ends, and a log
	# scale, which needs a bottom end above 0.
	#
	# Under "native" (args: native => 1) a colormap not asked for is ggplot2's
	# default gradient (colors => undef), the ends not given are left to
	# ggplot2 to take from what it draws, and a title not given is ggplot2's
	# own -- the name of what is colored -- where "default_title" is undef
	# (waiver => 1).
	my ($args) = @_;
	my ( $plot, $values, $sub ) = @{$args}{qw(plot values sub)};
	my $native = $args->{native} ? 1 : 0;
	my $colors = ( $native && ( not defined $plot->{cmap} ) ) ? undef : [ colormap_colors( $plot->{cmap} // $args->{default_cmap}, $engine, $sub ) ];
	my $log = bool_option( $plot->{cb_logscale}, 'cb_logscale', $sub );
	foreach my $end ( grep { defined $plot->{$_} } ( 'vmin', 'vmax' ) ) {
		check_numbers( [ $plot->{$end} ], "\"$end\"", $sub );
		die "$sub: \"$end\" must be a finite number, not \"$plot->{$end}\"" unless is_finite( $plot->{$end} );
	}
	if ($native) {
		die "$sub: \"cb_logscale\" cannot start at $plot->{vmin}: a log scale needs a minimum above 0" if $log && ( defined $plot->{vmin} ) && ( $plot->{vmin} <= 0 );
		my $show = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $sub );
		$show = 0 if defined $plot->{show_colorbar} && ( not bool_option( $plot->{show_colorbar}, 'show_colorbar', $sub ) );
		my $title = defined $plot->{cblabel} ? plain_text( $plot->{cblabel}, 'cblabel', $engine, $sub ) : $args->{default_title};
		return { colors => $colors, lo => $plot->{vmin}, hi => $plot->{vmax}, log => $log, show => $show, title => $title, waiver => ( defined $title ? 0 : 1 ),
			type => $plot->{plot_type}, aes => $args->{aes}, na => $args->{na} // 'NA' };
	}
	my @colors = @{$colors};
	my @finite = finite_values( @{$values} );
	my ( $lo, $hi ) = ( $plot->{vmin}, $plot->{vmax} );
	if ($log) {
		$lo = $lo // min( grep { $_ > 0 } @finite );
		die "$sub: \"cb_logscale\" needs a color value above 0 to start the scale at, or a \"vmin\" or \"cb_min\" above 0, and there is neither" unless defined $lo;
		die "$sub: \"cb_logscale\" cannot start at $lo: a log scale needs a minimum above 0" if $lo <= 0;
	} else {
		$lo = $lo // min(@finite);
	}
	$hi = $hi // max(@finite);
	my $show = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $sub );
	$show = 0 if defined $plot->{show_colorbar} && ( not bool_option( $plot->{show_colorbar}, 'show_colorbar', $sub ) );
	my $title = defined $plot->{cblabel} ? plain_text( $plot->{cblabel}, 'cblabel', $engine, $sub ) : $args->{default_title};
	return { colors => \@colors, lo => $lo, hi => $hi, log => $log, show => $show, title => $title, type => $plot->{plot_type}, aes => $args->{aes}, na => $args->{na} // 'NA' };
}
sub draw_hist2d {
	my ( $plot, $s, $where, $sub ) = @_;
	cb_limits( $plot, $sub );
	bin_counts( $plot, $sub );
	my @keys = key_order_of( $plot, $plot->{data}, 'key_order', $sub );
	die "$sub: There must be exactly 2 keys for hist2d, not " . scalar(@keys) if scalar @keys != 2;
	my @xy = map { $plot->{data}{$_} } @keys;
	die "$sub: The length of both keys must be equal: \"$keys[0]\" has " . scalar( @{ $xy[0] } ) . ", \"$keys[1]\" has " . scalar( @{ $xy[1] } ) if scalar @{ $xy[0] } != scalar @{ $xy[1] };
	foreach my $i ( 0, 1 ) {
		my @bad = grep { ( not defined $xy[$i][$_] ) || ( not looks_like_number( $xy[$i][$_] ) ) } 0 .. $#{ $xy[$i] };
		die "$sub: \"$keys[$i]\" is undefined or not a number at indices " . join( ', ', @bad ) if scalar @bad > 0;
	}
	@{ $s->{default_label} }{ 'x', 'y' } = @keys;
	my %log_axis = map { $_ => 1 } logscale_axes( $plot->{logscale}, $sub );
	if ( $s->{native} ) {
		draw_hist2d_native( $plot, $s, \@keys, \@xy, \%log_axis, $where, $sub );
		return;
	}
	my @edges;
	foreach my $i ( 0, 1 ) {
		my $axis = ( 'x', 'y' )[$i];
		my @finite = finite_values( @{ $xy[$i] } );
		foreach my $end ( 'min', 'max' ) {
			my $opt = "$axis$end";
			if ( defined $plot->{$opt} ) {
				check_numbers( [ $plot->{$opt} ], "\"$opt\"", $sub );
				die "$sub: \"$opt\" must be a finite number, not \"$plot->{$opt}\"" unless is_finite( $plot->{$opt} );
			} elsif ( scalar @finite == 0 ) {
				die "$sub: \"$keys[$i]\" has no finite value, so hist2d has no range to bin it over; give \"${axis}min\" and \"${axis}max\"";
			}
		}
		my $lo = $plot->{"${axis}min"} // min(@finite);
		my $hi = $plot->{"${axis}max"} // max(@finite);
		die "$sub: \"${axis}min\" = $lo is above \"${axis}max\" = $hi" if $lo > $hi;
		# Refused on a log axis, where widening by 0.5 each way could reach 0 or
		# below, and died taking its log; matplotlib's np.logspace of one value
		# has edges that do not rise, and fails too.
		die "$sub: \"logscale\" puts $axis on a log scale, but every $axis is $lo, a range of nothing; give \"${axis}min\" and \"${axis}max\"" if $log_axis{$axis} && ( $lo == $hi );
		( $lo, $hi ) = ( $lo - 0.5, $hi + 0.5 ) if $lo == $hi;    # numpy's range for data of one value
		my $n = $plot->{"${axis}bins"};
		if ( $log_axis{$axis} ) {
			die "$sub: \"logscale\" puts $axis on a log scale, which cannot start at $lo: give a \"${axis}min\" above 0" if $lo <= 0;
			$edges[$i] = [ logspace( $lo, $hi, $n + 1 ) ];    # as the matplotlib engine writes them
			$s->{axis}{$axis}{log} = 1;
		} else {
			$edges[$i] = [ linspace( $lo, $hi, $n + 1 ) ];
		}
		$s->{axis}{$axis}{expand0} = 1;
	}
	my @count;
	my $n_in = 0;
	foreach my $j ( 0 .. $#{ $xy[0] } ) {
		my ( $x, $y ) = ( $xy[0][$j], $xy[1][$j] );
		next unless is_finite($x) && is_finite($y);
		my ( $bx, $by ) = ( bin_index( $edges[0], $x ), bin_index( $edges[1], $y ) );
		next unless ( defined $bx ) && ( defined $by );
		$count[$bx][$by]++;
		$n_in++;
	}
	my $density = bool_option( $plot->{density}, 'density', $sub );
	foreach my $opt ( grep { defined $plot->{$_} } ( 'cmin', 'cmax' ) ) {
		check_numbers( [ $plot->{$opt} ], "\"$opt\"", $sub );
	}
	my ( @r, @v );
	foreach my $bx ( 0 .. $#{ $edges[0] } - 1 ) {
		foreach my $by ( 0 .. $#{ $edges[1] } - 1 ) {
			my $c = $count[$bx][$by] // 0;
			if ($density) {
				my $area = ( $edges[0][ $bx + 1 ] - $edges[0][$bx] ) * ( $edges[1][ $by + 1 ] - $edges[1][$by] );
				$c = ( $n_in > 0 ) ? $c / ( $n_in * $area ) : 0;
			}
			# hist2d leaves a bin out of the colors below "cmin" or above
			# "cmax", and LogNorm leaves out a bin of 0
			$c = undef if ( defined $plot->{cmin} && $c < $plot->{cmin} ) || ( defined $plot->{cmax} && $c > $plot->{cmax} );
			push @r, [ $edges[0][$bx], $edges[0][ $bx + 1 ], $edges[1][$by], $edges[1][ $by + 1 ] ];
			push @v, $c;
		}
	}
	my $gradient = gradient_of({ plot => $plot, values => [ grep { defined } @v ], default_cmap => 'gist_rainbow', default_title => 'Density', aes => 'fill', sub => $sub, native => $s->{native} });
	if ( $gradient->{log} ) {
		@v = map { ( defined $_ && $_ > 0 ) ? $_ : undef } @v;
	}
	set_gradient( $s, $gradient, $where, $sub );
	my $frame = r_frame(
		xmin => r_nums( map { $_->[0] } @r ), xmax => r_nums( map { $_->[1] } @r ),
		ymin => r_nums( map { $_->[2] } @r ), ymax => r_nums( map { $_->[3] } @r ),
		v    => r_nums(@v),
	);
	push @{ $s->{layers} }, "ggplot2::geom_rect(data = subset($frame, !is.na(v)), ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = v), colour = NA)";
}
sub draw_hist2d_native {
	# A hist2d as geom_bin_2d bins it, with stat_bin_2d, "xbins" by "ybins"
	# over the range of the data, or over "xmin" .. "xmax" and "ymin" ..
	# "ymax" where any is given, as breaks. On a log axis it bins in log units,
	# as the scale transforms the data, and the breaks, before the stat sees
	# them. "density" is
	# stat_bin_2d's own density, the share of the points in each bin, which is
	# not matplotlib's (that share divided by the bin's area). "cmin" and
	# "cmax" leave out of the colors a bin below or above them, as matplotlib
	# does, by what is colored.
	my ( $plot, $s, $keys, $xy, $log_axis, $where, $sub ) = @_;
	my @ok = grep { is_finite( $xy->[0][$_] ) && is_finite( $xy->[1][$_] ) } 0 .. $#{ $xy->[0] };
	if ( scalar @ok == 0 ) {
		# Refused as the matplotlib style refuses it, where an axis has no
		# range to bin over; with every range given, an empty panel. A frame of
		# no points has NULL columns, and ggplot2 died with "object 'x' not
		# found".
		foreach my $i ( 0, 1 ) {
			my $axis = ( 'x', 'y' )[$i];
			next if scalar finite_values( @{ $xy->[$i] } );
			next if ( defined $plot->{"${axis}min"} ) && ( defined $plot->{"${axis}max"} );
			die "$sub: \"$keys->[$i]\" has no finite value, so hist2d has no range to bin it over; give \"${axis}min\" and \"${axis}max\"";
		}
	}
	my %breaks;    # axis => its breaks, for an axis with "min" or "max" given
	foreach my $i ( 0, 1 ) {
		my $axis = ( 'x', 'y' )[$i];
		$s->{axis}{$axis}{log} = 1 if $log_axis->{$axis};
		foreach my $end ( grep { defined $plot->{"$axis$_"} } ( 'min', 'max' ) ) {
			check_numbers( [ $plot->{"$axis$end"} ], "\"$axis$end\"", $sub );
			die "$sub: \"$axis$end\" must be a finite number, not \"" . $plot->{"$axis$end"} . '"' unless is_finite( $plot->{"$axis$end"} );
		}
		next unless grep { defined $plot->{"$axis$_"} } ( 'min', 'max' );
		my @finite = finite_values( @{ $xy->[$i] } );
		my $lo = $plot->{"${axis}min"} // min(@finite);
		my $hi = $plot->{"${axis}max"} // max(@finite);
		die "$sub: \"${axis}min\" = $lo is above \"${axis}max\" = $hi" if $lo > $hi;
		my $seq = 'seq(%s, %s, length.out = ' . ( $plot->{"${axis}bins"} + 1 ) . ')';
		if ( $log_axis->{$axis} ) {
			die "$sub: \"logscale\" puts $axis on a log scale, which cannot start at $lo: give a \"${axis}min\" above 0" if $lo <= 0;
			# Even in log units, but given in the data's: stat_bin_2d puts the
			# breaks through the scale's transform, as it does the data. Given
			# as log10s, they were taken to run from 10^0 to 10^0.9 and no bin
			# held a point, under ggplot2 3.5.2 and 4.0.3 alike.
			$breaks{$axis} = '10^' . sprintf( $seq, r_num( log10($lo) ), r_num( log10($hi) ) );
		} else {
			$breaks{$axis} = sprintf( $seq, r_num($lo), r_num($hi) );
		}
	}
	foreach my $opt ( grep { defined $plot->{$_} } ( 'cmin', 'cmax' ) ) {
		check_numbers( [ $plot->{$opt} ], "\"$opt\"", $sub );
	}
	my $what = bool_option( $plot->{density}, 'density', $sub ) ? 'density' : 'count';
	my @out;
	push @out, "$what < " . r_num( $plot->{cmin} ) if defined $plot->{cmin};
	push @out, "$what > " . r_num( $plot->{cmax} ) if defined $plot->{cmax};
	my $fill = @out ? 'ifelse(' . join( ' | ', @out ) . ", NA, $what)" : $what;
	@{ $s->{default_label} }{ 'x', 'y' } = @{$keys};
	set_gradient( $s, gradient_of({ plot => $plot, values => [], aes => 'fill', sub => $sub, native => 1, default_title => undef }), $where, $sub );
	$s->{gradient}{na} = 'NA';    # a bin left out by "cmin" or "cmax" is not drawn
	return if scalar @ok == 0;
	# Both axes are named in "breaks", the one without a "min" or "max" as
	# NULL, which stat_bin_2d bins by "bins" as if no breaks were given. With
	# that axis left out, "breaks = list(x = ...)" was read as the breaks of
	# both, and ggplot2 4.0.3 failed with "`breaks` must be a <numeric>
	# vector, not a list" -- as a warning, so the panel was drawn empty and
	# the script still succeeded.
	my $breaks = %breaks ? 'breaks = list(' . join( ', ', map { "$_ = " . ( $breaks{$_} // 'NULL' ) } ( 'x', 'y' ) ) . '), ' : '';
	push @{ $s->{layers} }, 'ggplot2::geom_bin_2d(data = ' . r_frame( x => r_nums( map { $xy->[0][$_] } @ok ), y => r_nums( map { $xy->[1][$_] } @ok ) )
	 . ", ggplot2::aes(x = x, y = y, fill = ggplot2::after_stat($fill)), $breaks"
	 . 'bins = ' . r_nums( $plot->{xbins}, $plot->{ybins} ) . ', na.rm = TRUE)';
}
sub log10 { return log( $_[0] ) / log(10) }
sub draw_imshow {
	my ( $plot, $s, $where, $sub ) = @_;
	cb_limits( $plot, $sub );
	my $data = $plot->{data};
	die "$sub can only accept 2-D arrays as input in \"data\", but received " . ( ref $data || 'a scalar' ) if ref $data ne 'ARRAY';
	my @bad_rows = grep { ref $data->[$_] ne 'ARRAY' } 0 .. $#{$data};
	die "$sub: rows " . join( ', ', @bad_rows ) . ' of "data" are not array references, which imshow needs' if scalar @bad_rows > 0;
	die "$sub was given no data to draw" if ( scalar @{$data} == 0 ) || ( not grep { scalar @{$_} > 0 } @{$data} );
	my %lengths = map { scalar @{$_} => 1 } @{$data};
	die "$sub: the rows of \"data\" have different lengths (" . join( ', ', map { scalar @{$_} } @{$data} ) . '), but imshow draws a rectangle of cells' if scalar keys %lengths > 1;
	my @undef_cells;
	foreach my $r ( 0 .. $#{$data} ) {
		push @undef_cells, map { "[$r][$_]" } grep { not defined $data->[$r][$_] } 0 .. $#{ $data->[$r] };
	}
	die "$sub cannot draw an undefined cell, and \"data\" has them at " . join( ', ', @undef_cells[ 0 .. min( 4, $#undef_cells ) ] ) . '; a NaN is drawn as an empty cell' if scalar @undef_cells > 0;
	my $strings = grep { grep { not looks_like_number($_) } @{$_} } @{$data};
	die "$sub needs a map to translate strings to integers" if $strings && ( not defined $plot->{stringmap} );
	my ( @x, @y, @v );
	foreach my $r ( 0 .. $#{$data} ) {
		foreach my $c ( 0 .. $#{ $data->[$r] } ) {
			push @x, $c;
			push @y, $r;
			push @v, $data->[$r][$c];
		}
	}
	# Row 0 at the top, as matplotlib's "upper" origin puts it, and each cell
	# centred on its whole-number coordinates.
	$s->{axis}{y}{reverse} = 1;
	$s->{axis}{$_}{expand0} = 1 foreach grep { not $s->{native} } 'x', 'y';    # ggplot2 pads a raster as it pads anything else
	my $layer_aes = 'ggplot2::aes(x = x, y = y, fill = v)';
	if ($strings) {
		die "$sub: \"stringmap\" is a hash of each string in \"data\" to the label it is shown with" unless ref $plot->{stringmap} eq 'HASH';
		die "$sub: \"cb_logscale\" means nothing for imshow with a \"stringmap\": its colors are categories, not a scale" if bool_option( $plot->{cb_logscale}, 'cb_logscale', $sub );
		my @categories = sort keys %{ $plot->{stringmap} };
		my %known = map { $_ => 1 } @categories;
		my @unmapped = sort { $a cmp $b } keys %{ { map { $_ => 1 } grep { not $known{$_} } @v } };
		die "$sub: the values " . join( ', ', map { "\"$_\"" } @unmapped ) . ' of "data" are not keys of "stringmap", which imshow needs to give each one a color' if scalar @unmapped > 0;
		my @colors;
		if ( $s->{native} ) {
			@colors = (undef) x scalar @categories;    # ggplot2's hue scale
		} elsif ( scalar @categories <= scalar @cycle ) {
			@colors = @cycle[ 0 .. $#categories ];
		} else {
			# more categories than the property cycle has colors: gist_rainbow,
			# resampled to as many colors as there are categories
			my @stops = colormap_colors( 'gist_rainbow', $engine, $sub );
			@colors = map { colormap_at( \@stops, ( scalar @categories == 1 ) ? 0 : $_ / $#categories ) } 0 .. $#categories;
		}
		my $show = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $sub );
		$s->{category_fill} = {
			breaks => \@categories,
			labels => [ map { $plot->{stringmap}{$_} } @categories ],
			colors => \@colors,
			title  => defined $plot->{cblabel} ? plain_text( $plot->{cblabel}, 'cblabel', $engine, $sub ) : undef,
			show   => $show,
		};
		push @{ $s->{layers} }, 'ggplot2::geom_tile(data = ' . r_frame( x => r_nums(@x), y => r_nums(@y), v => r_strs(@v) ) . ", $layer_aes)";
		return;
	}
	set_gradient( $s, gradient_of({ plot => $plot, values => \@v, default_cmap => 'viridis', aes => 'fill', sub => $sub, native => $s->{native} }), $where, $sub );
	@v = map { ( $s->{gradient}{log} && looks_like_number($_) && ( $_ <= 0 ) ) ? undef : $_ } @v;    # LogNorm masks what it cannot place
	push @{ $s->{layers} }, 'ggplot2::geom_tile(data = ' . r_frame( x => r_nums(@x), y => r_nums(@y), v => r_nums(@v) ) . ", $layer_aes)";
}
sub draw_colored_table {
	my ( $plot, $s, $where, $sub ) = @_;
	my ( $row_keys, $cols, $cells ) = table_cells( $plot, $sub );
	my @rows = @{$row_keys};
	if ( defined $plot->{row_labels} ) {
		die "$sub: \"row_labels\" is an array of one label per row" unless ref $plot->{row_labels} eq 'ARRAY';
		die "$sub: \"row_labels\" has " . scalar( @{ $plot->{row_labels} } ) . ' labels, but the table has ' . scalar(@rows) . ' rows' if scalar @{ $plot->{row_labels} } != scalar @rows;
		@rows = @{ $plot->{row_labels} };
	}
	if ( defined $plot->{default_undefined} ) {
		die "$sub: \"default_undefined\" = $plot->{default_undefined} must be a number" unless looks_like_number( $plot->{default_undefined} );
	}
	my @non_numeric;
	foreach my $k1 ( @{$row_keys} ) {
		push @non_numeric, map { "$k1/$_ = \"$cells->{$k1}{$_}\"" } grep { ( defined $cells->{$k1}{$_} ) && ( not looks_like_number( $cells->{$k1}{$_} ) ) } @{$cols};
	}
	die "$sub: the cells " . join( ', ', @non_numeric ) . ' are not numbers, which colored_table needs; leave a cell out, or undefined, to draw it in "undef_color"' if scalar @non_numeric > 0;
	foreach my $opt ( grep { defined $plot->{$_} } 'cb_min', 'cb_max' ) {
		die "$sub: \"$opt\" = $plot->{$opt} must be a finite number" unless looks_like_number( $plot->{$opt} ) && is_finite( $plot->{$opt} );
	}
	my ( @x, @y, @v, @text );
	foreach my $r ( 0 .. $#{$row_keys} ) {
		foreach my $c ( 0 .. $#{$cols} ) {
			my $value = $cells->{ $row_keys->[$r] }{ $cols->[$c] } // $plot->{default_undefined};
			push @x, $c + 1;
			push @y, $r + 1;
			push @v, $value;
			push @text, ( ( defined $value ) && ( not is_nan($value) ) ) ? ( 0 + $value ) : '';
		}
	}
	my @finite = finite_values(@v);
	die "$sub: no cell of the data holds a number, so colored_table has nothing to color by" if ( scalar @finite == 0 ) && ( ( not defined $plot->{cb_min} ) || ( not defined $plot->{cb_max} ) );
	my %scale_plot = ( %{$plot}, vmin => $plot->{cb_min}, vmax => $plot->{cb_max} );
	my $gradient = gradient_of({ plot => \%scale_plot, values => \@v, default_cmap => 'gist_rainbow', aes => 'fill', sub => $sub, native => $s->{native},
		na => r_str( color_of( $plot->{undef_color} // ( $s->{native} ? '#7f7f7f' : 'gray' ), '"undef_color"', $sub ) ) });    # #7f7f7f is R's grey50, ggplot2's own na.value
	@v = map { ( $gradient->{log} && defined $_ && looks_like_number($_) && $_ <= 0 ) ? undef : $_ } @v;
	set_gradient( $s, $gradient, $where, $sub );
	# The rows run down from the top, as in the table they are, in either
	# style; the column labels above it and the tiles' black borders are
	# matplotlib's table, and ggplot2's own tiles have neither.
	$s->{kind} = 'table';
	$s->{axis}{y}{reverse} = 1;
	if ( not $s->{native} ) {
		$s->{axis}{x}{top} = 1;
		$s->{axis}{$_}{expand0} = 1 foreach 'x', 'y';
	}
	category_ticks( $s, 'x', [ 1 .. scalar @{$cols} ], $cols );
	category_ticks( $s, 'y', [ 1 .. scalar @rows ], \@rows );
	push @{ $s->{layers} }, 'ggplot2::geom_tile(data = ' . r_frame( x => r_nums(@x), y => r_nums(@y), v => r_nums(@v) ) . ', ggplot2::aes(x = x, y = y, fill = v)' . ( $s->{native} ? '' : ', colour = "#000000", linewidth = 0.3' ) . ')';
	if ( bool_option( $plot->{show_numbers}, 'show_numbers', $sub ) ) {
		push @{ $s->{layers} }, 'ggplot2::geom_text(data = ' . r_frame( x => r_nums(@x), y => r_nums(@y), t => r_strs(@text) ) . ', ggplot2::aes(x = x, y = y, label = t), size = 10 / ggplot2::.pt)';
	}
}
sub draw_pie {
	my ( $plot, $s, $where, $sub ) = @_;
	my @keys = key_order_of( $plot, $plot->{data}, 'key_order', $sub );
	foreach my $key (@keys) {
		my $v = $plot->{data}{$key};
		die "$sub: \"$key\" is not a number, which pie needs to size a wedge" unless looks_like_number($v);
		die "$sub: \"$key\" is not a finite number, which pie needs to size a wedge" unless is_finite($v);
		die "$sub: \"$key\" is $v, but pie cannot size a wedge below 0" if $v < 0;
	}
	die "$sub: every wedge of pie is 0, so there is no pie to divide between them" unless grep { $plot->{data}{$_} > 0 } @keys;
	my %dist = ( labeldistance => 1.1, pctdistance => 0.6 );    # matplotlib's defaults
	foreach my $arg ( grep { defined $plot->{$_} } keys %dist ) {
		check_numbers( [ $plot->{$arg} ], "\"$arg\"", $sub );
		$dist{$arg} = $plot->{$arg};
	}
	my $autopct = $plot->{autopct} // '';
	# A printf format with one number in it, which is what matplotlib's
	# "autopct" string is; Perl's sprintf reads it the same. A Python
	# function is matplotlib's alone.
	if ( ( $autopct ne '' ) && ( ( ref $autopct ) || ( $autopct !~ m/\A(?:[^%]|%%)*%[-+ 0#]*\d*(?:\.\d+)?[dfFeEgGi](?:[^%]|%%)*\z/ ) ) ) {
		die "$sub: \"autopct\" is a format with one number in it, such as '%1.1f%%', for the $engine engine, not \"$autopct\"";
	}
	$s->{kind} = 'pie';
	my $total = sum( map { $plot->{data}{$_} } @keys );
	my $theta = 0;    # matplotlib's startangle 0: from the positive x axis, counterclockwise
	my ( @px, @py, @pg, @fills, @label_rows, @pct_rows );
	foreach my $i ( 0 .. $#keys ) {
		my $frac = $plot->{data}{ $keys[$i] } / $total;
		my $t2 = $theta + 2 * 3.14159265358979 * $frac;
		my $n_pts = max( 2, int( 360 * $frac ) + 1 );
		my @ring = map { $theta + ( $t2 - $theta ) * $_ / ( $n_pts - 1 ) } 0 .. $n_pts - 1;
		push @px, 0, map { cos } @ring;
		push @py, 0, map { sin } @ring;
		push @pg, ($i) x ( $n_pts + 1 );
		push @fills, next_color( $s, 'patch' );
		my $mid = ( $theta + $t2 ) / 2;
		my ( $lx, $ly ) = ( $dist{labeldistance} * cos $mid, $dist{labeldistance} * sin $mid );
		push @label_rows, [ $lx, $ly, $keys[$i], ( $lx > 0 ) ? 0 : 1 ];
		push @pct_rows, [ $dist{pctdistance} * cos $mid, $dist{pctdistance} * sin $mid, sprintf( $autopct, 100 * $frac ) ] if $autopct ne '';
		$theta = $t2;
	}
	# Under "native" the wedges take ggplot2's hue scale, as many colors as
	# there are wedges; their shapes are still worked out above, since ggplot2
	# has no stat of its own for a pie.
	my $fill = $s->{native} ? 'scales::hue_pal()(' . scalar(@keys) . ')[' . r_nums( map { $_ + 1 } @pg ) . ']' : r_strs( map { $fills[$_] } @pg );
	push @{ $s->{layers} }, 'ggplot2::geom_polygon(data = ' . r_frame( x => r_nums(@px), y => r_nums(@py), g => r_nums(@pg) ) . ', ggplot2::aes(x = x, y = y, group = g), fill = ' . $fill . ', colour = NA)';
	push @{ $s->{layers} }, 'ggplot2::geom_text(data = ' . r_frame( x => r_nums( map { $_->[0] } @label_rows ), y => r_nums( map { $_->[1] } @label_rows ), t => r_strs( map { $_->[2] } @label_rows ), h => r_nums( map { $_->[3] } @label_rows ) )
	 . ', ggplot2::aes(x = x, y = y, label = t, hjust = h), size = 10 / ggplot2::.pt)';
	if (@pct_rows) {
		push @{ $s->{layers} }, 'ggplot2::geom_text(data = ' . r_frame( x => r_nums( map { $_->[0] } @pct_rows ), y => r_nums( map { $_->[1] } @pct_rows ), t => r_strs( map { $_->[2] } @pct_rows ) )
		 . ', ggplot2::aes(x = x, y = y, label = t), size = 10 / ggplot2::.pt)';
	}
}
sub draw_plot {
	my ( $plot, $s, $where, $sub ) = @_;
	my $show_legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $sub );
	$s->{axis}{$_}{log} = 1 foreach logscale_axes( $plot->{logscale}, $sub );
	my $data = $plot->{data};
	my @lines;    # [ name or undef, \@x, \@y ]
	if ( ( ref $data eq 'ARRAY' ) && ( scalar @{$data} == 2 ) && ( ref $data->[0] eq 'ARRAY' ) && ( ref $data->[1] eq 'ARRAY' ) && ( ref $data->[0][0] ne 'ARRAY' ) ) {
		$data = [$data];    # one line given as [ \@x, \@y ]
	}
	if ( ref $data eq 'ARRAY' ) {
		foreach my $i ( 0 .. $#{$data} ) {
			my $arr = $data->[$i];
			die "$sub: index $i is \"" . ref($arr) . '" but must be "ARRAY"' if ref $arr ne 'ARRAY';
			die "$sub: there must be 2 array references (x, y) but index $i has " . scalar( @{$arr} ) if scalar @{$arr} != 2;
			push @lines, [ undef, @{$arr}, "index $i" ];
		}
	} elsif ( ref $data eq 'HASH' ) {
		foreach my $set ( key_order_of( $plot, $data, 'key_order', $sub ) ) {
			my $xy = $data->{$set};
			die "$sub: $set must have two arrays, x and y coordinates, or one array of y values, but instead has a " . ( ref $xy || 'scalar' ) if ref $xy ne 'ARRAY';
			my $n_refs = grep { ref } @{$xy};
			if ( ( $n_refs == 0 ) && ( scalar @{$xy} > 0 ) ) {
				$xy = [ [ 0 .. $#{$xy} ], $xy ];
			} elsif ( $n_refs < scalar @{$xy} ) {
				die "$sub: set \"$set\" mixes arrays with plain values: it must be [ \\\@x, \\\@y ] or one array of y values";
			}
			die "$sub: " . scalar( @{$xy} ) . " were entered for $set, but there must be exactly 2" if scalar @{$xy} != 2;
			push @lines, [ ( $show_legend ? $set : undef ), @{$xy}, "set \"$set\"" ];
		}
	} else {
		die "$sub: \"data\" for plot is an array of [ \\\@x, \\\@y ] pairs or a hash of them, not " . ( ref $data || 'a scalar' );
	}
	foreach my $line (@lines) {
		my ( $name, $x, $y, $what ) = @{$line};
		die "$sub: $what has length = " . scalar( @{$x} ) . ' for x; length = ' . scalar( @{$y} ) . ' for y: x & y must be of equal length' if scalar @{$x} != scalar @{$y};
		foreach my $axis ( [ 'x', $x ], [ 'y', $y ] ) {
			my @bad = grep { ( not defined $_ ) || ( not looks_like_number($_) ) } @{ $axis->[1] };
			die "$sub: $what axis $axis->[0] has undefined or non-numeric values: \"" . join( '", "', map { $_ // 'undef' } @bad ) . '"' if scalar @bad > 0;
		}
		my $color = next_color( $s, 'line' );
		# a value matplotlib cannot place, NaN or infinite, is a gap in the line
		my $frame = r_frame( x => r_nums( map { is_finite($_) ? $_ : undef } @{$x} ), y => r_nums( map { is_finite($_) ? $_ : undef } @{$y} ) );
		my $lw = line_width($s);
		add_legend( $s->{colour_d}, $name, $color ) if defined $name;
		# A line of no points is drawn as nothing, as matplotlib draws it, its
		# color taken from the cycle all the same; R's cbind() cannot add a
		# column to a frame of no rows, and died as "differing number of rows".
		next if scalar @{$x} == 0;
		if ( defined $name ) {
			push @{ $s->{layers} }, "ggplot2::geom_path(data = cbind($frame, s = " . r_str($name) . "), ggplot2::aes(x = x, y = y, colour = s)$lw, na.rm = TRUE)";
		} else {
			push @{ $s->{layers} }, "ggplot2::geom_path(data = $frame, ggplot2::aes(x = x, y = y)" . ( defined $color ? ', colour = ' . r_str($color) : '' ) . "$lw, na.rm = TRUE)";
		}
	}
}
sub draw_scatter {
	my ( $plot, $s, $where, $sub ) = @_;
	foreach my $cb ( grep { defined $plot->{$_} } ( 'cb_min', 'cb_max' ) ) {
		check_numbers( [ $plot->{$cb} ], "\"$cb\"", $sub );
	}
	cb_limits( $plot, $sub );
	my $data = $plot->{data};
	die "$sub: scatter only takes a hash of arrays or a hash of hashes, not " . ( ref $data || 'a scalar' ) if ref $data ne 'HASH';
	my %ref_counts;
	$ref_counts{ ref $data->{$_} }++ foreach keys %{$data};
	die "$sub: different kinds of data were entered$where; should be a hash of arrays or a hash of hashes" if scalar keys %ref_counts > 1;
	$s->{axis}{$_}{log} = 1 foreach logscale_axes( $plot->{logscale}, $sub );
	my $sorted = sub { sort { lc $a cmp lc $b || $a cmp $b } @_ };
	# x, y and color keys of one set, as scatter_helper settles them
	my $axes_of = sub {
		my ( $set, $what ) = @_;
		my @keys = defined $plot->{keys} ? check_key_order({ keys => $plot->{keys}, data => $set, option => 'keys', sub => $sub }) : $sorted->( keys %{$set} );
		my $n_keys = scalar keys %{$set};
		die "$sub: scatterplots can only take 2 or 3 keys as data, but$what has $n_keys" if ( $n_keys != 2 ) && ( $n_keys != 3 );
		my $color_key;
		if ( defined $plot->{color_key} ) {
			$color_key = $plot->{color_key};
			# before the keys are counted, or a "color_key" that is not a key of
			# three is reported as leaving 3 keys, without its name
			die "$sub: \"$color_key\" isn't defined$what" unless defined $set->{$color_key};
			@keys = grep { $_ ne $color_key } @keys;
		} elsif ( scalar @keys == 3 ) {
			$color_key = pop @keys;
		} elsif ( $n_keys == 3 ) {
			my %named = map { $_ => 1 } @keys;
			($color_key) = grep { not $named{$_} } $sorted->( keys %{$set} );
		}
		die "$sub$what needs one key for x and one for y, but \"keys\" and \"color_key\" leave " . scalar(@keys) if scalar @keys != 2;
		foreach my $key (@keys) {
			check_scatter_values( $set->{$key}, "\"$key\"$what", $sub );
		}
		if ( defined $color_key ) {
			die "$sub: \"$color_key\" isn't defined$what" unless defined $set->{$color_key};
			check_scatter_values( $set->{$color_key}, "\"$color_key\"$what", $sub );
		}
		check_scatter_lengths( $set, [ @keys, ( defined $color_key ? $color_key : () ) ], $what, $sub );
		return ( \@keys, $color_key );
	};
	my @sets;    # [ name or undef, \%set, \@xy keys, color key ]
	if ( defined $ref_counts{ARRAY} ) {
		die "$sub: \"key_order\" orders the sets of a hash of sets; for the axes of a single set, use \"keys\"" if defined $plot->{key_order};
		my ( $keys, $color_key ) = $axes_of->( $data, '' );
		push @sets, [ undef, $data, $keys, $color_key ];
	} elsif ( defined $ref_counts{HASH} ) {
		my $show_legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $sub );
		foreach my $name ( key_order_of( $plot, $data, 'key_order', $sub ) ) {
			my $inner = $data->{$name};
			# a set of numbers alone is one point
			$inner = { map { $_ => [ $inner->{$_} ] } keys %{$inner} } if ( scalar keys %{$inner} > 0 ) && ( not grep { ref } values %{$inner} );
			my ( $keys, $color_key ) = $axes_of->( $inner, " of set \"$name\"" );
			push @sets, [ ( $show_legend ? $name : undef ), $inner, $keys, $color_key ];
		}
	} else {
		die "$sub: Could not determine the scatter type of \"data\"$where";
	}
	@{ $s->{default_label} }{ 'x', 'y' } = @{ $sets[-1][2] };
	my @colored = grep { defined $_->[3] } @sets;
	if (@colored) {
		my @z = map { @{ $_->[1]{ $_->[3] } } } @colored;
		set_gradient( $s, gradient_of({ plot => $plot, values => \@z, default_cmap => 'gist_rainbow', default_title => $colored[-1][3], aes => 'colour', sub => $sub, native => $s->{native} }), $where, $sub );
	}
	# Sets colored by value are told apart by their markers, in the order of
	# scatter_helper's (o s ^ D v P X * < > p h d) as near as R's own point
	# shapes come; the list repeats once it runs out.
	my @shapes = ( 16, 15, 17, 18, 25, 3, 4, 8, 1, 0, 2, 5, 6 );
	my $shape_i = 0;
	foreach my $set (@sets) {
		my ( $name, $values, $keys, $color_key ) = @{$set};
		# A set of no points is drawn as nothing, as matplotlib draws it: its
		# empty columns were written c(), which R reads as NULL and leaves out
		# of the frame, and ggplot2 died with "object 'x' not found".
		next if scalar @{ $values->{ $keys->[0] } } == 0;
		my @cols = ( x => r_nums( @{ $values->{ $keys->[0] } } ), y => r_nums( @{ $values->{ $keys->[1] } } ) );
		if ( defined $color_key ) {
			my @z = @{ $values->{$color_key} };
			@z = map { $_ > 0 ? $_ : undef } @z if $s->{gradient}{log};
			push @cols, z => r_nums(@z);
			# Under "native" the sets take ggplot2's own shape scale, in the
			# order of the sets, and a lone set its default point.
			my $shape = $s->{native} ? undef : ( scalar @sets > 1 ) ? $shapes[ $shape_i++ % scalar @shapes ] : 16;
			my $size = marker_size($s);
			if ( defined $name ) {
				add_legend( $s->{shape_d}, $name, $shape );
				push @{ $s->{layers} }, 'ggplot2::geom_point(data = cbind(' . r_frame(@cols) . ', s = ' . r_str($name) . "), ggplot2::aes(x = x, y = y, colour = z, shape = s)" . ( $s->{native} ? '' : ', fill = NA' ) . "$size, na.rm = TRUE)";
			} else {
				push @{ $s->{layers} }, 'ggplot2::geom_point(data = ' . r_frame(@cols) . ", ggplot2::aes(x = x, y = y, colour = z)" . ( defined $shape ? ", shape = $shape" : '' ) . "$size, na.rm = TRUE)";
			}
		} else {
			my $color = next_color( $s, 'patch' );
			my $style = $s->{native} ? marker_size($s) : ", shape = 16" . marker_size($s);
			if ( defined $name ) {
				add_legend( $s->{colour_d}, $name, $color );
				push @{ $s->{layers} }, 'ggplot2::geom_point(data = cbind(' . r_frame(@cols) . ', s = ' . r_str($name) . "), ggplot2::aes(x = x, y = y, colour = s)$style, na.rm = TRUE)";
			} else {
				push @{ $s->{layers} }, 'ggplot2::geom_point(data = ' . r_frame(@cols) . ', ggplot2::aes(x = x, y = y)' . ( defined $color ? ', colour = ' . r_str($color) : '' ) . "$style, na.rm = TRUE)";
			}
		}
	}
}
sub wide_summary {
	# The runs of one "wide" group, summarised as write_wide_group in
	# Matplotlib::Simple::Matplotlib summarises them: each run sorted by x and
	# interpolated onto 101 points across the group's x range, NaN outside the
	# run's own range, and at each point the mean and the population standard
	# deviation of the runs that reach it. Returns ( \@base_x, \@mean, \@sd ).
	my ($runs) = @_;
	my ( $lo, $hi ) = ( 9**9**9, -9**9**9 );
	foreach my $run ( @{$runs} ) {
		my @f = finite_values( @{ $run->[0] } );
		$lo = min( $lo, @f );
		$hi = max( $hi, @f );
	}
	my @base = linspace( $lo, $hi, 101 );    # as the matplotlib engine's np.linspace(min, max, 101)
	my @ys;
	foreach my $run ( @{$runs} ) {
		my @order = sort { $run->[0][$a] <=> $run->[0][$b] } 0 .. $#{ $run->[0] };    # Perl's sort is stable, as numpy's 'stable' is
		my @x = @{ $run->[0] }[@order];
		my @y = @{ $run->[1] }[@order];
		my @interp;
		foreach my $bx (@base) {
			my $v;
			if ( ( $bx >= $x[0] ) && ( $bx <= $x[-1] ) ) {
				my $j = 0;
				$j++ while ( $j < $#x - 1 ) && ( $x[ $j + 1 ] < $bx );
				if    ( $bx == $x[$j] ) { $v = $y[$j] }    # numpy returns a sample point's own value
				elsif ( ( $j < $#x ) && ( $bx == $x[ $j + 1 ] ) ) { $v = $y[ $j + 1 ] }
				elsif ( $j < $#x ) { $v = $y[$j] + ( $y[ $j + 1 ] - $y[$j] ) * ( $bx - $x[$j] ) / ( $x[ $j + 1 ] - $x[$j] ) }
			}
			push @interp, ( ( defined $v ) && ( not is_nan($v) ) ) ? $v : undef;
		}
		push @ys, \@interp;
	}
	my ( @mean, @sd );
	foreach my $i ( 0 .. $#base ) {
		my @at = grep { defined } map { $_->[$i] } @ys;
		if ( scalar @at == 0 ) {
			push @mean, undef;
			push @sd, undef;
			next;
		}
		my $m = sum(@at) / scalar @at;
		push @mean, $m;
		push @sd, sqrt( sum( map { ( $_ - $m )**2 } @at ) / scalar @at );
	}
	return ( \@base, \@mean, \@sd );
}
sub draw_wide {
	my ( $plot, $s, $where, $sub ) = @_;
	my $show_legend = bool_option( $plot->{show_legend} // 1, 'show_legend', $sub );
	my @groups;    # [ name or undef, runs, color ]
	if ( ref $plot->{data} eq 'HASH' ) {
		die "$sub: \"data\" is a HASH of groups, so \"color\" must be a HASH of one color per group" if ( defined $plot->{color} ) && ( ref $plot->{color} ne 'HASH' );
		my $i = 0;
		foreach my $group ( sort keys %{ $plot->{data} } ) {
			check_wide_runs( $plot->{data}{$group}, "group \"$group\"", $sub );
			my $c = defined $plot->{color}{$group} ? color_of( $plot->{color}{$group}, "\"color\" of \"$group\"", $sub ) : $s->{native} ? undef : $cycle[ $i % scalar @cycle ];
			push @groups, [ ( ( $show_legend || $s->{native} ) ? $group : undef ), $plot->{data}{$group}, $c ];
			$i++;
		}
	} elsif ( ref $plot->{data} eq 'ARRAY' ) {
		die "$sub: \"data\" is one unlabelled group, so \"color\" must be a single color, not a " . ref( $plot->{color} ) . ' reference' if ref $plot->{color};
		check_wide_runs( $plot->{data}, '"data"', $sub );
		push @groups, [ undef, $plot->{data}, ( ( defined $plot->{color} ) || ( not $s->{native} ) ) ? color_of( $plot->{color} // 'b', '"color"', $sub ) : undef ];    # undef: ggplot2's own black line and grey band
	} else {
		die "$sub cannot take ref type \"" . ( ref $plot->{data} || 'scalar' ) . '" for "data"';
	}
	# Under "native" every group with a name is mapped to the colour and fill
	# scales, which give it ggplot2's hue where it has no color of its own and
	# keep one legend, of the colour; with "show_legend" off the legend is
	# hidden, but the groups are still told apart.
	$s->{guide_none}{colour} = 1 if $s->{native} && ( not $show_legend );
	foreach my $group (@groups) {
		my ( $name, $runs, $color ) = @{$group};
		my $mapped = $s->{native} && ( defined $name );
		my ( $line_aes, $fill_aes, $line_fix, $fill_fix ) = ( '', '', '', '' );
		if ($mapped) {
			( $line_aes, $fill_aes ) = ( ', colour = s', ', fill = s' );
			add_legend( $s->{colour_d}, $name, $color );
			add_legend( $s->{fill_d}, $name, $color );
			$s->{guide_none}{fill} = 1;
		} elsif ( defined $color ) {
			( $line_fix, $fill_fix ) = ( ', colour = ' . r_str($color), ', fill = ' . r_str($color) );
		}
		my $named = sub { my ($frame) = @_; return $mapped ? "cbind($frame, s = " . r_str($name) . ')' : $frame };
		my $lw = line_width($s);
		foreach my $run ( @{$runs} ) {
			my @order = sort { $run->[0][$a] <=> $run->[0][$b] } 0 .. $#{ $run->[0] };
			push @{ $s->{layers} }, 'ggplot2::geom_path(data = ' . $named->( r_frame( x => r_nums( @{ $run->[0] }[@order] ), y => r_nums( map { is_finite($_) ? $_ : undef } @{ $run->[1] }[@order] ) ) )
			 . ", ggplot2::aes(x = x, y = y$line_aes)$line_fix, alpha = 0.15$lw, na.rm = TRUE)";
		}
		my ( $base, $mean, $sd ) = wide_summary($runs);
		# The band of one standard deviation each side of the mean, as one
		# polygon for each stretch of x where the mean is defined: geom_ribbon
		# draws a polygon per interval, and in a PNG the seams between them
		# showed as faint vertical streaks.
		my ( @px, @py, @pg, @run );
		my $g = 0;
		foreach my $i ( 0 .. $#{$base}, undef ) {
			if ( ( defined $i ) && ( defined $mean->[$i] ) ) {
				push @run, $i;
				next;
			}
			if ( scalar @run > 1 ) {
				push @px, @{$base}[@run], reverse @{$base}[@run];
				push @py, ( map { $mean->[$_] - $sd->[$_] } @run ), ( map { $mean->[$_] + $sd->[$_] } reverse @run );
				push @pg, ($g) x ( 2 * scalar @run );
				$g++;
			}
			@run = ();
		}
		if (@px) {
			push @{ $s->{layers} }, 'ggplot2::geom_polygon(data = ' . $named->( r_frame( x => r_nums(@px), y => r_nums(@py), g => r_nums(@pg) ) ) . ", ggplot2::aes(x = x, y = y, group = g$fill_aes)$fill_fix, alpha = 0.3, colour = NA)";
		}
		my $frame = r_frame( x => r_nums( @{$base} ), m => r_nums( @{$mean} ) );
		if ( ( defined $name ) && ( not $s->{native} ) ) {
			add_legend( $s->{colour_d}, $name, $color );
			push @{ $s->{layers} }, "ggplot2::geom_path(data = cbind($frame, s = " . r_str($name) . "), ggplot2::aes(x = x, y = m, colour = s)$lw, na.rm = TRUE)";
		} else {
			push @{ $s->{layers} }, 'ggplot2::geom_path(data = ' . $named->($frame) . ", ggplot2::aes(x = x, y = m$line_aes)$line_fix$lw, na.rm = TRUE)";
		}
	}
}
my %drawer = (
	bar => \&draw_bar, barh => \&draw_bar, boxplot => \&draw_boxplot, colored_table => \&draw_colored_table,
	hist => \&draw_hist, hist2d => \&draw_hist2d, imshow => \&draw_imshow, pie => \&draw_pie,
	plot => \&draw_plot, scatter => \&draw_scatter, violin => \&draw_violin, violinplot => \&draw_violin,
	wide => \&draw_wide,
);
sub last_value {
	# An option that matplotlib calls once per element of an array: the last
	# call is the one that stands.
	my ($v) = @_;
	return ( ref $v eq 'ARRAY' ) ? $v->[-1] : $v;
}
sub apply_axes_keywords {
	# The title, the axis labels, ranges and scales one plot hash asks for.
	# The pyplot forms ("title", "xlabel", "ylim", "xscale") come after the
	# axes forms ("set_title", ...), as matplotlib's engine writes them, so
	# where both are given the pyplot one stands.
	my ( $plot, $s, $where, $sub ) = @_;
	my %text = ( title => [ 'set_title', 'title' ], x => [ 'set_xlabel', 'xlabel' ], y => [ 'set_ylabel', 'ylabel' ] );
	foreach my $what ( sort keys %text ) {
		foreach my $option ( grep { defined $plot->{$_} } @{ $text{$what} } ) {
			my $value = last_value( $plot->{$option} );
			die "$sub: \"$option\"$where is text, not a " . ref($value) . ' reference' if ref $value;
			$s->{text}{$what} = plain_text( $value, $option, $engine, $sub );
		}
	}
	foreach my $option ( grep { defined $plot->{$_} } ( 'set_xlim', 'set_ylim', 'ylim' ) ) {
		my $axis = ( $option =~ m/x/ ) ? 'x' : 'y';
		die "$sub: \"$option\" means nothing for a $plot->{plot_type}, which has no axes" if $s->{kind} ne 'cartesian';
		$s->{axis}{$axis}{lim} = [ axis_limits( $plot->{$option}, $option, $engine, $sub ) ];
	}
	foreach my $option ( grep { defined $plot->{$_} } ( 'set_xscale', 'set_yscale', 'xscale', 'yscale' ) ) {
		my $axis = ( $option =~ m/x/ ) ? 'x' : 'y';
		die "$sub: \"$option\" means nothing for a $plot->{plot_type}, which has no axes" if $s->{kind} ne 'cartesian';
		$s->{axis}{$axis}{log} = ( axis_scale( $plot->{$option}, $option, $engine, $sub ) eq 'log' ) ? 1 : 0;
	}
}
sub panel_code {
	# One subplot, its "add" graphs drawn first and the plot itself last, as
	# R code making a ggplot object. $native: 1 = style "native".
	my ( $plot, $where, $sub, $native ) = @_;
	my $s = new_panel($native);
	my @graphs = ( @{ $plot->{add} // [] }, $plot );
	my %axis_kind;    # under "native": axis => [ 'discrete' or 'continuous', the type that made it so ]
	foreach my $graph (@graphs) {
		my $type = $graph->{plot_type};
		my $what = ( $graph == $plot ) ? $where : " for an \"add\" graph$where";
		if ( ( scalar @graphs > 1 ) && ( ( $type eq 'pie' ) || ( $type eq 'colored_table' ) ) ) {
			die "$sub: a $type$what has no axes to share, so the $engine engine draws it alone, with no \"add\" graph over it or under it";
		}
		$s->{discrete} = {};
		$drawer{$type}->( $graph, $s, $what, $sub );
		next unless $native;
		# A bar, box or violin stands on a discrete axis of its keys under
		# "native", and ggplot2 cannot put that axis under a graph whose
		# positions on it are numbers.
		foreach my $axis ( 'x', 'y' ) {
			my $kind = $s->{discrete}{$axis} ? 'discrete' : 'continuous';
			if ( ( defined $axis_kind{$axis} ) && ( $axis_kind{$axis}[0] ne $kind ) ) {
				die "$sub: in style \"native\" the $engine engine puts the keys of a bar, boxplot or violin on a discrete axis, so the $type$what cannot share the $axis axis with the $axis_kind{$axis}[1] it is drawn with; "
				 . 'give "style => \'matplotlib\'", where every position is a number';
			}
			$axis_kind{$axis} //= [ $kind, $type ];
		}
	}
	push @{ $s->{layers} }, @{ $s->{after} // [] };
	apply_axes_keywords( $_, $s, $where, $sub ) foreach @graphs;
	my @code = ( 'ggplot2::ggplot()', @{ $s->{layers} } );
	foreach my $axis ( 'x', 'y' ) {
		my $a = $s->{axis}{$axis};
		next if $s->{kind} eq 'pie';
		my @arg;
		if ( defined $a->{breaks} ) {
			push @arg, 'breaks = ' . r_nums( @{ $a->{breaks} } ), 'labels = ' . r_strs( @{ $a->{labels} } );
		}
		if ( $a->{log} && $a->{reverse} ) {
			die "$sub: the $engine engine cannot put the $axis axis$where on a log scale, since it runs downwards, as the rows of a $plot->{plot_type} do";
		}
		push @arg, 'transform = "log10"' if $a->{log};
		push @arg, 'transform = "reverse"' if $a->{reverse};
		push @arg, 'expand = c(0, 0)' if $a->{expand0};
		push @arg, 'expand = ggplot2::expansion(mult = c(0, 0.05))' if $a->{floor};    # the bars of a log axis start at its bottom edge, as draw_bar explains
		push @arg, 'position = "top"' if $a->{top};
		push @code, "ggplot2::scale_${axis}_continuous(" . join( ', ', @arg ) . ')' if @arg;
	}
	my @lim = map { $s->{axis}{$_}{lim} ? ( "${_}lim = " . r_nums( @{ $s->{axis}{$_}{lim} } ) ) : () } 'x', 'y';
	if ( $s->{kind} eq 'pie' ) {
		push @code, 'ggplot2::coord_equal(clip = "off")';
	} elsif (@lim) {
		push @code, 'ggplot2::coord_cartesian(' . join( ', ', @lim ) . ')';
	}
	foreach my $legend ( [ 'colour', 'colour_d' ], [ 'fill', 'fill_d' ], [ 'shape', 'shape_d' ] ) {
		my ( $aes, $list ) = @{$legend};
		next unless @{ $s->{$list} };
		if ( ( defined $s->{gradient} ) && ( $s->{gradient}{aes} eq $aes ) ) {
			die "$sub: the $engine engine cannot give the $aes of the plot$where both a scale of values and a legend of names";
		}
		my @names = map { $_->[0] } @{ $s->{$list} };
		my @given = grep { defined $s->{$list}[$_][1] } 0 .. $#names;
		my $guide = $s->{guide_none}{$aes} ? ', guide = "none"' : '';
		if ( scalar @given == scalar @names ) {
			my $values = ( $aes eq 'shape' ) ? r_nums( map { $_->[1] } @{ $s->{$list} } ) : r_strs( map { $_->[1] } @{ $s->{$list} } );
			push @code, "ggplot2::scale_${aes}_manual(name = NULL, values = stats::setNames($values, " . r_strs(@names) . '), breaks = ' . r_strs(@names) . "$guide)";
		} elsif ( scalar @given == 0 ) {
			# "native", with no color given: ggplot2's own scale, its levels in
			# the order the series were drawn
			my $scale = ( $aes eq 'shape' ) ? 'scale_shape_discrete' : "scale_${aes}_hue";
			push @code, "ggplot2::$scale(name = NULL, limits = " . r_strs(@names) . ', breaks = ' . r_strs(@names) . "$guide)";
		} else {
			# "native", with some colors given: ggplot2's hue for as many series
			# as there are, each given color put in its series' place
			push @code, "ggplot2::scale_${aes}_manual(name = NULL, values = replace(stats::setNames(scales::hue_pal()(" . scalar(@names) . '), ' . r_strs(@names) . '), '
			 . r_nums( map { $_ + 1 } @given ) . ', ' . r_strs( map { $s->{$list}[$_][1] } @given ) . '), breaks = ' . r_strs(@names) . "$guide)";
		}
	}
	if ( my $c = $s->{category_fill} ) {
		die "$sub: the $engine engine cannot give the plot$where two legends of fill colors" if @{ $s->{fill_d} };
		my $name = 'name = ' . ( defined $c->{title} ? r_str( $c->{title} ) : 'NULL' );
		my $tail = ', breaks = ' . r_strs( @{ $c->{breaks} } ) . ', labels = ' . r_strs( @{ $c->{labels} } ) . ', guide = ' . ( $c->{show} ? '"legend"' : '"none"' ) . ')';
		if ( grep { not defined } @{ $c->{colors} } ) {
			push @code, "ggplot2::scale_fill_hue($name, limits = " . r_strs( @{ $c->{breaks} } ) . $tail;    # "native": ggplot2's hue for each category
		} else {
			push @code, "ggplot2::scale_fill_manual($name, values = stats::setNames(" . r_strs( @{ $c->{colors} } ) . ', ' . r_strs( @{ $c->{breaks} } ) . ')' . $tail;
		}
	}
	if ( my $g = $s->{gradient} ) {
		if ( $s->{native} ) {
			# ggplot2's own gradient where no colormap was asked for, its own
			# title where none was given, and its own ends where none were
			my @arg;
			push @arg, 'name = ' . r_str( $g->{title} ) unless $g->{waiver};
			push @arg, 'colours = ' . r_strs( @{ $g->{colors} } ) if defined $g->{colors};
			push @arg, 'limits = ' . r_nums( $g->{lo}, $g->{hi} ), 'oob = scales::squish' if ( defined $g->{lo} ) || ( defined $g->{hi} );
			push @arg, "na.value = $g->{na}" unless $g->{na} eq 'NA' && $g->{type} ne 'hist2d';    # NA leaves ggplot2's grey50, except for the bins hist2d leaves out
			push @arg, 'transform = "log10"' if $g->{log};
			push @arg, 'guide = "none"' unless $g->{show};
			push @code, "ggplot2::scale_$g->{aes}_" . ( defined $g->{colors} ? 'gradientn' : 'gradient' ) . '(' . join( ', ', @arg ) . ')';
		} else {
			push @code, "ggplot2::scale_$g->{aes}_gradientn(name = " . ( defined $g->{title} ? r_str( $g->{title} ) : 'NULL' ) . ', colours = ' . r_strs( @{ $g->{colors} } )
			 . ', limits = ' . r_nums( $g->{lo}, $g->{hi} ) . ', oob = scales::squish, na.value = ' . $g->{na}
			 . ( $g->{log} ? ', transform = "log10"' : '' ) . ', guide = ' . ( $g->{show} ? 'ggplot2::guide_colourbar(theme = ggplot2::theme(legend.key.height = grid::unit(1, "null")))' : '"none"' ) . ')';
		}
	}
	my $title = $s->{text}{title};
	my %label = map { $_ => $s->{text}{$_} // $s->{default_label}{$_} } 'x', 'y';
	# NULL where nothing is given: ggplot2 would otherwise label an axis with
	# the name of the data.frame column, which is not the caller's text.
	push @code, 'ggplot2::labs(title = ' . ( defined $title ? r_str($title) : 'NULL' ) . join( '', map { ", $_ = " . ( defined $label{$_} ? r_str( $label{$_} ) : 'NULL' ) } 'x', 'y' ) . ')';
	if ( $s->{native} ) {
		# theme_grey, ggplot2's default, needs no call; a pie has no axes in
		# ggplot2 either, so it is drawn on theme_void, with room for its labels
		push @code, 'ggplot2::theme_void()', 'ggplot2::theme(plot.margin = ggplot2::margin(20, 40, 20, 40))' if $s->{kind} eq 'pie';
		return join( " +\n\t\t", @code );
	}
	push @code, 'ggplot2::theme_bw(base_size = 10)',
	 'ggplot2::theme(panel.grid = ggplot2::element_blank(), plot.title = ggplot2::element_text(hjust = 0.5, size = 12), axis.text = ggplot2::element_text(size = 10, colour = "#000000"), legend.text = ggplot2::element_text(size = 10))';
	push @code, 'ggplot2::theme(axis.ticks = ggplot2::element_blank(), panel.border = ggplot2::element_blank())' if $s->{kind} eq 'table';
	push @code, 'ggplot2::theme_void(base_size = 10)', 'ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 12), plot.margin = ggplot2::margin(20, 40, 20, 40))' if $s->{kind} eq 'pie';
	return join( " +\n\t\t", @code );
}
sub device_of {
	# The R graphics device for an output file, by its extension, as R code
	# opening it at the given size. Every one of these devices reads a "%" in
	# its file name as the start of a page-number format, so each is doubled.
	my ( $file, $w, $h, $sub ) = @_;
	my ($ext) = $file =~ m/\.([^.\/\\]+)\z/;
	$ext = lc( $ext // '' );
	( my $name = $file ) =~ s/%/%%/g;
	my $path = r_str($name);
	return "grDevices::svg($path, width = $w, height = $h)" if $ext eq 'svg';
	return "grDevices::png($path, width = " . int( $w * $png_dpi + 0.5 ) . ', height = ' . int( $h * $png_dpi + 0.5 ) . ", res = $png_dpi)" if $ext eq 'png';
	return "grDevices::cairo_pdf($path, width = $w, height = $h)" if $ext eq 'pdf';    # cairo, as svg() is, so that text outside Latin-1 is drawn
	die "$sub: the $engine engine writes .svg, .png and .pdf files, so it cannot write \"$file\"";
}
sub creator_code {
	# R that gives the SVG just drawn the note matplotlib gives its own, in
	# <dc:title>, which no R device writes. The script reads the R and ggplot2
	# versions, the user and the host as it runs, as the matplotlib engine's
	# does, so that a script written with "execute => 0" and run later names
	# whoever ran it. The file is spliced as raw bytes, so no encoding R might
	# take it to be in can change it.
	my ( $file, $sub ) = @_;
	my ( $before, $after ) = svg_creator_metadata();
	my $note = r_str( creator_note($sub) );
	return <<"R";
	local({
		# Sys.info() is NULL where R cannot ask, and its user is "unknown"
		# when R cannot find one; as matplotlib's script, the note says so.
		field <- function(name, otherwise) {
			value <- Sys.info()[name]
			if (is.null(value) || is.na(value) || !nzchar(value) || value == "unknown") otherwise else unname(value)
		}
		note <- paste0($note, ", R ", getRversion(), ", ggplot2 ", utils::packageVersion("ggplot2"),
			", by ", field("user", "unknown user"), " on ", field("nodename", "unknown host"))
		note <- gsub("&", "&amp;", note, fixed = TRUE) # first, or the escapes below would be escaped again
		note <- gsub("<", "&lt;", note, fixed = TRUE)
		note <- gsub(">", "&gt;", note, fixed = TRUE)
		svg <- ${\ r_str($file) }
		bytes <- readBin(svg, "raw", file.size(svg))
		at <- grepRaw(">", bytes, offset = grepRaw("<svg", bytes, fixed = TRUE), fixed = TRUE)
		block <- charToRaw(enc2utf8(paste0(${\ r_str($before) }, note, ${\ r_str($after) })))
		writeBin(c(bytes[seq_len(at)], block, bytes[-seq_len(at)]), svg)
	})
R
}
sub render {
	# plt's figure as an R script, which is run unless "execute" is false.
	# Returns the script's path. Its arguments are those of
	# Matplotlib::Simple::Matplotlib::render.
	#
	# Each figure is self-contained -- it loads ggplot2, opens its own device,
	# draws inside local() and closes the device -- so that several calls can
	# write into one "fh", with "execute => 0" on all but the last, and the
	# script run once draws them all.
	my ( $args, $context ) = @_;
	my $sub = $context->{sub};
	my @plots = $context->{single_plot} ? ($args) : @{ $args->{plots} };
	if ( not defined $args->{output_file} ) {
		die "$sub: the $engine engine writes the figure to \"output_file\", which is not given";
	}
	my %scale;
	foreach my $opt ( 'scale', 'scalex', 'scaley' ) {
		$scale{$opt} = $args->{$opt} // 1;
	}
	my $w = $fig_w * $scale{scale} * $scale{scalex};
	my $h = $fig_h * $scale{scale} * $scale{scaley};
	my $device = device_of( $args->{output_file}, $w, $h, $sub );
	my @panels;
	foreach my $i ( 0 .. $#plots ) {
		push @panels, panel_code( $plots[$i], $context->{single_plot} ? '' : " at subplot $i", $sub, ( ( $context->{style} // 'native' ) eq 'native' ) ? 1 : 0 );
	}
	my $suptitle = defined $args->{suptitle} ? plain_text( last_value( $args->{suptitle} ), 'suptitle', $engine, $sub ) : undef;
	my $fh = script_handle( $args, '.R', $sub );
	# The note is a comment, so it is made ASCII by hand: r_str's escapes
	# mean nothing there.
	( my $note = creator_note($sub) ) =~ s/([^\x20-\x7e])/sprintf '\\x{%x}', ord $1/ge;
	say {$fh} "# Written by Matplotlib::Simple's $engine engine: $note";
	say {$fh} 'if (!requireNamespace("ggplot2", quietly = TRUE) || utils::packageVersion("ggplot2") < ' . r_str($min_ggplot2) . ') {';
	say {$fh} "\tmessage(\"Matplotlib::Simple: the $engine engine needs the R package ggplot2 $min_ggplot2 or newer, which this R cannot load; install it with install.packages(\\\"ggplot2\\\")\")";
	say {$fh} "\tquit(status = 1)";
	say {$fh} '}';
	say {$fh} 'local({';
	foreach my $i ( 0 .. $#panels ) {
		say {$fh} "\tp$i <- $panels[$i]";
	}
	my ( $nrows, $ncols ) = ( $args->{nrows} // 1, $args->{ncols} // 1 );
	my $top = defined $suptitle ? 1 : 0;
	say {$fh} "\t$device";
	say {$fh} "\tgrid::grid.newpage()";
	say {$fh} "\tgrid::pushViewport(grid::viewport(layout = grid::grid.layout($nrows + $top, $ncols, heights = grid::unit.c(" . ( $top ? 'grid::unit(2, "lines"), ' : '' ) . "grid::unit(rep(1, $nrows), \"null\")))))";
	say {$fh} "\tgrid::grid.text(" . r_str($suptitle) . ", gp = grid::gpar(fontsize = 12), vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1:$ncols))" if $top;
	foreach my $i ( 0 .. $#panels ) {
		my ( $row, $col ) = ( int( $i / $ncols ) + 1 + $top, $i % $ncols + 1 );
		say {$fh} "\tprint(p$i, vp = grid::viewport(layout.pos.row = $row, layout.pos.col = $col))";
	}
	say {$fh} "\tinvisible(grDevices::dev.off())";
	print {$fh} creator_code( $args->{output_file}, $sub ) if lc( ( $args->{output_file} =~ m/\.([^.\/\\]+)\z/ )[0] // '' ) eq 'svg';
	say {$fh} '})';
	if ( $args->{execute} ) {
		$fh->flush;
		run_script( [ program_from_env('MATPLOTLIB_SIMPLE_RSCRIPT') // 'Rscript', $fh->filename ] );
	}
	say 'will write ' . "\e[36;103m$args->{output_file}\e[0m";
	return $fh->filename;
}
1;
