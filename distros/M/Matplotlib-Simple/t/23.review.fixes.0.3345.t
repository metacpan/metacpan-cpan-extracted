#!/usr/bin/env perl
#
# The fixes of 0.3346, one block each, in the form of t/22.review.fixes.0.3344.t.
#
# They came from a code review of 0.3345 on 2026-11-24, and each was
# reproduced against 0.3345 before it was fixed. Each block also checks what
# the fix had to keep.
#
# What each block checks of the script, or through a stand-in for run_script,
# runs on nothing but Perl, so on a Windows smoker. Each block then renders,
# where the engine is installed: matplotlib >= 3.10, as t/20 gates on; gnuplot
# >= 5.2, as t/17 does; ggplot2 at $Matplotlib::Simple::Ggplot2::min_ggplot2,
# as t/18 does. Without one, its renders skip.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
use Matplotlib::Simple::Gnuplot ();
use Matplotlib::Simple::Ggplot2 ();    # loaded by the first figure that asks for it, and $min_ggplot2 is read before
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

sub out_file {
	return File::Spec->catfile( $TMP, 'gen' . $seq++ . ( $_[0] // '.svg' ) );
}

sub slurp {
	my ($file) = @_;
	open my $fh, '<:raw', $file or die "can't read $file: $!";
	local $/;
	my $text = <$fh>;
	close $fh or die "can't close $file: $!";
	return $text;
}

# The message alone, never the Devel::Confess trace after it, which prints the
# arguments of every frame; see t/20.review.fixes.0.3342.t.
sub message_of {
	my ($code) = @_;
	my $message;
	capture { $message = eval { $code->(); 1 } ? '' : "$@" };
	$message =~ s/\n\t.*\z//s;
	return $message;
}

# The script plt writes for a figure, not run.
sub script_of {
	my (%spec) = @_;
	my ( undef, undef, $file ) = capture { plt( output_file => out_file(), execute => 0, %spec ) };
	return slurp($file);
}

# A figure run by its engine: what it printed to STDERR, and its error if it
# died, which is '' if it did not and the output file holds something.
sub rendered {
	my (%spec) = @_;
	my $file = out_file( $spec{output_suffix} // '.svg' );
	delete $spec{output_suffix};
	my $error;
	my ( undef, $stderr ) = capture { $error = eval { plt( output_file => $file, %spec ); 1 } ? '' : "$@" };
	$error =~ s/\n\t.*\z//s;
	$error = "nothing was written to $file" if ( $error eq '' ) && ( not -s $file );    # -s as a plausibility check only; see CLAUDE.md
	return ( $error, $stderr );
}

# Each engine, as the module finds it: see t/17.gnuplot.t, t/18.ggplot2.t and
# t/20.review.fixes.0.3342.t. Single quotes only in the arguments: see
# CLAUDE.md on list-form system on Win32.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $mpl_available = 0;
if ( scalar @PY ) {
	my ( $out, undef, $status ) = capture {
		no warnings 'exec';    # a missing python is a skip, not a failure
		system( @PY, '-c', 'import matplotlib; print(matplotlib.__version__)' );
	};
	# 3.10: the floor t/01 and t/03 gate on; see CLAUDE.md
	$mpl_available = ( ( $status == 0 ) && ( $out =~ m/^\s*(\d+)\.(\d+)/ ) && ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ) ? 1 : 0;
}
my $GP = Matplotlib::Simple::program_from_env('MATPLOTLIB_SIMPLE_GNUPLOT') // 'gnuplot';
my ( $gp_out, undef, $gp_status ) = capture {
	no warnings 'exec';
	system( $GP, '--version' );
};
# 5.2: what t/17 gates its renders on, for "reset session" and "bins"
my $gp_available = ( ( $gp_status == 0 ) && ( $gp_out =~ m/^gnuplot\s+(\d+)\.(\d+)/ ) && ( $1 > 5 || ( $1 == 5 && $2 >= 2 ) ) ) ? 1 : 0;
my @R = ( Matplotlib::Simple::program_from_env('MATPLOTLIB_SIMPLE_RSCRIPT') // 'Rscript' );
my ( $r_out, undef, $r_status ) = capture {
	no warnings 'exec';
	system( @R, '-e', q{cat(if (requireNamespace('ggplot2', quietly = TRUE)) as.character(utils::packageVersion('ggplot2')) else 'none')} );
};
my $gg_available = 0;
if ( ( $r_status == 0 ) && ( $r_out =~ m/^(\d+)\.(\d+)/ ) ) {
	my ( $major, $minor ) = ( $1, $2 );
	my ( $want_major, $want_minor ) = $Matplotlib::Simple::Ggplot2::min_ggplot2 =~ m/^(\d+)\.(\d+)/;
	$gg_available = ( $major > $want_major || ( $major == $want_major && $minor >= $want_minor ) ) ? 1 : 0;
}
diag( 'render checks: matplotlib ' . ( $mpl_available ? 'ON' : 'OFF' ) . ', gnuplot ' . ( $gp_available ? 'ON' : 'OFF' ) . ', ggplot2 ' . ( $gg_available ? 'ON' : 'OFF' ) );

#
# 1. A native gnuplot boxplot whose sets all had fewer than 4 values died in
#    gnuplot as "x range is invalid": gnuplot 6.0 draws such a set as its
#    points alone, with no box, so it had no x range to autoscale. The range
#    is now given, and such a set drawn as gnuplot draws it. Under
#    "showfliers" => 0 gnuplot draws it not at all, so that is refused by name.
#
{
	my $script = script_of( engine => 'gnuplot', plot_type => 'boxplot', data => { A => [ 1, 2, 3 ], B => [1], C => [ 1 .. 10 ] } );
	like( $script, qr/^set xrange \[0\.5:3\.5\]\r?$/m, 'gnuplot boxplot: the x range is given, half a place either side of 3 boxes' );
	like(
		message_of( sub { plt( engine => 'gnuplot', plot_type => 'boxplot', data => { A => [ 1, 2 ], B => [ 1 .. 5 ] }, showfliers => 0, output_file => out_file(), execute => 0 ) } ),
		qr/^"A" has 2 value\(s\), and gnuplot's boxplot draws a set of fewer than 4 as its points alone, which "showfliers" => 0 hides/,
		'gnuplot boxplot: a set of fewer than 4 under "showfliers" => 0 is refused by name'
	);
	# kept: "showfliers" => 0 with 4 or more values, and with an empty set;
	# style => 'matplotlib', which draws its own boxes
	is( message_of( sub { plt( engine => 'gnuplot', plot_type => 'boxplot', data => { A => [ 1 .. 4 ], B => [] }, showfliers => 0, output_file => out_file(), execute => 0 ) } ), '', 'gnuplot boxplot: kept: "showfliers" => 0 with 4 values, and an empty set' );
	is( message_of( sub { plt( engine => 'gnuplot', style => 'matplotlib', plot_type => 'boxplot', data => { A => [ 1, 2 ] }, showfliers => 0, output_file => out_file(), execute => 0 ) } ), '', 'gnuplot boxplot: kept: style => \'matplotlib\' takes a set of 2 under "showfliers" => 0' );
	SKIP: {
		skip( 'no gnuplot >= 5.2', 3 ) unless $gp_available;
		foreach my $data ( { A => [ 1, 2, 3 ] }, { A => [ 1, 2, 3 ], B => [ 1, 2, 3 ] }, { A => [1], B => [ 1, 2, 3 ] } ) {
			my ($error) = rendered( engine => 'gnuplot', plot_type => 'boxplot', data => $data );
			is( $error, '', 'gnuplot boxplot: drawn: ' . join( ', ', map { "$_ has " . scalar( @{ $data->{$_} } ) } sort keys %{$data} ) );
		}
	}
}

#
# 2. gnuplot died as "Can't plot with an empty cb range!" when every value of
#    an imshow, a colored_table, a scatter's "color_key" or a hist2d was the
#    same. The scale is now widened as matplotlib widens it: by 0.1 of the
#    value either side where matplotlib's colorbar widens the norm it colors
#    by, and up from the value where it colors by the norm before that.
#
{
	my %cbrange = (
		'imshow, with a colorbar'      => [ { plot_type => 'imshow', data => [ [ 1, 1 ], [ 1, 1 ] ] }, '0.9:1.1' ],
		'imshow, below 0'              => [ { plot_type => 'imshow', data => [ [ -3, -3 ], [ -3, -3 ] ] }, '-3.3:-2.7' ],
		'imshow, at 0'                 => [ { plot_type => 'imshow', data => [ [ 0, 0 ], [ 0, 0 ] ] }, '-0.1:0.1' ],
		'imshow, without a colorbar'   => [ { plot_type => 'imshow', data => [ [ 1, 1 ], [ 1, 1 ] ], colorbar_on => 0 }, '1:1.2' ],
		'imshow, "vmin" == "vmax"'     => [ { plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ], vmin => 2, vmax => 2 }, '1.8:2.2' ],
		'colored_table'                => [ { plot_type => 'colored_table', data => { A => { x => 1, y => 1 }, B => { x => 1, y => 1 } } }, '1:1.2' ],
		'scatter by a "color_key"'     => [ { plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 1, 2 ], z => [ 4, 4 ] }, keys => [ 'x', 'y', 'z' ], color_key => 'z' }, '3.6:4.4' ],
		'kept: imshow of 4 values'     => [ { plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ] }, '1:4' ],
	);
	foreach my $name ( sort keys %cbrange ) {
		my ( $spec, $range ) = @{ $cbrange{$name} };
		foreach my $style ( 'native', 'matplotlib' ) {
			like( script_of( engine => 'gnuplot', style => $style, %{$spec} ), qr/^set cbrange \[\Q$range\E\]\r?$/m, "gnuplot, $style, $name: cbrange [$range]" );
		}
	}
	SKIP: {
		skip( 'no gnuplot >= 5.2', 2 * scalar( keys %cbrange ) + 2 ) unless $gp_available;
		foreach my $name ( sort keys %cbrange ) {
			foreach my $style ( 'native', 'matplotlib' ) {
				my ($error) = rendered( engine => 'gnuplot', style => $style, %{ $cbrange{$name}[0] } );
				is( $error, '', "gnuplot, $style, $name: drawn" );
			}
		}
		foreach my $style ( 'native', 'matplotlib' ) {
			my ($error) = rendered( engine => 'gnuplot', style => $style, plot_type => 'hist2d', data => { x => [ 1, 2 ], y => [ 1, 2 ] }, xbins => 1, ybins => 1 );
			is( $error, '', "gnuplot, $style, hist2d of one bin: drawn" );
		}
	}
}

