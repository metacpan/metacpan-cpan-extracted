# ABSTRACT: Plots from Perl data structures, drawn by matplotlib, gnuplot or ggplot2, with one interface for every plot type
use strict;
use feature 'say';
use warnings FATAL => 'all';

package Matplotlib::Simple;
# The front end: plt and its wrappers take the caller's arguments, fold "p"
# and "df" into plots, and check every one of them, and then hand the figure
# to the engine that draws it -- Matplotlib::Simple::Matplotlib unless "engine" names
# another (%engine_module). Until 0.33 Matplotlib::Simple drew with matplotlib
# alone, so the keywords are matplotlib's names throughout, and an engine that
# has no counterpart for one refuses it by name rather than leaving it out (check_engine).
require 5.010;
our $VERSION = 0.3343;
use Scalar::Util 'looks_like_number';
use List::Util qw(max sum min);
use POSIX ();
use Cwd 'getcwd';
use File::Spec;
use File::Temp;
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';
use FindBin '$RealScript';
use Exporter 'import';
use Capture::Tiny 'capture';
our @EXPORT = qw(plt bar barh boxplot colored_table hexbin hist hist2d imshow pie plot scatter venn_proportional_area violinplot violin wide);
use Encode ();
our @EXPORT_OK = @EXPORT;

our @ax_methods = (
 'ArtistList',     'add_child_axes', 'add_collection', 'add_container',
 'add_image',      'add_line', 'add_patch', 'add_table', 'apply_aspect',
 'autoscale_view', 'axison',   'bxp', 'callbacks', 'can_pan', 'can_zoom',
 'child_axes', 'collections', 'containers', 'contains_point', 'dataLim',
 'drag_pan',   'end_pan',     'fmt_xdata',  'fmt_ydata',      'format_coord',
 'format_xdata', 'format_ydata','hexbin', 'hist', 'hist2d', 'hlines',
 'ignore_existing_data_limits', 'in_axes',    'indicate_inset',
'indicate_inset_zoom',         'inset_axes', 'invert_xaxis', 'invert_yaxis',
 'label_outer', 'legend_', 'name', 'pcolorfast', 'redraw_in_frame', 'relim',
 'reset_position',	'scatter', 'secondary_xaxis', 'secondary_yaxis', 'set_adjustable',
 'set_anchor', 'set_aspect', 'set_autoscale_on', 'set_autoscalex_on', 'set_autoscaley_on',
 'set_axes_locator', 'set_axis_off',    'set_axis_on',   'set_axisbelow',
 'set_box_aspect',   'set_fc',          'set_forward_navigation_events',
 'set_frame_on',     'set_navigate', 'set_navigate_mode',
 'set_position',     'set_prop_cycle',  'set_rasterization_zorder',
 'set_subplotspec',  'set_title',       'set_xbound', 'set_xlabel',
 'set_xlim', # ax.set_xlim(left, right), or ax.set_xlim(right = 180)
 'set_xmargin', 'set_xscale', 'set_xticklabels', 'set_xticks', 'set_ybound',
 'set_ylabel',  'set_ylim',   'set_ymargin', 'set_yscale', 'set_yticklabels',
 'set_yticks',  'sharex',     'sharey',      'spines', 'start_pan', 'tables',
 'text', 'tick_params', 'ticklabel_format', 'titleOffsetTrans', 'transAxes', 'transData', 'transLimits',
 'transScale', 'update_datalim', 'use_sticky_edges', 'viewLim', 'vlines', 'violin',
 'xaxis',      'xaxis_date',     'xaxis_inverted',   'yaxis',   'yaxis_date',
 'yaxis_inverted'
);
our @fig_methods = (
	'add_artist', 'add_axes', 'add_axobserver', 'add_callback', 'add_gridspec',
	'add_subfigure', 'add_subplot',   'align_labels', 'align_titles',
	'align_xlabels', 'align_ylabels', 'artists',	'autofmt_xdate', #'axes', # same as plt
	'bbox', 'bbox_inches', 'canvas', 'clear', 'clf', 'clipbox',
	'colorbar',  # same name as in plt, have to use on case-by-case
	'contains',           'convert_xunits', 'convert_yunits', 'delaxes', 'dpi',
	'dpi_scale_trans',    'draw', 'draw_artist', 'draw_without_rendering',
	'figbbox',            'figimage',    # 'figure', 'findobj',
	'format_cursor_data', 'frameon', 'have_units', 'images',    'is_transform_set',    # 'legend',	 legends',
	'lines',      'mouseover', 'number', 'patch', 'patches', 'pchanged', 'pick',
	'pickable',   'properties', 'remove',
	'remove_callback',    #'savefig', keeping plt instead
	'sca', 'set', 'set_agg_filter', 'set_alpha', 'set_animated', 'set_canvas',
	'set_clip_box', 'set_clip_on', 'set_clip_path', 'set_constrained_layout',
	'set_constrained_layout_pads', 'set_dpi', 'set_edgecolor', 'set_facecolor',
	'set_figheight'
	,    # default 4.8 # 'set_figure', # deprecated as of matplotlib 3.10.0
	'set_figwidth', # default 6.4
	'set_frameon',       'set_gid',       'set_in_layout', 'set_label',
	'set_layout_engine', 'set_linewidth', 'set_mouseover', 'set_path_effects',
	'set_picker', 'set_rasterized',   'set_size_inches',   'set_sketch_params',
	'set_snap',   'set_tight_layout', 'set_transform', 'set_url', 'set_visible',
	'set_zorder', # 'show', # keeping plt instead
	'stale', 'stale_callback', 'sticky_edges', 'subfigs',
	'subfigures', #	 subplot_mosaic',
	'subplotpars', #	 subplots','subplots_adjust',
	'suppressComposite', # 'suptitle', # keeping plt instead
	'supxlabel', 'supylabel', #'text',
	'texts', #'tight_layout',
	'transFigure', 'transSubfigure', 'update',
	'update_from', #'waitforbuttonpress',
	'zorder'
);
our @plt_methods = (
	'AbstractContextManager', 'Annotation', 'Arrow', 'Artist', 'AutoLocator',
	'AxLine', 'Axes', 'BackendFilter',          'Button', 'Circle', 'Colorizer',
	'ColorizingArtist', 'Colormap',     'Enum', 'ExitStack', 'Figure',
	'FigureBase',   'FigureCanvasBase', 'FigureManagerBase', 'FixedFormatter',
	'FixedLocator', 'FormatStrFormatter', 'Formatter',       'FuncFormatter',
	'GridSpec',     'IndexLocator',       'Line2D', 'LinearLocator', 'Locator',
	'LogFormatter', 'LogFormatterExponent', 'LogFormatterMathtext',
	'LogLocator', 'MaxNLocator', 'MouseButton', 'MultipleLocator', 'Normalize',
	'NullFormatter',   'NullLocator', 'PolarAxes', 'Polygon',      'Rectangle',
	'ScalarFormatter', 'Slider',      'Subplot', 'SubplotSpec', 'TYPE_CHECKING',
	'Text', 'TickHelper',   'Widget',    'acorr',  'angle_spectrum', 'annotate',
	'annotations', 'arrow', 'autoscale', 'autumn', 'axes',           'axhline',
	'axhspan',     'axis',  'axline', 'axvline', 'axvspan', 'backend_registry',
	'bar_label', 'barbs', 'bone',    'box', 'boxplot',
	'broken_barh', 'cast',      'cbook', 'cla',  'clabel'
	,    #'clf', # I don't think you'd ever do that, also redundant with fig
	'clim',      'close',   'cm',      'cohere', 'color_sequences', 'colorbar',
	'colormaps', 'connect', 'contour', 'contourf', 'cool', 'copper', 'csd',
	'cycler',              'delaxes', 'disconnect', 'draw',      'draw_all',
	'draw_if_interactive', 'ecdf',    'errorbar',   'eventplot', 'figaspect',
	'figimage',     'figlegend', 'fignum_exists',   'figtext', 'figure', 'fill',
	'fill_between', 'fill_betweenx', 'findobj',     'flag', 'functools', 'gca',
	'gcf', 'gci', 'get', 'get_backend', 'get_cmap', 'get_current_fig_manager',
	'get_figlabels', 'get_fignums', 'get_plot_commands', 'get_scale_names',
	'getp',    'ginput', 'gray', 'grid', 
	'hot',     'hsv',    'importlib', 'imread', 'imsave', 'inferno',
	'inspect', 'install_repl_displayhook', 'interactive', 'ioff', 'ion',
	'isinteractive',  'jet', 'legend', 'locator_params', 'logging', 'loglog',
	'magma',          'magnitude_spectrum', 'margins', 'matplotlib', 'matshow',
	'minorticks_off', 'minorticks_on',      'mlab',    'new_figure_manager',
	'nipy_spectral',  'np',  'overload', 'pause',  'pcolor', 'pcolormesh',
	'phase_spectrum', 'pie', 'pink',     'plasma', 'plot', 'plot_date', 'polar',
	'prism', 'psd', 'quiver', 'quiverkey', 'rc', 'rcParams', 'rcParamsDefault',
	'rcParamsOrig', 'rc_context', 'rcdefaults', 'rcsetup', 'rgrids', 'savefig',
	'sca', #'scatter', # taken by "ax"
	'sci', 'semilogx', 'semilogy', 'set_cmap',  'set_loglevel', 'setp', 'show',
	'specgram',   'spring', 'spy', 'stackplot', 'stairs',       'stem', 'step',
	'streamplot', # 'style' is plt's own keyword since 0.33; as a pyplot method it wrote plt.style(...), and plt.style is a module, so it never ran
	'subplot',    # nrows, ncols : int, default: 1
	'subplot2grid',    'subplot_mosaic', 'subplot_tool', 'subplots',
	'subplots_adjust', 'summer', 'suptitle', 'switch_backend', 'sys', 'table',
#	'text'
	, # text(x: 'float', y: 'float', s: 'str', fontdict: 'dict[str, Any] | None' = None, **kwargs) -> 'Text'
	'thetagrids',   'threading',# 'tick_params',
	'tight_layout', 'time', 'title', 'tricontour', 'tricontourf', 'tripcolor',
	'triplot',
#'twinx', 'twiny',
	'uninstall_repl_displayhook', 'violinplot',
	'viridis', 'waitforbuttonpress', 'winter', 'xcorr', 'xkcd',# 'vlines'
	'xlabel','xscale','ylabel', 'ylim', 'yscale',
#	'xlim','xticks','yticks'
);
# The names in the three lists above that are not something to call. The lists
# were read off dir() of an Axes, a Figure and pyplot, which holds attributes,
# modules and constants beside the methods, and every keyword in them is
# written into the script as a call: "dpi => 300" passed the keyword check and
# became fig.dpi(300), which python refused as "TypeError: 'float' object is
# not callable", and "rcParams => ..." as "'RcParams' object is not callable".
# Not one of them could ever have run, so each is now refused as any other
# unknown keyword is, with the keywords it resembles. Checked against
# matplotlib 3.11.2 with callable(getattr(obj, name)).
my %not_callable = (
	ax => [ qw(axison callbacks child_axes collections containers dataLim
	 fmt_xdata fmt_ydata ignore_existing_data_limits legend_ name spines tables
	 titleOffsetTrans transAxes transData transLimits transScale
	 use_sticky_edges viewLim xaxis yaxis) ],
	fig => [ qw(artists bbox bbox_inches canvas clipbox dpi dpi_scale_trans
	 figbbox frameon images lines mouseover number patch patches stale
	 sticky_edges subfigs subplotpars suppressComposite texts transFigure
	 transSubfigure zorder) ],
	plt => [ qw(TYPE_CHECKING annotations backend_registry cbook cm
	 color_sequences functools importlib inspect logging matplotlib mlab np
	 rcParams rcParamsDefault rcParamsOrig rcsetup sys threading time) ],
);
foreach my $list ( [ ax => \@ax_methods ], [ fig => \@fig_methods ], [ plt => \@plt_methods ] ) {
	my ( $object, $methods ) = @{$list};
	my %drop = map { $_ => 1 } @{ $not_callable{$object} };
	@{$methods} = grep { not $drop{$_} } @{$methods};
}

