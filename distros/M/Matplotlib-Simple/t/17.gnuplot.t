#!/usr/bin/env perl
#
# engine => 'gnuplot': lib/Matplotlib/Simple/Gnuplot.pm, one block per thing it must get
# right.
#
# Most of this is execute => 0 and reads the generated gnuplot script as text,
# so it runs everywhere, including a Windows smoker with no gnuplot: the option
# contract (what is drawn, and what is refused by name), the escaping of text
# and paths, and every shape of "data" each type takes.
#
# The render checks run the script, and need gnuplot 5.2 or newer, found as
# MATPLOTLIB_SIMPLE_GNUPLOT or "gnuplot", as the module finds it. 5.2 is where
# "reset session", which starts every figure, was added (gnuplot's NEWS for
# 5.2.0); the rest of what the scripts use -- datablocks, "set offsets graph",
# "set link", transparent fills and the noenhanced svg, pngcairo and pdfcairo
# terminals -- is from 5.0 or before. style => 'native' adds nothing newer: its
# "bins" filter is also 5.2 ('NEW data filter "bins"', NEWS for 5.2.0), and
# "set table $datablock" is 5.0, "with boxplot" 4.6 (both NEWS). That is read
# from gnuplot's release notes, not measured: only gnuplot 6.0 patchlevel 0
# has been run against these scripts. Without it, the render checks skip.
#
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
my $seq = 0;

my $GP = ( defined $ENV{MATPLOTLIB_SIMPLE_GNUPLOT} && length $ENV{MATPLOTLIB_SIMPLE_GNUPLOT} ) ? $ENV{MATPLOTLIB_SIMPLE_GNUPLOT} : 'gnuplot';
my ( $gp_out, $gp_err, $gp_status ) = capture {
	no warnings 'exec';    # a missing gnuplot is a skip, not a failure
	system( $GP, '--version' );
};
my $gp_available = 0;
if ( ( $gp_status == 0 ) && ( $gp_out =~ m/^gnuplot\s+(\d+)\.(\d+)/ ) ) {
	$gp_available = ( $1 > 5 || ( $1 == 5 && $2 >= 2 ) ) ? 1 : 0;
}
diag( $gp_available ? "gnuplot >= 5.2 found as \"$GP\" (render checks ON)" : 'no gnuplot >= 5.2 (render checks skipped)' );

