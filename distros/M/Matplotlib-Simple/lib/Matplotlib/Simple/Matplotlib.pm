use strict;
use feature 'say';
use warnings FATAL => 'all';

package Matplotlib::Simple::Matplotlib;
# The matplotlib engine, Matplotlib::Simple's default: it writes plt's figure as a Python
# 3 script that draws it with matplotlib, and runs that script. Everything
# here was in Matplotlib::Simple itself until 0.33, when it was split out so
# that other engines could draw the same figures; Matplotlib::Simple checks the
# arguments, and calls render() below once they are good.
#
# The helpers keep checking their own keywords, against the same lists Matplotlib::Simple
# checks them with, which are shared below rather than copied.
require 5.010;
our $VERSION = 0.3343;
use Scalar::Util 'looks_like_number';
use List::Util qw(max sum min);
use File::Spec;
use File::Temp;
use DDP { output => 'STDOUT', array_max => 10, show_memsize => 1 };
use Capture::Tiny 'capture';
use JSON::MaybeXS;
use MIME::Base64;
use Encode ();
# Loaded first, even when this module is the one asked for, so that the names
# below have something to alias. Matplotlib::Simple requires this module at its end, and
# must find it already in %INC, or it compiles it a second time and dies on
# "Subroutine py_list redefined". require puts it there, but "perl -c" on this
# file does not, so it is put there here.
BEGIN {
	$INC{'Matplotlib/Simple/Matplotlib.pm'} //= __FILE__;
	require Matplotlib::Simple;
}
# The parts of Matplotlib::Simple the helpers use under their old names: the checks that
# do not depend on the engine, and the keyword lists. Aliases, not copies, so
# a list Matplotlib::Simple changes is the list checked here.
BEGIN {
	no strict 'refs';
	*{$_} = \&{"Matplotlib::Simple::$_"} foreach qw(bad_keyword_error bin_counts bool_option cb_limits
	 check_key_order check_numbers check_plot_type check_scatter_lengths creator_note
	 check_scatter_values check_twinx_args check_wide_runs decoded_data
	 decoded_text finite_values is_finite is_nan logscale_axes nonfinite_name
	 program_from_env py_str run_script script_handle table_cells);
	*{$_} = \@{"Matplotlib::Simple::$_"} foreach qw(arg ax_methods cb_arg fig_methods plt_methods);
	*{$_} = \%{"Matplotlib::Simple::$_"} foreach qw(opt opt_key_of_type);
}
our ( @arg, @ax_methods, @cb_arg, @fig_methods, @plt_methods, %opt, %opt_key_of_type );
# Every plot type and keyword Matplotlib::Simple accepts is drawn here, so check_engine
# has nothing to refuse; the other engines list what they draw instead.
our $draws_everything = 1;
sub py_list {
	# The contents of a Python sequence literal: every item rendered by py_str
	# and joined with commas, so the caller wraps it in the [] or () it needs.
	#
	# The sites that take this are the ones that write user data -- data keys,
	# tick labels, set members -- into a list. Written by hand as
	# '["' . join('","', @keys) . '"]' they broke on a key holding a double
	# quote (a SyntaxError) and, worse, silently on one holding a backslash:
	# a "$\alpha$" key reached matplotlib as "$<BEL>lpha$", because Python read
	# the "\a" of a double-quoted literal as an escape.
	return join( ',', map { py_str($_) } @_ );
}
sub py_num {
	# A value that passed looks_like_number, as a Python numeric literal.
	#
	# looks_like_number accepts "nan", "inf", "Infinity" and a Perl NaN, and
	# each was written into the script as Perl stringifies it: "y = [1,NaN,3]"
	# died as "NameError: name 'NaN' is not defined". It also accepts
	# "0 but true", which is not Python either. A
	# finite value written in Python's own float syntax goes through as given,
	# so that no digits are lost to Perl's 15-digit stringification.
	#
	# Except for the leading zeros of a whole number, which are dropped: Python 3
	# refuses "007" as "leading zeros in decimal integer literals are not
	# permitted", and a column read from a file can hold such values. A float
	# such as "00.5" or "007e3" is legal Python and is left alone.
	my ($n) = @_;
	my $nonfinite = nonfinite_name($n);
	return "float('$nonfinite')" if defined $nonfinite;
	if ( $n =~ m/^\s*([-+]?)0*(\d+)\s*$/ ) {
		return "$1$2";
	}
	return $n if $n =~ m/^\s*[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*$/;
	return 0 + $n;
}
sub py_nums {
	# py_num of each value, joined with commas, for the caller to bracket.
	return join( ',', map { py_num($_) } @_ );
}
sub norm_args {
	# The keyword arguments of a drawing call that set its color scale,
	# each led by ", ": "vmin" and "vmax", or with "log" a LogNorm holding
	# them, since matplotlib refuses vmin and vmax beside a norm.
	#
	# args: lo, hi   => the ends of the scale, either undef to take it from
	#                   "values", or from matplotlib if there are none
	#       values   => array ref, optional: the values being colored
	#       log      => Perl true for a log scale
	#       fh, sub  => the script, and the helper, for the import and errors
	# A log scale cannot start at 0 or below, so its default bottom is the
	# smallest value above 0, as LogNorm would choose for itself.
	my ($args) = @_;
	my ( $lo, $hi ) = @{$args}{qw(lo hi)};
	my @values = finite_values( @{ $args->{values} // [] } );
	if ( $args->{log} ) {
		$lo = $lo // min( grep { $_ > 0 } @values );
		if ( not defined $lo ) {
			die "\"cb_logscale\" needs a color value above 0 to start the scale at, or a \"vmin\" or \"cb_min\" above 0, and $args->{sub} has neither";
		}
		if ( $lo <= 0 ) {
			die "\"cb_logscale\" cannot start at $lo in $args->{sub}: a log scale needs a minimum above 0";
		}
	} else {
		$lo = $lo // min(@values);
	}
	$hi = $hi // max(@values);
	my @kw;
	push @kw, 'vmin = ' . py_num($lo) if defined $lo;
	push @kw, 'vmax = ' . py_num($hi) if defined $hi;
	if ( $args->{log} ) {
		say { $args->{fh} } 'from matplotlib.colors import LogNorm';
		return ', norm = LogNorm(' . join( ', ', @kw ) . ')';
	}
	return join( '', map { ", $_" } @kw );
}
sub write_data {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ( ref $args ne 'HASH' ) {
	  die "args must be given as a hash ref, e.g. \"$current_sub({ data => ... })\"";
	}
	my @reqd_args = (
	  'data', # args to original function (scalar, hashref, or arrayref)
	  'fh',   # file handle
	  'name'  # python variable name
	);
	my @undef_args = grep { not defined $args->{$_} } @reqd_args;
	if (scalar @undef_args > 0) {
		p @undef_args;
		die "the above args are required for $current_sub, but weren't defined";
	}
	# 1. Create the JSON Encoder; allow_nonref: allows scalars (strings/numbers) to be encoded
	my $json_encoder = JSON::MaybeXS->new->utf8->allow_nonref;
	# 2. Serialize Perl Data -> JSON String; Passing data directly. JSON::MaybeXS handles refs + scalars automatically.
	my $json_string = $json_encoder->encode( decoded_data( $args->{data} ) );
	# 3. Base64 Encode the JSON String, not the reference
	my $b64_data = encode_base64($json_string, ''); 
	# Assign the b64 string to a temp python variable
	say {$args->{fh}} "$args->{name}_b64 = '$b64_data'";
	# Decode b64 -> bytes -> utf8 string -> json load -> python object
	say {$args->{fh}} "$args->{name} = json.loads(base64.b64decode($args->{name}_b64).decode('utf-8'))";
}
# The twin axis of each axes that has one, by the axes' python name: "ax0" =>
# "twinx_ax0". plot_helper makes one twin per axes and draws every twinned line
# on it, and plot_args reads (and deletes) the entry when it writes that axes'
# legend, so that the legend holds the twin's lines as well. plt empties it
# before it writes a figure, so a call that died part way leaves nothing behind.
my %twin_axes;
# The text of every scatter "tooltips" label in the figure, numbered by its
# place here. scatter_helper draws a labelled point with the url
# "#matplotlib-simple-tooltip-<n>", and once the SVG is written plt turns each
# such link into a group whose <title> is the text, which a browser shows on
# hovering. plt empties it, and sets $tooltips_drawn, before it writes a figure.
my @tooltip_text;
my $tooltips_drawn = 0;    # 1 = output_file is an SVG, which the tooltips are written into; 0 = they are checked and left out
my $tooltip_url = '#matplotlib-simple-tooltip-';
# The methods whose argument is usually bare text, which quote_text quotes.
# "supxlabel" and "supylabel" are figure methods, which are otherwise written
# as given: until 0.32 they were not here, so "supxlabel => 'Time'" wrote
# fig.supxlabel(Time), a NameError, where "suptitle => 'Time'" was quoted.
my @text_methods = ( 'set_title', 'set_xlabel', 'set_ylabel', 'suptitle', 'supxlabel', 'supylabel', 'xlabel', 'ylabel', 'title' );
sub quote_text {
	# A title or axis label as python: quoted, unless it is already python.
	#
	# Text holding a quote or a comma may be python of the caller's own --
	# "'Counts, by book'", "'title', fontsize = 20", 'r"$\it{anno}$"' or
	# 'label = "x", loc = "left"' -- and is left as written when it opens as
	# python does: with a string literal, which may carry a prefix such as r or
	# f, or with a keyword argument. Anything else is prose and is quoted. All
	# such text used to be left as written, so "Bob's data" became
	# set_xlabel(Bob's data), a SyntaxError, and "" became set_title(), a
	# TypeError for want of an argument.
	#
	# The literal has to close, and be all of the text or be followed by a
	# comma and the next argument. An opening quote was enough until 0.32, so
	# "'Tis the season" became set_title('Tis the season) and '"A" vs "B"'
	# became set_title("A" vs "B"), both SyntaxErrors.
	my ($text) = @_;
	$text = decoded_text($text);
	# py_str, not "'$text'": a backslash went through unescaped, so a
	# mathtext '$\alpha$' reached matplotlib with a bell character in it.
	return py_str($text) if $text =~ m/^([^\"\',]+)$/;
	return $text if $text =~ m/^\s*[rRbBuUfF]{0,2}(['"])(?:\\.|(?!\1)[^\\])*\1\s*(?:,|$)/s;
	return $text if $text =~ m/^\s*[A-Za-z_]\w*\s*=[^=]/;
	return py_str($text);
}
sub default_axis_labels {
	# "xlabel" and "ylabel" from the names of the two data keys of hexbin,
	# hist2d or scatter, for each axis the caller labelled in neither form.
	#
	# Only "xlabel" was looked at, so "set_xlabel => 'Custom'" got an "xlabel"
	# beside it, and plt's rename of "xlabel" to "set_xlabel" then wrote the
	# key's name over the caller's label. frame_to_data's $label_axis already
	# looked at both.
	my ( $plot, $x_key, $y_key ) = @_;
	foreach my $label ( [ 'xlabel', $x_key ], [ 'ylabel', $y_key ] ) {
		my ( $axis, $key ) = @{$label};
		next if ( defined $plot->{$axis} ) || ( defined $plot->{"set_$axis"} );
		$plot->{$axis} = py_str($key);
	}
}
sub plot_args {    # this is a helper function to other matplotlib subroutines
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	if ( ref $args ne 'HASH' ) {
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
	# "emit_plt_fig" and "no_legend" are this sub's own arguments, not plot
	# options; see below.
	my @defined_args = ( @reqd_args, 'emit_plt_fig', 'no_legend', @ax_methods, @fig_methods, @plt_methods, @arg, @cb_arg );
	my @bad_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @defined_args
	} keys %{$args};
	if ( scalar @bad_args > 0 ) {
		bad_keyword_error({
			bad      => \@bad_args,
			accepted => \@defined_args,
			sub      => $current_sub
		});
	}
	$args->{ax} = $args->{ax} // 'ax';
	# A copy, because the quoting below writes back into it: the hash can be
	# the caller's own ("twinx_args" hands one in untouched), and a second plot
	# drawn from it found its titles already wrapped in quotes.
	$args->{args} = { %{ $args->{args} } };
	# An array is one call per element, as for every other method below, so
	# each element is quoted. The array itself used to be, and
	# "set_title => ['First', 'Second']" wrote set_title('ARRAY(0x5b95...)').
	foreach my $item ( grep { defined $args->{args}{$_} } @text_methods ) {
		my $text = $args->{args}{$item};
		$args->{args}{$item} = ( ref $text eq 'ARRAY' ) ? [ map { quote_text($_) } @{$text} ] : ( ref $text ) ? $text : quote_text($text);
	}
	# Whether the "fig." and "plt." methods in this hash are written here as
	# well as the "ax." ones. 1 (the default) is what a subplot needs, since
	# nothing else writes them for it; plt() passes 0 for a single plot, whose
	# hash it walks itself afterwards. Both passes used to run over that one
	# hash, so every figure-wide and pyplot-wide option was written twice, and
	# the second pass ran print_type over text the first had already quoted:
	# suptitle => "'Counts, by book'" left plt.suptitle(''Counts, by book'')
	# in the script, a SyntaxError.
	$args->{emit_plt_fig} = $args->{emit_plt_fig} // 1;
	my @obj  = ( $args->{ax} );
	my @args = ( \@ax_methods );
	if ( $args->{emit_plt_fig} ) {
		push @obj,  'fig', 'plt';
		push @args, \@fig_methods, \@plt_methods;
	}
	foreach my $i ( 0 .. $#args ) {
		my @methods = grep { defined $args->{args}{$_} && ( $_ ne 'legend' ) } @{ $args[$i] };    # "legend" is written below, and only when something has a label
		# pyplot's functions act on the current axes, which after plt.subplots is
		# the last subplot and after a twinx() is the twin, so a subplot's own
		# "ylim" or "axhline" was drawn on some other subplot. This one is made
		# current first.
		if ( ( $obj[$i] eq 'plt' ) && ( grep { $_ ne 'show' } @methods ) ) {
			say {$args->{fh}} "plt.sca($args->{ax}) #line" . __LINE__;
		}
		# Only the pyplot calls are quoted, as plt() quotes a single plot's; the
		# axes and figure methods are written as given in both.
		my $arg_text = ( $obj[$i] eq 'plt' ) ? \&pyplot_arg : sub { $_[0] };
		foreach my $method (@methods) {
			my $ref = ref $args->{args}{$method};
			if ( ( $ref ne 'ARRAY' ) && ( $ref ne '' ) ) {
				die "$current_sub only accepts scalar or array types, but \"$ref\" was entered.";
			}
			if ( $ref eq '' ) {
				if ($method eq 'show') {
					next; # plt.show() is emitted by plt() after plt.savefig()
				} else {
					say {$args->{fh}} "$obj[$i].$method(" . $arg_text->( $args->{args}{$method} ) . ') #line' . __LINE__;
				}
				next;
			}
			# can only be ARRAY
			foreach my $j ( @{ $args->{args}{$method} } ) {
				say { $args->{fh} } "$obj[$i].$method(" . $arg_text->($j) . ') #line' . __LINE__;
			}
		}
	}
	return unless defined $args->{ax};
	my $legend   = $args->{args}{legend} // '';
	my $pie_plot = 0;
	if (   ( defined $args->{args}{plot_type} )
	  && ( $args->{args}{plot_type} eq 'pie' ) ) {
	  $pie_plot = 1;
	}
	return 1 if $pie_plot == 1;
	# pie charts don't get legends
	# A twin axis (see %twin_axes) is given no legend of its own: its lines go
	# in the legend of the axes it twins.
	return 1 if $args->{no_legend};
	say { $args->{fh} }
	"handles, labels = $args->{ax}.get_legend_handles_labels()";
	my $twin = delete $twin_axes{ $args->{ax} };
	if ( defined $twin ) {
		# One legend for both axes, drawn on the twin because the twin is drawn
		# over the axes it twins, and would cover a legend drawn on them. The
		# twin's lines were in no legend at all, or -- with "twinx_args" -- in a
		# second one drawn on top of the first, in the same "best" place.
		say { $args->{fh} } "twin_handles, twin_labels = $twin.get_legend_handles_labels()";
		say { $args->{fh} } 'handles += twin_handles';
		say { $args->{fh} } 'labels += twin_labels';
		say { $args->{fh} } 'if len(labels) > 0:';
		say { $args->{fh} } "\t$twin.legend(handles, labels" . ( length $legend ? ", $legend" : '' ) . ')';
		return 1;
	}
	say { $args->{fh} } 'if len(labels) > 0:';
	say { $args->{fh} } "\t$args->{ax}.legend($legend)";
}
sub barplot_helper { # this is a helper function to other matplotlib subroutines
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	my @opt = ('ax', @reqd_args, @ax_methods, @plt_methods, @fig_methods, @arg, @{ $opt{$current_sub} }	);
	my $plot      = $args->{plot};
	my @bad_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	my $ax = $args->{ax} // '';
	if ( scalar @bad_opt > 0 ) {
		bad_keyword_error({
			bad       => \@bad_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	my ( %ref_counts, $plot_type );
	foreach my $set ( keys %{ $plot->{data} } ) {
	  $ref_counts{ ref $plot->{data}{$set} }++;
	}
	if ( scalar keys %ref_counts > 1 ) {
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
		# "|| $a cmp $b": two inner keys differing only in case ("a", "A") tied,
		# and hash order then chose which series came first, from run to run.
		my @key2 = sort { lc $a cmp lc $b || $a cmp $b } keys %key2;
		my %new_structure;
		foreach my $k1 ( keys %{ $plot->{data} } ) {
			@{ $new_structure{$k1} } = @{ $plot->{data}{$k1} }{@key2};
		}
		# The inner keys are the series, so a color given as a hash can be
		# answered here: turn it into the positional array the series loop
		# below reads. Given as a hash it was silently dropped, since that
		# loop only ever looked at an ARRAY.
		if ( ( defined $plot->{color} ) && ( ref $plot->{color} eq 'HASH' ) ) {
			my @uncolored = grep { not defined $plot->{color}{$_} } @key2;
			if ( scalar @uncolored > 0 ) {
				p @uncolored;
				die "the above series have no color defined in \"color\" in $current_sub";
			}
			$plot->{color} = [ @{ $plot->{color} }{@key2} ];
		}
		# A new array rather than "@{ $plot->{label} } = ...", which wrote the
		# series names into an array the caller may have passed as "label".
		$plot->{label} = [@key2];
		$plot->{data} = \%new_structure;
	} else {
	  p %ref_counts;
	  p $plot->{data};
	  die 'the above plot type is not yet programmed in to bar/barh';
	}
	# Read as a Python bool, as "log" is: it was compared with "==", so
	# "stacked => 'True'" died as 'Argument "True" isn't numeric', and a
	# negative number shifted the bars as though unstacked while keeping the
	# full width of stacked ones.
	$plot->{stacked} = bool_option( $plot->{stacked}, 'stacked', $current_sub );
	# "float only", as documented, and written bare: "width => 'wide'" was a
	# NameError in Python.
	if ( defined $plot->{width} ) {
		if ( ref $plot->{width} ) {
			die "\"width\" is one number for every bar in $current_sub, not a " . ref( $plot->{width} ) . ' reference';
		}
		check_numbers( [ $plot->{width} ], '"width"', $current_sub );
		die "\"width\" must be a finite number for $current_sub, not \"$plot->{width}\"" unless is_finite( $plot->{width} );
	}
	if (   ( $plot_type eq 'grouped' )
	  && ( defined $plot->{width} )
	  && ( $plot->{stacked} == 0 ) )
	{
	  say STDERR 'grouped, non-stacked barplots ignore width settings';
	  delete $plot->{width};
	}
	my @key_order;
	if ( defined $plot->{key_order} ) {
	  @key_order = check_key_order({
	  	keys   => $plot->{key_order},
	  	data   => $plot->{data},
	  	option => 'key_order',
	  	sub    => $current_sub
	  });
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	# A color per data key only means something for the simple form, where one
	# key is one bar, and for the hash-of-hashes form, whose inner keys named
	# the series and were turned into an array above. The hash-of-arrays form
	# has nothing to key a color hash by, and used to ignore it in silence.
	if ( ( $plot_type eq 'grouped' ) && ( ref $plot->{color} eq 'HASH' ) ) {
		die "$current_sub: \"color\" is a HASH, but this data is a hash of arrays, whose series have no names to key it by: give one color per series as an array, e.g. color => ['red','blue']";
	}
	# Every value reaches the script as it stands, so a non-numeric one
	# becomes a bare Python name: "data => { A => 'abc' }" wrote "vals = [abc]"
	# and died as a NameError when the script ran, pointing at the generated
	# file rather than at the data.
	foreach my $key (@key_order) {
		my @values = ( $plot_type eq 'simple' ) ? ( $plot->{data}{$key} ) : @{ $plot->{data}{$key} };
		my @bad = grep { defined && !looks_like_number($_) } @values;
		if ( scalar @bad > 0 ) {
			p @bad;
			die "the above values of \"$key\" are not numbers, which $current_sub needs";
		}
		next unless $plot_type eq 'simple';
		die "\"$key\" has an undefined value, which $current_sub cannot plot"
		 unless defined $plot->{data}{$key};
	}
	if ( $plot_type eq 'grouped' ) {
		# One bar per key per series, so a short array leaves a series with
		# more x positions than heights, which matplotlib rejects with a shape
		# mismatch naming neither the key nor the length it expected.
		my %n_values = map { $_ => scalar @{ $plot->{data}{$_} } } @key_order;
		my %lengths = map { $_ => 1 } values %n_values;
		if ( scalar keys %lengths > 1 ) {
			p %n_values;
			die "the above keys hold different numbers of values; every key of a grouped $plot->{plot_type} needs the same number";
		}
		# Nothing to draw, which died as "Can't use an undefined value as an
		# ARRAY reference" where the first series was looked for.
		if ( ( scalar keys %lengths == 1 ) && ( ( keys %lengths )[0] == 0 ) ) {
			die "every key of \"data\" holds an empty array, so $current_sub has no bars to draw";
		}
	}
	my $options = '';    # these args go to the plt.bar call
	if ( bool_option( $plot->{'log'}, 'log', $current_sub ) || $plot->{logscale} ) {    # "logscale" is documented as taking Perl truth, "log" as a Python bool
	  $options .= ', log = True';
	}    # args that can be either arrays or strings below; STRINGS:
	foreach my $c ( grep { defined $plot->{$_} } ( 'color', 'edgecolor' ) ) {
		next if ( ( $c eq 'color' ) && ( $plot_type eq 'grouped' ) && ( ref $plot->{$c} ne '' ) );
		my $ref = ref $plot->{$c};
		if ( $ref eq '' ) {    # single color
			$options .= ", $c = " . py_str( $plot->{$c} );
		} elsif ( $ref eq 'ARRAY' ) {
			$options .= ", $c = [" . py_list( @{ $plot->{$c} } ) . ']';
		} elsif ( $ref eq 'HASH' ) {
			# One color per bar, keyed as the bars are, as "color" is. An
			# "edgecolor" hash fell into an empty branch here and was dropped
			# without a word. Every bar of a grouped plot is one key of one
			# series, and the hash has nothing to say which.
			if ( ( $c eq 'edgecolor' ) && ( $plot_type eq 'grouped' ) ) {
				die "$current_sub: \"edgecolor\" is a HASH, which is keyed by bar and so only fits a simple hash of one bar per key: give a grouped plot one color, or an array of one per key";
			}
			next if $c eq 'color';    # written with the bars, below
			my @uncolored = grep { not defined $plot->{$c}{$_} } @key_order;
			if ( scalar @uncolored > 0 ) {
				p @uncolored;
				die "the above keys have no color defined in \"$c\" in $current_sub";
			}
			$options .= ", $c = [" . py_list( @{ $plot->{$c} }{@key_order} ) . ']';
		} else {
			die "ref \"$ref\" isn't defined";
		}
	} # args that can be either arrays or strings below; NUMERIC:
	# One width for every bar edge, or one per bar. Nothing checked it, so
	# "linewidth => 'thick'" was written as a bare Python name.
	foreach my $c ( grep { defined $plot->{$_} } ('linewidth') ) {
		my $ref = ref $plot->{$c};
		if ( ( $ref ne '' ) && ( $ref ne 'ARRAY' ) ) {
			p $args;
			die "$ref for $c isn't acceptable";
		}
		my @values = ( $ref eq 'ARRAY' ) ? @{ $plot->{$c} } : ( $plot->{$c} );
		check_numbers( \@values, "\"$c\"", $current_sub );
		$options .= ( $ref eq 'ARRAY' ) ? ", $c = [" . py_nums(@values) . ']' : ", $c = " . py_num( $plot->{$c} );
	}
	# Error bars take the shapes matplotlib does -- one number for every bar,
	# an array of one per bar, or an array of two such arrays, lower then upper
	# -- and a hash keyed by the data keys, each value one number or a
	# [ lower, upper ] pair. An array died as "ARRAY for yerr isn't acceptable"
	# though the options table offered it, and a hash value that was one number,
	# or a key left out of the hash, died dereferencing it.
	my $n_bars = scalar @key_order;
	# An error bar across the bars of a simple plot -- "yerr" on a barh, "xerr"
	# on a bar -- lies along the axis that holds the labels, which are strings.
	# matplotlib draws one there from one number, or one per bar, but not from
	# a lower and an upper row: it adds the errors to the labels and dies as
	# "ConversionError: Failed to convert value(s) to axis units". The hash
	# form always wrote two rows, so barh(yerr => { A => 1, B => 1 }) died
	# that way though its errors were the same on both sides. Two rows that
	# are equal are written as the one row they amount to, and two that
	# differ are refused here, by name. A grouped plot is drawn at numbers and
	# takes either.
	my $across = sub {
		my ( $err, $low, $high ) = @_;
		return 0 unless ( $plot_type eq 'simple' ) && ( $err eq ( ( $plot->{plot_type} eq 'barh' ) ? 'yerr' : 'xerr' ) );
		if ( grep { ( 0 + $low->[$_] ) != ( 0 + $high->[$_] ) } 0 .. $#{$low} ) {
			die "\"$err\" on a $plot->{plot_type} lies along the axis of its labels, where matplotlib draws the same error on both sides of a bar and not a lower and an upper one, in $current_sub: give one number per bar, or \""
			 . ( ( $err eq 'yerr' ) ? 'xerr' : 'yerr' ) . '" for an error in the bars\' own direction';
		}
		return 1;
	};
	foreach my $err ( grep { defined $plot->{$_} } ( 'xerr', 'yerr' ) ) {
		my $ref = ref $plot->{$err};
		if ( $ref eq '' ) {
			check_numbers( [ $plot->{$err} ], "\"$err\"", $current_sub );
			$options .= ", $err = " . py_num( $plot->{$err} );
		} elsif ( $ref eq 'ARRAY' ) {
			my @rows = ( grep { ref } @{ $plot->{$err} } ) ? @{ $plot->{$err} } : ( $plot->{$err} );
			if ( ( scalar @rows > 2 ) || ( grep { ref $_ ne 'ARRAY' } @rows ) ) {
				die "\"$err\" is an array of one error per bar, or of two such arrays (lower, then upper), in $current_sub";
			}
			foreach my $row (@rows) {
				if ( scalar @{$row} != $n_bars ) {
					die "\"$err\" has " . scalar( @{$row} ) . " values in a row, but $current_sub has $n_bars bars";
				}
				check_numbers( $row, "\"$err\"", $current_sub );
			}
			pop @rows if ( scalar @rows == 2 ) && $across->( $err, @rows );
			my @py = map { '[' . py_nums( @{$_} ) . ']' } @rows;
			$options .= ", $err = " . ( ( scalar @rows == 1 ) ? $py[0] : '[' . join( ',', @py ) . ']' );
		} elsif ( $ref eq 'HASH' ) {
			my @missing = grep { not defined $plot->{$err}{$_} } @key_order;
			if ( scalar @missing > 0 ) {
				p @missing;
				die "the above keys have no \"$err\" in $current_sub";
			}
			my ( @low, @high );
			foreach my $i (@key_order) {
				my $e    = $plot->{$err}{$i};
				my @pair = ( ref $e eq 'ARRAY' ) ? @{$e} : ( ref $e eq '' ) ? ( $e, $e ) : ();
				if ( scalar @pair != 2 ) {
					p $e;
					die "$err/$i should be one number, or exactly 2 items: low and high error bars";
				}
				check_numbers( \@pair, "\"$err\" of \"$i\"", $current_sub );
				push @low,  $pair[0];
				push @high, $pair[1];
			}
			$options .= $across->( $err, \@low, \@high )
			 ? ", $err = [" . py_nums(@low) . ']'
			 : ", $err = [[" . py_nums(@low) . '],[' . py_nums(@high) . ']]';
		} else {
			p $args;
			die "$ref for $err isn't acceptable";
		}
	}
	if ( $plot_type eq 'simple' ) {    # a simple hash -> simple bar plot
		write_data({
			data => \@key_order,
			fh   => $args->{fh},
			name => 'labels'
		});
		say { $args->{fh} } 'vals = [' . py_nums( @{ $plot->{data} }{@key_order} ) . ']';
		if ((defined $plot->{color}) && (ref $plot->{color} eq 'HASH')) {
			@undef_args = grep {not defined $plot->{color}{$_}} @key_order;
			if (scalar @undef_args > 0) {
				p @undef_args;
				die 'the above keys were not defined in the colors hash';
			}
			$options .= ',color = [' . py_list( @{ $plot->{color} }{@key_order} ) . ']';
		}
		# "width" was read only by the grouped, stacked path, so a simple bar
		# plot was drawn at matplotlib's 0.8 whatever it said. barh calls the
		# same dimension "height".
		if ( defined $plot->{width} ) {
			$options .= ', ' . ( $plot->{plot_type} eq 'barh' ? 'height' : 'width' ) . ' = ' . py_num( $plot->{width} );
		}
		say { $args->{fh} } "ax$ax.$plot->{plot_type}(labels, vals $options)";
	} elsif ( $plot_type eq 'grouped' ) {    # grouped bar plot; hash of array
		my @val;
		foreach my $k (@key_order) {
			foreach my $i ( 0 .. scalar @{ $plot->{data}{$k} } - 1 ) {
				# 0 for a missing value, so that every series has a bar at
				# every key. Not written back: the array is the caller's.
				push @{ $val[$i] }, $plot->{data}{$k}[$i] // 0;
			}
		}
		my $barwidth = $plot->{width} // 0.8;
		if ( $plot->{stacked} == 0 ) {
			$barwidth /= ( scalar @val + 1 ); # @val holds one array per bar series
		}
		my @xticks   = 0 .. scalar @{ $val[0] } - 1;
		my @mean_pos = map { 0 } 0 .. scalar @{ $val[0] } - 1;    # initialize
		my $hw       = 'height';
		$hw = 'width' if $plot->{plot_type} eq 'bar';
		my @bottom = map { 0 } 0 .. scalar @{ $val[0] } - 1;      # initialize
		my $i = 0;
		foreach my $arr (@val) {
			my $x = '[' . join( ',', @xticks ) . ']';
			foreach my $p ( 0 .. $#mean_pos ) {
				$mean_pos[$p] += $xticks[$p];
			}
			my $set_options = '';
			foreach
			  my $f ( grep { ( ref $plot->{$_} eq 'ARRAY' ) && defined $plot->{$_}[$i] } ( 'color', 'label' ) )
			{
				 # py_str: a label is a series name, which for the
				 # hash-of-hashes form is one of the caller's own inner keys.
				 $set_options .= ", $f = " . py_str( $plot->{$f}[$i] );
			}
			if ( $plot->{stacked} > 0 ) {
				my $stack_kwarg = $plot->{plot_type} eq 'barh' ? 'left' : 'bottom';
				$set_options .= ", $stack_kwarg = [" . py_nums(@bottom) . ']';
			}
			say { $args->{fh} } "ax$ax.$plot->{plot_type}($x, ["
			 . py_nums( @{$arr} )
			 . "], $hw = " . py_num($barwidth) . " $options $set_options)";
			@bottom =
			  map { $bottom[$_] + $arr->[$_] } 0 .. scalar @{ $val[0] } - 1
			  if $plot->{stacked} > 0;
			@xticks = map { $_ + $barwidth } @xticks
			  if $plot->{stacked} <= 0;    # for next iteration
			  $i++;
		}
		my $xticks = '[' . py_list(@key_order) . ']';
		my $ticks  = 'yticks';
		$ticks = 'xticks' if $plot->{plot_type} eq 'bar';
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
	if ( ref $args ne 'HASH' ) {
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
	  @ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} }
	);
	my $plot      = $args->{plot};
	my @bad_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @bad_opt > 0 ) {
		bad_keyword_error({
			bad       => \@bad_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	$plot->{orientation} = $plot->{orientation} // 'vertical';
	if ( $plot->{orientation} !~ m/^(?:horizontal|vertical)$/ ) {
	  die
	"$current_sub needs either \"horizontal\" or \"vertical\", not \"$plot->{orientation}\"";
	}
	if (ref $plot->{data} eq 'ARRAY') {
		my $tmp = delete $plot->{data};
		$plot->{data}{''} = $tmp;
	}
	my ( @xticks, @key_order );
	if ( defined $plot->{key_order} ) {
	  @key_order = check_key_order({
	  	keys   => $plot->{key_order},
	  	data   => $plot->{data},
	  	option => 'key_order',
	  	sub    => $current_sub
	  });
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	my $ax = $args->{ax} // '';
	$plot->{notch}      = $plot->{notch}      // 'False';
	$plot->{showcaps}   = $plot->{showcaps}   // 'True';
	$plot->{showfliers} = $plot->{showfliers} // 'True';
	$plot->{showmeans}  = $plot->{showmeans}  // 'True';
	my $options = "orientation = '$plot->{orientation}'";
	# Through bool_option, as bar's "log" is: each was written as given, so
	# "notch => 'false'" left "notch = false" in the script, a NameError.
	foreach my $arg ( 'showcaps', 'showfliers', 'showmeans', 'notch') {
	  $options .= ", $arg = " . ( bool_option( $plot->{$arg}, $arg, $current_sub ) ? 'True' : 'False' );
	}
	# A color per box is "colors"; "color" is one color for them all, and a
	# hash given here was written into the script as 'HASH(0x...)'.
	if ( ref $plot->{color} ) {
		die "\"color\" is one color for every box in $current_sub, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	foreach my $axis ( logscale_axes( $plot->{logscale}, $current_sub ) ) { # x, y
		say {$args->{fh}} "ax$ax.set_$axis" . 'scale("log")';
	}
	say { $args->{fh} } 'd = []';
	# %values, rather than writing the filtered list back into $plot->{data}:
	# the arrays in there belong to the caller, and dropping the undefined
	# elements in place left the caller's own array shorter than they wrote it.
	my %values;
	foreach my $key (@key_order) {
		@{ $values{$key} } = grep { ( defined ) && ( not is_nan($_) ) } @{ $plot->{data}{$key} };    # NaN is a missing value, as undef is
		my @non_numeric = grep {!looks_like_number($_)} @{ $values{$key} };
		if (scalar @non_numeric > 0) {
			p @non_numeric;
			die "$key has non-numeric values";
		}
		say { $args->{fh} } 'd.append([' . py_nums( @{ $values{$key} } ) . '])';
	}
	say { $args->{fh} } "bp = ax$ax.boxplot(d, patch_artist = True, $options)";
	if ( defined $plot->{colors} ){ # every hash key should have its own color defined
	# the below code helps to provide better error messages in case I make an error in calling the sub
		my @bad_keys =
		 grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
		if ( scalar @bad_keys > 0 ) {
			p @bad_keys;
			die 'the above data keys have no defined color';
		}

	# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
	  print { $args->{fh} } 'colors = ['
		 . py_list( @{ $plot->{colors} }{@key_order} ) . ']' . "\n";

	 # the above color list will have the same order, via the above hash slice
	  say { $args->{fh} } 'for patch, color in zip(bp["boxes"], colors):';
	  say { $args->{fh} } "\tpatch.set_facecolor(color)";
	  say { $args->{fh} } "\tpatch.set_edgecolor('black')";
	} else {
		say { $args->{fh} } 'for pc in bp["boxes"]:';
		if ( defined $plot->{color} ) {
			say { $args->{fh} } "\tpc.set_facecolor(" . py_str($plot->{color}) . ')';
		}
		say { $args->{fh} } "\tpc.set_edgecolor('black')";
	}
	foreach my $key (@key_order) {
		push @xticks, "$key ("
		 . format_commas( scalar @{ $values{$key} }, '%.0u' ) . ')';
	}
	if ( $plot->{orientation} eq 'vertical' ) {
		say { $args->{fh} } "ax$ax.set_xticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ['
		 . py_list(@xticks) . '])';
	} else {
		say { $args->{fh} } "ax$ax.set_yticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ['
		 . py_list(@xticks) . '])';
	}
}

sub colored_table_helper {
	my ($args) = @_;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1]; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if (ref $args ne 'HASH') {
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
	'ax', @{ $opt{$current_sub} });
	my @bad_args = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $args };
	if (scalar @bad_args > 0) {
		bad_keyword_error({
			bad      => \@bad_args,
			accepted => \@defined_args,
			sub      => $current_sub
		});
	}
	my $plot = $args->{plot};
#	The check above is on this sub's own arguments (fh, plot, ax), not on the
#	caller's plot keywords, which live one level down in "plot" and were going
#	unchecked here while every other helper checked its own.
	my @bad_opt = grep { my $key = $_; not grep {$_ eq $key} @defined_args} keys %{ $plot };
	if (scalar @bad_opt > 0) {
		bad_keyword_error({
			bad       => \@bad_opt,
			accepted  => \@defined_args,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	$plot->{mirror} = bool_option( $plot->{mirror}, 'mirror', $current_sub );
	my ( $row_keys, $cols, $cells ) = table_cells( $plot, $current_sub );
	my @row_keys = @{$row_keys};
	my @cols     = @{$cols};
	my %data     = %{$cells};
	my @rows;
	if (defined $plot->{row_labels}) {
		@rows = @{ $plot->{row_labels} };
		# matplotlib refuses a count that differs, with an error naming neither
		# option.
		if ( scalar @rows != scalar @row_keys ) {
			die "\"row_labels\" has " . scalar(@rows) . ' labels, but the table has ' . scalar(@row_keys) . " rows in $current_sub";
		}
	} else {
		@rows = @row_keys;
	}
	my ($min, $max) = ('inf', '-inf');
	my $min_positive = 'inf';    # the floor of a log scale, which cannot start at 0 or below
	my $n_numeric = 0;    # cells that hold a number, for the check below
	say {$args->{fh}} 'd = []';
	say {$args->{fh}} 'import numpy as np';
	# What a cell with no value in "data" gets. np.nan, which a NaN cell also
	# becomes, is drawn in "undef_color" by the colormap's set_bad below and
	# left blank by "show_numbers"; a "default_undefined" given by the caller
	# is an ordinary value instead, counting towards the color scale like any
	# other. The option was read and then ignored -- the line below assigned
	# np.nan with "$plot->{default_undefined}" commented out beside it -- so a
	# table asked to call its holes 0 still drew them as holes.
	if (defined $plot->{default_undefined}) {
		unless (looks_like_number($plot->{default_undefined})) {
			die "\"default_undefined\" = $plot->{default_undefined} must be a number";
		}
	}
	# A cell that holds something other than a number is written into the
	# script as it stands, so "NA" became "d.append([1,NA])" and died as a
	# NameError. Checked before anything is written.
	my @non_numeric;
	foreach my $k1 (@row_keys) {
		foreach my $k2 (grep { (defined $data{$k1}{$_}) && (not looks_like_number($data{$k1}{$_})) } @cols) {
			push @non_numeric, "$k1/$k2 = \"$data{$k1}{$k2}\"";
		}
	}
	if (scalar @non_numeric > 0) {
		p @non_numeric;
		die "the above cells are not numbers, which $current_sub needs; leave a cell out, or undefined, to draw it in \"undef_color\"";
	}
	foreach my $k1 (@row_keys) {
		my @cells;
		foreach my $k2 (@cols) {
			my $value = $data{$k1}{$k2} // $plot->{default_undefined};
			push @cells, defined $value ? py_num($value) : 'np.nan';
			# A NaN or an infinity is drawn, but cannot be an end of the scale.
			next unless ( defined $value ) && is_finite($value);
			$min = min($min, $value);
			$max = max($max, $value);
			$min_positive = min($min_positive, $value) if $value > 0;
			$n_numeric++;
		}
		say {$args->{fh}} 'd.append([' . join( ',', @cells ) . '])';
	}
	# Nothing to scale the colors by. $min and $max are still the strings they
	# started as, and "plt.Normalize(inf, -inf)" is a NameError in Python,
	# which said nothing about the table being empty.
	if (($n_numeric == 0) && ((not defined $plot->{cb_min}) || (not defined $plot->{cb_max}))) {
		p $plot->{data};
		die "no cell of the above data holds a number, so $current_sub has nothing to color by";
	}
	foreach my $opt (grep {defined $plot->{$_}} 'cb_min', 'cb_max'){
		unless (looks_like_number( $plot->{$opt} )) {
			die "\"$opt\" = $plot->{$opt} must be a number";
		}
		# An end of the scale at infinity leaves no finite range to color by.
		die "\"$opt\" = $plot->{$opt} must be a finite number" unless is_finite( $plot->{$opt} );
	}
	$plot->{cmap} = $plot->{cmap} // 'gist_rainbow';
	$plot->{cb_logscale} = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	my $ax = $args->{ax} // '';
	# One norm, used both to color the cells and by the hidden image that the
	# colorbar is drawn from. The cells used to be colored through a linear
	# plt.Normalize whatever "cb_logscale" said, so only the colorbar was
	# logarithmic, and a table of 1, 10, 100 and 1000 drew three of its four
	# cells in nearly the same color.
	my $norm;
	if ($plot->{cb_logscale}) {
		# LogNorm refuses a vmin at or below 0; the one it chose for itself,
		# when it was left to autoscale, was the smallest positive value.
		$min = $plot->{cb_min} // $min_positive;
		if ($min eq 'inf') {
			die "\"cb_logscale\" needs a cell above 0 to start the scale at, or a \"cb_min\" above 0, and $current_sub has neither";
		}
		if ($min <= 0) {
			die "\"cb_logscale\" cannot start at \"cb_min\" = $min: a log scale needs a minimum above 0";
		}
		$max = $plot->{cb_max} // $max;
		say {$args->{fh}} 'from matplotlib import colors';
		$norm = 'colors.LogNorm(vmin = ' . py_num($min) . ', vmax = ' . py_num($max) . ')';
	} else {
		$min = $plot->{cb_min} // $min;
		$max = $plot->{cb_max} // $max;
		$norm = 'plt.Normalize(' . py_num($min) . ', ' . py_num($max) . ')';    # py_num: a cb_min such as "007" was written as given
	}
	$plot->{undef_color} = $plot->{undef_color} // 'gray';
	say {$args->{fh}} 'import matplotlib';
	say {$args->{fh}} 'table_cmap = matplotlib.colormaps[' . py_str($plot->{cmap}) . '].copy()';
	say {$args->{fh}} 'table_cmap.set_bad(' . py_str($plot->{undef_color}) . ')';
	say {$args->{fh}} "norm = $norm";
	say {$args->{fh}} 'datacolors = table_cmap(norm(d))';
	say {$args->{fh}} "img = ax$ax.imshow(d, cmap=table_cmap, norm=norm)";
	$plot->{colorbar_on} = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', $current_sub );
	# "colorbar_on" decides, and "cblabel" only says what to write on it. A
	# cblabel used to draw the colorbar even against "colorbar_on => 0",
	# which the documentation recorded rather than fixed: nobody passes a label
	# for a colorbar they have just turned off, so it read as a typo that the
	# module honoured.
	if ($plot->{colorbar_on}) {
		# colorbar_args: the cb* options, documented as working here, were
		# accepted and never written.
		my $label = defined $plot->{cblabel} ? ', label = ' . py_str($plot->{cblabel}) : '';
		say {$args->{fh}} "fig.colorbar(img$label" . colorbar_args($plot) . ')';
	}
	say {$args->{fh}} 'img.set_visible(False)';
	$plot->{show_numbers} = bool_option( $plot->{show_numbers}, 'show_numbers', $current_sub );
	say {$args->{fh}} 'for ri, row in enumerate(d):';
	say {$args->{fh}} '	for ii, item in enumerate(row):';
	say {$args->{fh}} '		if np.isnan(item):';
	say {$args->{fh}} '			d[ri][ii] = ""';
	if ($plot->{show_numbers}) {
		say {$args->{fh}} "table = ax$ax" . '.table(cellText=d, rowLabels=[' . py_list(@rows) . '], colLabels = [' . py_list(@cols) . '], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	} else {
		say {$args->{fh}} "table = ax$ax" . '.table(rowLabels=[' . py_list(@rows) . '], colLabels = [' . py_list(@cols) . '], cellColours = datacolors, loc = "center", bbox=[0,0,1,1])';
	}
	# No title written here, though there was one: it emitted "ax0.title('..')",
	# and "title" is a Text attribute of the axes rather than a method, so a
	# colored_table given a title died with "TypeError: 'Text' object is not
	# callable". plt() renames "title" to "set_title" for every plot type once
	# its helper has run, which is what actually draws it.
	# No logscale loop here, though there was one: "logscale" is not among the
	# options colored_table accepts, so the loop could never run, and a log
	# scale would mean nothing on a table whose axes are the row and column
	# labels -- both sets of ticks are emptied a few lines below.
#	say {$args->{fh}} "fig.clim(vmin = $plot->{cb_min})" if defined $plot->{cb_min};
#	say {$args->{fh}} "fig.clim(vmax = $plot->{cb_max})" if defined $plot->{cb_max};
	foreach my $axis ('x','y') {
		say {$args->{fh}} "ax$ax.set_${axis}ticks" . '([])';
		say {$args->{fh}} "ax$ax.set_${axis}ticklabels" . '([])';
	}
}

sub hexbin_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	  'ax', @{ $opt{$current_sub} }
	);
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
		bad_keyword_error({
			bad       => \@undef_args,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	cb_limits( $plot, $current_sub );
	$plot->{cb_logscale} = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	$plot->{marginals}   = $plot->{marginals}   // 0;
	bin_counts( $plot, $current_sub );
	my @keys;
	if ( defined $plot->{key_order} ) {
		@keys = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
	} else {
		@keys = sort keys %{ $plot->{data} };
	}
	if ( scalar @keys != 2 ) {
	  p @keys;
	  die "There must be exactly 2 keys for $current_sub";
	}
	my $n_points = scalar @{ $plot->{data}{ $keys[0] } };
	if ( scalar @{ $plot->{data}{ $keys[1] } } != $n_points ) {
	  say STDERR "\"$keys[0]\" has $n_points points.";
	  say STDERR "\"$keys[1]\" has "
		 . scalar @{ $plot->{data}{ $keys[1] } }
		 . " points.";
	  die 'The length of both keys must be equal.';
	}
	# Every point is written into the script as it stands, and nothing checked
	# them: an undefined one came out as an empty list element and a string
	# as a bare python name, each dying as a python error about the temp file.
	foreach my $key (@keys) {
		my @bad = grep { not looks_like_number( $plot->{data}{$key}[$_] ) } 0 .. $n_points - 1;
		next if scalar @bad == 0;
		p @bad;
		die "\"$key\" is undefined or not a number at the above indices, which $current_sub needs";
	}
	# quoted here because the key is data: the pass-through path that title and
	# label text otherwise take cannot tell an apostrophe from Python of the
	# user's own, and leaves it bare. See py_str.
	default_axis_labels( $plot, @keys );
	$plot->{cmap}   = $plot->{cmap}   // 'gist_rainbow';
	my $options =
	", gridsize = ($plot->{xbins}, $plot->{ybins}), cmap = " . py_str($plot->{cmap})
	;    # these args go to the plt.hist call
	foreach my $opt ( grep { defined $plot->{$_} } ( 'vmin', 'vmax', 'mincnt' ) ) {
		if ( not looks_like_number( $plot->{$opt} ) ) {
			die "\"$opt\" must be a number for $current_sub, but was given \"$plot->{$opt}\"";
		}
	}
	# A log scale cannot start at 0 or below, which LogNorm refused from inside
	# matplotlib, naming neither option.
	if ( ( $plot->{cb_logscale} ) && ( defined $plot->{vmin} ) && ( $plot->{vmin} <= 0 ) ) {
		die "\"cb_logscale\" cannot start at \"vmin\" = $plot->{vmin} in $current_sub: a log scale needs a minimum above 0";
	}
	# py_num, here and below: each was written as given, so "vmax => 'inf'",
	# which looks_like_number accepts, was a NameError in the script.
	if ( $plot->{cb_logscale} ) {
		# vmin and vmax go to the LogNorm, as in hist2d_helper: passed beside
		# it they raised "ValueError: Passing a Normalize instance
		# simultaneously with vmin/vmax is not supported".
		say { $args->{fh} } 'from matplotlib.colors import LogNorm';
		my @lognorm_opt = map { "$_ = " . py_num( $plot->{$_} ) } grep { defined $plot->{$_} } ( 'vmin', 'vmax' );
		$options .= ', norm = LogNorm(' . join( ', ', @lognorm_opt ) . ')';
		foreach my $opt ( grep { defined $plot->{$_} } ('mincnt') ) {
			$options .= ", $opt = " . py_num( $plot->{$opt} );
		}
	} else {
		foreach my $opt ( grep { defined $plot->{$_} } ( 'vmin', 'vmax', 'mincnt' ) ) {
			$options .= ", $opt = " . py_num( $plot->{$opt} );
		}
	}
	foreach my $opt (grep {defined $plot->{$_} } ('xscale_hexbin', 'yscale_hexbin')) {
		if (($plot->{$opt} ne 'log') && ($plot->{$opt} ne 'linear')) {
			die "\"$opt\" is neither \"log\" nor \"linear\"";
		}
		my $opth = $opt;
		$opth =~ s/_hexbin$//;    # "xscale_hexbin" is hexbin's own "xscale"
		$options .= ", $opth = '$plot->{$opt}'";
	}
	if ( bool_option( $plot->{marginals}, 'marginals', $current_sub ) ) {
		$options .= ', marginals = True';
	}
	say { $args->{fh} } 'x = ['
	. py_nums( @{ $plot->{data}{ $keys[0] } } ) . ']';
	say { $args->{fh} } 'y = ['
	. py_nums( @{ $plot->{data}{ $keys[1] } } ) . ']';
	my $ax = $args->{ax} // '';
	say { $args->{fh} } "im$ax = ax$ax.hexbin(x, y $options)\n";
	my $opts = colorbar_args($plot);    # cblabel is written below
	# "colorbar_on" is read here, and not only for the shared-colorbar test
	# above: the colorbar was drawn whatever it said, so "colorbar_on => 0"
	# did nothing, and a figure sharing one colorbar between subplots got the
	# shared one *and* the per-subplot one plt() had asked to be turned off.
	if ( $plot->{colorbar_on} ) {
		if ( defined $plot->{cblabel} ) {
			write_data({
				data => $plot->{cblabel},
				fh   => $args->{fh},
				name => 'cblabel',
			});
			say { $args->{fh} } "plt.colorbar(im$ax, label = cblabel $opts)";
		} else {
			say { $args->{fh} } "plt.colorbar(im$ax, label = 'Density' $opts)";
		}
	}
}

sub colorbar_args {
	# The keyword arguments of a colorbar call that the cb* options and
	# "shared_colorbar" ask for, each led by ", ". "cblabel" is left to the
	# caller, since each helper has a default label of its own.
	#
	# hexbin, hist2d and imshow each wrote this out for themselves; scatter
	# and colored_table accepted the same options and wrote none of them.
	# Sets "colorbar_on" to its default, 1, as each of those did.
	my ($plot) = @_;
	my $opts = '';
	foreach my $o (grep {defined $plot->{$_}} ('cblocation', 'cborientation')) { # str
		my $mpl_opt = $o;
		$mpl_opt =~ s/^cb//;
		$opts .= ", $mpl_opt = " . py_str( $plot->{$o} );
	}
	foreach my $o (grep {defined $plot->{$_}} ('cbdrawedges', 'cbpad')) { # numeric
		die "$o = $plot->{$o} must be numeric" unless (looks_like_number($plot->{$o}));
		my $mpl_opt = $o;
		$mpl_opt =~ s/^cb//;
		$opts .= ", $mpl_opt = " . py_num( $plot->{$o} );
	}
	# Read as a Python bool: tested for Perl truth, "colorbar_on => 'False'"
	# drew the colorbar.
	$plot->{colorbar_on} = bool_option( $plot->{colorbar_on} // 1, 'colorbar_on', "plot_type \"" . ( $plot->{plot_type} // '' ) . '"' );
	if (($plot->{colorbar_on}) && (defined $plot->{shared_colorbar})) {
		my @ax = map {"ax$_"} @{ $plot->{shared_colorbar} };
		$opts .= ', ax = [' . join (',', @ax) . '] ';
	}
	return $opts;
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

sub hist_value {
	# A scalar "bins", "color" or "orientation" for hist(), as python.
	#
	# A number of bins is the one bare value; everything else is text. The
	# test this replaces quoted only /^[A-Za-z]+$/, so a color such as
	# "#ff0000" went in bare and python read the rest of the line as a comment,
	# and "tab:blue" or a grayscale "0.5" went in as python rather than as a
	# color.
	my ( $arg, $value ) = @_;
	return py_num($value) if ( $arg eq 'bins' ) && looks_like_number($value);    # py_num: "010" bins was a SyntaxError
	return py_str($value);
}
sub hist_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
		die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',   # used for multiple plots
		'fh',   # e.g. $py, $fh, which will be passed by the subroutine
		'plot', # args to original function
	);
	my @undef = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef > 0 ) {
		p @undef;
		die 'the above args are necessary, but were not defined.';
	}
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	@undef = grep {
		my $key = $_;
		not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef > 0 ) {
		bad_keyword_error({
			bad       => \@undef,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	my $options = '';    # these args go to the plt.hist call
	$plot->{alpha} = $plot->{alpha} // 0.5;
	check_numbers( [ $plot->{alpha} ], '"alpha"', $current_sub );    # written into every hist() call
	# Through py_num: "alpha => 'nan'" passes looks_like_number and was written
	# as given, a NameError in the script.
	my $alpha = py_num( $plot->{alpha} );
	# All the sets are drawn on one axes, so they share one orientation. A hash
	# was skipped as though it held a setting per set, and then never read.
	if ( ref $plot->{orientation} ) {
		die "\"orientation\" is one of \"vertical\" or \"horizontal\" for every set in $current_sub, not a " . ref( $plot->{orientation} ) . ' reference';
	}
	# "color" is here as well as below: a single color for every set was
	# accepted and then never written, since only the per-set hash was read.
	foreach my $arg ( grep { defined $plot->{$_} } ( 'bins', 'color', 'orientation' ) ) {
		next if ref $plot->{$arg} eq 'HASH';    # set-specific setting exists
		my $ref = ref $plot->{$arg};
		if ( $ref eq '' ) {
			$options .= ", $arg = " . hist_value( $arg, $plot->{$arg} );
		} elsif ( $arg eq 'color' ) {
			# hist() is called once per set, so there is no position in a list
			# of colors that means a set; the hash names them.
			die "\"color\" for $current_sub is one color for every set, or a hash of one color per set, not a $ref reference";
		} elsif ( $ref eq 'ARRAY' ) {
			$options .= ", $arg = [" . py_nums( @{ $plot->{$arg} } ) . ']';
		} else {
			p $plot;
			die "$ref for $arg isn't acceptable";
		}
	}
	foreach my $axis ( logscale_axes( $plot->{logscale}, $current_sub ) ) { # x, y
		say {$args->{fh}} "ax$args->{ax}.set_$axis" . 'scale("log")';
	}
	if (ref $plot->{data} eq 'ARRAY') {
		my $tmp = delete $plot->{data};
		$plot->{data}{A} = $tmp;
	}
	# A per-set "bins" or "color" keyed by a set that is not in "data" -- a
	# typo, most often -- was ignored, and that set drawn with the defaults.
	foreach my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) ) {
		my @stray = sort grep { not exists $plot->{data}{$_} } keys %{ $plot->{$arg} };
		next if scalar @stray == 0;
		p @stray;
		die "the above keys of \"$arg\" are not sets of \"data\" in $current_sub";
	}
	# The order the sets are drawn in, and so the order of the legend. Sorted
	# by name before, with no way to change it, so the groups that "df" makes
	# with "by" came out with 10 before 2, though the documentation promised
	# numeric order.
	my @key_order;
	if ( defined $plot->{key_order} ) {
		@key_order = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
	} else {
		@key_order = sort keys %{ $plot->{data} };
	}
	if (scalar keys %{ $plot->{data} } > 1) {
		$plot->{show_legend} = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
	} else {
		$plot->{show_legend} = bool_option( $plot->{show_legend} // 0, 'show_legend', $current_sub );
	}
	# Every bin height drawn into this subplot goes into hist_counts<ax>, for
	# the range that plt() reports once the subplot is drawn; see
	# hist_range_report. Named for the subplot because a figure's subplots all
	# write into the one script, in order, and each has to report its own range.
	foreach my $set (@key_order) {
		my @non_numeric = grep {not looks_like_number($_)} @{ $plot->{data}{$set} };
		if (scalar @non_numeric > 0) {
			p @non_numeric;
			die "$set has non-numeric values; which for hist must be numeric";
		}
		# NaN is left for matplotlib, which bins around it; an infinity leaves it
		# no finite range to bin, and died as "supplied range of [1.0, inf] is not
		# finite".
		my @infinite = grep { not ( is_nan($_) || is_finite($_) ) } @{ $plot->{data}{$set} };
		if (scalar @infinite > 0) {
			p @infinite;
			die "$set has the above infinite values, which $current_sub cannot bin";
		}
		my $set_options = '';
		foreach
		 my $arg ( grep { ref $plot->{$_} eq 'HASH' } ( 'bins', 'color' ) )
		{
			next unless defined $plot->{$arg}{$set};
			my $ref = ref $plot->{$arg}{$set};
			if ( ( $ref eq 'ARRAY' ) && ( $arg eq 'color' ) ) {
				die "\"color\" for set \"$set\" is an array, but $current_sub draws each set in one color";
			} elsif ( $ref eq 'ARRAY' ) {
				# Bin edges for this set alone. The whole-plot "bins" has taken
				# an array since it was written; per set it fell through to the
				# single-value branch below and emitted "bins = ARRAY(0x55f0...)".
				$set_options .= ", $arg = [" . py_nums( @{ $plot->{$arg}{$set} } ) . ']';
			} elsif ( $ref ne '' ) {
				p $plot->{$arg};
				die "\"$arg\" for set \"$set\" is a $ref reference, but $current_sub takes a scalar or an array there";
			} else {
				$set_options .= ", $arg = " . hist_value( $arg, $plot->{$arg}{$set} );
			}
		}
		say {$args->{fh}} 'd = [' . py_nums( @{ $plot->{data}{$set} } ) . ']';
		# hist() returns (counts, bin edges, patches); the counts are the only
		# way to know a bin's height, since matplotlib, not this module, does
		# the binning. Naming them changes nothing about what is drawn.
		if ($plot->{show_legend}) {
			say { $args->{fh} } "hist_n, hist_edges, hist_patches = ax$args->{ax}.hist(d, alpha = $alpha, label = " . py_str($set) . " $options $set_options)";
		} else {
			say { $args->{fh} } "hist_n, hist_edges, hist_patches = ax$args->{ax}.hist(d, alpha = $alpha $options $set_options)";
		}
		say {$args->{fh}} "hist_counts$args->{ax} += list(hist_n)";
	}
}
sub has_hist {
	# Whether a plot, or one of its "add" graphs, is a hist. An "add" graph
	# with no "plot_type" of its own takes $type, the plot's.
	my ( $plot, $type ) = @_;
	my @graphs = ( $plot, ( ref $plot->{add} eq 'ARRAY' ) ? @{ $plot->{add} } : () );
	return scalar grep { ( ref $_ eq 'HASH' ) && ( ( $_->{plot_type} // $type // '' ) eq 'hist' ) } @graphs;
}
sub hist_range_report {
	# Python that starts ($when = 'start') or reports ($when = 'report') the
	# range of the bin heights of every hist drawn into subplot $ax.
	#
	# plt() calls this around the whole subplot -- its "add" graphs and its own
	# plot -- rather than hist_helper around each hist, which reset the list for
	# each: a subplot with a hist overlay printed two ranges, the second
	# leaving out the overlay's bins, where one range over all its sets is
	# what the documentation promises.
	#
	# On STDOUT and nowhere else: nothing here is handed to matplotlib, so the
	# figure written to "output_file" is exactly what it was without this.
	# plt() prints the script's STDOUT back out.
	my ( $fh, $ax, $when ) = @_;
	if ( $when eq 'start' ) {
		say {$fh} "hist_counts$ax = []";
		return;
	}
	# "%g" because hist() hands back its counts as float64, and "[1, 12]" for a
	# tally of whole things is what was counted; "[1.0, 12.0]" reads as though
	# it were not.
	# An empty subplot has no bins at all, and min() of an empty list raises
	# ValueError, so there is nothing to report.
	say {$fh} "if len(hist_counts$ax) > 0:";
	say {$fh} "\tprint(f'plot $ax hist range = [{min(hist_counts$ax):g}, {max(hist_counts$ax):g}]')";
}

sub hist2d_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
		bad_keyword_error({
			bad       => \@undef_args,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	cb_limits( $plot, $current_sub );
	$plot->{cb_logscale}     = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	$plot->{show_colorbar} = bool_option( $plot->{show_colorbar} // 1, 'show_colorbar', $current_sub );
	bin_counts( $plot, $current_sub );
	my @keys;
	if ( defined $plot->{key_order} ) {
		@keys = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
	} else {
		@keys = sort keys %{ $plot->{data} };
	}
	if ( scalar @keys != 2 ) {
	  p @keys;
	  die "There must be exactly 2 keys for $current_sub";
	}
	my $n_points = scalar @{ $plot->{data}{ $keys[0] } };
	if ( scalar @{ $plot->{data}{ $keys[1] } } != $n_points ) {
	  say STDERR "$keys[0] has $n_points points.";
	  say STDERR "$keys[1] has "
		 . scalar @{ $plot->{data}{ $keys[1] } }
		 . " points.";
	  die 'The length of both keys must be equal.';
	}
	# quoted here because the key is data: the pass-through path that title and
	# label text otherwise take cannot tell an apostrophe from Python of the
	# user's own, and leaves it bare. See py_str.
	default_axis_labels( $plot, @keys );
	$plot->{cmap}   = $plot->{cmap}   // 'gist_rainbow';
	my $options = ', cmap = ' . py_str($plot->{cmap}); # these args go to the plt.hist call
	if ( $plot->{cb_logscale} ) {
		say {$args->{fh}} 'from matplotlib.colors import LogNorm';
		# prevents "ValueError: Passing a Normalize instance simultaneously with vmin/vmax is not supported.  Please pass vmin/vmax directly to the norm when creating it"
		my @logNorm_opt;
		foreach my $arg (grep {defined $plot->{$_}} ('vmin', 'vmax')) {
			if (not looks_like_number($plot->{$arg})) {
				die "$arg must be numeric for $current_sub, but was given \"$plot->{$arg}\"";
			}
			if ( ( $arg eq 'vmin' ) && ( $plot->{$arg} <= 0 ) ) {    # as in hexbin_helper
				die "\"cb_logscale\" cannot start at \"vmin\" = $plot->{$arg} in $current_sub: a log scale needs a minimum above 0";
			}
			push @logNorm_opt, "$arg = " . py_num( $plot->{$arg} );    # py_num: "vmax => 'inf'" was a NameError
			delete $plot->{$arg}; 
		}
		$options .= ', norm = LogNorm(' . join (',', @logNorm_opt) . ')';
	}
	# Checked here as the log-scale branch above checks its own: each was
	# written as given, so "vmin => 'low'" left "vmin = low" in the script.
	foreach my $opt ( grep { defined $plot->{$_} } ( 'cmin', 'cmax', 'vmin', 'vmax' ) ) {
		check_numbers( [ $plot->{$opt} ], "\"$opt\"", $current_sub );
		$options .= ", $opt = " . py_num( $plot->{$opt} );
	}
	if ( defined $plot->{density} ) {
		$options .= ', density = ' . ( bool_option( $plot->{density}, 'density', $current_sub ) ? 'True' : 'False' );
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
	. py_nums( @{ $plot->{data}{ $keys[0] } } ) . ']';
	say { $args->{fh} } 'y = ['
	. py_nums( @{ $plot->{data}{ $keys[1] } } ) . ']';
	# The ends of the range binned over, each the caller's or the data's own.
	# Nothing here was checked, and each was written as given: "xmin => 'a'"
	# was a NameError, a column with no finite value left an undefined end that
	# died as "Use of uninitialized value in concatenation", and a log axis
	# that reached 0 died inside np.log10 as "invalid entry in coordinates
	# array".
	my %log_axis = map { $_ => 1 } logscale_axes( $plot->{logscale}, $current_sub );
	foreach my $i ( 0, 1 ) {
		my $axis   = ( 'x', 'y' )[$i];
		my @finite = finite_values( @{ $plot->{data}{ $keys[$i] } } );
		foreach my $end ( 'min', 'max' ) {
			my $opt = "$axis$end";
			if ( defined $plot->{$opt} ) {
				check_numbers( [ $plot->{$opt} ], "\"$opt\"", $current_sub );
				die "\"$opt\" must be a finite number for $current_sub, not \"$plot->{$opt}\"" unless is_finite( $plot->{$opt} );
			} elsif ( scalar @finite == 0 ) {
				die "\"$keys[$i]\" has no finite value, so $current_sub has no range to bin it over; give \"${axis}min\" and \"${axis}max\"";
			} else {
				$plot->{$opt} = ( $end eq 'min' ) ? min(@finite) : max(@finite);
			}
		}
		my ( $lo, $hi ) = @{$plot}{ "${axis}min", "${axis}max" };
		if ( $lo > $hi ) {
			die "\"${axis}min\" = $lo is above \"${axis}max\" = $hi in $current_sub";
		}
		if ( ( $log_axis{$axis} ) && ( $lo <= 0 ) ) {
			die "\"logscale\" puts $axis on a log scale, which cannot start at $lo in $current_sub: give a \"${axis}min\" above 0";
		}
	}
	my %end = map { $_ => py_num( $plot->{$_} ) } ( 'xmin', 'xmax', 'ymin', 'ymax' );
	my $ax = $args->{ax} // '';
	# the range argument ensures that there are no empty parts of the plot
	my $range =	", range = [($end{xmin}, $end{xmax}), ($end{ymin}, $end{ymax})]";
	# logscale complications
	say {$args->{fh}} 'import numpy as np';
	# Bin edges, one more than the bins: "xbins" and "ybins" count bins, as
	# they do on a linear plot, where they go to hist2d as counts. They were
	# written as the number of edges, so a log axis had one bin fewer than it
	# asked for, and "xbins => 1" gave one edge, no bins at all, and died in
	# np.max as "zero-size array". The test is on the axes, not on "logscale"
	# itself, which as an empty array was true and took this branch for none.
	if ( scalar keys %log_axis ) {
		foreach my $axis ( 'x', 'y' ) {
			my $min   = $end{ $axis . 'min' };
			my $max   = $end{ $axis . 'max' };
			my $edges = $plot->{"${axis}bins"} + 1;
			if ( $log_axis{$axis} ) {
				say {$args->{fh}} "ax$ax.set_$axis" . 'scale("log")';
				say {$args->{fh}} "${axis}bins = np.logspace(np.log10($min), np.log10($max), $edges)";
			} else {
				say {$args->{fh}} "${axis}bins = np.linspace($min, $max, $edges)";
			}
		}
		$options = ", bins = [xbins, ybins] $options";
	} else {
		$options = ", ($plot->{xbins}, $plot->{ybins}) $options";
	}
	say {$args->{fh}}	"hist2d_n, hist2d_xedges, hist2d_yedges, im$ax = ax$ax.hist2d(x, y $options $range)";
	say {$args->{fh}} 'max_hist2d_box = np.max(hist2d_n)';
	say {$args->{fh}} 'min_hist2d_box = np.min(hist2d_n)';
	say {$args->{fh}} "print(f'plot $ax hist2d density range = [{min_hist2d_box}, {max_hist2d_box}]')";
	return 0 if $plot->{show_colorbar} == 0;
	my $opts = colorbar_args($plot);    # cblabel is written below
#	say { $args->{fh} } "cbar = fig.colorbar(im$ax $opts)" if $plot->{colorbar_on};
	# As in hexbin_helper: "colorbar_on" used to be read only for the shared
	# colorbar, so "colorbar_on => 0" drew one anyway and the documentation
	# had to tell the reader to use "show_colorbar" instead. Both now work, and
	# a subplot whose colorbar plt() turns off for sharing stays off.
	if ( $plot->{colorbar_on} ) {
		if ( defined $plot->{cblabel} ) {
		  say { $args->{fh} } "plt.colorbar(im$ax, label = " . py_str($plot->{cblabel}) . " $opts)";
		} else {
		  say { $args->{fh} } "plt.colorbar(im$ax, label = 'Density' $opts)";
		}
	}
}

sub imshow_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
		bad_keyword_error({
			bad       => \@undef_args,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	cb_limits( $plot, $current_sub );
	my $data_ref = ref $plot->{data};
	if ($data_ref ne 'ARRAY') {
		p $args;
		die "$current_sub can only accept 2-D arrays as input in \"data\", but received $data_ref";
	}
	# An empty image is refused here, by name: it has nothing to draw, and it
	# used to reach Python as "vmin = inf", a NameError about nothing in the
	# data.
	my @bad_rows = grep { ref $plot->{data}[$_] ne 'ARRAY' } 0 .. $#{ $plot->{data} };
	if (scalar @bad_rows > 0) {
		p @bad_rows;
		die "the above rows of \"data\" are not array references, which $current_sub needs";
	}
	if ((scalar @{ $plot->{data} } == 0) || (scalar grep { scalar @{$_} > 0 } @{ $plot->{data} }) == 0) {
		die "$current_sub was given no data to draw";
	}
	# Every row the same length: numpy refused a ragged image from inside
	# matplotlib, as "setting an array element with a sequence ... inhomogeneous
	# shape", which named no row.
	my %row_lengths;
	$row_lengths{ scalar @{$_} } = 1 foreach @{ $plot->{data} };
	if ( scalar keys %row_lengths > 1 ) {
		die "the rows of \"data\" have different lengths ("
		 . join( ', ', map { scalar @{ $plot->{data}[$_] } } 0 .. $#{ $plot->{data} } )
		 . "), but $current_sub draws a rectangle of cells";
	}
	# An undefined cell, refused by name. It was counted as a string, and
	# without a "stringmap" the image died as needing "a map to translate
	# strings to integers", for numeric data that held no strings.
	my @undef_cells;
	foreach my $r ( 0 .. $#{ $plot->{data} } ) {
		push @undef_cells, map { "[$r][$_]" } grep { not defined $plot->{data}[$r][$_] } 0 .. $#{ $plot->{data}[$r] };
	}
	if ( scalar @undef_cells > 0 ) {
		splice @undef_cells, 5, scalar(@undef_cells) - 5, '...' if scalar @undef_cells > 5;    # enough to find them by
		die "$current_sub cannot draw an undefined cell, and \"data\" has them at " . join( ', ', @undef_cells ) . '; a NaN is drawn as an empty cell';
	}
	my $non_numeric_data = 0;
	foreach my $row (@{ $plot->{data} }) {
		if (grep {not looks_like_number($_)} @{ $row }) {
			$non_numeric_data = 1;
			last;
		}
	}
	$plot->{cb_logscale} = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	if (($non_numeric_data) && (not defined $plot->{stringmap})) {
		p $args;
		die "$current_sub needs a map to translate strings to integers";
	}
	# Each key of stringmap gets an integer, in sorted order. The integers come
	# from a range, not from "scalar @ytick_labels" as they were: perl returns
	# the count of an empty array as a shared 0 that also carries the string
	# "0", the first category's 0 was copied from it, and JSON::XS -- which
	# JSON::MaybeXS uses when it has no Cpanel::JSON::XS -- wrote it as "0".
	# One string among the integers made numpy read the whole image as text,
	# and imshow died as "Image data of dtype <U21 cannot be converted to
	# float".
	my @strings = sort keys %{ $plot->{stringmap} };
	my %intmap = map { $strings[$_] => $_ } 0 .. $#strings;
	my @ytick_labels = @{ $plot->{stringmap} }{@strings};
	# The rows drawn: the caller's own, or for string data a translated copy.
	# The strings used to be replaced in place, so the caller's array came back
	# holding integers; and a string that "stringmap" did not name became an
	# undefined cell, drawn blank with nothing said.
	my $data = $plot->{data};
	if ($non_numeric_data) {
		my %unmapped;
		foreach my $row (@{ $data }) {
			$unmapped{ $_ // 'undef' }++ foreach grep { ( not defined $_ ) || ( not defined $intmap{$_} ) } @{ $row };
		}
		if (scalar keys %unmapped > 0) {
			my @unmapped = sort keys %unmapped;
			p @unmapped;
			die "the above values of \"data\" are not keys of \"stringmap\", which $current_sub needs to give each one a color";
		}
		$data = [ map { [ map { $intmap{$_} } @{ $_ } ] } @{ $data } ];
	} else {
		# Numbers as numbers. write_data sends "d" through JSON, which writes a
		# scalar last used as a string -- a row split from a line of a file -- as
		# a JSON string, and numpy refused such rows as "Image data of dtype <U1
		# cannot be converted to float". A copy, since the rows are the caller's.
		# JSON has no NaN or infinity, and the encoder writes both as null, which
		# numpy refused as "Image data of dtype object"; they travel as the
		# strings "nan", "inf" and "-inf" instead, which the float conversion
		# written after the data below reads back as the numbers they were.
		$data = [ map { [ map { nonfinite_name($_) // 0 + $_ } @{ $_ } ] } @{ $data } ];
	}
	my ( $min_val, $max_val );    # the ends of a stringmap's scale; numbers are left to norm_args
	my $opts = '';
	if ($non_numeric_data) {
		my @prop_cycle = ('#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2',
 '#7f7f7f', '#bcbd22', '#17becf'); #plt.rcParams['axes.prop_cycle']
		my $n_strings = scalar keys %intmap;
		if ( $n_strings > scalar @prop_cycle ) {
			# More categories than the default property cycle has colors. The
			# slice used to run off the end of @prop_cycle and die inside
			# join() as "Use of uninitialized value", naming neither
			# "stringmap" nor the number of categories, so an 11th category
			# was an unexplained crash. A continuous colormap resampled to the
			# number of categories gives that many distinct colors for any
			# number of them.
			say { $args->{fh} } 'import matplotlib';
			say { $args->{fh} } "this_cmap = matplotlib.colormaps['gist_rainbow'].resampled($n_strings)";
		} else {
			say { $args->{fh} } 'from matplotlib.colors import ListedColormap';
			say { $args->{fh} } 'colors = [' . py_list( @prop_cycle[ 0 .. $n_strings - 1 ] ) . ']';
			say { $args->{fh} } 'this_cmap = ListedColormap(colors)';
		}
		warn "deleting \"$plot->{cmap}\" because string data is present" if defined $plot->{cmap};
		delete $plot->{cmap};
		$min_val = 0;
		$max_val = max(values %intmap);
		$opts .= ', cmap = this_cmap';
	}
	write_data({
		data => $data,
		fh   => $args->{fh},
		name => 'd',
	});
	# Only where a value needs it, so that an image of whole numbers is still
	# drawn from whole numbers.
	if ( ( not $non_numeric_data ) && ( grep { grep { m/^-?(?:nan|inf)$/ } @{$_} } @{$data} ) ) {
		say { $args->{fh} } 'import numpy as np';
		say { $args->{fh} } 'd = np.asarray(d, dtype = float)';
	}
	my $ax = $args->{ax} // '';
	foreach my $opt (grep {defined $plot->{$_}} ('cmap')) { # strings
		$opts .= ", $opt = " . py_str( $plot->{$opt} );
	}
	# Categories have no scale to put on a log axis.
	if ( $non_numeric_data && $plot->{cb_logscale} ) {
		die "\"cb_logscale\" means nothing for $current_sub with a \"stringmap\": its colors are categories, not a scale";
	}
	# vmin and vmax were written as given, so a word was a bare Python name,
	# and "cb_logscale" was accepted and never read. An image with no finite
	# value leaves the ends to matplotlib; they came out as "vmin = inf".
	foreach my $v ( grep { defined $plot->{$_} } ( 'vmin', 'vmax' ) ) {
		check_numbers( [ $plot->{$v} ], "\"$v\"", $current_sub );
	}
	$opts .= norm_args({
		lo     => $plot->{vmin} // ( $non_numeric_data ? $min_val : undef ),
		hi     => $plot->{vmax} // ( $non_numeric_data ? $max_val : undef ),
		values => $non_numeric_data ? [] : [ map { @{$_} } @{$data} ],
		log    => $plot->{cb_logscale},
		fh     => $args->{fh},
		sub    => $current_sub
	});
	say { $args->{fh} } "im$ax = ax$ax.imshow(d, aspect = 'auto' $opts)";
	$opts = '';
	if ($non_numeric_data) {
		# One tick per category, at the middle of its band of the colorbar.
		# The colormap has one color per category and spans [0, $max_val], so
		# category i covers [i/n, (i+1)/n] of that span and its middle sits at
		# $max_val * (2i+1) / 2n. The formula here was "$_ + 0.5 - $_/$max_val",
		# which divided by zero when there was a single category and put both
		# ticks in the same place when there were two.
		my $n_strings = $max_val + 1;
		$opts .= ', ticks = ['
		 . join( ',', map { $max_val * ( 2 * $_ + 1 ) / ( 2 * $n_strings ) } 0 .. $max_val ) . ']';
	}
	# py_str, not "'$value'": a cblabel is prose, and "Farmer's yield" closed
	# the literal early and left the script unparseable.
	$opts .= ', label = ' . py_str( $plot->{cblabel} ) if defined $plot->{cblabel};
	$opts .= colorbar_args($plot);
	say { $args->{fh} } "cbar = fig.colorbar(im$ax $opts)" if $plot->{colorbar_on};
	if (($non_numeric_data) && ($plot->{colorbar_on})) {
		# The colorbar's own set_ticklabels, which labels whichever axis its
		# ticks are on. cbar.ax.set_yticklabels was written whatever the
		# orientation, and a horizontal colorbar, whose ticks are on x, died as
		# "The number of FixedLocator locations (0) ... does not match the number
		# of labels".
		say { $args->{fh} } 'cbar.set_ticklabels([' . py_list(@ytick_labels) . '])';
	}
}

sub pie_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
	  die
	"args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'ax',
	  'fh',   # e.g. $py, $fh, which will be passed by the subroutine
	  'plot', # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		bad_keyword_error({
			bad       => \@undef_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	my @key_order;
	if ( defined $plot->{key_order} ) {
	  @key_order = check_key_order({
	  	keys   => $plot->{key_order},
	  	data   => $plot->{data},
	  	option => 'key_order',
	  	sub    => $current_sub
	  });
	} else {
	  @key_order = sort keys %{ $plot->{data} };
	}
	# As in barplot_helper: a wedge size is written into the script as it
	# stands, so a non-numeric one becomes a bare Python name and the script
	# dies as a NameError with nothing to say about the data.
	foreach my $key (@key_order) {
		if ( not looks_like_number( $plot->{data}{$key} ) ) {
			p $plot->{data};
			die "\"$key\" is not a number, which $current_sub needs to size a wedge";
		}
		# matplotlib refuses these as "Wedge sizes must be finite numbers"
		die "\"$key\" is not a finite number, which $current_sub needs to size a wedge" unless is_finite( $plot->{data}{$key} );
		# and these as "Wedge sizes 'x' must be non negative values"
		die "\"$key\" is $plot->{data}{$key}, but $current_sub cannot size a wedge below 0" if $plot->{data}{$key} < 0;
	}
	# and nothing at all, which matplotlib divides by: "x must have a positive sum"
	if ( not grep { $plot->{data}{$_} > 0 } @key_order ) {
		die "every wedge of $current_sub is 0, so there is no pie to divide between them";
	}
	$plot->{autopct} = $plot->{autopct} // '';
	my $opt = '';
	if ( $plot->{autopct} ne '' ) {
	$opt .= ", autopct = " . py_str( $plot->{autopct} );
	}
	foreach my $arg ( grep { defined $plot->{$_} } 'labeldistance', 'pctdistance' ) {
	  check_numbers( [ $plot->{$arg} ], "\"$arg\"", $current_sub );    # written bare, so a word was a NameError
	  $opt .= ", $arg = " . py_num( $plot->{$arg} );
	}
	write_data({
		data => \@key_order,
		fh   => $args->{fh},
		name => 'labels',
	});
	say { $args->{fh} } 'vals = ['
	. py_nums( @{ $plot->{data} }{@key_order} ) . ']';
	my $ax = $args->{ax} // '';
	say { $args->{fh} } "ax$ax.pie(vals, labels = labels $opt)";
}

sub plot_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',	'fh',# e.g. $py, $fh, which will be passed by the subroutine
		'plot',    # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (@ax_methods, @fig_methods, @arg, @plt_methods, 'ax', @{ $opt{$current_sub} });
	my $plot = $args->{plot};
	my @bad_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @bad_opt > 0 ) {
		bad_keyword_error({
			bad       => \@bad_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	$plot->{show_legend} = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
	foreach my $axis ( logscale_axes( $plot->{logscale}, $current_sub ) ) { # x, y
		say {$args->{fh}} "ax$args->{ax}.set_$axis" . 'scale("log")';
	}
	my @twinx;
	# The one twin of these axes, made the first time a line asks for it and
	# shared by every twinned line after, including those of an "add" graph on
	# the same axes. Each twinned line used to get a twin of its own, so two of
	# them had two right-hand axes, each with its own limits, their ticks drawn
	# over one another on the same spine.
	my $twin = sub {
		my $ax = "ax$args->{ax}";
		if ( not defined $twin_axes{$ax} ) {
			$twin_axes{$ax} = "twinx_$ax";
			say { $args->{fh} } "$twin_axes{$ax} = $ax.twinx() # " . __LINE__;
		}
		return $twin_axes{$ax};
	};
	# Allow a single line entered as two bare array refs, with no enclosing
	# pair-array and no hash key:
	#     data => [ \@x, \@y ]
	# Promote it to the canonical array-of-pairs form so the array path below
	# handles it unchanged:
	#     data => [ [ \@x, \@y ] ]
	# The discriminator vs. the multi-line form (data => [ [\@x,\@y], ... ]) is
	# data->[0][0]: a number here, an ARRAY ref in the multi-line form.
	if (   ( ref $plot->{data} eq 'ARRAY' )
		&& ( scalar @{ $plot->{data} } == 2 )
		&& ( ref $plot->{data}[0] eq 'ARRAY' )
		&& ( ref $plot->{data}[1] eq 'ARRAY' )
		&& ( ref $plot->{data}[0][0] ne 'ARRAY' ) )
	{
		$plot->{data} = [ $plot->{data} ];
	}
	if (ref $plot->{data} eq 'ARRAY') {
		if (defined $plot->{set_options}) {
			my $ref_type = ref $plot->{set_options};
			# a scalar applies to every line (handy for the single-line form);
			# an array gives one option string per line (positional)
			if ($ref_type eq 'ARRAY') {
				my $n_set_opt = scalar @{ $plot->{set_options} };
				my $n_data = scalar @{ $plot->{data} };
				if ($n_set_opt > $n_data) {
					p $args;
					die "there are $n_set_opt sets for options, but only $n_data data points.";
				}
			} elsif ($ref_type ne '') {
				p $args;
				die "\"set_options\" must be a scalar (applied to every line) or an array (one per line) when data is an array, but \"$ref_type\" was given.";
			}
		}
		if (defined $plot->{twinx}) {
			my $twinx_ref = ref $plot->{twinx};
			if ($twinx_ref eq '') {
				die "twinx must be an array index, not \"$plot->{twinx}\"" unless $plot->{twinx} =~ m/^\d+$/;
				@twinx = $plot->{twinx};
			} elsif ($twinx_ref eq 'ARRAY') {
				@bad_opt = grep {$_ !~ m/^\d+$/} @{ $plot->{twinx} };
				if (scalar @bad_opt > 0) {
					p @bad_opt;
					die 'data that could not possibly be an array index for twinx is shown above';
				}
				@twinx = @{ $plot->{twinx} };
			} else {
				# Any other reference fell off the end of this chain and was
				# ignored without a word, so a twinx given in the hash form
				# ("twinx => { B => 1 }") against array data simply did not
				# draw a second axis.
				die "$current_sub: \"data\" is an array, so \"twinx\" is an index or an array of indices into it, not a $twinx_ref reference";
			}
		}
		if (defined $plot->{twinx_args}) {
			my $ref = ref $plot->{twinx_args};
			die "\"twinx_args\" must be a hash, but $ref was entered" unless $ref eq 'HASH';
			check_twinx_args( $plot->{twinx_args}, $current_sub );
			@bad_opt = grep {$_ !~ m/^\d+$/} keys %{ $plot->{twinx_args} };
			if (scalar @bad_opt > 0) {
				p @bad_opt;
				die 'the above keys are not hash indices';
			}
			foreach my $idx (keys %{ $plot->{twinx_args} }) {
				next if grep {$idx == $_} @twinx;
				push @twinx, $idx;
			}
		}
		# An index past the last line was ignored without a word, where the
		# hash form refuses a key that is not in "data".
		my $n_lines = scalar @{ $plot->{data} };
		my @past_end = sort { $a <=> $b } grep { $_ >= $n_lines } @twinx;
		if ( scalar @past_end > 0 ) {
			die "$current_sub: \"twinx\" or \"twinx_args\" names line " . join( ', ', @past_end ) . ", but \"data\" has $n_lines line" . ( $n_lines == 1 ? '' : 's' ) . ', indexed from 0';
		}
		my $arr_i = 0;
		foreach my $arr (@{ $plot->{data} }) {
			my $ref = ref $arr;
			if ($ref ne 'ARRAY') {
				p $plot->{data}[$arr_i];
				die "index $arr_i is \"$ref\" but must be \"ARRAY\"";
			}
			my $n_elem = scalar @{ $arr };
			if ($n_elem != 2) {
				p $arr;
				die "there must be 2 array references (x, y) but index $arr_i has $n_elem";
			}
			@bad_opt = map { scalar @{ $arr->[$_] } } (0,1);
			if ($bad_opt[0] != $bad_opt[1]) {
				say STDERR "index $arr_i must have arrays/array refs of equal length, but these lengths were given:";
				p @bad_opt;
				die 'the array/array ref lengths must be equal';
			}
			foreach my $i (0,1) {
				my $max_i = scalar @{ $arr->[$i] } - 1;
				@bad_opt = grep {not looks_like_number($arr->[$i][$_])} 0..$max_i;
				next if scalar @bad_opt == 0; # it's fine, don't worry
				p $plot->{data}[$arr_i];
				p @bad_opt;
				@bad_opt = @{ $arr->[$i] }[@bad_opt];
				say STDERR 'have these non-numeric values:';
				p @bad_opt;
				die "Array index $arr_i/axis $i has non-numeric values (above)";
			}
			my $options = '';
			say { $args->{fh} } 'x = [' . py_nums( @{ $arr->[0] } ) . ']';
			say { $args->{fh} } 'y = [' . py_nums( @{ $arr->[1] } ) . ']';
			if ( defined $plot->{set_options} ) {
				my $so_ref = ref $plot->{set_options};
				if ( $so_ref eq '' ) {    # scalar: same options for every line
					$options = ", $plot->{set_options}";
				} elsif (   ( $so_ref eq 'ARRAY' )
						&& ( defined $plot->{set_options}[$arr_i] ) ) {
					$options = ", $plot->{set_options}[$arr_i]";    # one per line
				}
			}
			my $ax = "ax$args->{ax}";
			if (grep {$arr_i == $_} @twinx) {
				my $twin_ax = $twin->();
				say { $args->{fh} } "$twin_ax.plot(x, y $options) # " . __LINE__;
				if (defined $plot->{twinx_args}{$arr_i}) {
					plot_args({
						fh        => $args->{fh},
						args      => $plot->{twinx_args}{$arr_i},
						ax        => $twin_ax,
						no_legend => 1    # its lines go in the legend of $ax
					});
				}
			} else {
				say { $args->{fh} } "ax$args->{ax}.plot(x, y $options) # " . __LINE__;
			}
			$arr_i++;
		}
		return 1; # the rest only applies if $plot->{data} is a hash
	}
	my @key_order;
	if ( defined $plot->{key_order} ) {
		@key_order = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
	} else {
		@key_order = sort keys %{ $plot->{data} };
	}
	if ((defined $plot->{set_options}) && (ref $plot->{set_options} eq 'HASH')) {
		@bad_opt = sort grep {!defined $plot->{data}{$_}} keys %{ $plot->{set_options} };
		if (scalar @bad_opt > 0) {
			p @bad_opt;
			die "the above options are defined for undefined data sets in $current_sub.";
		}
	}
	if (defined $plot->{twinx}) {
		my $twinx_ref = ref $plot->{twinx};
		if ($twinx_ref eq '') {
			die "twinx \"$plot->{twinx}\" is not a key in data" unless defined $plot->{data}{ $plot->{twinx} };
			@twinx = ($plot->{twinx});
		} elsif ($twinx_ref eq 'HASH') {
			@bad_opt = sort grep {!defined $plot->{data}{$_}} keys %{ $plot->{twinx} };
			if (scalar @bad_opt > 0) {
				p @bad_opt;
				die 'data for undefined data keys is shown above';
			}
			@twinx = sort keys %{ $plot->{twinx} };
		} else {
			# As in the array branch above: anything else was ignored in
			# silence, so "twinx => ['B']" against a hash of sets drew nothing
			# and said nothing.
			die "$current_sub: \"data\" is a hash, so \"twinx\" is a data key or a hash of them, not a $twinx_ref reference";
		}
	}
	if (defined $plot->{twinx_args}) {
		my $ref = ref $plot->{twinx_args};
		die "\"twinx_args\" must be a hash, but $ref was entered" unless $ref eq 'HASH';
		check_twinx_args( $plot->{twinx_args}, $current_sub );
		@bad_opt = sort grep {!defined $plot->{data}{$_}} keys %{ $plot->{twinx_args} };
		if (scalar @bad_opt > 0) {
			p @bad_opt;
			die 'the above keys are not present in data keys';
		}
		foreach my $set (keys %{ $plot->{twinx_args} }) {
			next if grep {$set eq $_} @twinx;
			push @twinx, $set;
		}
	}
	foreach my $set (@key_order) {
		my $set_ref = ref $plot->{data}{$set};
		if ( $set_ref ne 'ARRAY' ) {
			p $plot->{data}{$set};
			die "$set must have two arrays, x and y coordinates, or one array of y values, but instead has a $set_ref";
		}
		# A set of plain values, with no array among them, is y alone, and is
		# drawn against 0 .. n-1. The pair is built here rather than written
		# back, so the caller's data is left as it was given.
		my $xy = $plot->{data}{$set};
		my $n_refs = grep { ref } @{$xy};
		if ( ( $n_refs == 0 ) && ( scalar @{$xy} > 0 ) ) {
			$xy = [ [ 0 .. $#{$xy} ], $xy ];
		} elsif ( $n_refs < scalar @{$xy} ) {
			p $xy;
			die "$current_sub: set \"$set\" mixes arrays with plain values: it must be [ \\\@x, \\\@y ] or one array of y values";
		}
		my $n_arrays = scalar @{ $xy };
		if ( $n_arrays != 2 ) {
			p $xy;
			die "$n_arrays were entered for $set, but there must be exactly 2";
		}
		my @n_elem = map { scalar @{ $xy->[$_] }} (0,1);
		if ( $n_elem[0] != $n_elem[1] ) {
			p $xy;
			p @n_elem;
			die "$set has length = $n_elem[0] for x; length = $n_elem[1] for y: x & y must be of equal length";
		}
		foreach my $ax (0,1) {
			my $n = scalar @{ $xy->[$ax] };
			my @undef_i = grep {not defined $xy->[$ax][$_]} 0..$n-1;
			if (scalar @undef_i > 0) {
				p $plot;
				p @undef_i;
				my $max_i = scalar @{ $xy->[$ax] };
				die "set $set axis $ax has undefined indices, of max index $max_i in $current_sub";
			}
			# The array form of "data" has always refused these; the hash form
			# wrote them into the script, where 'a' became "y = [a,3]" and died
			# as a NameError.
			my @non_numeric = grep { not looks_like_number( $xy->[$ax][$_] ) } 0 .. $n - 1;
			if ( scalar @non_numeric > 0 ) {
				my @values = @{ $xy->[$ax] }[@non_numeric];
				p @values;
				die "set \"$set\" axis $ax has the above non-numeric values, which $current_sub cannot plot";
			}
		}
		my $options = '';
		say { $args->{fh} } 'x = [' . py_nums( @{ $xy->[0] } ) . ']';
		say { $args->{fh} } 'y = [' . py_nums( @{ $xy->[1] } ) . ']';
		if (   ( defined $plot->{set_options} )
			&& ( ref $plot->{set_options} eq '' ) )
		{
			$options = ", $plot->{set_options}";
		}
		if ( ( ref $plot->{set_options} eq 'HASH' ) && ( defined $plot->{set_options}{$set} ) ) {
			$options = ", $plot->{set_options}{$set}";
		}
		my $label = '';
		if ( $plot->{show_legend} ) {
			$label = ',label = ' . py_str($set);
		}
		my $ax = "ax$args->{ax}";
		if (grep {$set eq $_} @twinx) { # this set has
			my $twin_ax = $twin->();
			say { $args->{fh} } "$twin_ax.plot(x, y $label $options) # " . __LINE__;
			if (defined $plot->{twinx_args}{$set}) {
				plot_args({
					fh        => $args->{fh},
					args      => $plot->{twinx_args}{$set},
					ax        => $twin_ax,
					no_legend => 1    # its lines go in the legend of $ax
				});
			}
		} else {
			say { $args->{fh} } "ax$args->{ax}.plot(x, y $label $options) # " . __LINE__;
		}
	}
	return 1;
}

sub scatter_tooltips {
	# Check one set's "tooltips" against its number of points, and return the
	# url of each point, which ties a labelled point to its text -- or undef
	# when there is nothing to draw.
	#
	# A url per point, rather than counting the markers in the SVG afterwards:
	# matplotlib writes each point's url as a link around that point's marker,
	# and leaves out the url of a point it does not draw -- NaN, or not above
	# 0 on a log axis -- so each label stays with its own point. An undefined
	# label is a point without a tooltip, and gets no url.
	my ( $labels, $n_points, $options, $where, $current_sub ) = @_;
	return undef unless defined $labels;    # no tooltips for this set
	if ( ref $labels ne 'ARRAY' ) {
		die "$current_sub: \"tooltips\"$where must be an array of one label per point, not "
		 . ( ref $labels ? 'a ' . ( ref $labels ) . ' reference' : "\"$labels\"" );
	}
	if ( scalar @{$labels} != $n_points ) {
		die "$current_sub: \"tooltips\"$where has " . scalar @{$labels} . " labels, but there are $n_points points: give one per point, and undef for a point that has none";
	}
	my @refs = grep { ref $labels->[$_] } 0 .. $#{$labels};
	if ( scalar @refs > 0 ) {
		die "$current_sub: \"tooltips\"$where holds text, but index " . join( ', ', @refs ) . ( scalar @refs == 1 ? ' is a reference' : ' are references' );
	}
	my @labelled = grep { defined $labels->[$_] } 0 .. $#{$labels};
	return undef if scalar @labelled == 0;
	if ( $options =~ m/\burls?\s*=/ ) {
		die "$current_sub: \"tooltips\"$where are drawn through the points' urls, so they cannot be given with a \"url\" or \"urls\" in \"set_options\"";
	}
	my @urls = (undef) x $n_points;
	foreach my $i (@labelled) {
		$urls[$i] = $tooltip_url . scalar @tooltip_text;
		push @tooltip_text, "$labels->[$i]";    # as text: ElementTree cannot write a python int as a <title>, and a number may be a dualvar to JSON::XS (see CLAUDE.md)
	}
	# Checked and counted either way, so that plt can say they were left out;
	# a url in a PNG or PDF is a link to nowhere.
	return undef unless $tooltips_drawn;
	return \@urls;
}
sub write_tooltip_urls {
	# Write one set's urls from scatter_tooltips, and return the argument that
	# hands them to ax.scatter; '' for a set with none.
	my ( $urls, $fh ) = @_;
	return '' unless defined $urls;
	write_data({
		data => $urls,
		fh   => $fh,
		name => 'tooltip_urls'
	});
	return ', urls = tooltip_urls';
}
sub scatter_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
	  'ax',  'fh', # e.g. $py, $fh, which will be passed by the subroutine
	  'plot',      # args to original function
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
	  p @undef_args;
	  die 'the above args are necessary, but were not defined.';
	}
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	@undef_args = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_args > 0 ) {
		bad_keyword_error({
			bad       => \@undef_args,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	foreach my $cb ( grep { defined $plot->{$_} } ( 'cb_min', 'cb_max' ) ) {
		check_numbers( [ $plot->{$cb} ], "\"$cb\"", $current_sub );
	}
	cb_limits( $plot, $current_sub );    # scatter has no vmin or vmax of its own, so cb_min and cb_max are its only way to set them
	my $overall_ref = ref $plot->{data};
	if ( $overall_ref ne 'HASH' ) {
		die
	"scatter only takes 1) hashes of arrays (single or 2) hash of hash of arrays; but $overall_ref was entered";
	}
	my ( %ref_counts, $plot_type );
	foreach my $set ( keys %{ $plot->{data} } ) {
		$ref_counts{ ref $plot->{data}{$set} }++;
	}
	my $ax = $args->{ax};
	if ( (scalar keys %ref_counts) > 1 ) {
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
	$plot->{cb_logscale} = bool_option( $plot->{cb_logscale}, 'cb_logscale', $current_sub );
	foreach my $axis ( logscale_axes( $plot->{logscale}, $current_sub ) ) { # x, y 
		say {$args->{fh}} "ax$ax.set_$axis" . 'scale("log")';
	}
	# "set_options" is one string of options for a single set, and a hash of
	# one per set for several. A string given to several sets died as "Can't
	# use string as a HASH ref"; a hash given to a single set was ignored.
	if ( defined $plot->{set_options} ) {
		my $so_ref = ref $plot->{set_options};
		if ( ( $plot_type eq 'single' ) && ( $so_ref ne '' ) ) {
			die "$current_sub: \"data\" is a single set, so \"set_options\" is one string of options, e.g. 'marker = \"v\"', not a $so_ref reference";
		}
		if ( ( $plot_type eq 'multiple' ) && ( $so_ref ne 'HASH' ) ) {
			die "$current_sub: \"data\" is a hash of sets, so \"set_options\" is a hash of one string of options per set, e.g. { A => 'marker = \"v\"' }, not "
			 . ( $so_ref ? "a $so_ref reference" : 'a string' );
		}
	}
	# "key_order" is the order of the sets, which "keys" -- the order of the
	# axes within a set -- cannot say; a single set has only the one.
	if ( ( defined $plot->{key_order} ) && ( $plot_type eq 'single' ) ) {
		die "$current_sub: \"key_order\" orders the sets of a hash of sets; for the axes of a single set, use \"keys\"";
	}
	if ( $plot_type eq 'single' ) { # only a single set of data
		my $options = '';
		my ( $color_key, @keys );
		if ( defined $plot->{'keys'} ) {
			@keys = check_key_order({
				keys   => $plot->{'keys'},
				data   => $plot->{data},
				option => 'keys',
				sub    => $current_sub
			});
		} else {
			@keys = sort { lc $a cmp lc $b || $a cmp $b } keys %{ $plot->{data} };    # tie-broken, or "x" and "X" came in hash order
		}
		my $n_keys = scalar keys %{ $plot->{data} };
		if ( ( $n_keys != 2 ) && ( $n_keys != 3 ) ) {
			p $plot->{data};
			die "scatterplots can only take 2 or 3 keys as data, but $current_sub received $n_keys";
		}
		if ( defined $plot->{color_key} ) {
			$color_key = $plot->{color_key};
			# Asked here, before the keys are counted: a "color_key" that is not
			# a key of three took none of them away, so the count below died
			# first, as "needs one key for x and one for y, but "keys" and
			# "color_key" leave the 3 above", which never named the key that
			# was wrong.
			if ( not defined $plot->{data}{$color_key} ) {
				die "\"$color_key\" isn't defined for this scatter";
			}
			@keys = grep {$_ ne $plot->{color_key}} @keys;
		} elsif ( scalar @keys == 3 ) {
			$color_key = pop @keys;
		} elsif ( $n_keys == 3 ) {
			# As for several sets: "keys" named x and y of three keys, so the one
			# it left out is the color. It was drawn without one.
			my %named = map { $_ => 1 } @keys;
			($color_key) = grep { not $named{$_} } sort { lc $a cmp lc $b || $a cmp $b } keys %{ $plot->{data} };
		}
		if ( scalar @keys != 2 ) {
			p @keys;
			die "$current_sub needs one key for x and one for y, but \"keys\" and \"color_key\" leave the " . scalar(@keys) . ' above';
		}
		foreach my $i (0,1) {
			check_scatter_values( $plot->{data}{ $keys[$i] }, "\"$keys[$i]\"", $current_sub );
		}
		check_scatter_lengths( $plot->{data}, [ @keys, ( defined $color_key ? $color_key : () ) ], '', $current_sub );
		say { $args->{fh} } 'x = [' . py_nums( @{ $plot->{data}{ $keys[0] } } ) . ']';
		say { $args->{fh} } 'y = [' . py_nums( @{ $plot->{data}{ $keys[1] } } ) . ']';
		if (   ( defined $plot->{set_options} )
			&& ( ref $plot->{set_options} eq '' ) )
		{
			$options = ", $plot->{set_options}";
		}
		$options .= write_tooltip_urls( scatter_tooltips( $plot->{tooltips}, scalar @{ $plot->{data}{ $keys[0] } }, $options, '', $current_sub ), $args->{fh} );
		if ( defined $color_key ) {
			if (not defined $plot->{data}{$color_key}) {
				die "\"$color_key\" isn't defined for this scatter";
			}
			check_scatter_values( $plot->{data}{$color_key}, "\"$color_key\"", $current_sub );
			say { $args->{fh} } 'z = [' . py_nums( @{ $plot->{data}{$color_key} } ) . ']';
			# cb_min, cb_max and cb_logscale, which were accepted here and not read.
			# Left out where set_options set a scale of their own, which matplotlib
			# would refuse beside this one.
			my $range = '';
			if ( ( ( defined $plot->{vmin} ) || ( defined $plot->{vmax} ) || $plot->{cb_logscale} ) && ( $options !~ m/\b(?:vmin|vmax|norm)\s*=/ ) ) {
				$range = norm_args({
					lo     => $plot->{vmin},
					hi     => $plot->{vmax},
					values => $plot->{data}{$color_key},
					log    => $plot->{cb_logscale},
					fh     => $args->{fh},
					sub    => $current_sub
				});
			}
			say { $args->{fh} }
			  "im = ax$ax.scatter(x, y, c = z, cmap = " . py_str($plot->{cmap}) . "$range $options)";
			# The cb* options, "cblabel", "colorbar_on" and "shared_colorbar" were
			# all accepted here and none of them read: the colorbar was always drawn,
			# labelled with the color key, with only cbpad and cbdrawedges applied.
			my $cb_opts = colorbar_args($plot);
			if ( $plot->{colorbar_on} ) {
				say { $args->{fh} } "fig.colorbar(im, label = " . py_str( $plot->{cblabel} // $color_key ) . " $cb_opts)";
			}
		} else {
			say { $args->{fh} } "ax$ax.scatter(x, y $options)";
		}
		# quoted here because the key is data; see py_str above
		default_axis_labels( $plot, @keys );
	} elsif ( $plot_type eq 'multiple' ) { # multiple sets
		my @undefined_opts;
		foreach my $set ( sort keys %{ $plot->{set_options} } ) {
			next if grep { $set eq $_ } keys %{ $plot->{data} };
			push @undefined_opts, $set;
		}
		if ( scalar @undefined_opts > 0 ) {
			p $plot->{data};
			p $plot;
			say STDERR 'The data and options are above, but the following sets have options without data:';
			p @undefined_opts;
			die 'no data was defined for the above options';
		}
		# As "set_options": one array of labels per set, keyed by the set's name.
		if ( defined $plot->{tooltips} ) {
			my $tt_ref = ref $plot->{tooltips};
			if ( $tt_ref ne 'HASH' ) {
				die "$current_sub: \"data\" is a hash of sets, so \"tooltips\" is a hash of one array of labels per set, e.g. { A => ['first', 'second'] }, not "
				 . ( $tt_ref ? ( $tt_ref eq 'ARRAY' ? 'an' : 'a' ) . " $tt_ref reference" : 'a string' );
			}
			my @no_set = grep { not exists $plot->{data}{$_} } sort keys %{ $plot->{tooltips} };
			if ( scalar @no_set > 0 ) {
				die "$current_sub: \"tooltips\" names " . join( ', ', map { "\"$_\"" } @no_set ) . ', which ' . ( scalar @no_set == 1 ? 'is not a set' : 'are not sets' ) . ' of "data"';
			}
		}
		# A set may be a single point, its values numbers rather than arrays:
		# catboost => { MAE => 0.41, R2 => 0.83 }. It is drawn as a scatter of
		# one point, labelled with the set's name. The wrapping goes into a copy
		# so that the caller's data is left as it was given.
		my %sets;
		foreach my $set ( keys %{ $plot->{data} } ) {
			my $inner = $plot->{data}{$set};
			if ( ( scalar keys %{$inner} > 0 ) && ( not grep { ref } values %{$inner} ) ) {
				$sets{$set} = { map { $_ => [ $inner->{$_} ] } keys %{$inner} };
			} else {
				$sets{$set} = $inner;
			}
		}
		# The order the sets are drawn in, which is the order of the legend and
		# of the markers handed out below. Sorted by name before, with no way to
		# change it, so the groups that "df" makes with "by" came out with 10
		# before 2, though the documentation promised numeric order.
		my @set_order;
		if ( defined $plot->{key_order} ) {
			@set_order = check_key_order({
				keys   => $plot->{key_order},
				data   => $plot->{data},
				option => 'key_order',
				sub    => $current_sub
			});
		} else {
			@set_order = sort keys %sets;
		}
		# Each set is labelled with its name, for the legend, unless this is
		# false. It was accepted and never read, so the legend was always drawn.
		$plot->{show_legend} = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
		# Keys and color key of every set are settled, and every value checked,
		# before anything is written, because the color range is shared by all
		# sets and so has to be known before the first set is drawn.
		my ( %xy_keys, %color_key_of, %tooltip_urls_of );
		foreach my $set ( sort keys %sets ) {
			my ( @keys, $color_key );
			if ( defined $plot->{'keys'} ) {
				 @keys = check_key_order({
				 	keys   => $plot->{'keys'},
				 	data   => $sets{$set},
				 	option => 'keys',
				 	sub    => "$current_sub set \"$set\""
				 });
			} else { # automatically take the key from the first; further sets should have the same labels
				 @keys = sort { lc $a cmp lc $b || $a cmp $b } keys %{ $sets{$set} };
			}
			my $n_keys = scalar keys %{ $sets{$set} };
			if ( ( $n_keys != 2 ) && ( $n_keys != 3 ) ) {
				p $plot->{data}{$set};
				die "scatterplots can only take 2 or 3 keys as data, but $current_sub received $n_keys";
			}
			foreach my $key (@keys) {
				check_scatter_values( $sets{$set}{$key}, "\"$key\" of set \"$set\"", $current_sub );
			}
			if ( defined $plot->{color_key} ) {
				$color_key = $plot->{color_key};
				# before the keys are counted, as for a single set above
				if ( not defined $sets{$set}{$color_key} ) {
					die "\"$color_key\" isn't defined for set \"$set\"";
				}
				@keys = grep {$_ ne $plot->{color_key}} @keys;
			} elsif ( scalar @keys == 3 ) {
				$color_key = pop @keys;
			} elsif ( $n_keys == 3 ) {
				# "keys" named x and y of three inner keys, so the one it left out
				# is the color, as the third is when the keys are sorted. This
				# popped the y key off "keys" instead, and died as "Use of
				# uninitialized value $keys[1] in hash element".
				my %named = map { $_ => 1 } @keys;
				($color_key) = grep { not $named{$_} } sort { lc $a cmp lc $b || $a cmp $b } keys %{ $sets{$set} };
			}
			if ( scalar @keys != 2 ) {
				p @keys;
				die "$current_sub set \"$set\" needs one key for x and one for y, but \"keys\" and \"color_key\" leave the " . scalar(@keys) . ' above';
			}
			if ( defined $color_key ) {
				if (not defined $sets{$set}{$color_key}) {
					die "\"$color_key\" isn't defined for set \"$set\"";
				}
				check_scatter_values( $sets{$set}{$color_key}, "\"$color_key\" of set \"$set\"", $current_sub );
				$color_key_of{$set} = $color_key;
			}
			check_scatter_lengths( $sets{$set}, [ @keys, ( defined $color_key ? $color_key : () ) ], " of set \"$set\"", $current_sub );
			$xy_keys{$set} = \@keys;
			$tooltip_urls_of{$set} = scatter_tooltips( ( $plot->{tooltips} // {} )->{$set}, scalar @{ $sets{$set}{ $keys[0] } }, ( $plot->{set_options} // {} )->{$set} // '', " of set \"$set\"", $current_sub );
		}
		# One color scale for every set. Each ax.scatter normalises its own c to
		# its own minimum and maximum, so without this the same color meant a
		# different value in each set, the colorbar -- drawn from the last set --
		# was true only of that set, and a set of one point was always drawn in
		# the bottom color of the map whatever its value.
		my $color_range = '';
		if ( scalar keys %color_key_of > 0 ) {
			my @z = finite_values( map { @{ $sets{$_}{ $color_key_of{$_} } } } keys %color_key_of );
			# cb_min, cb_max and cb_logscale, where given, set the ends and the
			# kind of the shared scale; they were accepted and not read.
			$color_range = norm_args({
				lo     => $plot->{vmin},
				hi     => $plot->{vmax},
				values => \@z,
				log    => $plot->{cb_logscale},
				fh     => $args->{fh},
				sub    => $current_sub
			});
		}
		# The key the one colorbar is labelled with, from the last set that has
		# one. Kept apart from each set's own $color_key, which used to be this
		# same variable: a set with a third key left it defined for every set
		# after it, and a later set of only x and y died as '"z" isn't defined'.
		my $colorbar_key;
		# Sets colored by a third key are all drawn from the same colormap, so
		# color cannot tell them apart; each takes the next of these markers, in
		# the sorted order of the set names, unless its set_options name one. All
		# are filled, so each shows its color; the list repeats once it runs out. A
		# marker that set_options give to some set is left out, so that no other
		# set is given it too.
		my %taken = map { $_ => 1 } grep { defined }
			map { m/\bmarker\s*=\s*['"]([^'"]+)['"]/ ? $1 : undef } values %{ $plot->{set_options} // {} };
		my @markers = grep { not $taken{$_} } qw(o s ^ D v P X * < > p h d);
		@markers = ('o') if scalar @markers == 0; # all 13 taken: repeat the first
		my $marker_i = 0;
		foreach my $set (@set_order) {
			my $options = '';
			my @keys = @{ $xy_keys{$set} };
			my $color_key = $color_key_of{$set};
			if ( defined $plot->{set_options}{$set} ) {
				$options = ", $plot->{set_options}{$set}";
			}
			say { $args->{fh} } 'x = [' . py_nums( @{ $sets{$set}{ $keys[0] } } ) . ']';
			say { $args->{fh} } 'y = [' . py_nums( @{ $sets{$set}{ $keys[1] } } ) . ']';
			# The set's name as its label, unless it has a label of its own: the
			# uncolored path below added one regardless, and a "label" in
			# "set_options" made "keyword argument repeated", a SyntaxError.
			if ( ( $plot->{show_legend} ) && ( $options !~ m/\blabel\s*=/ ) ) {
				$options .= ', label = ' . py_str($set);
			}
			$options .= write_tooltip_urls( $tooltip_urls_of{$set}, $args->{fh} );
			if ( defined $color_key ) {
				$colorbar_key = $color_key;
				say { $args->{fh} } 'z = [' . py_nums( @{ $sets{$set}{$color_key} } ) . ']';
				unless ( $options =~ m/\bmarker\s*=/ ) {
					$options .= ", marker = '$markers[ $marker_i % @markers ]'";
					$marker_i++;
				}
				# a set's own vmin, vmax or norm is its caller's decision, and
				# matplotlib refuses norm alongside vmin and vmax
				my $range = ( $options =~ m/\b(?:vmin|vmax|norm)\s*=/ ) ? '' : $color_range;
				say { $args->{fh} }
				"im = ax$ax.scatter(x, y, c = z, cmap = " . py_str($plot->{cmap}) . "$range $options)";
			} else {
				say { $args->{fh} }	"ax$ax.scatter(x, y$options)";
			}
			# quoted here because the key is data; see py_str above
			default_axis_labels( $plot, @keys );
	  }
	  if ( defined $colorbar_key ) {
		  my $cb_opts = colorbar_args($plot);
		  if ( $plot->{colorbar_on} ) {
			  say { $args->{fh} } 'plt.colorbar(im, label = ' . py_str( $plot->{cblabel} // $colorbar_key ) . "$cb_opts)";
		  }
	  }
	}
}

sub violin_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		bad_keyword_error({
			bad       => \@undef_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	$plot->{orientation} = $plot->{orientation} // 'vertical';
	if ( $plot->{orientation} !~ m/^(?:horizontal|vertical)$/ ) {
		die "$current_sub needs either \"horizontal\" or \"vertical\", not \"$plot->{orientation}\"";
	}
	if (ref $plot->{data} eq 'ARRAY') {
		my $tmp = delete $plot->{data};
		$plot->{data}{''} = $tmp;
	}
	my ( @xticks, @key_order );
	if ( defined $plot->{key_order} ) {
		@key_order = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
	} else {
		@key_order = sort keys %{ $plot->{data} };
	}
	my $ax = $args->{ax} // '';
	# Read as Python bools, as boxplot's switches are: "medians" was written as
	# given, so "medians => 'yes'" left "showmedians = yes" in the script, and
	# "whiskers" was tested for Perl truth, in which 'False' is true.
	$plot->{medians}  = bool_option( $plot->{medians}  // 1, 'medians',  $current_sub ) ? 'True' : 'False';    # by default, show median values
	$plot->{whiskers} = bool_option( $plot->{whiskers} // 1, 'whiskers', $current_sub );    # by default, make whiskers
	# As in boxplot_helper: a hash here was written as 'HASH(0x...)'.
	if ( ref $plot->{color} ) {
		die "\"color\" is one color for every violin in $current_sub, not a " . ref( $plot->{color} ) . ' reference; give one color per key in "colors", e.g. colors => { A => \'red\' }';
	}
	$plot->{edgecolor} = $plot->{edgecolor} // 'black';
	my $options = '';    # these args go to the plt.hist call
	say { $args->{fh} } 'd = []';
	# %values, rather than writing the filtered list back into $plot->{data}:
	# the arrays in there belong to the caller, and dropping the undefined and
	# non-numeric elements in place left the caller's own array shorter than
	# they wrote it.
	my %values;
	foreach my $key (@key_order) {
	  @{ $values{$key} } = grep { ( defined ) && looks_like_number($_) && ( not is_nan($_) ) } @{ $plot->{data}{$key} };
	  # A group left with nothing in it has no mean to draw, and the mean is
	  # computed by dividing by this count: it died as "Use of uninitialized
	  # value in division", which named neither the group nor the filtering
	  # that emptied it.
	  if ( scalar @{ $values{$key} } == 0 ) {
	  	my $n_given = scalar @{ $plot->{data}{$key} };
	  	die "\"$key\" has no numeric values for $current_sub to plot ($n_given value(s) given, all undefined, NaN or non-numeric)";
	  }
	  # An infinity gives the density estimate nothing to spread over and made
	  # the mean below "Inf", written into the script as a bare name.
	  my @infinite = grep { not is_finite($_) } @{ $values{$key} };
	  if ( scalar @infinite > 0 ) {
	  	p @infinite;
	  	die "\"$key\" has the above infinite values, which $current_sub cannot draw a density for";
	  }
	  say { $args->{fh} } 'd.append(['
		 . py_nums( @{ $values{$key} } ) . '])';
	}
	foreach my $axis ( logscale_axes( $plot->{logscale}, $current_sub ) ) { # x, y
		say {$args->{fh}} "ax$ax.set_$axis" . 'scale("log")';
	}
	# No "points": it is how many points the density curve is evaluated at,
	# not a count of data, and it used to be set to the size of the smallest
	# group, so a group of 5 values drew every violin as a 5-sided polygon.
	# matplotlib's default is 100.
	say { $args->{fh} } "vp = ax$ax.violinplot(d, showmeans=False, orientation = '$plot->{orientation}', showmedians = $plot->{medians})";
	if ( defined $plot->{colors} ) { # every hash key should have its own color defined
		# the below code helps to provide better error messages in case I make an error in calling the sub
		my @wrong_keys = grep { not defined $plot->{colors}{$_} } keys %{ $plot->{data} };
		if ( scalar @wrong_keys > 0 ) {
			p $plot;
			p @wrong_keys;
			die 'the above data keys have no defined color';
		}
		# list of pre-defined colors: https://matplotlib.org/stable/gallery/color/named_colors.html
		say { $args->{fh} } 'colors = ['
		 . py_list( @{ $plot->{colors} }{@key_order} ) . ']';

		# the above color list will have the same order, via the above hash slice
		say { $args->{fh} } 'for i, pc in enumerate(vp["bodies"], 1):';
		say { $args->{fh} } "\tpc.set_facecolor(colors[i-1])";
		say { $args->{fh} } "\tpc.set_edgecolor(" . py_str( $plot->{edgecolor} ) . ')';
	} else {
		say { $args->{fh} } 'for pc in vp["bodies"]:';
		if ( defined $plot->{color} ) {
			say { $args->{fh} } "\tpc.set_facecolor(" . py_str($plot->{color}) . ')';
		}
		say { $args->{fh} } "\tpc.set_edgecolor(" . py_str( $plot->{edgecolor} ) . ')';

		#		say {$args->{fh}} "\tpc.set_alpha(1)";
	}
	if ( $plot->{whiskers} ) {
		# https://matplotlib.org/stable/gallery/statistics/customized_violin.html
		say {$args->{fh} } 'import numpy as np';
		say {$args->{fh} } 'def adjacent_values(vals, q1, q3):';
		say {$args->{fh} } '	upper_adjacent_value = q3 + (q3 - q1) * 1.5';
		say {$args->{fh} }
		 '	upper_adjacent_value = np.clip(upper_adjacent_value, q3, vals[-1])';
		say {$args->{fh} } '	lower_adjacent_value = q1 - (q3 - q1) * 1.5';
		say {$args->{fh} }
		 '	lower_adjacent_value = np.clip(lower_adjacent_value, vals[0], q1)';
		say {$args->{fh} }
		 '	return lower_adjacent_value, upper_adjacent_value';
		say {$args->{fh} } 'np_data = np.array(d, dtype = object)';
		say {$args->{fh} } 'quartile1 = []';
		say {$args->{fh} } 'medians   = []';
		say {$args->{fh} } 'quartile3 = []';
		say {$args->{fh} } 'for subset in list(range(0, len(np_data))):';
		say {$args->{fh}} '	local_quartile1, local_medians, local_quartile3 = np.percentile(d[subset], [25, 50, 75])' . "\n";
		say {$args->{fh}} '	quartile1.append(local_quartile1)';
		say {$args->{fh}} '	medians.append(local_medians)';
		say {$args->{fh}} '	quartile3.append(local_quartile3)';
		# sorted(): adjacent_values reads the smallest and largest values as
		# vals[0] and vals[-1]. matplotlib's example sorts its data first; this
		# passed "d" in the caller's order, so for [10, 9, ..., 1, 100] the
		# lower whisker was clipped to q1 and not drawn at all.
		say {$args->{fh}} 'whiskers = np.array([';
		say {$args->{fh}} '    adjacent_values(sorted(subset), q1, q3)';
		say {$args->{fh}} '    for subset, q1, q3 in zip(d, quartile1, quartile3)])';
		say {$args->{fh}} 'whiskers_min, whiskers_max = whiskers[:, 0], whiskers[:, 1]';
		say {$args->{fh}} 'inds = np.arange(1, len(medians) + 1)';
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
		 . format_commas( scalar @{ $values{$key} }, '%.0u' ) . ')';
		my $mean = sum( @{ $values{$key} } ) / scalar @{ $values{$key} };
		if ( $plot->{orientation} eq 'vertical' ) {
			say { $args->{fh} } "ax$ax.plot("
			  . scalar @xticks . ", $mean"
			  . ', "ro")';    # plot mean point, which is red
		} else {                # orientation = horizontal
			say { $args->{fh} } "ax$ax.plot($mean, "
			 . scalar @xticks . ', "ro")';    # plot mean point, which is red
		}
	}
	if ( $plot->{orientation} eq 'vertical' ) {
		say { $args->{fh} } "ax$ax.set_xticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ['
		 . py_list(@xticks) . '])';
	} else {
	  say { $args->{fh} } "ax$ax.set_yticks(["
		 . join( ',',   1 .. scalar @key_order ) . '], ['
		 . py_list(@xticks) . '])';
	}
}

sub write_wide_group {
	# Emit the Python drawing one group of runs: every run faint, the mean of
	# the runs solid, and mean +/- 1 standard deviation as a ribbon.
	#
	# The runs need not share an x grid, so they are interpolated onto 101
	# evenly spaced points (the number the documentation promises) spanning
	# the group's own x range. Two properties of np.interp drive the code
	# below: it needs its sample points ascending, and by default it holds the
	# end values flat outside them. Left alone, the first silently returns a
	# flat line for a run whose x descends, and the second folds an invented
	# horizontal line into the mean and the s.d. wherever a run stops short of
	# the group's range. So each run is sorted by x first, and asked for NaN
	# outside its own range; the summary below then averages, at each point,
	# only the runs that actually reach it.
	my ($args) = @_;
	my ( $fh, $ax, $runs, $color, $label ) =
	  @{$args}{qw(fh ax runs color label)};
	my ( $min_x, $max_x ) = ( 'inf', '-inf' );
	foreach my $run ( @{$runs} ) {
		$min_x = min( $min_x, finite_values( @{ $run->[0] } ) );
		$max_x = max( $max_x, finite_values( @{ $run->[0] } ) );
	}
	my $py_color = py_str($color);
	say {$fh} 'ys = []';
	say {$fh} 'base_x = np.linspace(' . py_num($min_x) . ', ' . py_num($max_x) . ', 101)';
	foreach my $run ( @{$runs} ) {
		say {$fh} 'x = [' . py_nums( @{ $run->[0] } ) . ']';
		say {$fh} 'y = [' . py_nums( @{ $run->[1] } ) . ']';
		say {$fh} "order = np.argsort(x, kind = 'stable')";
		say {$fh} 'x = np.asarray(x)[order]';
		say {$fh} 'y = np.asarray(y)[order]';
		say {$fh} "ax$ax.plot(x, y, $py_color, alpha=0.15)";
		say {$fh} 'ys.append(np.interp(base_x, x, y, left = np.nan, right = np.nan))';
	}
	say {$fh} 'ys = np.array(ys)';
	say {$fh} 'covered = ~np.isnan(ys)';    # which runs reach each point of base_x
	say {$fh} 'n_runs = covered.sum(axis = 0)';
	say {$fh} 'divisor = np.maximum(n_runs, 1)';    # a point no run reaches would divide by 0
	say {$fh} 'mean_ys = np.where(covered, ys, 0.0).sum(axis = 0) / divisor';
	say {$fh} 'var_ys = np.where(covered, (ys - mean_ys) ** 2, 0.0).sum(axis = 0) / divisor';
	say {$fh} 'std = np.where(n_runs > 0, np.sqrt(var_ys), np.nan)';
	say {$fh} 'mean_ys = np.where(n_runs > 0, mean_ys, np.nan)';    # after var_ys, which needs the unmasked mean
	say {$fh} 'ys_upper = mean_ys + std';
	say {$fh} 'ys_lower = mean_ys - std';
	if ( defined $label ) {
		say {$fh} "ax$ax.plot(base_x, mean_ys, $py_color, label = " . py_str($label) . ')';
	} else {
		say {$fh} "ax$ax.plot(base_x, mean_ys, $py_color)";
	}
	say {$fh} "ax$ax.fill_between(base_x, ys_lower, ys_upper, color=$py_color, alpha=0.3)";
}
sub wide_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
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
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	$plot->{show_legend} = bool_option( $plot->{show_legend} // 1, 'show_legend', $current_sub );
	my @undef_opt = grep {
	  my $key = $_;
	  not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		bad_keyword_error({
			bad       => \@undef_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	say { $args->{fh} } 'import numpy as np';
	my $ax       = $args->{ax} // '';
	my $ref_type = ref $plot->{data};
	if ( $ref_type eq 'HASH' ) {    # one labelled group per key
		if ( ( defined $plot->{color} ) && ( ref $plot->{color} ne 'HASH' ) ) {
			die "$current_sub: \"data\" is a HASH of groups, so \"color\" must be a HASH of one color per group";
		}
		# Sorted, as every other plot type orders its keys: in hash order the
		# groups, and so the legend, came out in a different order from one
		# run to the next.
		my $group_i = 0;
		foreach my $group ( sort keys %{ $plot->{data} } ) {
			check_wide_runs( $plot->{data}{$group}, "group \"$group\"", $current_sub );
			# An uncolored group takes the next color of matplotlib's own
			# cycle, "C0", "C1" and on. Every group used to default to 'b', so
			# without a "color" hash the groups could not be told apart.
			write_wide_group({
				fh    => $args->{fh},
				ax    => $ax,
				runs  => $plot->{data}{$group},
				color => $plot->{color}{$group} // 'C' . ( $group_i % 10 ),    # the default cycle has 10 colors
				label => $plot->{show_legend} ? $group : undef
			});
			$group_i++;
		}
	} elsif ( $ref_type eq 'ARRAY' ) {    # one unlabelled group
		if ( ref $plot->{color} ) {
			die "$current_sub: \"data\" is one unlabelled group, so \"color\" must be a single color, not a " . ( ref $plot->{color} ) . ' reference';
		}
		check_wide_runs( $plot->{data}, '"data"', $current_sub );
		write_wide_group({
			fh    => $args->{fh},
			ax    => $ax,
			runs  => $plot->{data},
			color => $plot->{color} // 'b',
			label => undef    # the array form carries no group name to label
		});
	} else {
	  die "$current_sub cannot take ref type \"$ref_type\" for \"data\"";
	}
}

sub print_type {
	# Whether a value has to be quoted on its way into the generated Python.
	my $str = shift;
	my $type = 'no quotes';
	if (looks_like_number($str)) { # numbers (e.g. 0.8) must not be quoted
		return 'no quotes';
	}
	# An argument list of bare values, such as "0, 10" for "ylim" or "0.5, 0, 1"
	# for "axhline", is Python rather than text. The comma tests below quoted
	# it, so a single plot's "ylim => '0, 10'" wrote plt.ylim('0, 10') and died
	# as "ValueError: too many values to unpack". None, True and False are bare
	# values too, so that
	# "ylim => 'None, 10'" leaves the bottom where matplotlib puts it.
	my @items = split /,/, $str, -1;
	if (   ( scalar @items > 1 )
		&& ( not grep { ( not looks_like_number($_) ) && ( $_ !~ m/^\h*(?:None|True|False)\h*$/ ) } @items ) ) {
		return 'no quotes';
	}
	# A single Python value: None, True or False; one bracketed group, such as
	# "(0, 10)" or "[]"; or one call, such as "np.arange(0, 1, 0.1)". Each was
	# quoted below, which a single plot always did and a subplot does now that
	# it quotes as well. The bracket must close at the very end, so that
	# "f(x), g(x)" is still text.
	if (   ( $str =~ m/^\h*(?:None|True|False)\h*$/ )
		|| ( $str =~ m/^\h*(?:[A-Za-z_][\w.]*)?(\((?:[^()]++|(?1))*\))\h*$/ )
		|| ( $str =~ m/^\h*(\[(?:[^\[\]]++|(?1))*\])\h*$/ ) ) {
		return 'no quotes';
	}
	# Text that already carries a quote of its own is Python the caller wrote
	# -- a quoted label ('"Counts, by book"', the form the documentation asks
	# for when the text holds a comma), a mathtext raw string, or a whole
	# argument list such as '0.5, 0.01, "note"'. Quoting it again nests the
	# quotes and emits plt.suptitle(''Counts, by book''), a SyntaxError. This
	# generalises the "keyword = <quote>" test below, which caught the same
	# thing only when the quote followed an "=".
	if ($str =~ m/['"]/) {
		return 'no quotes';
	}
	# A keyword argument, e.g. "hspace = 0.5" or "loc = 'upper left'": already
	# Python, whether or not its value is quoted.
	if ($str =~ m/\w\h*=\h*\S/) {
		return 'no quotes';
	}
   if ($str =~ m/^\w+$/) {
   	return 'single quotes';
   } elsif ($str =~ m/^\[\h*\-?\d.+\d\h*\]$/) {
   	return 'no quotes';
   } elsif ($str =~ m/[!@#\$\%^&*\(\)\{\}\[\]\<\>,\/\-\h:;\+=\w]+$/) {
   	return 'single quotes';
   } elsif (($str =~ m/,/) && ($str !~ m/[\]\[]/)) {
   	return 'single quotes';
   }
   return $type;
}
sub pyplot_arg {
	# A pyplot option's value as the text between the parentheses of its call.
	#
	# A single plot and a subplot both write their pyplot options through
	# this. A subplot used to write every value exactly as given, so
	# "xscale => 'log'" left plt.xscale(log) and raised "NameError: name 'log'
	# is not defined", while the same option at a single plot was quoted.
	# py_str, not "'$value'": a backslash in '...' went through as a python
	# escape, so "C:\new" came out with a newline in it.
	my ($value) = @_;
	return print_type($value) eq 'single quotes' ? py_str($value) : $value;
}
# The interpreters tried on MSWin32, in order. "python" first, because it is
# what a stock install from python.org and an activated venv both put on PATH,
# and the venv is the one that has matplotlib; "py -3", the launcher, next,
# since an install can leave python off PATH but always installs the
# launcher; "python3" last, for MSYS2 and the like. A stock Windows install has
# no "python3" at all, which is why running it failed wherever Python *was*
# present, and never showed up in a CPAN Testers report because the smokers
# have none.
my @windows_python_candidates = ( ['python'], [ 'py', '-3' ], ['python3'] );
# The command plt runs, as a list for system(). undef = not yet looked for;
# [] = looked for, and none found. A package variable rather than a lexical so
# that the test suite can point it at a stand-in interpreter.
our $python_command;
sub python_command {
	# The interpreter plt runs scripts with, as a list.
	# $ENV{MATPLOTLIB_SIMPLE_PYTHON}, when set and not empty, is that
	# interpreter, taken whole and neither searched for nor checked: it names a venv or a module-loaded Python
	# without changing PATH, and is not split on spaces because a path such as
	# "C:\Program Files\Python312\python.exe" has them. One that does not
	# run is reported by plt as "failed to start". Otherwise it is
	# ('python3') on everything but MSWin32, as it always was, and there the
	# first of @windows_python_candidates that reports itself as Python 3, or
	# an empty list if none does. The result is kept, so the search runs once.
	#
	# "--version" rather than trusting that the name resolves: on Windows 10
	# and 11 "python" with no Python installed is a Microsoft Store stub,
	# which prints "Python was not found" and exits 9009. Both streams are
	# read, since Python 3 before 3.4 printed its version to STDERR.
	return @{$python_command} if defined $python_command;
	my $named = program_from_env('MATPLOTLIB_SIMPLE_PYTHON');
	if ( defined $named ) {
		$python_command = [$named];
		return @{$python_command};
	}
	if ( $^O ne 'MSWin32' ) {
		$python_command = ['python3'];
		return @{$python_command};
	}
	foreach my $candidate (@windows_python_candidates) {
		my ( $out, $err, $status ) = capture {
			no warnings 'exec';    # a candidate that is not installed is expected; see the call in plt
			system( @{$candidate}, '--version' );
		};
		next unless ( $status == 0 ) && ( "$out$err" =~ m/^Python 3\./m );
		$python_command = [ @{$candidate} ];
		return @{$python_command};
	}
	$python_command = [];
	return ();
}
sub savefig_takes_metadata {
	# Whether matplotlib's savefig accepts "metadata" for a file of this name:
	# 1 for .png, .pdf, .svg, .svgz, .eps and .ps, in any case, and for a name
	# with no extension, which matplotlib saves as its default format, a PNG;
	# 0 for every other extension. The extension is what follows the last "."
	# of the file's own name, as pathlib's suffix reads it, so a "." in a
	# directory's name, or one that leads the file's name, is not one.
	my ($file) = @_;
	return 1 unless $file =~ m{[^/\\.][^/\\]*\.([^./\\]*)\z}s;
	return ( lc($1) =~ m/\A(?:|png|pdf|svgz?|eps|ps)\z/ ) ? 1 : 0;
}
sub shared_color_scale {
	# Python giving every color-mapped artist of the subplots that share a
	# colorbar one scale: the lowest bottom and the highest top of any of
	# them.
	#
	# Each subplot scaled its colors to its own data -- hexbin and hist2d to
	# their own counts, which only matplotlib knows -- so the same color meant
	# a different value in each, and the one colorbar, drawn from the last of
	# them, was true only of that one. set_clim on each brings them to one
	# scale, and the colorbar follows the artist it was drawn from. The margins
	# a hexbin draws with "marginals" are left alone, being densities of their
	# own. colored_table is left to shared_table_range.
	my ( $fh, $args ) = @_;
	my @axes = map { "ax$_" } grep { ( $args->{plots}[$_]{plot_type} // '' ) ne 'colored_table' } @{ $args->{shared_colorbar} };
	return if scalar @axes < 2;
	say $fh 'shared_mappables = [m for a in [' . join( ', ', @axes ) . '] for m in a.collections + a.images if m.get_array() is not None]';
	say $fh 'shared_margins = [id(b) for m in shared_mappables for b in (getattr(m, "hbar", None), getattr(m, "vbar", None)) if b is not None]';
	say $fh 'shared_mappables = [m for m in shared_mappables if id(m) not in shared_margins and m.norm.vmin is not None and m.norm.vmax is not None]';
	say $fh 'if len(shared_mappables) > 1:';
	say $fh "\tshared_lo = min(m.norm.vmin for m in shared_mappables)";
	say $fh "\tshared_hi = max(m.norm.vmax for m in shared_mappables)";
	say $fh "\tfor m in shared_mappables:";
	say $fh "\t\tm.set_clim(shared_lo, shared_hi)";
}
sub render {
	# plt's figure as a Python script, which is run unless "execute" is false.
	# Returns the script's path.
	#
	# args:    plt's arguments once Matplotlib::Simple has checked them: "p" and "df"
	#          folded in, "nrows", "ncols" and "execute" set, every plot_type
	#          checked and every plot given "data"
	# context: sub         => the name the caller called ("plt", "bar", ...)
	#          single_plot => 1 = one plot, its keywords at the top level;
	#                         0 = "plots", one hash per subplot
	#          style       => "matplotlib" or "native" (%Matplotlib::Simple::styles), which
	#                         draw the same figure here
	#          dpi         => the dots per inch to save "output_file" at, a
	#                         finite number above 0, or undef for matplotlib's own
	my ( $args, $context ) = @_;
	my $current_sub = $context->{sub};
	my $single_plot = $context->{single_plot};
	%twin_axes = ();    # see its declaration
	@tooltip_text = ();    # and this one's
	# matplotlib picks the format by the extension, in any case, and ".svgz"
	# is a gzipped SVG.
	$tooltips_drawn = ( ( defined $args->{output_file} ) && ( $args->{output_file} =~ m/\.svgz?\z/i ) ) ? 1 : 0;
	my @ax = map { "ax$_" } 0 .. $args->{nrows} * $args->{ncols} - 1;
	my ( @py, @y, $fh);
	my $i = 0;
	foreach my $ax (@ax) {
		my $a1i = int $i / $args->{ncols}; # 1st index
		my $a2i = $i % $args->{ncols};     # 2nd index
		$y[$a1i][$a2i] = $ax;
		$i++;
	}
	foreach my $y (@y) {
		push @py, '(' . join( ',', @{$y} ) . ')';
	}
	$fh = script_handle( $args, '.py', $current_sub );
	say $fh 'import matplotlib.pyplot as plt';
	say $fh 'import json, base64';
	if ( $single_plot == 0 ) {
		# matplotlib takes a bool or one of the words "row", "col", "all" and
		# "none". A word was written bare, so "sharey => 'row'" left
		# "sharey = row" in the script and died as a NameError.
		foreach my $share ('sharex', 'sharey') {
			my $value = $args->{$share} // 0;
			if ( ( ref $value eq '' ) && ( $value =~ m/^(?:row|col|all|none)$/ ) ) {
				$args->{$share} = py_str($value);
			} elsif ( ( ref $value eq '' ) && looks_like_number($value) ) {
				$args->{$share} = py_num($value);    # matplotlib reads a number as a bool
			} else {
				$args->{$share} = bool_option( $value, $share, $current_sub ) ? 'True' : 'False';
			}
		}
		say $fh 'fig, ('
		 . join( ',', @py )
		 . ") = plt.subplots($args->{nrows}, $args->{ncols}, sharex = $args->{sharex}, sharey = $args->{sharey}, layout = 'constrained') #" . __LINE__;
	} elsif ( $single_plot == 1 ) {
		say $fh 'fig, ax0 = plt.subplots(1,1, layout = "constrained")';
	} else {
		die "\$single_plot = $single_plot breaks pigeonholes";
	}
	my %dispatch = (
		bar          => \&barplot_helper, barh         => \&barplot_helper,
		boxplot      => \&boxplot_helper, colored_table=> \&colored_table_helper,
		hexbin       => \&hexbin_helper,  hist         => \&hist_helper,
		hist2d       => \&hist2d_helper,  imshow       => \&imshow_helper,
		pie          => \&pie_helper,	    plot         => \&plot_helper,
		scatter      => \&scatter_helper, violin   => \&violin_helper,
		venn_proportional_area => \&venn_proportional_area_helper,
		violinplot   => \&violin_helper,
		wide         => \&wide_helper
	);
	if ($single_plot == 1) {
		my $has_hist = has_hist( $args, $args->{plot_type} );
		hist_range_report( $fh, 0, 'start' ) if $has_hist;
		foreach my $graph (@{ $args->{add} }) {
			$graph->{plot_type} = $graph->{plot_type} // $args->{plot_type};
			my $type = $graph->{plot_type};
			die 'plot_type not defined for "add" graph' unless defined $type;
			check_plot_type({ type => $type, where => 'for an "add" graph' });
			$dispatch{$type}->({
				fh   => $fh,
				ax   => 0,
				plot => $graph
			});
		}
		delete $args->{add};
		my $type = $args->{plot_type};
		# check_plot_type above has already refused anything outside
		# %opt_key_of_type, which lists the same 15 types as %dispatch, so this
		# fires only if the two are edited out of step.
		die "no helper is registered for plot_type \"$type\"" unless defined $dispatch{$type};
		$dispatch{$type}->({
			fh   => $fh,
			ax   => 0,
			plot => $args
		});
		hist_range_report( $fh, 0, 'report' ) if $has_hist;
		# "xlim" is not here, though it was: no keyword list accepts it, so it
		# is refused long before this as an option that isn't defined (the
		# documentation uses that refusal as its worked example), and the
		# rename could never fire.
		my %rename = (
			xlabel => 'set_xlabel',
			title  => 'set_title',
			ylabel => 'set_ylabel',
			legend => 'legend',
		);
		foreach my $opt ( grep { defined $rename{$_} } keys %{$args} ) {
			$args->{ $rename{$opt} } = delete $args->{$opt};
		}
		# emit_plt_fig => 0: the "fig." and "plt." methods in this same hash
		# are written by the two loops below, which quote through print_type.
		# Letting both passes run emitted every one of them twice.
		plot_args({
			fh           => $fh,
			args         => $args,
			ax           => 'ax0',
			emit_plt_fig => 0
		});
	}
	my $ax = 0;
	foreach my $plot (@{ $args->{plots} } ) {
		if (
				(defined $args->{shared_colorbar})               && # shared_colorbar is defined
				(grep {$_ == $ax} @{ $args->{shared_colorbar} })    # subplot's colorbar is shared w other plots
			) {
			if ($ax == max( @{ $args->{shared_colorbar} } )) { # this is the max
				$plot->{colorbar_on}     = 1; # turn on if this is the max plot
				$plot->{shared_colorbar} = $args->{shared_colorbar};
				$plot->{cbpad} = $args->{cbpad} if defined $args->{cbpad};    # not undef: an undef key is still a key, and was refused as an option
			} else {
				$plot->{colorbar_on} = 0; # turn off, its colorbar will be shared later
			}
		}
		my $has_hist = has_hist( $plot, $plot->{plot_type} );
		hist_range_report( $fh, $ax, 'start' ) if $has_hist;
		foreach my $graph (@{ $plot->{add} }) {
			$graph->{plot_type} = $graph->{plot_type} // $plot->{plot_type};
			my $type = $graph->{plot_type};
			die "plot_type not defined for \"add\" graph at ax = $ax" unless defined $type;
			# "at subplot $ax", not "at ax = $ax": the up-front check above
			# words it that way, and this line and that one describe the same
			# graph.
			check_plot_type({ type => $type, where => "for an \"add\" graph at subplot $ax" });
			$dispatch{$type}->({
				fh   => $fh,
				ax   => $ax,
				plot => $graph
			});
		}
		# As above: the type was checked before the figure was written, so this
		# is a guard on %dispatch alone. Without it an unknown type died as
		# "Can't use an undefined value as a subroutine reference".
		die "no helper is registered for plot_type \"$plot->{plot_type}\" at ax = $ax"
		 unless defined $dispatch{ $plot->{plot_type} };
		$dispatch{$plot->{plot_type}}->({
			fh   => $fh,
			ax   => $ax,
			plot => $plot
		});
		hist_range_report( $fh, $ax, 'report' ) if $has_hist;
		my %rename = (
			xlabel => 'set_xlabel',			title  => 'set_title',
			ylabel => 'set_ylabel',			legend => 'legend',
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
	shared_color_scale( $fh, $args ) if defined $args->{shared_colorbar};
	foreach my $ax (@ax) {
		say $fh "if $ax.has_data() == False:";    # remove empty plots
		say $fh "\t$ax.remove()";                 # remove empty plots
	}
	my %methods = map { $_ => 1 } @plt_methods;
	# Text is quoted as plot_args quotes it before print_type sees it. For a
	# single plot this is what always happened, though by accident: plot_args
	# quoted the caller's own hash in place, and this loop read the result.
	# plot_args now works on a copy, so the step is written out here, where it
	# now also reaches the "suptitle" of a figure of several subplots, and the
	# figure's own "supxlabel" and "supylabel", written by the fig. loop below.
	my %written_here = map { $_ => 1 } ( @plt_methods, @fig_methods );
	foreach my $text_method ( grep { ( $written_here{$_} ) && ( defined $args->{$_} ) } @text_methods ) {
		my $text = $args->{$text_method};
		$args->{$text_method} = ( ref $text eq 'ARRAY' ) ? [ map { quote_text($_) } @{$text} ] : ( ref $text ) ? $text : quote_text($text);    # an array element by element, as in plot_args
	}
	# As in plot_args: a single plot's "twinx" leaves the twin current, and its
	# "axhline" was drawn on the twin. A figure of several subplots is left
	# alone, since its own pyplot options are figure-wide ones like "suptitle".
	if ( ( $single_plot == 1 ) && ( grep { ( defined $methods{$_} ) && ( $_ ne 'show' ) } keys %{$args} ) ) {
		say $fh 'plt.sca(ax0) #' . __LINE__;
	}
	# A single plot's "legend" was written by plot_args above, and only if
	# something carries a label; writing it here too drew it a second time, and
	# warned "No artists with labels found to put in legend" when nothing did.
	foreach my $plt_method ( grep { defined $methods{$_} && ( ( $single_plot == 0 ) || ( $_ ne 'legend' ) ) } keys %{$args} ) {
		my $ref = ref $args->{$plt_method};
		if ( $ref eq '' ) {
			if ($plt_method eq 'show') {
				next; # plt.show() is emitted after plt.savefig() below
			}
			say $fh "plt.$plt_method(" . pyplot_arg( $args->{$plt_method} ) . ')#' . __LINE__;
		} elsif ( $ref eq 'ARRAY' ) {
			foreach my $j ( @{ $args->{$plt_method} } ) {
				say $fh "plt.$plt_method(" . pyplot_arg($j) . ')#' . __LINE__;
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
	if (defined $args->{scalex}) {
		say $fh "fig.set_figwidth(plt.rcParams['figure.figsize'][0] * $args->{scalex}) #" . __LINE__;
	}
	if (defined $args->{scaley}) {
		say $fh "fig.set_figheight(plt.rcParams['figure.figsize'][1] * $args->{scaley}) #" . __LINE__;
	}
	if (defined $args->{output_file}) {
		write_data({
			data => $args->{output_file},
			fh   => $fh,
			name => 'output_file'
		});
		# py_str, not interpolation: on MSWin32 the paths in creator_note are
		# backslash paths, so "C:\build\..." pasted into a Python literal
		# reads "\b" as a backspace and "\c" as an invalid escape
		# (SyntaxWarning in 3.12, SyntaxError from 3.15). An apostrophe
		# anywhere in the path would close the literal early.
		my $creator = py_str( creator_note($current_sub) );
		# The Python and matplotlib versions, the user and the host are read by
		# the script as it runs, not by Perl as it writes: with "execute => 0"
		# the script may be run later, or elsewhere, by an interpreter Perl
		# never sees, and it is whoever runs it that writes the file.
		say $fh 'import matplotlib, platform, getpass';
		# getpass.getuser() raises when no LOGNAME, USER, LNAME or USERNAME is
		# set and there is no password database to fall back on -- OSError
		# from Python 3.13, KeyError or ImportError before -- so an unknown
		# user must not stop the figure from being saved.
		say $fh 'try:';
		say $fh "\tcreator_user = getpass.getuser()";
		say $fh 'except Exception:';
		say $fh "\tcreator_user = 'unknown user'";
		say $fh "creator_host = platform.node() or 'unknown host' # node() is '' when the name cannot be found";
		# An SVG keeps only the Creator. matplotlib also writes the time it was
		# saved, its own "image/svg+xml" and a link to the Dublin Core "StillImage"
		# type, each of which a None leaves out (backend_svg._write_metadata,
		# matplotlib 3.11.2). Only for an SVG: the PDF backend warns about
		# "Format" and "Type" as keys it does not know.
		#
		# And only for a format that keeps metadata. The note was handed to
		# savefig whatever the file, and matplotlib refuses it for the formats
		# that have nowhere to put one -- "ValueError: metadata not supported
		# for format 'jpeg'", and the like for tiff, webp, gif, avif, raw and
		# rgba, and a TypeError for pgf -- so no .jpg, .tif, .webp, .gif or
		# .pgf could be written at all (matplotlib 3.11.2). Those are saved
		# without a note. matplotlib picks the format by the extension, in any
		# case, and a name with none is the PNG it has always been.
		# "dpi" is plt's own keyword for the resolution, checked there to be a
		# finite number above 0. Without it savefig is called as it always
		# was, at matplotlib's own "savefig.dpi".
		my $dpi = defined $context->{dpi} ? ', dpi = ' . py_num( $context->{dpi} ) : '';
		if ( savefig_takes_metadata( $args->{output_file} ) ) {
			say $fh "plt.savefig(output_file, bbox_inches = 'tight'$dpi, metadata={'Creator': $creator"
			 . " + ', Python ' + platform.python_version() + ', matplotlib ' + matplotlib.__version__"
			 . " + ', by ' + creator_user + ' on ' + creator_host"
			 . ( $tooltips_drawn ? ", 'Date': None, 'Format': None, 'Type': None" : '' ) . '})';
		} else {
			say $fh "plt.savefig(output_file, bbox_inches = 'tight'$dpi) # no metadata: this format keeps none";
		}
		# $tooltips_drawn is 1 exactly when output_file is an SVG. matplotlib
		# writes <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" ...> from a fixed
		# string, svgProlog in backend_svg.py, that no option turns off, so it is
		# cut from the file once written. SVG 2 has no DOCTYPE, and no browser
		# reads it. It holds no ">" of its own: there is no internal subset.
		print {$fh} <<'PYTHON' if $tooltips_drawn;
import gzip, re
svg_open = gzip.open if output_file.lower().endswith('.svgz') else open
with svg_open(output_file, 'rb') as svg:
	svg_bytes = svg.read()
with svg_open(output_file, 'wb') as svg:
	svg.write(re.sub(rb'<!DOCTYPE[^>]*>\s*', b'', svg_bytes, count = 1))
PYTHON
	}
	if ( ( scalar @tooltip_text > 0 ) && ( not $tooltips_drawn ) ) {
		warn '"tooltips" are drawn only into an SVG, so they are left out of '
		 . ( defined $args->{output_file} ? "\"$args->{output_file}\"" : 'a figure that is only shown' )
		 . ': give "output_file" a name ending in ".svg"';
	}
	if ( ( scalar @tooltip_text > 0 ) && $tooltips_drawn ) {
		write_data({
			data => \@tooltip_text,
			fh   => $fh,
			name => 'tooltip_text'
		});
		write_data({
			data => $tooltip_url,
			fh   => $fh,
			name => 'tooltip_url'
		});
		# Each labelled point was drawn inside <a xlink:href="#...-<n>"
		# target="_blank">, which becomes a bare <g> whose first child is a
		# <title> holding text n. The namespaces are registered so that the
		# file is written back with matplotlib's own prefixes rather than ns0,
		# ns1, ...
		#
		# A <title> alone was not enough: whether a browser shows it on
		# hovering is up to the browser and the desktop, and in 0.321 neither
		# Firefox nor Chromium showed one on the author's machine. So the <g>
		# is also given the class matplotlib-simple-tooltip, and a script at
		# the end of the SVG draws the label itself, in a box beside the point
		# under the mouse. The script takes each <title> out as it starts, so
		# that a browser that does show titles does not show the label twice;
		# a viewer that runs no script -- Inkscape, Eye of GNOME, an <img> on
		# a web page -- keeps the <title>s in the file.
		print {$fh} <<'PYTHON';
# Placement, in the SVG's own units, which are points: the box sits 4 from the
# marker and 3 outside its text, above and to the right of the point, and is
# moved left of or below it wherever it would leave the figure.
tooltip_script = r'''(function () {
	var ns = 'http://www.w3.org/2000/svg';
	var me = document.currentScript;
	var svg = (me && me.ownerSVGElement) || document.documentElement;
	var points = svg.querySelectorAll('g.matplotlib-simple-tooltip');
	var gap = 4, pad = 3;
	var tip = document.createElementNS(ns, 'g');
	tip.setAttribute('pointer-events', 'none');
	tip.setAttribute('display', 'none');
	var box = document.createElementNS(ns, 'rect');
	box.setAttribute('rx', '2');
	box.setAttribute('style', 'fill: #ffffe1; stroke: #555555; stroke-width: 0.5');
	var text = document.createElementNS(ns, 'text');
	text.setAttribute('style', 'font-family: sans-serif; font-size: 10px; fill: #000000');
	tip.appendChild(box);
	tip.appendChild(text);
	svg.appendChild(tip);
	function show(point, label) {
		while (text.firstChild) text.removeChild(text.firstChild);
		label.split('\n').forEach(function (line, i) {
			var span = document.createElementNS(ns, 'tspan');
			span.setAttribute('x', '0');
			span.setAttribute('dy', i ? '1.2em' : '0');
			span.textContent = line;
			text.appendChild(span);
		});
		tip.removeAttribute('display');
		var ctm = svg.getScreenCTM();
		if (!ctm) return;
		var t = text.getBBox(), w = t.width + 2 * pad, h = t.height + 2 * pad;
		var bx = t.x - pad, by = t.y - pad;
		var r = point.getBoundingClientRect(), inv = ctm.inverse(), p = svg.createSVGPoint();
		p.x = r.left; p.y = r.top;
		var lo = p.matrixTransform(inv);
		p.x = r.right; p.y = r.bottom;
		var hi = p.matrixTransform(inv);
		var vb = svg.viewBox.baseVal;
		var left = vb ? vb.x : 0, top = vb ? vb.y : 0;
		var right = vb ? vb.x + vb.width : Infinity, bottom = vb ? vb.y + vb.height : Infinity;
		var x = hi.x + gap, y = lo.y - gap - h;
		if (x + w > right) x = lo.x - gap - w;
		if (x < left) x = left;
		if (y < top) y = hi.y + gap;
		if (y + h > bottom) y = Math.max(top, bottom - h);
		box.setAttribute('x', bx);
		box.setAttribute('y', by);
		box.setAttribute('width', w);
		box.setAttribute('height', h);
		tip.setAttribute('transform', 'translate(' + (x - bx) + ' ' + (y - by) + ')');
	}
	function hide() {
		tip.setAttribute('display', 'none');
	}
	Array.prototype.forEach.call(points, function (point) {
		var title = point.querySelector('title');
		if (!title) return;
		var label = title.textContent;
		point.removeChild(title);
		if (label === '') return;
		point.addEventListener('mouseenter', function () { show(point, label); });
		point.addEventListener('mouseleave', hide);
	});
})();'''
import xml.etree.ElementTree as ET
svg_ns = 'http://www.w3.org/2000/svg'
xlink_href = '{http://www.w3.org/1999/xlink}href'
for prefix, uri in (('', svg_ns), ('xlink', 'http://www.w3.org/1999/xlink'),
	('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'),
	('cc', 'http://creativecommons.org/ns#'), ('dc', 'http://purl.org/dc/elements/1.1/')):
	ET.register_namespace(prefix, uri)
# svg_open was set where the DOCTYPE was cut, after savefig
with svg_open(output_file, 'rb') as svg:
	svg_tree = ET.parse(svg)
for link in list(svg_tree.iter('{%s}a' % svg_ns)):
	href = link.get(xlink_href, '')
	if not href.startswith(tooltip_url):
		continue
	link.tag = '{%s}g' % svg_ns
	link.attrib.clear()
	link.set('class', 'matplotlib-simple-tooltip')
	title = ET.Element('{%s}title' % svg_ns)
	title.text = tooltip_text[int(href[len(tooltip_url):])]
	link.insert(0, title)
# last, so that every point is in the document when it runs, and the box it
# draws is on top of everything else
ET.SubElement(svg_tree.getroot(), '{%s}script' % svg_ns, {'type': 'text/javascript'}).text = tooltip_script
with svg_open(output_file, 'wb') as svg:
	svg_tree.write(svg, encoding = 'utf-8', xml_declaration = True)
PYTHON
	}
	say $fh 'plt.show()' if $args->{show}; # after savefig, so the file is written even if the window is never closed
	say $fh 'plt.close()' if $args->{execute} == 0;
	if ( $args->{execute} ) {
		my @python = python_command();
		if ( scalar @python == 0 ) {
			die 'no Python 3 interpreter was found to run ' . $fh->filename
			 . ': tried ' . join( ', ', map { '"' . join( ' ', @{$_} ) . '"' } @windows_python_candidates )
			 . '. Install Python 3 and matplotlib, set MATPLOTLIB_SIMPLE_PYTHON to the path of a Python 3 that has them, or pass "execute => 0" to write the script without running it';
		}
		# What the script wrote to STDERR as it ran and succeeded: matplotlib's
		# warnings, which are the only word the caller gets that a figure was
		# written but is not what was asked for -- "Data has no positive
		# values, and therefore cannot be log-scaled", a font with no glyph for
		# a label, a deprecation. run_script captured them and returned them,
		# and they were dropped here, so only a script that failed ever showed
		# its STDERR. Printed as they came, to STDERR, and not with warn(),
		# which this file's fatal warnings would make a death after the figure
		# was written.
		my $stderr = run_script( [ @python, $fh->filename ] );
		print STDERR $stderr if ( defined $stderr ) && ( length $stderr );
		say 'will write ' . "\e[36;103m$args->{output_file}\e[0m" if defined $args->{output_file};
	} else { # not running yet
		say 'will write ' . "\e[36;103m$args->{output_file}\e[0m" if defined $args->{output_file};
	}
	return $fh->filename;
}
sub venn_proportional_area_helper {
	my ($args) = @_;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1]
	; # https://stackoverflow.com/questions/2559792/how-can-i-get-the-name-of-the-current-subroutine-in-perl
	if ( ref $args ne 'HASH' ) {
		die "args must be given as a hash ref, e.g. \"$current_sub({ data => \@blah })\"";
	}
	my @reqd_args = (
		'ax',   # e.g. 0, 1, 2 ... the subplot index, passed in by plt
		'fh',   # the File::Temp filehandle, passed in by plt
		'plot', # the per-plot args from the caller
	);
	my @undef_args = grep { !defined $args->{$_} } @reqd_args;
	if ( scalar @undef_args > 0 ) {
		p @undef_args;
		die 'the above args are necessary, but were not defined.';
	}
	my @opt = (@ax_methods, @plt_methods, @fig_methods, @arg, 'ax', @{ $opt{$current_sub} });
	my $plot      = $args->{plot};
	my @undef_opt = grep {
		my $key = $_;
		not grep { $_ eq $key } @opt
	} keys %{$plot};
	if ( scalar @undef_opt > 0 ) {
		bad_keyword_error({
			bad       => \@undef_opt,
			accepted  => \@opt,
			preferred => $opt{$current_sub},
			type      => $plot->{plot_type},
			sub       => $current_sub
		});
	}
	# Each of these died as Perl's own error, or as a Python traceback, naming
	# no option: "Not a HASH reference" for array data, and below, "Can't use
	# string as an ARRAY ref" for a string "set_colors".
	if ( ref $plot->{data} ne 'HASH' ) {
		die "$current_sub takes a hash of sets, one array of members per set, e.g. { A => [1, 2], B => [2, 3] }, not "
		 . ( ref $plot->{data} ? 'a ' . ref( $plot->{data} ) . ' reference' : 'a scalar' );
	}
	# matplotlib_venn only draws area-proportional diagrams for 2 or 3 sets
	my $n_keys = scalar keys %{ $plot->{data} };
	if ( ( $n_keys != 2 ) && ( $n_keys != 3 ) ) {
		p $plot->{data};
		die "$current_sub only takes 2 or 3 sets of data.";
	}
	foreach my $key ( keys %{ $plot->{data} } ) {
		if ( ref $plot->{data}{$key} ne 'ARRAY' ) {
			p $plot->{data};
			die "\"$key\" must be an array reference in $current_sub";
		}
		if ( grep { !defined } @{ $plot->{data}{$key} } ) {
			p $plot->{data}{$key}, array_max => scalar @{ $plot->{data}{$key} };
			die "\"$key\" has undefined values in $current_sub, there may be undefined values in other keys";
		}
	}
	my @keys;
	if ( defined $plot->{key_order} ) {
		@keys = check_key_order({
			keys   => $plot->{key_order},
			data   => $plot->{data},
			option => 'key_order',
			sub    => $current_sub
		});
		if ( scalar @keys != $n_keys ) {
			p $plot;
			die "\"key_order\" has " . scalar(@keys) . " keys, but data has $n_keys in $current_sub";
		}
	} else {
		@keys = sort keys %{ $plot->{data} };
	}
	# The import is emitted at the point of use; a duplicate "from matplotlib_venn
	# import ..." across several subplots is harmless in Python.
	say { $args->{fh} } "from matplotlib_venn import venn$n_keys";
	my $ax = $args->{ax} // '';
	my @sets;
	foreach my $i ( 0 .. $#keys ) { # "each @array" requires perl 5.12
		my $key  = $keys[$i];
		my $name = "venn_ax${ax}_set$i";
		say { $args->{fh} } "$name = set(["
		. py_list( @{ $plot->{data}{$key} } ) . '])';
		push @sets, $name;
	}
	my $opt = '';
	if ( defined $plot->{set_colors} ) {
		# One color per set, which matplotlib_venn reads by position; a list of
		# any other length was a TypeError from inside it.
		if ( ( ref $plot->{set_colors} ne 'ARRAY' ) || ( scalar @{ $plot->{set_colors} } != $n_keys ) ) {
			die "\"set_colors\" is an array of one color per set in $current_sub, and there are $n_keys sets";
		}
		$opt .= ', set_colors=(' . py_list( @{ $plot->{set_colors} } ) . ')';
	}
	if ( defined $plot->{alpha} ) {
		check_numbers( [ $plot->{alpha} ], '"alpha"', $current_sub );    # written bare, so a word was a NameError
		$opt .= ", alpha=" . py_num( $plot->{alpha} );
	}
	say { $args->{fh} } "venn$n_keys(["
	. join( ',', @sets ) . '],('
	. py_list(@keys) . "), ax=ax$ax$opt)";
}
1;
