#!/usr/bin/env perl
#
# The fixes of 0.3344, one block each, in the form of t/20.review.fixes.0.3342.t.
#
# They came out of an outside review of 0.3343 as it stood on 2026-11-17, and
# each was reproduced against the module before it was fixed. Each block also
# checks what the fix had to keep: whole bin counts, colors in range, numeric
# group order, agreeing grid aliases, figure keywords at the top level.
#
# The review also said that plain_text's refusal of keyword arguments was
# unreachable, since "fontsize = 20" came back as text. That is intended:
# quote_text writes the same text to matplotlib as the quoted words, so the
# other engines draw the words too. The refusal is reached by text that
# matplotlib reads as Python, such as "fontsize = 20, color = 'r'"; block 7
# pins both.
#
# Block 8 pins the contracts of the speed-ups of 0.3344 (decoded_data and
# norm_args), which change no script: that was checked by diffing the scripts
# of ten figures written before and after.
#
# Nothing here runs python, gnuplot or R: every figure is execute => 0, and
# block 6 runs this perl, so all of it runs on a Windows smoker.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Matplotlib::Simple;
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

sub out_file {
	return File::Spec->catfile( $TMP, 'gen' . $seq++ . '.svg' );
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

sub dies_with {
	my ( $code, $like, $name ) = @_;
	my $message = message_of($code);
	return ok( 0, "$name (did not die)" ) unless length $message;
	like( $message, $like, $name ) or diag("  died: $message");
	return;
}

sub lives {
	my ( $code, $name ) = @_;
	my $message = message_of($code);
	ok( !length $message, $name ) or diag("  died: $message");
	return;
}

sub figure {
	my (%spec) = @_;
	return sub { plt( output_file => out_file(), execute => 0, %spec ) };
}

my %xy = ( x => [ 1, 2, 3, 4 ], y => [ 2, 3, 1, 4 ] );

#
# 1. "xbins" and "ybins" were cut to their whole part: 1.5 drew one bin.
#
{
	foreach my $bins ( 1.5, '2.9', 0.5, '1e-1' ) {
		dies_with( figure( plot_type => 'hexbin', data => \%xy, xbins => $bins ),
		 qr/^"xbins" must be a whole number of at least 1 for hexbin_helper, not "\Q$bins\E"/, "hexbin: xbins => $bins is refused" );
	}
	dies_with( figure( plot_type => 'hist2d', data => \%xy, ybins => 2.5 ),
	 qr/^"ybins" must be a whole number of at least 1 for hist2d_helper, not "2.5"/, 'hist2d: ybins => 2.5 is refused' );
	# kept: a whole number in any spelling
	foreach my $bins ( 3, '3', 3.0, '3.0', '1e1' ) {
		my %plot = ( xbins => $bins );
		Matplotlib::Simple::bin_counts( \%plot, 'hexbin' );
		is( $plot{xbins}, int $bins, "bin_counts: xbins => '$bins' is $plot{xbins}" );
	}
	lives( figure( plot_type => 'hexbin', data => \%xy, xbins => 4, ybins => '5' ), 'hexbin with whole bins is drawn' );
}

#
# 2. A NaN channel passed the range check and came out as "#NaN8080".
#
{
	my $hex = sub { Matplotlib::Simple::color_hex( $_[0], 'color', 'gnuplot', 'plt' ) };
	foreach my $color ( [ 'NaN', 0.5, 0.5 ], [ 0.5, 'nan', 0.5 ], [ 0.5, 0.5, 0.5, 'NaN' ], '(NaN, 0.5, 0.5)', [ 'inf', 0, 0 ], [ 0, '-Inf', 0 ] ) {
		my $shown = ref $color ? '[' . join( ', ', @{$color} ) . ']' : $color;
		dies_with( sub { $hex->($color) }, qr/^plt: color is not a color the gnuplot engine knows/, "color $shown is refused" );
	}
	# kept
	is( $hex->( [ 1, 0.5, 0 ] ),       '#ff8000',   'an RGB tuple' );
	is( $hex->( [ 0, 0, 1, 0.5 ] ),    '#0000ff80', 'an RGBA tuple' );
	is( $hex->( [ 0, 0, 1, 1 ] ),      '#0000ff',   'an RGBA tuple with an alpha of 1' );
	is( $hex->('(0.0, 1.0, 0.0)'),     '#00ff00',   'a tuple as Python' );
	is( $hex->('0.5'),                 '#808080',   'a gray level' );
}

# ----------------------------------------------------------------------------
# 3. group_order died on a NaN, "Use of uninitialized value in sort", and
#    left "2" and "2.0" in the order they came in.
# ----------------------------------------------------------------------------
{
	my $order = \&Matplotlib::Simple::group_order;
	my @got;
	lives( sub { @got = $order->( 10, 'NaN', 2 ) }, 'group_order with a NaN' );
	is_deeply( \@got, [ 10, 2, 'NaN' ], 'a NaN among numbers: all in string order' );
	is_deeply( [ $order->( 10, 'inf', 2 ) ], [ 10, 2, 'inf' ], 'an infinity among numbers: all in string order' );
	is_deeply( [ $order->( '2.0', 2, 1 ) ], [ 1, 2, '2.0' ], '"2.0" before "2": equal numbers in string order' );
	is_deeply( [ $order->( 2, '2.0', 1 ) ], [ 1, 2, '2.0' ], '"2" before "2.0": the same order' );
	# kept
	is_deeply( [ $order->( 10, 2, 1, 2 ) ],     [ 1, 2, 10 ],      'numbers in numeric order, once each' );
	is_deeply( [ $order->( 'b', 10, 'a', 2 ) ], [ 10, 2, 'a', 'b' ], 'a word among them: string order' );
}

# ----------------------------------------------------------------------------
# 4. "nrows => 2, nrow => 1": normalise_p sized the grid by one and plt drew
#    it by the other, a grid too small for three plots.
# ----------------------------------------------------------------------------
{
	my @three = map { { plot_type => 'bar', data => { A => $_ } } } 1 .. 3;
	dies_with( figure( p => \@three, nrows => 2, nrow => 1 ),
	 qr/^plt: "nrow" is another name for "nrows", and they disagree: "nrow" = 1, "nrows" = 2/, 'p: nrows and nrow that disagree' );
	dies_with( figure( plots => \@three, ncols => 3, ncol => '2' ),
	 qr/^plt: "ncol" is another name for "ncols", and they disagree: "ncol" = 2, "ncols" = 3/, 'plots: ncols and ncol that disagree' );
	# kept
	lives( figure( p => \@three, nrows => 3, nrow => '03' ), 'nrows and nrow that agree' );
	lives( figure( p => \@three, nrow => 1 ), 'nrow alone' );
	lives( figure( plots => \@three, ncols => 3 ), 'ncols alone' );
}

# ----------------------------------------------------------------------------
# 5. "execute" and "fh" in a subplot or an "add" graph, and "output_file" in
#    an "add" graph, were accepted and never read.
# ----------------------------------------------------------------------------
{
	my %bar  = ( plot_type => 'bar', data => { A => 1 } );
	my %line = ( plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 2 ] ] } );
	my %over = ( plot_type => 'plot', data => { B => [ [ 1, 2 ], [ 2, 3 ] ] } );
	foreach my $choice ( [ execute => 1 ], [ fh => 'x' ], [ output_file => 'y.svg' ] ) {
		my ( $key, $value ) = @{$choice};
		dies_with( figure( plots => [ \%bar, { %bar, $key => $value } ], ncols => 2 ),
		 qr/^plt: "$key" at subplot 1: .*, so give "$key" once, beside "plots" or "p"/, "$key in a subplot" );
		dies_with( figure( p => [ [ \%line, { %over, $key => $value } ] ] ),
		 qr/^plt: "$key" in an "add" graph at subplot 0: .*, so give "$key" once, at the top level/, "$key in an \"add\" graph of p" );
		dies_with( figure( %line, add => [ { %over, $key => $value } ] ),
		 qr/^plt: "$key" in an "add" graph: .*, so give "$key" once, at the top level/, "$key in an \"add\" graph of a single plot" );
	}
	# kept: each of them at the top level, of a single plot and beside "plots"
	lives( figure( %line, add => [ \%over ] ), 'a single plot with an "add" graph' );
	lives( figure( plots => [ \%bar, \%bar ], ncols => 2 ), "plots" );
	my $fh = File::Temp->new( DIR => $TMP, SUFFIX => '.py' );
	lives( sub { plt( output_file => out_file(), execute => 0, fh => $fh, plots => [ \%bar ] ) }, '"fh" beside "plots"' );
}