sub out_file { return File::Spec->catfile( $TMP, 'gen' . $seq++ . ( $_[0] // '.svg' ) ) }

sub slurp {
	my ($file) = @_;
	open my $in, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return $text;
}

# Build one figure with execute => 0 and return the generated script as text.
# In style "matplotlib" unless the spec names a style, as most blocks check
# what matplotlib draws; "style => undef" leaves plt to choose its default.
sub gen {
	my (%spec) = @_;
	$spec{style} = 'matplotlib' unless exists $spec{style};
	$spec{output_file} //= out_file();
	$spec{execute} = 0;
	$spec{engine}  = 'gnuplot';
	my ( $out, $err, $file ) = capture { plt( \%spec ) };
	return ( slurp($file), $file );
}

# Only the message, never the Devel::Confess trace that follows it, is matched.
sub dies_with {
	my ( $spec, $like, $name ) = @_;
	my ( $out, $err ) = capture { eval { gen( %{$spec} ) } };
	my $message = "$@";
	return ok( 0, "$name (did not die)" ) unless length $message;
	$message =~ s/\n\t.*\z//s;
	like( $message, $like, $name ) or diag("  died: $message");
	return;
}

sub lives {
	my ( $spec, $name ) = @_;
	my ( @r, $died );
	capture { $died = eval { @r = gen( %{$spec} ); 1 } ? '' : "$@" };
	$died =~ s/\n\t.*\z//s;
	ok( !length $died, $name ) or diag("  died: $died");
	return @r;
}

# Well-formed XML, by a stack of tag names: enough to catch an SVG that gnuplot
# left unfinished or wrote text into unescaped, with no XML module, which a
# smoker may not have.
sub well_formed {
	my ($xml) = @_;
	$xml =~ s/<!--.*?-->//gs;
	$xml =~ s/<!\[CDATA\[.*?\]\]>//gs;
	$xml =~ s/<\?.*?\?>//gs;
	$xml =~ s/<!DOCTYPE[^>]*>//s;
	my @stack;
	while ( $xml =~ m{<(/?)([A-Za-z_][\w:.-]*)((?:[^>"']|"[^"]*"|'[^']*')*?)(/?)>}g ) {
		my ( $close, $name, $self ) = ( $1, $2, $4 );
		next if $self;
		if ($close) {
			return 0 unless @stack && ( pop(@stack) eq $name );
		} else {
			push @stack, $name;
		}
	}
	( my $text = $xml ) =~ s/<[^>]*>//g;
	return 0 if $text =~ m/&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/;    # a bare & is not XML
	return ( scalar @stack == 0 ) && ( $xml =~ m/<svg\b/ ) ? 1 : 0;
}

# Render a figure, returning its SVG; the caller has skipped without gnuplot.
# In style "matplotlib" unless the spec names a style, as gen is.
sub render {
	my (%spec) = @_;
	my $file = out_file();
	my ( $out, $err, $ok ) = capture { eval { plt( style => 'matplotlib', %spec, engine => 'gnuplot', output_file => $file ); 1 } };
	if ( not $ok ) {
		( my $died = "$@" ) =~ s/\n\t.*\z//s;
		diag("  died: $died");
	}
	return ( -e $file ) ? slurp($file) : '';
}

srand 7;    # the same figures every run
sub normal { my ( $m, $s, $n ) = @_; return [ map { sprintf '%.4f', $m + $s * sqrt( -2 * log( 1 - rand ) ) * cos( 6.283185307 * rand ) } 1 .. $n ] }
my @x = map { $_ / 10 } 0 .. 30;
# One figure of each type, in each of its shapes of "data".
my %figure = (
	'bar, one bar per key'       => { plot_type => 'bar', data => { Matthew => 18345, Mark => 11304, Luke => 19482, John => 15635 } },
	'barh, one bar per key'      => { plot_type => 'barh', data => { A => 3, B => 5 } },
	'bar, a hash of arrays'      => { plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, label => [ 'one', 'two' ] },
	'bar, a hash of hashes'      => { plot_type => 'bar', data => { A => { x => 1, y => 2 }, B => { x => 3, y => 4 } } },
	'barh, stacked'              => { plot_type => 'barh', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, stacked => 1 },
	'boxplot, a hash'            => { plot_type => 'boxplot', data => { A => normal( 0, 1, 50 ), B => normal( 1, 1, 50 ) } },
	'boxplot, an array'          => { plot_type => 'boxplot', data => normal( 0, 1, 50 ), orientation => 'horizontal' },
	'colored_table'              => { plot_type => 'colored_table', data => { H => { H => 432, Cl => 427 }, C => { H => 413 } }, show_numbers => 1 },
	'hist, a hash'               => { plot_type => 'hist', data => { A => normal( 0, 1, 100 ), B => normal( 2, 1, 100 ) } },
	'hist, an array'             => { plot_type => 'hist', data => normal( 0, 1, 100 ), bins => 5 },
	'hist2d'                     => { plot_type => 'hist2d', data => { E => normal( 0, 1, 300 ), N => normal( 0, 1, 300 ) } },
	'imshow, numbers'            => { plot_type => 'imshow', data => [ [ 1, 2, 3 ], [ 4, 5, 'nan' ] ] },
	'imshow, a stringmap'        => { plot_type => 'imshow', data => [ [ 'H', 'E' ], [ 'C', 'H' ] ], stringmap => { H => 'helix', E => 'strand', C => 'coil' } },
	'pie'                        => { plot_type => 'pie', data => { A => 1, B => 2, C => 3 }, autopct => '%1.1f%%' },
	'plot, one pair'             => { plot_type => 'plot', data => [ \@x, [ map { sin $_ } @x ] ] },
	'plot, an array of pairs'    => { plot_type => 'plot', data => [ [ \@x, [ map { sin $_ } @x ] ], [ \@x, [ map { cos $_ } @x ] ] ] },
	'plot, a hash of pairs'      => { plot_type => 'plot', data => { sin => [ \@x, [ map { sin $_ } @x ] ], y => [ 3, 1, 2 ] } },
	'scatter, two keys'          => { plot_type => 'scatter', data => { X => [ 1, 2, 3 ], Y => [ 3, 1, 2 ] } },
	'scatter, three keys'        => { plot_type => 'scatter', data => { X => [ 1, 2, 3 ], Y => [ 3, 1, 2 ], Z => [ 1, 5, 9 ] } },
	'scatter, sets of arrays'    => { plot_type => 'scatter', data => { A => { x => [ 1, 2 ], y => [ 2, 1 ] }, B => { x => [ 3, 4 ], y => [ 1, 3 ] } } },
	'scatter, sets of points'    => { plot_type => 'scatter', data => { A => { x => 1, y => 2 }, B => { x => 3, y => 1 } } },
	'violin'                     => { plot_type => 'violin', data => { A => normal( 0, 1, 60 ), B => normal( 1, 2, 60 ) } },
	'violinplot, horizontal'     => { plot_type => 'violinplot', data => normal( 0, 1, 60 ), orientation => 'horizontal' },
	'wide, a hash'               => { plot_type => 'wide', data => { G => [ [ \@x, [ map { sin $_ } @x ] ], [ \@x, [ map { 0.1 + sin $_ } @x ] ] ] } },
	'wide, an array'             => { plot_type => 'wide', data => [ [ \@x, [ map { cos $_ } @x ] ], [ \@x, [ map { 0.1 + cos $_ } @x ] ] ] },
);
# And a fresh seed for everything after: File::Temp names the scripts with rand,
# and the module keeps them, so with the seed above every run tried the same
# names, and once runs had left enough of them in the temporary directory
# File::Temp gave up: "Have exceeded the maximum number of attempts (1000) to
# open temp file".
srand();

# ----------------------------------------------------------------------------
# 1. Every type, in every shape of its data, is written as a whole figure.
# ----------------------------------------------------------------------------
foreach my $name ( sort keys %figure ) {
	my ($gp) = lives( { %{ $figure{$name} }, title => $name }, "$name: the script is written" );
	next unless defined $gp;
	like( $gp, qr/^reset session\n.*^set terminal svg .*^set output ".*^plot .*^unset output\n/ms, "$name: reset, terminal, output, plot and unset output, in that order" );
	like( $gp, qr/^set title "\Q$name\E"/m, "$name: the title is written" );
	like( $gp, qr/^\$d0 << EOD$/m, "$name: the data is in a datablock" );
}

# ----------------------------------------------------------------------------
# 2. Each keyword the engine declares reaches the script.
# ----------------------------------------------------------------------------
{
	my ($gp) = gen( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 3, 4 ] ] }, xlabel => 'time', set_ylabel => 'speed', set_xlim => '0, 10', ylim => '(None, 5)', yscale => 'log', suptitle => 'all', scale => 2 );
	like( $gp, qr/^set xlabel "time"$/m,  'xlabel' );
	like( $gp, qr/^set ylabel "speed"$/m, 'set_ylabel' );
	like( $gp, qr/^set xrange \[0:10\]$/m, 'set_xlim' );
	like( $gp, qr/^set yrange \[\*:5\]$/m, 'ylim, with None for an end left where it falls' );
	like( $gp, qr/^set logscale y$/m,      'yscale => "log"' );
	like( $gp, qr/^set multiplot layout 1,1 title "all"$/m, 'suptitle, as the title of a multiplot' );
	like( $gp, qr/^set terminal svg size 1280,960 /m, 'scale doubles matplotlib\'s 6.4 by 4.8 inches, at 100 pixels to the inch' );
	($gp) = gen( plot_type => 'bar', data => { A => 1, B => 2 }, color => { A => 'tab:orange', B => 'C2' }, yerr => { A => 0.1, B => [ 0.1, 0.3 ] }, scalex => 1.5 );
	like( $gp, qr/^0 0\.5 -0\.4 0\.4 0 1 16744206$/m, 'bar color by key, as matplotlib\'s tab:orange' );
	like( $gp, qr/^1 2 1\.9 2\.3$/m,             'yerr as a [ lower, upper ] pair' );
	like( $gp, qr/with yerrorbars/,               'yerr is drawn as error bars' );
	like( $gp, qr/^set terminal svg size 960,480 /m, 'scalex widens the figure alone' );
	($gp) = gen( plot_type => 'scatter', data => { X => [ 1, 2 ], Y => [ 2, 1 ], Z => [ 1, 3 ] }, cmap => 'viridis_r', cb_logscale => 1, cblabel => 'zed' );
	like( $gp, qr/^set palette defined \(0 "#fde725",/m, 'cmap, reversed with "_r"' );
	like( $gp, qr/^set logscale cb$/m,           'cb_logscale' );
	like( $gp, qr/^set cblabel "zed"$/m,          'cblabel' );
	like( $gp, qr/^set xlabel "X"$/m,             'scatter labels its axes with its keys' );
	($gp) = gen( plot_type => 'hist2d', data => { E => [ 1, 2, 3 ], N => [ 1, 2, 3 ] }, xbins => 2, ybins => 2, show_colorbar => 0, cb_min => 0, cb_max => 9 );
	like( $gp, qr/^unset colorbox$/m,             'show_colorbar => 0' );
	like( $gp, qr/^set cbrange \[0:9\]$/m,        'cb_min and cb_max' );
	is( scalar( () = $gp =~ m/^\S+ \S+ \S+ \S+ \S+ \S+ \d+$/mg ), 4, 'xbins => 2, ybins => 2 is 4 bins' );
	($gp) = gen( plot_type => 'boxplot', data => { A => [ 1, 2, 3, 4, 100 ] }, showfliers => 0, showmeans => 'False', colors => { A => 'red' } );
	unlike( $gp, qr/pt 6 /, 'showfliers => 0 draws no fliers' );
	unlike( $gp, qr/pt 9 /, 'showmeans => "False" draws no mean' );
	like( $gp, qr/ 16711680$/m, 'colors by key' );
	($gp) = gen( plot_type => 'bar', data => { A => 1, B => 100 }, log => 'True' );
	like( $gp, qr/^set logscale y$/m, 'log => "True" puts the bars on a log axis' );
	# matplotlib's range for 1 .. 100 on a log axis: 5% of the 2 decades either
	# side, 10 ** -0.1 to 10 ** 2.1. The bars started at 0.1 until 0.33, which
	# dragged the axis down a decade below matplotlib's.
	like( $gp, qr/^set yrange \[0\.794328234724281\d*:125\.89254117941\d*\]$/m, 'the log axis runs as far as matplotlib\'s, 5% of its decades past the bars' );
	like( $gp, qr/^0 \S+ -0\.4 0\.4 0\.794328234724281\d* 1 \d+$/m, 'and a bar of 1 starts at the foot of the axis, a sliver, as matplotlib draws it' );
	($gp) = gen( plot_type => 'pie', data => { A => 1, B => 3 }, autopct => '%.0f%%', labeldistance => 1.3 );
	like( $gp, qr/^set label "75%" at /m, 'autopct, formatted in Perl' );
	like( $gp, qr/^set label "A" at 0\.91923881554\d*,0\.91923881554\d* left front$/m, 'labeldistance' );
}

# ----------------------------------------------------------------------------
# 3. What the engine does not draw is refused by name, not left out.
# ----------------------------------------------------------------------------
{
	my %two = ( x => [ 1, 2 ], y => [ 2, 1 ] );
	dies_with( { plot_type => 'hexbin', data => \%two }, qr/the gnuplot engine does not draw plot_type "hexbin"/, 'hexbin is refused by name' );
	dies_with( { plot_type => 'venn_proportional_area', data => { A => [ 1, 2 ], B => [ 2, 3 ] } }, qr/does not draw plot_type "venn_proportional_area"/, 'venn_proportional_area is refused by name' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, edgecolor => 'k' }, qr/does not draw "edgecolor" for plot_type "bar"/, 'edgecolor is refused, naming the type' );
	dies_with( { plot_type => 'plot', data => { A => [ [1], [2] ] }, set_options => 'marker = "o"' }, qr/"set_options"/, 'set_options, which is matplotlib\'s python, is refused' );
	dies_with( { plot_type => 'plot', data => { A => [ [1], [2] ] }, legend => 'loc = "upper left"' }, qr/"legend"/, 'legend, whose value is matplotlib\'s python, is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, title => '"Counts", fontsize = 20' }, qr/"title" is given matplotlib's arguments, fontsize = 20 after its text/, 'a title with matplotlib\'s arguments is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, title => q{f'{n} counts'} }, qr/"title" is a Python f-string/, 'an f-string title is refused' );
	dies_with( { plot_type => 'imshow', data => [ [1] ], cmap => 'nipy_spectral' }, qr/"cmap" "nipy_spectral" is not a colormap the gnuplot engine has/, 'a colormap it has no table for is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, color => 'xkcd:sky blue' }, qr/"color" is not a color the gnuplot engine knows: "xkcd:sky blue"/, 'an xkcd color is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, output_file => out_file('.jpg') }, qr/the gnuplot engine writes \.pdf, \.png, \.svg files/, 'an output format it has no terminal for is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, xerr => 1 }, qr/draws "xerr" on a barh plot but not on bar/, 'xerr on a bar is refused' );
	dies_with( { plot_type => 'bar', data => { A => [ 1, 2 ] }, yerr => 1 }, qr/"yerr" only for a bar plot of one bar per key/, 'error bars on grouped bars are refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, set_xlim => 'right = 5' }, qr/"set_xlim" is two finite numbers for the gnuplot engine/, 'set_xlim as keyword arguments is refused' );
	dies_with( { plot_type => 'bar', data => { A => 1 }, show => 1 }, qr/does not draw "show"/, 'show is refused' );
	dies_with( { plot_type => 'pie', data => { A => 1 }, autopct => 'lambda p: p' }, qr/"autopct" is a format with one number in it/, 'autopct as python is refused' );
	dies_with( { plots => [ { plot_type => 'pie', data => { A => 1 }, add => [ { plot_type => 'bar', data => { A => 1 } } ] } ] }, qr/draws plot_type "pie" on axes of its own/, 'a pie cannot take an "add" graph' );
	dies_with( { plot_type => 'violin', data => { A => [ 1, 1, 1 ] } }, qr/"A" has no spread/, 'a violin of one repeated value is refused by name' );
	dies_with( { plots => [ { plot_type => 'bar', data => { A => 1 } } ], sharex => 1 }, qr/does not draw "sharex" for the figure/, 'sharex is refused at the top of a figure' );
}

# ----------------------------------------------------------------------------
# 4. Text and paths are escaped, and read as given.
# ----------------------------------------------------------------------------
{
	my $key = qq{Bob's "x" \\n @ & ^ _ {ρ}};
	my ($gp) = gen( plot_type => 'bar', data => { $key => 1, "two\nlines" => 2 }, title => 'a\b', xlabel => q{'it\'s'} );
	like( $gp, qr/^set xtics \("Bob's \\"x\\" \\\\n \@ & \^ _ \{ρ\}" 0, "two\\nlines" 1\)$/m, 'a key with quotes, a backslash, gnuplot\'s enhanced-text characters and a newline' );
	like( $gp, qr/^set title "a\\\\b" font/m, 'a backslash in a title is doubled' );
	like( $gp, qr/^set xlabel "it's"$/m, 'a python literal is read as the text it holds' );
	like( $gp, qr/^set terminal svg .* noenhanced /m, 'the terminal is noenhanced, so "@", "^", "_" and "{" read as given' );
	($gp) = gen( plot_type => 'bar', data => { A => 1 }, output_file => q{C:\new\x's dir\out.svg} );
	like( $gp, qr/^set output "C:\\\\new\\\\x's dir\\\\out\.svg"$/m, 'a Windows path with an apostrophe arrives whole' );
	unlike( $gp, qr/^[^#]*C:\\new/m, 'and no backslash is left single, outside the comment' );
}

# ----------------------------------------------------------------------------
# 5. Numbers: NaN for anything not finite, and leading zeros dropped.
# ----------------------------------------------------------------------------
{
	my ($gp) = gen( plot_type => 'plot', data => [ [ 1, 2, 3, 4 ], [ '007', 'nan', 'inf', 2.5 ] ] );
	like( $gp, qr/^1 7\n2 NaN\n3 NaN\n4 2\.5\nEOD$/m, 'NaN and inf are NaN, a gap in the line; "007" is 7' );
}

# ----------------------------------------------------------------------------
# 6. Grids and overlays.
# ----------------------------------------------------------------------------
{
	my ($gp) = gen( plots => [ $figure{'pie'}, $figure{'hist, a hash'}, { %{ $figure{'scatter, two keys'} }, add => [ { plot_type => 'plot', data => [ [ 1, 3 ], [ 1, 3 ] ] } ] } ], ncols => 2, nrows => 2 );
	like( $gp, qr/^set multiplot layout 2,2$/m, 'plots => [...], ncols => 2, nrows => 2 is a 2 by 2 multiplot' );
	is( scalar( () = $gp =~ m/^plot /mg ), 3, 'one plot command per subplot' );
	is( scalar( () = $gp =~ m/^reset$/mg ), 3, 'and each subplot starts from gnuplot\'s defaults' );
	like( $gp, qr/^unset multiplot$/m, 'the multiplot is closed' );
	like( $gp, qr/with lines lw 1\.5 lc rgb "#1f77b4" notitle, \\\n\t\$d\d+ using 1:2 with points pt 7 [^\n]* lc rgb "#1f77b4"/, 'an "add" line is drawn first, and lines and points each start matplotlib\'s cycle at C0' );
}

# ----------------------------------------------------------------------------
# 7. Several figures through one "fh": each starts from a clean slate.
# ----------------------------------------------------------------------------
# README, "Advanced > Speed": one script can hold many figures, with execute
# => 0 on all but the last. gnuplot keeps every setting from one plot command
# to the next, so a figure that did not reset would draw with the last one's
# log scale, ranges, palette and labels.
{
	my $fh = File::Temp->new( DIR => $TMP, SUFFIX => '.gp', UNLINK => 1 );
	my @files = ( out_file(), out_file() );
	capture {
		plt( engine => 'gnuplot', fh => $fh, execute => 0, output_file => $files[0], plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 10 ] ] }, title => 'FIRST', yscale => 'log', set_xlim => '0, 99' );
		plt( engine => 'gnuplot', fh => $fh, execute => 0, output_file => $files[1], plot_type => 'bar', data => { B => 2 } );
	};
	close $fh;
	my $gp = slurp( $fh->filename );
	my @figures = split /^(?=# .* called using)/m, $gp;
	is( scalar @figures, 2, 'two figures in one script' );
	like( $figures[1] // '', qr/\A# [^\n]*\nreset session\n/, 'the second starts with "reset session"' );
	like( $figures[0], qr/^unset output\nprint sprintf\("Matplotlib::Simple gnuplot [^\n]*\n\z/m, 'the first ends with "unset output", closing its file, and then names the gnuplot that drew it' );
	unlike( $figures[1] // '', qr/FIRST|logscale y|\[0:99\]/, 'none of the first figure\'s settings is written into the second' );
	SKIP: {
		skip( 'no gnuplot >= 5.2', 3 ) unless $gp_available;
		my ( $out, $err, $status ) = capture { system( $GP, $fh->filename ) };
		is( $status, 0, 'the script of two figures runs' ) or diag("  gnuplot: $err");
		my $second = -e $files[1] ? slurp( $files[1] ) : '';
		ok( well_formed($second), 'the second figure is a whole SVG' );
		unlike( $second, qr/FIRST/, 'the second figure has no title from the first' );
	}
}

# ----------------------------------------------------------------------------
# 8. Rendered: every type, in every shape, is a well-formed SVG with its labels.
# ----------------------------------------------------------------------------
SKIP: {
	skip( 'no gnuplot >= 5.2', 3 * scalar( keys %figure ) + 4 ) unless $gp_available;
	foreach my $name ( sort keys %figure ) {
		my $svg = render( %{ $figure{$name} }, title => "$name & <more>" );
		ok( length $svg, "$name: an SVG is written" );
		ok( well_formed($svg), "$name: it is well-formed XML" );
		like( $svg, qr/\Q$name\E &amp; &lt;more(?:&gt;|>)/, "$name: the title is in it, escaped for XML (gnuplot leaves a \">\", which XML allows)" );
	}
	my $svg = render( plot_type => 'bar', data => { 'ρ τ' => 1, q{Bob's "x"} => 2 }, xlabel => 'a_b^c@d' );
	like( $svg, qr/ρ τ/, 'a non-ASCII key is drawn as written' );
	like( $svg, qr/Bob's (?:"|&quot;)x(?:"|&quot;)/, 'and a key with quotes' );
	like( $svg, qr/a_b\^c\@d/, 'and enhanced-text characters, as given' );
	my $file = File::Spec->catfile( $TMP, q{it's a dir} );
	mkdir $file or die "can't mkdir $file: $!";
	$file = File::Spec->catfile( $file, 'out.svg' );
	capture { plt( engine => 'gnuplot', plot_type => 'pie', data => { A => 1 }, output_file => $file ) };
	ok( ( -s $file ), 'a path with an apostrophe and a space is written to' );
}

# ----------------------------------------------------------------------------
# 9. style => 'native' is the default; 'matplotlib' has none of its constructs.
# ----------------------------------------------------------------------------
# The default style matches the engine: a figure given no style is drawn in
# gnuplot's own. The matplotlib style must still be asked for by name, and no
# native construct leaks into it.
foreach my $name ( 'bar, one bar per key', 'boxplot, a hash', 'hist, a hash', 'violin', 'scatter, three keys', 'colored_table', 'hist2d' ) {
	my ($default) = gen( %{ $figure{$name} }, output_file => '/same.svg', style => undef );
	my ($given)   = gen( %{ $figure{$name} }, output_file => '/same.svg', style => 'native' );
	my ($matplotlib) = gen( %{ $figure{$name} }, output_file => '/same.svg', style => 'matplotlib' );
	s/\A#[^\n]*\n// for $default, $given;    # the creator note names the call, which differs
	is( $given, $default, "$name: style => 'native' writes the same script as no style" );
	unlike( $matplotlib, qr/with boxplot|\bbins\b(?!=?\S* with boxxyerror)|kdensity|set key default|rgbformulae|set table/, "$name: and style => 'matplotlib' has nothing of style => 'native'" );
}

# ----------------------------------------------------------------------------
# 10. style => 'native': gnuplot computes, colors and lays out for itself.
# ----------------------------------------------------------------------------
{
	my %n = ( style => 'native' );
	my ($gp) = gen( %{ $figure{'boxplot, a hash'} }, %n );
	like( $gp, qr/\$d\d+ using \(1\):1 with boxplot lc rgb "#9400d3" notitle, \\\n\t\$d\d+ using \(2\):1 with boxplot lc rgb "#009e73" notitle$/m, 'boxplot: gnuplot\'s "with boxplot", one per set, in its linetype colors' );
	unlike( $gp, qr/with points/, 'boxplot: and no mean, which gnuplot\'s boxplot does not mark' );
	($gp) = gen( %{ $figure{'boxplot, a hash'} }, %n, showfliers => 0, showcaps => 0, showmeans => 1 );
	like( $gp, qr/^set style boxplot nooutliers$/m, 'boxplot: showfliers => 0 is "nooutliers"' );
	like( $gp, qr/^set errorbars 0$/m, 'boxplot: showcaps => 0 is no bars on the whiskers' );
	like( $gp, qr/^stats \$d\d+ using 1 name "box1" nooutput$/m, 'boxplot: showmeans => 1, the mean from gnuplot\'s stats' );
	like( $gp, qr/using \(1\):\(box1_mean\) with points/, 'boxplot: drawn at the box' );
	($gp) = gen( %{ $figure{'hist, a hash'} }, %n );
	like( $gp, qr/\$d\d+ using 1 bins=10 with boxes lc rgb "#9400d3" title "A"/m, 'hist: gnuplot\'s own "bins", 10 of them, as the ggplot2 engine draws' );
	unlike( $gp, qr/fs transparent/, 'hist: gnuplot\'s own fill, none, with no "alpha" given' );
	($gp) = gen( %{ $figure{'hist, an array'} }, %n, alpha => 0.4 );
	like( $gp, qr/using 1 bins=5 with boxes fs transparent solid 0\.4 lc rgb/, 'hist: bins => 5 and alpha => 0.4 are kept' );
	($gp) = gen( plot_type => 'hist', data => [ 0.5, 1, 1.5, 2.6 ], bins => [ 0, 1, 2, 3 ], %n );
	like( $gp, qr/using 1 bins binrange \[0\.5:2\.5\] binwidth=1 with boxes/, 'hist: even edges are the centers of the first and last bins, and their width' );
	($gp) = gen( %{ $figure{'violin'} }, %n );
	like( $gp, qr/^set table \$kd\d+\nplot \$d\d+ using 1:\(1\) smooth kdensity\nunset table$/m, 'violin: the density from gnuplot\'s "smooth kdensity", with its own bandwidth' );
	like( $gp, qr/with filledcurves x=1 /, 'violin: drawn as filled curves about its place' );
	like( $gp, qr/using \(1\):1:\(0\.08\) with boxplot/, 'violin: with a narrow boxplot for the whiskers and median' );
	($gp) = gen( %{ $figure{'scatter, three keys'} }, %n );
	like( $gp, qr/^set palette rgbformulae 7,5,15$/m, 'scatter colored by a key, with no cmap: gnuplot\'s own palette' );
	unlike( $gp, qr/ pt \d| ps /, 'scatter: gnuplot\'s own point type and size' );
	foreach my $name ( 'hist2d', 'colored_table', 'imshow, numbers' ) {
		($gp) = gen( %{ $figure{$name} }, %n );
		like( $gp, qr/^set palette rgbformulae 7,5,15$/m, "$name: gnuplot's own palette with no cmap" );
	}
	($gp) = gen( %{ $figure{'plot, a hash of pairs'} }, %n );
	like( $gp, qr/^set key default\nset key opaque$/m, 'the key where gnuplot puts it, opaque, so that no bar covers it' );
	like( $gp, qr/^set terminal svg size 640,480 dynamic noenhanced$/m, 'the terminal\'s own font and lines, at the same size, still noenhanced' );
	unlike( $gp, qr/^set (?:offsets|autoscale fix|tics out)/m, 'none of matplotlib\'s margins or tics' );
	like( $gp, qr/with lines lc rgb "#9400d3" title "sin", \\\n\t\$d\d+ using 1:2 with lines lc rgb "#009e73"/, 'plot: gnuplot\'s linetype colors and widths' );
	($gp) = gen( plot_type => 'bar', data => { A => 1, B => 100 }, log => 1, %n );
	like( $gp, qr/^0 \S+ -0\.4 0\.4 0\.1 1 \d+$/m, 'a log bar starts at the decade below, and gnuplot ranges the axis' );
	unlike( $gp, qr/^set yrange/m, 'with no range of matplotlib\'s' );
	($gp) = gen( %{ $figure{'colored_table'} }, %n );
	like( $gp, qr/:4 with labels center tc rgb variable/, 'colored_table: each number in white or black by its cell, since gnuplot\'s palette starts at black' );
	($gp) = gen( %{ $figure{'scatter, sets of arrays'} }, %n );
	like( $gp, qr/with points lc rgb "#9400d3" title "A", \\\n\t\$d\d+ using 1:2 with points lc rgb "#009e73" title "B"/, 'scatter: each set the next linetype, lines and points counted as one, as gnuplot counts them' );
}

# ----------------------------------------------------------------------------
# 11. What the caller gave survives style => 'native'.
# ----------------------------------------------------------------------------
{
	my %n = ( style => 'native' );
	my ($gp) = gen( plot_type => 'bar', data => { A => 1, B => 2 }, color => 'red', %n );
	like( $gp, qr/^0 0\.5 -0\.4 0\.4 0 1 16711680$/m, 'bar: color => "red"' );
	($gp) = gen( %{ $figure{'boxplot, a hash'} }, colors => { A => 'tab:orange', B => 'C2' }, %n );
	like( $gp, qr/with boxplot fs solid 1\.0 border lc rgb "black" lc rgb "#ff7f0e"/, 'boxplot: colors => { ... }, filled as matplotlib fills them' );
	($gp) = gen( %{ $figure{'hist, a hash'} }, color => { A => 'red', B => 'blue' }, %n );
	like( $gp, qr/lc rgb "#ff0000" title "A"/, 'hist: color => { ... }' );
	($gp) = gen( %{ $figure{'scatter, three keys'} }, cmap => 'viridis', %n );
	like( $gp, qr/^set palette defined \(0 "#440154",/m, 'scatter: cmap => "viridis"' );
	($gp) = gen( %{ $figure{'violin'} }, colors => { A => 'red', B => 'blue' }, edgecolor => 'black', %n );
	like( $gp, qr/fs solid 0\.5 border lc rgb "#000000" lc rgb "#ff0000"/, 'violin: colors and edgecolor' );
	($gp) = gen( %{ $figure{'plot, a hash of pairs'} }, title => 'kept', xlabel => 'x', set_ylim => '-2, 2', yscale => 'linear', %n );
	like( $gp, qr/^set title "kept"$/m, 'the title' );
	like( $gp, qr/^set yrange \[-2:2\]$/m, 'the limits' );
	($gp) = gen( %{ $figure{'pie'} }, scale => 2, %n );
	like( $gp, qr/^set terminal svg size 1280,960 /m, 'and the size' );
}

# ----------------------------------------------------------------------------
# 12. Refused only under style => 'native', where gnuplot has nothing to match.
# ----------------------------------------------------------------------------
{
	my %n = ( style => 'native' );
	dies_with( { %{ $figure{'boxplot, an array'} }, %n }, qr/gnuplot's boxplot style draws its boxes upright only/, 'boxplot: orientation => "horizontal"' );
	dies_with( { %{ $figure{'hist, an array'} }, orientation => 'horizontal', %n }, qr/gnuplot's "bins" are drawn upright only/, 'hist: orientation => "horizontal"' );
	dies_with( { plot_type => 'hist', data => [ 1, 2, 3 ], bins => [ 0, 1, 3 ], %n }, qr/edges of different widths, but gnuplot's bins under style => 'native' are all one width/, 'hist: edges of different widths' );
	dies_with( { plot_type => 'hist', data => [ 1, 2, 3 ], bins => 1, %n }, qr/"bins" => 1 for "A": gnuplot's bins under style => 'native' are at least 2/, 'hist: one bin, which gnuplot refuses as "x range is invalid"' );
	dies_with( { %{ $figure{'violin'} }, medians => 0, %n }, qr/whiskers are gnuplot's boxplot, which always draws its median/, 'violin: whiskers without medians' );
	dies_with( { %{ $figure{'violinplot, horizontal'} }, %n }, qr/needs "whiskers" => 0/, 'violin: horizontal, with whiskers' );
	lives( { %{ $figure{'violinplot, horizontal'} }, whiskers => 0, %n }, 'violin: horizontal without whiskers is drawn' );
	lives( { %{ $figure{'boxplot, an array'} } }, 'and style => "matplotlib" draws a horizontal boxplot' );
	lives( { plot_type => 'hist', data => [ 1, 2, 3 ], bins => [ 0, 1, 3 ] }, 'and uneven edges' );
}

# ----------------------------------------------------------------------------
# 13. A small subplot gets fewer tics, and smaller labels where they would touch.
# ----------------------------------------------------------------------------
# In a 2 by 2 grid of the default figure, gnuplot labelled a count axis every
# 10 from 0 to 80, a colorbar every 1 from 1 to 9, and wrote "MarkMatthew",
# each label running into the next.
{
	my %grid = ( plots => [
		{ plot_type => 'bar', data => { Matthew => 18345, Mark => 11304, Luke => 19482, John => 15635 } },
		{ plot_type => 'plot', data => [ [ 0, 80 ], [ 0, 80 ] ] },
		{ plot_type => 'scatter', data => { X => [ 1, 2, 3 ], Y => [ 3, 1, 2 ], Z => [ 1, 5, 9 ] } },
		$figure{'pie'},
	], nrows => 2, ncols => 2 );
	my ($gp) = gen(%grid);
	like( $gp, qr/^set ytics 20$/m, 'a count axis from 0 to 80 is labelled every 20, as matplotlib labels it in a panel this size' );
	like( $gp, qr/^set cbtics 2$/m, 'a colorbar from 1 to 9 every 2' );
	my ($size) = $gp =~ m/^set xtics font ",(\d+\.\d)"$/m;
	ok( ( defined $size ) && ( $size < 11 ), 'and "Mark" beside "Matthew" in a font below the 11 of the rest of the labels' ) or diag( '  font: ' . ( $size // 'none' ) );
	($gp) = gen( %{ $grid{plots}[1] } );
	unlike( $gp, qr/^set [xy]tics \d/m, 'a figure of one plot keeps gnuplot\'s tics' );
	# A label running into the next is no part of gnuplot's own look, so
	# style => 'native' is thinned as well.
	($gp) = gen( %grid, style => 'native' );
	like( $gp, qr/^set ytics 20$/m, 'native: the count axis every 20 too' );
	like( $gp, qr/^set xtics font ",\d+\.\d"$/m, 'native: and "Mark" beside "Matthew" smaller' );
	# gnuplot bins a native hist itself, so its counts are worked out in Perl
	# by gnuplot's rule for the tics alone: in the same grid, 300 values in 10
	# bins reach 80 or so, and were labelled every 10.
	srand 11;    # values the same from run to run, for the count below
	my @a = map { sqrt( -2 * log( 1 - rand ) ) * cos( 6.283185307 * rand ) } 1 .. 300;
	srand();     # and File::Temp's names no longer so; see the srand() above block 1
	($gp) = gen( %grid, plots => [ $grid{plots}[0], { plot_type => 'hist', data => { A => \@a } }, @{ $grid{plots} }[ 2, 3 ] ], style => 'native' );
	my ($step) = $gp =~ m/^set ytics (\d+)$/m;
	ok( ( defined $step ) && ( $step >= 20 ), 'native: a hist\'s counts are labelled every 20 or more, not every 10' ) or diag( '  step: ' . ( $step // 'none' ) );
	is( Matplotlib::Simple::Gnuplot::native_bin_peak( [ 0, 1, 1, 2, 2, 2 ], 3 ), 3, 'native_bin_peak: three centers, 0, 1 and 2, the fullest holding 3' );
	is( Matplotlib::Simple::Gnuplot::native_bin_peak( [ 0.4, 0.6, 1.4, 1.6 ], [ 0, 1, 2 ] ), 2, 'native_bin_peak: edges, two values in each bin' );
}

# ----------------------------------------------------------------------------
# 14. Rendered under style => 'native': every type, in every shape it draws.
# ----------------------------------------------------------------------------
# Two shapes are refused under native (block 12), and are drawn here in the
# form native takes: the horizontal boxplot upright, the horizontal violin
# without whiskers.
SKIP: {
	skip( 'no gnuplot >= 5.2', 2 * scalar( keys %figure ) + 1 ) unless $gp_available;
	my %as_native = ( 'boxplot, an array' => { orientation => 'vertical' }, 'violinplot, horizontal' => { whiskers => 0 } );
	foreach my $name ( sort keys %figure ) {
		my $svg = render( %{ $figure{$name} }, %{ $as_native{$name} // {} }, style => 'native', title => $name );
		ok( length $svg, "native $name: an SVG is written" );
		ok( well_formed($svg), "native $name: it is well-formed XML" );
	}
	my $svg = render( plots => [ $figure{'hist, a hash'}, $figure{'violin'}, $figure{'boxplot, a hash'}, $figure{'colored_table'} ], nrows => 2, ncols => 2, style => 'native' );
	ok( well_formed($svg), 'native: a grid of the types gnuplot computes for itself' );
}

# ----------------------------------------------------------------------------
# 15. Fixes found by review before 0.33 was released: each matched against what
# matplotlib draws.
# ----------------------------------------------------------------------------
# The bin counts are numpy 2.5.2's: np.histogram([0.1, 1, 2, 2.9], 3) is
# [2, 0, 2], and np.histogram([0, 0.3, 0.6, 0.7, 1], 10) is
# [1, 0, 1, 0, 0, 1, 1, 0, 0, 1]. The box widths are matplotlib 3.11.2's
# Axes.bxp, np.clip(0.15 * np.ptp(positions), 0.15, 0.5).
{
	my $counts = sub {
		my ( $v, $bins ) = @_;
		return [ Matplotlib::Simple::Gnuplot::bin_count( $v, [ Matplotlib::Simple::Gnuplot::bin_edges( $v, $bins, '"bins"' ) ] ) ];
	};
	# Edges made as lo + (hi - lo) * i / n left the last at 2.8999999999999995,
	# below the greatest value, which was then in no bin.
	is_deeply( $counts->( [ 0.1, 1, 2, 2.9 ], 3 ), [ 2, 0, 2 ], 'hist: the greatest value is in the last bin, as numpy bins it' );
	is_deeply( $counts->( [ 0, 0.3, 0.6, 0.7, 1 ], 10 ), [ 1, 0, 1, 0, 0, 1, 1, 0, 0, 1 ], 'hist: a value on an edge is in the bin numpy puts it in' );
	is_deeply( $counts->( [ 0.5, 1, 1.5, 2 ], [ 0, 1, 1, 2 ] ), [ 1, 0, 3 ], 'hist: two equal edges are a bin of no width, as numpy allows' );
	dies_with( { plot_type => 'hist', data => [ 1, 2 ], bins => [ 0, 2, 1 ] }, qr/"bins" must not fall from edge to edge/, 'hist: edges that fall are refused, as numpy refuses them' );
	lives( { plot_type => 'hist', data => { A => [], B => [ 1, 2 ] } }, 'hist: a set of no values is binned over 0 .. 1, as numpy bins it' );
	lives( { plot_type => 'hist', data => { A => [ 'nan', 'nan' ], B => [ 1, 2 ] } }, 'hist: and so is a set of NaN alone' );
	dies_with( { plot_type => 'hist2d', data => { x => [ 0.3, 0.3 ], y => [ 2, 3 ] }, logscale => ['x'] }, qr/every x is 0\.3, a range of nothing/, 'hist2d: one value on a log axis is refused by name, not taken the log of below 0' );

	my ($gp) = gen( plot_type => 'boxplot', data => { A => [ 1, 2, 3, 4, 5 ] } );
	like( $gp, qr/^1 3 0\.925 1\.075 2 4 /m, 'boxplot: one box is 0.15 wide, as bxp draws it' );
	($gp) = gen( plot_type => 'boxplot', data => { map { $_ => [ 1 .. 5 ] } 'A' .. 'C' } );
	like( $gp, qr/^1 3 0\.85 1\.15 2 4 /m, 'boxplot: and each of three, 0.3' );
	($gp) = gen( plot_type => 'boxplot', data => { map { $_ => [ 1 .. 5 ] } 'A' .. 'F' } );
	like( $gp, qr/^1 3 0\.75 1\.25 2 4 /m, 'boxplot: and each of six, 0.5' );

	my %grouped = ( plot_type => 'bar', data => { A => [ 1, 2 ], B => [ 3, 4 ] }, output_file => '/same.svg' );
	my ($with) = gen( %grouped, width => 0.4 );
	my ($without) = gen(%grouped);
	s/\A#[^\n]*\n// for $with, $without;    # the creator note names the call
	is( $with, $without, 'bar: a grouped bar plot ignores "width", as it says it does' );

	($gp) = gen( plot_type => 'wide', data => [ [ [ 1, 2, 3 ], [ 1, 2, 3 ] ], [ [ 1, 2, 3 ], [ 2, 3, 4 ] ] ], color => '#ff000080' );
	unlike( $gp, qr/"#ff000080"/, 'wide: a color with alpha is not written as gnuplot would misread it, #aarrggbb' );
	like( $gp, qr/lc rgb "#7fff0000"/, 'wide: but as gnuplot\'s transparency before the red' );
	foreach my $native ( [ 'boxplot', { color => '#ff000080' } ], [ 'violin', { edgecolor => '#ff000080' } ] ) {
		($gp) = gen( plot_type => $native->[0], data => { A => [ 1, 2, 3, 4 ] }, %{ $native->[1] }, style => 'native' );
		like( $gp, qr/rgb "#7fff0000"/, "$native->[0], native: and so is its color with alpha" );
	}

	($gp) = gen( plot_type => 'colored_table', data => { A => { A => 1234567, B => 0.123456789 } }, show_numbers => 1 );
	like( $gp, qr/sprintf\("%\.15g", \$3\)/, 'colored_table: numbers to 15 significant digits, as matplotlib shows them' );

	($gp) = gen( plot_type => 'bar', data => { A => 1 }, output_file => out_file('.png'), scale => 3 );
	like( $gp, qr/^set terminal pngcairo size 1920,1440 /m, 'scale => 3: 1440 pixels high, rounded, as matplotlib draws it, not 1439' );
}

done_testing();
