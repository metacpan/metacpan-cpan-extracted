#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempdir);
use File::Spec;
use Capture::Tiny 'capture';
use Test::Exception;                 # lives_ok / throws_ok
use Matplotlib::Simple;
use Test::More;
#
# Dependency discovery (python3 is needed for the SVG well-formedness check and
# for the render layer; matplotlib only for the render layer).
# 
my $python_version_raw = qx/python3 --version 2>&1/;
my $python_available = ( $? == 0 && $python_version_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
my $mpl_version   = '';
if ($python_available) {
	my $raw = qx/python3 -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)\.\d+/ ) {
		# the module documents a 3.10+ requirement; render only when satisfied
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
		( $mpl_version = $raw ) =~ s/^\s+|\s+$//g;
	}
}
diag( $python_available ? "python3: $python_version_raw" : 'python3 not found' );
diag( $mpl_available ? "matplotlib: $mpl_version (render layer ON)"
	: 'matplotlib >= 3.10 not found (render layer SKIPPED)' );

# ----------------------------------------------------------------------------
# Helpers.
# ----------------------------------------------------------------------------
my @tmp_to_unlink;
END { unlink grep { defined && -e } @tmp_to_unlink }

sub slurp {
	my ($path) = @_;
	open my $in, '<', $path or die "can't read $path: $!";
	local $/;
	my $t = <$in>;
	close $in;
	return defined $t ? $t : '';
}

# Build a figure with "p" but DON'T run python (execute => 0). "show => 1"
# satisfies plt()'s "need output.file or show" guard without touching the
# output-file machinery, so these structural checks are pure and offline.
# Returns the generated python source text.
sub build_py {
	my (@p) = @_;
	my ( $py, $out, $err );
	( $out, $err, $py ) = capture {
		plt({ p => [@p], show => 1, execute => 0 });
	};
	push @tmp_to_unlink, $py if defined $py;
	return ( defined $py && -e $py ) ? slurp($py) : '';
}

sub count_matches {
	my ( $text, $re ) = @_;
	my $n = 0;
	$n++ while $text =~ /$re/g;
	return $n;
}

# A minimal, valid single-plot spec (hist needs numeric data only).
sub H {
	my ( $key, @vals ) = @_;
	return { 'plot.type' => 'hist', data => { $key => [@vals] } };
}