our @arg = ('add', 'cmap', 'data', 'execute', 'fh', 'ncol', 'ncols', 'nrow', 'nrows', 'p', 'plot_type',  'plots', 'plot', 'output_file', 'scale', 'scalex', 'scaley', 'show', 'twinx');
# Options of plt itself, which no helper takes. "shared_colorbar" was in @arg,
# so every plot type accepted it inside a subplot and did nothing with it;
# plt hands it only to the subplot that draws the shared colorbar, whose type
# lists it among its own options. "engine" names what draws the whole figure,
# and "style" how it looks; both are refused in a subplot by
# refuse_subplot_choices.
# "dpi" is the resolution the figure is saved at, which the matplotlib engine
# hands to savefig. Until 0.3343 it was among the Figure "methods", and wrote
# fig.dpi(300), a TypeError; and "set_dpi", the method beside it, is no way to
# say it, since savefig takes the figure's resolution as it was when the figure
# was made (matplotlib 3.11.2), so fig.set_dpi(300) left the file as it was.
my @plt_arg = ( 'dpi', 'engine', 'shared_colorbar', 'style' );
# Every keyword this module spelled with a dot up to 0.318, and what it is
# called now. The old spellings are refused, not accepted: see
# refuse_dotted_keywords.
my %undotted_keyword = (
	'col.labels'      => 'col_labels',
	'colorbar.on'     => 'colorbar_on',
	'key.order'       => 'key_order',
	'output.file'     => 'output_file',
	'plot.type'       => 'plot_type',
	'row.labels'      => 'row_labels',
	'set.options'     => 'set_options',
	'shared.colorbar' => 'shared_colorbar',
	'show.colorbar'   => 'show_colorbar',
	'show.legend'     => 'show_legend',
	'show.numbers'    => 'show_numbers',
	'twinx.args'      => 'twinx_args',
	'undef.color'     => 'undef_color',
	'xscale.hexbin'   => 'xscale_hexbin',
	'yscale.hexbin'   => 'yscale_hexbin',
);
our @cb_arg = (
'cbdrawedges', # for colarbar: Whether to draw lines at color boundaries
'cblabel',		# The label on the colorbar's long axis
'cblocation', # of the colorbar None or {'left', 'right', 'top', 'bottom'}
'cb_min',
'cb_max',
'cborientation', # None or {'vertical', 'horizontal'}
'cbpad',         # pad : float, default: 0.05 if vertical, 0.15 if horizontal; Fraction of original Axes between colorbar and new image Axes
'cb_logscale');
our %opt = (
	barplot_helper => [
	'color'
	, # :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed
	'edgecolor'	, # optional; The colors of the bar edges.
	'key_order',    # define the keys in an order (an array reference)
	'label',        # an array of labels for grouped bar plots
	'linewidth', # float or array, optional; Width of the bar edge(s). If 0, don't draw edges
	'log'	,   # bool, default: False; If *True*, set the y-axis to be log scale.
	'logscale', # equivalent to "log"
	'stacked',    # stack the groups on top of one another; default 0 = off
	'width',      # float or array, default: 0.8; The width(s) of the bars.
	'xerr', # float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)
	'yerr',    # same as xerr, but better with bar
	],
	boxplot_helper => [
	 'color', # one color for every box; "colors" is the hash of one per key
	 'colors', 'key_order',
	 'logscale', # array of "x" and/or "y"
	 'notch', # Whether to draw a notched boxplot (`True`), or a rectangular boxplot (`False`)
	 'orientation',# {'vertical', 'horizontal'}, default: 'vertical'
	 'showcaps',   # bool: Show the caps on the ends of whiskers; default "True"
	 'showfliers', #bool, default: :rc:`boxplot.showfliers`; Show the outliers beyond the caps.
	 'showmeans'   #bool, default: :rc:`boxplot.showmeans`
	],
	colored_table_helper => [@cb_arg,
		'col_labels',
		'cmap',		# the cmap used for coloring
		'colorbar_on', # only draw if colorbar is on
		'default_undefined',	# what value should undefined values be assigned to?
		'mirror',   # $data{A}{B} = $data{B}{A}
		'row_labels',	# row labels
		'shared_colorbar', # array of 0-based indices for sharing a colorbar
		'show_numbers',# show the numbers or not, by default off.  0 = "off"; "show_numbers" > 0 => "on"
		'undef_color', # what color will undefined points be
	],
	hexbin_helper => [ @cb_arg,
	  'cb_logscale',
	  'cmap',         # "gist_rainbow" by default
	  'colorbar_on',  # only draw colorbar if colorbar is on
	  'key_order',    # define the keys in an order (an array reference)
	  'marginals',  # If marginals is *True*, plot the marginal density as colormapped rectangles along the bottom of the x-axis and left of the y-axis.
	  'mincnt'
	  , # int >= 0, default: 0 If > 0, only display cells with at least *mincnt*        number of points in the cell.
		'shared_colorbar', # array of 0-based indices for sharing a colorbar
	  'vmax'
	  , #  When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'vmin'
	  , # When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'xbins',    # default 15
	  'xscale_hexbin', # 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the horizontal axis.
	  'ybins',    # default 15
	  'yscale_hexbin', # 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the vertical axis.
	],
	hist_helper => [
	  'alpha',    # default 0.5; same for all sets
	  'key_order', # the order the sets are drawn in, and so of the legend; default sorted
	  'bins'
	  , # int or sequence or str, default: :rc:`hist.bins`If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open
	  'color', # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
	  'logscale',       # array of "x" and/or "y"; a scalar is refused
	  'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
	  'show_legend'
	],
	hist2d_helper => [@cb_arg,
	  'cb_logscale',
	  'cmap',         # "gist_rainbow" by default
	  'cmax',         # All bins that has count < *cmin* or > *cmax* will not be displayed
	  'cmin',         # color min
	  'colorbar_on',  # only draw colorbar if colorbar is on
	  'density',      # density : bool, default: False
	  'key_order',    # define the keys in an order (an array reference)
	  'logscale',     # logscale, an array of axes that will get log scale
	  'shared_colorbar', # array of 0-based indices for sharing a colorbar
	  'show_colorbar',
	  'vmax'
	  , #  When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'vmin'
	  , # When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'xbins',    # default 15
	  'xmin', 'xmax', 'ymin', 'ymax',
	  'ybins',    # default 15
	],
	imshow_helper => [@cb_arg,
	  'cblabel', # colorbar label
	  'cbdrawedges', # for colorbar
	  'cblocation', # of the colorbar None or {'left', 'right', 'top', 'bottom'}
	  'cborientation', # None or {'vertical', 'horizontal'}
	  'cmap', # The Colormap instance or registered colormap name used to map scalar data to colors
	  'colorbar_on', # only draw if colorbar is on
	  'shared_colorbar', # array of 0-based indices for sharing a colorbar
	  'stringmap', # 'H' => 'Alpha helix'
	  'vmax', # float
	  'vmin', # flat
	],
	pie_helper => [
	 'autopct',    # percent wise
	 'key_order',
	 #labeldistance and pctdistance are ratios of the radius; therefore they vary between 0 for the center of the pie and 1 for the edge of the pie, and can be set to greater than 1 to place text outside the pie https://matplotlib.org/stable/gallery/pie_and_polar_charts/pie_features.html
	 'labeldistance',
	 'pctdistance',
   ],
	plot_helper => [
	 'key_order',   # an array of key strings (which are defined in data)
	 'logscale',    # an array of "x" and/or "y"
	 'show_legend', # be default on; should be 0 if off
	 'set_options',
	 'twinx_args'
	],
	venn_proportional_area_helper => [
	 'alpha',       # float, opacity of the set circles (matplotlib_venn default 0.4)
	 'key_order',   # array ref: the order (and hence the set labels) of the sets
	 'set_colors',  # array ref of colors, one per set, e.g. ['red','green']
	],
	scatter_helper => [@cb_arg,
	 'color_key',    # which of data keys is the color key
	 'cmap',         # for 3-set scatterplots; default "gist_rainbow"
	 'colorbar_on',  # only draw colorbar if colorbar is on
	 'keys', # specify the order, otherwise alphabetical #'log', # if set to > 1, the y-axis will be logarithmic # 's', # float or array-like, shape (n, ), optional. The marker size in points**2 (typographic points are 1/72 in.).
	  'logscale', # "x" and/or "y" as an aray
	 'key_order',    # the order of the sets of a hash of sets; default sorted
	 'shared_colorbar', # array of 0-based indices for sharing a colorbar
	 'show_legend',  # label each of several sets for the legend; default on, 0 or 'False' for off
	 'set_options',   # color = 'red', marker = 'v', etc.
	 'tooltips',      # text shown on hovering over each point, in an SVG only: an array for one set, a hash of arrays for several
	],
	violin_helper => [
	 'color',      # one color for every violin; "colors" is the hash of one per key
	 'colors',
	 'edgecolor',
	 'key_order',
	 'medians',
	 'logscale',   # array: "x" and/or "y"
	 'orientation',# {'vertical', 'horizontal'}, default: 'vertical'
	 'whiskers'
	],
	wide_helper => [
	  'color',		   # a hash, with each key assigned to a color "blue" or something
	  'show_legend',  # be default on; should be 0 if off
	],
);
# plot_type => the %opt key holding that type's own keywords. "plt" dispatches
# on the same pairing (%dispatch, inside plt), but the option lists are needed
# out here too, so that a keyword rejected before dispatch can still be
# reported against the list for the type the caller actually asked for.
our %opt_key_of_type = (
	bar                    => 'barplot_helper',
	barh                   => 'barplot_helper',
	boxplot                => 'boxplot_helper',
	colored_table          => 'colored_table_helper',
	hexbin                 => 'hexbin_helper',
	hist                   => 'hist_helper',
	hist2d                 => 'hist2d_helper',
	imshow                 => 'imshow_helper',
	pie                    => 'pie_helper',
	plot                   => 'plot_helper',
	scatter                => 'scatter_helper',
	venn_proportional_area => 'venn_proportional_area_helper',
	violin                 => 'violin_helper',
	violinplot             => 'violin_helper',
	wide                   => 'wide_helper',
);
my @all_opt;
my %types_of_opt;    # keyword => array of the plot types whose own list has it
foreach my $type ( sort keys %opt_key_of_type ) {
	foreach my $keyword ( @{ $opt{ $opt_key_of_type{$type} } } ) {
		push @all_opt, $keyword;
		next if grep { $_ eq $type } @{ $types_of_opt{$keyword} // [] };
		push @{ $types_of_opt{$keyword} }, $type;
	}
}
sub edit_distance {
	# Optimal string alignment distance between two strings.
	#
	# Levenshtein with one extra case: two adjacent characters swapped count
	# as one edit, not two, because "widht" for "width" and "hsit" for "hist"
	# are the commonest way to mistype a keyword and a plain Levenshtein
	# threshold tight enough to be useful misses them.
	#
	# Three rows of the matrix are kept, since the transposition case reaches
	# two rows back; that is the only difference from the usual two-row form.
	my ( $x, $y ) = @_;
	my @prev2;
	my @prev = ( 0 .. length $y );
	foreach my $i ( 1 .. length $x ) {
		my @cur = ($i);
		foreach my $j ( 1 .. length $y ) {
			my $xc   = substr( $x, $i - 1, 1 );
			my $yc   = substr( $y, $j - 1, 1 );
			my $cost = ( $xc eq $yc ) ? 0 : 1;
			$cur[$j] = min(
				$cur[ $j - 1 ] + 1,        # insertion
				$prev[$j] + 1,             # deletion
				$prev[ $j - 1 ] + $cost    # substitution, or a match
			);
			if (   ( $i > 1 )
				&& ( $j > 1 )
				&& ( $xc eq substr( $y, $j - 2, 1 ) )
				&& ( $yc eq substr( $x, $i - 2, 1 ) ) ) {
				$cur[$j] = min( $cur[$j], $prev2[ $j - 2 ] + 1 );    # transposition
			}
		}
		@prev2 = @prev;
		@prev  = @cur;
	}
	return $prev[ length $y ];
}
sub resembles {
	# Whether $keyword is a plausible reading of the mistyped $bad.
	#
	# $bad and $keyword arrive already normalised (case folded, "." and "_"
	# dropped) so that the separator slips this module invites -- "key.order"
	# for "key_order", "show.legend" for "show_legend" -- cost nothing.
	#
	# Two ways in, for two kinds of mistake. Containment catches a keyword
	# reached for by the wrong name: "xlim" for "set_xlim", "legend" for
	# "show_legend". It is capped at 6 characters of difference, because
	# without a cap "log" pulls in "LogFormatterExponent" and every other
	# method with "log" buried in it. Edit distance catches the typing slips,
	# at one edit per three characters and never fewer than one: a
	# 4-character keyword such as "xlim" admits a single edit ("ylim"), and
	# only from 6 characters is a second allowed. A flat threshold of 2
	# instead matches most of the 4-character method names against each other.
	my ( $bad, $keyword ) = @_;
	my $difference = abs( length($keyword) - length($bad) );
	if ( $difference <= 6 ) {
		return 1 if index( $keyword, $bad ) >= 0;
		return 1 if index( $bad, $keyword ) >= 0;
	}
	my $max_edits = int( length($bad) / 3 ) || 1;
	return ( edit_distance( $bad, $keyword ) <= $max_edits );
}
sub normalise_keyword {
	# Case folded with "." and "_" dropped, so that keywords are compared on
	# their letters alone. This module spells the same idea both ways in
	# different places ("cb_min" beside "cblabel"), so a caller has no way to
	# be sure which separator a keyword uses.
	my ($keyword) = @_;
	$keyword = lc $keyword;
	$keyword =~ s/[._]//g;
	return $keyword;
}
sub similar_keywords {
	# The accepted keywords that a mistyped one plausibly meant, closest
	# first. $preferred, if given, is the plot type's own keyword list: those
	# are ranked ahead of equally-close matplotlib method names, since a
	# caller writing "log" at a "hist" wants "logscale", not "loglog".
	my ( $bad, $accepted, $preferred ) = @_;
	my $norm = normalise_keyword($bad);
	return () if $norm eq '';
	my %is_preferred = map { $_ => 1 } @{ $preferred // [] };
	my ( %seen, @scored );
	foreach my $keyword ( @{$accepted} ) {
		next if $seen{$keyword}++;    # the accepted lists are concatenated, so they repeat
		next unless resembles( $norm, normalise_keyword($keyword) );
		push @scored, [ $is_preferred{$keyword} ? 0 : 1, edit_distance( $norm, normalise_keyword($keyword) ), $keyword ];
	}
	@scored = sort {
		    $a->[0] <=> $b->[0]
		 || $a->[1] <=> $b->[1]
		 || $a->[2] cmp $b->[2]
	} @scored;
	# 5, measured: take every option of every plot type in turn and ask what
	# the types that do not accept it would suggest for it (1688 cases). 82
	# of them produce more than 5 suggestions -- up to 14 -- and in every one
	# of the 82, everything past the 5th is a matplotlib method name that
	# merely shares a stem ("pcolor", "Colormap", "tripcolor" for "color"),
	# never an option of any plot type. Re-measure before raising this.
	splice @scored, 5 if scalar @scored > 5;
	return map { $_->[2] } @scored;
}
sub keywords_of_other_types {
	# The keywords that resemble the mistyped one, are not accepted here, but
	# are accepted by some other plot type. The caller looks each one up in
	# %types_of_opt to say which types those are.
	#
	# This is the mistake the module's shape invites most. "stacked" is real,
	# and so are "notch" and "bins" -- just not for the plot type in hand --
	# so a bare "isn't defined" reads like the module is wrong. Naming the
	# types that do take the keyword answers the question the caller is
	# actually asking.
	my ( $bad, $accepted ) = @_;
	my $norm = normalise_keyword($bad);
	return () if $norm eq '';
	my %is_accepted = map { $_ => 1 } @{$accepted};
	my @scored;
	foreach my $keyword ( sort keys %types_of_opt ) {
		next if $is_accepted{$keyword};
		next unless resembles( $norm, normalise_keyword($keyword) );
		push @scored, [ edit_distance( $norm, normalise_keyword($keyword) ), $keyword ];
	}
	@scored = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @scored;
	# Fewer than the cap above, because each of these costs a whole line of
	# the message, and they are drawn from the 85 keywords the plot types
	# define between them rather than the 450-odd names a plot also accepts,
	# so the ranking has much less to choose between.
	splice @scored, 4 if scalar @scored > 4;
	return map { $_->[1] } @scored;
}
sub bad_keyword_error {
	# Die naming each unrecognised keyword, with the accepted keywords it
	# resembles.
	#
	# The accepted set is not one list: "notch" is a boxplot keyword and
	# "stacked" a bar keyword, and each helper validates against its own. The
	# caller passes the list it just checked against, so the suggestions are
	# the ones that would have worked where the caller was.
	#
	# args: bad       => array ref of the unrecognised keywords
	#       accepted  => array ref of the keywords that would have been taken
	#       preferred => array ref, optional: the subset to rank first
	#       type      => the plot_type being drawn, when one is known
	#       sub       => the subroutine doing the checking, named when the
	#                    type is not known (several subplots, no one type)
	my ($args) = @_;
	my $where =
	 defined $args->{type}
	 ? "for plot_type \"$args->{type}\""
	 : "in $args->{sub}";
	my ( @lines, $any_help );
	foreach my $bad ( sort @{ $args->{bad} } ) {
		my @similar = similar_keywords( $bad, $args->{accepted}, $args->{preferred} );
		if ( scalar @similar > 0 ) {
			$any_help = 1;
			push @lines, "\"$bad\" isn't defined $where, perhaps you meant one of these defined keywords: ("
			 . join( ', ', @similar ) . ')';
		} else {
			push @lines, "\"$bad\" isn't defined $where";
		}
		foreach my $keyword ( keywords_of_other_types( $bad, $args->{accepted} ) ) {
			$any_help = 1;
			push @lines, "\t\"$keyword\" is a defined keyword, but for plot_type "
			 . join( ', ', @{ $types_of_opt{$keyword} } );
		}
	}
	# Nothing resembled anything, here or elsewhere, so the caller has been
	# given no way forward: fall back to printing the whole accepted list, as
	# this module did before it could suggest anything.
	unless ($any_help) {
		my %seen;
		my @sorted = sort grep { !$seen{$_}++ } @{ $args->{accepted} };
		p @sorted, array_max => scalar @sorted;
		say STDERR "the keywords above are the ones defined $where.";
	}
	die join( "\n", @lines );
}
sub check_plot_type {
	# Die unless "plot_type" names a type this module draws, saying which of
	# the types it resembles was probably meant.
	#
	# "plot_type" is the one argument to plt whose *value* is drawn from a
	# fixed list, so a typo in it deserves the same answer a typo in a keyword
	# gets: the suggestions come from the matcher above, run over the type
	# names instead of over a type's options. Before this, a mistyped type
	# printed the whole args hash and died "barr isn't defined" at a single
	# plot, and reached %dispatch as an undef code ref -- "Can't use an
	# undefined value as a subroutine reference" -- at a subplot.
	#
	# It is also checked before the keywords are, because an unrecognised type
	# leaves plt with no type-specific option list to check them against: the
	# check falls back to the union of every type's options, and the caller is
	# told which of their options do not exist rather than that their type
	# does not.
	#
	# args: type  => the plot_type given, which must be defined
	#       where => optional phrase saying which plot it was given for, e.g.
	#                'at subplot 2'; omitted for a single plot, which has only
	#                the one.
	my ($args) = @_;
	my $type = $args->{type};
	return if defined $opt_key_of_type{$type};
	my $where = defined $args->{where} ? " $args->{where}" : '';
	my $norm  = normalise_keyword($type);
	my @scored;
	foreach my $known ( sort keys %opt_key_of_type ) {
		next unless resembles( $norm, normalise_keyword($known) );
		push @scored, [ edit_distance( $norm, normalise_keyword($known) ), $known ];
	}
	@scored = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @scored;
	# No cap, unlike the keyword suggestions: there are 15 plot types in all,
	# so the whole list is shorter than the 5 suggestions a keyword is allowed
	# and printing all of it costs the reader nothing.
	if ( scalar @scored > 0 ) {
		die "\"$type\" isn't a defined plot_type$where, perhaps you meant one of these defined plot types: ("
		 . join( ', ', map { $_->[1] } @scored ) . ')';
	}
	die "\"$type\" isn't a defined plot_type$where; the defined plot types are: ("
	 . join( ', ', sort keys %opt_key_of_type ) . ')';
}
sub decoded_text {
	# A string as characters, for writing through the script's UTF-8 layer.
	#
	# Raw UTF-8 bytes -- a key read from a file with no decoding layer, or
	# written in a script without "use utf8" -- are decoded, or each byte of a
	# "\x{3c1}" would be written as a character of its own. A string that is
	# already characters is left alone, and so is one whose bytes are not
	# UTF-8: a native "\xb0C" is the two characters it says, and decoding it
	# regardless, as quote_text did, turned the degree sign into U+FFFD.
	my ($str) = @_;
	return $str if ( not defined $str ) || Encode::is_utf8($str) || ( $str !~ m/[\x80-\xff]/ );
	my $copy    = $str;    # decode() with FB_CROAK consumes its argument
	my $decoded = eval { Encode::decode( 'UTF-8', $copy, Encode::FB_CROAK ) };
	return defined $decoded ? $decoded : $str;
}
sub decoded_data {
	# decoded_text of every string in a structure bound for write_data, in a
	# copy. A number is passed through untouched: a regex match would mark it
	# as a string, and the JSON encoder would then write it as one.
	my ($data) = @_;
	my $ref = ref $data;
	return [ map { decoded_data($_) } @{$data} ] if $ref eq 'ARRAY';
	return { map { decoded_text($_) => decoded_data( $data->{$_} ) } keys %{$data} } if $ref eq 'HASH';
	return $data if $ref || ( not defined $data ) || looks_like_number($data);
	return decoded_text($data);
}
sub py_str {
	# Render a Perl string as a Python single-quoted string literal.
	#
	# Legend labels, colorbar labels and the like are user data (data keys,
	# group names), so a name such as "Farmer's" would otherwise close the
	# literal early and emit unparseable Python. Backslashes are doubled
	# first, which also makes a mathtext label like '$\alpha$' survive as
	# written instead of being read as a Python escape.
	my ($str) = @_;
	$str = decoded_text( $str // '' );    # data keys reach here as raw bytes as often as labels do
	$str =~ s/\\/\\\\/g;	# backslash first, or the escapes below get doubled
	$str =~ s/'/\\'/g;
	$str =~ s/\n/\\n/g;
	$str =~ s/\r/\\r/g;
	$str =~ s/\t/\\t/g;
	# Every other control character as a hex escape. A NUL went through as it
	# stood, and Python refuses the whole script for it: "source code string
	# cannot contain null bytes".
	$str =~ s/([\x00-\x08\x0b\x0c\x0e-\x1f\x7f])/sprintf( '\\x%02x', ord $1 )/ge;
	return "'$str'";
}
sub is_finite {
	# Whether a value that passed looks_like_number is neither NaN nor infinite.
	my $v = 0 + $_[0];
	return ( ( $v == $v ) && ( $v != 9**9**9 ) && ( $v != -9**9**9 ) ) ? 1 : 0;
}
sub as_double {
	# A number rounded to a C double, which numpy, R and gnuplot all compute in.
	# A perl whose NV is a long double or a __float128 (quadmath) computes more
	# precisely, so a statistic worked out here as numpy works it out came out
	# a digit or two away from numpy's on those perls, and in a different bin.
	return unpack 'd', pack 'd', $_[0];
}
sub double_literal {
	# A finite number as a literal that reads back as the same double: in 15
	# significant digits, or 17 where 15 would not. Perl stringifies a computed
	# number to 15 digits on a double perl, so 1/3 lost its last two, and on a
	# quadmath perl to 36, which no double has. Whether 15 read back is asked
	# of C's strtod, which R and gnuplot read with: perl 5.10.1 read
	# "-6.06404429188014e-15" a double away from it, and so wrote 17 digits
	# where 15 were enough.
	my $v = as_double( $_[0] );
	my $s = sprintf '%.15g', $v;
	return ( as_double( scalar POSIX::strtod($s) ) == $v ) ? $s : sprintf '%.17g', $v;
}
sub is_nan {
	# Whether a value is a number that is NaN: a missing value, for the helpers
	# that drop missing values rather than draw them.
	return 0 unless looks_like_number( $_[0] );
	my $v = 0 + $_[0];
	return ( $v != $v ) ? 1 : 0;
}
sub nonfinite_name {
	# "nan", "inf" or "-inf" for a non-finite number, as numpy's float() reads
	# them; undef for a finite one.
	return undef if is_finite( $_[0] );
	my $v = 0 + $_[0];
	return ( $v != $v ) ? 'nan' : ( $v > 0 ) ? 'inf' : '-inf';
}
sub check_numbers {
	# Die unless every value of an option is a defined number, naming the option.
	my ( $values, $what, $current_sub ) = @_;
	my @bad = grep { ( not defined ) || ( not looks_like_number($_) ) } @{$values};
	return if scalar @bad == 0;
	die "$what must be numeric for $current_sub, but was given \"" . join( '", "', map { $_ // 'undef' } @bad ) . '"';
}
sub finite_values {
	# The values of a list that are numbers and finite, for a range computed in
	# Perl: min() and max() over a NaN answer by the order of the list, and an
	# infinite end leaves a range that nothing can be drawn in.
	return grep { ( defined ) && looks_like_number($_) && is_finite($_) } @_;
}
sub bool_option {
	# A yes-or-no option as 1 or 0, read as Python reads a bool.
	#
	# The documentation gives these options as Python bools -- "log => 'True'"
	# -- and the code tested them for Perl truth, so "log => 'False'" turned
	# the log scale on, the string being true in Perl. "True" and "False" in
	# any case, and any number, are taken; anything else is refused, naming the
	# option, since a word such as "yes" could mean either.
	my ( $value, $option, $current_sub ) = @_;
	return 0 unless defined $value;
	if ( ref $value ) {
		die "\"$option\" is True or False (or 1 or 0) for $current_sub, not a " . ( ref $value ) . ' reference';
	}
	return 1 if $value =~ m/^\s*true\s*$/i;
	return 0 if $value =~ m/^\s*(?:false|none)?\s*$/i;    # "" and None are false in Python too
	return ( ( 0 + $value ) != 0 ) ? 1 : 0 if looks_like_number($value);
	die "\"$option\" is True or False (or 1 or 0) for $current_sub, not \"$value\"";
}
sub cb_limits {
	# "cb_min" and "cb_max" as the "vmin" and "vmax" a helper writes.
	#
	# colored_table takes the ends of its color scale as cb_min and cb_max,
	# and every other helper with a colorbar accepts them too, since they are
	# in @cb_arg -- but read vmin and vmax, where it read anything, and left
	# cb_min and cb_max unread. Each is now the other's synonym. Giving both
	# for the same end is refused, rather than one of them silently winning.
	# Each caller checks the result is a number, as it checked vmin and vmax.
	my ( $plot, $current_sub ) = @_;
	foreach my $pair ( [ 'cb_min', 'vmin' ], [ 'cb_max', 'vmax' ] ) {
		my ( $cb, $v ) = @{$pair};
		next unless defined $plot->{$cb};
		if ( defined $plot->{$v} ) {
			die "\"$cb\" and \"$v\" both set the same end of the color scale in $current_sub; give one of them";
		}
		$plot->{$v} = delete $plot->{$cb};
	}
}
sub check_key_order {
	# The keys an ordering option names, as a list, dying unless it is an array
	# of distinct keys of "data".
	#
	# Without this the missing key reaches the writer as an undef and dies as
	# "Use of uninitialized value in join or string", which names neither the
	# key that is missing nor the option that asked for it. A key named twice
	# was drawn twice, and in a venn_proportional_area, whose sets are counted
	# from "data", it put one set in place of another: "key_order => ['A','A']"
	# drew A against itself and left B out. A string died as "Can't use string
	# as an ARRAY ref", and an empty array left nothing to draw.
	#
	# args: keys   => the option's value, which should be an array ref
	#       data   => the data hash they must all be keys of
	#       option => the option they came from, e.g. "key_order"
	#       sub    => the helper doing the checking
	my ($args) = @_;
	my $keys = $args->{keys};
	if ( ref $keys ne 'ARRAY' ) {
		my $got = ref $keys ? ( ref $keys ) . ' reference' : '"' . ( $keys // 'undef' ) . '"';
		die "\"$args->{option}\" is an array of keys of \"data\" in $args->{sub}, not $got";
	}
	if ( scalar @{$keys} == 0 ) {
		die "\"$args->{option}\" is an empty array in $args->{sub}; give the keys of \"data\" in the order to draw them";
	}
	if ( grep { ( not defined ) || ( ref ) } @{$keys} ) {
		die "\"$args->{option}\" holds something that is not a key of \"data\" in $args->{sub}";
	}
	my %n_named;
	my @twice = grep { $n_named{$_}++ == 1 } @{$keys};
	if ( scalar @twice > 0 ) {
		die "\"$args->{option}\" names " . join( ', ', map { "\"$_\"" } @twice ) . " more than once in $args->{sub}";
	}
	my @missing = grep { not exists $args->{data}{$_} } @{$keys};
	if ( scalar @missing > 0 ) {
		p @missing;
		die "the above keys are named in \"$args->{option}\" but are not keys of \"data\" in $args->{sub}";
	}
	return @{$keys};
}
sub logscale_axes {
	# The axes a "logscale" option asks for, refusing anything that is not an
	# axis name.
	#
	# The check this replaces was m/^([^xy])$/, which only ever saw one
	# character: "xy" and "" both passed it and emitted ax.set_xyscale("log")
	# and ax.set_scale("log"), neither of which matplotlib has. A scalar
	# "logscale => 'y'" died inside the dereference, as
	# "Can't use string ("y") as an ARRAY ref".
	#
	# "bar"/"barh" are not callers: their "logscale" is the scalar synonym for
	# "log", documented as such.
	my ( $logscale, $current_sub ) = @_;
	return () unless defined $logscale;
	if ( ref $logscale ne 'ARRAY' ) {
		my $got = ref $logscale ? ( ref $logscale ) . ' reference' : "\"$logscale\"";
		die "\"logscale\" must be an array of axis names, e.g. [ 'y' ], but $current_sub was given $got";
	}
	my @bad = grep { ( not defined $_ ) || ( $_ !~ m/^[xy]$/ ) } @{$logscale};
	if ( scalar @bad > 0 ) {
		p $logscale;
		die 'only "x" and "y" are allowed in "logscale" for ' . $current_sub
		 . ', not "' . join( '", "', map { $_ // 'undef' } @bad ) . '"';
	}
	return @{$logscale};
}
sub table_cells {
	# The keys of a colored_table's rows and columns, in the order drawn, and
	# its cells, as ( \@row_keys, \@cols, \%data ). colored_table_helper draws
	# these, and shared_table_range scales the colors of several tables by
	# them, so that a cell "col_labels" leaves out of a table is left out of
	# the scale it shares as well.
	my ( $plot, $current_sub ) = @_;
	my $mirror = bool_option( $plot->{mirror}, 'mirror', $current_sub );
	# The rows and the columns. "data" is documented as outer key = row and
	# inner key = column, but both were taken from the outer keys, so a column
	# that was only ever an inner key was dropped: of
	# { H => { H => 432, Cl => 427 }, C => { H => 413, Cl => 339 } } the table
	# drew columns C and H, lost every Cl value and left the C column empty.
	# "col_labels" still selects the rows and the columns together, as
	# documented, and "mirror", which reflects the table, makes it square.
	my %inner;
	foreach my $k1 ( keys %{ $plot->{data} } ) {
		my $ref = ref $plot->{data}{$k1};
		if ( $ref ne 'HASH' ) {
			die "$current_sub takes a hash of hashes, but row \"$k1\" of \"data\" is " . ( $ref ? "a $ref reference" : 'a scalar' );
		}
		$inner{$_} = 1 foreach keys %{ $plot->{data}{$k1} };
	}
	my %every_key = ( %inner, map { $_ => 1 } keys %{ $plot->{data} } );
	my ( @row_keys, @cols, %data );
	if (defined $plot->{col_labels}) {
		@cols = check_key_order({
			keys   => $plot->{col_labels},
			data   => \%every_key,
			option => 'col_labels',
			sub    => $current_sub
		});
		@row_keys = @cols;
	} elsif ( $mirror ) {
		@row_keys = sort keys %every_key;
		@cols     = @row_keys;
	} else {
		@row_keys = sort keys %{ $plot->{data} };
		@cols     = sort keys %inner;
	}
	foreach my $k1 ( keys %{ $plot->{data} } ) {
		foreach my $k2 ( keys %{ $plot->{data}{$k1} } ) {
			$data{$k1}{$k2} = $plot->{data}{$k1}{$k2};
		}
	}
	# A reflection fills only the cells the caller left empty. It used to
	# overwrite, so where both $data{A}{B} and $data{B}{A} were given, which
	# one the table showed depended on hash order.
	if ( $mirror ) {
		foreach my $k1 ( keys %{ $plot->{data} } ) {
			foreach my $k2 ( keys %{ $plot->{data}{$k1} } ) {
				$data{$k2}{$k1} = $plot->{data}{$k1}{$k2} unless defined $data{$k2}{$k1};
			}
		}
	}
	return ( \@row_keys, \@cols, \%data );
}
sub bin_counts {
	# "xbins" and "ybins" for hexbin and hist2d, each a whole number of at
	# least 1, set to its default of 15 where not given.
	#
	# Only 0 was refused. A negative count reached numpy, which refused it as
	# "'minlength' must not be negative", and a word died at int() as
	# 'Argument "ten" isn't numeric'.
	my ( $plot, $current_sub ) = @_;
	foreach my $bins ( 'xbins', 'ybins' ) {
		$plot->{$bins} = $plot->{$bins} // 15;
		my $n = $plot->{$bins};
		if ( ( ref $n ) || ( not looks_like_number($n) ) || ( not is_finite($n) ) || ( int($n) < 1 ) ) {
			die "\"$bins\" must be a whole number of at least 1 for $current_sub, not \"$n\"";
		}
		$plot->{$bins} = int $n;
	}
}
sub linspace {
	# numpy.linspace(start, stop, num): num points from start to stop, each
	# i * step + start and the last exactly stop, as numpy 2.5.2's
	# function_base.linspace makes them; for an engine to bin or sample
	# where numpy does. Written as start + (stop - start) * i / n, the points
	# rounded differently: a value on an edge fell into the next bin, and the
	# last edge could come out below stop, so that the maximum was in no bin.
	my ( $start, $stop, $num ) = map { as_double($_) } @_;
	return ($start) if $num == 1;
	# Each step is rounded to a double, as numpy's are; see as_double.
	my $step = as_double( as_double( $stop - $start ) / ( $num - 1 ) );
	return ( ( map { as_double( as_double( $_ * $step ) + $start ) } 0 .. $num - 2 ), $stop );
}
sub logspace {
	# numpy.logspace(np.log10(lo), np.log10(hi), num), as the matplotlib engine
	# writes a hist2d's edges on a log axis: 10 to the power of each point of
	# linspace, so that, unlike linspace, the last need not be exactly hi.
	my ( $lo, $hi, $num ) = @_;
	return map { as_double( 10**$_ ) } linspace( POSIX::log10($lo), POSIX::log10($hi), $num );
}
sub check_twinx_args {
	# Die naming any keyword of a "twinx_args" hash that no axes, figure or
	# pyplot method answers to. plot_args checks its own arguments, not the
	# hash it is handed to write out, so a typo such as "ylable" was dropped
	# without a word.
	my ( $twinx_args, $current_sub ) = @_;
	my @accepted = ( @ax_methods, @fig_methods, @plt_methods );
	my %accepted = map { $_ => 1 } @accepted;
	foreach my $set ( sort keys %{$twinx_args} ) {
		my $ref = ref $twinx_args->{$set};
		if ( $ref ne 'HASH' ) {
			die "\"twinx_args\" for \"$set\" must be a hash of axes options, but " . ( $ref ? "a $ref reference" : 'a scalar' ) . ' was entered';
		}
		my @bad = grep { not $accepted{$_} } keys %{ $twinx_args->{$set} };
		next if scalar @bad == 0;
		bad_keyword_error({
			bad      => \@bad,
			accepted => \@accepted,
			sub      => "$current_sub \"twinx_args\" for \"$set\""
		});
	}
}
sub check_scatter_values {
	# Die unless every value of one scatter axis is a defined number.
	#
	# Only undefined values were refused before, and only for x and y: a
	# string in any axis, or anything at all in the color axis, was written
	# into the script as it stands and died there as a python NameError.
	my ( $values, $what, $current_sub ) = @_;
	if ( ref $values ne 'ARRAY' ) {
		my $got = ref $values ? ( ref $values ) . ' reference' : 'a scalar';
		die "$current_sub: $what must be an array of numbers, not $got";
	}
	my @bad = grep { not looks_like_number( $values->[$_] ) } 0 .. $#{$values};
	return if scalar @bad == 0;
	p @bad;
	die "$what is undefined or not a number at the above indices in $current_sub";
}
sub check_scatter_lengths {
	# Die unless the axes of one scatter set -- x, y and the color key, if any
	# -- hold the same number of values, as the documentation requires.
	# matplotlib refused a mismatch as "x and y must be the same size", which
	# named neither the keys nor the set. An axis that is not an array is left
	# for check_scatter_values to refuse.
	my ( $set, $keys, $where, $current_sub ) = @_;
	my @arrays = grep { ref $set->{$_} eq 'ARRAY' } @{$keys};
	my %lengths = map { scalar @{ $set->{$_} } => 1 } @arrays;
	return if scalar keys %lengths <= 1;
	die "$current_sub: the axes$where must all have the same number of values, but "
	 . join( ', ', map { "\"$_\" has " . scalar @{ $set->{$_} } } @arrays );
}
sub check_wide_runs {
	# Validate one group's runs for "wide", naming the offending run.
	#
	# A group is an ARRAY of [ \@x, \@y ] pairs. Getting that shape wrong --
	# passing "plot"'s single [ \@x, \@y ] pair, say -- otherwise dies deep
	# inside the writer with "Can't use string ("0") as an ARRAY ref", which
	# says nothing about which group was malformed.
	my ( $runs, $where, $current_sub ) = @_;
	if ( ref $runs ne 'ARRAY' ) {
		my $got = ref $runs ? ( ref $runs ) . ' reference' : 'a scalar';
		die "$current_sub: $where must be an ARRAY of [ \\\@x, \\\@y ] pairs, not $got";
	}
	if ( scalar @{$runs} == 0 ) {
		die "$current_sub: $where holds no runs";
	}
	foreach my $i ( 0 .. $#{$runs} ) {
		my $run = $runs->[$i];
		unless (( ref $run eq 'ARRAY' )
			&& ( scalar @{$run} == 2 )
			&& ( ref $run->[0] eq 'ARRAY' )
			&& ( ref $run->[1] eq 'ARRAY' ) ) {
			die "$current_sub: run $i of $where must be [ \\\@x, \\\@y ]; a group is an ARRAY of such pairs, so a lone pair needs one more ARRAY around it";
		}
		my $n_x = scalar @{ $run->[0] };
		my $n_y = scalar @{ $run->[1] };
		if ( $n_x != $n_y ) {
			die "$current_sub: run $i of $where has $n_x x values but $n_y y values";
		}
		if ( $n_x == 0 ) {
			die "$current_sub: run $i of $where is empty";
		}
		foreach my $axis ( 0, 1 ) {    # 0 = x, 1 = y
			my @bad = grep { !looks_like_number($_) } @{ $run->[$axis] };
			next if scalar @bad == 0;
			my $name = $axis == 0 ? 'x' : 'y';
			# only the first few, so a wholly non-numeric run does not print itself
			my $shown = join '", "', @bad[ 0 .. min( $#bad, 4 ) ];
			die "$current_sub: run $i of $where has non-numeric $name value(s): \"$shown\"";
		}
		# looks_like_number takes "inf" and "nan". An infinite x was written into
		# np.linspace as a bare name, a NameError; a NaN x sorts last and is
		# interpolated across as though it were a point. An infinite y has no
		# mean. A NaN y is a gap, which the mean below already steps around.
		my @nonfinite_x = grep { not is_finite($_) } @{ $run->[0] };
		my @infinite_y  = grep { ( not is_finite($_) ) && ( not is_nan($_) ) } @{ $run->[1] };
		if ( scalar @nonfinite_x > 0 ) {
			die "$current_sub: run $i of $where has x value(s) that are not finite: \"" . join( '", "', @nonfinite_x[ 0 .. min( $#nonfinite_x, 4 ) ] ) . '"';
		}
		if ( scalar @infinite_y > 0 ) {
			die "$current_sub: run $i of $where has infinite y value(s): \"" . join( '", "', @infinite_y[ 0 .. min( $#infinite_y, 4 ) ] ) . '"';
		}
	}
}
sub normalise_p {
	# "p" is a flat list of subplots: ONE array element == ONE subplot.
	#   p => [ \%h, \%h, ... ]                 each hash is its own subplot
	#   p => [ \%h, [ \%h, \%h ], \%h, ... ]   an inner array of hashes is a
	#                                          single subplot holding several
	#                                          plots on the same axes (the 1st
	#                                          hash is the base plot, the rest
	#                                          are "add"itions/overlays)
	# The plain-hash and inner-array forms may be mixed freely in one "p".
	# Using "p" means top-level "plot_type"/"data" are not used. If no grid is
	# given, the subplots are laid out on an automatically-sized near-square
	# grid; pass nrow(s)/ncol(s) to override.
	my ( $args, $current_sub ) = @_;
	$current_sub = $current_sub // 'plt';
	my $p = delete $args->{p};
	if ( ref $p ne 'ARRAY' ) {
		die "$current_sub: \"p\" must be an ARRAY reference (one element per subplot)";
	}
	if ( scalar @{$p} == 0 ) {
		die "$current_sub: \"p\" is empty";
	}
	# "p" supersedes the older interface; forbid mixing to avoid ambiguity
	foreach my $clash ( grep { defined $args->{$_} } ( 'plot_type', 'data', 'plots', 'add' ) ) {
		die "$current_sub: \"$clash\" cannot be combined with \"p\"";
	}
	my @plots;
	my $i = 0;
	foreach my $subplot ( @{$p} ) {
		my $ref = ref $subplot;
		if ( $ref eq 'HASH' ) {                       # one subplot, one plot
			push @plots, { %{$subplot} };             # shallow copy; don't mutate caller
		} elsif ( $ref eq 'ARRAY' ) {                 # one subplot, several overlaid plots
			if ( scalar @{$subplot} == 0 ) {
				die "$current_sub: subplot $i in \"p\" is an empty array";
			}
			my @g    = @{$subplot};
			my $main = shift @g;                      # 1st hash is the base plot
			foreach my $plot ( $main, @g ) {
				if ( ref $plot ne 'HASH' ) {
					die "$current_sub: subplot $i in \"p\": every plot must be a HASH reference";
				}
			}
			my %plot = %{$main};                      # shallow copy of the base plot
			# the rest overlay on the same axes. A new array, not a push: the
			# copy above shares the base plot's own "add" array with the caller.
			$plot{add} = [ @{ $plot{add} // [] }, @g ] if scalar @g;
			push @plots, \%plot;
		} else {
			die "$current_sub: subplot $i in \"p\" must be a HASH reference (one plot) or an ARRAY of HASH references (overlaid plots), not a \"$ref\" reference";
		}
		$i++;
	}
	$args->{plots} = \@plots;
	# convenience: choose a subplot grid. With neither dimension given, use a
	# near-square grid; with exactly one given (and positive), derive the other
	# so e.g. "ncols => 1" stacks the subplots in a single column. Empty
	# trailing cells are pruned later by the engine.
	my $n     = scalar @plots;
	my $ncols = $args->{ncols} // $args->{ncol};
	my $nrows = $args->{nrows} // $args->{nrow};
	if ( ( not defined $ncols ) && ( not defined $nrows ) ) {
		$ncols = 1;
		$ncols++ while ( $ncols * $ncols ) < $n;             # ceil(sqrt $n), no floats
		$args->{ncols} = $ncols;
		$args->{nrows} = int( ( $n + $ncols - 1 ) / $ncols );  # ceil($n / $ncols)
	} elsif ( ( not defined $ncols ) && ( $nrows > 0 ) ) {   # only rows given
		$args->{ncols} = int( ( $n + $nrows - 1 ) / $nrows );
	} elsif ( ( not defined $nrows ) && ( $ncols > 0 ) ) {   # only cols given
		$args->{nrows} = int( ( $n + $ncols - 1 ) / $ncols );
	}
	return $args;
}
sub copy_plot_hashes {
	# A copy of plt's arguments, deep enough that nothing plt does is seen by
	# the caller.
	#
	# plt and its helpers write into the hashes they are given: "add" is
	# deleted once drawn, "title" is renamed "set_title", a subplot is told
	# whether to draw its colorbar, and array "data" is rewrapped as a hash.
	# Under plt({ ... }) those were the caller's own hashes, so the same hash
	# drawn twice lost its overlays the second time. The hashes are copied,
	# at every level plt writes to -- the top, each subplot, each "add" graph --
	# and the data inside them is not: it is only read, and can be large.
	# Anything of the wrong shape is passed through as it is, for the checks
	# in plt to refuse by name.
	#
	# "p" is copied too, subplot by subplot and overlay by overlay. It was not,
	# and normalise_p copies only the subplot hashes it builds, so an overlay
	# drawn through "p" -- the 2nd hash of an inner array, or an "add" graph --
	# was the caller's own: a hist overlay came back with its array "data"
	# rewrapped as { A => [...] } and a "plot_type" it had not been given.
	my ($args) = @_;
	my $copy_plot = sub {
		my ($plot) = @_;
		return $plot unless ref $plot eq 'HASH';
		$plot = { %{$plot} };
		if ( ref $plot->{add} eq 'ARRAY' ) {
			$plot->{add} = [ map { ref $_ eq 'HASH' ? { %{$_} } : $_ } @{ $plot->{add} } ];
		}
		return $plot;
	};
	my $copy = $copy_plot->($args);
	if ( ref $copy->{plots} eq 'ARRAY' ) {
		$copy->{plots} = [ map { $copy_plot->($_) } @{ $copy->{plots} } ];
	}
	if ( ref $copy->{p} eq 'ARRAY' ) {
		$copy->{p} = [
			map { ref $_ eq 'ARRAY' ? [ map { $copy_plot->($_) } @{$_} ] : $copy_plot->($_) } @{ $copy->{p} }
		];
	}
	return $copy;
}
sub refuse_dotted_keywords {
	# Die naming every keyword given in its pre-0.319 dotted spelling, where
	# it was given, and what it is called now.
	#
	# Most of them would be refused anyway, with the new name among the
	# suggestions, since similar_keywords ignores separators. "plot.type" and
	# "output.file" would not: plt looks for "plot_type" and "output_file"
	# before it checks any keyword, so a script written for 0.318 died with
	# "either "show" or "output_file" must be defined", which never mentions
	# the key the caller actually wrote. This runs first, so that every old
	# script fails the same way. It visits the levels copy_plot_hashes copies.
	my ( $args, $current_sub ) = @_;
	my @found;    # "old" => "new" at <where>, one per dotted key
	my $check_keys = sub {
		my ( $plot, $where ) = @_;
		return unless ref $plot eq 'HASH';
		foreach my $key ( sort grep { exists $undotted_keyword{$_} } keys %{$plot} ) {
			push @found, "\"$key\" is now \"$undotted_keyword{$key}\"$where";
		}
	};
	my $check = sub {    # a plot and its "add" graphs, which do not nest
		my ( $plot, $where ) = @_;
		$check_keys->( $plot, $where );
		return unless ( ref $plot eq 'HASH' ) && ( ref $plot->{add} eq 'ARRAY' );
		foreach my $i ( 0 .. $#{ $plot->{add} } ) {
			$check_keys->( $plot->{add}[$i], " in \"add\" graph $i$where" );
		}
	};
	$check->( $args, '' );
	if ( ref $args->{plots} eq 'ARRAY' ) {
		$check->( $args->{plots}[$_], " at subplot $_" ) foreach 0 .. $#{ $args->{plots} };
	}
	if ( ref $args->{p} eq 'ARRAY' ) {
		foreach my $i ( 0 .. $#{ $args->{p} } ) {
			my $entry = $args->{p}[$i];
			my @graphs = ref $entry eq 'ARRAY' ? @{$entry} : ($entry);
			$check->( $_, " at \"p\" entry $i" ) foreach @graphs;
		}
	}
	return if scalar @found == 0;
	die "$current_sub: keywords are spelled with \"_\", not \".\", since 0.319: "
	 . join( '; ', @found );
}
# "df": a data frame given whole, with the columns to plot named by role, in
# place of "data" built by hand. The four shapes are those of Stats::LikeR
# (lib/Stats/LikeR.pm, _df_shape, Stats::LikeR 0.3213): an array of hashes (one
# hash per row), a hash of arrays (one array per column), a hash of hashes (row
# name => { column => value }) and an array of arrays (columns by 0-based
# position). They are recognised by their structure, so the frame can come from
# anywhere; Stats::LikeR is not loaded.
#
# frames_to_data rewrites every plot hash holding "df" into the "data" its
# plot_type already takes, before anything else in plt looks at it, so no
# helper knows that a frame was ever given.
#
# plot_type => the roles it reads columns from:
#   take => the roles it accepts
#   need => the roles it cannot be drawn without
#   many => the one role that may name several columns, as an array ref
#   rows => 1 if "x" may be left out of a hash-of-hashes frame, whose row names
#           are then the labels
#   each => 1 if each column is one distribution of its own: "many" may be left
#           out, for every column of numbers, and without "by" the columns
#           need not be the same length, since no row is read across them
my %frame_roles = (
	bar           => { take => [ 'x', 'y', 'by' ], need => ['y'],        many => 'y', rows => 1 },
	barh          => { take => [ 'x', 'y', 'by' ], need => ['y'],        many => 'y', rows => 1 },
	boxplot       => { take => [ 'y', 'by' ],      need => ['y'],        many => 'y' },
	colored_table => { take => [ 'x', 'y' ],       need => [],           many => 'y', rows => 1 },
	hexbin        => { take => [ 'x', 'y' ],       need => [ 'x', 'y' ] },
	hist          => { take => [ 'x', 'by' ],      need => [],           many => 'x', each => 1 },
	hist2d        => { take => [ 'x', 'y' ],       need => [ 'x', 'y' ] },
	pie           => { take => [ 'x', 'y' ],       need => ['y'],                     rows => 1 },
	plot          => { take => [ 'x', 'y', 'by' ], need => [ 'x', 'y' ], many => 'y' },
	scatter       => { take => [ 'x', 'y', 'by' ], need => [ 'x', 'y' ] },
	violin        => { take => [ 'y', 'by' ],      need => [],           many => 'y', each => 1 },
	violinplot    => { take => [ 'y', 'by' ],      need => [],           many => 'y', each => 1 },
);
my @frame_keys = ( 'df', 'x', 'y', 'by' );
sub frame_shape {
	# "AoA", "AoH", "HoA" or "HoH": which of the four shapes a frame is.
	my ( $df, $where ) = @_;
	my $ref = ref $df;
	if ( $ref eq 'ARRAY' ) {
		foreach my $row ( @{$df} ) {
			next unless defined $row;
			return 'AoA' if ref $row eq 'ARRAY';
			return 'AoH' if ref $row eq 'HASH';
			die "\"df\"$where is an array, so its rows must be ARRAY (AoA) or HASH (AoH) references, but one is "
			 . ( ref $row ? 'a ' . ref $row . ' reference' : "\"$row\"" );
		}
		die "\"df\"$where has no rows";
	}
	if ( $ref eq 'HASH' ) {
		die "\"df\"$where has no columns" if scalar keys %{$df} == 0;
		my %kinds = map { ( ref $_ ) => 1 } values %{$df};
		my @kinds = sort keys %kinds;
		return 'HoA' if "@kinds" eq 'ARRAY';
		return 'HoH' if "@kinds" eq 'HASH';
		die "\"df\"$where is a hash, so its values must all be ARRAY (HoA, column => values) or all HASH (HoH, row => { column => value }) references, but they are: "
		 . join( ', ', map { $_ eq '' ? 'not references' : $_ } @kinds );
	}
	die "\"df\"$where must be an ARRAY (AoA, AoH) or HASH (HoA, HoH) reference, not "
	 . ( $ref eq '' ? 'a plain value' : "a $ref reference" );
}
sub frame_column_names {
	# Every column name of a frame, sorted; for an AoA, every position.
	my ( $df, $shape ) = @_;
	return sort keys %{$df} if $shape eq 'HoA';
	if ( $shape eq 'AoA' ) {
		my $width = max( 0, map { scalar @{$_} } grep { defined } @{$df} );
		return 0 .. $width - 1;
	}
	my %seen;
	foreach my $row ( $shape eq 'HoH' ? values %{$df} : @{$df} ) {
		next unless ref $row eq 'HASH';
		$seen{$_} = 1 foreach keys %{$row};
	}
	return sort keys %seen;
}
sub frame_columns {
	# The named columns of a frame as arrays, row by row in step with one
	# another, and the row names, which only a hash of hashes has.
	#
	# A row's cells are all taken from that row in the one pass, rather than a
	# column at a time, so that x and y cannot come from different rows
	# whatever the shape. Rows run in the frame's own order; a hash of hashes
	# has none, and its rows are taken in the sorted order of their names,
	# which is the order Stats::LikeR's vals() and view() give them. A column
	# that no row has is refused by name, as Stats::LikeR refuses it.
	#
	# $ragged is true when no row is read across the columns, so that the
	# columns of a hash of arrays need not be the same length; Stats::LikeR's
	# group_by gives one column per group, each as long as its group.
	#
	# $given maps a column to the option that named it ("x", "y", "by" or
	# "color_key"), and $sub is the caller's name; both are optional, and
	# serve only to say, when a column is missing, which option named it.
	my ( $df, $shape, $columns, $where, $ragged, $given, $sub ) = @_;
	$given //= {};
	# how a missing column is introduced: 'scatter: "dG", given as "x",'
	my $named = sub {
		my ($column) = @_;
		return ( defined $sub ? "$sub: " : '' ) . "\"$column\""
		 . ( defined $given->{$column} ? ", given as \"$given->{$column}\"," : '' );
	};
	my %seen;
	my @columns = grep { not $seen{$_}++ } @{$columns};
	my ( %out, @row_names );
	my $missing = sub {
		my ($column) = @_;
		my @have  = frame_column_names( $df, $shape );
		my @close = similar_keywords( $column, \@have );
		# 20: enough to show a typical table whole, while a wide one from a
		# spreadsheet does not bury the message under hundreds of names.
		my $shown = scalar @have > 20 ? join( ', ', @have[ 0 .. 19 ] ) . ', ...' : join( ', ', @have );
		die $named->($column) . " is not a column in the dataframe \"df\"$where"
		 . ( scalar @close ? '; perhaps you meant ' . join( ' or ', map { "\"$_\"" } @close ) : '' )
		 . ". Its columns are: $shown";
	};
	if ( $shape eq 'HoA' ) {
		foreach my $column (@columns) {
			$missing->($column) unless exists $df->{$column};
			$out{$column} = $df->{$column};    # only read from here on, so not copied
		}
		my %n_rows = map { $_ => scalar @{ $df->{$_} } } @columns;
		my %lengths = map { $_ => 1 } values %n_rows;
		if ( ( not $ragged ) && ( scalar keys %lengths > 1 ) ) {
			die "the columns of \"df\"$where must all have the same number of rows, but they have "
			 . join( ', ', map { "\"$_\" $n_rows{$_}" } @columns );
		}
		return ( \%out, [] );
	}
	if ( $shape eq 'AoA' ) {
		my $width = max( 0, map { scalar @{$_} } grep { defined } @{$df} );
		my %position;
		foreach my $column (@columns) {
			if ( ( $column !~ m/^-?\d+$/ ) || ( $column >= $width ) || ( $column < -$width ) ) {
				die $named->($column) . " is not a column in the dataframe \"df\"$where, which is an array of arrays, whose columns are 0-based positions from 0 to " . ( $width - 1 )
				 . ' (or negative, from the end)';
			}
			$position{$column} = $column < 0 ? $width + $column : $column;
			$out{$column} = [];
		}
		my $i = 0;
		foreach my $row ( @{$df} ) {
			# An undefined row is a row with no values, left out by the caller's
			# plot like any other row missing one. frame_shape and
			# frame_column_names already stepped over it, and this died on it.
			if ( not defined $row ) {
				push @{ $out{$_} }, undef foreach @columns;
				$i++;
				next;
			}
			die "row $i of \"df\"$where is not an ARRAY reference" unless ref $row eq 'ARRAY';
			push @{ $out{$_} }, $row->[ $position{$_} ] foreach @columns;
			$i++;
		}
		return ( \%out, [] );
	}
	my @rows;
	if ( $shape eq 'HoH' ) {
		@row_names = sort keys %{$df};
		@rows      = @{$df}{@row_names};
	} else {
		@rows = @{$df};
	}
	my %found;
	foreach my $i ( 0 .. $#rows ) {
		if ( ( $shape eq 'AoH' ) && ( not defined $rows[$i] ) ) {    # as for an array of arrays above
			push @{ $out{$_} }, undef foreach @columns;
			next;
		}
		if ( ref $rows[$i] ne 'HASH' ) {
			die 'row ' . ( $shape eq 'HoH' ? "\"$row_names[$i]\"" : $i ) . " of \"df\"$where is not a HASH reference";
		}
		foreach my $column (@columns) {
			$found{$column} = 1 if exists $rows[$i]{$column};
			push @{ $out{$column} }, $rows[$i]{$column};
		}
	}
	foreach my $column (@columns) {
		$missing->($column) unless $found{$column};
	}
	return ( \%out, \@row_names );
}
sub complete_rows {
	# The indices of the rows that have a value in every one of the columns.
	my ( $cells, $columns ) = @_;
	my $n = scalar @{ $cells->{ $columns->[0] } };
	return grep {
		my $i = $_;
		not grep { not defined $cells->{$_}[$i] } @{$columns}
	} 0 .. $n - 1;
}
sub check_dropped {
	# Say how many rows were left out for want of a value, as ggplot2's
	# "Removed 3 rows containing missing values" does: a missing value cannot
	# be drawn, and refusing every frame with one in it would refuse most real
	# data, but rows leaving a plot without a word would be worse.
	#
	# Die if that was every row. Only plot without "by", and scatter, hexbin
	# and hist2d, checked for themselves, and scatter's message left out the
	# "by" column; the rest made an empty "data" and died as '"data" is an
	# empty hash', about an option the caller had never given.
	my ( $n_kept, $n, $columns, $where, $sub ) = @_;
	if ( $n_kept == 0 ) {
		my @names = map { "\"$_\"" } @{$columns};
		die "$sub: no row of \"df\"$where has a value in "
		 . ( scalar @names == 1 ? $names[0] : scalar @names == 2 ? "both $names[0] and $names[1]" : 'every one of ' . join( ', ', @names ) );
	}
	return if $n_kept == $n;
	warn "$sub: left out " . ( $n - $n_kept ) . " of $n rows of \"df\"$where, which have no value in "
	 . join( ' or ', map { "\"$_\"" } @{$columns} ) . "\n";
}
sub group_order {
	# The distinct values of a grouping column, in numeric order when every
	# one is a number and in string order otherwise: 2 before 10, as a reader
	# expects, where the sorted order of keys would put 10 first.
	my @values = @_;
	my %seen;
	my @groups = grep { not $seen{$_}++ } @values;
	return ( grep { not looks_like_number($_) } @groups )
	 ? sort @groups
	 : sort { $a <=> $b } @groups;
}
sub first_seen {
	# The distinct values of a column, in the order of the rows they first
	# appear in.
	my %seen;
	return grep { not $seen{$_}++ } @_;
}
sub frame_to_data {
	# Rewrite one plot hash holding "df" into the "data" its plot_type takes,
	# deleting "df", "x", "y" and "by", and filling in the options that say
	# what the columns were: "key_order" or "keys", so that x is drawn on the
	# x axis rather than wherever the sorted names put it, and the axis
	# labels, which the caller's own still override.
	#
	# The plot hash is plt's own copy, made by copy_plot_hashes, so writing to
	# it leaves the caller's as it was. The frame is only read.
	my ( $plot, $type, $where, $sub ) = @_;
	if ( not exists $plot->{df} ) {
		my @stray = grep { exists $plot->{$_} } ( 'x', 'y', 'by' );
		return unless scalar @stray;
		die "$sub: " . join( ', ', map { "\"$_\"" } @stray ) . "$where name" . ( scalar @stray == 1 ? 's' : '' )
		 . ' columns of "df", but no "df" was given';
	}
	die "$sub: \"df\"$where is undefined" unless defined $plot->{df};
	die "$sub: \"df\" and \"data\" cannot both be given$where; \"df\" is turned into \"data\"" if exists $plot->{data};
	die "$sub: \"df\"$where needs a \"plot_type\" to say how its columns are drawn" unless defined $type;
	check_plot_type({ type => $type, where => ( $where eq '' ? undef : substr( $where, 1 ) ) });
	my $roles = $frame_roles{$type};
	if ( not defined $roles ) {
		die "$sub: plot_type \"$type\"$where does not take \"df\"; give it \"data\". The plot types that take \"df\" are: "
		 . join( ', ', sort keys %frame_roles );
	}
	my %takes = map { $_ => 1 } @{ $roles->{take} };
	my @refused = grep { ( exists $plot->{$_} ) && ( not $takes{$_} ) } ( 'x', 'y', 'by' );
	if ( scalar @refused ) {
		die "$sub: plot_type \"$type\"$where takes its columns of \"df\" in "
		 . join( ' and ', map { "\"$_\"" } @{ $roles->{take} } ) . ', not in ' . join( ' or ', map { "\"$_\"" } @refused );
	}
	my $df    = $plot->{df};
	my $shape = frame_shape( $df, $where );
	my @need  = @{ $roles->{need} };
	push @need, 'x' if ( $takes{x} ) && ( $roles->{rows} ) && ( $shape ne 'HoH' );
	push @need, $roles->{many} if ( $roles->{each} ) && ( defined $plot->{by} );    # the one column "by" splits
	my @absent = grep { not defined $plot->{$_} } @need;
	if ( scalar @absent ) {
		die "$sub: plot_type \"$type\"$where needs " . join( ' and ', map { "\"$_\"" } @absent ) . ' to name '
		 . ( scalar @absent == 1 ? 'a column' : 'columns' ) . ' of "df"'
		 . ( ( grep { $_ eq 'x' } @absent ) && ( $roles->{rows} ) ? '; only a hash of hashes has row names to label it by instead' : '' );
	}
	# Each role as a list of column names; only $roles->{many} may hold more than one.
	my %col;
	foreach my $role ( 'x', 'y', 'by' ) {
		next unless defined $plot->{$role};
		my $value = $plot->{$role};
		my @names = ref $value eq 'ARRAY' ? @{$value} : ($value);
		if ( ( ref $value ne '' ) && ( ref $value ne 'ARRAY' ) ) {
			die "$sub: \"$role\"$where names a column of \"df\", or for \"" . ( $roles->{many} // $role ) . '" an array of them, not a ' . ref($value) . ' reference';
		}
		die "$sub: \"$role\"$where is an empty array" if scalar @names == 0;
		my @bad = grep { ( not defined $_ ) || ( ref $_ ) } @names;
		die "$sub: \"$role\"$where holds something that is not a column name" if scalar @bad;
		if ( ( scalar @names > 1 ) && ( ( $roles->{many} // '' ) ne $role ) ) {
			die "$sub: \"$role\"$where can name only one column for plot_type \"$type\""
			 . ( defined $roles->{many} ? "; \"$roles->{many}\" is the one that takes several" : '' );
		}
		$col{$role} = \@names;
	}
	my $many = $roles->{many} // '';
	if ( ( defined $col{by} ) && ( defined $col{$many} ) && ( scalar @{ $col{$many} } > 1 ) ) {
		die "$sub: \"by\"$where splits one column into groups, so \"$many\" can name only one column when \"by\" is given";
	}
	my $color_key = ( $type eq 'scatter' ) ? $plot->{color_key} : undef;    # a column too, for scatter
	if ( ( defined $color_key ) && ( ref $color_key ) ) {
		die "$sub: \"color_key\"$where names one column of \"df\"";
	}
	my @used = ( map { @{ $col{$_} // [] } } ( 'x', 'y', 'by' ) );
	push @used, $color_key if defined $color_key;
	my %n_named;
	my @twice = grep { $n_named{$_}++ == 1 } @used;
	if ( scalar @twice ) {
		# The columns become the keys of "data", so one named twice would be
		# drawn against itself, or silently once.
		die "$sub: " . join( ', ', map { "\"$_\"" } @twice ) . "$where is named more than once among the columns of \"df\" to plot";
	}
	foreach my $option ( grep { exists $plot->{$_} } ( 'keys', ( $type =~ m/^(?:hexbin|hist2d)$/ ? 'key_order' : () ) ) ) {
		die "$sub: \"$option\"$where cannot be given with \"df\": \"x\" and \"y\" already say which column goes on which axis";
	}
	my @default_y;
	if ( ( $type eq 'colored_table' ) && ( not defined $col{y} ) ) {
		my %is_x = map { $_ => 1 } @{ $col{x} // [] };
		@default_y = grep { not $is_x{$_} } frame_column_names( $df, $shape );
		$col{y} = \@default_y;
		@used = ( @{ $col{x} // [] }, @default_y );
	}
	my $every_column = ( $roles->{each} ) && ( not defined $col{$many} );
	@used = frame_column_names( $df, $shape ) if $every_column;
	my %given;
	foreach my $role ( 'x', 'y', 'by' ) {
		$given{$_} = $role foreach @{ $col{$role} // [] };
	}
	$given{$color_key} = 'color_key' if defined $color_key;
	my ( $cells, $row_names ) = frame_columns( $df, $shape, \@used, $where, $roles->{each} && ( not defined $col{by} ), \%given, $sub );
	# the longest column, as the columns of "each" need not be the same length
	my $n_rows = scalar( @{$row_names} ) || max( 0, map { scalar @{ $cells->{$_} } } @used );
	die "\"df\"$where has no rows" if $n_rows == 0;
	if ($every_column) {
		# Every column that holds numbers and nothing else, as pandas' DataFrame.hist
		# and .boxplot take every numeric column: a column of names or of
		# categories is not a distribution, and most tables have one.
		my @numeric = grep {
			my @values = grep { defined } @{ $cells->{$_} };
			( scalar @values ) && ( not grep { not looks_like_number($_) } @values );
		} @used;
		die "$sub: \"df\"$where has no column of numbers to draw" if scalar @numeric == 0;
		# in numeric order when every name is a number, as the groups of
		# group_by are, so that 4, 6 and 8 cylinders are drawn in that order
		$col{$many} = [ group_order(@numeric) ];
	}
	my ($x)  = @{ $col{x}  // [] };
	my ($by) = @{ $col{by} // [] };
	my @y    = @{ $col{y}  // [] };
	my %data;
	my $label_axis = sub {    # default an axis label to a column name; py_str because a column name is data, see hist2d_helper
		my ( $axis, $column ) = @_;
		return unless defined $column;
		return if ( defined $plot->{$axis} ) || ( defined $plot->{"set_$axis"} );
		$plot->{$axis} = py_str($column);
	};
	if ( $type =~ m/^(?:bar|barh|pie|colored_table)$/ ) {
		# The labels: column "x", or the row names of a hash of hashes.
		my $labels = defined $x ? $cells->{$x} : $row_names;
		if ( $type eq 'colored_table' ) {
			# $x is undefined for a hash of hashes labelled by its row names,
			# and the message died as "Use of uninitialized value $x".
			if ( scalar @y == 0 ) {
				die "$sub: \"df\"$where has no columns " . ( defined $x ? "but \"$x\" " : '' ) . 'to put in the table';
			}
			my %row;
			foreach my $i ( grep { defined $labels->[$_] } 0 .. $n_rows - 1 ) {
				my $label = $labels->[$i];
				die "$sub: \"$label\" appears in more than one row of \"$x\" in \"df\"$where, and colored_table has one row per label" if $row{$label};
				# An undefined cell is left out, which colored_table draws as undefined.
				$row{$label} = { map { $_ => $cells->{$_}[$i] } grep { defined $cells->{$_}[$i] } @y };
			}
			check_dropped( scalar keys %row, $n_rows, [$x], $where, $sub ) if defined $x;
			%data = %row;
		} else {
			my @value_cols = ( @y, ( defined $by ? $by : () ) );
			my @kept = grep { defined $labels->[$_] } complete_rows( $cells, \@value_cols );
			check_dropped( scalar @kept, $n_rows, [ ( defined $x ? $x : () ), @value_cols ], $where, $sub );
			my @labels = map { $labels->[$_] } @kept;
			my $what   = $type eq 'pie' ? 'wedge' : 'bar';
			if ( defined $by ) {
				# A pivot: one series per group, one bar per label in each.
				my @groups = group_order( map { $cells->{$by}[$_] } @kept );
				my %cell;
				foreach my $i (@kept) {
					my ( $label, $group ) = ( $labels->[$i], $cells->{$by}[$i] );
					if ( exists $cell{$label}{$group} ) {
						die "$sub: more than one row of \"df\"$where has \"$x\" = \"$label\" and \"$by\" = \"$group\", and a grouped $type draws one bar for each pair: aggregate the rows first, e.g. with Stats::LikeR's agg or pivot_table";
					}
					$cell{$label}{$group} = $cells->{ $y[0] }[$i];
				}
				my @labels_once = first_seen(@labels);
				my @gaps;
				foreach my $label (@labels_once) {
					push @gaps, map { "\"$label\"/\"$_\"" } grep { not exists $cell{$label}{$_} } @groups;
					$data{$label} = [ map { $cell{$label}{$_} } @groups ];
				}
				if ( scalar @gaps ) {
					splice @gaps, 5, scalar(@gaps) - 5, '...' if scalar @gaps > 5;    # enough to see the pattern
					die "$sub: no row of \"df\"$where has a value for " . join( ', ', @gaps )
					 . ' (' . ( defined $x ? "\"$x\"" : 'row name' ) . "/\"$by\"), and a grouped $type needs one for every pair";
				}
				$plot->{label} = $plot->{label} // [@groups];
				if ( ref $plot->{color} eq 'HASH' ) {
					# The series are the groups, so a color keyed by group can be put in their order here.
					my @uncolored = grep { not defined $plot->{color}{$_} } @groups;
					die "$sub: \"color\"$where has no color for the groups " . join( ', ', map { "\"$_\"" } @uncolored ) if scalar @uncolored;
					$plot->{color} = [ @{ $plot->{color} }{@groups} ];
				}
			} else {
				my %row_of;
				foreach my $i (@kept) {
					my $label = $labels->[$i];
					if ( exists $row_of{$label} ) {
						die "$sub: \"$label\" appears in more than one row of \"$x\" in \"df\"$where, and $type draws one $what per label: aggregate the rows first, e.g. with Stats::LikeR's agg";
					}
					$row_of{$label} = $i;
					$data{$label} = scalar @y == 1 ? $cells->{ $y[0] }[$i] : [ map { $cells->{$_}[$i] } @y ];
				}
				if ( scalar @y > 1 ) {
					$plot->{label} = $plot->{label} // [@y];
					if ( ref $plot->{color} eq 'HASH' ) {
						my @uncolored = grep { not defined $plot->{color}{$_} } @y;
						die "$sub: \"color\"$where has no color for the columns " . join( ', ', map { "\"$_\"" } @uncolored ) if scalar @uncolored;
						$plot->{color} = [ @{ $plot->{color} }{@y} ];
					}
				}
			}
			# The rows of a table are in an order of their own, which the
			# sorted labels would lose.
			$plot->{key_order} = $plot->{key_order} // [ first_seen(@labels) ];
			if ( $type ne 'pie' ) {
				my ( $label_axis_name, $value_axis_name ) = $type eq 'barh' ? ( 'ylabel', 'xlabel' ) : ( 'xlabel', 'ylabel' );
				$label_axis->( $label_axis_name, $x );
				$label_axis->( $value_axis_name, scalar @y == 1 ? $y[0] : undef );
			}
		}
	} elsif ( $type =~ m/^(?:hist|boxplot|violin|violinplot)$/ ) {
		# One distribution per column, or one per group of a single column.
		my @value_cols = $type eq 'hist' ? @{ $col{x} } : @y;
		if ( defined $by ) {
			my $column = $value_cols[0];
			my @kept = complete_rows( $cells, [ $column, $by ] );
			check_dropped( scalar @kept, $n_rows, [ $column, $by ], $where, $sub );
			push @{ $data{ $cells->{$by}[$_] } }, $cells->{$column}[$_] foreach @kept;
			$plot->{key_order} = $plot->{key_order} // [ group_order( keys %data ) ];
		} else {
			# Column by column: a value missing from one column says nothing about the others.
			foreach my $column (@value_cols) {
				$data{$column} = [ grep { defined } @{ $cells->{$column} } ];
				check_dropped( scalar @{ $data{$column} }, scalar @{ $cells->{$column} }, [$column], $where, $sub );
			}
			$plot->{key_order} = $plot->{key_order} // [@value_cols];
		}
		my $values = scalar @value_cols == 1 ? $value_cols[0] : undef;
		if ( $type eq 'hist' ) {
			$label_axis->( ( $plot->{orientation} // '' ) eq 'horizontal' ? 'ylabel' : 'xlabel', $values );
		} else {
			my $horizontal = ( $plot->{orientation} // '' ) eq 'horizontal';
			$label_axis->( $horizontal ? 'xlabel' : 'ylabel', $values );
			$label_axis->( $horizontal ? 'ylabel' : 'xlabel', $by );
		}
	} elsif ( $type =~ m/^(?:scatter|hist2d|hexbin)$/ ) {
		my @axes = ( $x, $y[0], ( defined $color_key ? $color_key : () ) );
		my @kept = complete_rows( $cells, [ @axes, ( defined $by ? $by : () ) ] );
		check_dropped( scalar @kept, $n_rows, [ @axes, ( defined $by ? $by : () ) ], $where, $sub );
		if ( defined $by ) {
			foreach my $i (@kept) {
				push @{ $data{ $cells->{$by}[$i] }{$_} }, $cells->{$_}[$i] foreach @axes;
			}
			# in numeric order when the groups are numbers, as for every other
			# type; the sets of a scatter were drawn in sorted order, 10 before 2
			$plot->{key_order} = $plot->{key_order} // [ group_order( keys %data ) ] if $type eq 'scatter';
		} else {
			$data{$_} = [ @{ $cells->{$_} }[@kept] ] foreach @axes;
		}
		# The helpers' labels are taken from these, so they need not be set here.
		if ( $type eq 'scatter' ) {
			$plot->{'keys'} = [@axes];
		} else {
			$plot->{key_order} = [ $x, $y[0] ];
		}
	} elsif ( $type eq 'plot' ) {
		# One line per y column, or per group: each in the order of x, as a
		# line through a table's rows is meant to be read, the ties in row order.
		my $line = sub {
			my ( $y_col, @rows ) = @_;
			my @xs = @{ $cells->{$x} }[@rows];
			if ( not grep { not looks_like_number($_) } @xs ) {    # a word is refused by plot_helper, by name
				@rows = @rows[ sort { $xs[$a] <=> $xs[$b] || $a <=> $b } 0 .. $#rows ];
			}
			return [ [ @{ $cells->{$x} }[@rows] ], [ @{ $cells->{$y_col} }[@rows] ] ];
		};
		if ( defined $by ) {
			my @kept = complete_rows( $cells, [ $x, $y[0], $by ] );
			check_dropped( scalar @kept, $n_rows, [ $x, $y[0], $by ], $where, $sub );
			my %rows_of;
			push @{ $rows_of{ $cells->{$by}[$_] } }, $_ foreach @kept;
			$data{$_} = $line->( $y[0], @{ $rows_of{$_} } ) foreach keys %rows_of;
			$plot->{key_order} = $plot->{key_order} // [ group_order( keys %rows_of ) ];
		} else {
			foreach my $y_col (@y) {
				my @kept = complete_rows( $cells, [ $x, $y_col ] );
				check_dropped( scalar @kept, $n_rows, [ $x, $y_col ], $where, $sub );
				$data{$y_col} = $line->( $y_col, @kept );
			}
			$plot->{key_order} = $plot->{key_order} // [@y];
			# One line needs no legend: the y axis already says what it is.
			$plot->{show_legend} = $plot->{show_legend} // 0 if scalar @y == 1;
		}
		$label_axis->( 'xlabel', $x );
		$label_axis->( 'ylabel', defined $by || scalar @y == 1 ? $y[0] : undef );
	} else {
		die "plot_type \"$type\" is in %frame_roles but frame_to_data has no branch for it";
	}
	delete @{$plot}{@frame_keys};
	$plot->{data} = \%data;
}
sub frames_to_data {
	# frame_to_data for every plot hash plt will draw: the top level, each
	# subplot, and each "add" graph, which takes its subplot's plot_type when
	# it has none of its own.
	my ( $args, $sub ) = @_;
	my $graphs = sub {
		my ( $plot, $at ) = @_;
		return unless ref $plot->{add} eq 'ARRAY';
		foreach my $graph ( @{ $plot->{add} } ) {
			next unless ref $graph eq 'HASH';
			frame_to_data( $graph, $graph->{plot_type} // $plot->{plot_type}, " for an \"add\" graph$at", $sub );
		}
	};
	if ( ref $args->{plots} eq 'ARRAY' ) {
		my @top = grep { exists $args->{$_} } @frame_keys;
		if ( scalar @top ) {
			die "$sub: " . join( ', ', map { "\"$_\"" } @top ) . ' belong' . ( scalar @top == 1 ? 's' : '' )
			 . ' to a subplot when "plots" or "p" is given, not to the figure';
		}
		foreach my $j ( 0 .. $#{ $args->{plots} } ) {
			my $plot = $args->{plots}[$j];
			next unless ref $plot eq 'HASH';
			frame_to_data( $plot, $plot->{plot_type}, " at subplot $j", $sub );
			$graphs->( $plot, " at subplot $j" );
		}
	} else {
		frame_to_data( $args, $args->{plot_type}, '', $sub );
		$graphs->( $args, '' );
	}
}
sub shared_table_range {
	# One color scale for the colored_tables that share a colorbar, as
	# "cb_min" and "cb_max" for each that does not give its own.
	#
	# A table colors its cells in Perl's order of things, from the range of its
	# own cells, so tables sharing a colorbar each spread their own range over
	# the whole colormap, and the one colorbar -- drawn from the last of them --
	# was true only of that one. shared_color_scale cannot reach them, because
	# their colors are fixed when the table is drawn.
	my ( $args, $current_sub ) = @_;
	my @tables = grep { ( $args->{plots}[$_]{plot_type} // '' ) eq 'colored_table' } @{ $args->{shared_colorbar} };
	return if scalar @tables < 2;
	my ( @values, $log );
	foreach my $plot ( map { $args->{plots}[$_] } @tables ) {
		$log = 1 if bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
		next unless ref $plot->{data} eq 'HASH';
		# The cells the table draws, not every cell of "data": a cell that
		# "col_labels" left out stretched the shared scale, and
		# "default_undefined" was counted in whether or not any cell was
		# undefined.
		my ( $row_keys, $cols, $cells ) = table_cells( $plot, $current_sub );
		foreach my $k1 ( @{$row_keys} ) {
			push @values, finite_values( map { $cells->{$k1}{$_} // $plot->{default_undefined} } @{$cols} );
		}
	}
	@values = grep { $_ > 0 } @values if $log;    # a log scale starts above 0, as colored_table_helper's does
	return if scalar @values == 0;                 # each table refuses an empty one by name
	my ( $lo, $hi ) = ( min(@values), max(@values) );
	foreach my $plot ( map { $args->{plots}[$_] } @tables ) {
		$plot->{cb_min} = $plot->{cb_min} // $lo;
		$plot->{cb_max} = $plot->{cb_max} // $hi;
	}
}
sub check_add {
	# Die unless an "add" option, where given, is an array of hashes, one per
	# graph. A string in it died as 'Can't use string ("1") as a HASH ref'.
	my ( $add, $where ) = @_;
	return unless defined $add;
	if ( ref $add ne 'ARRAY' ) {
		die "\"add\"$where must be an array (of anonymous hashes), but you entered " . ( ref $add ? 'a ' . ref($add) . ' reference' : "\"$add\"" );
	}
	my @not_hash = grep { ref $add->[$_] ne 'HASH' } 0 .. $#{$add};
	if ( scalar @not_hash > 0 ) {
		die "\"add\"$where holds one HASH reference per graph, but index " . join( ', ', @not_hash ) . ' is not one';
	}
	# An "add" inside an "add" graph. The matplotlib engine draws the graphs
	# of "add" and never looks inside one for more, so the inner graphs were
	# left out of the figure without a word, where gnuplot and ggplot2 refused
	# them. Every graph of a subplot goes in the one "add", so there is nothing
	# a nested one could mean that the flat one does not say.
	my @nested = grep { exists $add->[$_]{add} } 0 .. $#{$add};
	if ( scalar @nested > 0 ) {
		die "\"add\"$where graph " . join( ', ', @nested ) . ' has an "add" of its own, which is not drawn: list every graph of the subplot in the one "add"';
	}
}
# The shape of "data" each plot_type reads. plot, scatter, imshow,
# venn_proportional_area and wide are not here: each checks its own.
my %data_shape = (
	bar           => 'hash',      barh       => 'hash',
	colored_table => 'hash',      pie        => 'hash',
	hexbin        => 'hash of arrays', hist2d => 'hash of arrays',
	boxplot       => 'sets',      hist       => 'sets',    # sets = an array of values, or a hash of them
	violin        => 'sets',      violinplot => 'sets',
);
sub check_data_shape {
	# Die naming the plot unless its "data" has the shape its plot_type reads.
	#
	# The helpers of these types dereferenced "data" without looking, so an
	# array given to bar died as "Not a HASH reference" and a hash of numbers
	# given to boxplot as 'Can't use string ("1") as an ARRAY ref', neither
	# naming "data" or the plot. An "add" graph was not checked at all: with
	# "data => {}" a violin wrote violinplot([]) and the script died in
	# matplotlib as "IndexError: too many indices for array".
	my ( $plot, $type, $where, $sub ) = @_;
	my $shape = $data_shape{ $type // '' };
	return unless defined $shape;
	my $data = $plot->{data};
	die "$sub: \"data\"$where is not defined" unless defined $data;
	my $ref = ref $data;
	if ( ( $ref eq 'ARRAY' ) && ( $shape eq 'sets' ) ) {
		die "$sub: \"data\"$where is an empty array" if scalar @{$data} == 0;
		return;
	}
	if ( $ref ne 'HASH' ) {
		my $wanted = ( $shape eq 'sets' ) ? 'an array of values, or a hash of them,' : "a $shape";
		die "$sub: \"data\"$where must be $wanted for $type, not " . ( $ref ? ( $ref eq 'ARRAY' ? 'an' : 'a' ) . " $ref reference" : "\"$data\"" );
	}
	die "$sub: \"data\"$where is an empty hash" if scalar keys %{$data} == 0;
	return if $shape eq 'hash';
	my @not_array = grep { ref $data->{$_} ne 'ARRAY' } sort keys %{$data};
	if ( scalar @not_array > 0 ) {
		die "$sub: each key of \"data\"$where is an array of values for $type, but "
		 . join( ', ', map { "\"$_\"" } @not_array ) . ( scalar @not_array == 1 ? ' is' : ' are' ) . ' not';
	}
}
# The pyplot functions that act on the whole figure rather than on the current
# axes, and so mean the same at the top of a figure of several subplots as
# anywhere. Every other one -- "title", "xscale", "ylim", "legend" -- acts on
# whichever axes is current, which there is the last subplot drawn.
my %figure_pyplot = map { $_ => 1 } qw(draw figimage figlegend figtext pause savefig set_loglevel show subplots_adjust suptitle tight_layout);
sub refuse_figure_keywords {
	# Die naming each keyword at the top of a figure of several subplots that
	# would not reach the subplots it seems to be about.
	#
	# The top level was checked against every plot type's options, then only
	# the figure's ("fig.") methods, pyplot's and a few of plt's own were
	# written. A "color", "cmap", "set_xlabel" or "add" there was accepted and
	# dropped; a pyplot "title" or "xscale" was written as plt.title(),
	# landing on the last subplot and replacing that subplot's own title.
	my ( $args, $current_sub ) = @_;
	my %plot_arg = map { $_ => 1 } ( 'add', 'cmap', 'plot', 'twinx' );
	my %plt_method = map { $_ => 1 } @plt_methods;
	my %fig_method = map { $_ => 1 } @fig_methods;
	my @lines;
	foreach my $key ( sort keys %{$args} ) {
		next if $fig_method{$key} || $figure_pyplot{$key};
		next if grep { $_ eq $key } ( 'sharex', 'sharey', @plt_arg );
		next if ( $key eq 'cbpad' ) && ( defined $args->{shared_colorbar} );
		if ( $plt_method{$key} ) {
			push @lines, "\"$key\" acts on one subplot, and here it would act on the last one drawn: give it in the hash of the subplot it belongs to"
			 . ( $key =~ m/^(?:title|xlabel|ylabel|legend)$/ ? ' ("suptitle", "supxlabel", "supylabel" and "figlegend" act on the whole figure)' : '' );
		} elsif ( $key eq 'cbpad' ) {
			push @lines, '"cbpad" at the top of a figure only places a "shared_colorbar"; without one, give it in the hash of the subplot whose colorbar it places';
		} elsif ( ( grep { $_ eq $key } @ax_methods, @all_opt ) || $plot_arg{$key} ) {
			push @lines, "\"$key\" belongs to one subplot: give it in the hash of the subplot it belongs to";
		}
	}
	return if scalar @lines == 0;
	die "$current_sub: with \"plots\" or \"p\", these keywords at the top of the figure would not be drawn where they seem to belong: " . join( '; ', @lines );
}
# The engines that draw plt's figures: the value of "engine" => the module that
# draws with it, which is loaded only when a figure asks for it. matplotlib is
# the default and draws everything this module accepts. Every other engine
# declares what it draws, and check_engine refuses the rest by name:
#
#   our %types           = ( bar => [ 'color', 'key_order', ... ], ... );
#                          the plot types it draws, each with the keywords of
#                          %opt it reads for that type
#   our @plot_keywords   = ( 'title', 'xlabel', ... );
#                          the keywords any plot it draws may carry, alone or
#                          in a subplot
#   our @figure_keywords = ( 'suptitle', 'scale', ... );
#                          the keywords of the figure as a whole, at the top
#                          level of a single plot or of "plots"
#   sub render { my ( $args, $context ) = @_; ... }
#                          as Matplotlib::Simple::Matplotlib::render, which documents
#                          what it is given; returns the script's path
#
# Each engine draws both styles (%styles); render finds the one asked for in
# $context->{style}.
#
# Matplotlib::Simple::Matplotlib instead sets $draws_everything, and is not checked.
our %engine_module = (
	ggplot2    => 'Matplotlib::Simple::Ggplot2',
	gnuplot    => 'Matplotlib::Simple::Gnuplot',
	matplotlib => 'Matplotlib::Simple::Matplotlib',
);
my $default_engine = 'matplotlib';
sub engine_name {
	# The engine a figure asked for, "matplotlib" if it asked for none, with its
	# module loaded; "engine" itself is taken out of the arguments, so that no
	# engine's own keyword checks meet it. Dies naming the engines there are
	# for any other value.
	my ( $args, $current_sub ) = @_;
	my $engine = delete $args->{engine};
	$engine = $default_engine unless defined $engine;
	if ( ( ref $engine ) || ( not defined $engine_module{$engine} ) ) {
		my $got = ref $engine ? 'a ' . ( ref $engine ) . ' reference' : "\"$engine\"";
		die "$current_sub: \"engine\" is one of " . join( ', ', map { "\"$_\"" } sort keys %engine_module ) . ", not $got";
	}
	( my $file = "$engine_module{$engine}.pm" ) =~ s{::}{/}g;
	require $file;
	return $engine;
}
# How the figure looks: the value of "style" => what it means. The default,
# "native", matches the engine: it lets the engine choose for itself its own
# palette and default colormap, its own statistics where it has a function for
# them, its own theme and legend placement. "matplotlib" has every engine draw
# what matplotlib draws -- its colors and colormaps, its binning, quartiles and
# densities, computed in Perl as numpy and scipy compute them, and its layout
# -- so that changing "engine" changes the renderer and not the figure. What
# the caller gave is drawn either way: the data, the key order, a "color" or a
# "cmap", the labels, limits, log scales and the size. matplotlib draws the
# same figure for both, its native look being matplotlib's.
our %styles = (
	matplotlib => 'what matplotlib draws, whichever engine draws it',
	native     => "the engine's own palette, statistics and theme",
);
my $default_style = 'native';
sub style_name {
	# The style a figure asked for, "native" if it asked for none; "style"
	# is taken out of the arguments, as "engine" is by engine_name.
	my ( $args, $current_sub ) = @_;
	my $style = delete $args->{style};
	$style = $default_style unless defined $style;
	if ( ( ref $style ) || ( not defined $styles{$style} ) ) {
		my $got = ref $style ? 'a ' . ( ref $style ) . ' reference' : "\"$style\"";
		die "$current_sub: \"style\" is one of " . join( '; ', map { "\"$_\", $styles{$_}" } sort keys %styles ) . "; not $got";
	}
	return $style;
}
sub refuse_subplot_choices {
	# Die if a subplot, or an "add" graph, names an engine or a style. One
	# engine draws the whole figure in one style, so each is given once,
	# beside "plots" or "p".
	my ( $args, $current_sub ) = @_;
	my @plots = ( $args, @{ ( ref $args->{plots} eq 'ARRAY' ) ? $args->{plots} : [] } );
	foreach my $i ( 0 .. $#plots ) {
		my $plot = $plots[$i];
		next unless ref $plot eq 'HASH';
		my $where = ( $i == 0 ) ? '' : ' at subplot ' . ( $i - 1 );
		foreach my $choice ( 'engine', 'style' ) {
			if ( ( $i > 0 ) && ( exists $plot->{$choice} ) ) {
				die "$current_sub: \"$choice\"$where: one engine draws the whole figure in one style, so give \"$choice\" once, beside \"plots\" or \"p\"";
			}
			next unless ref $plot->{add} eq 'ARRAY';
			if ( grep { ( ref $_ eq 'HASH' ) && ( exists $_->{$choice} ) } @{ $plot->{add} } ) {
				die "$current_sub: \"$choice\" in an \"add\" graph$where: one engine draws the whole figure in one style, so give \"$choice\" once, at the top level";
			}
		}
	}
}
sub check_engine {
	# Die unless the engine draws every plot type and reads every keyword the
	# figure asks for, naming each one it does not, and what it does draw.
	#
	# An engine that met a keyword it had no counterpart for could only leave
	# it out, and a figure missing its error bars, or drawn with a different
	# kind of color scale, looks right to someone who did not know to look.
	# matplotlib draws all of it, so the message says so.
	my ( $engine, $args, $single_plot, $current_sub ) = @_;
	my $module = $engine_module{$engine};
	no strict 'refs';
	return if ${"${module}::draws_everything"};
	my %types     = %{"${module}::types"};
	my %plot_kw   = map { $_ => 1 } @{"${module}::plot_keywords"};
	my %figure_kw = map { $_ => 1 } ( @{"${module}::figure_keywords"}, 'execute', 'fh', 'output_file' );
	my %grid_kw   = map { $_ => 1 } ( 'ncol', 'ncols', 'nrow', 'nrows', 'plots' );
	# Keywords given with the value that asks for nothing, which no engine has
	# to draw, and which are left out of the list of what it draws: "show =>
	# 0", which a program for matplotlib may pass, was refused, so that it
	# could not change "engine" without dropping it.
	my %asks_nothing = ( show => !$args->{show} );
	my ( @lines, %listed );
	my $refuse_keys = sub {
		my ( $bad, $what ) = @_;
		return if scalar @{$bad} == 0;
		push @lines, join( ', ', map { "\"$_\"" } @{$bad} ) . $what;
	};
	if ( $single_plot == 0 ) {
		$refuse_keys->( [ grep { ( not $figure_kw{$_} ) && ( not $grid_kw{$_} ) && ( not $asks_nothing{$_} ) } sort keys %{$args} ], ' for the figure' );
	}
	my @drawn = ( $single_plot == 1 ) ? ( [ $args, '' ] ) : map { [ $args->{plots}[$_], " at subplot $_" ] } 0 .. $#{ $args->{plots} };
	foreach my $drawn (@drawn) {
		my ( $plot, $at ) = @{$drawn};
		foreach my $graph ( $plot, @{ $plot->{add} // [] } ) {
			my $where = ( $graph == $plot ) ? $at : " for an \"add\" graph$at";
			my $type = $graph->{plot_type};
			if ( not defined $types{$type} ) {
				push @lines, "plot_type \"$type\"$where";
				next;
			}
			my %ok = ( %plot_kw, map { $_ => 1 } ( @{ $types{$type} }, 'data', 'plot_type' ) );
			if ( $graph == $plot ) {
				$ok{add} = 1;
				%ok = ( %ok, %figure_kw, %grid_kw ) if $single_plot == 1;    # plt sets "nrows" and "ncols" to 1 for a single plot
			}
			my @bad = grep { ( not $ok{$_} ) && ( ( $graph != $args ) || ( not $asks_nothing{$_} ) ) } sort keys %{$graph};
			next if scalar @bad == 0;
			$refuse_keys->( \@bad, " for plot_type \"$type\"$where" );
			$listed{$type} = 1;
		}
	}
	return if scalar @lines == 0;
	my @types_drawn = map { "$_ (" . ( join( ', ', @{ $types{$_} } ) || 'nothing of its own' ) . ')' } sort keys %listed;
	die "$current_sub: the $engine engine does not draw " . join( '; ', @lines )
	 . ". It draws the plot types " . join( ', ', sort keys %types )
	 . ( scalar @types_drawn ? ', with these keywords of their own: ' . join( '; ', @types_drawn ) : '' )
	 . '; and at any plot: ' . join( ', ', sort keys %plot_kw )
	 . '; and for the figure: ' . join( ', ', sort keys %figure_kw )
	 . ". engine => 'matplotlib', the default, draws all of it";
}
my $n_scripts = 0;    # scripts this process has named, for script_handle
sub script_handle {
	# The file an engine writes its script into, given a UTF-8 layer: the
	# caller's "fh", or a new temporary file with the engine's suffix.
	my ( $args, $suffix, $current_sub ) = @_;
	my $fh;
	if ( defined $args->{fh} ) {
		my $ref = ref $args->{fh};
		if ($ref ne 'File::Temp') {
			p $args;
			die "$current_sub received a \"$ref\" for \"fh\", which isn't a \"File::Temp\" object.";
		}
		$fh = $args->{fh};
	} else {
		# File::Spec->tmpdir(), not a literal "/tmp": on MSWin32 there is no
		# /tmp, and File::Temp dies with "Parent directory (\tmp\) does not
		# exist" (CPAN Testers FAIL for 0.312 on Strawberry perl 5.42.2).
		#
		# The process, the time and a count lead the name, ahead of the X's
		# File::Temp fills from rand(). The scripts are kept, and a caller who
		# seeds rand() with a fixed "srand 7" got the same names on every run,
		# each run stepping past the scripts the runs before it had left, until
		# File::Temp gave up: "Have exceeded the maximum number of attempts
		# (1000) to open temp file". Reseeding here would have cured it at the
		# price of the caller's own sequence, which a fixed seed is there to
		# keep.
		$fh = File::Temp->new(
			DIR      => File::Spec->tmpdir,
			TEMPLATE => sprintf( 'matplotlib-simple-%d-%d-%d-XXXXXX', $$, time, $n_scripts++ ),
			SUFFIX   => $suffix,
			UNLINK   => 0
		);
	}
	# Non-ASCII key names (e.g. Greek letters like ρ, τ) arrive as wide
	# characters when the caller has "use utf8", so give the output filehandle
	# a UTF-8 encoding layer. Without it, "say $fh" dies with
	# "Wide character in say" under this module's "warnings FATAL => 'all'".
	# Only add the layer if it isn't already present, to avoid double-encoding
	# a filehandle that was passed in.
	unless ( grep { /utf-?8/i } PerlIO::get_layers($fh) ) {
		# Checked by hand because this module does not "use autodie" (see
		# CLAUDE.md): binmode reports failure by returning undef, and an
		# unchecked failure here would stay silent until the first wide
		# character reached the file and died as "Wide character in say".
		# The message is autodie's own, which read
		# "Can't binmode($fh, ':encoding(UTF-8)'): Bad file descriptor".
		binmode( $fh, ':encoding(UTF-8)' )
		 or die "Can't binmode(" . $fh->filename . ", ':encoding(UTF-8)'): $!";
	}
	say 'temp file is ' . $fh->filename;
	return $fh;
}
sub run_script {
	# Run a command, the engine's interpreter and its script, and print what
	# it printed; die with what it printed if it fails.
	my ($command) = @_;
	my $errno;
	my ($stdout, $stderr, $exit) = capture {
		# The list form, not "python3 $file": the one-argument form goes
		# through the shell and splits on whitespace, so a temp directory
		# with a space in it -- %TEMP% on a Windows smoker sits under
		# C:\Users\<name>, and a user name with a space is ordinary --
		# would run python against a truncated path.
		# Departs from this file's "warnings FATAL => 'all'" on purpose,
		# for this statement only: with exec warnings fatal, a missing
		# interpreter dies right here as "Can't exec "python3"", system()
		# never returns, and the three failure modes below get reported
		# two different ways. autodie raised all three as one kind of
		# exception naming the command, which is what this restores.
		no warnings 'exec';
		my $status = system( @{$command} );
		# Read here, not after capture(): capture() does its own file
		# operations on the way out and they overwrite $!, which was
		# observed to leave "failed to start:" with nothing after it.
		$errno = "$!";
		$status;
	};
	if ($exit != 0) {
		say STDERR "STDOUT = $stdout";
		say STDERR "STDERR = $stderr";
		# The three ways system() reports failure, told apart because
		# they call for different fixes: no interpreter, a killed
		# process, and an error in the script. "use autodie" used to raise
		# these through IPC::System::Simple, but it threw from inside
		# capture(), so the two lines above -- the python traceback, the only
		# thing that says what is actually wrong -- were never reached. See
		# CLAUDE.md.
		my $why;
		if ( $exit == -1 ) {
			$why = "failed to start: $errno";
		} elsif ( $exit & 127 ) {
			$why = 'died to signal ' . ( $exit & 127 );
		} else {
			$why = 'unexpectedly returned exit value ' . ( $exit >> 8 );
		}
		die join( ' ', @{$command} ) . " $why";
	}
	# What the script printed, which capture{} above took out of the
	# terminal. The script reports things the caller has no other way to
	# learn -- the range of a hist's bin heights, a hist2d's density range,
	# both computed by matplotlib as it draws -- and those lines were
	# captured and then dropped on the floor on every successful run, so
	# only a *failing* run ever showed them. Already newline-terminated by
	# the interpreter, hence print and not say.
	print $stdout if length $stdout;
	# What it wrote to STDERR, which a successful run does not show: the
	# gnuplot engine reads gnuplot's version from it for the creator note.
	return $stderr;
}
sub program_from_env {
	# The first of these environment variables that is set and not empty,
	# taken whole -- a path such as "C:\Program Files\gnuplot\bin\gnuplot.exe"
	# has spaces in it, and is not split on them -- or undef if none is.
	foreach my $name (@_) {
		return $ENV{$name} if ( defined $ENV{$name} ) && ( $ENV{$name} ne '' );
	}
	return undef;
}
sub creator_note {
	# Where a figure came from, for the note an engine leaves in the file it
	# writes: the script that called plt, the call, this module and Perl. The
	# engine adds its own name and version, and the user and the host, which
	# its script reads as it runs.
	my ($current_sub) = @_;
	return getcwd() . "/$RealScript called using \"$current_sub\" in "
	 . ( $INC{'Matplotlib/Simple.pm'} // __FILE__ ) . " version $VERSION with Perl " . sprintf( '%vd', $^V );
}
sub svg_creator_metadata {
	# The <metadata> an SVG from matplotlib carries its Creator note in, as
	# two strings: what comes before the note, which must be XML-escaped
	# already, and what comes after. Laid out as matplotlib 3.11.2 writes it
	# (backend_svg._write_metadata), so that a figure from any engine keeps its
	# note in the one place, <dc:creator><cc:Agent><dc:title>. Each starts
	# on a new line, to follow the <svg ...> tag it goes after.
	return (
		"\n <metadata>\n"
		 . '  <rdf:RDF xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' . "\n"
		 . "   <cc:Work>\n    <dc:creator>\n     <cc:Agent>\n      <dc:title>",
		"</dc:title>\n     </cc:Agent>\n    </dc:creator>\n   </cc:Work>\n  </rdf:RDF>\n </metadata>"
	);
}
# What the engines other than matplotlib read the keywords as. The keywords
# are matplotlib's, and so are the conventions of their values: text may be
# Python of the caller's own (quote_text in Matplotlib::Simple::Matplotlib), a color is
# one of matplotlib's names, an axis range is the arguments of set_xlim. These
# turn each into something any engine can write, and refuse what has no
# meaning outside matplotlib by name.
sub plain_text {
	# A title or a label as the text it shows.
	#
	# Text that quote_text would leave as Python is read as Python: a string
	# literal, which may carry an r, u or b prefix, is its contents, escapes
	# and all, so "xlabel => py_str($column)" from frame_to_data and
	# "title => '\"Two groups, mean and s.d.\"'" both come out as the words.
	# A literal followed by keyword arguments, such as "fontsize = 20", or
	# keyword arguments alone, are matplotlib's, and are refused.
	my ( $text, $option, $engine, $current_sub ) = @_;
	$text = decoded_text($text);
	return $text if $text =~ m/^([^\"\',]+)$/;
	if ( $text =~ m/^\s*([rRbBuUfF]{0,2})(['"])((?:\\.|(?!\2)[^\\])*)\2\s*(,.*)?$/s ) {
		my ( $prefix, $body, $rest ) = ( lc $1, $3, $4 );
		if ( ( defined $rest ) && ( $rest !~ m/^,\s*$/ ) ) {    # a trailing comma alone is still one argument to Python
			die "$current_sub: \"$option\" is given matplotlib's arguments$rest after its text; the $engine engine takes the text alone";
		}
		if ( $prefix =~ m/f/ ) {
			die "$current_sub: \"$option\" is a Python f-string, which only matplotlib's Python can fill in; give the $engine engine the text as it should read";
		}
		return $body if $prefix =~ m/r/;    # a raw string keeps its backslashes
		# Python's escapes, as its lexical analysis lists them: octal of one to
		# three digits, which "\0" alone stood for, so that "\012" was a NUL
		# and "12"; and a character by its Unicode name, \N{...}, which Python
		# matches without regard to case. One Python does not know is left as
		# written, as Python leaves an unknown escape. The braces of \N{...}
		# are written [{] and [}], not \{ and \}: inside s{}{} perl 5.18 reads
		# \{ as a useless escape and warns, which FATAL warnings made a failure
		# to compile.
		my %escape = ( n => "\n", t => "\t", r => "\r", a => "\a", b => "\b", f => "\f", v => "\x0b", "\\" => "\\", "'" => "'", '"' => '"', "\n" => '' );
		require charnames;
		$body =~ s{\\(?:x([0-9a-fA-F]{2})|u([0-9a-fA-F]{4})|U([0-9a-fA-F]{8})|([0-7]{1,3})|N[{]([^{}]+)[}]|(.))}{
			defined $1 ? chr hex $1 : defined $2 ? chr hex $2 : defined $3 ? chr hex $3 : defined $4 ? chr oct $4
			: defined $5 ? ( defined charnames::vianame( uc $5 ) ? chr charnames::vianame( uc $5 ) : "\\N{$5}" )
			: exists $escape{$6} ? $escape{$6} : "\\$6"
		}gse;
		return $body;
	}
	if ( $text =~ m/^\s*[A-Za-z_]\w*\s*=[^=]/ ) {
		die "$current_sub: \"$option\" is given as matplotlib's keyword arguments, \"$text\"; the $engine engine takes the text alone";
	}
	return $text;
}
sub axis_limits {
	# The two ends of an axis range given as set_xlim's arguments -- "0, 10",
	# "(0, 10)" or [ 0, 10 ] -- as ( $lo, $hi ), either undef for None, which
	# leaves that end where the engine puts it.
	my ( $value, $option, $engine, $current_sub ) = @_;
	my @ends;
	if ( ref $value eq 'ARRAY' ) {
		@ends = @{$value};
	} elsif ( not ref $value ) {
		( my $inner = $value // '' ) =~ s/^\s*[\(\[]\s*(.*?)\s*[\)\]]\s*$/$1/s;
		@ends = map { ( my $end = $_ ) =~ s/^\s+|\s+$//g; $end } split /,/, $inner, -1;
	}
	if ( ( scalar @ends == 2 ) && ( not grep { ( defined $_ ) && ( $_ ne 'None' ) && ( ( not looks_like_number($_) ) || ( not is_finite($_) ) ) } @ends ) ) {
		return map { ( ( not defined $_ ) || ( $_ eq 'None' ) ) ? undef : 0 + $_ } @ends;
	}
	my $got = ref $value ? 'a ' . ( ref $value ) . ' reference' . ( ref $value eq 'ARRAY' ? ' of ' . scalar( @{$value} ) : '' ) : '"' . ( $value // 'undef' ) . '"';
	die "$current_sub: \"$option\" is two finite numbers for the $engine engine, the bottom and the top of the axis, such as \"0, 10\" or [ 0, 10 ], with None for an end left where it falls; not $got";
}
sub axis_scale {
	# "log" or "linear" from an "xscale", "yscale", "set_xscale" or
	# "set_yscale", quoted or not.
	my ( $value, $option, $engine, $current_sub ) = @_;
	my $scale = ( ref $value ) ? '' : ( $value // '' );
	$scale =~ s/^\s*(['"]?)(\w+)\1\s*$/$2/;
	return $scale if ( $scale eq 'log' ) || ( $scale eq 'linear' );
	die "$current_sub: \"$option\" is \"log\" or \"linear\" for the $engine engine, not \"" . ( ref $value ? ref $value : $value // 'undef' ) . '"';
}
sub color_hex {
	# A matplotlib color as "#rrggbb", or "#rrggbbaa" where it has an alpha
	# below 1: one of matplotlib's names (Matplotlib::Simple::Colors), a hex code, a
	# gray level from "0" to "1", or an RGB or RGBA tuple of numbers from 0 to
	# 1, as an array or as Python. The names are matplotlib's because gnuplot
	# and R each have their own lists, which differ from it and from each other.
	my ( $color, $option, $engine, $current_sub ) = @_;
	require Matplotlib::Simple::Colors;
	my $named = do { no warnings 'once'; \%Matplotlib::Simple::Colors::named };
	my @channels;
	if ( ref $color eq 'ARRAY' ) {
		@channels = @{$color};
	} elsif ( ( defined $color ) && ( not ref $color ) ) {
		( my $name = $color ) =~ s/^\s*(['"]?)(.*?)\1\s*$/$2/s;
		return $named->{$name} if defined $named->{$name};
		return $named->{ lc $name } if defined $named->{ lc $name };
		if ( $name =~ m/^#([0-9a-fA-F]{3,4})$/ ) {
			my $hex = lc join '', map { $_ x 2 } split //, $1;
			return '#' . ( ( $hex =~ m/ff$/ ) && ( length $hex == 8 ) ? substr( $hex, 0, 6 ) : $hex );
		}
		if ( $name =~ m/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/ ) {
			my $hex = lc $1;
			return '#' . ( ( $hex =~ m/ff$/ ) && ( length $hex == 8 ) ? substr( $hex, 0, 6 ) : $hex );
		}
		if ( ( looks_like_number($name) ) && ( $name >= 0 ) && ( $name <= 1 ) ) {
			@channels = ( $name, $name, $name );
		} elsif ( $name =~ m/^\s*[\(\[](.*)[\)\]]\s*$/s ) {
			@channels = map { ( my $channel = $_ ) =~ s/^\s+|\s+$//g; $channel } split /,/, $1;
		}
	}
	if ( ( ( scalar @channels == 3 ) || ( scalar @channels == 4 ) )
		&& ( not grep { ( not defined ) || ( not looks_like_number($_) ) || ( $_ < 0 ) || ( $_ > 1 ) } @channels ) ) {
		pop @channels if ( scalar @channels == 4 ) && ( $channels[3] == 1 );
		return '#' . join( '', map { sprintf '%02x', int( $_ * 255 + 0.5 ) } @channels );
	}
	my $got = ref $color ? 'a ' . ( ref $color ) . ' reference' : '"' . ( $color // 'undef' ) . '"';
	die "$current_sub: $option is not a color the $engine engine knows: $got. It takes matplotlib's base, CSS4 and \"tab:\" names, \"C0\" to \"C9\", \"#rrggbb\", a gray level from 0 to 1, or (r, g, b) from 0 to 1";
}
sub colormap_colors {
	# The colors of a matplotlib colormap from its low end to its high end, as
	# "#rrggbb", read from Matplotlib::Simple::Colors; a name ending in "_r" is the map
	# reversed, as in matplotlib.
	my ( $name, $engine, $current_sub ) = @_;
	require Matplotlib::Simple::Colors;
	my $maps = do { no warnings 'once'; \%Matplotlib::Simple::Colors::colormap };
	my $text = ( ref $name ) ? '' : ( $name // '' );
	$text =~ s/^\s*(['"]?)(.*?)\1\s*$/$2/s;
	my $reversed = ( $text =~ s/_r$// ) ? 1 : 0;
	if ( not defined $maps->{$text} ) {
		die "$current_sub: \"cmap\" \"" . ( ref $name ? ref $name : $name // 'undef' ) . "\" is not a colormap the $engine engine has; it has "
		 . join( ', ', sort { lc $a cmp lc $b } keys %{$maps} ) . ', and each of them reversed with "_r"';
	}
	my @colors = @{ $maps->{$text} };
	return $reversed ? reverse @colors : @colors;
}
sub plt {
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	# Accept BOTH calling conventions:
	#   new style:       plt( key => value, ... )
	#   back-compatible: plt({ key => value, ... })
	my $args;
	if ( ( scalar @_ == 1 ) && ( ref $_[0] eq 'HASH' ) ) {
		$args = $_[0];      # plt({ ... })
	} elsif ( ( scalar @_ % 2 ) == 0 ) {
		$args = { @_ };     # plt( ... )
	} else {
		die "$current_sub: odd number of arguments; call as $current_sub( key => value, ... ) or $current_sub({ key => value, ... })";
	}
	$args = copy_plot_hashes($args);
	refuse_dotted_keywords( $args, $current_sub );
	# Checked before anything multiplies them or compares them with a count of
	# plots: "ncols => 'two'" died as "Argument \"two\" isn't numeric in
	# multiplication", from a check further down that came too late to run.
	my @bad_grid = grep { ( defined $args->{$_} ) && ( ( ref $args->{$_} ) || ( $args->{$_} !~ m/^\s*\d+\s*$/ ) || ( $args->{$_} == 0 ) ) } ('ncol', 'ncols', 'nrow', 'nrows');
	if ( scalar @bad_grid > 0 ) {
		die "$current_sub: " . join( ', ', map { "\"$_\" = \"$args->{$_}\"" } @bad_grid ) . ' must be a whole number of at least 1';
	}
	# As numbers: they are written into plt.subplots() as they stand, and
	# "ncols => '02'" passed the check above and was a SyntaxError there.
	$args->{$_} = 0 + $args->{$_} foreach grep { defined $args->{$_} } ( 'ncol', 'ncols', 'nrow', 'nrows' );
	# fold the "p" interface into the engine's internal plot model
	normalise_p( $args, $current_sub ) if defined $args->{p};
	# and every "df" into the "data" of its plot_type, before anything checks
	# "data" or the keywords
	frames_to_data( $args, $current_sub );
	refuse_subplot_choices( $args, $current_sub );
	# Read as a Python bool, as every other switch is: tested for Perl truth,
	# "show => 'False'" wrote plt.show() and let the figure go without an
	# "output_file".
	$args->{show} = bool_option( $args->{show}, 'show', $current_sub ) if defined $args->{show};
	my @reqd_args = $args->{show} ? () : ('output_file'); # e.g. "my_image.svg"; optional if "show" is set
	my $single_example = 'plt({
	\'output_file\' => \'/tmp/gospel.word.counts.svg\',
	\'plot_type\'       => \'bar\',
	data              => {
	\'Matthew\' => 18345,
	\'Mark\'    => 11304,
	\'Luke\'    => 19482,
	\'John\'    => 15635,
	}
	});';
	my $multi_example = 'plt({
	\'output_file\'	=> \'svg/pie.svg\',
	plots             => [
	{
		data	=> {
		 Russian => 106_000_000,  # Primarily European Russia
		 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
		},
		\'plot_type\'	=> \'pie\',
		title       => \'Top Languages in Europe\',
		suptitle    => \'Pie in subplots\',
	},
	{
		data	=> {
		 Russian => 106_000_000,  # Primarily European Russia
		 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
		},
		\'plot_type\'	=> \'pie\',
		title       => \'Top Languages in Europe\',
	},
	ncols    => 3,
	});';
	if (ref $args->{output_file} ne '') {
		p $args;
		die '"output_file" must be a SCALAR or string, but was given a ' . ref $args->{output_file};
	}
	# A single plot is validated against the keywords of the type it asked
	# for, so that a mistyped keyword is reported against "bar"'s keywords
	# rather than the union of every type's -- which would suggest "notch"
	# to someone drawing a bar chart. This rejects nothing new: the helper
	# this plot dispatches to checks the same hash against the same list.
	# "plots" and "p" carry one type per subplot and none here, so for those
	# the union stands and each subplot is checked by its own helper.
	my $type_opt;
	if ( not defined $args->{plots} ) {
		check_plot_type({ type => $args->{plot_type} }) if defined $args->{plot_type};
		$type_opt = $opt_key_of_type{ $args->{plot_type} // '' };
	}
	my @defined_args = (@reqd_args, @ax_methods, @fig_methods, @plt_methods, @arg, @plt_arg,
	 defined $type_opt ? @{ $opt{$type_opt} } : @all_opt);
	my @bad_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @defined_args
	} keys %{$args};
	if ( scalar @bad_args > 0 ) {
		bad_keyword_error({
			bad       => \@bad_args,
			accepted  => \@defined_args,
			preferred => defined $type_opt ? $opt{$type_opt} : \@all_opt,
			type      => defined $type_opt ? $args->{plot_type} : undef,
			sub       => $current_sub
		});
	}
	# What is missing is reported only now that every keyword given is known to
	# be one: "shoxw => 1" died as 'either "show" or "output_file" must be
	# defined', which did not say that "show" had been given, mistyped, and
	# "plot_typ" as 'either "plot_type" or "plots"' likewise.
	# "output_file" is any name at all, so it is tested for being given rather
	# than for Perl truth, which refused a file called "0" as missing.
	if ( ( not ( ( defined $args->{output_file} ) && ( length $args->{output_file} ) ) ) && ( not $args->{show} ) ) {
		p $args;
		die 'either "show" or "output_file" must be defined';
	}
	if (   ( not defined $args->{plot_type} )
	  && ( not defined $args->{plots} ) )
	{
		p $args;
		die 'either "plot_type" or "plots" must be defined, but neither were';
	}
	$args->{nrows} = $args->{nrow} if defined $args->{nrow}; # allow synonyms
	$args->{ncols} = $args->{ncol} if defined $args->{ncol}; # allow synonyms
	$args->{nrows} = $args->{nrows} // 1;
	$args->{ncols} = $args->{ncols} // 1;
	my $single_plot = 0; # false
	if ( ( defined $args->{plot_type} ) && ( defined $args->{data} ) ) {
	  $single_plot = 1; # true
	}
	# A single plot and "plots" both given, or half of a single plot beside
	# "plots". The single plot was drawn on ax0 and then the first subplot drawn
	# on top of it, and with two subplots the script named an "ax1" that
	# plt.subplots(1,1) had not made; half of one was ignored.
	if ( defined $args->{plots} ) {
		my @single = grep { defined $args->{$_} } ( 'plot_type', 'data' );
		if ( scalar @single > 0 ) {
			die "$current_sub: " . join( ' and ', map { "\"$_\"" } @single ) . ' belong' . ( scalar @single == 1 ? 's' : '' )
			 . ' to a single plot, and cannot be given with "plots": put ' . ( scalar @single == 1 ? 'it' : 'them' ) . ' in the hash of a subplot';
		}
		refuse_figure_keywords( $args, $current_sub );
	}
	if (($single_plot == 1) && (not defined $args->{plot_type})) {
	  p $args;
	  say STDERR $single_example;
	  die "\"plot_type\" was not defined for a single plot in $current_sub";
	}
	if ( ( $single_plot == 0 ) && (not defined $args->{plots} )) {
		say STDERR $multi_example;
		die "$current_sub: single plots need \"data\" and \"plot_type\", see example above";
	}
	if ( ( $single_plot == 0 ) && ( ref $args->{plots} ne 'ARRAY' ) ) {
		p $args;
		die "$current_sub \"plots\" must have an array entered into it";
	}
	if ( ( $single_plot == 0 ) && ( scalar @{ $args->{plots} } == 0 ) ) {
		p $args;
		die "$current_sub \"plots\" has 0 plots entered.";
	}
	# Each subplot is read as a hash from here on, so anything else died as
	# "Not a HASH reference" at whichever line first looked inside it.
	if ( $single_plot == 0 ) {
		my @not_hash = grep { ref $args->{plots}[$_] ne 'HASH' } 0 .. $#{ $args->{plots} };
		if ( scalar @not_hash > 0 ) {
			die "$current_sub: \"plots\" holds one HASH reference per subplot, but index " . join( ', ', @not_hash ) . ' is not one';
		}
	}
	if ($single_plot == 1) {
		foreach my $arg (grep {defined $args->{$_} && $args->{$_} > 1} ('ncols', 'nrows')) {
			warn "\"$arg\" is set to >1, but there is only 1 plot: resetting $arg to 1.";
			$args->{$arg} = 1;
		}
		# Sharing an axis needs a second subplot to share it with. These are
		# axes methods too, so a single plot wrote "ax0.sharex(1)", which
		# matplotlib refused: "'other' must be an instance of ... _AxesBase".
		foreach my $arg ( grep { defined $args->{$_} } ( 'sharex', 'sharey' ) ) {
			warn "\"$arg\" shares an axis between subplots, but there is only 1 plot: ignoring it.";
			delete $args->{$arg};
		}
	}
	if (   ( $single_plot == 0 )
	  && ( ( $args->{nrows} * $args->{ncols} ) < scalar @{ $args->{plots} } )
	)
	{
	  p $args;
	  my $n_plots = scalar @{ $args->{plots} };
	  say STDERR
	"ncols = $args->{ncols}; nrows = $args->{nrows}, but there are $n_plots plots.\n";
	  die 'There are not enough subplots for the data';
	}
	if ($single_plot == 0) { # multiple plots
		my $max_i = scalar @{ $args->{plots} } - 1;
		my @hash_ref_i = grep { ref $args->{plots}[$_]{data} eq 'HASH' } 0..$max_i;
		@bad_args = grep { scalar keys %{ $args->{plots}[$_]{data} } == 0} @hash_ref_i;
		if (scalar @bad_args > 0) {
			foreach my $i (@bad_args) {
				say STDERR "plot index $i:";
				p $args->{plots}[$i];
			}
			die "the above hash ref indices have empty data hashes for $current_sub";
		}
		my @output_file = grep {defined $args->{plots}[$_]{output_file}} 0..$max_i;
		if (scalar @output_file > 0) {
			p $args;
			p @output_file;
			die '"output_file" was defined at subplots indices above, which does not make sense';
		}
	}
	if (($single_plot == 1) && (ref $args->{data} eq 'HASH') && (scalar keys %{ $args->{data}} == 0 )) {
		p $args;
		die '"data" is an empty hash';
	}
	@bad_args = grep {defined $args->{$_} && (not looks_like_number($args->{$_}))} ('cbpad', 'scale', 'scalex', 'scaley');
	if (scalar @bad_args > 0) {
		p $args;
		p @bad_args;
		die 'the above args must be numeric';
	}
	# A figure infinitely large, or NaN wide, cannot be drawn; each was written
	# into the script as given, as a bare "inf" or "nan".
	foreach my $scale ( grep { defined $args->{$_} } ( 'scale', 'scalex', 'scaley' ) ) {
		die "\"$scale\" must be a finite number above 0, not \"$args->{$scale}\"" unless ( is_finite( $args->{$scale} ) ) && ( $args->{$scale} > 0 );
	}
	# "dpi" is written into savefig as it stands, so it is a number here, and
	# one a file can be drawn at.
	if ( defined $args->{dpi} ) {
		my $dpi = $args->{dpi};
		if ( ( ref $dpi ) || ( not looks_like_number($dpi) ) || ( not is_finite($dpi) ) || ( $dpi <= 0 ) ) {
			die "\"dpi\" must be a finite number above 0, the dots per inch \"output_file\" is saved at, not " . ( ref $dpi ? ( ref $dpi ) . ' reference' : "\"$dpi\"" );
		}
		$args->{dpi} = 0 + $dpi;    # "0300" and " 300" are numbers to perl and not to python
	}
	# One file is saved at one resolution, so "dpi" in a subplot or an "add"
	# graph has nothing of its own to set. Asked here, by name: left to the
	# helper it was "isn't defined for plot_type", with "set_dpi" suggested.
	{
		my @plots = ( $single_plot == 1 ) ? ( [ $args, '' ] ) : map { [ $args->{plots}[$_], " at subplot $_" ] } 0 .. $#{ ( ref $args->{plots} eq 'ARRAY' ) ? $args->{plots} : [] };
		foreach my $drawn (@plots) {
			my ( $plot, $where ) = @{$drawn};
			next unless ref $plot eq 'HASH';
			if ( ( $single_plot == 0 ) && ( exists $plot->{dpi} ) ) {
				die "$current_sub: \"dpi\"$where: one file is saved at one resolution, so give \"dpi\" once, beside \"plots\" or \"p\"";
			}
			if ( ( ref $plot->{add} eq 'ARRAY' ) && ( grep { ( ref $_ eq 'HASH' ) && ( exists $_->{dpi} ) } @{ $plot->{add} } ) ) {
				die "$current_sub: \"dpi\" in an \"add\" graph$where: one file is saved at one resolution, so give \"dpi\" once, at the top level";
			}
		}
	}
	if ((defined $args->{shared_colorbar}) && ($single_plot == 1)) {
		warn 'There is only 1 plot/subplot, shared colorbars make no sense... deleting';
		delete $args->{shared_colorbar};
	}
	if (defined $args->{shared_colorbar}) {
		my $ref = ref $args->{shared_colorbar};
		if ($ref ne 'ARRAY') {
			p $args;
			die '"shared_colorbar" must be an array reference';
		}
		if ( scalar @{ $args->{shared_colorbar} } == 0 ) {
			die '"shared_colorbar" is an empty array: it takes the 0-based indices of the subplots that share the colorbar, e.g. [0,1]';
		}
		my @bad_idx = grep { ( not defined $_ ) || ( $_ !~ m/^\d+$/ ) } @{ $args->{shared_colorbar} };
		if ( scalar @bad_idx > 0 ) {
			p @bad_idx;
			die 'the above "shared_colorbar" entries are not 0-based subplot indices';
		}
		# Against the plots, not the cells of the grid: an index naming an empty
		# cell passed, the subplots before it had their colorbars turned off, and
		# the one meant to draw the shared colorbar did not exist, so none was
		# drawn and nothing was said.
		my $max_subplot_idx = max(@{ $args->{shared_colorbar} });
		my $max_plot_idx    = scalar @{ $args->{plots} } - 1;
		if ($max_subplot_idx > $max_plot_idx) {
			p $args;
			die "the max \"shared_colorbar\" index $max_subplot_idx > than the max index of plots, $max_plot_idx";
		}
		# plt tells each of these subplots whether to draw the colorbar, so each
		# has to be of a type that draws one. Any other died, from its own helper,
		# about a "colorbar_on" or "cbpad" the caller had never passed.
		my %draws_colorbar = map { $_ => 1 } qw(colored_table hexbin hist2d imshow scatter);
		my @no_colorbar = grep {
			( ref $args->{plots}[$_] eq 'HASH' ) && ( not $draws_colorbar{ $args->{plots}[$_]{plot_type} // '' } )
		} @{ $args->{shared_colorbar} };
		if ( scalar @no_colorbar > 0 ) {
			die '"shared_colorbar" lists subplot ' . join( ', ', map { "$_ (\"" . ( $args->{plots}[$_]{plot_type} // 'undef' ) . '")' } @no_colorbar )
			 . ', but only these plot types draw a colorbar: ' . join( ', ', sort keys %draws_colorbar );
		}
		shared_table_range( $args, $current_sub );
	}
	check_add( $args->{add}, '' );
	if ( $single_plot == 0 ) {
		check_add( $args->{plots}[$_]{add}, " at subplot $_" ) foreach 0 .. $#{ $args->{plots} };
	}
	# Before the figure is written, as the types are checked: every plot and
	# every "add" graph, which takes its plot's type when it has none.
	my @drawn = ( $single_plot == 1 ) ? ( [ $args, '' ] ) : map { [ $args->{plots}[$_], " at subplot $_" ] } 0 .. $#{ $args->{plots} };
	foreach my $drawn (@drawn) {
		my ( $plot, $at ) = @{$drawn};
		check_data_shape( $plot, $plot->{plot_type}, $at, $current_sub ) if defined $plot->{data};    # a plot with no "data" is refused by name where it is drawn
		foreach my $graph ( @{ $plot->{add} // [] } ) {
			check_data_shape( $graph, $graph->{plot_type} // $plot->{plot_type}, " for an \"add\" graph$at", $current_sub );
		}
	}
	if ( defined $args->{plots} ) {
		my @undef_plot_types;
		my $j = 0;
		foreach my $plot (@{ $args->{plots} }) {
			push @undef_plot_types, $j unless defined $plot->{plot_type};
			$j++;	# every subplot, not only the ones missing a type: $j is the index reported
		}
		if ( scalar @undef_plot_types > 0 ) {
			p $args;
			p @undef_plot_types;
			die 'The above subplot indices are missing "plot_type"';
		}
		# Each subplot's type is checked here, before the figure is written,
		# rather than at the dispatch below: a bad type at the last subplot
		# would otherwise be found only after every earlier subplot had been
		# written to the script.
		$j = 0;
		foreach my $plot (@{ $args->{plots} }) {
			check_plot_type({ type => $plot->{plot_type}, where => "at subplot $j" });
			foreach my $graph (@{ $plot->{add} }) {
				next unless defined $graph->{plot_type};	# an "add" graph without one inherits the subplot's
				check_plot_type({ type => $graph->{plot_type}, where => "for an \"add\" graph at subplot $j" });
			}
			$j++;
		}
	}
	# Each subplot has its "data" and its "plot_type". Here rather than where
	# each is drawn, as the types above are, so that every engine is handed
	# plots it can read without checking again.
	foreach my $i ( 0 .. $#{ $args->{plots} // [] } ) {
		my $plot = $args->{plots}[$i];
		my @undef_keys = grep { !defined $plot->{$_} } ( 'data', 'plot_type' );
		if ( scalar @undef_keys > 0 ) {
			p $plot;
			p @undef_keys;
			die "Above args are necessary, but were not defined for plot $i.";
		}
	}
	# An "add" graph without a type is drawn as its plot's type, which is what
	# an engine reads it as from here on.
	foreach my $drawn (@drawn) {
		my ( $plot, $at ) = @{$drawn};
		foreach my $graph ( @{ $plot->{add} // [] } ) {
			$graph->{plot_type} = $graph->{plot_type} // $plot->{plot_type};
		}
	}
	# As a Python bool, as the other switches are: compared with "==", "execute
	# => 'yes'" died as 'Argument "yes" isn't numeric'.
	$args->{execute} = bool_option( $args->{execute} // 1, 'execute', $current_sub );
	my $engine = engine_name( $args, $current_sub );
	my $style  = style_name( $args, $current_sub );
	check_engine( $engine, $args, $single_plot, $current_sub );
	# Taken out after check_engine has seen it, so that an engine that does not
	# list "dpi" refuses it by name, and before render, so that the helper a
	# single plot's hash is handed to does not meet a keyword that is the
	# figure's and not its own.
	my $dpi = delete $args->{dpi};
	return $engine_module{$engine}->can('render')->( $args, { sub => $current_sub, single_plot => $single_plot, style => $style, dpi => $dpi } );
}
# Generate wrappers dynamically
my @wrappers = qw(bar barh boxplot colored_table hexbin hist hist2d imshow pie plot scatter venn_proportional_area violin violinplot wide);

foreach my $sub_name (@wrappers) {
	no strict 'refs'; # Gemini helped
	*$sub_name = sub {
		# accept both bar({ ... }) and bar( ... )
		my $args;
		if ( ( scalar @_ == 1 ) && ( ref $_[0] eq 'HASH' ) ) {
			$args = $_[0];
		} elsif ( ( scalar @_ % 2 ) == 0 ) {
			$args = { @_ };
		} else {
			die "$sub_name: odd number of arguments; call as $sub_name( key => value, ... ) or $sub_name({ key => value, ... })";
		}
		# Check for conflicts
		if ((defined $args->{plot_type}) && ($args->{plot_type} ne $sub_name)) {
			warn "$args->{plot_type} will be ignored for $sub_name";
		}
		if (defined $args->{plots}) {
			die "\"plots\" is meant for the subroutine \"plt\"; $sub_name is single-only";
		}
		if (defined $args->{p}) {
			die "\"p\" is meant for the subroutine \"plt\"; $sub_name is single-only";
		}
		# Call plt
		plt({ %{ $args }, plot_type => $sub_name });
	};
}
# The default engine, loaded with the module rather than on the first figure,
# so that its subs -- python_command, which the tests call -- can be called by
# name as soon as Matplotlib::Simple is loaded. Last, because it aliases subs of this
# package, which have to be compiled first.
require Matplotlib::Simple::Matplotlib;
1;
__END__
# from md2pod.pl πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου
=encoding utf8

=head1 NAME

Matplotlib::Simple - Plots from Perl data structures, drawn by matplotlib, gnuplot or ggplot2, with one interface for every plot type

=head1 Synopsis

Use python3/matplotlib, gnuplot, and/or R/ggplot2 to make figures, using the exact same language syntax. Learning this one module gives easy creation of figures using 3 different common plotting libraries.

My aim is to simplify the most common tasks as much as possible.  In my opinion, using this module is much easier than matplotlib/gnuplot/ggplot themselves.

=head1 Single Plots

Simplest use case:

 use Matplotlib::Simple;
 bar(
    output_file       => '/tmp/gospel.word.counts.png',
    data              => {
       Matthew => 18345,
       Mark    => 11304,
       Luke    => 19482,
       John    => 15635,
    }
 );

A more complete (and slightly faster execution):

 use Matplotlib::Simple;
 plt(
    output_file       => '/tmp/gospel.word.counts.png',
    plot_type         => 'bar',
    data              => {
       Matthew => 18345,
       Mark    => 11304,
       Luke    => 19482,
       John    => 15635,
    }
 );


=for html
<p>
<img width="651" height="491" alt="gospel word counts" src="https://github.com/user-attachments/assets/a008dece-2e34-47bf-af0f-8603709f7d52" />
<p>


=head1 Multiple Plots

Having a C<plots> argument as an array lets the module know to create subplots:

 use Matplotlib::Simple 'plt';
 plt(
     output_file     => 'svg/pies.png',
     plots             => [
     {
             data    => {
              Russian => 106_000_000,  # Primarily European Russia
              German => 95_000_000,    # Germany, Austria, Switzerland, etc.
             },
             plot_type => 'pie',
             title       => 'Top Languages in Europe',
             suptitle    => 'Pie in subplots',
         },
         {
             data    => {
              Russian => 106_000_000,  # Primarily European Russia
              German => 95_000_000,    # Germany, Austria, Switzerland, etc.
             },
             plot_type => 'pie',
             title       => 'Top Languages in Europe',
         },
     ],
     ncols    => 2,
 );

which produces the following subplots image:


=for html
<p>
<img width="651" height="424" alt="pies" src="https://github.com/user-attachments/assets/49d3e28b-f897-4b01-9e72-38afa12fa538" />
<p>


C<bar>, C<barh>, C<boxplot>, C<hexbin>, C<hist>, C<hist2d>, C<imshow>, C<pie>, C<plot>, C<scatter>, and C<violinplot> all match the methods in matplotlib itself.  C<venn_proportional_area> additionally wraps the LL<https://pypi.org/project/matplotlib-venn/> library (see L<#venn_proportional_area>).

Everything that belongs to one subplot goes in that subplot's hash.  The top of
the call takes only what belongs to the whole figure: C<output_file>, C<show>,
C<execute>, C<ncols>/C<nrows>, C<scale>/C<scalex>/C<scaley>, C<sharex>/C<sharey>,
C<shared_colorbar> (with C<cbpad> to place it), the figure's own methods such as
C<set_figwidth> and C<supxlabel>, and those of pyplot's that act on the whole
figure: C<suptitle>, C<figtext>, C<figlegend>, C<figimage>, C<subplots_adjust> and
C<tight_layout>.  Anything else there is refused, naming where it belongs: a
C<title> or an C<xscale> at the top would act on whichever subplot was drawn last,
and a C<color> or an C<add> would reach none of them.  C<plot_type> and C<data> are a
single plot, and are refused beside C<plots>.

=head2 The C<p> argument

C<p> is a single, uniform way to describe one I<or> many subplots, so you no
longer need a top-level C<plot_type> (or the older C<plots> array). Each plot is a
hash, exactly like a single-plot call, and C<p> collects the subplots into one
array.

The rule is simple: B<< one element of C<p> is one subplot. >>

=over

=item * A B<hash> element is a subplot containing a single plot.

=item * An B<array of hashes> element is a single subplot whose plots are drawn on
the B<same> axes: the first hash is the base plot and the rest are
I<additions> (overlays), exactly like C<add>.

=back

The two forms may be B<mixed freely> in the same C<p>. The first (or only) hash
of a subplot supplies that subplot's axes-level options (C<title>, C<xlabel>,
C<ylabel>, C<legend>, …).

If you don't give a grid, the subplots are laid out automatically on a
near-square grid. Give C<ncol>/C<nrow> (aliases for C<ncols>/C<nrows>) to control
it; supplying only one dimension derives the other (so C<< ncols =E<gt> 1 >> stacks the
subplots in a single column), and supplying both is honored as given.

C<p> cannot be combined with C<plot_type>, C<data>, C<plots>, or C<add>.

 > Arguments are now passed as a plain list — C<plt( ... )> — though the older
 > C<plt({ ... })> form still works.

=head3 One subplot, several plots overlaid

Wrap the plots in an inner array and they all land on a single subplot (the
first is the base plot, the rest are additions):

 plt(
     p => [
         [
             {
                 data => {
                     E => [ 55, @{$x}, 160 ],
                     B => [ @{$y}, 140 ],
                 },
                 plot_type => 'boxplot',
                 title       => 'Single Box Plot: Specified Colors',
                 colors      => { E => 'yellow', B => 'purple' },
             },
             {
                 data => {
                     A => [ 55, @{$z} ],
                     E => [ @{$y} ],
                     B => [ 122, @{$z} ],
                 },
                 plot_type => 'violinplot',
                 title       => 'Single Violin Plot: Specified Colors',
                 colors      => { E => 'yellow', B => 'purple', A => 'green' },
             },
         ],
     ],
     output_file => '1plot.svg',    # note: no C<plot_type> needed
 );

=head3 Multiple subplots

Give each subplot as its own element. A bare hash is a one-plot subplot, so two
hashes make two subplots; with C<< ncol =E<gt> 2 >> they sit side by side:

 plt(
     p => [
         {
             data => {
                 E => [ 55, @{$x}, 160 ],
                 B => [ @{$y}, 140 ],
             },
             plot_type => 'boxplot',
             title       => 'Box Plot: Specified Colors',
             colors      => { E => 'yellow', B => 'purple' },
         },
         {
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             plot_type => 'violinplot',
             title       => 'Violin Plot: Specified Colors',
             colors      => { E => 'yellow', B => 'purple', A => 'green' },
         },
     ],
     ncol          => 2,
     output_file => '2plots.svg',
 );

To overlay extra plots on any one subplot, make that element an array of hashes
instead of a bare hash (the first is the plot, the rest are additions). Bare
hashes and inner arrays may be intermixed in the same C<p>, for example
C<< p =E<gt> [ \%single, [ \%base, \%overlay ], \%another ] >>.

=head2 Options

C<sharex> and C<sharey> are both implemented at the plot, rather than subplot, level.  Each takes C<True> or C<False> (or 1 or 0), or one of Matplotlib's words C<row>, C<col>, C<all> and C<none>, such as C<< sharey =E<gt> 'row' >>.  See Matplotlib's documentation for more clarity.

A number in C<data> may be NaN or infinite.  Such a value is drawn as Matplotlib draws it -- a NaN is a gap in a line, an empty cell of an C<imshow> or C<colored_table> -- and it does not count towards any range this module works out, such as a color scale.  C<boxplot> and C<violin> leave NaN out as they leave out an undefined value, and C<hist>, C<pie> and C<violin> refuse an infinite value, since there is nothing finite to bin, size or draw a density for.

=head3 Quoting text: commas and apostrophes

C<title>, C<suptitle>, C<supxlabel>, C<supylabel>, C<xlabel>, C<ylabel>,
C<set_title>, C<set_xlabel> and C<set_ylabel> are quoted for you, unless the text
is already Python of your own.
Text is taken to be Python when it holds a comma or a quote I<and> opens the way
Python does: with a string literal, which may carry a prefix such as C<r> or
C<f>, or with a keyword argument.  The literal has to close, and either be the
whole of the text or be followed by a comma, so C<"'Tis the season"> and
C<'"A" vs "B"'> are prose.  That is what makes a raw string such as

 xlabel => 'r"$\it{anno}$ $\it{domini}$"',    # italics, via mathtext

possible, along with options after the text:

 title => '"Two groups, mean and s.d.", fontsize = 20',

Anything else is prose, and is quoted, comma, apostrophe and all:

 title => 'Two groups, mean and s.d.',     # quoted for you
 title => "war's end",                     # likewise

Up to 0.318 any text holding a comma, an apostrophe or a double quote was passed
through, so prose like the two lines above had to carry its own quotes, and
without them the script was a syntax error.  Quoting it yourself still works.

Either kind of quote will do.  Up to 0.3131 a single plot wrote its figure-wide
options twice — C<suptitle> came out once for the subplot and once for the
figure — and the second pass ran its own quoting rules over text the first had
already quoted, turning C<< suptitle =E<gt> "'a, b'" >> into C<plt.suptitle(''a, b'')>, a
syntax error.  Double quotes were the documented way round it.  Each option is
now written once, and text that already carries a quote of its own is left
alone.

Every other option is passed through as written, so text inside C<legend>, C<text>
and friends is Python syntax throughout: C<< legend =E<gt> 'loc = "upper left"' >>.

B<Never pass untrusted text to an option.>  Text that reads as Python is
written into the script as Python, so text from a web form, a file you did not
write, or anyone else is a way to run code as you.  In a C<title>, a label or
C<suptitle>, C<'"t", fontsize = __import__("os").getpid()'> reads as a literal
followed by a keyword argument, and lands in the script whole.  Only text with
no quote character in it, C<'> or C<">, is certain to be quoted, so a label built
from untrusted text must have its quotes removed first.  C<legend>, C<text> and
the other options passed through as written are never quoted at all:
C<< legend =E<gt> 'x = exec(...)' >> runs, quotes or no quotes, so untrusted text must
never reach them.  The keys of C<data> are always escaped, and are
the place for text you did not write.

The exception is an option written as a C<plt.> call, such as C<xscale>, C<ylim>
or C<axhline>, at a single plot and at a subplot alike.  A word is quoted for
you, so C<< xscale =E<gt> 'log' >> becomes C<plt.xscale('log')>.  A value that is already
Python is left as it is: a number, a list of numbers such as C<< ylim =E<gt> '0, 10' >>,
C<None>, C<True> or C<False>, one bracketed group such as C<< ylim =E<gt> '(0, 10)' >>, one
function call, a keyword argument such as C<< axhline =E<gt> 'y = 0.5' >>, or anything
holding a quote of its own.

=head3 An option that isn't defined

Each plot type has its own list of options, so an option is only ever right or
wrong I<for the plot type you asked for>.  An option that isn't on that list
dies, naming what you wrote and what it resembles:

 bar(
    output_file => 'counts.svg',
    data          => { Matthew => 18345, Mark => 11304 },
    xlim          => '0, 20000',
 );
 
 "xlim" isn't defined for plot_type "bar", perhaps you meant one of these
 defined keywords: (clim, ylim, set_xlim)

The suggestions come from the list that plot type actually accepts, so the same
misspelling gets different answers at different plot types — C<bins_> is offered
C<bins> at a C<hist> and is not offered it at a C<boxplot>, which has no C<bins>.
Separators are ignored when matching, so C<key.order> finds C<key_order>, and two
transposed characters count as one mistake, so C<widht> finds C<width>.

An option that is real but belongs elsewhere is the commonest case, and says so
rather than leaving you to wonder whether the documentation lied:

 plot( ..., notch => 'True' );
 
 "notch" isn't defined for plot_type "plot"
         "notch" is a defined keyword, but for plot_type boxplot

=head3 A C<plot_type> that isn't defined

C<plot_type> is the one argument whose I<value> comes from a fixed list, and a
misspelling in it is answered the same way:

 plt(
    output_file => 'counts.svg',
    plot_type     => 'barr',
    data          => { Matthew => 18345, Mark => 11304 },
 );
 
 "barr" isn't a defined plot_type, perhaps you meant one of these defined
 plot types: (bar, barh)

The type is checked before the options are, because an unrecognised type leaves
no per-type list to check them against.  A type given for a subplot, or for an
C<add> graph, says which one it was:

 "violn" isn't a defined plot_type at subplot 1, perhaps you meant one of
 these defined plot types: (violin)
 
 "pye" isn't a defined plot_type for an "add" graph at subplot 1, perhaps
 you meant one of these defined plot types: (pie)

=head1 Engines

Every figure is drawn by an I<engine>, which is matplotlib unless C<engine> names
another.  The rest of the call stays as it is:

 use Matplotlib::Simple;
 bar(
    output_file => 'gospel.svg',
    data        => { Matthew => 18345, Mark => 11304, Luke => 19482, John => 15635 },
    title       => 'Gospel word counts',
    engine      => 'gnuplot',    # or 'ggplot2', or 'matplotlib', the default
 );

Here is one call, a C<bar>, a C<boxplot>, a C<hist> and a C<plot> in four subplots,
drawn by each engine in its own default style.  Only C<engine> differs between
them; C<engine.examples.pl> in the repository draws all three.

 plt(
    output_file => 'engines.png',
    engine      => $engine,    # 'matplotlib', 'gnuplot' or 'ggplot2'
    ncols       => 2,
    nrows       => 2,
    suptitle    => "engine: $engine",
    plots       => [
       { plot_type => 'bar',     title => 'bar',
         data => { Matthew => 18345, Mark => 11304, Luke => 19482, John => 15635 } },
       { plot_type => 'boxplot', title => 'boxplot', data => \%groups },
       { plot_type => 'hist',    title => 'hist',    data => \%groups },
       { plot_type => 'plot',    title => 'plot',
         data => { sin => [ \@x, [ map { sin } @x ] ],
                   cos => [ \@x, [ map { cos } @x ] ] } },
    ],
 );

where C<%groups> holds two samples of 200 normal deviates, C<A> and C<B>, and C<@x>
runs from 0 to 10.


=for html
<p>
<img width="651" height="491" alt="four subplots drawn by matplotlib" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/engine.matplotlib.png" />
<p>



=for html
<p>
<img width="640" height="480" alt="four subplots drawn by gnuplot" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/engine.gnuplot.png" />
<p>



=for html
<p>
<img width="640" height="480" alt="four subplots drawn by ggplot2" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/engine.ggplot2.png" />
<p>


=for html
<table>
<tbody>
<tr><td><code>engine</code></td><td>writes</td><td>runs it with</td><td>needs</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>matplotlib</code></td><td>a Python 3 script, <code>.py</code></td><td><code>python3</code>, or <code>MATPLOTLIB_SIMPLE_PYTHON</code></td><td>matplotlib 3.5 or newer, and <code>matplotlib_venn</code> for <code>venn_proportional_area</code></td></tr>
<tr><td><code>gnuplot</code></td><td>a gnuplot script, <code>.gp</code></td><td><code>gnuplot</code>, or <code>MATPLOTLIB_SIMPLE_GNUPLOT</code></td><td>gnuplot 5.2 or newer</td></tr>
<tr><td><code>ggplot2</code></td><td>an R script, <code>.R</code></td><td><code>Rscript</code>, or <code>MATPLOTLIB_SIMPLE_RSCRIPT</code></td><td>R with the package ggplot2 3.5.0 or newer, and nothing else</td></tr>
</tbody>
</table>

C<MATPLOTLIB_SIMPLE_GNUPLOT> and C<MATPLOTLIB_SIMPLE_RSCRIPT> work as C<MATPLOTLIB_SIMPLE_PYTHON> does: when set
and not empty, each is the path of the program to run, taken whole, spaces and
all.  C<engine> belongs to the whole figure: it goes at the top of the call,
beside C<plots> or C<p>, and is refused inside a subplot.  C<< execute =E<gt> 0 >>, C<fh>
and the L<#speed> trick of writing several figures into one script work
with every engine.

gnuplot and ggplot2 write C<.svg>, C<.png> and C<.pdf>, and refuse any other
C<output_file> by name.  A PNG is 100 dots to the inch, as matplotlib's is, and
every figure is matplotlib's 6.4 by 4.8 inches, times C<scale>, C<scalex> and
C<scaley>.  An SVG from either carries the note saying where it came from, in
the same place as matplotlib's (see L<#notes-in-files>); a PNG
or PDF from either does not, and the note is in the gnuplot or R script as a
comment.

=head2 What each engine draws

matplotlib draws every plot type and every keyword in this documentation.
gnuplot and ggplot2 draw these types:

=for html
<table>
<tbody>
<tr><td><code>plot_type</code></td><td>gnuplot</td><td>ggplot2</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>bar</code>, <code>barh</code></td><td>yes, without <code>edgecolor</code></td><td>yes</td></tr>
<tr><td><code>boxplot</code></td><td>yes, without <code>notch</code></td><td>yes</td></tr>
<tr><td><code>colored_table</code>, <code>hist</code>, <code>hist2d</code>, <code>imshow</code>, <code>pie</code>, <code>plot</code>, <code>scatter</code>, <code>violin</code>, <code>wide</code></td><td>yes</td><td>yes</td></tr>
<tr><td><code>hexbin</code></td><td>no</td><td>no: <code>geom_hex</code> needs the R package hexbin, which ggplot2 does not depend on</td></tr>
<tr><td><code>venn_proportional_area</code></td><td>no</td><td>no</td></tr>
</tbody>
</table>

and these keywords of every plot: C<title>, C<xlabel>, C<ylabel>, C<set_title>,
C<set_xlabel>, C<set_ylabel>, C<set_xlim>, C<set_ylim>, C<ylim>, C<xscale>, C<yscale>,
C<set_xscale> and C<set_yscale>; and of the figure: C<suptitle>, C<scale>,
C<scalex>, C<scaley>, C<output_file>, C<execute> and C<fh>, besides C<plots>, C<p>,
C<ncols> and C<nrows>.  Each type takes its own keywords as documented below,
except for these, which only matplotlib draws:

=over

=item * Python of your own: C<set_options>, C<twinx_args> and C<legend>, and any of
matplotlib's C<ax>, C<fig> and C<plt> methods not named above;

=item * C<tooltips>, C<twinx>, C<sharex>, C<sharey>, C<shared_colorbar>, C<linewidth>,
C<cbpad>, C<cbdrawedges>, C<cblocation>, C<cborientation> and C<show>.

=back

Anything an engine does not draw is refused by name, with what it does draw,
rather than left out of the figure:

 bar( engine => 'gnuplot', output_file => 'counts.svg',
      data => { Matthew => 18345, Mark => 11304 }, edgecolor => 'black' );
 
 plt: the gnuplot engine does not draw "edgecolor" for plot_type "bar". It
 draws the plot types bar, barh, boxplot, colored_table, hist, hist2d,
 imshow, pie, plot, scatter, violin, violinplot, wide, with these keywords
 of their own: bar (color, key_order, label, log, logscale, stacked, width,
 xerr, yerr); [...] engine => 'matplotlib', the default, draws all of it

Each engine also refuses, by name, the few combinations it cannot draw: an
error bar across a bar rather than along it, error bars on grouped bars, a
C<bins> given as a rule such as C<'auto'>, an C<add> graph on a C<pie> or a
C<colored_table> (or, in gnuplot, an C<imshow>), whose axes are their own, and
two graphs on one plot that would each need a color scale of their own, such as
a C<scatter> colored by C<color_key> over a C<hist2d>.

=head2 How the keywords are read

The keywords are matplotlib's, and so are the conventions of their values,
which gnuplot and ggplot2 read as matplotlib would:

=over

=item * B<Text.> A title or label that would be Python to matplotlib (see L<#quoting-text-commas-and-apostrophes>) is read as Python:
C<< title =E<gt> '"Two groups, mean and s.d."' >> is the words inside the quotes, and
C<r'C:\new'> keeps its backslash.  Text followed by matplotlib's own
arguments, such as C<'"Counts", fontsize = 20'>, is refused, and so is an
f-string.  Everything else is the words as given, quotes, backslashes, C<@>,
C<&>, C<^>, C<_>, C<{> and non-ASCII characters included.  Mathtext such as
C<$\alpha$> is shown as written.

=item * B<Colors.> matplotlib's names -- the base colors such as C<'k'>, the CSS4
names, the C<'tab:'> colors and C<'C0'> to C<'C9'> -- and C<'#rrggbb'>, a gray
level from C<'0'> to C<'1'>, or C<(r, g, b)> from 0 to 1, each drawn as the color
matplotlib gives it.  gnuplot and R have color names of their own, which
differ from matplotlib's and from each other, so these are not used.  The
C<'xkcd:'> names are refused.

=item * B<Colormaps.> C<cmap> is one of C<viridis>, C<plasma>, C<inferno>, C<magma>,
C<cividis>, C<turbo>, C<gist_rainbow>, C<rainbow>, C<jet>, C<coolwarm>, C<bwr>,
C<seismic>, C<RdBu>, C<RdYlBu>, C<RdYlGn>, C<Spectral>, C<PiYG>, C<PRGn>, C<BrBG>,
C<Blues>, C<Greens>, C<Greys>, C<Oranges>, C<Purples>, C<Reds>, C<YlOrRd>, C<YlGnBu>,
C<hot>, C<cool>, C<spring>, C<summer>, C<autumn>, C<winter>, C<gray>, C<bone> or
C<copper>, or any of them reversed with C<_r>, sampled from matplotlib.

=item * B<Axis ranges.> C<set_xlim>, C<set_ylim> and C<ylim> are two numbers, the bottom
and the top, as C<'0, 10'>, C<'(0, 10)'> or C<[ 0, 10 ]>, with C<None> for an end
left where the engine puts it.  Keyword forms such as C<'right = 180'> are
refused.  C<xscale> and the rest are C<'log'> or C<'linear'>.

=back

=head2 C<style>: the engine's own look, or matplotlib's

By default the style matches the engine: gnuplot and ggplot2 each draw in
their own style, C<< style =E<gt> 'native' >>, with their own palette, statistics and
theme.

C<< style =E<gt> 'matplotlib' >> has gnuplot or ggplot2 draw what matplotlib draws: its
colors and colormaps, its figure size, and its statistics -- a hist's bins, a
boxplot's quartiles and whiskers, a violin's density -- worked out in Perl as
numpy and scipy work them out, and only drawn by the engine.  Changing
C<engine> then changes how the figure is rendered, and not what it shows:

 plt( ..., engine => 'ggplot2', style => 'matplotlib' );

=for html
<table>
<tbody>
<tr><td></td><td><code>style => 'matplotlib'</code></td><td><code>style => 'native'</code> (the default)</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td>colors not given</td><td>matplotlib's <code>C0</code>, <code>C1</code>, ...</td><td>gnuplot's linetype colors; ggplot2's hue scale</td></tr>
<tr><td>colormap not given</td><td>matplotlib's default for the type</td><td>gnuplot's default palette; ggplot2's blue gradient</td></tr>
<tr><td><code>boxplot</code></td><td>numpy's quartiles, whiskers to 1.5 IQR</td><td>gnuplot's <code>with boxplot</code>; ggplot2's <code>stat_boxplot</code></td></tr>
<tr><td><code>violin</code></td><td>scipy's Gaussian density, Scott's bandwidth</td><td>gnuplot's <code>smooth kdensity</code>; ggplot2's <code>geom_violin</code></td></tr>
<tr><td><code>hist</code></td><td>numpy's bins</td><td>gnuplot's <code>bins</code> filter; ggplot2's <code>stat_bin</code></td></tr>
<tr><td><code>hist2d</code></td><td>numpy's 2-D bins</td><td>computed in Perl for gnuplot; ggplot2's <code>geom_bin_2d</code></td></tr>
<tr><td>frame, ticks, legend</td><td>matplotlib's</td><td>the engine's own theme</td></tr>
</tbody>
</table>

What you give is drawn either way: the data, the key order, a C<color> or a
C<cmap>, the labels, ranges, log scales and the size.  With no C<bins>, a hist
has 10 under either style, matplotlib's default: gnuplot's own count is the
number of points it samples a curve at, 100, and ggplot2's 30 comes with a
warning that it should be chosen.  C<pie> and C<wide> are worked out in Perl
under both styles, since neither engine has a statistic of its own for them.
Under matplotlib, C<< style =E<gt> 'matplotlib' >> draws what the default does.

A few things only the matplotlib style draws, and C<native> refuses by name,
saying so:

 plt: gnuplot's boxplot style draws its boxes upright only, so style =>
 'native' cannot draw orientation => 'horizontal'; style => 'matplotlib'
 can

namely a horizontal C<boxplot> or C<hist> in gnuplot, a horizontal C<violin> with
C<whiskers> in gnuplot, a hist whose C<bins> are edges of different widths in
gnuplot, and, in ggplot2, a C<bar>, C<boxplot> or C<violin> overlaid with a type
whose positions are numbers, since native ggplot2 puts their keys on a category
axis.  C<style> too belongs to the whole figure, and is refused inside a
subplot.

=head1 Color Bars (colorbars)

Colarbar args attempt to match matplotlib closely

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>cbdrawedges</code></td><td>Whether to draw lines at color boundaries</td><td><code>cbdrawedges => 1</code></td></tr>
<tr><td><code>cblabel</code></td><td>The label on the colorbar's long axis</td><td><code>cblabel => 'kJ/mol'</code></td></tr>
<tr><td><code>cblocation</code></td><td>of the colorbar None or {'left', 'right', 'top', 'bottom'}</td><td></td></tr>
<tr><td><code>cborientation</code></td><td># None or {<code>vertical</code>, <code>horizontal</code>}</td><td></td></tr>
<tr><td><code>cbpad</code></td><td>pad : float, default: 0.05 if vertical, 0.15 if horizontal; Fraction of original Axes between colorbar and new image Axes</td><td></td></tr>
<tr><td><code>cb_logscale</code></td><td>color on a log scale: <code>'True'</code> or <code>'False'</code> (in any case), or 1 or 0.  Works for <code>colored_table</code>, <code>hexbin</code>, <code>hist2d</code>, <code>imshow</code> and <code>scatter</code>, though not for an <code>imshow</code> with a <code>stringmap</code>, whose colors are categories.  The bottom of the scale is the smallest value above 0 unless <code>cb_min</code> or <code>vmin</code> says otherwise</td><td><code>cb_logscale => 1</code></td></tr>
<tr><td><code>cb_min</code>, <code>cb_max</code></td><td>the bottom and top of the color scale, taken from the data where not given.  For <code>hexbin</code>, <code>hist2d</code> and <code>imshow</code> these are the same as <code>vmin</code> and <code>vmax</code>, and only one of the two may be given for each end</td><td><code>cb_min => 0, cb_max => 10</code></td></tr>
<tr><td><code>shared_colorbar</code></td><td>share colorbar between different plots: specify plot indices.  Each subplot listed must be one that draws a colorbar: <code>colored_table</code>, <code>hexbin</code>, <code>hist2d</code>, <code>imshow</code> or <code>scatter</code>.  The subplots listed are put on one color scale, running from the lowest bottom of any of them to the highest top, so that one color means one value in all of them</td><td><code>shared_colorbar => [0,1]</code></td></tr>
</tbody>
</table>

Every switch among the options -- C<cb_logscale>, C<colorbar_on>, C<show_colorbar>,
C<show_legend>, C<show_numbers>, C<mirror>, C<stacked>, C<log>, C<notch>, C<showcaps>,
C<showfliers>, C<showmeans>, C<medians>, C<whiskers>, C<marginals>, C<density> and
C<execute> -- takes C<'True'> or C<'False'> in any case, or a number, where 0 is off.
Anything else, such as C<'yes'>, is refused by name, since it could mean either.
C<logscale> for C<bar> is the one exception, and takes Perl truth.

=head1 Size/Dimensions of output file

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>scale</code></td><td>scale/multiply the size of the output figure; this and the two below must be finite and above 0</td><td><code>scale => 2.4</code></td></tr>
<tr><td><code>scalex</code></td><td>scale/multiply the x-axis only</td><td><code>scalex => 2.4</code></td></tr>
<tr><td><code>scaley</code></td><td>scale/multiply the y-axis only</td><td><code>scaley => 1.4</code></td></tr>
<tr><td><code>dpi</code></td><td>dots per inch of the saved file, a finite number above 0; matplotlib's own default if left out. Given beside <code>plots</code> or <code>p</code>, not in a subplot. The matplotlib engine only, as of version 0.3343</td><td><code>dpi => 300</code></td></tr>
</tbody>
</table>

=head1 Examples/Plot Types

Every plot type can be called two ways: through C<plt> with C<< 'plot_type' =E<gt> 'bar' >>,
or through the same-named helper subroutine, C<bar( ... )>, which is a thin wrapper
that fills in C<'plot_type'> and calls C<plt> for you.  Everything documented for a
plot type therefore works in either form, and works identically whether the plot
is alone or one panel of a C<plots> grid.

=head2 Which helper takes which data?

The fastest way to pick a plot type is to start from the shape of the data you
already have in Perl:

=for html
<table>
<tbody>
<tr><td><code>data</code> you have</td><td>Helpers that take it</td><td>Notes</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td>hash of numbers, <code>A => 1</code></td><td><code>bar</code>, <code>barh</code>, <code>pie</code></td><td>one bar/wedge per key</td></tr>
<tr><td>hash of array refs, <code>A => [1,2,3]</code></td><td><code>boxplot</code>, <code>violin</code>, <code>hist</code>, <code>hexbin</code>, <code>hist2d</code>, <code>scatter</code>, <code>venn_proportional_area</code></td><td>one distribution/series per key; <code>hexbin</code> and <code>hist2d</code> need exactly 2 keys (x and y), <code>scatter</code> 2 or 3, <code>venn_proportional_area</code> 2 or 3</td></tr>
<tr><td>hash of hashes, <code>A => { X => 1 }</code></td><td><code>bar</code>, <code>barh</code>, <code>colored_table</code></td><td>grouped/stacked bars, or a matrix</td></tr>
<tr><td>hash of <code>[ \@x, \@y ]</code> pairs</td><td><code>plot</code></td><td>one labelled line per key</td></tr>
<tr><td>hash of arrays of <code>[ \@x, \@y ]</code> pairs</td><td><code>wide</code></td><td>repeated runs of the same curve, summarised</td></tr>
<tr><td>hash of hashes of array refs</td><td><code>scatter</code></td><td>several labelled sets, each with its own x/y (and colour)</td></tr>
<tr><td>hash of hashes of numbers, <code>A => { X => 1, Y => 2 }</code></td><td><code>scatter</code></td><td>one labelled point per key</td></tr>
<tr><td>a single array ref</td><td><code>hist</code>, <code>boxplot</code>, <code>violin</code></td><td>the one-series shorthand</td></tr>
<tr><td>array of <code>[ \@x, \@y ]</code> pairs</td><td><code>plot</code>, <code>wide</code></td><td>unlabelled lines</td></tr>
<tr><td>2-D array (array of array refs)</td><td><code>imshow</code></td><td>a raster/heatmap; strings allowed via <code>stringmap</code></td></tr>
<tr><td>a data frame (<code>df</code>) in any of <code>Stats::LikeR</code>'s four shapes</td><td>every type but <code>imshow</code>, <code>venn_proportional_area</code> and <code>wide</code></td><td>name the columns with <code>x</code>, <code>y</code> and <code>by</code>; see [Plotting a data frame](#plotting-a-data-frame-with-df)</td></tr>
</tbody>
</table>

A few conventions hold across all of them:

=over

=item * Keys are used in B<sorted order> unless you say otherwise.  C<key_order> is
accepted by C<bar>, C<barh>, C<boxplot>, C<violin>, C<hexbin>, C<hist2d>, C<pie>,
C<plot> and C<venn_proportional_area>; C<scatter> spells the same idea C<keys>;
and C<colored_table> uses C<row_labels>/C<col_labels>.  C<hist> and C<wide> take no
ordering option at all, and C<imshow> has no keys to order.

=item * An ordering option naming a key that C<data> does not have is an error naming
that key.  It used to reach the writer as an undefined value and die as C<Use
of uninitialized value in join or string>, which named neither the key nor the
option it came from.

=item * C<title>, C<xlabel>, C<ylabel>, C<suptitle>, C<set_xlim>, C<legend> and the rest of
Matplotlib's C<ax>/C<fig>/C<plt> methods are accepted by every plot type; see
L<#options>.

=item * Anything that is not recognised is reported as an error listing the arguments
that I<are> accepted, rather than being silently ignored.

=back

Consider the following helper subroutines to generate data to plot:

 sub linspace { # mostly written by Grok
    my ($start, $stop, $num, $endpoint) = @_; # endpoint means include $stop
    $num = defined $num ? int($num) : 50; # Default to 50 points
    $endpoint = defined $endpoint ? $endpoint : 1; # Default to include endpoint
    return () if $num < 0; # Return empty array for invalid num
    return ($start) if $num == 1; # Return single value if num is 1
    my (@result, $step);
 
    if ($endpoint) {
        $step = ($stop - $start) / ($num - 1) if $num > 1;
        for my $i (0 .. $num - 1) {
          $result[$i] = $start + $i * $step;
        }
   } else {
      $step = ($stop - $start) / $num;
      for my $i (0 .. $num - 1) {
         $result[$i] = $start + $i * $step;
      }
   }
    return @result;
 }
 
 sub generate_normal_dist {
     my ($mean, $std_dev, $size) = @_;
     $size = defined $size ? int $size : 100; # default to 100 points
     my @numbers;
     for (1 .. int($size / 2) + 1) {# Box-Muller transform
         my $u1 = rand();
         my $u2 = rand();
         my $z0 = sqrt(-2.0 * log($u1)) * cos(2.0 * 3.141592653589793 * $u2);
         my $z1 = sqrt(-2.0 * log($u1)) * sin(2.0 * 3.141592653589793 * $u2); # Scale and shift to match mean and std_dev
         push @numbers, ($z0 * $std_dev + $mean, $z1 * $std_dev + $mean);
     } # Trim to exact size if needed
     @numbers = @numbers[0 .. $size - 1] if @numbers > $size;
     @numbers = map {sprintf '%.1f', $_} @numbers;
     return \@numbers;
 }
 sub rand_between {
     my ($min, $max) = @_;
     return $min + rand($max - $min)
 }

=head2 Plotting a data frame with C<df>

A table read with C<Stats::LikeR>'s C<read_table>, or built by hand, can be given
whole as C<df> instead of C<data>, with the columns to draw named by role.  The
module rearranges the columns into the C<data> the plot type takes, so every
other option works as it does with C<data>:

 use Stats::LikeR 'read_table';
 my $d = read_table('main.table.csv');
 bar(
     output_file => 'bedroc.svg',
     df            => $d,
     x             => 'Method',          # one bar per row, labelled by this column
     y             => 'BEDROC(32.2)',    # and as tall as this one
 );

C<df> can be any of the four shapes C<Stats::LikeR> uses.  It is recognised by its
structure, so C<Stats::LikeR> itself is not needed:

=for html
<table>
<tbody>
<tr><td>shape</td><td>example</td><td>rows are taken</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td>array of hashes</td><td><code>[ { name => 'Al', age => 30 }, ... ]</code></td><td>in array order</td></tr>
<tr><td>hash of arrays</td><td><code>{ name => ['Al', ...], age => [30, ...] }</code></td><td>in array order; every column used must be the same length, except by <code>hist</code> and <code>violin</code> without <code>by</code></td></tr>
<tr><td>hash of hashes</td><td><code>{ Al => { age => 30 }, ... }</code></td><td>in the sorted order of the row names, as <code>Stats::LikeR</code>'s <code>vals</code> takes them</td></tr>
<tr><td>array of arrays</td><td><code>[ [ 'Al', 30 ], ... ]</code></td><td>in array order; columns are 0-based positions, negative from the end</td></tr>
</tbody>
</table>

The roles each plot type reads:

=for html
<table>
<tbody>
<tr><td>plot type</td><td><code>x</code></td><td><code>y</code></td><td><code>by</code></td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>bar</code>, <code>barh</code></td><td>the labels; leave it out of a hash of hashes to label by row name</td><td>the heights; several columns make grouped bars</td><td>one bar per group within each label</td></tr>
<tr><td><code>pie</code></td><td>the labels, as for <code>bar</code></td><td>the sizes</td><td></td></tr>
<tr><td><code>hist</code></td><td>the values; several columns make several histograms; every column of numbers if left out</td><td></td><td>one histogram per group</td></tr>
<tr><td><code>boxplot</code></td><td></td><td>the values; several columns make several boxes</td><td>one box per group</td></tr>
<tr><td><code>violin</code></td><td></td><td>the values, as for <code>boxplot</code>; every column of numbers if left out</td><td>one violin per group</td></tr>
<tr><td><code>scatter</code></td><td>x</td><td>y</td><td>one set of points per group</td></tr>
<tr><td><code>plot</code></td><td>x</td><td>y; several columns make several lines</td><td>one line per group</td></tr>
<tr><td><code>hist2d</code>, <code>hexbin</code></td><td>x</td><td>y</td><td></td></tr>
<tr><td><code>colored_table</code></td><td>the row labels, as for <code>bar</code></td><td>the columns of the table; every column but <code>x</code> if left out</td><td></td></tr>
</tbody>
</table>

C<scatter> also reads C<color_key> as the name of a column, which colors each point
and gets a colorbar:

 scatter(
     output_file => 'people.svg',
     df            => $d,
     x             => 'height',
     y             => 'weight',
     color_key     => 'age',
     by            => 'sex',     # one marker per sex, on one shared color scale
 );

Things C<df> does for you:

=over

=item * B<x is drawn on the x axis.>  C<scatter>, C<hist2d> and C<hexbin> otherwise
assign axes by the sorted order of the keys, so C<keys> and (for C<hist2d> and
C<hexbin>) C<key_order> are refused alongside C<df>.

=item * B<The axes are labelled with the column names>, unless you give C<xlabel> or
C<ylabel>.

=item * B<Bars and wedges are in the order of the rows>, and groups made by C<by> are
in numeric order when every group is a number (2 before 10) and in string
order otherwise.  An explicit C<key_order> still wins.

=item * B<< C<plot> draws each line in the order of x >>, so a table need not be sorted
first.

=item * B<< A row with no value (an C<undef>) in a column the plot uses is left out >>,
with a warning saying how many rows were dropped and from which columns, as
ggplot2 does.  Columns of C<hist>, C<boxplot> and C<violin> are filtered
independently, so a gap in one column does not cost the others a value.
C<colored_table> keeps such cells, and draws them as undefined.  A row that is
itself C<undef>, in an array of arrays or of hashes, is a row with no values.

=item * B<A color hash keyed by group or column> works for grouped bars.

=item * B<< C<hist> and C<violin> draw every column of numbers when C<x> or C<y> is left
out >>, as pandas' C<DataFrame.hist> does: a column holding anything but numbers,
such as names, is passed over.  The columns are in numeric order when every
name is a number, and in string order otherwise.  Each column is one
distribution, so without C<by> the columns of a hash of arrays need not be the
same length.  That is the shape C<Stats::LikeR>'s C<group_by> returns, one
column per group, and it can be drawn whole:

  my $mpg_by_cyl = group_by( $mtcars, 'mpg', 'cyl' );    # { 4 => [...], 6 => [...], 8 => [...] }
  violin(
    output_file => 'mpg.svg',
    df          => $mpg_by_cyl,                         # one violin per number of cylinders
  );

=back

And things it refuses, by name:

=over

=item * a column the frame does not have, with the closest names it does have;

=item * a label repeated in C<bar>, C<barh> or C<pie>, or a label and group pair
repeated in a grouped C<bar>.  C<df> does not aggregate: use C<Stats::LikeR>'s
C<agg> or C<pivot_table> first;

=item * a grouped C<bar> missing a value for some label and group;

=item * a column named twice, a role the plot type does not read, and several
columns where only one makes sense;

=item * C<df> together with C<data>.

=back

C<df> works the same in a subplot and in an C<add> graph, each with its own frame.
C<venn_proportional_area>, C<imshow> and C<wide> do not take it.

=head2 Barplot/bar/barh

Plot a hash, a hash of arrays, or a hash of hashes as a bar chart.  C<bar> draws
vertical bars, C<barh> horizontal ones; every option below applies to both.

=head3 Entering data

C<data> accepts three shapes, and the shape alone decides whether you get one
bar per key or a group of bars per key:

B<1. One bar per key (hash of numbers).> The simplest case — the key is the
tick label:

 bar(
     output_file => '/tmp/simple.svg',
     data          => { Mon => 73, Tue => 93, Wed => 77 },
 );

B<2. Groups of bars (hash of array refs).> Each key becomes a group; index C<i>
of every array is one series, so C<color> and C<label> are arrays indexed the same
way:

 bar(
     output_file => '/tmp/grouped.svg',
     data          => {
         1941 => [ 6.6, 6.2 ],    # UK, US
         1942 => [ 7.6, 26.4 ],
     },
     color         => [ 'blue', 'gray' ],    # index 0, index 1
     label         => [ 'UK',   'US'   ],    # legend entries
 );

B<3. Groups of bars (hash of hashes).> The same picture as (2), but the series
are named by the inner keys rather than by position, so no C<label> is needed:

 bar(
     output_file => '/tmp/grouped.hoh.svg',
     data          => {
         1941 => { UK => 6.6, US => 6.2 },
         1942 => { UK => 7.6, US => 26.4 },
     },
 );

Both grouped forms accept C<< stacked =E<gt> 1 >> to pile the series on top of one
another instead of placing them side by side.

=head3 Error bars

C<yerr> (natural for C<bar>) and C<xerr> (natural for C<barh>) take either one
number for every bar, an array of one number per bar (in the order of C<key_order>, or
of the sorted keys), an array of two such arrays (the lower errors, then the upper),
or a hash keyed by the data keys.  In the hash, each value is one number, or a
two-element array giving asymmetric C<[ lower, upper ]> errors:

 bar(
     output_file => '/tmp/warheads.svg',
     data          => { USA => 5277, Russia => 5449 },
     yerr          => {
         USA    => [ 15,  29   ],    # -15, +29
         Russia => [ 199, 1000 ],
     },
     log           => 'True',
     ylabel        => '# of Nuclear Warheads',
 );

=head3 Options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td>color</td><td>:mpltype:<code>color</code> or list of :mpltype:<code>color</code>, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed; as of version 0.23, colors can be given as a hash, whose keys are the bars of a simple hash or the *inner* keys (the series) of a hash of hashes.  A hash of arrays has no series names to key a color hash by, and says so rather than ignoring it</td><td><code>color => ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],</code> or a single color for all bars <code>color => 'red'</code>, or as of version 0.23 <code>color => {A => 'red', B => 'green'}</code></td></tr>
<tr><td>edgecolor</td><td>:mpltype:<code>color</code> or list of :mpltype:<code>color</code>, optional; The colors of the bar edges.  For a simple hash, may also be a hash of one color per key, as <code>color</code> may; a grouped plot refuses a hash, since each of its bars is one key of one series</td><td><code>edgecolor     => 'black'</code></td></tr>
<tr><td>key_order</td><td>define the keys in an order (an array reference)</td><td><code>key_order          => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],</code></td></tr>
<tr><td>label</td><td>an array of legend labels for grouped bar plots, indexed like the data arrays; only meaningful for the hash-of-arrays form, since the hash-of-hashes form takes its labels from the inner keys</td><td><code>label => ['North', 'South'],</code></td></tr>
<tr><td>linewidth</td><td>float or array of one per bar, optional; Width of the bar edge(s). If 0, don't draw edges. Only does anything with defined <code>edgecolor</code></td><td><code>linewidth => 2,</code></td></tr>
<tr><td>log</td><td>bool, default: False; If *True*, set the y-axis to be log scale.  Give <code>'True'</code> or <code>'False'</code> (or 1 or 0); anything else is refused, and <code>'False'</code> turns the log scale off</td><td><code>log = 'True',</code></td></tr>
<tr><td>logscale</td><td>a synonym for <code>log</code> taking a Perl true/false value rather than Python's <code>'True'</code>/<code>'False'</code>.  Unlike the <code>logscale</code> of <code>boxplot</code>, <code>hist</code>, <code>hist2d</code>, <code>plot</code>, <code>scatter</code> and <code>violin</code>, this one is a scalar and not an array of axis names</td><td><code>logscale => 1,</code></td></tr>
<tr><td>stacked</td><td>stack the groups on top of one another; <code>'True'</code> or 1 for on, default off</td><td><code>stacked  => 1,</code></td></tr>
<tr><td>width</td><td>float only, default: 0.8; The width of the bars (their height, for <code>barh</code>).  <code>width</code> will be deactivated with grouped, non-stacked bar plots</td><td><code>width => 0.4,</code></td></tr>
<tr><td>xerr</td><td>float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)</td><td><code>yerr                       => {'USA'               => [15,29], 'Russia'            => [199,1000],}</code></td></tr>
<tr><td>yerr</td><td>same as xerr, but better with bar</td><td></td></tr>
</tbody>
</table>

an example of multiple plots, showing many options:

=head3 single, simple plot

 use Matplotlib::Simple 'plt';
 plt(
     output_file             => 'output.images/single.barplot.png',
     data    => { # simple hash
         Fri => 76, Mon  => 73, Sat => 26, Sun => 11, Thu    => 94, Tue  => 93, Wed  => 77
     },
     plot_type => 'bar',
     xlabel      => '# of Days',
     ylabel      => 'Count',
     title       => 'Customer Calls by Days'
 );

where C<xlabel>, C<ylabel>, C<title>, etc. are axis methods in matplotlib itself. C<plot_type>, C<data>, C<fh> are all specific to C<MatPlotLib::Simple>.

=for html
<p>
<img width="651" height="491" alt="single barplot" src="https://github.com/user-attachments/assets/eae009a8-5571-4608-abdb-1016e3cff5fd" />
<p>


=head3 multiple plots

 plt(
     fh                  => $fh,
     execute                => 0,
     output_file     => 'output.images/barplots.png',
     plots                   => [
     { # simple plot
             data    => { # simple hash
                 Fri => 76, Mon  => 73, Sat => 26, Sun => 11, Thu    => 94, Tue  => 93, Wed  => 77
             },
             plot_type => 'bar',
            key_order        => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
             suptitle            => 'Types of Plots', # applies to all
             color               => ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],
             edgecolor       => 'black',
             set_figwidth    => 40/1.5, # applies to all plots
             set_figheight   => 30/2, # applies to all plots
             title               => 'bar: Rejections During Job Search',
             xlabel          => 'Day of the Week',
             ylabel          => 'No. of Rejections'
         },
         { # grouped bar plot
             plot_type => 'bar',
             data    => {
                 1941 => {
                    UK       => 6.6,
                    US       => 6.2,
                    USSR     => 17.8,
                    Germany => 26.6
                 },
                 1942 => {
                   UK      => 7.6,
                   US      => 26.4,
                   USSR    => 19.2,
                   Germany => 29.7
                 },
                 1943 => {
                  UK      => 7.9,
                   US      => 61.4,
                   USSR    => 22.5,
                   Germany => 34.9
                 },
                 1944 => {
                   UK      => 7.4,
                   US      => 80.5,
                   USSR    => 27.0,
                   Germany => 31.4
                 },
                 1945 => {
                   UK      => 5.4,
                   US      => 83.1,
                   USSR    => 25.5,
                   Germany => 11.2 #Rapid decrease due to war's end
                 },
             },
             stacked => 0,
             title       => 'Hash of Hash Grouped Unstacked Barplot',
             width       => 0.23,
             xlabel  => 'r"$\it{anno}$ $\it{domini}$"', # italic
             ylabel  => 'Military Expenditure (Billions of $)'
         },
          { # grouped bar plot
             plot_type => 'bar',
             data    => {
                 1941 => {
                   UK      => 6.6,
                   US      => 6.2,
                   USSR    => 17.8,
                   Germany => 26.6
                 },
                 1942 => {
                   UK      => 7.6,
                   US      => 26.4,
                   USSR    => 19.2,
                   Germany => 29.7
                 },
                 1943 => {
                   UK      => 7.9,
                   US      => 61.4,
                   USSR    => 22.5,
                   Germany => 34.9
                 },
                 1944 => {
                   UK      => 7.4,
                   US      => 80.5,
                   USSR    => 27.0,
                   Germany => 31.4
                 },
                 1945 => {
                   UK      => 5.4,
                   US      => 83.1,
                   USSR    => 25.5,
                    Germany => 11.2 #Rapid decrease due to war's end 
                 },
             },
             stacked => 1,
             title       => 'Hash of Hash Grouped Stacked Barplot',
             xlabel  => 'r"$\it{anno}$ $\it{domini}$"', # italic
             ylabel  => 'Military Expenditure (Billions of $)'
         },
         {# grouped barplot: arrays indicate Union, Confederate which must be specified in options hash
             data                    => { # 4th plot: arrays indicate Union, Confederate which must be specified in options hash
              'Antietam'             => [ 12400, 10300 ],
              'Gettysburg'           => [ 23000, 28000 ],
              'Chickamauga'          => [ 16000, 18000 ],
              'Chancellorsville' => [ 17000, 13000 ],
              'Wilderness'           => [ 17500, 11000 ],
              'Spotsylvania'     => [ 18000, 12000 ],
              'Cold Harbor'          => [ 12000, 5000  ],
              'Shiloh'               => [ 13000, 10700 ],
              'Second Bull Run'  => [ 10000, 8000  ],
              'Fredericksburg'       => [ 12600, 5300  ],
             },
             plot_type => 'barh',
             color       =>  ['blue', 'gray'], # colors match indices of data arrays
             label       => ['North', 'South'], # colors match indices of data arrays
             xlabel  => 'Casualties',
             ylabel  => 'Battle',
             title       => 'barh: hash of array'
         },
         { # 5th plot: barplot with groups
             data    => {
                 1942 => [ 109867,  310000, 7700000 ], # US, Japan, USSR
                 1943 => [ 221111,  440000, 9000000 ],
                 1944 => [ 318584,  610000, 7000000 ],
                 1945 => [ 318929, 1060000, 3000000 ],
             },
             color       => ['blue', 'pink', 'red'], # colors match indices of data arrays
             label       => ['USA', 'Japan', 'USSR'], # colors match indices of data arrays
             'log'       => 1,
             title       => 'grouped bar: Casualties in WWII',
             ylabel  => 'Casualties',
             plot_type => 'bar'
         },
         { # nuclear weapons barplot
             plot_type       => 'bar',
             data => {
                 'USA'               => 5277, # FAS Estimate
                 'Russia'            => 5449, # FAS Estimate
                 'UK'                => 225, # Consistent estimate
                 'France'            => 290, # Consistent estimate
                 'China'         => 600, # FAS Estimate
                 'India'         => 180, # FAS Estimate
                 'Pakistan'      => 130, # FAS Estimate
                 'Israel'            => 90, # FAS Estimate
                 'North Korea'   => 50, # FAS Estimate
             },
             title       => 'Simple hash for barchart with yerr',
             xlabel  => 'Country',
             yerr                        => {
                 'USA'               => [15,29],
                 'Russia'            => [199,1000],
                 'UK'                => [15,19],
                 'France'            => [19,29],
                 'China'         => [200,159],
                 'India'         => [15,25],
                 'Pakistan'      => [15,49],
                 'Israel'            => [90,50],
                 'North Korea'   => [10,20],
             },
             ylabel  => '# of Nuclear Warheads',
             'log'                       => 'True', #    linewidth               => 1,
         }
     ],
     ncols   => 3,
     nrows   => 4
 );

which produces the plot:


=for html
<p>
<img width="2678" height="849" alt="barplots" src="https://github.com/user-attachments/assets/6d87d13b-dabd-485d-92f7-1418f4acc65b" />
<p>


=head3 colors for each hash key defined by hash

 plt(
     plots => [
         {
             color        => {
                 A => 'red', B => 'green', C => 'blue'
             },
             data => {
                 A => 1, B => 2, C => 3
             },
             plot_type     => 'bar'
         },
         {
             color        => {
                 A => 'red', B => 'green', C => 'blue'
             },
             data => {
                 A => 1, B => 2, C => 3
             },
             plot_type     => 'barh'
         },
     ],
     ncols         => 2,
     output_file => '/tmp/key.colors.bar.svg',
 );

which produces the plot


=for html
<p>
<img width="651" height="491" alt="key colors bar" src="https://github.com/user-attachments/assets/0eab9c75-7e87-4297-b45d-86e5d7ffc550" />
<p>


=head2 boxplot

Plot a hash of arrays as a series of boxplots: one box per key, labelled with
the key and the number of points it holds.

=head3 Entering data

Ordinarily C<data> is a hash of array refs, one array per box:

 boxplot(
     output_file => '/tmp/boxes.svg',
     data          => { A => \@a, B => \@b, C => \@c },
 );

A bare array ref is the one-box shorthand; the box gets an empty label:

 boxplot(
     output_file => '/tmp/one.box.svg',
     data          => \@a,
 );

Undefined values are dropped rather than fatal, so a column read out of a
spreadsheet with blank cells can be handed over as-is; a value that is present
but not a number is an error naming the offending key.  (L<#violin>
takes exactly these two shapes as well — swapping C<< 'plot_type' =E<gt> 'boxplot' >>
for C<< 'plot_type' =E<gt> 'violinplot' >> is a one-word change — but it drops
non-numeric values silently instead of dying.)

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>color</code></td><td>a single color for all boxes</td><td><code>color => 'pink'</code></td></tr>
<tr><td><code>colors</code></td><td>a hash pairing each data key with its own color.  Every key in <code>data</code> must appear, otherwise the call dies naming the keys that have no color</td><td><code>colors => { A => 'orange', E => 'yellow', B => 'purple' },</code></td></tr>
<tr><td><code>key_order</code></td><td>order that the keys in the entry hash will be plotted</td><td><code>key_order => ['A', 'E', 'B']</code></td></tr>
<tr><td><code>logscale</code></td><td>an array of the axes to put on a log scale; only <code>x</code> and <code>y</code> are accepted</td><td><code>logscale => ['y']</code></td></tr>
<tr><td><code>notch</code></td><td>draw a notched box (<code>'True'</code>) instead of a rectangular one</td><td><code>notch => 'True'</code></td></tr>
<tr><td><code>orientation</code></td><td>orientation of the plot, by default <code>vertical</code></td><td><code>orientation => 'horizontal'</code></td></tr>
<tr><td><code>showcaps</code></td><td>Show the caps on the ends of whiskers; default <code>True</code></td><td><code>showcaps => 'False',</code></td></tr>
<tr><td><code>showfliers</code></td><td>Show the outliers beyond the caps; default <code>True</code></td><td><code>showfliers  => 'False'</code></td></tr>
<tr><td><code>showmeans</code></td><td>show means; default = <code>True</code></td><td><code>showmeans   => 'False'</code></td></tr>
</tbody>
</table>

C<showcaps>, C<showfliers>, C<showmeans> and C<notch> take Python's C<'True'>/C<'False'>,
in any case, or 1 or 0; anything else is refused by name.
The C<whiskers> switch belongs to L<#violin>, not to C<boxplot>.

=head3 single, simple plot

 my $x = generate_normal_dist( 100, 15, 3 * 10 );
 my $y = generate_normal_dist( 85,  15, 3 * 10 );
 my $z = generate_normal_dist( 106, 15, 3 * 10 );

single plots are simple

 use Matplotlib::Simple 'boxplot';
 boxplot(
     output_file => 'output.images/single.boxplot.png',
     data              => {                                     # simple hash
         E => [ 55,    @{$x}, 160 ],
         B => [ @{$y}, 140 ],
 
         #       A => @a
     },
     title        => 'Single Box Plot: Specified Colors',
     colors       => { E => 'yellow', B => 'purple' },
     fh           => $fh,
     execute      => 0,
 );

which makes the following image:


=for html
<p>
<img width="651" height="491" alt="single boxplot" src="https://github.com/user-attachments/assets/19870fa2-fe36-4513-8cbb-23da3a0cf686" />
<p>


=head3 multiple plots

 plt(
     output_file => 'output.images/boxplot.png',
     execute           => 0,
     fh                => $fh,
     plots             => [
         {
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Simple Boxplot',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             plot_type => 'boxplot',
             suptitle    => 'Boxplot examples'
         },
         {
             color => 'pink',
             data  => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Specify single color',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             plot_type => 'boxplot'
         },
         {
             colors => {
                 A => 'orange',
                 E => 'yellow',
                 B => 'purple'
             },
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Specify set-specific color; showfliers = False',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             plot_type => 'boxplot',
             showmeans   => 'True',
             showfliers  => 'False',
             set_figwidth => 12
         },
         {
             colors => {
                 A => 'orange',
                 E => 'yellow',
                 B => 'purple'
             },
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Specify set-specific color; showmeans = False',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             plot_type => 'boxplot',
             showmeans   => 'False',
         },
         {
             colors => {
                 A => 'orange',
                 E => 'yellow',
                 B => 'purple'
             },
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Set-specific color; orientation = horizontal',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             orientation => 'horizontal',
             plot_type => 'boxplot',
         },
         {
             colors => {
                 A => 'orange',
                 E => 'yellow',
                 B => 'purple'
             },
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title       => 'Notch = True',
             ylabel      => 'ylabel',
             xlabel      => 'label',
             notch       => 'True',
             plot_type => 'boxplot',
         },
         {
             colors => {
                 A => 'orange',
                 E => 'yellow',
                 B => 'purple'
             },
             data => {
                 A => [ 55, @{$z} ],
                 E => [ @{$y} ],
                 B => [ 122, @{$z} ],
             },
             title         => 'showcaps = False',
             ylabel        => 'ylabel',
             xlabel        => 'label',
             showcaps      => 'False',
             plot_type     => 'boxplot',
             set_figheight => 12,
         },
     ],
     ncols => 3,
     nrows => 3,
 );

which makes the following plot:


=for html
<p>
<img width="1230" height="1211" alt="boxplot" src="https://github.com/user-attachments/assets/7e32e394-86fc-49e7-ad97-f48fd82fc8b0" />
<p>


=head2 Colored Table

Plot a hash of hashes as a matrix, coloring each cell by its value.

=head3 Entering data

C<data> is a hash of hashes: the outer key is the row, the inner key is the
column, and the value is the number that picks the cell's color.

 colored_table(
     output_file => '/tmp/matrix.svg',
     data          => {
         H => { H => 432, Cl => 427, Br => 363 },
         C => { H => 413, Cl => 339, Br => 276 },
     },
 );

The matrix does not have to be complete.  Cells with no value are left out of
the color scale and drawn in C<undef_color> (gray by default), and a table that
only fills one triangle — the usual shape of a pairwise-comparison table — can
be completed by reflecting it across the diagonal with C<< mirror =E<gt> 1 >>, so that
C<$data{A}{B}> also supplies C<$data{B}{A}>.

The rows are the outer keys and the columns every inner key, each in sorted
order, so the table above has rows C and H and columns Br, Cl and H.  With
C<mirror>, which makes the table symmetric, rows and columns are both every key.
C<col_labels> chooses which keys are drawn and in what order, as the rows and the
columns both, which is how the bond-dissociation example below shows the
halogens only out of a larger table; C<row_labels> supplies the text down the
left-hand side, so it should list the same keys in the same order, and must have
one label per row.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>cb_logscale</code></td><td>color the cells on a log scale</td><td><code>cb_logscale => 1</code></td></tr>
<tr><td><code>cb_min</code>, <code>cb_max</code></td><td>clamp the ends of the color scale instead of taking them from the data, so several tables can be compared directly</td><td><code>cb_min => 100, cb_max => 500</code></td></tr>
<tr><td><code>cblabel</code></td><td>the label on the colorbar</td><td><code>cblabel => 'kJ/mol'</code></td></tr>
<tr><td><code>cmap</code></td><td>the colormap used for coloring the cells</td><td><code>cmap => 'viridis'</code></td></tr>
<tr><td><code>col_labels</code></td><td>array ref: which keys to draw, in order — this selects the rows and the columns of the matrix, not just the heading text</td><td><code>col_labels => ['H', 'F', 'Cl', 'Br', 'I']</code></td></tr>
<tr><td><code>colorbar_on</code></td><td>draw the colorbar; on by default, <code>0</code> turns it off, <code>cblabel</code> or no <code>cblabel</code></td><td><code>colorbar_on => 0</code></td></tr>
<tr><td><code>mirror</code></td><td>treat the table as symmetric: <code>$data{A}{B}</code> also fills <code>$data{B}{A}</code></td><td><code>mirror => 1</code></td></tr>
<tr><td><code>row_labels</code></td><td>array ref of the labels printed down the left side; give it the same keys, in the same order, as <code>col_labels</code></td><td><code>row_labels => ['H', 'F', 'Cl', 'Br', 'I']</code></td></tr>
<tr><td><code>show_numbers</code></td><td>print each cell's value in the cell; off by default</td><td><code>show_numbers => 1</code></td></tr>
<tr><td><code>undef_color</code></td><td>the color for cells that have no value; gray by default</td><td><code>undef_color => 'white'</code></td></tr>
<tr><td><code>default_undefined</code></td><td>the value a cell with no value takes, instead of being left empty.  It counts towards the color scale like any other value, so <code>undef_color</code> no longer applies to those cells</td><td><code>default_undefined => 0</code></td></tr>
</tbody>
</table>

The colorbar options in L<#color-bars-colorbars> — C<cbdrawedges>,
C<cblocation>, C<cborientation>, C<cbpad> — work here too.

=head3 Single, simple plot

the bond dissociation energy table can be plotted:

 # https://labs.chem.ucsb.edu/zakarian/armen/11---bonddissociationenergy.pdf and https://chem.libretexts.org/Bookshelves/Physical_and_Theoretical_Chemistry_Textbook_Maps/Supplemental_Modules_(Physical_and_Theoretical_Chemistry)/Chemical_Bonding/Fundamentals_of_Chemical_Bonding/Bond_Energies
 my %bond_dissociation = (
     Br =>  {
       Br =>  193
     },
     C  =>  {
         Br =>  276, C  =>  347, Cl =>  339, F   => 485, H  =>  413, I  =>  240,
         N  =>  305, O  =>  358, S  =>  259
     },
     Cl =>  {
         Br =>  218, Cl =>  239
     },
     F =>   {
         I => 280, Br =>  237, Cl  => 253, F   => 154
     },
     H  =>  {
         Br =>  363, Cl =>  427, F  =>  565, H   => 432, I   => 295
     },
     I  =>  {
         Br  => 175, Cl =>  208, I  =>  149
     },
     N  =>  {
         Br =>  243, Cl  => 200, F   => 272, H  =>  391, N  =>  160, O  =>  201
     },
     O =>   {
         Cl =>  203, F  =>  190, H  =>  467, I  =>  234, O  =>  146
     },
     S  =>  {
         Br => 218,  Cl => 253,  F  => 327,  H  => 347,  S  => 266
     },
     Si => {
         C  => 360, H  => 393, O  => 452,    Si => 340
     }
 );

and the plot itself:

 colored_table(
     'cblabel'     => 'kJ/mol',
     col_labels    => ['H', 'F', 'Cl', 'Br', 'I'],
     data          => \%bond_dissociation,
     execute       => 0,
     fh            => $fh,
     mirror        => 1,
     output_file => 'output.images/single.tab.png',
     row_labels    => ['H', 'F', 'Cl', 'Br', 'I'],
     show_numbers=> 1,
     set_title     => 'Bond Dissociation Energy'
 );

which makes the following image:


=for html
<p>
<img width="584" height="491" alt="single tab" src="https://github.com/user-attachments/assets/d890830b-a502-4d51-b118-20aeae0473e8" />
<p>


=head3 Multiple Plots

 plt(
     output_file => 'output.images/tab.multiple.png',
     execute       => 0,
     fh            => $fh,
     plots         => [
         {
             data          => \%bond_dissociation,
             plot_type     => 'colored_table',
             set_title     => 'No other options'
         },
         {
             data          => \%bond_dissociation,
             cblabel       => 'Average Dissociation Energy (kJ/mol)',
             col_labels    => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             mirror        => 1,
             plot_type     => 'colored_table',
             row_labels    => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             show_numbers=> 1,
             set_title     => 'Showing numbers and mirror with defined order'
         },
         {
             data          => \%bond_dissociation,
             cblabel       => 'Average Dissociation Energy (kJ/mol)',
             col_labels    => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             mirror        => 1,
             plot_type     => 'colored_table',
             row_labels    => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             show_numbers=> 1,
             set_title     => 'Set undefined color to white',
             undef_color => 'white'
         }
     ],
     ncols         => 3,
     set_figwidth  => 14,
     suptitle      => 'Colored Table options'
 );

which makes the following plot:


=for html
<p>
<img width="1410" height="491" alt="tab multiple" src="https://github.com/user-attachments/assets/be836742-cc5b-4618-a0c8-a0ee57856eb1" />
<p>


=head2 hexbin

Plot a hash of arrays as a hexbin
see https://matplotlib.org/stable/api/I<as>gen/matplotlib.pyplot.hexbin.html

A hexbin answers the question a scatterplot stops answering once there are tens
of thousands of points: instead of drawing every point and letting them pile up
into an indistinguishable blob, the plane is tiled with hexagons and each one is
colored by how many points fell inside it.

=head3 Entering data

C<data> is a hash of exactly B<two> array refs of equal length — the first key
(sorted) is the x-axis, the second is the y-axis, and both become the axis
labels.  Use C<key_order> to say which is which rather than relying on the sort:

 hexbin(
     output_file => '/tmp/hex.svg',
     data          => { Height => \@heights, Weight => \@weights },
     key_order     => [ 'Weight', 'Height' ],    # Weight on x
     cblabel       => 'people per cell',
 );

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td>cb_logscale</td><td>colorbar log scale <code>from matplotlib.colors import LogNorm</code></td><td>default 0, any value > 0 enables</td></tr>
<tr><td>cblabel</td><td>the label on the colorbar, i.e. what the cell counts mean; <code>Density</code> if not given</td><td><code>cblabel => 'observations'</code></td></tr>
<tr><td>cmap</td><td>The Colormap instance or registered colormap name used to map scalar data to colors</td><td>default <code>gist_rainbow</code></td></tr>
<tr><td>key_order</td><td>define the keys in an order (an array reference)</td><td><code>key_order => ['X-rays', 'Yak Butter'],</code></td></tr>
<tr><td>marginals</td><td>integer, by default off = 0</td><td><code>marginals => 1</code></td></tr>
<tr><td>mincnt</td><td>int >= 0, default: None; If not None, only display cells with at least mincnt number of points in the cell.</td><td><code>mincnt => 2</code></td></tr>
<tr><td>vmax</td><td>the cell count at the top of the color scale; taken from the data if not given</td><td><code>vmax => 50</code></td></tr>
<tr><td>vmin</td><td>the cell count at the bottom of the color scale; taken from the data if not given</td><td><code>vmin => 1</code></td></tr>
<tr><td>xbins</td><td>integer that accesses horizontal gridsize</td><td>default is 15</td></tr>
<tr><td>xscale_hexbin</td><td>'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the horizontal axis</td><td><code>xscale_hexbin => 'log'</code></td></tr>
<tr><td>ybins</td><td>integer that accesses vertical gridsize</td><td>default is 15</td></tr>
<tr><td>yscale_hexbin</td><td>'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the vertical axis</td><td><code>yscale_hexbin => 'log'</code></td></tr>
</tbody>
</table>

With C<cb_logscale>, C<vmin> and C<vmax> set the ends of the C<LogNorm> that draws
the log-scaled colorbar, as they do for C<hist2d>.

=head3 single, simple plot

 plt(
     data    => {
         E   => generate_normal_dist(100, 15, 3*210),
         B   => generate_normal_dist(85, 15, 3*210)
     },
     output_file     => 'output.images/single.hexbin.png',
     plot_type => 'hexbin',
     set_figwidth => 12,
     title           => 'Simple Hexbin',
 );

which makes the following plot:

=for html
<p>
<img width="1208" height="491" alt="single hexbin" src="https://github.com/user-attachments/assets/129c41cd-2d7d-43de-978a-2b9c441b8939" />
<p>


=head3 multiple plots

 plt(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/hexbin.png',
     plots             => [
         {
             data => {
             E => @e,
             B => @b
             },
             plot_type    => 'hexbin',
             title        => 'Simple Hexbin',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type => 'hexbin',
             title       => 'colorbar logscale',
             cb_logscale => 1
         },
         {
             cmap => 'jet',
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'cmap is jet',
             xlabel       => 'xlabel',
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             key_order    => ['E', 'B'],
             plot_type    => 'hexbin',
             title        => 'Switch axes with key_order',
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'vmax set to 25',
             vmax         => 25
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'vmin set to -4',
             vmin         => -4
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'mincnt set to 7',
             mincnt       => 7
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'xbins set to 9',
             xbins        => 9
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'ybins set to 9',
             ybins        => 9
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'marginals = 1',
             marginals    => 1
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'xscale_hexbin = 1',
             xscale_hexbin => 'log'
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'hexbin',
             title        => 'yscale_hexbin = 1',
             yscale_hexbin => 'log'
         },
     ],
     ncols        => 4,
     nrows        => 3,
     scale        => 5,
     suptitle     => 'Various Changes to Standard Hexbin: All data is the same'
 );

which produces the following image:

=for html
<p>
<img width="2409" height="3211" alt="hexbin" src="https://github.com/user-attachments/assets/0b23a0cb-8f9a-43fb-8da1-0debee13d540" />
<p>


=head2 hist

Plot a hash of arrays as a series of histograms, one per key, drawn over each
other in the same axes — C<alpha> defaults to 0.5 so that the overlaps stay
readable.  A single array ref is the one-set shorthand.  Values must be numeric:
unlike C<boxplot> and C<violin>, a non-numeric value here is an error.

Each set is binned separately, so with C<< bins =E<gt> 50 >> two sets covering different
ranges get 50 bins each over their own range rather than a common set of edges.
When the sets must line up exactly — which is what makes the bar heights
comparable — pass the edges themselves rather than a count:

 hist(
     output_file => '/tmp/hist.svg',
     data          => { E => \@e, B => \@b },
     bins          => [ map { 10 * $_ } 0 .. 20 ],    # shared edges, 0..200
 );

C<bins> and C<color> also accept a B<hash keyed by set>, for when one
distribution wants different treatment from the others:

     bins  => { E => 50, B => 20 },
     color => { E => 'orange', B => 'black' },

The legend is on by default when there is more than one set and off when there is
only one; C<show_legend> overrides that either way.

Every subplot drawn with C<hist> reports the range of its bin heights on STDOUT,
over all of the sets drawn into it, as

 plot 0 hist range = [1, 12]

where the number is the subplot's index — C<plot 1> is the second subplot of a
figure — and the range is C<[shortest bar, tallest bar]>.  The heights are
matplotlib's, counted as the figure is drawn: this module does not bin the data,
so there is no way to know them without asking.  Nothing about the figure
changes because they are reported; the file written to C<output_file> is the
same either way.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>alpha</code></td><td>opacity of the bars, default 0.5; the same value is used for all sets</td><td><code>alpha => 0.25</code></td></tr>
<tr><td><code>bins</code></td><td>int or sequence or str, default: :rc:<code>hist.bins</code>.  If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open.  May also be a hash keyed by set</td><td><code>bins => 50</code></td></tr>
<tr><td><code>color</code></td><td>either one color for every set, or a hash pairing each data key with its own color.  A key of the hash that is not a set of <code>data</code> is refused, and so is one of a <code>bins</code> hash</td><td><code>color => { X => 'blue', Y => 'orange' }</code></td></tr>
<tr><td><code>key_order</code></td><td>the order the sets are drawn in, and so the order of the legend; sorted by name by default</td><td><code>key_order => ['Y', 'X']</code></td></tr>
<tr><td><code>logscale</code></td><td>an array of the axes to put on a log scale, useful when one set is orders of magnitude rarer than another.  It must be an array reference — <code>logscale => 1</code> is an error</td><td><code>logscale => ['y']</code></td></tr>
<tr><td><code>orientation</code></td><td>{'vertical', 'horizontal'}, default: 'vertical'; one for every set, which share an axes</td><td><code>orientation => 'horizontal'</code></td></tr>
<tr><td><code>show_legend</code></td><td>on when <code>data</code> holds more than one set, off when it holds one; set it explicitly to override</td><td><code>show_legend => 0</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

as of version 0.26, single arrays can be given to C<hist> instead of a hash, simplifying the call:

 hist(
     data          => [0..9],
     output_file => '/tmp/hist.arr.svg',
 );

for slightly more complex data sets, hashes are taken:

 use Matplotlib::Simple 'hist';
 
 my @e = generate_normal_dist( 100, 15, 3 * 200 );
 my @b = generate_normal_dist( 85,  15, 3 * 200 );
 my @a = generate_normal_dist( 105, 15, 3 * 200 );
 
 hist(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/single.hist.png',
     data              => {
         E => @e,
         B => @b,
         A => @a,
     }
 );

which makes the following simple plot:


=for html
<p>
<img width="651" height="491" alt="single hist" src="https://github.com/user-attachments/assets/fafcf787-6c4f-4998-88c4-77a15d878fa6" />
<p>


=head3 multiple plots

 plt(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/histogram.png',
    set_figwidth => 15,
    suptitle          => 'hist Examples',
     plots             => [
         { # 1st subplot
             data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             plot_type => 'hist',
             alpha       => 0.25,
             bins        => 50,
             title       => 'alpha = 0.25',
             color       => {
                 B => 'Black',
                 E => 'Orange',
                 A => 'Yellow',
             },
             scatter => '['
               . join( ',', 22 .. 44 ) . '],['  # x coords
               . join( ',', 22 .. 44 )          # y coords
               . '], label = "scatter"',
             xlabel   => 'Value',
             ylabel   => 'Frequency',
         },
         { # 2nd subplot
             data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             plot_type => 'hist',
             alpha       => 0.75,
             bins        => 50,
             title       => 'alpha = 0.75',
             color       => {
                 B => 'Black',
                 E => 'Orange',
                 A => 'Yellow',
             },
             xlabel   => 'Value',
             ylabel   => 'Frequency',
         },
         { # 3rd subplot
             add               => [ # add secondary plots/graphs/methods
             { # 1st additional plot/graph
                 data              => {
                     'Gaussian'       => [
                         [40..150],
                         [map {150 * exp(-0.5*($_-100)**2)} 40..150]
                     ]
                 },
                 plot_type => 'plot',
                 set_options => {
                     'Gaussian' =>  'color = "red", linestyle = "dashed"'
                 }
             }
             ],
            data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             plot_type => 'hist',
             alpha       => 0.75,
             bins        => {
                 A => 10,
                 B => 25,
                 E => 50
             },
             title => 'Varying # of bins',
             color => {
                 B => 'Black',
                 E => 'Orange',
                 A => 'Yellow',
             },
             xlabel       => 'Value',
             ylabel       => 'Frequency',
         },
         {# 4th subplot
             data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             plot_type => 'hist',
             alpha       => 0.75,
             color       => {
                 B => 'Black',
                 E => 'Orange',
                 A => 'Yellow',
             },
             orientation  => 'horizontal',    # assign x and y labels smartly
             title        => 'Horizontal orientation',
             ylabel       => 'Value',
             xlabel       => 'Frequency',                #               'log'                   => 1,
         },
     ],
     ncols => 3,
     nrows => 2,
 );


=for html
<p>
<img width="1511" height="491" alt="histogram" src="https://github.com/user-attachments/assets/b13b4cc8-6e64-40b0-913d-6a5886cee0db" />
<p>


=head2 hist2d

Make a 2-D histogram from a hash of arrays: like L<#hexbin>, C<data> is
a hash of exactly B<two> equal-length array refs, the first (sorted) key giving
the x-axis and the second the y-axis, and the plane is divided into rectangular
cells colored by how many points landed in each.  C<hexbin> and C<hist2d> are
interchangeable on the same data — hexagons tile the plane without the visual
grid artefacts of squares, while square bins are easier to read off against the
axes.

=head3 single, simple plot

 plt(
     output_file => 'output.images/single.hist2d.png',
     data              => {
         E => @e,
         B => @b
     },
     plot_type    => 'hist2d',
     title        => 'title',
     execute      => 0,
     fh => $fh,
 );

makes the following image:


=for html
<p>
<img width="650" height="491" alt="single hist2d" src="https://github.com/user-attachments/assets/86480c77-7b8f-4bfa-b5d8-71f82830260f" />
<p>


the range for the density min and max is reported to stdout

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>cb_logscale</code></td><td>make the colorbar log-scale</td><td><code>cb_logscale => 1</code></td></tr>
<tr><td><code>cblabel</code></td><td>the label on the colorbar, i.e. what the cell counts mean; <code>Density</code> if not given</td><td><code>cblabel => 'observations'</code></td></tr>
<tr><td><code>cmap</code></td><td>color map for coloring # "gist_rainbow" by default</td><td></td></tr>
<tr><td>'cmax', <code>cmin</code></td><td>All bins that has count < *cmin* or > *cmax* will not be displayed.  <code>cmin => 1</code> is the usual way to leave empty cells blank instead of coloring them as zero</td><td><code>cmin => 1</code></td></tr>
<tr><td>'density'</td><td>density : bool, default: False; normalise the counts so the plot shows a probability density instead of raw counts, which is what makes two plots of different-sized samples comparable</td><td><code>density => 'True'</code></td></tr>
<tr><td>'key_order'</td><td>define the keys in an order (an array reference), i.e. which key is the x-axis</td><td><code>key_order => ['Y', 'X']</code></td></tr>
<tr><td>'logscale'</td><td>an array of the axes that will get a log scale</td><td><code>logscale => ['x']</code></td></tr>
<tr><td>'show_colorbar'</td><td>self-evident, 0 or 1; a synonym for <code>colorbar_on</code>, either of which suppresses the colorbar (before 0.3132 only this one did)</td><td><code>show_colorbar</code> => 0</td></tr>
<tr><td>'vmax'</td><td>When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover</td><td></td></tr>
<tr><td>'vmin'</td><td># When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover</td><td></td></tr>
<tr><td>'xbins'</td><td># default 15</td><td></td></tr>
<tr><td>'xmin', 'xmax',</td><td></td><td></td></tr>
<tr><td>'ymin', 'ymax',</td><td></td><td></td></tr>
<tr><td>'ybins'</td><td>default 15</td><td></td></tr>
</tbody>
</table>

=head3 multiple plots

 plt(
     fh => $fh,
     execute           => 1,
     ncols             => 3,
     nrows             => 3,
     suptitle          => 'Types of hist2d plots: all of the data is identical',
     plots => [
         {
             data => {
             X => $x,    # x-axis
             Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'Simple hist2d',
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'cmap = terrain',
             cmap        => 'terrain'
         },
         {
             cmap => 'ocean',
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title => 'cmap = ocean and set colorbar range with vmin/vmax',
             set_figwidth => 15,
             vmin         => -2,
             vmax         => 14
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'density = True',
             cmap        => 'terrain',
             density     => 'True'
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'key_order flips axes',
             cmap        => 'terrain',
             key_order => [ 'Y', 'X' ]
         },
         {
             cb_logscale => 1,
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'cb_logscale = 1',
         },
         {
             cb_logscale => 1,
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type => 'hist2d',
             title       => 'cb_logscale = 1 with vmax set',
             vmax        => 2.1,
             vmin        => 1
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type       => 'hist2d',
             show_colorbar => 0,
             title           => 'no colorbar',
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             plot_type       => 'hist2d',
             title           => 'xbins = 9',
             xbins           => 9
         },
     ],
     output_file => 'output.images/hist2d.png',
 );

makes the following image:


=for html
<p>
<img width="1510" height="491" alt="hist2d" src="https://github.com/user-attachments/assets/3d6becd3-44f3-4511-8b0f-eae39bc325fa" />
<p>


=head2 imshow

Plot 2D array of numbers as an image

=head3 Entering data

C<data> is a 2-D array — an array of array refs — and nothing else; a hash is an
error.  The generated call leaves Matplotlib's C<origin> at its default, so row
C<0> is drawn at the B<top>; use C<invert_yaxis> if your first row is meant to be
the bottom of the picture:

 my @grid;
 foreach my $i (0 .. 360) {
     foreach my $j (0 .. 360) {
         push @{ $grid[$i] }, sin($i * $pi/180) * cos($j * $pi/180);
     }
 }
 imshow(
     output_file => '/tmp/grid.svg',
     data          => \@grid,
     cblabel       => 'sin(x) * cos(x)',
 );

The cells may hold B<strings> instead of numbers, as long as C<stringmap> gives
the meaning of each one — without it, non-numeric data is an error.  Each string
is assigned an integer, the image is drawn with one discrete color per string,
and the colorbar's ticks are labelled with the names from C<stringmap> rather than
with numbers.  (C<cmap> is dropped, with a warning, when strings are in play,
since the palette has to be a discrete one.)  This is what makes C<imshow> usable
for categorical rasters — sequence annotation, land cover, state-over-time
diagrams — and there is a worked example under
L<#secondary-structure-prediction-dssp>.

Because C<imshow> produces a colorbar per subplot, C<shared_colorbar> is often
worth setting when several panels show the same quantity: it gives them one
colorbar, and hence one color scale, so the panels can be compared.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>cblabel</code></td><td>colorbar label</td><td><code>cblabel => 'sin(x) * cos(x)',</code></td></tr>
<tr><td><code>cbdrawedges</code></td><td>draw edges for colorbar</td><td></td></tr>
<tr><td><code>cblocation</code></td><td>'left', 'right', 'top', 'bottom'</td><td><code>cblocation => 'left',</code></td></tr>
<tr><td><code>cborientation</code></td><td>None, or 'vertical', 'horizontal'</td><td></td></tr>
<tr><td><code>cbpad</code></td><td>fraction of the original axes between the image and the colorbar; the default 0.05 is often too big for a short, wide image</td><td><code>cbpad => 0.01,</code></td></tr>
<tr><td><code>cmap</code></td><td># The Colormap instance or registered colormap name used to map scalar data to colors.</td><td></td></tr>
<tr><td><code>colorbar_on</code></td><td>draw the colorbar; on by default, <code>0</code> turns it off</td><td><code>colorbar_on => 0</code></td></tr>
<tr><td><code>shared_colorbar</code></td><td>0-based indices of the subplots that should share one colorbar, and therefore one color scale</td><td><code>shared_colorbar => [0,1]</code></td></tr>
<tr><td><code>stringmap</code></td><td>a hash giving the meaning of each string used in <code>data</code>, which also makes string data legal</td><td><code>stringmap => { H => 'Alpha helix' }</code></td></tr>
<tr><td><code>vmax</code></td><td>float</td><td></td></tr>
<tr><td><code>vmin</code></td><td>float</td><td></td></tr>
</tbody>
</table>

=head3 single, simple plot

 my @imshow_data;
 foreach my $i (0..360) {
     foreach my $j (0..360) {
         push @{ $imshow_data[$i] }, sin($i * $pi/180)*cos($j * $pi/180);
     }
 }
 plt(
     data              => \@imshow_data,
     execute           => 0,
    fh => $fh,
     output_file => 'output.images/imshow.single.png',
     plot_type         => 'imshow',
     set_xlim          => '0, ' . scalar @imshow_data,
     set_ylim          => '0, ' . scalar @imshow_data,
 );

which makes the following image:


=for html
<p>
<img width="599" height="491" alt="imshow single" src="https://github.com/user-attachments/assets/3fa4ffe6-4817-4133-9c91-b68099400377" />
<p>


=head3 multiple plots

 plt(
     plots  => [
         {
             data => \@imshow_data,
             plot_type         => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'basic',
         },
         {
             cblabel           => 'sin(x) * cos(x)',
             data => \@imshow_data,
             plot_type         => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'cblabel',
         },
         {
             cblabel           => 'sin(x) * cos(x)',
             cblocation        => 'left',
             data              => \@imshow_data,
             plot_type         => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'cblocation = left',
         },
         {
             cblabel           => 'sin(x) * cos(x)',
             data              => \@imshow_data,
             add               => [ # add secondary plots
             { # 1st additional plot
                 data              => {
                     'sin(x)'       => [
                         [0..360],
                         [map {180 + 180*sin($_ * $pi/180)} 0..360]
                     ],
                     'cos(x)'       => [
                         [0..360],
                         [map {180 + 180*cos($_ * $pi/180)} 0..360]
                     ],
                 },
                 plot_type => 'plot',
                 set_options => {
                     'sin(x)'    =>  'color = "red", linestyle = "dashed"',
                     'cos(x)'    =>  'color = "blue", linestyle = "dashed"',
                 }
             }
             ],
             plot_type         => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'auxiliary plots',
         },
     ],
     execute         => 0,
   fh              => $fh,
     output_file     => 'output.images/imshow.multiple.png',
     ncols           => 2,
     nrows           => 2,
     set_figheight   => 6*3,# 4.8
     set_figwidth    => 6*4 # 6.4
 );

which makes the following image:


=for html
<p>
<img width="2416" height="1811" alt="imshow multiple" src="https://github.com/user-attachments/assets/091acccb-151c-47ca-82cc-99c19d2bff91" />
<p>


=head3 Secondary Structure Prediction (DSSP)

Sometimes strings instead of numbers can be entered into a 2-D array, one example is protein secondary structure.
Protein secondary structure can be plotted thus, with a key in C<stringmap> to show which strings become which integers in a minimal working example:

 plt(
     cbpad       => 0.01,          # default 0.05 is too big
     data        => [              # imshow gets a 2D array
         [' ', ' ', ' ', ' ', 'G'], # bottom
         ['S', 'I', 'T', 'E', 'H'], # top
     ],
     plot_type => 'imshow',
     stringmap   => {
         'H' => 'Alpha helix',
         'B' => 'Residue in isolated β-bridge',
         'E' => 'Extended strand, participates in β ladder',
         'G' => '3-helix (3/10 helix)',
         'I' => '5 helix (pi helix)',
         'T' => 'hydrogen bonded turn',
         'S' => 'bend',
         ' ' => 'Loops and irregular elements'
     },
     output_file => 'output.images/dssp.single.png',
     scalex        => 2.4,
     set_ylim      => '0, 1',
     title         => 'Dictionary of Secondary Structure in Proteins (DSSP)',
     xlabel        => 'xlabel',
     ylabel        => 'ylabel'
 );


=for html
<p>
<img width="1547" height="491" alt="dssp single" src="https://github.com/user-attachments/assets/712f6199-4a41-4d8f-953e-19df9dacc447" />
<p>


or for multiple plots, where the colorbar can be spread across multiple plots now:

 plt(
     cbpad       => 0.01,          # default 0.05 is too big
     plots       => [
         { # 1st plot
             data    => [
                 [' ', ' ', ' ', ' ', 'G'], # bottom
                 ['S', 'I', 'T', 'E', 'H'], # top
             ],
             plot_type => 'imshow',
             set_xticklabels=> '[]', # remove x-axis labels
             set_ylim    => '0, 1',
             stringmap   => {
                 'H' => 'Alpha helix',
                 'B' => 'Residue in isolated β-bridge',
                 'E' => 'Extended strand, participates in β ladder',
                 'G' => '3-helix (3/10 helix)',
                 'I' => '5 helix (pi helix)',
                 'T' => 'hydrogen bonded turn',
                 'S' => 'bend',
                 ' ' => 'Loops and irregular elements'
             },
             title         => 'top plot',
             ylabel        => 'ylabel'
         },
         { # 2nd plot
             data    => [
                 [' ', ' ', ' ', ' ', 'G'], # bottom
                 ['S', 'I', 'T', 'E', 'H'], # top
             ],
             plot_type => 'imshow',
             set_ylim    => '0, 1',
             stringmap   => {
                 'H' => 'Alpha helix',
                 'B' => 'Residue in isolated β-bridge',
                 'E' => 'Extended strand, participates in β ladder',
                 'G' => '3-helix (3/10 helix)',
                 'I' => '5 helix (pi helix)',
                 'T' => 'hydrogen bonded turn',
                 'S' => 'bend',
                 ' ' => 'Loops and irregular elements'
             },
             title         => 'bottom plot',
             xlabel        => 'xlabel',
             ylabel        => 'ylabel'
         }
     ],
     nrows             => 2,
     output_file       => 'output.images/dssp.multiple.png',
     scalex            => 2.4,
     shared_colorbar => [0,1], # plots 0 and 1 share a colorbar
     suptitle          => 'Dictionary of Secondary Structure in Proteins (DSSP)',
 );

which makes the following plot:


=for html
<p>
<img width="1547" height="491" alt="dssp multiple" src="https://github.com/user-attachments/assets/d88e295e-1d1e-4e2a-bd5b-48029c46f5b0" />
<p>


=head2 pie

Plot a hash of numbers as a pie chart: one wedge per key, sized by its share of
the total.  C<data> is the same simple hash that C<bar> takes, so the two are
interchangeable — reach for C<pie> when the reader should see parts of a whole,
and for C<bar> when they should compare the parts with each other.

Wedges are laid out in sorted key order unless C<key_order> says otherwise, and
a C<key_order> that names only some of the keys draws only those wedges.  No
legend is added — the wedges carry their own labels — so C<show_legend> is not
among the options C<pie> accepts.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>autopct</code></td><td>a Python format string for the share printed inside each wedge; omit it and no numbers are drawn</td><td><code>autopct => '%1.1f%%'</code></td></tr>
<tr><td><code>key_order</code></td><td>array ref: the order the wedges are laid out in.  Naming only some of the keys draws only those wedges</td><td><code>key_order => ['Fri','Sat','Sun']</code></td></tr>
<tr><td><code>labeldistance</code></td><td>where the key label sits, as a fraction of the radius: <code>0</code> is the centre, <code>1</code> the edge, above <code>1</code> outside the pie</td><td><code>labeldistance => 0.6</code></td></tr>
<tr><td><code>pctdistance</code></td><td>the same scale, for the <code>autopct</code> text.  Swapping the two — labels in, percentages out — is a readable arrangement when the labels are long</td><td><code>pctdistance => 1.25</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

 plt(
     output_file => 'output.images/single.pie.png',
     data              => {                                 # simple hash
         Fri => 76,
         Mon => 73,
         Sat => 26,
         Sun => 11,
         Thu => 94,
         Tue => 93,
         Wed => 77
     },
     plot_type    => 'pie',
     title        => 'Single Simple Pie',
     fh           => $fh,
     execute      => 0,
 );

which makes the image:


=for html
<p>
<img width="469" height="491" alt="single pie" src="https://github.com/user-attachments/assets/a0bc3212-d013-463a-9be6-f96829ac7dba" />
<p>


=head3 multiple plots

 plt(
     output_file => 'output.images/pie.png',
     plots             => [
         {
             data => {
                 'Russian' => 106_000_000,    # Primarily European Russia
                 'German'  =>
                   95_000_000,    # Germany, Austria, Switzerland, etc.
                 'English' => 70_000_000,      # UK, Ireland, etc.
                 'French' => 66_000_000, # France, Belgium, Switzerland, etc.
                 'Italian'   => 59_000_000,    # Italy, Switzerland, etc.
                 'Spanish'   => 45_000_000,    # Spain
                 'Polish'    => 38_000_000,    # Poland
                 'Ukrainian' => 32_000_000,    # Ukraine
                 'Romanian'  => 24_000_000,    # Romania, Moldova
                 'Dutch'     => 22_000_000     # Netherlands, Belgium
             },
             plot_type => 'pie',
             title       => 'Top Languages in Europe',
             suptitle    => 'Pie in subplots',
         },
         {
             data => {
                 'Russian' => 106_000_000,     # Primarily European Russia
                 'German'  =>
                   95_000_000,    # Germany, Austria, Switzerland, etc.
                 'English' => 70_000_000,      # UK, Ireland, etc.
                 'French' => 66_000_000, # France, Belgium, Switzerland, etc.
                 'Italian'   => 59_000_000,    # Italy, Switzerland, etc.
                 'Spanish'   => 45_000_000,    # Spain
                 'Polish'    => 38_000_000,    # Poland
                 'Ukrainian' => 32_000_000,    # Ukraine
                 'Romanian'  => 24_000_000,    # Romania, Moldova
                 'Dutch'     => 22_000_000     # Netherlands, Belgium
             },
             plot_type => 'pie',
             title       => 'Top Languages in Europe',
             autopct     => '%1.1f%%',
         },
         {
             data => {
                 'United States'  => 86,
                 'United Kingdom' => 33,
                 'Germany'        => 29,
                 'France'         => 10,
                 'Japan'          => 7,
                 'Israel'         => 6,
             },
             title         => 'Chem. Nobels: swap text positions',
             plot_type     => 'pie',
             autopct       => '%1.1f%%',
             pctdistance   => 1.25,
             labeldistance => 0.6,
         }
     ],
     fh => $fh,
     execute      => 0,
    set_figwidth  => 12,
     ncols        => 3,
 );


=for html
<p>
<img width="1210" height="444" alt="pie" src="https://github.com/user-attachments/assets/4c44d300-fd84-49bc-9a32-b73af54286cf" />
<p>


=head2 plot

A line plot of one or more series of C<(x, y)> points. Each series needs an
x array and a y array of B<equal length>, or, in the hash form, may give the y
values alone and have x made for it.

=head3 Entering data

C<data> accepts four shapes:

B<1. Labeled series (hash).> Use this when you want a legend — each key
becomes a line label. The value is a C<[ \@x, \@y ]> pair:

 {
     plot_type => 'plot',
     data        => {
         A => [ [5..9], [5..9] ],
         B => [ [5..9], [1..5] ],
     },
 }

B<2. Several unlabeled series (array of pairs).> A list of C<[ \@x, \@y ]>
pairs, one per line, with no legend labels:

 {
     plot_type => 'plot',
     data        => [
         [ [5..9], [5..9] ],
         [ [5..9], [1..5] ],
     ],
 }

B<3. A single unlabeled series (two bare arrays).> The simplest form: just
the x array and the y array, with no enclosing pair-array and no key:

 {
     plot_type => 'plot',
     data        => [
         [5..9],
         [5..9],
     ],
 }

Form 3 is shorthand for form 2 with a single line — it is promoted internally
to C<[ [ \@x, \@y ] ]>. Because there is no key, the line is B<unlabeled>; if
you need a legend entry, use the hash form (1).

 > How the forms are told apart: in the multi-line form (2) C<< data-E<gt>[0] >> is itself
 > a C<[ \@x, \@y ]> pair, so C<< data-E<gt>[0][0] >> is an array ref; in the single-line
 > form (3) C<< data-E<gt>[0] >> is the x array, so C<< data-E<gt>[0][0] >> is a number. A 2-element
 > C<data> whose first element starts with a number is therefore always read as a
 > single line.

B<4. Labeled y values alone (hash).> When the x values are only the positions
0, 1, 2, …, give each key a plain array of y values and leave x out:

 plt(
     output_file => 'output.images/plot.y.only.png',
     data        => {    # y values only: x is 0, 1, 2, ... for each
         '1cka' => [ 0.86, 0.85, 0.85, 0.85, 0.85 ],
         '1ckb' => [ 0.81, 0.8,  0.79, 0.78, 0.77 ],
         '1d4t' => [ 0.92, 0.92, 0.92, 0.92, 0.91 ],
     },
     plot_type  => 'plot',
     title      => 'y values only',
     xlabel     => 'index',
     ylabel     => 'score',
     set_xticks => '[0, 1, 2, 3, 4]',
 );

which makes


=for html
<p>
<img width="651" height="491" alt="plot of y values only" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/plot.y.only.png" />
<p>


Each key's x is C<0 .. n-1> for its own C<n> values, so the series need not be the
same length. A key's value is read as y alone when B<none> of its elements is
an array, and as an C<[ \@x, \@y ]> pair when they all are; the two forms can be
mixed from key to key in one C<data> hash, but a value that mixes arrays with
plain numbers is refused. This form is for hash data only: in array data, two
plain arrays are already the single unlabeled line of form 3, with x and y.

=head3 Setting line options with C<set_options>

C<set_options> is passed straight through to Matplotlib's C<.plot(x, y, ...)>,
so anything C<plot> accepts works (C<color>, C<linewidth>, C<linestyle>, C<marker>,
C<alpha>, …). How you supply it depends on the data shape:

B<A scalar applies to every line.> This is the natural partner of the
single-line data form — the one option string is used for the only series:

 {
     plot_type     => 'plot',
     show_legend => 0,
     data          => [
         [ min(vals($df, 'experiment')) .. max(vals($df, 'experiment')) ],
         [ min(vals($df, 'experiment')) .. max(vals($df, 'experiment')) ],
     ],
     set_options => 'color = "red"',
 }

The same scalar also works with the multi-line array form, where it is applied
to B<all> lines at once:

 {
     plot_type     => 'plot',
     data          => [
         [ [5..9], [5..9] ],
         [ [5..9], [1..5] ],
     ],
     set_options => 'linewidth = 2',    # both lines
 }

B<An array sets options per line (positional).> With array data, give one
string per line; entry C<i> styles line C<i>. You may supply fewer entries than
lines, but not more:

 {
     plot_type     => 'plot',
     data          => [
         [ [5..9], [5..9] ],
         [ [5..9], [1..5] ],
     ],
     set_options => [
         'color = "red"',
         'color = "blue", linestyle = "--"',
     ],
 }

B<A hash sets options per key.> With hash data, key the options by the same
data keys (any key may be omitted):

 {
     plot_type     => 'plot',
     data          => {
         A => [ [5..9], [5..9] ],
         B => [ [5..9], [1..5] ],
     },
     set_options => {
         A => 'color = "red"',
         B => 'color = "blue", marker = "o"',
     },
 }

Note the pairing rule: a scalar C<set_options> goes with B<any> data shape; an
B<array> C<set_options> goes with B<array> data; a B<hash> C<set_options> goes
with B<hash> data. Mismatches (for example a hash of options with array data)
are rejected with an explanatory error.

=head3 Other options

=over

=item * C<show_legend> — on by default (C<1>); set to C<0> to suppress labels. Only the
hash form produces labels in the first place.

=item * C<key_order> — array of keys (hash form) fixing the draw/legend order; defaults
to the keys sorted alphabetically.

=item * C<logscale> — array of axes to put on a log scale, e.g. C<[ 'x', 'y' ]>.

=item * C<twinx> — draw selected series against a secondary y-axis.

=over

=item * hash data: a single key, or a hash whose keys are the series to twin;

=item * array data: an integer index, or an array of indices.

=back

=item * C<twinx_args> — a hash keyed by data key (hash form) or index (array form);
each value is a hash of axis options (e.g. C<ylabel>, C<set_ylim>) applied to
that twin axis.

=back

Common axes options such as C<title>, C<xlabel>, C<ylabel>, and C<legend> are
accepted here too, exactly as for the other plot types.

=head3 Two y-axes with C<twinx>

Series measured in different units, or on wildly different scales, flatten each
other when they share a y-axis.  C<twinx> moves the named series onto a second
y-axis on the right, and C<twinx_args> labels it:

 plt(
     output_file => '/tmp/twinx.svg',
     plot_type     => 'plot',
     data          => {
         Temperature => [ [@t], [@celsius] ],
         Pressure    => [ [@t], [@hPa]     ],
     },
     twinx         => 'Pressure',                        # onto the right axis
     twinx_args    => { Pressure => { ylabel => 'hPa' } },
     ylabel        => 'degrees C',                       # the left axis
     xlabel        => 'hour',
 );

C<< twinx =E<gt> 'Pressure' >> is shorthand for the single-series case.  To twin more than
one series, pass a hash whose keys are the series to move:

 twinx => { Pressure => 1, Humidity => 1 },

The twinned series share the one right-hand axis, so a C<twinx_args> of each
applies to that axis.  Every series, on either axis, is listed in the one
legend.  Up to 0.318 each twinned series had a right-hand axis of its own, with
limits of its own and its ticks drawn over the others', and none of them was in
the legend.

With array data the same options are given by index instead of by key:

 plt(
     output_file => '/tmp/twinx.arr.svg',
     plot_type     => 'plot',
     data          => [
         [ [@t], [@celsius] ],    # index 0, left axis
         [ [@t], [@hPa]     ],    # index 1
     ],
     twinx         => 1,                              # index 1 goes right
     twinx_args    => { 1 => { ylabel => 'hPa' } },
 );

An index past the last line is refused.

A C<plot> spec is an ordinary plot hash, so it can be dropped straight into the
L<#the-p-argument> argument — on its own for a single subplot, or alongside
other hashes to overlay or to fill a grid of subplots.

=head3 single, simple

data can be given as a hash, where the hash key is the label:

 plt(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/plot.single.png',
     data              => {
         'sin(x)' => [
             [@x],                     # x
             [ map { sin($_) } @x ]    # y
         ],
         'cos(x)' => [
             [@x],                     # x
             [ map { cos($_) } @x ]    # y
         ],
     },
     plot_type => 'plot',
     title       => 'simple plot',
     set_xticks  =>
     "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
      . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
     set_options => {    # set options overrides global settings
         'sin(x)' => 'color="blue", linewidth=2',
         'cos(x)' => 'color="red",  linewidth=2'
     }
 );

or as an array of arrays:

 plt(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/plot.single.arr.png',
     data              => [
         [
             [@x],                     # x
             [ map { sin($_) } @x ]    # y
         ],
         [
             [@x],                     # x
             [ map { cos($_) } @x ]    # y
         ],
     ],
     plot_type => 'plot',
     title       => 'simple plot',
     set_xticks  =>
     "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
      . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
     set_options => [    # set options overrides global settings; indices match data array
         'color="blue", linewidth=2, label = "sin(x)"', # labels aren't added automatically when using array here
         'color="red",  linewidth=2, label = "cos(x)"'
     ],
 );

both of which make the following "plot" plot:


=for html
<p>
<img width="651" height="491" alt="plot single" src="https://github.com/user-attachments/assets/6cbd6aad-c464-4703-b962-b420ec08bb66" />
<p>


=head3 multiple sub-plots

which makes

 my $epsilon = 10**-7;
 my (%set_opt, %d);
 my $i = 0;
 foreach my $interval (
     [-2*$pi, -$pi],
     [-$pi, 0],
     [0, $pi],
     [$pi, 2*$pi]
 ) {
     my @th = linspace($interval->[0] + $epsilon, $interval->[1] - $epsilon, 99, 0);
     @{ $d{csc}{$i}[0] } = @th;
     @{ $d{csc}{$i}[1] } = map { 1/sin($_) } @th;
     @{ $d{cot}{$i}[0] } = @th;
     @{ $d{cot}{$i}[1] } = map { cos($_)/sin($_) } @th;
     if ($i == 0) {
         $set_opt{csc}{$i} = 'color = "red", label = "csc(θ)"';
         $set_opt{cot}{$i} = 'color = "violet", label = "cot(θ)"';
     } else {
         $set_opt{csc}{$i} = 'color = "red"';
         $set_opt{cot}{$i} = 'color = "violet"';
     }
     $i++;
 }
 $i = 0;
 foreach my $interval (
     [-2 * $pi, -1.5 * $pi],
     [-1.5*$pi, -0.5*$pi],
     [-0.5*$pi, 0.5 * $pi],
     [0.5 * $pi, 1.5 * $pi],
     [1.5 * $pi, 2 * $pi]
 ) {
     my @th = linspace($interval->[0] + $epsilon, $interval->[1] - $epsilon, 99, 0);
     @{ $d{sec}{$i}[0] } = @th;
     @{ $d{sec}{$i}[1] } = map { 1/cos($_) } @th;
     if ($i == 0) {
         $set_opt{sec}{$i} = 'color = "blue", label = "sec(θ)"';
         $set_opt{tan}{$i} = 'color = "green", label = "tan(θ)"';
     } else {
         $set_opt{sec}{$i} = 'color = "blue"';
         $set_opt{tan}{$i} = 'color = "green"';
     }
     @{ $d{tan}{$i}[0] } = @th;
     @{ $d{tan}{$i}[1] } = map { sin($_)/cos($_) } @th;
     $i++;
 }
 mkdir 'svg' unless -d 'svg';
 my $xticks = "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
         . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']';
 my ($min, $max) = (-9,9);
 plt(
     fh => $fh,
     execute           => 0,
     output_file => 'output.images/plots.png',
     plots         => [
     { # sin
         data          => {
             'sin(θ)' => [
                 [@x],
                 [map {sin($_)} @x]
             ]
         },
         plot_type     => 'plot',
         set_options => {
             'sin(θ)' => 'color = "orange"'
         },
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         xlabel        => 'θ',
         ylabel        => 'sin(θ)',
     },
     { # sin
         data          => {
             'cos(θ)' => [
                 [@x],
                 [map {cos($_)} @x]
             ]
         },
         plot_type     => 'plot',
         set_options => {
             'cos(θ)' => 'color = "black"'
         },
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         xlabel        => 'θ',
         ylabel        => 'cos(θ)',
     },
     { # csc
         data          => $d{csc},
         plot_type     => 'plot',
         set_options => $set_opt{csc},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         show_legend => 0,
         vlines        => [ # asymptotes
             "-2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "-$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "0, $min, $max, color = 'gray', linestyle = 'dashed'",
             "$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
         ],
         xlabel        => 'θ',
         ylabel        => 'csc(θ)',
     },
     { # sec
         data          => $d{sec},
         plot_type     => 'plot',
         set_options => $set_opt{sec},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         show_legend => 0,
         vlines        => [ # asymptotes
             "-1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "-.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             ".5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
 #           "2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
         ],
         xlabel        => 'θ',
         ylabel        => 'sec(θ)',
     },
         { # csc
         data          => $d{cot},
         plot_type     => 'plot',
         set_options => $set_opt{cot},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         show_legend => 0,
         vlines        => [ # asymptotes
             "-2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "-$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "0, $min, $max, color = 'gray', linestyle = 'dashed'",
             "$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
         ],
         xlabel        => 'θ',
         ylabel        => 'cot(θ)',
     },
     { # sec
         data          => $d{tan},
         plot_type     => 'plot',
         set_options => $set_opt{tan},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         show_legend => 0,
         vlines        => [ # asymptotes
             "-1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "-.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             ".5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
             "1.5*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
 #           "2*$pi, $min, $max, color = 'gray', linestyle = 'dashed'",
         ],
         xlabel        => 'θ',
         ylabel        => 'tan(θ)',
     },
     ], # end
     ncols        => 2,
     nrows        => 3,
     set_figwidth => 8,
     suptitle     => 'Basic Trigonometric Functions'
 );


=for html
<p>
<img width="811" height="491" alt="plots" src="https://github.com/user-attachments/assets/0bdd0744-c1bb-4c4a-9482-b3de3f2d4fc2" />
<p>


=head2 scatter

Plot points from a hash of arrays.  Beyond x and y, a scatterplot can carry a
third number per point as B<color>, which is where most of C<scatter>'s options
go.

=head3 Entering data

C<data> takes three shapes, and which one you passed is worked out from whether the
values are arrays or hashes.

B<1. One set (hash of 2 or 3 array refs).> All the arrays must be the same
length.  Keys are taken in case-insensitive sorted order: the first is x, the
second y, and a third — if present — is the value each point is colored by, which
also gets a colorbar.  Exactly 2 or 3 keys are allowed; anything else is an
error.  The keys become the axis labels, so naming them for the quantity they
hold pays off:

 scatter(
     output_file => '/tmp/scatter.svg',
     data          => {
         Height => \@height,    # x
         Weight => \@weight,    # y
         Age    => \@age,       # colour + colorbar
     },
     color_key     => 'Age',    # say so rather than relying on the sort
     cmap          => 'viridis',
 );

Sorted order is convenient but fragile — rename a key and the axes swap.  Use
C<keys> to fix the roles positionally, or C<color_key> to name the color column
explicitly, as above:

     keys => [ 'Weight', 'Height', 'Age' ],    # x, y, colour

B<2. Several labelled sets (hash of hashes of array refs).> The outer key is
the set's legend label; each inner hash is a set of 2 or 3 arrays read exactly as
in form 1.  This is the form to use for "the same measurement, split by group":

 scatter(
     output_file => '/tmp/by.group.svg',
     data          => {
         Male   => { Height => \@mh, Weight => \@mw },
         Female => { Height => \@fh, Weight => \@fw },
     },
     set_options => {
         Male   => 'marker = "v", color = "blue"',
         Female => 'marker = "o", color = "red"',
     },
 );

With three inner keys, every set is colored by its own third column, on one
scale running from the smallest to the largest color value of all the sets, and
the figure gets a single colorbar for that scale.  A set whose C<set_options>
give their own C<vmin>, C<vmax> or C<norm> keeps them instead.  Since color then says nothing about which set a point belongs to, each such set is drawn with its own marker -- C<o>, C<s>, C<^>, C<D>, C<v> and on, in the sorted order of the set names -- unless its C<set_options> name a C<marker>, which no other set is then given.  C<color_key>
then names an B<inner> key, and it must exist in every set: naming a key that is
not there is an error rather than being quietly ignored.

B<3. One point per set (hash of hashes of numbers).> An inner hash whose values
are all plain numbers is a single point, read as in form 2 and labelled with the
set's name in the legend.  This suits one summary per group, such as the scores
of several models:

 scatter(
     output_file => '/tmp/models.svg',
     data          => {
         catboost   => { MAE => 0.41, MSE => 0.30, R2 => 0.83 },
         elasticnet => { MAE => 0.60, MSE => 0.55, R2 => 0.61 },
     },
     keys          => [ 'MAE', 'R2', 'MSE' ],    # x, y, colour
 );

A set cannot mix the two: numbers for some keys and arrays for others is an
error.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>cmap</code></td><td>the colormap used when a third key colors the points; <code>gist_rainbow</code> by default</td><td><code>cmap => 'viridis'</code></td></tr>
<tr><td><code>color_key</code></td><td>which key of <code>data</code> holds the color values, rather than letting the sort decide.  For the multi-set form this is an inner key, and it must be present in every set</td><td><code>color_key => 'Age'</code></td></tr>
<tr><td><code>colorbar_on</code>, <code>cblabel</code> and the other colorbar options</td><td>the colorbar drawn when a third key colors the points, as listed under Color Bars; <code>cblabel</code> defaults to the color key's name, and <code>colorbar_on => 0</code> leaves the colorbar out</td><td><code>cblabel => 'Age (years)'</code></td></tr>
<tr><td><code>key_order</code></td><td>the multi-set form only: the order the sets are drawn in, and so of the legend and of the markers each is given; sorted by name by default</td><td><code>key_order => ['catboost', 'xgboost']</code></td></tr>
<tr><td><code>keys</code></td><td>array ref fixing the roles of the keys positionally: x, y, then color.  In either form, the single-set or the multi-set, naming only x and y of three keys leaves the third as the color</td><td><code>keys => ['Weight', 'Height', 'Age']</code></td></tr>
<tr><td><code>logscale</code></td><td>an array of the axes to put on a log scale</td><td><code>logscale => ['x', 'y']</code></td></tr>
<tr><td><code>set_options</code></td><td>arguments passed straight to Matplotlib's <code>ax.scatter</code>: <code>marker</code>, <code>color</code>, <code>alpha</code>, <code>s</code>, …  A **scalar** for the single-set form; a **hash keyed by set name** for the multi-set form; the other shape is refused.  Options for a set that has no data are an error.  A <code>label</code> here replaces the set's name in the legend</td><td><code>set_options => 'marker = "v", alpha = 0.4'</code></td></tr>
<tr><td><code>show_legend</code></td><td>the multi-set form only: label each set with its name, for the legend; on by default</td><td><code>show_legend => 0</code></td></tr>
<tr><td><code>tooltips</code></td><td>text shown when the mouse is over a point, in an SVG; see [Tooltips](#tooltips).  An **array** of one label per point for the single-set form, <code>undef</code> for a point without one; a **hash keyed by set name** of such arrays for the multi-set form</td><td><code>tooltips => ['Sample 1', undef, 'Sample 3']</code></td></tr>
</tbody>
</table>

=head3 Tooltips

C<tooltips> puts a label on each point that appears when the mouse is over it.
Opened in a web browser (Firefox, Chromium, Chrome, ...), the SVG draws the
label itself, in a box beside the point, by a short script at the end of the
file.  Each label is also the point's C<< E<lt>titleE<gt> >>, for whatever runs no script:
the script removes the titles as it starts, so that a browser does not show a
label twice.  Image viewers such as Eye of GNOME and Inkscape open the same
file and show the plot as it is, without the labels, and so does a browser
showing the SVG through an C<< E<lt>imgE<gt> >> tag, which runs no script.  C<output_file>
must end in C<.svg> or C<.svgz>; any other format has no tooltips, and is drawn
without them, with a warning.

 scatter(
     output_file => '/tmp/samples.svg',
     data        => { Height => [ 150, 162, 175 ], Weight => [ 50, 61, 80 ] },
     tooltips    => [ 'Sample 1', undef, 'Sample 3' ],    # the second point has none
 );

The array must hold exactly one entry per point, in the order of the data, so
that each label lands on its own point; give C<undef> for a point that should
have no label.  An array of the wrong length is refused, with both counts.  For
the multi-set form, give a hash of such arrays keyed by set name, as for
C<set_options>; a set that is left out has no labels, and a name that is not a
set of C<data> is refused.  A one-point set takes an array of one label.

A point that matplotlib does not draw, such as one with a NaN value or one that
is not above 0 on a log axis, takes its label with it, and every other point
keeps its own.  The labels reach each point through matplotlib's per-point
C<urls>, so a set with C<tooltips> cannot also have a C<url> or C<urls> in its
C<set_options>.

x, y and the color key of a set must hold the same number of values; a set that
does not is refused, naming its axes and their lengths.

C<xlabel> and C<ylabel> default to the names of the keys used for x and y; set them
explicitly to override.  The colorbar is labelled with the name of the color key
itself, and takes C<cbdrawedges> and C<cbpad> from
L<#color-bars-colorbars>.

=head3 single, simple plot

 scatter(
     fh            => $fh,
     data          => {
         X => [@x],
         Y => [map {sin($_)} @x]
     },
     execute       => 0,
     output_file => 'output.images/single.scatter.png',
 );

makes the following image:


=for html
<p>
<img width="651" height="491" alt="single scatter" src="https://github.com/user-attachments/assets/c45d9922-23e0-4f85-8306-aa7fca400328" />
<p>


=head3 options

=head3 multiple plots

 plt(
     fh => $fh,
     output_file => 'output.images/scatterplots.png',
     execute           => 0,
     nrows             => 2,
     ncols             => 3,
     set_figheight     => 8,
     set_figwidth      => 16,
     suptitle          => 'Scatterplot Examples',            # applies to all
     plots             => [
         {    # single-set scatter; no label
             data => {
                 X => @e,    # x-axis
                 Y => @b,    # y-axis
                 Z => @a     # color
             },
             title     => '"Single Set Scatterplot: Random Distributions"',
             color_key => 'Z',
             set_options => 'marker = "v"'
             , # arguments to ax.scatter: there's only 1 set, so "set_options" is a scalar
             text        => [ '100, 100, "text1"', '100, 100, "text2"', ],
             plot_type => 'scatter',
         },
         {     # multiple-set scatter, labels are "X" and "Y"
             data => {
                 X => {    # 1st data set; label is "X"
                     A => @a,    # x-axis
                     B => @b,    # y-axis
                 },
                 W => {    # 2nd data set; label is "Y"
                     A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                     B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                 }
             },
             plot_type     => 'scatter',
             title         => 'Multiple Set Scatterplot',
             set_options =>
             {    # arguments to ax.scatter, for each set in data
               X => 'marker = ".", color = "red"',
               W => 'marker = "d", color = "green"'
             },
         },
         {          # multiple-set scatter, labels are "X" and "Y"
             data => {    # 8th plot,
                 X => {    # 1st data set; label is "X"
                     A => @e,    # x-axis
                     B => @b,    # y-axis
                     C => @a,    # color
                 },
                 Y => {    # 2nd data set; label is "Y"
                     A => generate_normal_dist( 100, 15, 210 ),    # x-axis
                     B => generate_normal_dist( 100, 15, 210 ),    # y-axis
                     C => generate_normal_dist( 100, 15, 210 ),    # color
                 },
             },
             plot_type     => 'scatter',
             title         => 'Multiple Set Scatter w/ colorbar',
             set_options => {    # arguments to ax.scatter, for each set in data
                 X => 'marker = "."',    # point
                 Y => 'marker = "d"'     # diamond
             },
             color_key => 'C', # an inner key, present in both sets
         }
     ]
 );

which makes the following figure:


=for html
<p>
<img width="1610" height="461" alt="scatterplots" src="https://github.com/user-attachments/assets/b8a90f9f-acb3-4cf2-a423-6ad18686ab8c" />
<p>


=head2 venn_proportional_area

Draw an area-proportional Venn diagram, where the size of each region is scaled
to the number of elements it contains.  This plot type wraps the
LL<https://pypi.org/project/matplotlib-venn/> library, so that
library must be installed in addition to C<matplotlib>:

 python3 -m pip install matplotlib-venn

C<data> is a hash of array references; each key is a B<set> and its array is the
set's members (duplicates within a set are collapsed, exactly like a
mathematical set).  Because C<matplotlib_venn> only draws proportional-area
diagrams for two or three sets, C<data> must contain either B<2 or 3> keys.  By
default the sets are labelled and ordered alphabetically by key; use C<key_order>
to override that.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>alpha</code></td><td>opacity of the set regions, <code>0</code>–<code>1</code> (default <code>0.4</code>)</td><td><code>alpha => 0.5</code></td></tr>
<tr><td><code>key_order</code></td><td>array ref giving the order (and hence label positions) of the sets; each set exactly once</td><td><code>key_order => ['Right','Left']</code></td></tr>
<tr><td><code>set_colors</code></td><td>array ref of colors, one per set, and so of the same length as <code>data</code></td><td><code>set_colors => [qw(skyblue lightgreen salmon)]</code></td></tr>
<tr><td><code>title</code></td><td>the subplot title</td><td><code>title => 'Gospels vs. Synoptics'</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

C<venn_proportional_area> is a single-plot wrapper around C<plt>, so it can be
called directly:

 venn_proportional_area(
     output_file => 'output.images/single.venn.png',
     title         => 'Gospels vs. Synoptics',
     data          => {
         Gospels  => [qw(Matthew Mark Luke John)],
         Synoptic => [qw(Matthew Mark Luke)],
     },
 );

which makes the image:


=for html
<p>
<img width="467" height="491" alt="single venn" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/single.venn.png" />
<p>


=head3 multiple plots

Like every other plot type, it can also be one panel among several via C<plt>
and the C<plots> array; here a two-set diagram sits beside a colored three-set
diagram:

 plt(
     output_file => 'output.images/venn.png',
     ncols         => 2,
     suptitle      => 'Proportional-area Venn diagrams',
     plots => [
         {
             plot_type => 'venn_proportional_area',
             title       => 'Two sets',
             data        => {
                 Perl   => [qw(regex hashes CPAN sigils)],
                 Python => [qw(regex hashes pip indentation)],
             },
         },
         {
             plot_type    => 'venn_proportional_area',
             title        => 'Three sets with colors',
             set_colors   => [qw(skyblue lightgreen salmon)],
             alpha        => 0.5,
             data         => {
                 Mammals => [qw(bat whale dog cat human platypus)],
                 Aquatic => [qw(whale shark octopus platypus)],
                 Legged  => [qw(dog cat human bat platypus shark)],
             },
         },
     ],
 );

which makes the following figure:


=for html
<p>
<img width="651" height="409" alt="venn diagrams" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/venn.png" />
<p>


=head2 violin

Plot a hash of array refs as violins: one kernel-density silhouette per key, with
the quartile box, the whiskers and a red dot at the mean drawn over it.  Where a
boxplot summarises a distribution in five numbers, a violin shows its shape, so
bimodal data that a boxplot would hide is visible.

C<violin> and C<violinplot> are the same subroutine under two names, and both
accept the two data shapes described under L<#boxplot> — a hash of array
refs, or a bare array ref for a single violin.  Non-numeric and undefined values
are dropped silently.  Each x-axis label carries the number of points that went
into it, so a violin drawn from very few points announces itself.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>color</code></td><td>a single color for every violin</td><td><code>color => 'red'</code></td></tr>
<tr><td><code>colors</code></td><td>a hash pairing each data key with its own color; every key in <code>data</code> must appear</td><td><code>colors       => { E => 'yellow', B => 'purple', A => 'green' }</code></td></tr>
<tr><td><code>edgecolor</code></td><td>the color of the outline of every violin; <code>black</code> by default</td><td><code>edgecolor => 'none'</code></td></tr>
<tr><td><code>key_order</code></td><td>determine key order display on x-axis</td><td><code>key_order => ['B', 'A', 'E']</code></td></tr>
<tr><td><code>logscale</code></td><td>an array of the axes to put on a log scale; only <code>x</code> and <code>y</code> are accepted.  Note this is an array reference, not the <code>log => 1</code> scalar that <code>bar</code> takes</td><td><code>logscale => ['y']</code></td></tr>
<tr><td><code>orientation</code></td><td>'vertical', 'horizontal'}, default: 'vertical'</td><td><code>orientation => 'horizontal'</code></td></tr>
<tr><td><code>medians</code></td><td>draw a line at each median; on by default, <code>0</code> or <code>'False'</code> for off</td><td><code>medians => 0</code></td></tr>
<tr><td><code>whiskers</code></td><td>draw the quartile bar and whiskers over the silhouette; on by default, <code>0</code> leaves the bare violin</td><td><code>whiskers => 0</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

 plt(
     output_file => 'output.images/single.violinplot.png',
     data              => {                                     # simple hash
         A => [ 55, @{$z} ],
         E => [ @{$y} ],
         B => [ 122, @{$z} ],
     },
     plot_type    => 'violinplot',
     title        => 'Single Violin Plot: Specified Colors',
     colors       => { E => 'yellow', B => 'purple', A => 'green' },
     fh => $fh,
     execute      => 0,
 );

which makes:


=for html
<p>
<img width="651" height="491" alt="single violinplot" src="https://github.com/user-attachments/assets/989650fd-c947-45b0-91c8-c7f71c075cf3" />
<p>


=head3 multiple plots

 plt(
     fh                => $fh,
     execute           => 0,
     output_file       => 'output.images/violin.png',
     plots             => [
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type    => 'violinplot',
             title        => 'Basic',
             xlabel       => 'xlabel',
             set_figwidth => 12,
             suptitle     => 'Violinplot'
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type => 'violinplot',
             color       => 'red',
             title       => 'Set Same Color for All',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             plot_type => 'violinplot',
             colors      => {
                 E => 'yellow',
                 B => 'black'
             },
             title => 'Color by Key',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             orientation => 'horizontal',
             plot_type => 'violinplot',
             colors      => {
                 E => 'yellow',
                 B => 'black'
             },
             title => 'Horizontal orientation',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             whiskers    => 0,
             plot_type => 'violinplot',
             colors      => {
                 E => 'yellow',
                 B => 'black'
             },
             title => 'Whiskers off',
         },
     ],
     ncols => 3,
     nrows => 2,
 );


=for html
<p>
<img width="1211" height="491" alt="violin" src="https://github.com/user-attachments/assets/248df5e4-fd57-45d6-96da-956af0a7dbfb" />
<p>


=head2 wide

Summarise B<several runs of the same curve>.  Every run is drawn as a faint
line, the mean of the runs as a solid one, and one standard deviation either side
of the mean as a translucent ribbon.  This is the plot for repeated measurements
— replicate experiments, repeated simulations, one trace per subject — where a
C<plot> of every line on top of the others would be an unreadable thicket and a
C<plot> of the mean alone would hide how much the runs disagree.

The runs do not have to share an x grid: each group's runs are interpolated onto
101 evenly spaced points spanning that group's own x range before the mean and
the standard deviation are taken, so runs of different lengths, or sampled at
different x values, can be summarised together.  A run is first sorted by x, so
it may be entered in any order; and it counts towards the mean and the ribbon
only between its own first and last x, so a run that stops early narrows the
summary to the runs that continue rather than being held flat at its last
value.

=head3 Entering data

B<1. Labelled groups (hash).> Each key is a group and becomes the legend label;
its value is an array of runs, and each run is a C<[ \@x, \@y ]> pair — the same
pair L<#plot> uses:

 my @x = 0 .. 100;
 my %runs;
 foreach my $group ('Clinical', 'HGI') {
     my $shift = $group eq 'HGI' ? 1 : 0;
     foreach my $replicate (1 .. 3) {
         push @{ $runs{$group} }, [
             [@x],                                                       # x
             [ map { $shift + sin($_/10) + rand_between(-0.2, 0.2) } @x ] # y
         ];
     }
 }
 wide(
     output_file => 'output.images/single.wide.png',
     data          => \%runs,
     color         => {          # one color per group
         Clinical => 'blue',
         HGI      => 'green',
     },
     title         => 'Visualization of similar lines plotted together',
     xlabel        => 'time',
     ylabel        => 'signal',
 );

which makes the image:


=for html
<p>
<img width="651" height="491" alt="wide single" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/single.wide.png" />
<p>


B<2. One unlabelled group (array).> Drop the enclosing hash and pass one group's
array of runs directly; C<color> is then a single color rather than a hash:

 wide(
     output_file => 'output.images/single.array.png',
     data          => $runs{Clinical},
     color         => 'red',
 );

A group with a single run is legal — it just produces a line with a
zero-width ribbon — which is convenient when one group has replicates and
another does not.

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>color</code></td><td>for hash data, a hash of one color per group; for array data, a single color.  Groups with no entry take the next color of Matplotlib's default cycle (<code>C0</code>, <code>C1</code>, ...), in the sorted order of the group names, so a partial hash is allowed; before version 0.315 they were all <code>b</code> (blue)</td><td><code>color => { Clinical => 'blue', HGI => 'green' }</code></td></tr>
<tr><td><code>show_legend</code></td><td>on by default, and only the hash form has labels to show; <code>0</code> suppresses it</td><td><code>show_legend => 0</code></td></tr>
</tbody>
</table>

C<wide> accepts the usual axes options — C<title>, C<xlabel>, C<ylabel>, C<set_xlim>
and the rest — but B<not> C<logscale> or C<key_order>.  For a log axis use
Matplotlib's own C<< set_yscale =E<gt> '"log"' >>.  There is no C<key_order>: as of
version 0.315 the groups are drawn, and listed in the legend, in the sorted
order of their names, so the same data draws the same picture every time.
Before that they were drawn in Perl's hash order, which differs between runs.

=head3 single, simple plot

Both calls above go through the C<wide> wrapper; naming the type explicitly to
C<plt> is equivalent and takes exactly the same options:

 plt(
     output_file => 'output.images/single.wide.png',
     plot_type     => 'wide',
     data          => \%runs,
     color         => { Clinical => 'blue', HGI => 'green' },
 );

=head3 multiple plots

As an element of C<plots>, a C<wide> panel is just another plot hash — here the
labelled groups sit beside one group on its own:

 plt(
     output_file => 'output.images/wide.png',
     ncols         => 2,
     suptitle      => 'Replicate runs, summarised',
     plots         => [
         {
             plot_type => 'wide',
             data        => \%runs,               # hash of groups of runs
             color       => { Clinical => 'blue', HGI => 'green' },
             title       => '"Two groups, mean +/- 1 s.d."', # comma: quoted
             xlabel      => 'time',
             ylabel      => 'signal',
         },
         {
             plot_type     => 'wide',
             data          => $runs{Clinical},    # just the runs, unlabelled
             color         => 'red',
             show_legend => 0,
             title         => 'One group with no legend',
         },
     ],
 );


=for html
<p>
<img width="651" height="491" alt="wide subplots" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/wide.png" />
<p>


Because a C<wide> panel collapses many lines into one summary, it also composes
well with a plot type that shows the same data another way.  Here the runs are
summarised on the left and the distribution of their final values is drawn beside
them:

 my %endpoints;
 foreach my $group (keys %runs) {
     @{ $endpoints{$group} } = map { $_->[1][-1] } @{ $runs{$group} };
 }
 plt(
     output_file => 'output.images/wide.and.violin.png',
     ncols         => 2,
     plots         => [
         {
             plot_type => 'wide',
             data        => \%runs,
             color       => { Clinical => 'blue', HGI => 'green' },
             title       => 'Runs over time',
         },
         {
             plot_type => 'violinplot',
             data        => \%endpoints,    # hash of arrays, same keys
             colors      => { Clinical => 'blue', HGI => 'green' },
             title       => 'Final values',
         },
     ],
 );


=for html
<p>
<img width="651" height="491" alt="wide and violin" src="https://raw.githubusercontent.com/hhg7/MatPlotLib-Simple/main/output.images/wide.and.violin.png" />
<p>


The three images above are written by C<wide.example.pl> in the git repository
(it is not shipped in the CPAN distribution); re-run it from the repository root
with C<perl -Ilib wide.example.pl> to regenerate them.

=head1 Advanced

=head2 Notes in Files

all files that can have notes with them, give notes about how the file was written.  For example, SVG files have the following:

 <dc:title>/mnt/ceph/dcondon/ui/gromacs/tut/dup.2puy/1.plot.gromacs.pl called using "plot" in /mnt/ceph/dcondon/perl5/perlbrew/perls/perl-5.42.0/lib/site_perl/5.42.0/x86_64-linux/Matplotlib/Simple.pm version 0.33 with Perl 5.42.0, Python 3.12.3, matplotlib 3.10.7, by dcondon on login1</dc:title>

The Perl version is the one that wrote the script; the Python and matplotlib
versions, the user and the host are those of whoever ran it, read by the script
itself, so they are right even when a script written with C<< execute =E<gt> 0 >> is run
later or elsewhere.  A user that cannot be found is written as C<unknown user>,
and a host as C<unknown host>.

In an SVG, this note is all the metadata there is: the date, format and type
that matplotlib would add are left out, and so is the
C<< E<lt>!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" ...E<gt> >> line, which no browser
reads.  Other formats, such as PNG and PDF, keep matplotlib's own notes beside
this one.

An SVG from the L<#engines> has the same note in the same place,
C<< E<lt>dc:creatorE<gt>E<lt>cc:AgentE<gt>E<lt>dc:titleE<gt> >>, ending with that engine's versions in place
of Python's and matplotlib's:

 ... version 0.33 with Perl 5.44.0, gnuplot 6.0.0, by dcondon on login1
 ... version 0.33 with Perl 5.44.0, R 4.6.1, ggplot2 4.0.3, by dcondon on login1

and nothing else of the engine's own: gnuplot's C<< E<lt>titleE<gt>GnuplotE<lt>/titleE<gt> >>, which
a browser shows as the figure's name, and its C<< E<lt>descE<gt>Produced by GNUPLOT ...E<lt>/descE<gt> >>
are taken out.  Neither gnuplot nor R's graphics devices can write metadata, so
the note is added to the file once it is drawn, and the two differ in who adds
it:

=over

=item * The R script adds it itself, reading the R and ggplot2 versions, the user and
the host as it runs, as matplotlib's script does, so a script written with
C<< execute =E<gt> 0 >> and run later stamps its figure too.

=item * gnuplot cannot read the user or the host, nor rewrite a file, so Perl adds the
note when it runs gnuplot, with the user and host of that Perl process and the
version gnuplot reports.  A gnuplot script written with C<< execute =E<gt> 0 >> and run
by gnuplot alone leaves its SVG without the note; the script still carries it
as a comment on its first line.

=back

A PNG or PDF from gnuplot or ggplot2 has no note.

=head2 Speed

To improve speed, all data can be written into a single temp python3 file thus:

 use File::Spec;
 use File::Temp;
 my $fh = File::Temp->new( DIR => File::Spec->tmpdir, SUFFIX => '.py', UNLINK => 0 );

all files will be written to C<< $fh-E<gt>filename >>; be sure to put C<< execute =E<gt> 0 >> unless you want the file to be run, which is the last step.

 plt(
     data => {
         Clinical => [
             [
                 [@xw],    # x
                 [@y]      # y
             ],
             [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
             [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
         ],
         HGI => [
             [
                 [@xw],                            # x
                 [ map { 1.9 - 1.1 / $_ } @xw ]    # y
             ],
             [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
             [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
         ]
     },
     output_file => 'output.images/single.wide.png',
     plot_type         => 'wide',
     color             => {
         Clinical => 'blue',
         HGI      => 'green'
     },
     title        => 'Visualization of similar lines plotted together',
     fh => $fh,
     execute      => 0,
 );
 # the last plot should have C<< execute =E<gt> 1 >>
 plt(
     data => [
         [
             [@xw],    # x
             [@y]      # y
         ],
         [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
         [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
     ],
     output_file => 'output.images/single.array.png',
     plot_type         => 'wide',
     color             => 'red',
     title             => 'Visualization of similar lines plotted together',
     fh                => $fh,
     execute           => 1,
 );

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

=head1 Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI
