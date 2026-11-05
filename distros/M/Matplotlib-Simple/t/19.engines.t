#!/usr/bin/env perl
#
# The front end's part in choosing what draws a figure, added in 0.33 along
# with the gnuplot and ggplot2 engines: "engine" and "style", check_engine's
# refusals, and the readers that turn matplotlib's conventions for a value --
# text that may be Python, a color by matplotlib's name, set_xlim's arguments,
# a colormap -- into something any engine can write.
#
# The wrappers report an error as plt's, since that is the sub that finds it:
# "bar( engine => 'gnuplott' )" dies as "plt: ...".
#
# Nothing here runs an engine: each figure is written with "execute => 0", or
# a reader is called directly, so this file needs no Python, gnuplot or R, and
# runs in full on a Windows smoker, which has none of them. Each engine's own
# drawing is tested in t/17.gnuplot.t and t/18.ggplot2.t, and matplotlib's
# everywhere else.
#
# The expected colors are matplotlib 3.11.2's, which lib/Matplotlib/Simple/Colors.pm was
# generated from (see make.colors.pl): "tab:blue" is matplotlib's #1f77b4, "C3"
# its #d62728, and viridis runs from #440154 to #fde725.
require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
use Test::More;
binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);

my $TMP = tempdir( CLEANUP => 1 );
sub outfile { File::Spec->catfile( $TMP, $_[0] ) }
# The error a call dies with, its first line only, without the " at FILE line N."
# that Devel::Confess and die add.
sub error_of {
	my ($call) = @_;
	my $ok;
	capture { $ok = eval { $call->(); 1 } };    # a "return" inside capture{} would leave only the block
	return '' if $ok;
	( my $died = "$@" ) =~ s/\n.*\z//s;
	$died =~ s/ at \S+ line \d+\.?\z//;
	return $died;
}
# The script a call writes, read back as text.
sub script_of {
	my (%args) = @_;
	my $file;
	capture { $file = plt( execute => 0, %args ) };
	open my $in, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
	local $/;
	return scalar <$in>;
}

# ----------------------------------------------------------------------------
# 1. "engine" picks the engine, and anything else is refused, naming them.
# ----------------------------------------------------------------------------
{
	like( script_of( plot_type => 'bar', data => { A => 1 }, output_file => outfile('e1.svg') ), qr/^import matplotlib\.pyplot as plt$/m, 'no "engine": matplotlib draws it' );
	like( script_of( plot_type => 'bar', data => { A => 1 }, output_file => outfile('e2.svg'), engine => 'matplotlib' ), qr/^import matplotlib\.pyplot as plt$/m, 'engine => "matplotlib" is the default, named' );
	unlike( script_of( plot_type => 'bar', data => { A => 1 }, output_file => outfile('e3.svg'), engine => 'gnuplot' ), qr/matplotlib\.pyplot/, 'engine => "gnuplot" writes no Python' );
	unlike( script_of( plot_type => 'bar', data => { A => 1 }, output_file => outfile('e4.svg'), engine => 'ggplot2' ), qr/matplotlib\.pyplot/, 'engine => "ggplot2" writes no Python' );
	is( error_of( sub { bar( output_file => outfile('e5.svg'), data => { A => 1 }, engine => 'gnuplott', execute => 0 ) } ),
		'plt: "engine" is one of "ggplot2", "gnuplot", "matplotlib", not "gnuplott"', 'a misspelled engine is refused, naming the engines there are' );
	is( error_of( sub { bar( output_file => outfile('e6.svg'), data => { A => 1 }, engine => ['gnuplot'], execute => 0 ) } ),
		'plt: "engine" is one of "ggplot2", "gnuplot", "matplotlib", not a ARRAY reference', 'so is a reference' );
}

# ----------------------------------------------------------------------------
# 2. "engine" and "style" belong to the whole figure, not to a subplot.
# ----------------------------------------------------------------------------
{
	foreach my $choice ( [ engine => 'gnuplot' ], [ style => 'native' ] ) {
		my ( $key, $value ) = @{$choice};
		like( error_of( sub { plt( output_file => outfile('s.svg'), execute => 0, plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'bar', data => { B => 1 }, $key => $value } ] ) } ),
			qr/^plt: "$key" at subplot 1: one engine draws the whole figure in one style/, "\"$key\" in a subplot is refused, naming the subplot" );
		like( error_of( sub { plt( output_file => outfile('s.svg'), execute => 0, p => [ { plot_type => 'bar', data => { A => 1 }, $key => $value } ] ) } ),
			qr/^plt: "$key" at subplot 0:/, "and in a subplot given through \"p\"" );
		like( error_of( sub { bar( output_file => outfile('s.svg'), execute => 0, data => { A => 1 }, add => [ { plot_type => 'bar', data => { B => 1 }, $key => $value } ] ) } ),
			qr/^plt: "$key" in an "add" graph: one engine draws the whole figure in one style/, "and in an \"add\" graph" );
	}
	unlike( script_of( output_file => outfile('s2.svg'), engine => 'gnuplot', plots => [ { plot_type => 'bar', data => { A => 1 } } ] ), qr/matplotlib\.pyplot/, 'beside "plots", "engine" is the whole figure\'s' );
}

