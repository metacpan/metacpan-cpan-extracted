# ABSTRACT: Access Matplotlib from Perl; providing consistent user interface between different plot types
#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use autodie ':all';
use feature 'say';
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';

package Matplotlib::Simple;
our $VERSION = 0.02;

=head1 NAME
Matplotlib::Simple
=head1 AUTHOR
David E. Condon
=head1 LICENSE
FreeBSD
=head1 SYNOPSIS
Simplest possible use case:

	use Matplotlib::Simple 'plot';
	plot({
		'output.filename' => '/tmp/gospel.word.counts.png',
		'plot.type'       => 'bar',
		data              => {
			Matthew => 18345,
			Mark    => 11304,
			Luke    => 19482,
			John    => 15635,
		}
	});
	
Having a `plots` argument as an array lets the module know to create subplots:

	use Matplotlib::Simple 'plot';
	plot({
		'output.filename'	=> 'svg/pies.png',
		plots             => [
			{
				data	=> {
				 Russian => 106_000_000,  # Primarily European Russia
				 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
				},
				'plot.type'	=> 'pie',
				title       => 'Top Languages in Europe',
				suptitle    => 'Pie in subplots',
			},
			{
				data	=> {
				 Russian => 106_000_000,  # Primarily European Russia
				 German => 95_000_000,    # Germany, Austria, Switzerland, etc.
				},
				'plot.type'	=> 'pie',
				title       => 'Top Languages in Europe',
			},
		],
		ncols    => 2,
	});

See https://github.com/hhg7/MatPlotLib-Simple for more detailed use cases (with images)

=cut
use List::Util qw(max sum min);
use Term::ANSIColor;
use Cwd 'getcwd';
use File::Temp 'tempfile';
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Devel::Confess 'color';
use FindBin '$RealScript';
use Exporter 'import';
use Capture::Tiny 'capture';
our @EXPORT = ('plot');

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
    }
    elsif ( $return eq 'stderr' ) {
        chomp $stderr;
        return $stderr;
    }
    elsif ( $return eq 'stdout' ) {
        chomp $stdout;
        return $stdout;
    }
    elsif ( $return eq 'all' ) {
        chomp $stdout;
        chomp $stderr;
        return {
            exit   => $exit,
            stdout => $stdout,
            stderr => $stderr
        };
    }
    else {
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
    'format_xdata', 'format_ydata',
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
    'text',        'titleOffsetTrans', 'transAxes', 'transData', 'transLimits',
    'transScale', 'update_datalim', 'use_sticky_edges', 'viewLim', 'violin',
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
    'bar',         'bar_label', 'barbs', 'barh', 'bone',    'box', 'boxplot',
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
    'getp',    'ginput', 'gray', 'grid', 'hexbin', 'hist', 'hist2d', 'hlines',
    'hot',     'hsv',    'importlib', 'imread', 'imsave', 'imshow', 'inferno',
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
    'text'
    , # text(x: 'float', y: 'float', s: 'str', fontdict: 'dict[str, Any] | None' = None, **kwargs) -> 'Text'
    'thetagrids',   'threading', 'tick_params', 'ticklabel_format',
    'tight_layout', 'time', 'title', 'tricontour', 'tricontourf', 'tripcolor',
    'triplot', 'twinx',     'twiny', 'uninstall_repl_displayhook', 'violinplot',
    'viridis', 'vlines',    'waitforbuttonpress', 'winter', 'xcorr', 'xkcd',
    'xlabel',
    #	'xlim',
    'xscale',
    #'xticks',
    'ylabel', 'ylim', 'yscale',
    #	'yticks'
);

my @arg = ('cmap', 'data', 'execute', 'input.file','ncols', 'plot.type',
 'plots', 'plot', 'output.filename','nrows');