#
# 3. gnuplot's "with image" draws nothing for a matrix of one row or one
#    column, and says only "Image grid must be at least 4 points", which
#    went unseen (block 5), so a one-row colored_table or imshow was written
#    as an empty frame. Such a matrix is now drawn as boxes colored by the
#    palette.
#
{
	my %thin = (
		'imshow of one row'           => { plot_type => 'imshow', data => [ [ 1, 2, 3 ] ] },
		'imshow of one column'        => { plot_type => 'imshow', data => [ [1], [2] ] },
		'imshow of one cell'          => { plot_type => 'imshow', data => [ [1] ] },
		'imshow of one row of words'  => { plot_type => 'imshow', data => [ [ 'a', 'b' ] ], stringmap => { a => 'A', b => 'B' } },
		'colored_table of one row'    => { plot_type => 'colored_table', data => { A => { x => 1, y => 2 } } },
	);
	foreach my $name ( sort keys %thin ) {
		my $script = script_of( engine => 'gnuplot', %{ $thin{$name} } );
		like( $script, qr/ with boxxyerror fs solid 1\.0 noborder lc palette /, "gnuplot, $name: drawn as boxes" );
		unlike( $script, qr/ with image /, "gnuplot, $name: not as an image" );
	}
	# kept: an image of 2 by 2 or more stays one
	like( script_of( engine => 'gnuplot', plot_type => 'imshow', data => [ [ 1, 2 ], [ 3, 4 ] ] ), qr/ matrix using 1:2:3 with image notitle/, 'gnuplot, imshow of 2 by 2: kept: an image' );
	SKIP: {
		skip( 'no gnuplot >= 5.2', 2 * scalar( keys %thin ) ) unless $gp_available;
		foreach my $name ( sort keys %thin ) {
			my ( $error, $stderr ) = rendered( engine => 'gnuplot', %{ $thin{$name} } );
			is( $error, '', "gnuplot, $name: drawn" );
			unlike( $stderr, qr/Image grid/, "gnuplot, $name: without gnuplot's warning" );
		}
	}
}

