# ABSTRACT: Access Matplotlib from Perl; providing consistent user interface between different plot types
#!/usr/bin/env perl
use strict;
use feature 'say';
use warnings FATAL => 'all';
use autodie ':all';
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';

package Matplotlib::Simple;
require 5.010;
our $VERSION = 0.14;
use Scalar::Util 'looks_like_number';
use List::Util qw(max sum min);
use Term::ANSIColor;
use Cwd 'getcwd';
use File::Temp;
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';
use FindBin '$RealScript';
use Exporter 'import';
use Capture::Tiny 'capture';
our @EXPORT = ('plt', 'bar', 'barh', 'boxplot', 'colored_table', 'hist', 'hist2d', 'imshow', 'pie', 'plot', 'scatter', 'violin', 'wide');
our @EXPORT_OK = @EXPORT;

sub execute {
	my ( $cmd, $return, $die ) = @_;
	$return = $return // 'exit';
	$die    = $die    // 1;
	if ( $return !~ m/^(exit|stdout|stderr|all)$/ ) {
	  die
	"you gave \$return = \"$return\", while this subroutine only accepts ^(exit|stdout|stderr)\$";
	}
	my ( $stdout, $stderr, $exit ) = capture {
	  system($cmd)
	};
	if ( ( $die == 1 ) && ( $exit != 0 ) ) {
	  say STDERR "exit = $exit";
	  say STDERR "STDOUT = $stdout";
	  say STDERR "STDERR = $stderr";
	  die "$cmd\n failed";
	}
	if ( $return eq 'exit' ) {
		return $exit;
	} elsif ( $return eq 'stderr' ) {
		chomp $stderr;
		return $stderr;
	} elsif ( $return eq 'stdout' ) {
		chomp $stdout;
		return $stdout;
	} elsif ( $return eq 'all' ) {
		chomp $stdout;
		chomp $stderr;
		return {
			exit   => $exit,
			stdout => $stdout,
			stderr => $stderr
		};
	} else {
		die "$return broke pigeonholes";
	}
	return $stdout;
}
my @ax_methods = (
	'ArtistList',     'add_child_axes', 'add_collection', 'add_container',
	'add_image',      'add_line', 'add_patch', 'add_table', 'apply_aspect',
	'autoscale_view', 'axison',   'bxp', 'callbacks', 'can_pan', 'can_zoom',
	'child_axes', 'collections', 'containers', 'contains_point', 'dataLim',
	'drag_pan',   'end_pan',     'fmt_xdata',  'fmt_ydata',      'format_coord',
	'format_xdata', 'format_ydata','hexbin', 'hist', 'hist2d', 'hlines',
	'ignore_existing_data_limits', 'in_axes',    'indicate_inset',
	'indicate_inset_zoom',         'inset_axes', 'invert_xaxis', 'invert_yaxis',
	'label_outer', 'legend_', 'name', 'pcolorfast', 'redraw_in_frame', 'relim',
	'reset_position',
	'scatter',
	'secondary_xaxis', 'secondary_yaxis', 'set_adjustable', 'set_anchor',
	'set_aspect', 'set_autoscale_on', 'set_autoscalex_on',  'set_autoscaley_on',
	'set_axes_locator', 'set_axis_off',    'set_axis_on',   'set_axisbelow',
	'set_box_aspect',   'set_fc',          'set_forward_navigation_events',
	'set_frame_on',     'set_mouseover( ', 'set_navigate', 'set_navigate_mode',
	'set_position',     'set_prop_cycle',  'set_rasterization_zorder',
	'set_subplotspec',  'set_title',       'set_xbound', 'set_xlabel',
	'set_xlim',    # ax.set_xlim(left, right), or ax.set_xlim(right = 180)
	'set_xmargin', 'set_xscale', 'set_xticklabels', 'set_xticks', 'set_ybound',
	'set_ylabel',  'set_ylim',   'set_ymargin', 'set_yscale', 'set_yticklabels',
	'set_yticks',  'sharex',     'sharey',      'spines', 'start_pan', 'tables',
	'text', 'ticklabel_format', 'titleOffsetTrans', 'transAxes', 'transData', 'transLimits',
	'transScale', 'update_datalim', 'use_sticky_edges', 'viewLim', 'vlines', 'violin',
	'xaxis',      'xaxis_date',     'xaxis_inverted',   'yaxis',   'yaxis_date',
	'yaxis_inverted'
);
my @fig_methods = (
	'add_artist', 'add_axes', 'add_axobserver', 'add_callback', 'add_gridspec',
	'add_subfigure', 'add_subplot',   'align_labels', 'align_titles',
	'align_xlabels', 'align_ylabels', 'artists',
	'autofmt_xdate', #'axes', # same as plt
	'bbox', 'bbox_inches', 'canvas', 'clear', 'clf', 'clipbox',
	'colorbar',    # same name as in plt, have to use on case-by-case
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
	'set_figwidth',    # default 6.4
	'set_frameon',       'set_gid',       'set_in_layout', 'set_label',
	'set_layout_engine', 'set_linewidth', 'set_mouseover', 'set_path_effects',
	'set_picker', 'set_rasterized',   'set_size_inches',   'set_sketch_params',
	'set_snap',   'set_tight_layout', 'set_transform', 'set_url', 'set_visible',
	'set_zorder',      # 'show', # keeping plt instead
	'stale', 'stale_callback', 'sticky_edges', 'subfigs',
	'subfigures',           #	 subplot_mosaic',
	'subplotpars',          #	 subplots','subplots_adjust',
	'suppressComposite',    # 'suptitle', # keeping plt instead
	'supxlabel', 'supylabel',    #'text',
	'texts',                     #'tight_layout',
	'transFigure', 'transSubfigure', 'update',
	'update_from',               #'waitforbuttonpress',
	'zorder'
);
my @plt_methods = (
	'AbstractContextManager', 'Annotation', 'Arrow', 'Artist', 'AutoLocator',
	'AxLine', 'Axes', 'BackendFilter',          'Button', 'Circle', 'Colorizer',
	'ColorizingArtist', 'Colormap',     'Enum', 'ExitStack', 'Figure',
	'FigureBase',   'FigureCanvasBase', 'FigureManagerBase', ' FixedFormatter',
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
	'sca',    #'scatter', # taken by "ax"
	'sci', 'semilogx', 'semilogy', 'set_cmap',  'set_loglevel', 'setp', 'show',
	'specgram',   'spring', 'spy', 'stackplot', 'stairs',       'stem', 'step',
	'streamplot', 'style',
	'subplot',    # nrows, ncols : int, default: 1
	'subplot2grid',    'subplot_mosaic', 'subplot_tool', 'subplots',
	'subplots_adjust', 'summer', 'suptitle', 'switch_backend', 'sys', 'table',
#	'text'
	, # text(x: 'float', y: 'float', s: 'str', fontdict: 'dict[str, Any] | None' = None, **kwargs) -> 'Text'
	'thetagrids',   'threading', 'tick_params',
	'tight_layout', 'time', 'title', 'tricontour', 'tricontourf', 'tripcolor',
	'triplot', 'twinx',     'twiny', 'uninstall_repl_displayhook', 'violinplot',
	'viridis', 'waitforbuttonpress', 'winter', 'xcorr', 'xkcd',# 'vlines'
	'xlabel',
	#	'xlim',
	'xscale',
	#'xticks',
	'ylabel', 'ylim', 'yscale',
	#	'yticks'
);

my @arg = ('cmap', 'data', 'execute', 'fh','ncols', 'plot.type',
 'plots', 'plot', 'output.file','nrows');
