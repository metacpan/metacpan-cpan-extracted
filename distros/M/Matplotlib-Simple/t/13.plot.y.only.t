#!/usr/bin/env perl
#
# plot: a hash of sets may give a set as its y values alone, drawn against
# 0 .. n-1, as in
#
#     data => { '1cka' => [ 0.86, 0.85, 0.85 ], '1ckb' => [ 0.81, 0.8, 0.79 ] }
#
# Until 0.32 every set had to be an [ \@x, \@y ] pair, and that one died
# with "3 were entered for 1cka, but there must be exactly 2" -- or, for a set
# of exactly two numbers, with "Can't use string ("0.86") as an ARRAY ref".
#
# The scaffolding is that of t/12.review.fixes.0.319.t: most of this is
# execute => 0 and reads the generated python as text, so it runs everywhere;
# parses_ok needs python3 and run_py needs python3 and matplotlib >= 3.10, and
# each skips without them.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use JSON::MaybeXS;
use MIME::Base64;
use Matplotlib::Simple;
# The interpreter the module itself runs; see t/07.review.fixes.t.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $PY = join ' ', @PY;
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

my $python_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
if ($python_available) {
	# 3.10 is the floor t/01 and t/03 gate on. The generated figure passes
	# layout = "constrained", which matplotlib refuses before 3.5, so an older
	# one must skip these checks, not fail them.
	my $raw = qx/$PY -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)/ ) {
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
	}
}
diag( $python_available ? "Python 3 found as \"$PY\" (parser gate ON)" : 'no Python 3 (parser gate skipped)' );
diag( $mpl_available ? 'matplotlib >= 3.10 found (render checks ON)' : 'no matplotlib >= 3.10 (render checks skipped)' );

my $PARSE = q{import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())};