#
# 4. A matplotlib hist set of NaN alone died in Python as "autodetected range
#    of [nan, nan] is not finite". It is written as the empty set it bins to.
#
{
	my $script = script_of( plot_type => 'hist', data => { A => [ 'NaN', 'NaN' ], B => [ 'NaN', 1 ] } );
	my @d = $script =~ m/^d = (.*)$/mg;
	is_deeply( \@d, [ '[]', "[float('nan'),1]" ], 'matplotlib hist: a set of NaN alone is written empty; kept: NaN beside a number is written for matplotlib to bin around' );
	SKIP: {
		skip( 'no matplotlib >= 3.10', 3 ) unless $mpl_available;
		foreach my $spec ( [ { A => [ 'NaN', 'NaN' ], B => [ 1, 2, 3 ] } ], [ { A => ['NaN'] } ], [ { A => [ 'NaN', 1 ], B => ['NaN'] }, bins => [ 0, 1, 2 ] ] ) {
			my ( $data, @options ) = @{$spec};
			my ($error) = rendered( plot_type => 'hist', data => $data, @options );
			is( $error, '', 'matplotlib hist: drawn: ' . join( ', ', map { "$_ = [" . join( ', ', @{ $data->{$_} } ) . ']' } sort keys %{$data} ) );
		}
	}
}