my @cb_arg = (
'cbdrawedges', # for colarbar: Whether to draw lines at color boundaries
'cblabel',		# The label on the colorbar's long axis
'cblocation', # of the colorbar None or {'left', 'right', 'top', 'bottom'}
'cborientation', # None or {'vertical', 'horizontal'}
'cb_logscale');
my @colored_table_args = ('col.labels', 'default_undefined', 'mirror', 'row.labels', 'show.numbers', 'undef.color');
my $cb_regex = join ('|', @cb_arg);
my $colored_table_regex = join ('|', @colored_table_args);
sub plot_args {    # this is a helper function to other matplotlib subroutines
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',   # ax1, ax2, etc. when there are multiple plots
		'fh',   # e.g. $py, $fh, which will be passed by the subroutine
		'args', # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @defined_args = ( @reqd_args, @ax_methods, @fig_methods, @plt_methods, @arg, @cb_arg );
	my @bad_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @defined_args
	} keys %{$args};
	if ( scalar @bad_args > 0 ) {
	  p @bad_args, array_max => scalar @bad_args;
	  say 'the above arguments are not recognized.';
	  p @defined_args, array_max => scalar @defined_args;
	  die 'The above args are accepted.';
	}
	$args->{ax} = $args->{ax} // 'ax';
	foreach my $item (
		grep { defined $args->{args}{$_} } ( # no quotes!
			'set_title', 'set_xlabel', 'set_ylabel', 'suptitle',
			'xlabel',    'ylabel',     'title'
		)
		)
		{
		if ( $args->{args}{$item} =~ m/^([^\"\',]+)$/ ) {
			$args->{args}{$item} = "'$args->{args}{$item}'";
		}
	}
	my @obj  = ( $args->{ax}, 'fig', 'plt' );
	my @args = ( \@ax_methods, \@fig_methods, \@plt_methods );
	foreach my $i ( 0 .. $#args ) {
		foreach my $method ( grep { defined $args->{args}{$_} } @{ $args[$i] } ) {
			my $ref = ref $args->{args}{$method};
			if ( ( $ref ne 'ARRAY' ) && ( $ref ne '' ) ) {
				die "$current_sub only accepts scalar or array types, but $ref was entered.";
			}
			if ( $ref eq '' ) {
				say {$args->{fh}} "$obj[$i].$method($args->{args}{$method}) #line" . __LINE__;
				next;
			}
			# can only be ARRAY
			foreach my $j ( @{ $args->{args}{$method} } ) {
				say { $args->{fh} } "$obj[$i].$method($j) #line" . __LINE__;
			}
		}
	}
	return unless defined $args->{ax};
	my $legend   = $args->{args}{legend} // '';
	my $pie_plot = 0;
	if (   ( defined $args->{args}{'plot.type'} )
	  && ( $args->{args}{'plot.type'} eq 'pie' ) ) {
	  $pie_plot = 1;
	}
	return 1 if $pie_plot == 1;
	# pie charts don't get legends
	say { $args->{fh} }
	"handles, labels = $args->{ax}.get_legend_handles_labels()";
	say { $args->{fh} } 'if len(labels) > 0:';
	say { $args->{fh} } "\t$args->{ax}.legend($legend)";
}
sub barplot_helper { # this is a helper function to other matplotlib subroutines
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
	  die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	@reqd_args, @ax_methods, @plt_methods, @fig_methods, @arg,
	'ax',
	'color'
	, # :mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed
	'edgecolor'
	, #:mpltype:`color` or list of :mpltype:`color`, optional; The colors of the bar edges.
	'key.order',    # define the keys in an order (an array reference)
	'label',        # an array of labels for grouped bar plots
	'linewidth'
	, # float or array, optional; Width of the bar edge(s). If 0, don't draw edges
	'log'
	,    # bool, default: False; If *True*, set the y-axis to be log scale.
	'stacked',    # stack the groups on top of one another; default 0 = off
	'width',      # float or array, default: 0.8; The width(s) of the bars.
	'xerr'
	, # float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)
	'yerr',    # same as xerr, but better with bar
	);
	@opt = grep {$_ !~ m/^(?:$cb_regex)$/} @opt; # args that shouldn't apply
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt; # args that shouldn't apply
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	my $ax = $args->{ax} // '';
	if ( scalar @undef_opt > 0 ) {
	  p @undef_opt;
	  die
	"The above arguments aren't defined for $plot->{'plot.type'} at plot position $ax";
	}
	my ( %ref_counts, $plot_type );
	foreach my $set ( keys %{ $plot->{data} } ) {
	  $ref_counts{ ref $plot->{data}{$set} }++;
	}
	if ( scalar %ref_counts > 1 ) {
		p $plot->{data};
		p %ref_counts;
		die
	"different kinds of data were entered to plot $ax which should be simple hash or hash of arrays.";
	}
	if ( defined $ref_counts{''} ) {
		$plot_type = 'simple';
	} elsif ( defined $ref_counts{'ARRAY'} ) {
		$plot_type = 'grouped';
	} elsif ( defined $ref_counts{'HASH'} ) {
		$plot_type = 'grouped';    # now make the hash of hash into a ARRAY structure
		my %key2;
		foreach my $key1 ( keys %{ $plot->{data} } ) {
			foreach my $key2 ( keys %{ $plot->{data}{$key1} } ) {
				$key2{$key2}++;
			}
		}
		my @key2 = sort { lc $a cmp lc $b } keys %key2;
		my %new_structure;
		foreach my $k1 ( keys %{ $plot->{data} } ) {
			@{ $new_structure{$k1} } = @{ $plot->{data}{$k1} }{@key2};
		}
		@{ $plot->{label} } = @key2;
		$plot->{data} = \%new_structure;
	} else {
	  p %ref_counts;
	  p $plot->{data};
	  die 'the above plot type is not yet programmed in to bar/barh';
	}
	$plot->{stacked} = $plot->{stacked} // 0;
	if (   ( $plot_type eq 'grouped' )
	  && ( defined $plot->{width} )
	  && ( $plot->{stacked} == 0 ) )
	{
	  say STDERR 'grouped, non-stacked barplots ignore width settings';
	  delete $plot->{width};
	}
	my @key_order;
	if ( defined $plot->{'key.order'} ) {
	  @key_order = @{ $plot->{'key.order'} };
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	my $options = '';    # these args go to the plt.bar call
	if ( defined $plot->{'log'} ) {
	  $options .= ", log = $plot->{log}";
	}    # args that can be either arrays or strings below; STRINGS:
	foreach my $c ( grep { defined $plot->{$_} } ( 'color', 'edgecolor' ) ) {
	  next if ( ( $c eq 'color' ) && ( $plot_type eq 'grouped' ) );
	  my $ref = ref $plot->{$c};
	  if ( $ref eq '' ) {    # single color
		   $options .= ", $c = '$plot->{$c}'";
	  } elsif ( $ref eq 'ARRAY' ) {
		   $options .= ", $c = [\"" . join( '","', @{ $plot->{$c} } ) . '"]';
	  }
	}    # args that can be either arrays or strings below; NUMERIC:
	foreach my $c ( grep { defined $plot->{$_} } ('linewidth') ) {
		my $ref = ref $plot->{$c};
		if ( $ref eq '' ) {    # single color
			$options .= ", $c = $plot->{$c}";
		} elsif ( $ref eq 'ARRAY' ) {
			$options .= ", $c = [" . join( ',', @{ $plot->{$c} } ) . ']';
		} else {
			p $args;
			die "$ref for $c isn't acceptable";
		}
	}
	foreach my $err ( grep { defined $plot->{$_} } ( 'xerr', 'yerr' ) ) {
		my $ref = ref $plot->{$err};
		if ( $ref eq '' ) {
			$options .= ", $err = $plot->{$err}";
		} elsif ( $ref eq 'HASH' ) {    # I assume that it's all defined
			my ( @low, @high );
			foreach my $i (@key_order) {
				if ( scalar @{ $plot->{$err}{$i} } != 2 ) {
				  p $plot->{$err}{$i};
				  die	"$err/$i should have exactly 2 items: low and high error bars";
				}
				push @low,  $plot->{$err}{$i}[0];
				push @high, $plot->{$err}{$i}[1];
			}
			$options .=
				 ", $err = [["
			  . join( ',', @low ) . '],['
			  . join( ',', @high ) . ']]';
		} else {
			p $args;
			die "$ref for $err isn't acceptable";
		}
	}
	if ( $plot_type eq 'simple' ) {    # a simple hash -> simple bar plot
	  say { $args->{fh} } 'labels = ["' . join( '","', @key_order ) . '"]';
	  say { $args->{fh} } 'vals = ['
		 . join( ',', @{ $plot->{data} }{@key_order} ) . ']';
	  say { $args->{fh} } "ax$ax.$plot->{'plot.type'}(labels, vals $options)";
	} elsif ( $plot_type eq 'grouped' ) {    # grouped bar plot; hash of array
	  my @val;
	  foreach my $k (@key_order) {
		   foreach my $i ( 0 .. scalar @{ $plot->{data}{$k} } - 1 ) {
		       push @{ $val[$i] }, $plot->{data}{$k}[$i];
		   }
	  }
	  my $barwidth = $plot->{width} // 0.8;
	  $plot->{stacked} = $plot->{stacked} // 0;
	  if ( $plot->{stacked} == 0 ) {
		   $barwidth /= ( scalar %ref_counts + 3 );
	  }
	  my @xticks   = 0 .. scalar @{ $val[0] } - 1;
	  my @mean_pos = map { 0 } 0 .. scalar @{ $val[0] } - 1;    # initialize
	  my $hw       = 'height';
	  $hw = 'width' if $plot->{'plot.type'} eq 'bar';
	  my @bottom = map { 0 } 0 .. scalar @{ $val[0] } - 1;      # initialize
	  my $i = 0;
	  foreach my $arr (@val) {
		   my $x = '[' . join( ',', @xticks ) . ']';
		   foreach my $p ( 0 .. $#mean_pos ) {
		       $mean_pos[$p] += $xticks[$p];
		   }
		   my $set_options = '';
		   foreach
		     my $f ( grep { defined $plot->{$_}[$i] } ( 'color', 'label' ) )
		   {
		       $set_options .= ", $f = '$plot->{$f}[$i]'";
		   }
		   if ( $plot->{stacked} > 0 ) {
		       $set_options .= ', bottom = [' . join( ',', @bottom ) . ']';
		   }
		   say { $args->{fh} } "ax$ax.$plot->{'plot.type'}($x, ["
		     . join( ',', @{$arr} )
		     . "], $hw = $barwidth $options $set_options)";
		   @bottom =
		     map { $bottom[$_] + $arr->[$_] } 0 .. scalar @{ $val[0] } - 1
		     if $plot->{stacked} > 0;
		   @xticks = map { $_ + $barwidth } @xticks
		     if $plot->{stacked} <= 0;    # for next iteration
		     $i++;
	  }
	  my $xticks = '["' . join( '","', @key_order ) . '"]';
	  my $ticks  = 'yticks';
	  $ticks = 'xticks' if $plot->{'plot.type'} eq 'bar';
	  $_ /= scalar @val for @mean_pos;
	  say { $args->{fh} } "ax$ax.set_$ticks(["
		 . join( ',', @mean_pos )
		 . "], $xticks)";
	} else {
	  die
	"\$plot_type = $plot_type & stacked = $plot->{stacked}and isn't defined.";
	}
}

sub boxplot_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'ax',       # used for multiple plots
	  'color'
	  , # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
	  'colors', 'key.order',
	  'notch', # Whether to draw a notched boxplot (`True`), or a rectangular boxplot (`False`)
	  'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
	  'showcaps'
	  ,    # bool: Show the caps on the ends of whiskers; default "True"
	  'showfliers',
	  'showmeans',
	  'whiskers',    # 0 or 1
	);
	@opt = grep {$_ !~ m/^(?:$cb_regex)$/} @opt; # args that shouldn't apply
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt;
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		p @undef_opt;
		die "The above arguments aren't defined for $plot->{'plot.type'} using $current_sub";
	}
	$plot->{orientation} = $plot->{orientation} // 'vertical';
	if ( $plot->{orientation} !~ m/^(?:horizontal|vertical)$/ ) {
	  die
	"$current_sub needs either \"horizontal\" or \"vertical\", not \"$plot->{orientation}\"";
	}
	$args->{whiskers} = $args->{whiskers} // 1;    # by default, make whiskers
	my ( @xticks, @key_order );
	if ( defined $plot->{'key.order'} ) {
	  @key_order = @{ $plot->{'key.order'} };
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	my $ax = $args->{ax} // '';
	#	$plot->{medians} = $plot->{medians} // 1; # by default, show median values
	$plot->{notch}      = $plot->{notch}      // 'False';
	$plot->{showcaps}   = $plot->{showcaps}   // 'True';
	$plot->{showfliers} = $plot->{showfliers} // 'True';
	$plot->{showmeans}  = $plot->{showmeans}  // 'True';
	my $options = "orientation = '$plot->{orientation}'";
	foreach my $arg ( 'showcaps', 'showfliers', 'showmeans', 'notch' ) {
	  $options .= ", $arg = $plot->{$arg}";
	}
	say { $args->{fh} } 'd = []';
	foreach my $key (@key_order) {
	  @{ $plot->{data}{$key} } = grep { defined } @{ $plot->{data}{$key} };
	  say { $args->{fh} } 'd.append(['
		 . join( ',', @{ $plot->{data}{$key} } ) . '])';
	}
	say { $args->{fh} } "bp = ax$ax.boxplot(d, patch_artist = True, $options)";
	if ( defined $plot->{colors} ){ # every hash key should have its own color defined
	# the below code helps to provide better error messages in case I make an error in calling the sub
	  my @wrong_keys =
		 grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
	  if ( scalar @wrong_keys > 0 ) {
		   p @wrong_keys;
		   die 'the above data keys have no defined color';
	  }

	# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
	  print { $args->{fh} } 'colors = ["'
		 . join( '","', @{ $plot->{colors} }{@key_order} ) . '"]' . "\n";

	 # the above color list will have the same order, via the above hash slice
	  say { $args->{fh} } 'for patch, color in zip(bp["boxes"], colors):';
	  say { $args->{fh} } "\tpatch.set_facecolor(color)";
	  say { $args->{fh} } "\tpatch.set_edgecolor('black')";
	} else {
		say { $args->{fh} } 'for pc in bp["boxes"]:';
		if ( defined $plot->{color} ) {
			say { $args->{fh} } "\tpc.set_facecolor('$plot->{color}')";
		}
		say { $args->{fh} } "\tpc.set_edgecolor('black')";
	}
	foreach my $key (@key_order) {
		push @xticks, "$key ("
		 . format_commas( scalar @{ $plot->{data}{$key} }, '%.0u' ) . ')';
	}
	if ( $plot->{orientation} eq 'vertical' ) {
		say { $args->{fh} } "ax$ax.set_xticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ["'
		 . join( '","', @xticks ) . '"])';
	} else {
		say { $args->{fh} } "ax$ax.set_yticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ["'
		 . join( '","', @xticks ) . '"])';
	}
}

sub colored_table_helper {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless (ref $args eq 'HASH') {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',   # e.g. $py, $fh, which will be passed by the subroutine
		'plot', # args to original function
	);
	my @undef_args = grep {!defined $args->{$_}} @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "The arguments above are necessary for proper function of $current_sub and weren't defined.";
	}
#	optional args are below
	my @defined_args = (@reqd_args, @ax_methods, @plt_methods, @fig_methods, @arg,
	@cb_arg,
		'ax',       # used for multiple plots
		'col.labels',
		'cmap',		# the cmap used for coloring
		'default_undefined',	# what value should undefined values be assigned to?
		'mirror',   # $data{A}{B} = $data{B}{A}
		'row.labels',	# row labels
		'show.numbers',# show the numbers or not, by default off.  0 = "off"; "show.numbers" > 0 => "on"
		'undef.color', # what color will undefined points be
#		'xlabel',	# xlabel prints in a bad position, so I removed this as a possible option
#		'ylabel',	# ylabel prints under the row labels
	);
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		p @bad_args;
		say 'the above arguments are not recognized.';
		p @defined_args;
		die 'The above args are accepted.'
	}
	my $plot = $args->{plot};
	$plot->{default_undefined} = $plot->{default_undefined} // 0;
	$plot->{mirror} = $plot->{mirror} // 0;
#	my @data;
	my (@cols, @rows, %data);
	if (defined $plot->{'col.labels'}) {
		@cols = @{ $plot->{'col.labels'} };
	} else {
		@cols = sort keys %{ $plot->{data} };
	}
	foreach my $k1 (@cols) {
		foreach my $k2 (keys %{ $plot->{data}{$k1} }) {
			$data{$k1}{$k2} = $plot->{data}{$k1}{$k2};
			$data{$k2}{$k1} = $data{$k1}{$k2} if $plot->{mirror} > 0;
		}
	}
	if (defined $plot->{'row.labels'}) {
		@rows = @{ $plot->{'row.labels'} };
	} else {
		@rows = sort keys %data;
	}
	my ($min, $max) = ('inf', '-inf');
	say {$args->{fh}} 'data = []';
	say {$args->{fh}} 'import numpy as np';
	foreach my $k1 (@cols) {
		foreach my $k2 (grep {!defined $data{$k1}{$_}} @cols) {
			$data{$k1}{$k2} = 'np.nan';#$plot->{default_undefined};
			$data{$k2}{$k1} = 'np.nan';#$plot->{default_undefined};
		}
		foreach my $k2 (grep {looks_like_number($data{$k1}{$_})} @cols) {
			$min = min($min, $data{$k1}{$k2});
			$max = max($max, $data{$k1}{$k2});
		}
		say {$args->{fh}} 'data.append([' . join (',', @{ $data{$k1} }{@cols}) . '])';
	}
	$min = $args->{cb_min} // $min;
	$max = $args->{cb_max} // $max;
	$plot->{cmap} = $plot->{cmap} // 'gist_rainbow';
	$plot->{cblogscale} = $plot->{cblogscale} // 0;
	my $ax = $args->{ax} // '';
	say {$args->{fh}} 'from matplotlib import colors' if $plot->{cblogscale} > 0;
	$plot->{'undef.color'} = $plot->{'undef.color'} // 'gray';
	say {$args->{fh}} 'plt.cm.gist_rainbow.set_bad("' . $plot->{'undef.color'} . '")';
	say {$args->{fh}} "norm = plt.Normalize($min, $max)";
	say {$args->{fh}} 'datacolors = plt.cm.gist_rainbow(norm(data))';
	if ($plot->{cblogscale} > 0) {
		say {$args->{fh}} "img = ax$ax.imshow(data, cmap='$plot->{cmap}', norm=colors.LogNorm())";
	} else {
		say {$args->{fh}} "img = ax$ax.imshow(data, cmap='$plot->{cmap}')";
	}
	if (defined $plot->{cblabel}) {
		say {$args->{fh}} "fig.colorbar(img, label = '$plot->{cblabel}')";
	} else {
		say {$args->{fh}} 'fig.colorbar(img)';
	}
	say {$args->{fh}} 'img.set_visible(False)';
	$plot->{'show.numbers'} = $plot->{'show.numbers'} // 0;
	say {$args->{fh}} 'for ri, row in enumerate(data):';
	say {$args->{fh}} '	for ii, item in enumerate(row):';
	say {$args->{fh}} '		if np.isnan(item):';
	say {$args->{fh}} '			data[ri][ii] = ""';
	if ($plot->{'show.numbers'} > 0) {
		say {$args->{fh}} "table = ax$ax" . '.table(cellText=data, rowLabels=["' . join ('","', @rows) . '"], colLabels = ["' . join ('","', @cols) . '"], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	} else {
		say {$args->{fh}} "table = ax$ax" . '.table(rowLabels=["' . join ('","', @rows) . '"], colLabels = ["' . join ('","', @cols) . '"], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	}
	foreach my $arg (grep {defined $plot->{$_}} ('title')) {
		say {$args->{fh}} "ax$ax.$arg('$plot->{$arg}')";
	}
	if (defined $plot->{logscale}) {
		foreach my $axis (@{ $plot->{logscale} }) { # x, y 
			say {$args->{fh}} "ax$ax.$axis" . 'scale("log")';
		}
	}
	say {$args->{fh}} "plt.clim(vmin = $plot->{cb_min})" if defined $plot->{cb_min};
	say {$args->{fh}} "plt.clim(vmax = $plot->{cb_max})" if defined $plot->{cb_max};
	foreach my $axis ('x','y') {
		say {$args->{fh}} "ax$ax.set_${axis}ticks" . '([])';
		say {$args->{fh}} "ax$ax.set_${axis}ticklabels" . '([])';
	}
}