#
# 6. The Creator note named the script as the working directory and its
#    base name, so that a script run from elsewhere was named wrongly.
#
{
	my $dir    = File::Spec->catdir( $TMP, 'scripts dir' );    # a space, as %TEMP% may have
	my $script = File::Spec->catfile( $dir, 'note.pl' );
	mkdir $dir or die "can't mkdir $dir: $!";
	open my $out, '>', $script or die "can't write $script: $!";
	print {$out} "use Matplotlib::Simple; print Matplotlib::Simple::creator_note('plt');\n";
	close $out or die "can't close $script: $!";
	my $lib = File::Spec->rel2abs( ( grep { -e File::Spec->catfile( $_, 'Matplotlib', 'Simple.pm' ) } @INC )[0] );
	# Run from $TMP, not from $dir, so that the working directory is not the
	# script's.
	my $here = File::Spec->rel2abs( File::Spec->curdir );
	chdir $TMP or die "can't chdir to $TMP: $!";
	my ( $note, $err, $status ) = capture { system( $^X, "-I$lib", $script ) };
	chdir $here or die "can't chdir to $here: $!";
	is( $status, 0, 'the script ran' ) or diag($err);
	require Cwd;
	my $real = Cwd::realpath($dir);
	like( $note, qr/^\Q${\ File::Spec->catfile( $real, 'note.pl' ) }\E called using "plt" in /, 'the note names the script where it is, not where it was run from' );
}