my @cb_arg = (
'cbdrawedges', # for colarbar: Whether to draw lines at color boundaries
'cblabel',		# The label on the colorbar's long axis
'cblocation', # of the colorbar None or {'left', 'right', 'top', 'bottom'}
'cborientation', # None or {'vertical', 'horizontal'}
'cb_logscale');
my $cb_regex = join ('|', @cb_arg);
sub plot_args {    # this is a helper function to other matplotlib subroutines
    my ($args) = @_;
    my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
      ; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
    unless ( ref $args eq 'HASH' ) {
        die
"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
    }
    my @reqd_args = (
        'ax',      # ax1, ax2, etc. when there are multiple plots
        'fh',      # e.g. $py, $fh, which will be passed by the subroutine
        'args',    # args to original function
    );
    my @undef_args = grep { !defined $args->{$_} } @reqd_args;
    if ( scalar @undef_args > 0 ) {
        p @undef_args;
        die 'the above args are necessary, but were not defined.';
    }
    my @defined_args =
      ( @reqd_args, @ax_methods, @fig_methods, @plt_methods, @arg, @cb_arg );
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
        grep { defined $args->{args}{$_} } (
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
        foreach my $method ( grep { defined $args->{args}{$_} } @{ $args[$i] } )
        {
            my $ref = ref $args->{args}{$method};
            if ( ( $ref ne 'ARRAY' ) && ( $ref ne '' ) ) {
                die
"$current_sub only accepts scalar or array types, but $ref was entered.";
            }
            if ( $ref eq '' ) {
                say { $args->{fh} }
                  "$obj[$i].$method($args->{args}{$method}) #" . __LINE__;
                next;
            }

            # can only be ARRAY
            foreach my $j ( @{ $args->{args}{$method} } )
            {    # say $fh "plt.$method($plt)";
                say { $args->{fh} } "$obj[$i].$method($j) # " . __LINE__;
            }
        }
    }
    return unless defined $args->{ax};
    my $legend   = $args->{args}{legend} // '';
    my $pie_plot = 0;
    if (   ( defined $args->{args}{'plot.type'} )
        && ( $args->{args}{'plot.type'} eq 'pie' ) )
    {
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
    }
    elsif ( defined $ref_counts{'ARRAY'} ) {
        $plot_type = 'grouped';
    }
    elsif ( defined $ref_counts{'HASH'} ) {
        $plot_type =
          'grouped';    # now make the hash of hash into a ARRAY structure
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
    }
    else {
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
    }
    else {
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
        }
        elsif ( $ref eq 'ARRAY' ) {
            $options .= ", $c = [\"" . join( '","', @{ $plot->{$c} } ) . '"]';
        }
    }    # args that can be either arrays or strings below; NUMERIC:
    foreach my $c ( grep { defined $plot->{$_} } ('linewidth') ) {
        my $ref = ref $plot->{$c};
        if ( $ref eq '' ) {    # single color
            $options .= ", $c = $plot->{$c}";
        }
        elsif ( $ref eq 'ARRAY' ) {
            $options .= ", $c = [" . join( ',', @{ $plot->{$c} } ) . ']';
        }
        else {
            p $args;
            die "$ref for $c isn't acceptable";
        }
    }
    foreach my $err ( grep { defined $plot->{$_} } ( 'xerr', 'yerr' ) ) {
        my $ref = ref $plot->{$err};
        if ( $ref eq '' ) {
            $options .= ", $err = $plot->{$err}";
        }
        elsif ( $ref eq 'HASH' ) {    # I assume that it's all defined
            my ( @low, @high );
            foreach my $i (@key_order) {
                if ( scalar @{ $plot->{$err}{$i} } != 2 ) {
                    p $plot->{$err}{$i};
                    die
"$err/$i should have exactly 2 items: low and high error bars";
                }
                push @low,  $plot->{$err}{$i}[0];
                push @high, $plot->{$err}{$i}[1];
            }
            $options .=
                ", $err = [["
              . join( ',', @low ) . '],['
              . join( ',', @high ) . ']]';
        }
        else {
            p $args;
            die "$ref for $err isn't acceptable";
        }
    }
    if ( $plot_type eq 'simple' ) {    # a simple hash -> simple bar plot
        say { $args->{fh} } 'labels = ["' . join( '","', @key_order ) . '"]';
        say { $args->{fh} } 'vals = ['
          . join( ',', @{ $plot->{data} }{@key_order} ) . ']';
        say { $args->{fh} } "ax$ax.$plot->{'plot.type'}(labels, vals $options)";
    }
    elsif ( $plot_type eq 'grouped' ) {    # grouped bar plot; hash of array
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
        while ( my ( $i, $arr ) = each @val ) {
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
        }
        my $xticks = '["' . join( '","', @key_order ) . '"]';
        my $ticks  = 'yticks';
        $ticks = 'xticks' if $plot->{'plot.type'} eq 'bar';
        $_ /= scalar @val for @mean_pos;
        say { $args->{fh} } "ax$ax.set_$ticks(["
          . join( ',', @mean_pos )
          . "], $xticks)";
    }
    else {
        die
"\$plot_type = $plot_type & stacked = $plot->{stacked}and isn't defined.";
    }
}