sub hexbin_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @fig_methods, @arg, @plt_methods,
	  'ax',
	  'cb_logscale',
	  'cmap',         # "gist_rainbow" by default
	  'key.order',    # define the keys in an order (an array reference)
	  'marginals',  # If marginals is *True*, plot the marginal density as colormapped rectangles along the bottom of the x-axis and left of the y-axis.
	  'mincnt'
	  , # int >= 0, default: 0 If > 0, only display cells with at least *mincnt*        number of points in the cell.
	  'vmax'
	  , #  When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'vmin'
	  , # When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'xbins',    # default 15
	  'xscale.hexbin', # 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the horizontal axis.
	  'ybins',    # default 15
	  'yscale.hexbin', # 'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the vertical axis.
	);
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt;
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
		p @undef_args;
		die "The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
	}
	$plot->{cb_logscale} = $plot->{cb_logscale} // 0;
	$plot->{marginals}   = $plot->{marginals}   // 0;
	$plot->{xbins}       = $plot->{xbins}       // 15;
	$plot->{ybins}       = $plot->{ybins}       // 15;
	$plot->{xbins}       = int $plot->{xbins};
	$plot->{ybins}       = int $plot->{ybins};
	if ( ( $plot->{xbins} == 0 ) || ( $plot->{ybins} == 0 ) ) {
	  p $plot;
	  die "# of bins cannot be 0 in $current_sub";
	}
	if ( ( $plot->{xbins} == 0 ) || ( $plot->{ybins} == 0 ) ) {
	  p $args;
	  die '# of bins cannot be 0';
	}
	my @keys;
	if ( defined $plot->{'key.order'} ) {
		@keys = @{ $plot->{'key.order'} };
	} else {
		@keys = sort keys %{ $plot->{data} };
	}
	if ( scalar @keys != 2 ) {
	  p @keys;
	  die "There must be exactly 2 keys for $current_sub";
	}
	my $n_points = scalar @{ $plot->{data}{ $keys[0] } };
	if ( scalar @{ $plot->{data}{ $keys[1] } } != $n_points ) {
	  say "\"$keys[0]\" has $n_points points.";
	  say "\"$keys[1]\" has "
		 . scalar @{ $plot->{data}{ $keys[1] } }
		 . " points.";
	  die 'The length of both keys must be equal.';
	}
	$plot->{xlabel} = $plot->{xlabel} // $keys[0];
	$plot->{ylabel} = $plot->{ylabel} // $keys[1];
	$plot->{cmap}   = $plot->{cmap}   // 'gist_rainbow';
	my $options =
	", gridsize = ($plot->{xbins}, $plot->{ybins}), cmap = '$plot->{cmap}'"
	;    # these args go to the plt.hist call
	if ( $plot->{cb_logscale} > 0 ) {
	  say { $args->{fh} } 'from matplotlib.colors import LogNorm';
	  $options .= ', norm = LogNorm()';
	}
	foreach my $opt (
	  grep { defined $plot->{$_} } ('xrange', 'yrange', 'vmin', 'vmax', 'mincnt')
	)
	{
		$options .= ", $opt = $plot->{$opt}";
	}
	foreach my $opt (grep {defined $plot->{$_} } ('xscale.hexbin', 'yscale.hexbin')) {
		if (($plot->{$opt} ne 'log') && ($plot->{$opt} ne 'linear')) {
			die "\"$opt\" is neither \"log\" nor \"linear\"";
		}
		my $opth = $opt;
		$opth =~ s/\.\w+$//;
		$options .= ", $opth = '$plot->{$opt}'";
	}
	if ((defined $plot->{marginals}) && ($plot->{marginals} > 0)) {
		$options .= ', marginals = True';
	}
	say { $args->{fh} } 'x = ['
	. join( ',', @{ $plot->{data}{ $keys[0] } } ) . ']';
	say { $args->{fh} } 'y = ['
	. join( ',', @{ $plot->{data}{ $keys[1] } } ) . ']';
	my $ax = $args->{ax} // '';
	say { $args->{fh} } "im = ax$ax.hexbin(x, y $options)\n";
	if ( defined $plot->{cblabel} ) {
	  say { $args->{fh} } 'plt.colorbar(im' . ", label = '$plot->{cblabel}')";
	} else {
	  say { $args->{fh} } 'plt.colorbar(im, label = "Density")';
	}
}

sub format_commas
{ #($n, $format = '.%02d') { # https://stackoverflow.com/questions/33442240/perl-printf-to-use-commas-as-thousands-separator
    # $format should be '%.0u' for integers
    my ( $n, $format ) = @_;
    $format = '.%02d' if not defined $format;
    return
      reverse( join( ",", unpack( "(A3)*", reverse int($n) ) ) )
      . sprintf( $format, int( 100 * ( .005 + ( $n - int($n) ) ) ) );
}

sub hist_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',      # used for multiple plots
		'fh',      # e.g. $py, $fh, which will be passed by the subroutine
		'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'alpha',    # default 0.5; same for all sets
	  'bins'
	  , # nt or sequence or str, default: :rc:`hist.bins`If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open
	  'color'
	  , # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
	  'log',            # if set to > 1, the y-axis will be logarithmic
	  'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
	  'plots', 'ncols', 'nrows', 'output.file', 'fh',
	  'execute'         # these will be ignored
	);
	@opt = grep {$_ !~ m/^(?:$cb_regex)$/} @opt; # args that shouldn't apply
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt;
	my $plot      = $args->{plot};
	my @undef_opt = grep {
		my $key = $_;
		not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		p @undef_opt;
		die "The above arguments aren't defined for $plot->{'plot.type'}";
	}
	my $options = '';    # these args go to the plt.hist call
	if ( ( defined $plot->{'log'} ) && ( $plot->{'log'} > 0 ) ) {
	  $options .= ', log = True';
	}
	$plot->{alpha} = $plot->{alpha} // 0.5;
	foreach my $arg ( grep { defined $plot->{$_} } ( 'bins', 'orientation' ) ) {
		next if ref $plot->{$arg} eq 'HASH';    # set-specific setting exists
		my $ref = ref $plot->{$arg};
		if ( $ref eq '' ) { # single color
			if ( $plot->{$arg} =~ m/^[A-Za-z]+$/ ) {    # "Red" needs quotes
				$options .= ", $arg = '$plot->{$arg}'";
			} else { # I'm assuming numeric
				$options .= ", $arg = $plot->{$arg}";
			}
		} elsif ( $ref eq 'ARRAY' ) {
			$options .= ", $arg = [" . join( ',', @{ $plot->{$arg} } ) . '"]';
		} else {
			p $plot;
			die "$ref for $arg isn't acceptable";
		}
	}
	foreach my $set ( sort keys %{ $plot->{data} } ) {
		my $set_options = '';
		foreach
		 my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) )
		{
			next unless defined $plot->{$arg}{$set};
			if ( $plot->{$arg}{$set} =~ m/^[A-Za-z]+$/ ) {  # "Red" needs quotes
				$set_options .= ", $arg = '$plot->{$arg}{$set}'";
			} else {    # I'm assuming numeric; "10" doesn't need quotes
				$set_options .= ", $arg = $plot->{$arg}{$set}";
			}
		}
		say { $args->{fh} } "ax$args->{ax}.hist(["
		 . join( ',', @{ $plot->{data}{$set} } )
		 . "], alpha = $plot->{alpha}, label = '$set' $options $set_options)";
	}
}

sub hist2d_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'fh',      # e.g. $py, $fh, which will be passed by the subroutine
		'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'ax',
	  'cb_logscale',
	  'cmap',         # "gist_rainbow" by default
	  'cmax'
	  ,   # All bins that has count < *cmin* or > *cmax* will not be displayed
	  'cmin',         # color min
	  'density',      # density : bool, default: False
	  'key.order',    # define the keys in an order (an array reference)
	  'logscale',     # logscale, an array of axes that will get log scale
	  'show.colorbar',
	  'vmax'
	  , #  When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'vmin'
	  , # When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover
	  'xbins',    # default 15
	  'xmin', 'xmax',
	  'ymin', 'ymax',
	  'ybins',    # default 15
	);
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt;
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die
	"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
	}
	$plot->{cb_logscale}     = $plot->{cb_logscale}     // 0;
	$plot->{'show.colorbar'} = $plot->{'show.colorbar'} // 1;
	$plot->{xbins}           = int( $plot->{xbins} // 15 );
	$plot->{ybins}           = int( $plot->{ybins} // 15 );
	if ( ( $plot->{xbins} == 0 ) || ( $plot->{ybins} == 0 ) ) {
	  p $plot;
	  die "# of bins cannot be 0 in $current_sub";
	}
	if ( ( $plot->{xbins} == 0 ) || ( $plot->{ybins} == 0 ) ) {
	  p $args;
	  die '# of bins cannot be 0';
	}
	my @keys;
	if ( defined $plot->{'key.order'} ) {
		@keys = @{ $plot->{'key.order'} };
	} else {
		@keys = sort keys %{ $plot->{data} };
	}
	if ( scalar @keys != 2 ) {
	  p @keys;
	  die "There must be exactly 2 keys for $current_sub";
	}
	my $n_points = scalar @{ $plot->{data}{ $keys[0] } };
	if ( scalar @{ $plot->{data}{ $keys[1] } } != $n_points ) {
	  say "$keys[0] has $n_points points.";
	  say "$keys[1] has "
		 . scalar @{ $plot->{data}{ $keys[1] } }
		 . " points.";
	  die 'The length of both keys must be equal.';
	}
	$plot->{xlabel} = $plot->{xlabel} // $keys[0];
	$plot->{ylabel} = $plot->{ylabel} // $keys[1];
	$plot->{cmap}   = $plot->{cmap}   // 'gist_rainbow';
	my $options = ", cmap = '$plot->{cmap}'"; # these args go to the plt.hist call
	if ( $plot->{cb_logscale} > 0 ) {
		say {$args->{fh}} 'from matplotlib.colors import LogNorm';
		# prevents "ValueError: Passing a Normalize instance simultaneously with vmin/vmax is not supported.  Please pass vmin/vmax directly to the norm when creating it"
		my @logNorm_opt;
		foreach my $arg (grep {defined $plot->{$_}} ('vmin', 'vmax')) {
			if (not looks_like_number($plot->{$arg})) {
				die "$arg must be numeric for $current_sub, but was given \"$plot->{$arg}\"";
			}
			push @logNorm_opt, "$arg = $plot->{$arg}";
			delete $plot->{$arg}; 
		}
		$options .= ', norm = LogNorm(' . join (',', @logNorm_opt) . ')';
	}
	foreach my $opt ( grep { defined $plot->{$_} }
	  ( 'cmin', 'cmax', 'density', 'vmin', 'vmax' ) )
	{
		$options .= ", $opt = $plot->{$opt}";
	}
	my @bad_indices;
	my $bad_pts = 0;
	foreach my $i (0,1) {
		@{ $bad_indices[$i] } = grep {not defined $plot->{data}{$keys[$i]}[$_]} 0..$n_points-1;
		$bad_pts += scalar @{ $bad_indices[$i] };
	}
	if ($bad_pts > 0) {
		say STDERR "the above args have the following indices undefined ($n_points total)";
		p @bad_indices;
		die "Cannot proceed as there are $bad_pts undefined points.";
	}
	foreach my $i (0,1) {
		@{ $bad_indices[$i] } = grep {not looks_like_number($plot->{data}{$keys[$i]}[$_])} 0..$n_points-1;
		$bad_pts += scalar @{ $bad_indices[$i] };
	}
	if ($bad_pts > 0) {
		p $args;
		say STDERR "the above args have the following indices non-numeric ($n_points total)";
		p @bad_indices;
		die "Cannot proceed as there are $bad_pts non-numeric points.";
	}
	say { $args->{fh} } 'x = ['
	. join( ',', @{ $plot->{data}{ $keys[0] } } ) . ']';
	$plot->{xmin} = $plot->{xmin} // min( @{ $plot->{data}{ $keys[0] } } );
	$plot->{xmax} = $plot->{xmax} // max( @{ $plot->{data}{ $keys[0] } } );
	say { $args->{fh} } 'y = ['
	. join( ',', @{ $plot->{data}{ $keys[1] } } ) . ']';
	$plot->{ymin} = $plot->{ymin} // min( @{ $plot->{data}{ $keys[1] } } );
	$plot->{ymax} = $plot->{ymax} // max( @{ $plot->{data}{ $keys[1] } } );
	my $ax = $args->{ax} // '';

	# the range argument ensures that there are no empty parts of the plot
	my $range =
	", range = [($plot->{xmin}, $plot->{xmax}), ($plot->{ymin}, $plot->{ymax})]";
	say {$args->{fh}}
	"hist2d_n, hist2d_xedges, hist2d_yedges, im$ax = ax$ax.hist2d(x, y, ($plot->{xbins}, $plot->{ybins}) $options $range)";
	say {$args->{fh}} 'import numpy as np';
	say {$args->{fh}} 'max_hist2d_box = np.max(hist2d_n)';
	say {$args->{fh}} 'min_hist2d_box = np.min(hist2d_n)';
	say {$args->{fh}} "print(f'plot $ax hist2d density range = [{min_hist2d_box}, {max_hist2d_box}]')";
	return 0 if $plot->{'show.colorbar'} == 0;
	if ( defined $plot->{cblabel} ) {
		say { $args->{fh} } "plt.colorbar(im$ax, label = '$plot->{cblabel}')";
	} else {
		say { $args->{fh} } "plt.colorbar(im$ax, label = 'Density')";
	}
}

sub imshow_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
	  die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'ax',
	  'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'cblabel', # colorbar label
	  'cbdrawedges', # for colorbar
	  'cblocation', # of the colorbar None or {'left', 'right', 'top', 'bottom'}
	  'cborientation', # None or {'vertical', 'horizontal'}
	  'cmap', # The Colormap instance or registered colormap name used to map scalar data to colors.
	  'aux',
	  'vmax', # float
	  'vmin', # flat
	);
	@opt = grep {$_ !~ m/^(?:$colored_table_regex)$/} @opt;
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die
	"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
	}
	my $i = 0;
	print { $args->{fh} } 'd = [';
	my ($min_val, $max_val) = ('inf', '-inf');
	foreach my $row (@{ $plot->{data} }) {
		say { $args->{fh} } '[' . join (',', @{ $row }) . '],';
		$min_val = min(@{ $row }, $min_val);
		$max_val = max(@{ $row }, $max_val);
	}
	say { $args->{fh} } ']';
	my $ax = $args->{ax} // '';
	my $opts = '';
	$plot->{vmax} = $plot->{vmax} // $max_val;
	$plot->{vmin} = $plot->{vmin} // $min_val;
	foreach my $opt (grep {defined $plot->{$_}} ('cmap')) { # strings
		$opts .= ", $opt = '$plot->{$opt}'";
	}
	foreach my $opt (grep {defined $plot->{$_}} ('vmax', 'vmin')) { # numeric
		$opts .= ", $opt = $plot->{$opt}";
	}
	say { $args->{fh} } "im$ax = ax$ax.imshow(d $opts)";#, labels = labels $opt)";
	$opts = '';
	foreach my $o (grep {defined $plot->{$_}} ('cblabel', 'cblocation', 'cborientation')) { #str
		my $mpl_opt = $o;
		$mpl_opt =~ s/^cb//;
		$opts .= ", $mpl_opt = '$plot->{$o}'";
	}
	foreach my $o (grep {defined $plot->{$_}} ('cbdrawedges')) { # numeric
		my $mpl_opt = $o;
		$mpl_opt =~ s/^cb//;
		$opts .= ", $mpl_opt = $plot->{$o}";
	}
	say { $args->{fh} } "fig.colorbar(im$ax $opts)";
}