# ----------------------------------------------------------------------------
# 3. "style" is "native", the default, or "matplotlib"; matplotlib draws the
# same for both.
# ----------------------------------------------------------------------------
# "style" was on the list of pyplot methods until 0.33, and wrote plt.style(...),
# which raised "TypeError: 'module' object is not callable": plt.style is a
# module. No figure that drew can have used it.
{
	my %bar = ( plot_type => 'bar', data => { A => 1, B => 2 } );
	my $default = script_of( %bar, output_file => outfile('m.svg') );
	my $native  = script_of( %bar, output_file => outfile('m.svg'), style => 'native' );
	my $named   = script_of( %bar, output_file => outfile('m.svg'), style => 'matplotlib' );
	is( $native, $default, 'matplotlib: style => "native" writes the script the default does' );
	is( $named,  $default, 'and so does style => "matplotlib", named' );
	unlike( $default, qr/plt\.style\(/, 'no plt.style() call is written' );
	# Every other engine's default is its own style, "native", as matplotlib's
	# is. A hist is drawn differently in the two styles by both engines.
	my %hist = ( plot_type => 'hist', data => { A => [ 1, 2, 2, 3 ] }, output_file => outfile('h.svg') );
	foreach my $engine ( 'gnuplot', 'ggplot2' ) {
		my ( $none, $own, $mpl ) = map { ( my $script = script_of( %hist, engine => $engine, @{$_} ) ) =~ s/\A[^\n]*\n//; $script } ( [], [ style => 'native' ], [ style => 'matplotlib' ] );    # line 1 is the creator note
		is( $none, $own, "$engine: no style writes what style => \"native\" writes" );
		isnt( $none, $mpl, "$engine: and not what style => \"matplotlib\" writes" );
	}
	like( error_of( sub { bar( output_file => outfile('m.svg'), data => { A => 1 }, style => 'ggplot', execute => 0 ) } ),
		qr/^plt: "style" is one of "matplotlib", .*; "native", .*; not "ggplot"/, 'any other style is refused, saying what each one is' );
}

# ----------------------------------------------------------------------------
# 4. check_engine refuses by name what an engine does not draw.
# ----------------------------------------------------------------------------
# Every engine but matplotlib lists what it draws, and an engine that met a
# keyword it had no counterpart for could only have left it out of the figure.
{
	my $err = error_of( sub { plt( engine => 'gnuplot', output_file => outfile('c.svg'), execute => 0, plot_type => 'hexbin', data => { x => [ 1, 2 ], y => [ 3, 4 ] } ) } );
	like( $err, qr/^plt: the gnuplot engine does not draw plot_type "hexbin"\./, 'a type the engine does not draw is refused by name' );
	like( $err, qr/engine => 'matplotlib', the default, draws all of it$/, 'and the message says which engine does' );
	$err = error_of( sub { plt( engine => 'ggplot2', output_file => outfile('c.svg'), execute => 0, plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] }, set_options => { A => 'marker = "o"' } ) } );
	like( $err, qr/does not draw "set_options" for plot_type "plot"/, '"set_options", which is matplotlib\'s Python, is refused by name' );
	$err = error_of( sub { plt( engine => 'gnuplot', output_file => outfile('c.svg'), execute => 0, plots => [ { plot_type => 'bar', data => { A => 1 } }, { plot_type => 'venn_proportional_area', data => { A => [1], B => [2] } } ], ncols => 2 ) } );
	like( $err, qr/plot_type "venn_proportional_area" at subplot 1/, 'a subplot is named by its index' );
	$err = error_of( sub { plt( engine => 'gnuplot', output_file => outfile('c.svg'), execute => 0, plots => [ { plot_type => 'bar', data => { A => 1 } } ], sharex => 1 ) } );
	like( $err, qr/"sharex" for the figure/, 'a keyword of the figure is named as the figure\'s' );
	$err = error_of( sub { plt( engine => 'gnuplot', output_file => outfile('c.svg'), execute => 0, plot_type => 'bar', data => { A => 1 }, add => [ { plot_type => 'hexbin', data => { x => [1], y => [2] } } ] ) } );
	like( $err, qr/plot_type "hexbin" for an "add" graph/, 'and an "add" graph as an "add" graph' );
	is( error_of( sub { bar( engine => 'gnuplot', output_file => outfile('c.svg'), execute => 0, data => { A => 1 } ) } ), '', 'a plot the engine draws whole is not refused, nrows and ncols included' );
	# "show" is refused, but not when it asks for nothing: a program written
	# for matplotlib that passes "show => 0" was refused under any other engine.
	foreach my $engine ( 'gnuplot', 'ggplot2' ) {
		foreach my $no ( 0, "'False'" ) {
			is( error_of( sub { bar( engine => $engine, output_file => outfile('c.svg'), execute => 0, data => { A => 1 }, show => eval $no ) } ), '', "$engine: show => $no is not refused" );
		}
		is( error_of( sub { plt( engine => $engine, output_file => outfile('c.svg'), execute => 0, show => 0, plots => [ { plot_type => 'bar', data => { A => 1 } } ] ) } ), '', "$engine: nor beside \"plots\"" );
		like( error_of( sub { bar( engine => $engine, output_file => outfile('c.svg'), execute => 0, data => { A => 1 }, show => 1 ) } ), qr/does not draw "show"/, "$engine: show => 1 is" );
	}
}