#
# 5. The gnuplot and ggplot2 engines dropped what their script wrote to
#    STDERR when it succeeded, so R's and gnuplot's warnings never reached
#    the caller, as 0.3343 had made matplotlib's do. Each now prints it, less
#    the gnuplot script's line giving its version.
#
{
	my $through = sub {
		my ( $engine, $returns, %spec ) = @_;
		my ( undef, $stderr ) = capture {
			no warnings qw(once redefine);
			no strict 'refs';    # the engine named by $engine
			local *{"Matplotlib::Simple::${engine}::run_script"} = sub { return $returns };
			plt( output_file => out_file('.png'), %spec );
		};
		return $stderr;
	};
	my $warning = "Warning: empty x range [1:1], adjusting to [0.99:1.01]\n";
	is( $through->( 'Gnuplot', "Matplotlib::Simple gnuplot 6.0.0\n$warning", engine => 'gnuplot', plot_type => 'bar', data => { A => 1 } ), $warning, 'gnuplot: a warning is printed to STDERR, and the version line is not' );
	is( $through->( 'Gnuplot', "Matplotlib::Simple gnuplot 6.0.0\r\n", engine => 'gnuplot', plot_type => 'bar', data => { A => 1 } ), '', 'gnuplot: kept: the version line alone, ended with CRLF, prints nothing' );
	$warning = "Warning message:\nIn ggplot2::scale_x_continuous(transform = \"log10\") :\n  log-10 transformation introduced infinite values.\n";
	is( $through->( 'Ggplot2', $warning, engine => 'ggplot2', plot_type => 'bar', data => { A => 1 } ), $warning, 'ggplot2: a warning is printed to STDERR' );
	is( $through->( 'Ggplot2', '', engine => 'ggplot2', plot_type => 'bar', data => { A => 1 } ), '', 'ggplot2: kept: nothing, when the script printed nothing' );
	SKIP: {
		skip( 'no gnuplot >= 5.2', 3 ) unless $gp_available;
		my ( $error, $stderr ) = rendered( engine => 'gnuplot', plot_type => 'plot', data => { A => [ [1], [2] ] } );
		is( $error, '', 'gnuplot: a plot of one point: drawn' );
		like( $stderr, qr/^Warning: empty x range/m, 'gnuplot: a plot of one point: gnuplot\'s warning reaches STDERR' );
		( $error, $stderr ) = rendered( engine => 'gnuplot', plot_type => 'bar', data => { A => 1, B => 2 } );
		unlike( $stderr, qr/Matplotlib::Simple gnuplot/, 'gnuplot: the version line does not' );
	}
	SKIP: {
		skip( "no ggplot2 >= $Matplotlib::Simple::Ggplot2::min_ggplot2", 2 ) unless $gg_available;
		my ( $error, $stderr ) = rendered( engine => 'ggplot2', plot_type => 'scatter', logscale => ['x'], data => { x => [ 0, 1, 2 ], y => [ 1, 2, 3 ] }, keys => [ 'x', 'y' ] );
		is( $error, '', 'ggplot2: a log x axis with a 0 on it: drawn' );
		like( $stderr, qr/infinite values/, 'ggplot2: R\'s warning reaches STDERR' );
	}
}

done_testing();