sub boxplot_helper {
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
        @ax_methods, @plt_methods, @fig_methods, @arg,
        'alpha',    # default 0.5; same for all sets
        'ax',       # used for multiple plots
        'bins'
        , # nt or sequence or str, default: :rc:`hist.bins`If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open
        'color'
        , # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
        'colors', 'key.order',
        'log',    # if set to > 1, the y-axis will be logarithmic
        'notch'
        , # Whether to draw a notched boxplot (`True`), or a rectangular boxplot (`False`)
        'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
        'showcaps'
        ,    # bool: Show the caps on the ends of whiskers; default "True"
        'showfliers',
        'showmeans',
        'whiskers',    # 0 or 1
        'plots', 'ncols', 'nrows', 'output.filename', 'input.file',
        'execute'      # these will be ignored
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
"The above arguments aren't defined for $plot->{'plot.type'} using $current_sub";
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
    }
    else {
        @key_order = sort keys %{ $plot->{data} };
    }
    my $ax = $args->{ax} // '';

    #	$plot->{medians} = $plot->{medians} // 1; # by default, show median values
    $plot->{edgecolor}  = $plot->{edgecolor}  // 'black';
    $plot->{showcaps}   = $plot->{showcaps}   // 'True';
    $plot->{showfliers} = $plot->{showfliers} // 'True';
    $plot->{showmeans}  = $plot->{showmeans}  // 'True';
    $plot->{notch}      = $plot->{notch}      // 'False';
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
    if ( defined $plot->{colors} )
    {    # every hash key should have its own color defined

# the below code helps to provide better error messages in case I make an error in calling the sub
        my @wrong_keys =
          grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
        if ( scalar @wrong_keys > 0 ) {
            p @wrong_keys;
            die 'the above data keys have no defined color';
        }

# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
        say { $args->{fh} } 'colors = ["'
          . join( '","', @{ $plot->{colors} }{@key_order} ) . '"]';

       # the above color list will have the same order, via the above hash slice
        say { $args->{fh} } 'for patch, color in zip(bp["boxes"], colors):';
        say { $args->{fh} } "\tpatch.set_facecolor(color)";
        say { $args->{fh} } "\tpatch.set_edgecolor('black')";
    }
    else {
        say { $args->{fh} } 'for pc in bp["boxes"]:';
        if ( defined $plot->{color} ) {
            say { $args->{fh} } "\tpc.set_facecolor('$plot->{color}')";
        }
        say { $args->{fh} } "\tpc.set_edgecolor('black')";

        #		say {$args->{fh}} "\tpc.set_alpha(1)";
    }
    foreach my $key (@key_order) {
        push @xticks, "$key ("
          . format_commas( scalar @{ $plot->{data}{$key} }, '%.0u' ) . ')';
    }
    if ( $plot->{orientation} eq 'vertical' ) {
        say { $args->{fh} } "ax$ax.set_xticks(["
          . join( ',',   1 .. scalar @key_order ) . '], ["'
          . join( '","', @xticks ) . '"])';
    }
    else {
        say { $args->{fh} } "ax$ax.set_yticks(["
          . join( ',',   1 .. scalar @key_order ) . '], ["'
          . join( '","', @xticks ) . '"])';
    }
}