sub pie_helper {
    my ($args) = @_;
    my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
      ; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
    unless ( ref $args eq 'HASH' ) {
        die
"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
    }
    my @reqd_args = (
        'ax',
        'fh',      # e.g. $py, $fh, which will be passed by the subroutine
        'plot',    # args to original function
    );
    my @undef_args = grep { !defined $args->{$_} } @reqd_args;
    if ( scalar @undef_args > 0 ) {
        p @undef_args;
        die 'the above args are necessary, but were not defined.';
    }
    my @opt = (
        @ax_methods, @plt_methods, @fig_methods, @arg,
        'autopct',    # percent wise
        'ax',
#labeldistance and pctdistance are ratios of the radius; therefore they vary between 0 for the center of the pie and 1 for the edge of the pie, and can be set to greater than 1 to place text outside the pie https://matplotlib.org/stable/gallery/pie_and_polar_charts/pie_features.html
        'labeldistance',
        'pctdistance',
    );
    @opt = grep {$_ !~ m/^(?:$cb_regex)$/} @opt; # args that shouldn't apply
    my $plot      = $args->{plot};
    my @undef_opt = grep {
        my $key = $_;
        not grep { $_ eq $key } @opt
    } keys %{$plot};
    if ( scalar @undef_opt > 0 ) {
        p @undef_opt;
        die
"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
    }
    my @key_order;
    if ( defined $plot->{'key.order'} ) {
        @key_order = @{ $plot->{'key.order'} };
    }
    else {
        @key_order = sort keys %{ $plot->{data} };
    }
    $plot->{autopct} = $plot->{autopct} // '';
    my $opt = '';
    if ( $plot->{autopct} ne '' ) {
        $opt .= ", autopct = '$plot->{autopct}'";
    }
    foreach
      my $arg ( grep { defined $plot->{$_} } 'labeldistance', 'pctdistance' )
    {
        $opt .= ", $arg = $plot->{$arg}";
    }
    say { $args->{fh} } 'labels = ["' . join( '","', @key_order ) . '"]';
    say { $args->{fh} } 'vals = ['
      . join( ',', @{ $plot->{data} }{@key_order} ) . ']';
    my $ax = $args->{ax} // '';
    say { $args->{fh} } "ax$ax.pie(vals, labels = labels $opt)";
}

sub plot_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',
		'fh',      # e.g. $py, $fh, which will be passed by the subroutine
		'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @fig_methods, @arg, @plt_methods,
	  'key.order',      # an array of key strings (which are defined in data)
	  'show.legend',    # be default on; should be 0 if off
	  'set.options'
	);
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
	  p $args;
	  p @undef_opt;
	  die	"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
	}
	$plot->{'show.legend'} = $plot->{'show.legend'} // 1;
	if (ref $plot->{data} eq 'ARRAY') {
		if (defined $plot->{'set.options'}) {
			my $ref_type = ref $plot->{'set.options'};
			unless ($ref_type eq 'ARRAY') {
				p $args;
				die "\"set.options\" must also be an array when the data is an array, but \"$ref_type\" was given." ;
			}
			my $n_set_opt = scalar @{ $plot->{'set.options'} };
			my $n_data = scalar @{ $plot->{data} };
			if ($n_set_opt > $n_data) {
				p $args;
				die "there are $n_set_opt sets for options, but only $n_data data points.";
			}
		}
		my $arr_i = 0;
		foreach my $arr (@{ $plot->{data} }) {
			my $options = '';
			say { $args->{fh} } 'x = [' . join( ',', @{ $arr->[0] } ) . ']';
			say { $args->{fh} } 'y = [' . join( ',', @{ $arr->[1] } ) . ']';
			if (   ( defined $plot->{'set.options'} )
				&& ( ref $plot->{'set.options'} eq '' ) )
			{
				$options = ", $plot->{'set.options'}";
			}
			if ( defined $plot->{'set.options'}[$arr_i] ) {
				$options = ", $plot->{'set.options'}[$arr_i]";
			}
			say { $args->{fh} } "ax$args->{ax}.plot(x, y $options) # " . __LINE__;
			$arr_i++;
		}
		return 0; # the rest only applies if $plot->{data} is a hash
	}
	my @key_order;
	if ( defined $plot->{'key.order'} ) {
		@key_order = @{ $plot->{'key.order'} };
	} else {
		@key_order = sort keys %{ $plot->{data} };
	}
	if ((defined $plot->{'set.options'}) && (ref $plot->{'set.options'} eq 'HASH')) {
		my @undef_set_opt = sort grep {!defined $plot->{data}{$_}} keys %{ $plot->{'set.options'} };
		if (scalar @undef_set_opt > 0) {
			p @undef_set_opt;
			die "the above options are defined for undefined data sets in $current_sub.";
		}
	}
	foreach my $set (@key_order) {
		my $set_ref = ref $plot->{data}{$set};
		if ( $set_ref ne 'ARRAY' ) {
			p $plot->{data}{$set};
			die "$set must have two arrays, x and y coordinates, but instead has a $set_ref";
		}
		my $n_arrays = scalar @{ $plot->{data}{$set} };
		if ( $n_arrays != 2 ) {
			p $plot->{data}{$set};
			die "$n_arrays were entered for $set, but there must be exactly 2";
		}
		my ( $nx, $ny ) = (
			scalar @{ $plot->{data}{$set}[0] },
			scalar @{ $plot->{data}{$set}[1] }
		);
		if ( $nx != $ny ) {
			p $plot->{data}{$set};
			die "$set has length = $nx for x; length = $ny for y: x & y must be of equal length";
		}
		foreach my $ax (0,1) {
			my $n = scalar @{ $plot->{data}{$set}[$ax] };
			my @undef_i = grep {not defined $plot->{data}{$set}[$ax][$_]} 0..$n-1;
			if (scalar @undef_i > 0) {
				p $plot->{data}{$set}[$ax];
				p @undef_i;
				my $n_undef = scalar @undef_i;
				die "set $set axis $ax has $n_undef undefined values, of $n total values";
			}
		}
		my $options = '';
		say { $args->{fh} } 'x = ['
		 . join( ',', @{ $plot->{data}{$set}[0] } ) . ']';
		say { $args->{fh} } 'y = ['
		 . join( ',', @{ $plot->{data}{$set}[1] } ) . ']';
		if (   ( defined $plot->{'set.options'} )
			&& ( ref $plot->{'set.options'} eq '' ) )
		{
			$options = ", $plot->{'set.options'}";
		}
		if ( defined $plot->{'set.options'}{$set} ) {
			$options = ", $plot->{'set.options'}{$set}";
		}
		my $label = '';
		if ( $plot->{'show.legend'} > 0 ) {
			$label = ",label = '$set'";
		}
		say { $args->{fh} } "ax$args->{ax}.plot(x, y $label $options) # " . __LINE__;
	}
	return 0;
}

sub scatter_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
	  die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'ax',
	  'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'color_key',    # which of data keys is the color key
	  'cmap',         # for 3-set scatterplots; default "gist_rainbow"
	  'keys'
	  , # specify the order, otherwise alphabetical #'log', # if set to > 1, the y-axis will be logarithmic # 's', # float or array-like, shape (n, ), optional. The marker size in points**2 (typographic points are 1/72 in.).
	  'set.options'    # color = 'red', marker = 'v', etc.
	);
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		p @undef_opt;
		die	"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
	}
	my $overall_ref = ref $plot->{data};
	unless ( $overall_ref eq 'HASH' ) {
		die
	"scatter only takes 1) hashes of arrays (single or 2) hash of hash of arrays; but $overall_ref was entered";
	}
	my ( %ref_counts, $plot_type );
	foreach my $set ( keys %{ $plot->{data} } ) {
		$ref_counts{ ref $plot->{data}{$set} }++;
	}
	my $ax = $args->{ax};
	if ( scalar %ref_counts > 1 ) {
		p $plot->{data};
		die "different kinds of data were entered to plot $ax; should be simple hash or hash of arrays.";
	}
	if ( defined $ref_counts{ARRAY} ) {
		$plot_type = 'single';
	} elsif ( defined $ref_counts{HASH} ) {
		$plot_type = 'multiple';
	} else {
		p $plot->{data};
		p %ref_counts;
		die 'Could not determine scatter type for the above data.';
	}
	$plot->{cmap} = $plot->{cmap} // 'gist_rainbow';
	my $options = '';
	if ( $plot_type eq 'single' ) { # only a single set of data
		my ( $color_key, @keys );
		if ( defined $plot->{'keys'} ) {
		@keys = @{ $plot->{'keys'} };
		} else {
			@keys = sort { lc $a cmp lc $b } keys %{ $plot->{data} };
		}
		my $n_keys = scalar keys %{ $plot->{data} };
		if ( ( $n_keys != 2 ) && ( $n_keys != 3 ) ) {
			p $plot->{data};
			die
		"scatterplots can only take 2 or 3 keys as data, but $current_sub received $n_keys";
		}
		if ( defined $plot->{color_key} ) {
			$color_key = $plot->{color_key};
			my $i = 0;
			foreach my $key (@keys) {
		#            while ( my ( $i, $key ) = each @keys ) {
				 next unless $key eq $plot->{color_key};
				 splice @keys, $i, 1;    # remove the color key from @keys
				 $i++;
			}
		} elsif ( scalar @keys == 3 ) {
			$color_key = pop @keys;
		}    #			my $options = '';# these args go to the plt.hist call
		say { $args->{fh} } 'x = ['
		 . join( ',', @{ $plot->{data}{ $keys[0] } } ) . ']';
		say { $args->{fh} } 'y = ['
		 . join( ',', @{ $plot->{data}{ $keys[1] } } ) . ']';
		if (   ( defined $plot->{'set.options'} )
			&& ( ref $plot->{'set.options'} eq '' ) )
		{
			$options = ", $plot->{'set.options'}";
		}
		if ( defined $color_key ) {
			say { $args->{fh} } 'z = ['
			  . join( ',', @{ $plot->{data}{$color_key} } ) . ']';
			say { $args->{fh} }
			  "im = ax$ax.scatter(x, y, c = z, cmap = 'gist_rainbow' $options)";
			say { $args->{fh} } "fig.colorbar(im, label = '$color_key')";
		} else {
			say { $args->{fh} } "ax$ax.scatter(x, y, $options)";
		}
		$plot->{xlabel} = $plot->{xlabel} // $keys[0];
		$plot->{ylabel} = $plot->{ylabel} // $keys[1];
	} elsif ( $plot_type eq 'multiple' ) { # multiple sets
		my @undefined_opts;
		foreach my $set ( sort keys %{ $plot->{'set.options'} } ) {
			next if grep { $set eq $_ } keys %{ $plot->{data} };
			push @undefined_opts, $set;
		}
		if ( scalar @undefined_opts > 0 ) {
			p $plot->{data};
			p $plot;
			say 'The data and options are above, but the following sets have options without data:';
			p @undefined_opts;
			die 'no data was defined for the above options';
		}
		my $color_key;
		foreach my $set ( sort keys %{ $plot->{data} } ) {
			my @keys;
			if ( defined $plot->{'keys'} ) {
				 @keys = @{ $plot->{'keys'} };
			} else { # automatically take the key from the first; further sets should have the same labels
				 @keys = sort { lc $a cmp lc $b } keys %{ $plot->{data}{$set} };
			}
			my $n_keys = scalar keys %{ $plot->{data}{$set} };
			if ( ( $n_keys != 2 ) && ( $n_keys != 3 ) ) {
				 p $plot->{data}{$set};
				 die
			"scatterplots can only take 2 or 3 keys as data, but $current_sub received $n_keys";
			}
			if ( ( not defined $color_key ) && ( $n_keys == 3 ) ) {
				 $color_key = pop @keys;
			}
			if ( defined $plot->{'set.options'}{$set} ) {
				 $options = ", $plot->{'set.options'}{$set}";
			}
			say { $args->{fh} } 'x = ['
			  . join( ',', @{ $plot->{data}{$set}{ $keys[0] } } ) . ']';
			say { $args->{fh} } 'y = ['
			  . join( ',', @{ $plot->{data}{$set}{ $keys[1] } } ) . ']';
			if ( defined $color_key ) {
				 say { $args->{fh} } 'z = ['
					. join( ',', @{ $plot->{data}{$set}{$color_key} } ) . ']';
				 unless ( $options =~ m/label\s*=/ ) {
					  $options .= ", label = '$set'";
				 }
				 say { $args->{fh} }
			"im = ax$ax.scatter(x, y, c = z, cmap = '$plot->{cmap}' $options)";
			} else {
				 say { $args->{fh} }
					"ax$ax.scatter(x, y, label = '$set' $options)";
			}
			$plot->{xlabel} = $plot->{xlabel} // $keys[0];
			$plot->{ylabel} = $plot->{ylabel} // $keys[1];
	  }
	  say { $args->{fh} } "plt.colorbar(im, label = '$color_key')"  if defined $color_key;
	}
}