# ----------------------------------------------------------------------------
# 1. Flat array of hashes  ->  one subplot per hash.
#    p => [ \%h, \%h, \%h ]  ==> 3 subplots on an auto 2x2 grid, one plot each.
# ----------------------------------------------------------------------------
{
	my $py;
	lives_ok {
		$py = build_py( H('A',1,2,3), H('B',2,3,4), H('C',3,4,5) );
	} 'flat p: three single-plot subplots build without dying';

	like( $py, qr/plt\.subplots\(2, 2,/, 'flat p (n=3): auto grid is 2x2' );
	is( count_matches( $py, qr/\bax0\.hist\(/ ), 1, 'flat p: ax0 has 1 plot' );
	is( count_matches( $py, qr/\bax1\.hist\(/ ), 1, 'flat p: ax1 has 1 plot' );
	is( count_matches( $py, qr/\bax2\.hist\(/ ), 1, 'flat p: ax2 has 1 plot' );
	is( count_matches( $py, qr/\.hist\(/ ),      3, 'flat p: 3 plots total (one per subplot)' );
	# the unused 4th cell of the 2x2 grid is pruned by the engine
	like( $py, qr/ax3\.remove\(\)/, 'flat p: empty 4th cell is removed' );
}

# ----------------------------------------------------------------------------
# 2. Mixed forms  ->  an inner array is ONE subplot with overlaid plots.
#    p => [ \%h, [ \%h, \%h ], \%h ]
#    ax1 must carry TWO plot calls (the overlay); ax0 and ax2 one each.
# ----------------------------------------------------------------------------
{
	my $py;
	lives_ok {
		$py = build_py(
			{ 'plot.type' => 'hist', data => { A => [1,2,3] }, title => 'single' },
			[ H('B',1,2), H('C',3,4) ],                      # overlaid in ONE subplot
			{ 'plot.type' => 'hist', data => { D => [5,6] }, title => 'third' },
		);
	} 'mixed p: hash + array-of-hashes + hash builds without dying';

	is( count_matches( $py, qr/\bax0\.hist\(/ ), 1, 'mixed p: ax0 = single plot' );
	is( count_matches( $py, qr/\bax1\.hist\(/ ), 2, 'mixed p: ax1 = two overlaid plots' );
	is( count_matches( $py, qr/\bax2\.hist\(/ ), 1, 'mixed p: ax2 = single plot' );
	is( count_matches( $py, qr/\.hist\(/ ),      4, 'mixed p: 4 plots across 3 subplots' );
	like( $py, qr/ax0\.set_title\('single'\)/, 'mixed p: subplot 0 title preserved' );
	like( $py, qr/ax2\.set_title\('third'\)/,  'mixed p: subplot 2 title preserved' );
}

# ----------------------------------------------------------------------------
# 3. A single-element p is a 1x1 figure.
# ----------------------------------------------------------------------------
{
	my $py = build_py( H('A',1,2,3) );
	like( $py, qr/plt\.subplots\(1, 1,/, 'single p element: 1x1 grid' );
	is( count_matches( $py, qr/\.hist\(/ ), 1, 'single p element: 1 plot' );
}

# ----------------------------------------------------------------------------
# 4. Partial grid: giving one dimension derives the other.
#    ncols => 1 stacks vertically (3x1); nrows => 1 lays out in a row (1x3).
# ----------------------------------------------------------------------------
{
	my ( $py, $out, $err );
	( $out, $err, $py ) = capture {
		plt({ p => [ H('A',1), H('B',2), H('C',3) ], ncols => 1, show => 1, execute => 0 });
	};
	push @tmp_to_unlink, $py if defined $py;
	like( slurp($py), qr/plt\.subplots\(3, 1,/, 'ncols=1 with 3 subplots -> 3x1 (vertical stack)' );
}
{
	my ( $py, $out, $err );
	( $out, $err, $py ) = capture {
		plt({ p => [ H('A',1), H('B',2), H('C',3) ], nrows => 1, show => 1, execute => 0 });
	};
	push @tmp_to_unlink, $py if defined $py;
	like( slurp($py), qr/plt\.subplots\(1, 3,/, 'nrows=1 with 3 subplots -> 1x3 (single row)' );
}

# ----------------------------------------------------------------------------
# 5. Explicit grid is honoured verbatim.
# ----------------------------------------------------------------------------
{
	my ( $py, $out, $err );
	( $out, $err, $py ) = capture {
		plt({ p => [ H('A',1) ], nrows => 2, ncols => 3, show => 1, execute => 0 });
	};
	push @tmp_to_unlink, $py if defined $py;
	like( slurp($py), qr/plt\.subplots\(2, 3,/, 'explicit nrows/ncols kept as given' );
}

# ----------------------------------------------------------------------------
# 6. Error paths: bad "p" shapes and forbidden combinations must die clearly.
# ----------------------------------------------------------------------------
throws_ok { plt({ p => { A => 1 },        show => 1 }) }
	qr/must be an ARRAY reference/,        'p as a HASH ref dies';
throws_ok { plt({ p => [],                show => 1 }) }
	qr/is empty/,                          'empty p dies';
throws_ok { plt({ p => [ [] ],            show => 1 }) }
	qr/empty array/,                       'empty inner subplot array dies';
throws_ok { plt({ p => [ 42 ],            show => 1 }) }
	qr/must be a HASH reference/,          'scalar subplot element dies';
throws_ok { plt({ p => [ [ 42 ] ],        show => 1 }) }
	qr/every plot must be a HASH/,         'non-hash inside an inner array dies';
throws_ok { plt({ p => [ H('A',1) ], data => { X => [1] },     show => 1 }) }
	qr/cannot be combined with/,           '"data" combined with "p" dies';
throws_ok { plt({ p => [ H('A',1) ], 'plot.type' => 'hist',    show => 1 }) }
	qr/cannot be combined with/,           '"plot.type" combined with "p" dies';
throws_ok { plt({ p => [ H('A',1) ], plots => [ H('A',1) ],    show => 1 }) }
	qr/cannot be combined with/,           '"plots" combined with "p" dies';
throws_ok { plt({ p => [ H('A',1) ], add => [ H('A',1) ],      show => 1 }) }
	qr/cannot be combined with/,           '"add" combined with "p" dies';

# ----------------------------------------------------------------------------
# 7. Render layer: drive matplotlib end-to-end and confirm the mixed figure
#    yields a well-formed SVG with exactly three Axes (the overlay shares one).
#    Skipped unless matplotlib >= 3.10.
# ----------------------------------------------------------------------------
SKIP: {
	skip 'matplotlib >= 3.10 not available for the render layer', 4
		unless $mpl_available;

	my $dir = tempdir( CLEANUP => 1 );
	my $svg = File::Spec->catfile( $dir, 'condon.p_interface.svg' );

	my ( $out, $err, $py );
	lives_ok {
		( $out, $err, $py ) = capture {
			plt({
				p => [
					H('A',1,2,2,3,3,3,4),
					[ H('B',1,1,2,2,3), H('C',2,3,3,4,4,5) ],   # overlay -> one subplot
					H('D',5,5,6,6,6,7),
				],
				'output.file' => $svg,
				execute       => 1,
			});
		};
	} 'mixed p figure renders to SVG without dying';
	push @tmp_to_unlink, $py if defined $py;

	ok( -e $svg, 'SVG output file was created' );
	ok( -s $svg, 'SVG output file is non-empty' );

	my $svg_text  = slurp($svg);
	my $axes_seen = count_matches( $svg_text, qr/id="axes_/ );
	is( $axes_seen, 3, 'exactly 3 Axes rendered (overlay collapsed into one subplot)' );
}

done_testing();