sub hexbin_helper {
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
    }
    else {
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
          . ' points.';
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
    say { $args->{fh} } "im = ax$ax.hexbin(x, y $options)";
    if ( defined $plot->{cblabel} ) {
        say { $args->{fh} } 'plt.colorbar(im' . ", label = '$plot->{cblabel}')";
    }
    else {
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
        'plots', 'ncols', 'nrows', 'output.filename', 'input.file',
        'execute'         # these will be ignored
    );
    @opt = grep {$_ !~ m/^(?:$cb_regex)$/} @opt; # args that shouldn't apply
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
        if ( $ref eq '' ) {                     # single color
            if ( $plot->{$arg} =~ m/^[A-Za-z]+$/ ) {    # "Red" needs quotes
                $options .= ", $arg = '$plot->{$arg}'";
            }
            else {                                      # I'm assuming numeric
                $options .= ", $arg = $plot->{$arg}";
            }
        }
        elsif ( $ref eq 'ARRAY' ) {
            $options .= ", $arg = [" . join( ',', @{ $plot->{$arg} } ) . '"]';
        }
        else {
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
            }
            else {    # I'm assuming numeric; "10" doesn't need quotes
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
    }
    else {
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
          . ' points.';
        die 'The length of both keys must be equal.';
    }
    $plot->{xlabel} = $plot->{xlabel} // $keys[0];
    $plot->{ylabel} = $plot->{ylabel} // $keys[1];
    $plot->{cmap}   = $plot->{cmap}   // 'gist_rainbow';
    my $options =
      ", cmap = '$plot->{cmap}'";    # these args go to the plt.hist call
    if ( $plot->{cb_logscale} > 0 ) {
        say { $args->{fh} } 'from matplotlib.colors import LogNorm';
        $options .= ', norm = LogNorm()';
    }
    foreach my $opt ( grep { defined $plot->{$_} }
        ( 'cmin', 'cmax', 'density', 'vmin', 'vmax' ) )
    {
        $options .= ", $opt = $plot->{$opt}";
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
    say { $args->{fh} }
"im$ax = ax$ax.hist2d(x, y, ($plot->{xbins}, $plot->{ybins}) $options $range)";
    return 0 if $plot->{'show.colorbar'} == 0;
    if ( defined $plot->{cblabel} ) {
        say { $args->{fh} } "plt.colorbar(im$ax"
          . "[3], label = '$plot->{cblabel}')";
    }
    else {
        say { $args->{fh} } "plt.colorbar(im$ax" . "[3], label = 'Density')";
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
        'vmax', # float
        'vmin', # flat
    );
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
        p @undef_opt;
        p $args;
        die
"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
    }
    $plot->{'show.legend'} = $plot->{'show.legend'} // 1;
    my @key_order;
    if ( defined $plot->{'key.order'} ) {
        @key_order = @{ $plot->{'key.order'} };
    }
    else {
        @key_order = sort keys %{ $plot->{data} };
    }
    foreach my $set (@key_order) {
        my $set_ref = ref $plot->{data}{$set};
        if ( $set_ref ne 'ARRAY' ) {
            p $plot->{data}{$set};
            die
"$set must have two arrays, x and y coordinates, but instead has a $set_ref";
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
            die
"$set has $nx x data points, but y has $ny y data points, and they must be equal";
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
        say { $args->{fh} } "ax$args->{ax}.plot(x, y $label $options) # "
          . __LINE__;
    }
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
        die
"The above arguments aren't defined for $plot->{'plot.type'} in $current_sub";
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
        die
"different kinds of data were entered to plot $ax; it should be simple hash or hash of arrays.";
    }
    if ( defined $ref_counts{ARRAY} ) {
        $plot_type = 'single';
    }
    elsif ( defined $ref_counts{HASH} ) {
        $plot_type = 'multiple';
    }
    $plot->{cmap} = $plot->{cmap} // 'gist_rainbow';
    my $options = '';
    if ( $plot_type eq 'single' ) {    # only a single set of data
        my ( $color_key, @keys );
        if ( defined $plot->{'keys'} ) {
            @keys = @{ $plot->{'keys'} };
        }
        else {
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
            while ( my ( $i, $key ) = each @keys ) {
                next unless $key eq $plot->{color_key};
                splice @keys, $i, 1;    # remove the color key from @keys
            }
        }
        elsif ( scalar @keys == 3 ) {
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
            say { $args->{fh} } "plt.colorbar(im, label = '$color_key')";
        }
        else {
            say { $args->{fh} } "ax$ax.scatter(x, y, $options)";
        }
        $plot->{xlabel} = $plot->{xlabel} // $keys[0];
        $plot->{ylabel} = $plot->{ylabel} // $keys[1];
    }
    elsif ( $plot_type eq 'multiple' ) {    # multiple sets
        my @undefined_opts;
        foreach my $set ( sort keys %{ $plot->{'set.options'} } ) {
            next if grep { $set eq $_ } keys %{ $plot->{data} };
            push @undefined_opts, $set;
        }
        if ( scalar @undefined_opts > 0 ) {
            p $plot->{data};
            p $plot;
            say
'The data and options are above, but the following sets have options without data:';
            p @undefined_opts;
            die 'no data was defined for the above options';
        }
        my $color_key;
        foreach my $set ( sort keys %{ $plot->{data} } ) {
            my @keys;
            if ( defined $plot->{'keys'} ) {
                @keys = @{ $plot->{'keys'} };
            }
            else
            { # automatically take the key from the first; further sets should have the same labels
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
            }
            else {
                say { $args->{fh} }
                  "ax$ax.scatter(x, y, label = '$set' $options)";
            }
            $plot->{xlabel} = $plot->{xlabel} // $keys[0];
            $plot->{ylabel} = $plot->{ylabel} // $keys[1];
        }
        say { $args->{fh} } "plt.colorbar(im, label = '$color_key')"
          if defined $color_key;
    }
}