sub violin_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'ax',       # used for multiple plots
	  'color'
	  , # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
	  'colors',
	  'key.order',
	  'log',            # if set to > 1, the y-axis will be logarithmic
	  'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
	  'whiskers',
	  'plots', 'ncols', 'nrows', 'output.file', 'fh',
	  'execute'         # these will be ignored
	);
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		p @undef_opt;
		die "The above arguments aren't defined for $plot->{'plot.type'} using $current_sub";
	}
	$plot->{orientation} = $plot->{orientation} // 'vertical';
	if ( $plot->{orientation} !~ m/^(?:horizontal|vertical)$/ ) {
	  die
	"$current_sub needs either \"horizontal\" or \"vertical\", not \"$plot->{orientation}\"";
	}
	$args->{whiskers} = $args->{whiskers} // 1;    # by default, make whiskers
	my ( @xticks, @key_order );
	if ( defined $plot->{'key.order'} ) {
	  @key_order = @{ $plot->{'key.order'} };
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	my $ax = $args->{ax} // '';
	$plot->{medians}  = $plot->{medians}  // 1; # by default, show median values
	$plot->{whiskers} = $plot->{whiskers} // 1;
	$plot->{edgecolor} = $plot->{edgecolor} // 'black';
	my $options = '';    # these args go to the plt.hist call
	if ( ( defined $plot->{'log'} ) && ( $plot->{'log'} > 0 ) ) {
	  $options .= ', log = True';
	}
	say { $args->{fh} } 'd = []';
	my $min_n_points = 'inf';
	foreach my $key (@key_order) {
	  @{ $plot->{data}{$key} } = grep { defined } @{ $plot->{data}{$key} };
	  say { $args->{fh} } 'd.append(['
		 . join( ',', @{ $plot->{data}{$key} } ) . '])';
	  $min_n_points = min( scalar @{ $plot->{data}{$key} }, $min_n_points );
	}
	say { $args->{fh} }
	"vp = ax$ax.violinplot(d, showmeans=False, points = $min_n_points, orientation = '$plot->{orientation}', showmedians = $plot->{medians})";
	if ( defined $plot->{colors} ) { # every hash key should have its own color defined
		# the below code helps to provide better error messages in case I make an error in calling the sub
		my @wrong_keys = grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
		if ( scalar @wrong_keys > 0 ) {
			p $plot;
			p @wrong_keys;
			die 'the above data keys have no defined color';
		}
		# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
		print { $args->{fh} } 'colors = ["'
		 . join( '","', @{ $plot->{colors} }{@key_order} ) . '"]' . "\n";

		# the above color list will have the same order, via the above hash slice
		say { $args->{fh} } 'for i, pc in enumerate(vp["bodies"], 1):';
		say { $args->{fh} } "\tpc.set_facecolor(colors[i-1])";
		say { $args->{fh} } "\tpc.set_edgecolor('black')";
	} else {
		say { $args->{fh} } 'for pc in vp["bodies"]:';
		if ( defined $plot->{color} ) {
			print { $args->{fh} } "\tpc.set_facecolor('$plot->{color}')\n";
		}
		print { $args->{fh} } "\tpc.set_edgecolor('black')\n";

		#		say {$args->{fh}} "\tpc.set_alpha(1)";
	}
	if ( $plot->{whiskers} > 0 ) {
	 # https://matplotlib.org/stable/gallery/statistics/customized_violin.html
	  say { $args->{fh} } 'import numpy as np';
	  say { $args->{fh} } 'def adjacent_values(vals, q1, q3):';
	  say { $args->{fh} } '	upper_adjacent_value = q3 + (q3 - q1) * 1.5';
	  say { $args->{fh} }
		 '	upper_adjacent_value = np.clip(upper_adjacent_value, q3, vals[-1])';
	  say { $args->{fh} } '	lower_adjacent_value = q1 - (q3 - q1) * 1.5';
	  say { $args->{fh} }
		 '	lower_adjacent_value = np.clip(lower_adjacent_value, vals[0], q1)';
	  say { $args->{fh} }
		 '	return lower_adjacent_value, upper_adjacent_value';
	  say { $args->{fh} } 'np_data = np.array(d, dtype = object)';
	  say { $args->{fh} } 'quartile1 = []';
	  say { $args->{fh} } 'medians   = []';
	  say { $args->{fh} } 'quartile3 = []';
	  say { $args->{fh} } 'for subset in list(range(0, len(np_data))):';
	  say { $args->{fh} }
	'	local_quartile1, local_medians, local_quartile3 = np.percentile(d[subset], [25, 50, 75])' . "\n";
	  say { $args->{fh} } '	quartile1.append(local_quartile1)';
	  say { $args->{fh} } '	medians.append(local_medians)';
	  say { $args->{fh} } '	quartile3.append(local_quartile3)';
	  say { $args->{fh} } 'whiskers = np.array([';
	  say { $args->{fh} } '    adjacent_values(sorted_array, q1, q3)';
	  say { $args->{fh} }
		 '    for sorted_array, q1, q3 in zip(d, quartile1, quartile3)])';
	  say { $args->{fh} }
		 'whiskers_min, whiskers_max = whiskers[:, 0], whiskers[:, 1]';
	  say { $args->{fh} } 'inds = np.arange(1, len(medians) + 1)';
	  if ( $plot->{orientation} eq 'vertical' ) {
		   say { $args->{fh} } "ax$ax"
		     . '.vlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=5)';
		   say { $args->{fh} } "ax$ax"
		     . '.vlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=1)';
	  } else {
		   say { $args->{fh} } "ax$ax"
		     . '.hlines(inds, quartile1, quartile3, color="k", linestyle="-", lw=5)';
		   say { $args->{fh} } "ax$ax"
		     . '.hlines(inds, whiskers_min, whiskers_max, color="k", linestyle="-", lw=1)';
	  }
	}
	foreach my $key (@key_order) {
	  push @xticks, "$key ("
		 . format_commas( scalar @{ $plot->{data}{$key} }, '%.0u' ) . ')';
	  if ( $plot->{orientation} eq 'vertical' ) {
		   say { $args->{fh} } "ax$ax.plot("
		     . scalar @xticks . ', '
		     . ( sum( @{ $plot->{data}{$key} } ) /
		         scalar @{ $plot->{data}{$key} } )
		     . ', "ro")';    # plot mean point, which is red
	  }
	  else {                # orientation = horizontal
		   say { $args->{fh} } "ax$ax.plot("
		     . ( sum( @{ $plot->{data}{$key} } ) /
		         scalar @{ $plot->{data}{$key} } )
		     . ', '
		     . scalar @xticks
		     . ', "ro")';    # plot mean point, which is red
	  }
	}
	if ( $plot->{orientation} eq 'vertical' ) {
	  say { $args->{fh} } "ax$ax.set_xticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ["'
		 . join( '","', @xticks ) . '"])';
	} else {
	  say { $args->{fh} } "ax$ax.set_yticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ["'
		 . join( '","', @xticks ) . '"])';
	}
}

sub wide_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
	  die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'fh',      # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
		p @undef_args;
		die "the above args are necessary for $current_sub, but were not defined.";
	}
	my @opt = (
	  @ax_methods, @plt_methods, @fig_methods, @arg,
	  'color',		   # a hash, with each key assigned to a color "blue" or something
	  'show.legend',  # be default on; should be 0 if off
	);
	my $plot      = $args->{plot};
	$plot->{'show.legend'} = $plot->{'show.legend'} // 1;
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
	  p @undef_opt;
	  die
	"The above arguments aren't defined for $plot->{'plot.type'} using $current_sub";
	}
	say { $args->{fh} } 'import numpy as np';
	my $ax       = $args->{ax} // '';
	my $ref_type = ref $plot->{data};
	if ( $ref_type eq 'HASH' ) {    # multiple groups, no label
		foreach my $group ( keys %{ $plot->{data} } ) {
			my $color = $plot->{color}{$group} // 'b';
			say { $args->{fh} } 'ys = []';
			my ( $min_x, $max_x ) = ( 'inf', '-inf' );
			foreach my $run ( 0 .. scalar @{ $plot->{data}{$group} } - 1 ) {
				$min_x = min( $min_x, @{ $plot->{data}{$group}[$run][0] } );
				$max_x = max( $max_x, @{ $plot->{data}{$group}[$run][0] } );
			}
			say { $args->{fh} } "base_y = np.linspace($max_x, $min_x, 101)";
			foreach my $run ( 0 .. scalar @{ $plot->{data}{$group} } - 1 ) {
				say { $args->{fh} } 'x = ['
				. join( ',', @{ $plot->{data}{$group}[$run][0] } ) . ']';
				say { $args->{fh} } 'y = ['
				. join( ',', @{ $plot->{data}{$group}[$run][1] } ) . ']';
				say { $args->{fh} } "ax$ax.plot(x, y, '$color', alpha=0.15)";
				say { $args->{fh} } 'y = np.interp(base_y, x, y)';
				say { $args->{fh} } 'ys.append(y)';
			}
			say { $args->{fh} } 'ys = np.array(ys)';
			say { $args->{fh} } 'mean_ys = ys.mean(axis=0)';
			say { $args->{fh} } 'std = ys.std(axis=0)';
			say { $args->{fh} } 'ys_upper = np.minimum(mean_ys + std, 1)';
			say { $args->{fh} } 'ys_lower = mean_ys - std';
			if ( $plot->{'show.legend'} > 0 ) {
				say { $args->{fh} } "ax$ax.plot(base_y, mean_ys, '$color', label = '$group')";
			} else {
				say { $args->{fh} } "ax$ax.plot(base_y, mean_ys, '$color')";
			}
			say { $args->{fh} }
		"ax$ax.fill_between(base_y, ys_lower, ys_upper, color='$color', alpha=0.3)";
		}
	} elsif ( $ref_type eq 'ARRAY' ) {
		my $color = $plot->{color} // 'b';
		say { $args->{fh} } 'ys = []';
		my ( $min_x, $max_x ) = ( 'inf', '-inf' );
		foreach my $run ( 0 .. scalar @{ $plot->{data} } - 1 ) {
			$min_x = min( $min_x, @{ $plot->{data}[$run][0] } );
			$max_x = max( $max_x, @{ $plot->{data}[$run][0] } );
		}
		say { $args->{fh} } "base_y = np.linspace($max_x, $min_x, 101)";
		foreach my $run ( 0 .. scalar @{ $plot->{data} } - 1 ) {
			say { $args->{fh} } 'x = ['
			  . join( ',', @{ $plot->{data}[$run][0] } ) . ']';
			say { $args->{fh} } 'y = ['
			  . join( ',', @{ $plot->{data}[$run][1] } ) . ']';
			say { $args->{fh} } "ax$ax.plot(x, y, '$color', alpha=0.15)";
			say { $args->{fh} } 'y = np.interp(base_y, x, y)';
			say { $args->{fh} } 'ys.append(y)';
		}
		say { $args->{fh} } 'ys = np.array(ys)';
		say { $args->{fh} } 'mean_ys = ys.mean(axis=0)';
		say { $args->{fh} } 'std = ys.std(axis=0)';
		say { $args->{fh} } 'ys_upper = np.minimum(mean_ys + std, 1)';
		say { $args->{fh} } 'ys_lower = mean_ys - std';
		say { $args->{fh} } "ax$ax.plot(base_y, mean_ys, '$color')";
		say { $args->{fh} }
		"ax$ax.fill_between(base_y, ys_lower, ys_upper, color='$color', alpha=0.3)";
	} else {
	  die "$current_sub cannot take ref type \"$ref_type\" for \"data\"";
	}
}

sub print_type {
	my $str = shift;
	my $type = 'no quotes';
   if ($str =~ m/^\w+$/) {
   	return 'single quotes';
   } elsif ($str =~ m/[!@#\$\%^&*\(\)\{\}\[\]\<\>,\/\-\h:;\+=\w]+$/) {
   	return 'single quotes';
   } elsif (($str =~ m/,/) && ($str !~ m/[\]\[]/)) {
   	say __LINE__;
   	return 'single quotes';
   }
   return $type;
}

sub plt {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	unless ( ref $args eq 'HASH' ) {
	  die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'output.file',    # e.g. "my_image.svg"
	);
	my $single_example = 'plt({
	\'output.file\' => \'/tmp/gospel.word.counts.svg\',
	\'plot.type\'       => \'bar\',
	data              => {
	\'Matthew\' => 18345,
	\'Mark\'    => 11304,
	\'Luke\'    => 19482,
	\'John\'    => 15635,
	}
	});';
	my $multi_example = 'plt({
	\'output.file\'	=> \'svg/pie.svg\',
	plots             => [
	{
		data	=> {
		 Russian => 106_000_000,  # Primarily European Russia
		 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
		},
		\'plot.type\'	=> \'pie\',
		title       => \'Top Languages in Europe\',
		suptitle    => \'Pie in subplots\',
	},
	{
		data	=> {
		 Russian => 106_000_000,  # Primarily European Russia
		 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
		},
		\'plot.type\'	=> \'pie\',
		title       => \'Top Languages in Europe\',
	},
	ncols    => 3,
	});';
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	if (   ( not defined $args->{'plot.type'} )
	  && ( not defined $args->{plots} ) )
	{
		p $args;
		die 'either "plot.type" or "plots" must be defined, but neither were';
	}
	my @defined_args = (
	@reqd_args, @ax_methods, @fig_methods,  @plt_methods, @cb_arg,
	@arg,       'add', 'key.order', 'set.options', 'color', 'scale',
	'colors',   'show.legend', @colored_table_args
	);
	my @bad_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @defined_args
	} keys %{$args};
	if ( scalar @bad_args > 0 ) {
	  p @defined_args, array_max => scalar @defined_args;
	  p @bad_args, array_max => scalar @bad_args;
	  say STDERR 'the 2nd group of arguments are not recognized, while the 1st is the defined list';
	  die "The above args are accepted by \"$current_sub\"";
	}
	my $single_plot = 0; # false
	if ( ( defined $args->{'plot.type'} ) && ( defined $args->{data} ) ) {
	  $single_plot = 1; # true
	}
	if ( ( $single_plot == 1 ) && ( not defined $args->{'plot.type'} ) ) {
	  p $args;
	  say $single_example;
	  die "\"plot.type\" was not defined for a single plot in $current_sub";
	}
	if ( ( $single_plot == 0 ) && ( not defined $args->{plots} ) ) {
		say $multi_example;
		die "$current_sub: single plots need \"data\" and \"plot.type\", see example above";
	}
	if ( ( $single_plot == 0 ) && ( ref $args->{plots} ne 'ARRAY' ) ) {
	  p $args;
	  die "$current_sub \"plots\" must have an array entered into it";
	}
	if ( ( $single_plot == 0 ) && ( scalar @{ $args->{plots} } == 0 ) ) {
	  p $args;
	  die "$current_sub \"plots\" has 0 plots entered.";
	}
	if ($single_plot == 1) {
	 foreach my $arg (grep {defined $args->{$_} && $args->{$_} > 1} ('ncols', 'nrows')) {
	 	warn "\"$arg\" is set to >1, but there is only 1 plot: resetting $arg to 1.";
	 	$args->{$arg} = 1;
	 }
	}
	$args->{nrows} = $args->{nrows} // 1;
	$args->{ncols} = $args->{ncols} // 1;
	if (   ( $single_plot == 0 )
	  && ( ( $args->{nrows} * $args->{ncols} ) < scalar @{ $args->{plots} } )
	)
	{
	  p $args;
	  my $n_plots = scalar @{ $args->{plots} };
	  say
	"ncols = $args->{ncols}; nrows = $args->{nrows}, but there are $n_plots plots.\n";
	  die 'There are not enough subplots for the data';
	}
	my @ax = map { "ax$_" } 0 .. $args->{nrows} * $args->{ncols} - 1;
	my ( @py, @y, $fh, $temp_py );
	my $i = 0;
	foreach my $ax (@ax) {
		my $a1i = int $i / $args->{ncols};    # 1st index
		my $a2i = $i % $args->{ncols};        # 2nd index
		$y[$a1i][$a2i] = $ax;
		$i++;
	}
	foreach my $y (@y) {
		push @py, '(' . join( ',', @{$y} ) . ')';
	}
	if ( defined $args->{fh} ) {
		$fh = $args->{fh};# open $fh, '>>', $args->{fh};
	} else {
		$fh = File::Temp->new( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );
	}
	say 'temp file is ' . $fh->filename;# if $unlink == 0;
	say $fh 'import matplotlib.pyplot as plt';
	if ( $single_plot == 0 ) {
		$args->{sharex} = $args->{sharex} // 'False';
		say $fh 'fig, ('
		 . join( ',', @py )
		 . ") = plt.subplots($args->{nrows}, $args->{ncols}, sharex = $args->{sharex}, layout = 'constrained') #" . __LINE__;
	} elsif ( $single_plot == 1 ) {
		say $fh 'fig, ax0 = plt.subplots(1,1, layout = "constrained")';
	} else {
		die "\$single_plot = $single_plot breaks pigeonholes";
	}
	if ( defined $args->{plots} ) {
		my @undef_plot_types;
		my $i = 0;
		foreach my $plot (@{ $args->{plots} }) {
			next if defined $plot->{'plot.type'};
			push @undef_plot_types, $i;
			$i++;
		}
		if ( scalar @undef_plot_types > 0 ) {
			p $args;
			p @undef_plot_types;
			die 'The above subplot indices are missing "plot.type"';
		}
	}