# ----------------------------------------------------------------------------
# 5. plain_text reads text as matplotlib would show it.
# ----------------------------------------------------------------------------
# Text that Matplotlib::Simple::Matplotlib's quote_text would leave as Python is read as
# Python, and anything else is the words as given.
{
	my %shown = (
		'Plain words'               => 'Plain words',
		q{"Two groups, mean and s.d."} => 'Two groups, mean and s.d.',
		q{'it\'s'}                  => q{it's},
		q{"Bob's"}                  => q{Bob's},
		q{'a\nb \u03c1 \x41'}       => "a\nb ρ A",
		q{r'C:\new'}                => q{C:\new},
		q{'C:\\\\new'}              => q{C:\new},
		q{'Tis the season}          => q{'Tis the season},
		q{"A" vs "B"}               => q{"A" vs "B"},
		q{$\alpha$}                 => q{$\alpha$},
		# Python 3.14's own readings of the same literals: octal escapes of
		# one to three digits, a character by its name in any case, and a
		# name it does not know left as written.
		q{"line\012two"}           => "line\ntwo",
		q{"\101\x42\u0043"}         => 'ABC',
		q{"a\0b"}                  => "a\0b",
		q{"\N{GREEK SMALL LETTER ALPHA}"} => "\x{3b1}",
		q{"\N{greek small letter beta}"}  => "\x{3b2}",
		q{"\N{NO SUCH NAME}"}       => q{\N{NO SUCH NAME}},
		q{"one argument", }         => 'one argument',    # Python takes the trailing comma
	);
	foreach my $text ( sort keys %shown ) {
		is( Matplotlib::Simple::plain_text( $text, 'title', 'gnuplot', 'plt' ), $shown{$text}, "plain_text: $text" );
	}
	like( error_of( sub { Matplotlib::Simple::plain_text( q{"Counts", fontsize = 20}, 'title', 'gnuplot', 'plt' ) } ), qr/^plt: "title" is given matplotlib's arguments, fontsize = 20 after its text/, 'a literal followed by matplotlib\'s arguments is refused' );
	like( error_of( sub { Matplotlib::Simple::plain_text( q{label = "x", loc = "left"}, 'title', 'ggplot2', 'plt' ) } ), qr/^plt: "title" is given as matplotlib's keyword arguments/, 'and so are keyword arguments alone' );
	like( error_of( sub { Matplotlib::Simple::plain_text( q{f'{x}'}, 'xlabel', 'gnuplot', 'plt' ) } ), qr/^plt: "xlabel" is a Python f-string/, 'and an f-string, which only Python can fill in' );
}

# ----------------------------------------------------------------------------
# 6. axis_limits and axis_scale read set_xlim's and xscale's arguments.
# ----------------------------------------------------------------------------
{
	my @cases = ( [ '0, 10', [ 0, 10 ] ], [ '(None, 5)', [ undef, 5 ] ], [ '[-1.5,1.5]', [ -1.5, 1.5 ] ], [ [ 1, 2 ], [ 1, 2 ] ] );
	foreach my $case (@cases) {
		my ( $given, $ends ) = @{$case};
		is_deeply( [ Matplotlib::Simple::axis_limits( $given, 'set_xlim', 'gnuplot', 'plt' ) ], $ends, 'axis_limits: ' . ( ref $given ? "[ @{$given} ]" : $given ) );
	}
	foreach my $bad ( 'right = 180', '0, inf', '0', [ 1, 2, 3 ] ) {
		like( error_of( sub { Matplotlib::Simple::axis_limits( $bad, 'set_xlim', 'gnuplot', 'plt' ) } ), qr/^plt: "set_xlim" is two finite numbers for the gnuplot engine/, 'axis_limits refuses ' . ( ref $bad ? 'an array of 3' : "\"$bad\"" ) );
	}
	is( Matplotlib::Simple::axis_scale( q{'log'}, 'xscale', 'gnuplot', 'plt' ), 'log', 'axis_scale: a quoted "log"' );
	is( Matplotlib::Simple::axis_scale( 'linear', 'yscale', 'gnuplot', 'plt' ), 'linear', 'axis_scale: "linear"' );
	like( error_of( sub { Matplotlib::Simple::axis_scale( 'symlog', 'yscale', 'ggplot2', 'plt' ) } ), qr/^plt: "yscale" is "log" or "linear" for the ggplot2 engine, not "symlog"/, 'axis_scale refuses a scale only matplotlib has' );
}

# ----------------------------------------------------------------------------
# 7. color_hex and colormap_colors use matplotlib's names and values.
# ----------------------------------------------------------------------------
{
	my %hex = (
		'red' => '#ff0000', 'Red' => '#ff0000', 'tab:blue' => '#1f77b4', 'C3' => '#d62728', 'k' => '#000000',
		'#abc' => '#aabbcc', '#11223380' => '#11223380', '#112233ff' => '#112233', '0.5' => '#808080',
		'(1, 0, 0, 0.5)' => '#ff000080', q{'navy'} => '#000080',
	);
	foreach my $color ( sort keys %hex ) {
		is( Matplotlib::Simple::color_hex( $color, '"color"', 'gnuplot', 'plt' ), $hex{$color}, "color_hex: $color" );
	}
	is( Matplotlib::Simple::color_hex( [ 0, 1, 0 ], '"color"', 'gnuplot', 'plt' ), '#00ff00', 'color_hex: an RGB array' );
	foreach my $bad ( 'xkcd:sky blue', 'notacolor', '1.5', [ 2, 0, 0 ] ) {
		like( error_of( sub { Matplotlib::Simple::color_hex( $bad, '"color"', 'ggplot2', 'plt' ) } ), qr/^plt: "color" is not a color the ggplot2 engine knows/, 'color_hex refuses ' . ( ref $bad ? 'an RGB array out of range' : "\"$bad\"" ) );
	}
	my @viridis = Matplotlib::Simple::colormap_colors( 'viridis', 'gnuplot', 'plt' );
	is_deeply( [ @viridis[ 0, -1 ] ], [ '#440154', '#fde725' ], 'colormap_colors: viridis, low end first' );
	is_deeply( [ Matplotlib::Simple::colormap_colors( 'viridis_r', 'gnuplot', 'plt' ) ], [ reverse @viridis ], 'and "_r" reverses it' );
	like( error_of( sub { Matplotlib::Simple::colormap_colors( 'vridis', 'gnuplot', 'plt' ) } ), qr/^plt: "cmap" "vridis" is not a colormap the gnuplot engine has; it has .*viridis/, 'an unknown colormap is refused, listing the ones there are' );
}

# ----------------------------------------------------------------------------
# 8. Every module of the distribution carries Matplotlib::Simple's version.
# ----------------------------------------------------------------------------
# dist.ini takes the version from lib/Matplotlib/Simple.pm, and PAUSE indexes each
# package by its own $VERSION, so one left behind at a release is indexed as
# older than the distribution that ships it.
{
	require Matplotlib::Simple::Colors;
	require Matplotlib::Simple::Gnuplot;
	require Matplotlib::Simple::Ggplot2;
	no strict 'refs';
	foreach my $module ( 'Matplotlib::Simple::Colors', 'Matplotlib::Simple::Ggplot2', 'Matplotlib::Simple::Gnuplot', 'Matplotlib::Simple::Matplotlib' ) {
		is( ${"${module}::VERSION"}, $Matplotlib::Simple::VERSION, "$module is version $Matplotlib::Simple::VERSION, as Matplotlib::Simple is" );
	}
}

# ----------------------------------------------------------------------------
# 9. A script's name does not repeat under a caller's fixed seed.
# ----------------------------------------------------------------------------
# File::Temp names a file from rand(), and the scripts are kept, so a program
# that began with "srand 7" asked for the same names on every run, and once
# enough runs had left their scripts behind File::Temp died: "Have exceeded
# the maximum number of attempts (1000) to open temp file".
{
	my @names;
	foreach my $engine ( 'matplotlib', 'gnuplot' ) {
		srand 7;
		my $file;
		capture { $file = bar( output_file => outfile('seed.svg'), data => { A => 1 }, execute => 0, engine => $engine ) };
		push @names, ( File::Spec->splitpath($file) )[2];
	}
	srand();    # this file's later calls to rand() owe nothing to the 7
	like( $names[0], qr/^matplotlib-simple-$$-\d+-\d+-\w{6}\.py\z/, 'a script is named by the process, the time and a count, ahead of the random part' );
	( my $first = $names[0] ) =~ s/-\w{6}\.py\z//;
	( my $second = $names[1] ) =~ s/-\w{6}\.gp\z//;
	isnt( $first, $second, 'and two scripts made under the same seed differ ahead of it' );
}

done_testing();