sub violin_helper {
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
        @ax_methods, @plt_methods, @fig_methods, @arg,
        'alpha',    # default 0.5; same for all sets
        'ax',       # used for multiple plots
        'bins'
        , # nt or sequence or str, default: :rc:`hist.bins`If *bins* is an integer, it defines the number of equal-width bins in the range. If *bins* is a sequence, it defines the bin edges, including the left edge of the first bin and the right edge of the last bin; in this case, bins may be unequally spaced.  All but the last  (righthand-most) bin is half-open
        'color'
        , # a hash, where keys are the keys in data, and values are colors, e.g. X => 'blue'
        'colors',
        'key.order',
        'log',            # if set to > 1, the y-axis will be logarithmic
        'orientation',    # {'vertical', 'horizontal'}, default: 'vertical'
        'whiskers',
        'plots', 'ncols', 'nrows', 'output.filename', 'input.file',
        'execute'         # these will be ignored
    );
    my $plot      = $args->{plot};
    my @undef_opt = grep {
        my $key = $_;
        not grep { $_ eq $key } @opt
    } keys %{$plot};
    if ( scalar @undef_opt > 0 ) {
        p @undef_opt;
        die
"The above arguments aren't defined for $plot->{'plot.type'} using $current_sub";
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
    }
    else {
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
    if ( defined $plot->{colors} )
    {    # every hash key should have its own color defined

# the below code helps to provide better error messages in case I make an error in calling the sub
        my @wrong_keys =
          grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
        if ( scalar @wrong_keys > 0 ) {
            p @wrong_keys;
            die 'the above data keys have no defined color';
        }

# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
        say { $args->{fh} } 'colors = ["'
          . join( '","', @{ $plot->{colors} }{@key_order} ) . '"]';

       # the above color list will have the same order, via the above hash slice
        say { $args->{fh} } 'for i, pc in enumerate(vp["bodies"], 1):';
        say { $args->{fh} } "\tpc.set_facecolor(colors[i-1])";
        say { $args->{fh} } "\tpc.set_edgecolor('black')";
    }
    else {
        say { $args->{fh} } 'for pc in vp["bodies"]:';
        if ( defined $plot->{color} ) {
            say { $args->{fh} } "\tpc.set_facecolor('$plot->{color}')";
        }
        say { $args->{fh} } "\tpc.set_edgecolor('black')";

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
'	local_quartile1, local_medians, local_quartile3 = np.percentile(d[subset], [25, 50, 75])';
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
        }
        else {
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
    }
    else {
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
        die
"the above args are necessary for $current_sub, but were not defined.";
    }
    my @opt = (
        @ax_methods, @plt_methods, @fig_methods, @arg,
        'color', # a hash, with each key assigned to a color "blue" or something
    );
    my $plot      = $args->{plot};
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
            say { $args->{fh} }
              "ax$ax.plot(base_y, mean_ys, '$color', label = '$group')";
            say { $args->{fh} }
"ax$ax.fill_between(base_y, ys_lower, ys_upper, color='$color', alpha=0.3)";
        }
    }
    elsif ( $ref_type eq 'ARRAY' ) {
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
    }
    else {
        die "$current_sub cannot take ref type \"$ref_type\" for \"data\"";
    }
}