#	my $find_global_min_max = scalar grep { $_->{'plot.type'} eq 'hist2d' } @{ $args->{plots} };
#	if ( $find_global_min_max > 0 ) {
#		say $fh 'global_max = float("-inf")';
#		say $fh 'global_min = float("inf")';
#	}
	if ($single_plot == 1) {
		foreach my $graph (@{ $args->{add} }) {
			if ( $args->{'plot.type'} =~ m/^barh?$/ ) {  # barplot: "bar" and "barh"
				barplot_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'boxplot' ) {
				boxplot_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'colored_table') {
				colored_table_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'hexbin' ) {
				hexbin_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'hist' ) {    # histogram
				hist_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
			  });
			} elsif ( $args->{'plot.type'} eq 'hist2d' ) {
				hist2d_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'imshow' ) {
				imshow_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'pie' ) {
				pie_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $args
				});
			} elsif ( $args->{'plot.type'} eq 'plot' ) {
				plot_helper({
					fh   => $fh,
					ax   => 0,
					plot => $graph
				});
			} elsif ( $args->{'plot.type'} eq 'scatter' ) {    # scatterplot
				scatter_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $graph
				 });
			} elsif ( $args->{'plot.type'} eq 'violinplot' ) {
				violin_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $graph
			  });
			} elsif ( $args->{'plot.type'} eq 'wide' ) {
				wide_helper({
				  fh   => $fh,
				  ax   => 0,
				  plot => $graph
				});
			} else {
				die "$args->{'plot.type'} doesn't fit pigeonholes with \$single_plot = $single_plot";
			} # sometimes, I need "ax" methods instead of plt, while keeping calling simpler
		}
		delete $args->{add};
	}
	if ($single_plot == 1) {
		if ( not defined $args->{'plot.type'} ) {
			die "\"plot.type\" is not defined for \"$current_sub\"";
		}
		if ( $args->{'plot.type'} =~ m/^barh?$/ ) {  # barplot: "bar" and "barh"
			barplot_helper({
				fh   => $fh,
				ax   => 0,
				plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'boxplot' ) {
			boxplot_helper({
				fh   => $fh,
				ax   => 0,
				plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'colored_table') {
			colored_table_helper({
				fh   => $fh,
				ax   => 0,
				plot => $args
			});
		} elsif ($args->{'plot.type'} eq 'hexbin') {
			hexbin_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			});
		} elsif ($args->{'plot.type'} eq 'hist') {    # histogram
			hist_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
		  });
		} elsif ($args->{'plot.type'} eq 'hist2d') {
			hist2d_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'imshow' ) {
			imshow_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'pie' ) {
			pie_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'plot' ) {
			plot_helper({
				fh   => $fh,
				ax   => 0,
				plot => $args
			});
		} elsif ( $args->{'plot.type'} eq 'scatter' ) {    # scatterplot
			scatter_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			 });
		} elsif ( $args->{'plot.type'} eq 'violinplot' ) {
			violin_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
		  });
		} elsif ( $args->{'plot.type'} eq 'wide' ) {
			wide_helper({
			  fh   => $fh,
			  ax   => 0,
			  plot => $args
			});
		} else {
			die
		"$args->{'plot.type'} doesn't fit pigeonholes with \$single_plot = $single_plot";
		} # sometimes, I need "ax" methods instead of plt, while keeping calling simpler
		my %rename = (
			xlabel => 'set_xlabel',
			title  => 'set_title',
			ylabel => 'set_ylabel',
			legend => 'legend',
			xlim   => 'set_xlim',
		);
		foreach my $opt ( grep { defined $rename{$_} } keys %{$args} ) {
			$args->{ $rename{$opt} } = delete $args->{$opt};
		}
		plot_args({
			fh   => $fh,
			args => $args,
			ax   => 'ax0'
		});
	}
	my $ax = 0;
	foreach my $plot (@{ $args->{plots} } ) {
		foreach my $graph (@{ $plot->{add} }) {
			if ( $graph->{'plot.type'} =~ m/^barh?$/ ) {  # barplot: "bar" and "barh"
				barplot_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'boxplot' ) {
				boxplot_helper({
				  fh   => $fh,
				  ax   => $ax,
				  plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'colored_table' ) {
				colored_table_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'hexbin' ) {
				hexbin_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			}  elsif ( $graph->{'plot.type'} eq 'hist' ) {    # histogram
				hist_helper({
				  fh   => $fh,
				  ax   => $ax,
				  plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'hist2d' ) {
				hist2d_helper({
				  fh   => $fh,
				  ax   => $ax,
				  plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'imshow' ) {
				imshow_helper({
				  fh   => $fh,
				  ax   => $ax,
				  plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'pie' ) {
				pie_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'plot' ) {
				plot_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'scatter' ) {    # scatterplot
				scatter_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'violinplot' ) {
				violin_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} elsif ( $graph->{'plot.type'} eq 'wide' ) {
				wide_helper({
					fh   => $fh,
					ax   => $ax,
					plot => $graph
				});
			} else {
				die "\"$plot->{'plot.type'}\" doesn't fit pigeonholes with \$single_plot = $single_plot";
			}
		}
		delete $plot->{add};
		my @reqd_keys = (
			'data',         # data type, of which several are available
			'plot.type',    # "bar", "barh", "hist", etc.
		);
		my @undef_keys = grep { !defined $plot->{$_} } @reqd_keys;
		if ( scalar @undef_keys > 0 ) {
			p $plot;
			p @undef_keys;
			die "Above args are necessary, but were not defined for plot $ax.";
		}
		if ( $plot->{'plot.type'} =~ m/^barh?$/) {  # barplot: "bar" and "barh"
			barplot_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'boxplot') {
			boxplot_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'colored_table') {
			colored_table_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'hexbin' ) {
			hexbin_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		}  elsif ( $plot->{'plot.type'} eq 'hist' ) {    # histogram
			hist_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'hist2d' ) {
			hist2d_helper({
				fh   => $fh,
				ax   => $ax,
				plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'imshow' ) {
			imshow_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'pie' ) {
			pie_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
		  });
		} elsif ( $plot->{'plot.type'} eq 'plot' ) {
			plot_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'scatter' ) {    # scatterplot
			scatter_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'violinplot' ) {
			violin_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
			});
		} elsif ( $plot->{'plot.type'} eq 'wide' ) {
			wide_helper({
			  fh   => $fh,
			  ax   => $ax,
			  plot => $plot
			});
		} else {
			die "\"$plot->{'plot.type'}\" doesn't fit pigeonholes with \$single_plot = $single_plot";
		}
		my %rename = (
			xlabel => 'set_xlabel',
			title  => 'set_title',
			ylabel => 'set_ylabel',
			legend => 'legend',
			#			xlim => 'set_xlim',
		);
		foreach my $opt ( grep { defined $rename{$_} } keys %{$plot} ) {
			$plot->{ $rename{$opt} } = delete $plot->{$opt};
		}
		plot_args({
			fh   => $fh,
			args => $plot,
			ax   => "ax$ax"
		});
		$ax++;
	}
	foreach my $ax (@ax) {
		say $fh "if $ax.has_data() == False:";    # remove empty plots
		say $fh "\t$ax.remove()";                 # remove empty plots
	}
	my %methods = map { $_ => 1 } @plt_methods;
	foreach my $plt_method ( grep { defined $methods{$_} } keys %{$args} ) {
		my $ref = ref $args->{$plt_method};
		if ( $ref eq '' ) {
			my $type = print_type($args->{$plt_method});
			if ($type eq 'single quotes') {
				say $fh "plt.$plt_method('$args->{$plt_method}')#" . __LINE__;
			} elsif ($type eq 'no quotes') {
				say $fh "plt.$plt_method($args->{$plt_method})#" . __LINE__;
			}
		} elsif ( $ref eq 'ARRAY' ) {
			foreach my $j ( @{ $args->{$plt_method} } ) {
				my $type = print_type($j);
				if ($type eq 'single quotes') {
					say $fh "plt.$plt_method('$j')#" . __LINE__;
				} elsif ($type eq 'no quotes') {
					say $fh "plt.$plt_method($j)#" . __LINE__;
				}
			}
		} else {
			p $args;
			die "$plt_method = \"$ref\" only accepts scalar or array types";
		}
	}
	%methods = map { $_ => 1 } @fig_methods;
	foreach my $fig_method ( grep { defined $methods{$_} } keys %{$args} ) {
		my $ref = ref $args->{$fig_method};
		if ( $ref eq '' ) {
			say $fh "fig.$fig_method($args->{$fig_method})#" . __LINE__;
		} elsif ( $ref eq 'ARRAY' ) {
			foreach my $j ( @{ $args->{$fig_method} } ) {    # say $fh "plt.$method($plt)";
				say $fh "fig.$fig_method($j)";
			}
		} else {
			p $args;
			die "$fig_method = \"$ref\" only accepts scalar or array types";
		}
	}
	if (defined $args->{scale}) {
		say $fh "fig.set_figheight(plt.rcParams['figure.figsize'][1] * $args->{scale}) #" . __LINE__;
		say $fh "fig.set_figwidth(plt.rcParams['figure.figsize'][0] * $args->{scale}) #" . __LINE__;
	}
	say $fh
	"plt.savefig('$args->{'output.file'}', bbox_inches = 'tight', metadata={'Creator': 'made/written by "
	. getcwd()
	. "/$RealScript called using \"$current_sub\" in " . __FILE__ . "'})";
	$args->{execute} = $args->{execute} // 1;
	if ( $args->{execute} == 0 ) {
	  say $fh 'plt.close()';
	}
	if ( $args->{execute} > 0 ) {
		my $r = execute( 'python3 ' . $fh->filename, 'all' );
		say 'wrote '		
		 . colored( ['cyan on_bright_yellow'], "$args->{'output.file'}" );
		p $r;
	} else {    # not running yet
		say 'will write '
		 . colored( ['cyan on_bright_yellow'], "$args->{'output.file'}" );
	}
}

sub bar { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plot\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}
sub barh { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub boxplot { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}
sub colored_table {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutine \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub hist { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub hist2d { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub imshow { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plot\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub pie { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub plot {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub scatter { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub violin { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}

sub wide { # a wrapper to simplify calling
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ((defined $args->{'plot.type'}) && ($args->{'plot.type'} ne $current_sub)) {
		warn "$args->{'plot.type'} will be ignored for $current_sub";
	}
	if (defined $args->{plots}) {
		die "\"plots\" is meant for the subroutin \"plt\"; $current_sub is single-only";
	}
	plt({
		%{ $args },
		'plot.type' => $current_sub
	});
}
1;
# from md2pod.pl πατερ ημων ο εν τοις ουρανοις, ἁγιασθήτω τὸ ὄνομά σου
=encoding utf8

=head1 Synopsis

Take a data structure in Perl, and automatically write a Python3 script using matplotlib to generate an image.  The Python3 script is saved in C</tmp>, to be edited at the user's discretion.
Requires python3 and matplotlib installations.

=head1 Single Plots

Simplest use case:

 use Matplotlib::Simple 'plt';
 plt({
    'output.file'     => '/tmp/gospel.word.counts.png',
    'plot.type'       => 'bar',
    data              => {
       Matthew => 18345,
       Mark    => 11304,
       Luke    => 19482,
       John    => 15635,
    }
 });

where C<xlabel>, C<ylabel>, C<title>, etc. are axis methods in matplotlib itself. C<plot.type>, C<data>, C<fh> are all specific to C<MatPlotLib::Simple>.

As of version 0.11, all plot types are available as their own subroutines for making B<single> plots.
For example, the above code is equivalent to the shorter version:

 use Matplotlib::Simple 'bar';
 bar({
    'output.file'     => '/tmp/gospel.word.counts.png',
    data              => {
       Matthew => 18345,
       Mark    => 11304,
       Luke    => 19482,
       John    => 15635,
    }
 });


=for html
<p>
<img width="651" height="491" alt="gospel word counts" src="https://github.com/user-attachments/assets/a008dece-2e34-47bf-af0f-8603709f7d52" />
<p>


=head1 Multiple Plots

Having a C<plots> argument as an array lets the module know to create subplots:

 use Matplotlib::Simple 'plt';
 plt({
     'output.file'   => 'svg/pies.png',
     plots             => [
     {
             data    => {
              Russian => 106_000_000,  # Primarily European Russia
              German => 95_000_000,    # Germany, Austria, Switzerland, etc.
             },
             'plot.type' => 'pie',
             title       => 'Top Languages in Europe',
             suptitle    => 'Pie in subplots',
         },
         {
             data    => {
              Russian => 106_000_000,  # Primarily European Russia
              German => 95_000_000,    # Germany, Austria, Switzerland, etc.
             },
             'plot.type' => 'pie',
             title       => 'Top Languages in Europe',
         },
     ],
     ncols    => 2,
 });

which produces the following subplots image:


=for html
<p>
<img width="651" height="424" alt="pies" src="https://github.com/user-attachments/assets/49d3e28b-f897-4b01-9e72-38afa12fa538" />
<p>


C<bar>, C<barh>, C<boxplot>, C<hexbin>, C<hist>, C<hist2d>, C<imshow>, C<pie>, C<plot>, C<scatter>, and C<violinplot> all match the methods in matplotlib itself.
=head1 Examples/Plot Types

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

=head2 Barplot/bar/barh

Plot a hash or a hash of arrays as a boxplot

=head3 Options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>------- </td></tr>
<tr><td>color</td><td>:mpltype:<code>color</code> or list of :mpltype:<code>color</code>, optional; The colors of the bar faces. This is an alias for *facecolor*. If both are given, *facecolor* takes precedence # if entering multiple colors, quoting isn't needed</td><td><code>color => ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'fuchsia'],</code> or a single color for all bars <code>color => 'red'</code></td></tr>
<tr><td>edgecolor</td><td>:mpltype:<code>color</code> or list of :mpltype:<code>color</code>, optional; The colors of the bar edges</td><td><code>edgecolor     => 'black'</code></td></tr>
<tr><td>key.order</td><td>define the keys in an order (an array reference)</td><td><code>'key.order'        => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],</code></td></tr>
<tr><td>linewidth</td><td>float or array, optional; Width of the bar edge(s). If 0, don't draw edges. Only does anything with defined <code>edgecolor</code></td><td><code>linewidth => 2,</code></td></tr>
<tr><td>log</td><td>bool, default: False; If *True*, set the y-axis to be log scale.</td><td><code>log = 'True',</code></td></tr>
<tr><td>stacked</td><td>stack the groups on top of one another; default 0 = off</td><td><code>stacked   => 1,</code></td></tr>
<tr><td>width</td><td>float only, default: 0.8; The width(s) of the bars.  <code>width</code> will be deactivated with grouped, non-stacked bar plots</td><td><code>width => 0.4,</code></td></tr>
<tr><td>xerr</td><td>float or array-like of shape(N,) or shape(2, N), optional. If not *None*, add horizontal / vertical errorbars to the bar tips. The values are +/- sizes relative to the data:        - scalar: symmetric +/- values for all bars #        - shape(N,): symmetric +/- values for each bar #        - shape(2, N): Separate - and + values for each bar. First row #          contains the lower errors, the second row contains the upper #          errors. #        - *None*: No errorbar. (Default)</td><td><code>yerr                       => {'USA'               => [15,29], 'Russia'            => [199,1000],}</code></td></tr>
<tr><td>yerr</td><td>same as xerr, but better with bar</td><td></td></tr>
</tbody>
</table>

an example of multiple plots, showing many options:

=head3 single, simple plot

 use Matplotlib::Simple 'plt';
 plt({
     'output.file'           => 'output.images/single.barplot.png',
     data    => { # simple hash
         Fri => 76, Mon  => 73, Sat => 26, Sun => 11, Thu    => 94, Tue  => 93, Wed  => 77
     },
     'plot.type' => 'bar',
     xlabel      => '# of Days',
     ylabel      => 'Count',
     title       => 'Customer Calls by Days'
 });

where C<xlabel>, C<ylabel>, C<title>, etc. are axis methods in matplotlib itself. C<plot.type>, C<data>, C<fh> are all specific to C<MatPlotLib::Simple>.

=for html
<p>
<img width="651" height="491" alt="single barplot" src="https://github.com/user-attachments/assets/eae009a8-5571-4608-abdb-1016e3cff5fd" />
<p>


=head3 multiple plots

 plt({
     fh                  => $fh,
     execute                => 0,
     'output.file'   => 'output.images/barplots.png',
     plots                   => [
     { # simple plot
             data    => { # simple hash
                 Fri => 76, Mon  => 73, Sat => 26, Sun => 11, Thu    => 94, Tue  => 93, Wed  => 77
             },
             'plot.type' => 'bar',
            'key.order'      => ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'],
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
             'plot.type' => 'bar',
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
                   Germany => 11.2 #Rapid decrease due to war's end <br />
                 },
             },
             stacked => 0,
             title       => 'Hash of Hash Grouped Unstacked Barplot',
             width       => 0.23,
             xlabel  => 'r"$\it{anno}$ $\it{domini}$"', # italic
             ylabel  => 'Military Expenditure (Billions of $)'
         },
          { # grouped bar plot
             'plot.type' => 'bar',
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
             'plot.type' => 'barh',
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
             'plot.type' => 'bar'
         }, <br />
         { # nuclear weapons barplot
             'plot.type'     => 'bar',
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
 });

which produces the plot:


=for html
<p>
<img width="2678" height="849" alt="barplots" src="https://github.com/user-attachments/assets/6d87d13b-dabd-485d-92f7-1418f4acc65b" />
<p>


=head2 boxplot

Plot a hash of arrays as a series of boxplots

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>color</code></td><td>a single color for all plots</td><td><code>color => 'pink'</code></td></tr>
<tr><td><code>colors</code></td><td>a hash, where each data point and color is a hash pair</td><td><code>colors => { A => 'orange', E => 'yellow', B => 'purple' },</code></td></tr>
<tr><td><code>key.order</code></td><td>order that the keys in the entry hash will be plotted</td><td><code>key.order = ['A', 'E', 'B']</code></td></tr>
<tr><td><code>orientation</code></td><td>orientation of the plot, by default <code>vertical</code></td><td><code>orientation = 'horizontal'</code></td></tr>
<tr><td><code>showcaps</code></td><td>Show the caps on the ends of whiskers; default <code>True</code></td><td><code>showcaps => 'False',</code></td></tr>
<tr><td><code>showfliers</code></td><td>Show the outliers beyond the caps; default <code>True</code></td><td><code>showfliers  => 'False'</code></td></tr>
<tr><td><code>showmeans</code></td><td>show means; default = <code>True</code></td><td><code>showmeans   => 'False'</code></td></tr>
<tr><td><code>whiskers</code></td><td>show whiskers, default = 1</td><td><code> whiskers    => 0,</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

 my $x = generate_normal_dist( 100, 15, 3 * 10 );
 my $y = generate_normal_dist( 85,  15, 3 * 10 );
 my $z = generate_normal_dist( 106, 15, 3 * 10 );

single plots are simple

 use Matplotlib::Simple 'barplot';
 barplot({
     'output.file' => 'output.images/single.boxplot.png',
     data              => {                                     # simple hash
         E => [ 55,    @{$x}, 160 ],
         B => [ @{$y}, 140 ],
 
         #       A => @a
     },
     title        => 'Single Box Plot: Specified Colors',
     colors       => { E => 'yellow', B => 'purple' },
     fh           => $fh,
     execute      => 0,
 });

which makes the following image:


=for html
<p>
<img width="651" height="491" alt="single boxplot" src="https://github.com/user-attachments/assets/19870fa2-fe36-4513-8cbb-23da3a0cf686" />
<p>


=head3 multiple plots

 plt({
     'output.file' => 'output.images/boxplot.png',
     execute           => 0,
     fh => $fh,
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
             'plot.type' => 'boxplot',
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
             'plot.type' => 'boxplot'
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
             'plot.type' => 'boxplot',
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
             'plot.type' => 'boxplot',
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
             'plot.type' => 'boxplot',
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
             'plot.type' => 'boxplot',
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
             'plot.type'   => 'boxplot',
             set_figheight => 12,
         },
     ],
     ncols => 3,
     nrows => 3,
 });

which makes the following plot:


=for html
<p>
<img width="1230" height="1211" alt="boxplot" src="https://github.com/user-attachments/assets/7e32e394-86fc-49e7-ad97-f48fd82fc8b0" />
<p>


=head2 Colored Table

=head3 options

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

 colored_table({
     'cblabel'     => 'kJ/mol',
     'col.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
     data          => \%bond_dissociation,
     execute       => 0,
     fh            => $fh,
     mirror        => 1,
     'output.file' => 'output.images/single.tab.png',
     'row.labels'  => ['H', 'F', 'Cl', 'Br', 'I'],
     'show.numbers'=> 1,
     set_title     => 'Bond Dissociation Energy'
 });

which makes the following image:


=for html
<p>
<img width="584" height="491" alt="single tab" src="https://github.com/user-attachments/assets/d890830b-a502-4d51-b118-20aeae0473e8" />
<p>


=head3 Multiple Plots

 plt({
     'output.file' => 'output.images/tab.multiple.png',
     execute       => 0,
     fh            => $fh,
     plots         => [
         {
             data          => \%bond_dissociation,
             'output.file' => '/tmp/single.bonds.svg',
             'plot.type'   => 'colored_table',
             set_title     => 'No other options'
         },
         {
             data          => \%bond_dissociation,
             cblabel       => 'Average Dissociation Energy (kJ/mol)',
             'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             mirror        => 1,
             'output.file' => '/tmp/single.bonds.svg',
             'plot.type'   => 'colored_table',
             'row.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             'show.numbers'=> 1,
             set_title     => 'Showing numbers and mirror with defined order'
         },
         {
             data          => \%bond_dissociation,
             cblabel       => 'Average Dissociation Energy (kJ/mol)',
             'col.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             mirror        => 1,
             'output.file' => '/tmp/single.bonds.svg',
             'plot.type'   => 'colored_table',
             'row.labels'  => ['H', 'C', 'N', 'O', 'F', 'Si', 'S', 'Cl', 'Br', 'I'],
             'show.numbers'=> 1,
             set_title     => 'Set undefined color to white',
             'undef.color' => 'white'
         }
     ],
     ncols         => 3,
     set_figwidth  => 14,
     suptitle      => 'Colored Table options'
 });

which makes the following plot:


=for html
<p>
<img width="1410" height="491" alt="tab multiple" src="https://github.com/user-attachments/assets/be836742-cc5b-4618-a0c8-a0ee57856eb1" />
<p>


=head2 hexbin

Plot a hash of arrays as a hexbin
see https://matplotlib.org/stable/api/I<as>gen/matplotlib.pyplot.hexbin.html

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>------- </td></tr>
<tr><td>cb_logscale</td><td>colorbar log scale <code>from matplotlib.colors import LogNorm</code></td><td>default 0, any value > 0 enables</td></tr>
<tr><td>cmap</td><td>The Colormap instance or registered colormap name used to map scalar data to colors</td><td>default <code>gist_rainbow</code></td></tr>
<tr><td>key.order</td><td>define the keys in an order (an array reference)</td><td><code>'key.order' => ['X-rays', 'Yak Butter'],</code></td></tr>
<tr><td>marginals</td><td>integer, by default off = 0</td><td><code>marginals => 1</code></td></tr>
<tr><td>mincnt</td><td>int >= 0, default: None; If not None, only display cells with at least mincnt number of points in the cell.</td><td><code>mincnt => 2</code></td></tr>
<tr><td>vmax</td><td>The normalization method used to scale scalar data to the [0, 1] range before mapping to colors using cmap</td><td><code>'asinh', 'function', 'functionlog', 'linear', 'log', 'logit', 'symlog'</code> default <code>linear</code></td></tr>
<tr><td>vmin</td><td>The normalization method used to scale scalar data to the [0, 1] range before mapping to colors using cmap</td><td><code>'asinh', 'function', 'functionlog', 'linear', 'log', 'logit', 'symlog'</code> default <code>linear</code></td></tr>
<tr><td>xbins</td><td>integer that accesses horizontal gridsize</td><td>default is 15</td></tr>
<tr><td>xscale.hexbin</td><td>'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the horizontal axis</td><td><code>'xscale.hexbin' => 'log'</code></td></tr>
<tr><td>ybins</td><td>integer that accesses vertical gridsize</td><td>default is 15</td></tr>
<tr><td>yscale.hexbin</td><td>'linear', 'log'}, default: 'linear': Use a linear or log10 scale on the vertical axis</td><td><code>'yscale.hexbin' => 'log'</code></td></tr>
</tbody>
</table>

=head3 single, simple plot

 plt({
     data    => {
         E   => generate_normal_dist(100, 15, 3*210),
         B   => generate_normal_dist(85, 15, 3*210)
     },
     'output.file'   => 'output.images/single.hexbin.png',
     'plot.type' => 'hexbin',
     set_figwidth => 12,
     title           => 'Simple Hexbin',
 });

which makes the following plot:

=for html
<p>
<img width="1208" height="491" alt="single hexbin" src="https://github.com/user-attachments/assets/129c41cd-2d7d-43de-978a-2b9c441b8939" />
<p>

=head3 multiple plots

 plt({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/hexbin.png',
     plots             => [
         {
             data => {
             E => @e,
             B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'Simple Hexbin',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type' => 'hexbin',
             title       => 'colorbar logscale',
             cb_logscale => 1
         },
         {
             cmap => 'jet',
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'cmap is jet',
             xlabel       => 'xlabel',
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             'key.order'  => ['E', 'B'],
             'plot.type'  => 'hexbin',
             title        => 'Switch axes with key.order',
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'vmax set to 25',
             vmax         => 25
         },
          {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'vmin set to -4',
             vmin         => -4
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'mincnt set to 7',
             mincnt       => 7
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'xbins set to 9',
             xbins        => 9
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'ybins set to 9',
             ybins        => 9
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'marginals = 1',
             marginals    => 1
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'xscale.hexbin = 1',
             'xscale.hexbin' => 'log'
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'hexbin',
             title        => 'yscale.hexbin = 1',
             'yscale.hexbin' => 'log'
         },
     ],
     ncols        => 4,
     nrows        => 3,
     scale        => 5,
     suptitle     => 'Various Changes to Standard Hexbin: All data is the same'
 });

which produces the following image:

=for html
<p>
<img width="2409" height="3211" alt="hexbin" src="https://github.com/user-attachments/assets/0b23a0cb-8f9a-43fb-8da1-0debee13d540" />
<p>


=head2 hist

Plot a hash of arrays as a series of histograms

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>alpha</code></td><td>default 0.5; same for all sets</td><td></td></tr>
<tr><td><code>bins</code></td><td># nt or sequence or str, default: :rc:<code>hist.bins</code>If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open</td><td></td></tr>
<tr><td><code>color</code></td><td>a hash, where keys are the keys in data, and values are colors</td><td><code>X => 'blue'</code></td></tr>
<tr><td><code>log</code></td><td>if set to > 1, the y-axis will be logarithmic</td><td></td></tr>
<tr><td><code>orientation</code></td><td>{'vertical', 'horizontal'}, default: 'vertical'</td><td></td></tr>
</tbody>
</table>

=head3 single, simple plot

 use Matplotlib::Simple 'hist';
 
 my @e = generate_normal_dist( 100, 15, 3 * 200 );
 my @b = generate_normal_dist( 85,  15, 3 * 200 );
 my @a = generate_normal_dist( 105, 15, 3 * 200 );
 
 hist({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/single.hist.png',
     data              => {
         E => @e,
         B => @b,
         A => @a,
     }
 });

which makes the following simple plot:


=for html
<p>
<img width="651" height="491" alt="single hist" src="https://github.com/user-attachments/assets/fafcf787-6c4f-4998-88c4-77a15d878fa6" />
<p>


=head3 multiple plots

 plt({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/histogram.png',
    set_figwidth => 15,
    suptitle          => 'hist Examples',
     plots             => [
         { # 1st subplot
             data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             'plot.type' => 'hist',
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
             'plot.type' => 'hist',
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
                 'plot.type' => 'plot',
                 'set.options' => {
                     'Gaussian' =>  'color = "red", linestyle = "dashed"'
                 }
             }
             ],
            data => {
                 E => @e,
                 B => @b,
                 A => @a,
             },
             'plot.type' => 'hist',
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
             'plot.type' => 'hist',
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
 });


=for html
<p>
<img width="1511" height="491" alt="histogram" src="https://github.com/user-attachments/assets/b13b4cc8-6e64-40b0-913d-6a5886cee0db" />
<p>


Make a 2-D histogram from a hash of arrays

=head2 hist2d

=head3 single, simple plot

 plt({
     'output.file' => 'output.images/single.hist2d.png',
     data              => {
         E => @e,
         B => @b
     },
     'plot.type'  => 'hist2d',
     title        => 'title',
     execute      => 0,
     fh => $fh,
 });

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
<tr><td><code>cmap</code></td><td>color map for coloring # "gist_rainbow" by default</td><td></td></tr>
<tr><td>'cmax', <code>cmin</code></td><td>All bins that has count < *cmin* or > *cmax* will not be displayed</td><td></td></tr>
<tr><td>'density'</td><td>density : bool, default: False</td><td></td></tr>
<tr><td>'key.order'</td><td>define the keys in an order (an array reference)</td><td></td></tr>
<tr><td>'logscale'</td><td># logscale, an array of axes that will get log scale</td><td></td></tr>
<tr><td>'show.colorbar'</td><td>self-evident, 0 or 1</td><td><code>show.colorbar</code> => 1</td></tr>
<tr><td>'vmax'</td><td>When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover</td><td></td></tr>
<tr><td>'vmin'</td><td># When using scalar data and no explicit *norm*, *vmin* and *vmax* define the data range that the colormap cover</td><td></td></tr>
<tr><td>'xbins'</td><td># default 15</td><td></td></tr>
<tr><td>'xmin', 'xmax',</td><td></td><td></td></tr>
<tr><td>'ymin', 'ymax',</td><td></td><td></td></tr>
<tr><td>'ybins'</td><td>default 15</td><td></td></tr>
</tbody>
</table>

=head3 multiple plots

 plt({
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
             'plot.type' => 'hist2d',
             title       => 'Simple hist2d',
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type' => 'hist2d',
             title       => 'cmap = terrain',
             cmap        => 'terrain'
         },
         {
             cmap => 'ocean',
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type' => 'hist2d',
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
             'plot.type' => 'hist2d',
             title       => 'density = True',
             cmap        => 'terrain',
             density     => 'True'
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type' => 'hist2d',
             title       => 'key.order flips axes',
             cmap        => 'terrain',
             'key.order' => [ 'Y', 'X' ]
         },
         {
             cb_logscale => 1,
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type' => 'hist2d',
             title       => 'cb_logscale = 1',
         },
         {
             cb_logscale => 1,
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type' => 'hist2d',
             title       => 'cb_logscale = 1 with vmax set',
             vmax        => 2.1,
             vmin        => 1
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type'     => 'hist2d',
             'show.colorbar' => 0,
             title           => 'no colorbar',
         },
         {
             data => {
                 X => $x,    # x-axis
                 Y => $y,    # y-axis
             },
             'plot.type'     => 'hist2d',
             title           => 'xbins = 9',
             xbins           => 9
         },
     ],
     'output.file' => 'output.images/hist2d.png',
 });

makes the following image:


=for html
<p>
<img width="1510" height="491" alt="hist2d" src="https://github.com/user-attachments/assets/3d6becd3-44f3-4511-8b0f-eae39bc325fa" />
<p>


=head2 imshow

Plot 2D array of numbers as an image

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>------- </td></tr>
<tr><td><code>cblabel</code></td><td>colorbar label</td><td><code>cblabel => 'sin(x) * cos(x)',</code></td></tr>
<tr><td><code>cbdrawedges</code></td><td>draw edges for colorbar</td><td></td></tr>
<tr><td><code>cblocation</code></td><td>'left', 'right', 'top', 'bottom'</td><td><code>cblocation => 'left',</code></td></tr>
<tr><td><code>cborientation</code></td><td>None, or 'vertical', 'horizontal'</td><td></td></tr>
<tr><td><code>cmap</code></td><td># The Colormap instance or registered colormap name used to map scalar data to colors.</td><td></td></tr>
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
 plt({
     data              => \@imshow_data,
     execute           => 0,
    fh => $fh,
     'output.file' => 'output.images/imshow.single.png',
     'plot.type'       => 'imshow',
     set_xlim          => '0, ' . scalar @imshow_data,
     set_ylim          => '0, ' . scalar @imshow_data,
 });

which makes the following image:


=for html
<p>
<img width="599" height="491" alt="imshow single" src="https://github.com/user-attachments/assets/3fa4ffe6-4817-4133-9c91-b68099400377" />
<p>


=head3 multiple plots

 plt({
     plots  => [
         {
             data => \@imshow_data,
             'plot.type'       => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'basic',
         },
         {
             cblabel           => 'sin(x) * cos(x)',
             data => \@imshow_data,
             'plot.type'       => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'cblabel',
         },
         {
             cblabel           => 'sin(x) * cos(x)',
             cblocation        => 'left',
             data              => \@imshow_data,
             'plot.type'       => 'imshow',
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
                 'plot.type' => 'plot',
                 'set.options' => {
                     'sin(x)'    =>  'color = "red", linestyle = "dashed"',
                     'cos(x)'    =>  'color = "blue", linestyle = "dashed"',
                 }
             }
             ],
             'plot.type'       => 'imshow',
             set_xlim          => '0, ' . scalar @imshow_data,
             set_ylim          => '0, ' . scalar @imshow_data,
             title             => 'auxiliary plots',
         },
     ],
     execute         => 0,
   fh              => $fh,
     'output.file'   => 'output.images/imshow.multiple.png',
     ncols           => 2,
     nrows           => 2,
     set_figheight   => 6*3,# 4.8
     set_figwidth    => 6*4 # 6.4
 });

which makes the following image:


=for html
<p>
<img width="2416" height="1811" alt="imshow multiple" src="https://github.com/user-attachments/assets/091acccb-151c-47ca-82cc-99c19d2bff91" />
<p>


=head2 pie

=head3 options

=head3 single, simple plot

 plt({
     'output.file' => 'output.images/single.pie.png',
     data              => {                                 # simple hash
         Fri => 76,
         Mon => 73,
         Sat => 26,
         Sun => 11,
         Thu => 94,
         Tue => 93,
         Wed => 77
     },
     'plot.type'  => 'pie',
     title        => 'Single Simple Pie',
     fh           => $fh,
     execute      => 0,
 });

which makes the image:


=for html
<p>
<img width="469" height="491" alt="single pie" src="https://github.com/user-attachments/assets/a0bc3212-d013-463a-9be6-f96829ac7dba" />
<p>


=head3 multiple plots

 plt({
     'output.file' => 'output.images/pie.png',
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
             'plot.type' => 'pie',
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
             'plot.type' => 'pie',
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
             'plot.type'   => 'pie',
             autopct       => '%1.1f%%',
             pctdistance   => 1.25,
             labeldistance => 0.6,
         }
     ],
     fh => $fh,
     execute      => 0,
    set_figwidth  => 12,
     ncols        => 3,
 });


=for html
<p>
<img width="1210" height="444" alt="pie" src="https://github.com/user-attachments/assets/4c44d300-fd84-49bc-9a32-b73af54286cf" />
<p>


=head2 plot

plot either a hash of arrays or an array of arrays

=head3 single, simple

data can be given as a hash, where the hash key is the label:

 plt({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/plot.single.png',
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
     'plot.type' => 'plot',
     title       => 'simple plot',
     set_xticks  =>
     "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
      . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
     'set.options' => {    # set options overrides global settings
         'sin(x)' => 'color="blue", linewidth=2',
         'cos(x)' => 'color="red",  linewidth=2'
     }
 });

or as an array of arrays:

 plt({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/plot.single.arr.png',
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
     'plot.type' => 'plot',
     title       => 'simple plot',
     set_xticks  =>
     "[-2 * $pi, -3 * $pi / 2, -$pi, -$pi / 2, 0, $pi / 2, $pi, 3 * $pi / 2, 2 * $pi"
      . '], [r\'$-2\pi$\', r\'$-3\pi/2$\', r\'$-\pi$\', r\'$-\pi/2$\', r\'$0$\', r\'$\pi/2$\', r\'$\pi$\', r\'$3\pi/2$\', r\'$2\pi$\']',
     'set.options' => [    # set options overrides global settings; indices match data array
         'color="blue", linewidth=2, label = "sin(x)"', # labels aren't added automatically when using array here
         'color="red",  linewidth=2, label = "cos(x)"'
     ],
 });

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
 plt({
     fh => $fh,
     execute           => 0,
     'output.file' => 'output.images/plots.png',
     plots         => [
     { # sin
         data          => {
             'sin(θ)' => [
                 [@x],
                 [map {sin($_)} @x]
             ]
         },
         'plot.type'   => 'plot',
         'set.options' => {
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
         'plot.type'   => 'plot',
         'set.options' => {
             'cos(θ)' => 'color = "black"'
         },
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         xlabel        => 'θ',
         ylabel        => 'cos(θ)',
     },
     { # csc
         data          => $d{csc},
         'plot.type'   => 'plot',
         'set.options' => $set_opt{csc},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         'show.legend' => 0,
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
         'plot.type'   => 'plot',
         'set.options' => $set_opt{sec},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         'show.legend' => 0,
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
         'plot.type'   => 'plot',
         'set.options' => $set_opt{cot},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         'show.legend' => 0,
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
         'plot.type'   => 'plot',
         'set.options' => $set_opt{tan},
         set_xticks    => $xticks,
         set_xlim      => "-2*$pi, 2*$pi",
         set_ylim      => "$min,$max",
         'show.legend' => 0,
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
 });


=for html
<p>
<img width="811" height="491" alt="plots" src="https://github.com/user-attachments/assets/0bdd0744-c1bb-4c4a-9482-b3de3f2d4fc2" />
<p>


=head2 scatter

=head3 single, simple plot

 scatter({
     fh            => $fh,
     data          => {
         X => [@x],
         Y => [map {sin($_)} @x]
     },
     execute       => 0,
     'output.file' => 'output.images/single.scatter.png',
 });

makes the following image:


=for html
<p>
<img width="651" height="491" alt="single scatter" src="https://github.com/user-attachments/assets/c45d9922-23e0-4f85-8306-aa7fca400328" />
<p>


=head3 options

=head3 multiple plots

 plt({
     fh => $fh,
     'output.file' => 'output.images/scatterplots.png',
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
             'set.options' => 'marker = "v"'
             , # arguments to ax.scatter: there's only 1 set, so "set.options" is a scalar
             text        => [ '100, 100, "text1"', '100, 100, "text2"', ],
             'plot.type' => 'scatter',
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
             'plot.type'   => 'scatter',
             title         => 'Multiple Set Scatterplot',
             'set.options' =>
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
             'plot.type'   => 'scatter',
             title         => 'Multiple Set Scatter w/ colorbar',
             'set.options' => {    # arguments to ax.scatter, for each set in data
                 X => 'marker = "."',    # diamond
                 Y => 'marker = "d"'     # diamond
             },
             color_key => 'Z',
         }
     ]
 });

which makes the following figure:


=for html
<p>
<img width="1610" height="461" alt="scatterplots" src="https://github.com/user-attachments/assets/b8a90f9f-acb3-4cf2-a423-6ad18686ab8c" />
<p>


=head2 violin

plot a hash of array refs as violins

=head3 options

=for html
<table>
<tbody>
<tr><td>Option</td><td>Description</td><td>Example</td></tr>
<tr><td>--------</td><td>-------</td><td>-------</td></tr>
<tr><td><code>color</code></td><td># a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'</td><td></td></tr>
<tr><td><code>colors</code></td><td>match sets</td><td><code>colors       => { E => 'yellow', B => 'purple', A => 'green' }</code></td></tr>
<tr><td><code>key.order</code></td><td>determine key order display on x-axis</td><td></td></tr>
<tr><td><code>log</code></td><td># if set to > 1, the y-axis will be logarithmic</td><td></td></tr>
<tr><td><code>orientation</code></td><td>'vertical', 'horizontal'}, default: 'vertical'</td><td></td></tr>
</tbody>
</table>

=head3 single, simple plot

 plt({
     'output.file' => 'output.images/single.violinplot.png',
     data              => {                                     # simple hash
         A => [ 55, @{$z} ],
         E => [ @{$y} ],
         B => [ 122, @{$z} ],
     },
     'plot.type'  => 'violinplot',
     title        => 'Single Violin Plot: Specified Colors',
     colors       => { E => 'yellow', B => 'purple', A => 'green' },
     fh => $fh,
     execute      => 0,
 });

which makes:


=for html
<p>
<img width="651" height="491" alt="single violinplot" src="https://github.com/user-attachments/assets/989650fd-c947-45b0-91c8-c7f71c075cf3" />
<p>


=head3 multiple plots

 plt({
     fh                => $fh,
     execute           => 0,
     'output.file'     => 'output.images/violin.png',
     plots             => [
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type'  => 'violinplot',
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
             'plot.type' => 'violinplot',
             color       => 'red',
             title       => 'Set Same Color for All',
         },
         {
             data => {
                 E => @e,
                 B => @b
             },
             'plot.type' => 'violinplot',
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
             'plot.type' => 'violinplot',
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
             'plot.type' => 'violinplot',
             colors      => {
                 E => 'yellow',
                 B => 'black'
             },
             title => 'Whiskers off',
         },
     ],
     ncols => 3,
     nrows => 2,
 });


=for html
<p>
<img width="1211" height="491" alt="violin" src="https://github.com/user-attachments/assets/248df5e4-fd57-45d6-96da-956af0a7dbfb" />
<p>


=head2 wide

=head3 options

=head3 single, simple plot

=head3 multiple plots

=head1 Advanced

=head2 Notes in Files

all files that can have notes with them, give notes about how the file was written.  For example, SVG files have the following:

 <dc:title>made/written by /mnt/ceph/dcondon/ui/gromacs/tut/dup.2puy/1.plot.gromacs.pl called using "plot" in /mnt/ceph/dcondon/perl5/perlbrew/perls/perl-5.42.0/lib/site_perl/5.42.0/x86_64-linux/Matplotlib/Simple.pm</dc:title>`

=head2 Speed

To improve speed, all data can be written into a single temp python3 file thus:

 use File::Temp;
 my $fh = File::Temp->new( DIR => '/tmp', SUFFIX => '.py', UNLINK => 0 );

all files will be written to C<< $fh-E<gt>filename >>; be sure to put C<< execute =E<gt> 0 >> unless you want the file to be run, which is the last step.

 plt({
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
     'output.file' => 'output.images/single.wide.png',
     'plot.type'       => 'wide',
     color             => {
         Clinical => 'blue',
         HGI      => 'green'
     },
     title        => 'Visualization of similar lines plotted together',
     fh => $fh,
     execute      => 0,
 });
 # the last plot should have C<< execute =E<gt> 1 >>
 plt({
     data => [
         [
             [@xw],    # x
             [@y]      # y
         ],
         [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ],
         [ [@xw], [ map { $_ + rand_between( -0.5, 0.5 ) } @y ] ]
     ],
     'output.file' => 'output.images/single.array.png',
     'plot.type'       => 'wide',
     color             => 'red',
     title             => 'Visualization of similar lines plotted together',
     fh                => $fh,
     execute           => 1,
 });