sub out_file { return File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' ) }

sub slurp {
	my ($file) = @_;
	open my $in, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return $text;
}

# Build one figure with execute => 0 and return the generated python as text.
sub gen {
	my (%spec) = @_;
	$spec{output_file} = out_file();
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	return ( slurp($pyfile), $pyfile );
}

# Only the message, never the Devel::Confess trace that follows it, is matched.
sub dies_with {
	my ( $spec, $like, $name ) = @_;
	my ( $out, $err, $file ) = capture { eval { gen( %{$spec} ) } };
	my $died = $@;
	return ok( 0, "$name (did not die)" ) unless length $died;
	my $message = "$died";
	$message =~ s/\n\t.*\z//s;
	if ( !like( $message, $like, $name ) ) {
		diag("  died: $message");
	}
	return;
}

# The result is taken inside the capture block: "$@" read after capture()
# returns can still hold an earlier test's error.
sub lives {
	my ( $spec, $name ) = @_;
	my ( @r, $died );
	capture { $died = eval { @r = gen( %{$spec} ); 1 } ? '' : "$@" };
	$died =~ s/\n\t.*\z//s;
	ok( !length $died, $name ) or diag("  died: $died");
	return @r;
}

sub parses_ok {
	my ( $pyfile, $name ) = @_;
	SKIP: {
		skip( 'no Python 3 interpreter found', 1 ) unless $python_available;
		my ( $out, $err, $status ) = capture {
			system( @PY, '-c', $PARSE, $pyfile );
		};
		ok( $status == 0, $name ) or diag( '  ' . ( $err . $out ) );
	}
	return;
}

# Run a generated script with $tail appended, returning what it printed. The
# caller has already skipped unless matplotlib is present.
sub run_py {
	my ( $pyfile, $tail ) = @_;
	my $script = File::Spec->catfile( $TMP, 'run' . $seq++ . '.py' );
	open my $o, '>:encoding(UTF-8)', $script or die "can't write $script: $!";
	print {$o} slurp($pyfile), "\n", $tail, "\n";
	close $o or die "can't close $script: $!";
	local $ENV{MPLBACKEND} = 'Agg';
	my ( $out, $err, $status ) = capture { system( @PY, $script ) };
	diag("  python: $err") if $status != 0;
	return $out;
}

# 1. A set of y values alone is drawn against 0 .. n-1, beside a pair.
{
	my %data = (
		'1cka' => [ 0.86, 0.85, 0.85, 0.85, 0.85 ],
		'1ckb' => [ 0.81, 0.8 ],                       # two numbers, not an x and a y
		pair   => [ [ 0, 2, 4 ], [ 0.7, 0.71, 0.72 ] ],
	);
	my ( $py, $file ) = lives( { plot_type => 'plot', data => \%data }, 'y values alone are accepted' );
	like( $py, qr/^x = \[0,1,2,3,4\]\ny = \[0\.86,0\.85,0\.85,0\.85,0\.85\]\nax0\.plot\(x, y ,label = '1cka'/m, 'five y values are drawn against 0 .. 4' );
	like( $py, qr/^x = \[0,1\]\ny = \[0\.81,0\.8\]\nax0\.plot\(x, y ,label = '1ckb'/m, 'two y values are drawn against 0 .. 1' );
	like( $py, qr/^x = \[0,2,4\]\ny = \[0\.7,0\.71,0\.72\]\nax0\.plot\(x, y ,label = 'pair'/m, 'kept: a pair in the same hash is drawn as before' );
	is_deeply( $data{'1cka'}, [ 0.86, 0.85, 0.85, 0.85, 0.85 ], "the caller's set is left as it was given" );
	parses_ok( $file, 'the script parses' );
	SKIP: {
		skip( 'needs matplotlib >= 3.10', 1 ) unless $mpl_available;
		my $out = run_py( $file, 'print("X", [[int(v) for v in l.get_xdata()] for l in ax0.get_lines()])' );
		like( $out, qr/^X \[\[0, 1, 2, 3, 4\], \[0, 1\], \[0, 2, 4\]\]$/m, 'matplotlib draws them at those x' );
	}
}

# 2. set_options, key_order and twinx reach a set of y values alone.
{
	my %data = ( A => [ 1, 2, 3 ], B => [ 900, 950, 1000 ] );
	my ($py) = lives(
		{
			plot_type   => 'plot',
			data        => \%data,
			key_order   => [ 'B', 'A' ],
			set_options => { A => 'color = "red"' },
			twinx       => 'B',
		},
		'options are accepted with y values alone'
	);
	like( $py, qr/^ax0\.plot\(x, y ,label = 'A' , color = "red"\)/m, 'set_options reaches A' );
	like( $py, qr/^twinx_ax0\.plot\(x, y ,label = 'B'/m, 'twinx moves B to the right axis' );
	ok( index( $py, "label = 'B'" ) < index( $py, "label = 'A'" ), 'key_order puts B first' );
}

# 3. What cannot be a set of y values is still refused, by name.
{
	dies_with( { plot_type => 'plot', data => { A => [ [ 1, 2 ], 3 ] } }, qr/set "A" mixes arrays with plain values/, 'a set mixing an array with a number is refused' );
	dies_with( { plot_type => 'plot', data => { A => [ 1, 'a', 3 ] } }, qr/set "A" axis 1 has the above non-numeric values/, 'a word among y values alone is refused' );
	dies_with( { plot_type => 'plot', data => { A => [ 1, undef, 3 ] } }, qr/set A axis 1 has undefined indices/, 'an undef among y values alone is refused' );
	dies_with( { plot_type => 'plot', data => { A => [] } }, qr/0 were entered for A/, 'an empty set is refused, as before' );
	# The array form is unchanged: two plain arrays are one line, x and y.
	my ($py) = lives( { plot_type => 'plot', data => [ [ 5, 6, 7 ], [ 1, 2, 3 ] ] }, 'array data: two plain arrays are accepted' );
	like( $py, qr/^x = \[5,6,7\]\ny = \[1,2,3\]$/m, 'kept: and are still read as one line of x and y' );
}

done_testing();