sub plot {
    my ($args) = @_;
    my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
      ; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
    unless ( ref $args eq 'HASH' ) {
        die
"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
    }
    my @reqd_args = (
        'output.filename',    # e.g. "my_image.svg"
    );
    my $single_example = 'plot({
	\'output.filename\' => \'/tmp/gospel.word.counts.svg\',
	\'plot.type\'       => \'bar\',
	data              => {
		\'Matthew\' => 18345,
		\'Mark\'    => 11304,
		\'Luke\'    => 19482,
		\'John\'    => 15635,
	}
});';
    my $multi_example = 'plot({
	\'output.filename\'	=> \'svg/pie.svg\',
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
        @arg,       'key.order', 'set.options', 'color',
        'colors',   'show.legend'
    );
    my @bad_args = grep {
        my $key = $_;
        not grep { $_ eq $key } @defined_args
    } keys %{$args};
    if ( scalar @bad_args > 0 ) {
        p @bad_args, array_max => scalar @bad_args;
        say 'the above arguments are not recognized.';
        p @defined_args, array_max => scalar @defined_args;
        die "The above args are accepted by \"$current_sub\"";
    }
    my $single_plot = 0;    # false
    if ( ( defined $args->{'plot.type'} ) && ( defined $args->{data} ) ) {
        $single_plot = 1;    # true
    }
    if ( ( $single_plot == 1 ) && ( not defined $args->{'plot.type'} ) ) {
        p $args;
        say $single_example;
        die "\"plot.type\" was not defined for a single plot in $current_sub";
    }
    if ( ( $single_plot == 0 ) && ( not defined $args->{plots} ) ) {
        say $multi_example;
        die
"$current_sub: single plots need \"data\" and \"plot.type\", see example above";
    }
    if ( ( $single_plot == 0 ) && ( ref $args->{plots} ne 'ARRAY' ) ) {
        p $args;
        die "$current_sub \"plots\" must have an array entered into it";
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
    while ( my ( $i, $ax ) = each @ax ) {
        my $a1i = int $i / $args->{ncols};    # 1st index
        my $a2i = $i % $args->{ncols};        # 2nd index
        $y[$a1i][$a2i] = $ax;
    }
    foreach my $y (@y) {
        push @py, '(' . join( ',', @{$y} ) . ')';
    }
    my $unlink = 0;
    if ( defined $args->{'input.file'} ) {
        $temp_py = $args->{'input.file'};
        open $fh, '>>', $args->{'input.file'};
    }
    else {
        ( $fh, $temp_py ) =
          tempfile( DIR => '/tmp', SUFFIX => '.py', UNLINK => $unlink );
    }
    say "temp file is $temp_py" if $unlink == 0;
    say $fh 'import matplotlib.pyplot as plt';
    if ( $single_plot == 0 ) {
        $args->{sharex} = $args->{sharex} // 'False';
        say $fh 'fig, ('
          . join( ',', @py )
          . ") = plt.subplots($args->{nrows}, $args->{ncols}, sharex = $args->{sharex}, layout = 'constrained') #"
          . __LINE__;
    }
    elsif ( $single_plot == 1 ) {
        say $fh 'fig, ax0 = plt.subplots(1,1, layout = "constrained")';
    }
    else {
        die "\$single_plot = $single_plot breaks pigeonholes";
    }
    if ( defined $args->{plots} ) {
        my @undef_plot_types;
        while ( my ( $i, $plot ) = each @{ $args->{plots} } ) {
            next if defined $plot->{'plot.type'};
            push @undef_plot_types, $i;
        }
        if ( scalar @undef_plot_types > 0 ) {
            p $args;
            p @undef_plot_types;
            die 'The above subplot indices are missing "plot.type"';
        }
    }
    my $find_global_min_max =
      scalar grep { $_->{'plot.type'} eq 'hist2d' } @{ $args->{plots} };
    if ( $find_global_min_max > 0 ) {
        say $fh 'global_max = float("-inf")';
        say $fh 'global_min = float("inf")';
    }
    if ( $single_plot == 1 ) {
        if ( not defined $args->{'plot.type'} ) {
            die;
        }
        if ( $args->{'plot.type'} =~ m/^barh?$/ ) {  # barplot: "bar" and "barh"
            barplot_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'boxplot' ) {
            boxplot_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'hexbin' ) {
            hexbin_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'hist' ) {    # histogram
            hist_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'hist2d' ) {
            hist2d_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'imshow' ) {
            imshow_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'pie' ) {
            pie_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'plot' ) {
            plot_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'scatter' ) {    # scatterplot
            scatter_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'violinplot' ) {
            violin_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        elsif ( $args->{'plot.type'} eq 'wide' ) {
            wide_helper(
                {
                    fh   => $fh,
                    ax   => 0,
                    plot => $args
                }
            );
        }
        else {
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
        plot_args(
            {
                fh   => $fh,
                args => $args,
                ax   => 'ax0'
            }
        );
    }
    while ( my ( $ax, $plot ) = each @{ $args->{plots} } )
    {    # for each plot $ax (hash is $plot)
        my @reqd_keys = (
            'data',         # data type, of which several are available
            'plot.type',    # "bar", "barh", "hist", etc.
        );
        my @undef_keys = grep { !defined $plot->{$_} } @reqd_keys;
        if ( scalar @undef_keys > 0 ) {
            p @undef_keys;
            die
"the above args are necessary, but were not defined for plot $ax.";
        }
        if ( $plot->{'plot.type'} =~ m/^barh?$/ ) {  # barplot: "bar" and "barh"
            barplot_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'boxplot' ) {
            boxplot_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'hexbin' ) {
            hexbin_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'hist' ) {    # histogram
            hist_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'hist2d' ) {
            hist2d_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'imshow' ) {
            imshow_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'pie' ) {
            pie_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'plot' ) {
            plot_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'scatter' ) {    # scatterplot
            scatter_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'violinplot' ) {
            violin_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        elsif ( $plot->{'plot.type'} eq 'wide' ) {
            wide_helper(
                {
                    fh   => $fh,
                    ax   => $ax,
                    plot => $plot
                }
            );
        }
        else {
            die
"\"$plot->{'plot.type'}\" doesn't fit pigeonholes with \$single_plot = $single_plot";
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
        plot_args(
            {
                fh   => $fh,
                args => $plot,
                ax   => "ax$ax"
            }
        );
    }
    foreach my $ax (@ax) {
        say $fh "if $ax.has_data() == False:";    # remove empty plots
        say $fh "\t$ax.remove()";                 # remove empty plots
    }
    my %methods = map { $_ => 1 } @plt_methods;
    foreach my $plt_method ( grep { defined $methods{$_} } keys %{$args} ) {
        my $ref = ref $args->{$plt_method};
        if ( $ref eq '' ) {

            #			if ($args->{$plt_method} =~ m/^([^\"\',]+)$/) {
            #				$args->{$plt_method} = "'$args->{$plt_method}'";
            #			}
            $args->{$plt_method} =~ s/^\'+//;
            $args->{$plt_method} =~ s/\'+$//;
            say $fh "plt.$plt_method('$args->{$plt_method}')#" . __LINE__;
        }
        elsif ( $ref eq 'ARRAY' ) {
            foreach my $j ( @{ $args->{$plt_method} } )
            {    # say $fh "plt.$method($plt)";
                say $fh "plt.$plt_method($j)#" . __LINE__;
            }
        }
        else {
            p $args;
            die "$plt_method = \"$ref\" only accepts scalar or array types";
        }
    }
    %methods = map { $_ => 1 } @fig_methods;
    foreach my $fig_method ( grep { defined $methods{$_} } keys %{$args} ) {
        my $ref = ref $args->{$fig_method};
        if ( $ref eq '' ) {
            say $fh "fig.$fig_method($args->{$fig_method})#" . __LINE__;
        }
        elsif ( $ref eq 'ARRAY' ) {
            foreach my $j ( @{ $args->{$fig_method} } )
            {    # say $fh "plt.$method($plt)";
                say $fh "fig.$fig_method($j)";
            }
        }
        else {
            p $args;
            die "$fig_method = \"$ref\" only accepts scalar or array types";
        }
    }
    say $fh
"plt.savefig('$args->{'output.filename'}', bbox_inches = 'tight', metadata={'Creator': 'made/written by "
      . getcwd()
      . "/$RealScript called using \"$current_sub\" in "
      . __FILE__ . "'})";
    $args->{execute} = $args->{execute} // 1;
    if ( $args->{execute} == 0 ) {
        say $fh 'plt.close()';
    }
    if ( $args->{execute} > 0 ) {
        my $r = execute( "python3 $temp_py", 'all' );
        say 'wrote '
          . colored( ['cyan on_bright_yellow'], "$args->{'output.filename'}" );
        p $r;
    }
    else {    # not running yet
        say 'will write '
          . colored( ['cyan on_bright_yellow'], "$args->{'output.filename'}" );
    }
}
1;