#
# 7. Not a fix: plain_text keeps "fontsize = 20" as words, as quote_text does
#    for matplotlib, and refuses keyword arguments that matplotlib would read
#    as Python.
#
{
	my $plain = sub { Matplotlib::Simple::plain_text( $_[0], 'title', 'gnuplot', 'plt' ) };
	is( $plain->('fontsize = 20'), 'fontsize = 20', 'text with no quote or comma is the words' );
	is( Matplotlib::Simple::Matplotlib::quote_text('fontsize = 20'), q{'fontsize = 20'}, 'and matplotlib draws the same words' );
	dies_with( sub { $plain->(q{fontsize = 20, color = 'r'}) }, qr/^plt: "title" is given as matplotlib's keyword arguments/, 'keyword arguments as Python are refused' );
}

#
# 8. Not a fix: the contracts of what was made faster. decoded_data copies only
#    what decoding changes, and returns the rest as it was given; norm_args
#    finds the same range from "rows" as from the same values in one list.
#
{
	require Scalar::Util;
	require JSON::MaybeXS;
	my $decoded = \&Matplotlib::Simple::decoded_data;
	my $same    = sub { Scalar::Util::refaddr( $_[0] ) == Scalar::Util::refaddr( $_[1] ) };
	my @image = ( [ 1, 2.5, 'nan' ], [ 'ascii', undef, -3 ] );
	ok( $same->( $decoded->( \@image ), \@image ), 'nothing to decode: the image itself is returned' );
	my %h = ( a => [ 1, 2 ], b => { c => 'd' } );
	ok( $same->( $decoded->( \%h ), \%h ), 'nothing to decode: the hash itself is returned' );
	my $bytes = "\xcf\x81";    # the UTF-8 bytes of U+03C1
	my $untouched = [ 7, 8 ];
	my %mixed = ( $bytes => 1, list => [ 'x', $bytes ], keep => $untouched );
	my $got = $decoded->( \%mixed );
	ok( !$same->( $got, \%mixed ), 'bytes to decode: a copy is returned' );
	is_deeply( [ sort keys %{$got} ], [ sort( 'keep', 'list', "\x{3c1}" ) ], 'a key of bytes is decoded' );
	is( $got->{list}[1], "\x{3c1}", 'a value of bytes is decoded' );
	ok( $same->( $got->{keep}, $untouched ), 'and what holds nothing to decode is shared, not copied' );
	is_deeply( [ sort keys %mixed ], [ sort( $bytes, 'keep', 'list' ) ], "the caller's hash keeps its own keys" );
	is( $mixed{list}[1], $bytes, "and its own values" );
	my $json = JSON::MaybeXS->new->canonical;
	is( $json->encode( $decoded->( [ 1, 2.5, -3, 'a' ] ) ), '[1,2.5,-3,"a"]', 'numbers are still written as numbers' );
	my $norm = sub {
		my (%a) = @_;
		open my $fh, '>', \my $script or die "can't open a string: $!";
		return Matplotlib::Simple::Matplotlib::norm_args( { fh => $fh, sub => 'imshow', %a } );
	};
	my @rows = ( [ 'nan', -2, 5 ], [], [ 0, 'inf', 0.5 ], [ 9, '-inf', 3 ] );
	my @flat = map { @{$_} } @rows;
	foreach my $case ( [], [ log => 1 ], [ lo => 1 ], [ hi => 4 ], [ lo => 1, hi => 4, log => 1 ] ) {
		my $name = scalar @{$case} ? join( ', ', @{$case} ) : 'no ends given';
		is( $norm->( rows => \@rows, @{$case} ), $norm->( values => \@flat, @{$case} ), "norm_args ($name): rows and values agree" );
	}
	is( $norm->( rows => \@rows ), ', vmin = -2, vmax = 9', 'the range of the finite values' );
	is( $norm->( rows => \@rows, log => 1 ), ', norm = LogNorm(vmin = 0.5, vmax = 9)', 'a log scale from the smallest above 0' );
}

done_testing();
