#!/usr/bin/env perl
#
# scatter's "tooltips": text shown on hovering over each point of an SVG, in
# the form of t/14.review.fixes.0.32.t.
#
# A labelled point is drawn with a url, which matplotlib writes as a link
# around that point's marker; once the SVG is saved the script turns each link
# into a <g> whose <title> is the label, and adds a script at the end of the
# SVG that draws that label in a box on hovering. The render blocks check that each
# title sits on its own point, by the marker's x coordinate, including where
# matplotlib leaves a point out.
#
# Most of this is execute => 0 and reads the generated python as text, so it
# runs everywhere, including a Windows smoker with no python. parses_ok needs
# python3 and the render blocks python3 and matplotlib >= 3.10, and each skips
# without them.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use JSON::MaybeXS;
use MIME::Base64;
use Encode ();
use Matplotlib::Simple;
# The interpreter the module itself runs; see t/07.review.fixes.t.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $PY = join ' ', @PY;
use Test::More;
binmode( Test::More->builder->$_, ':encoding(UTF-8)' ) foreach qw(output failure_output todo_output);

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

sub out_file {
	my ($ext) = @_;
	return File::Spec->catfile( $TMP, 'gen' . $seq++ . '.' . ( $ext // 'svg' ) );
}

sub slurp {
	my ($file) = @_;
	open my $in, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
	local $/;
	my $text = <$in>;
	close $in;
	return $text;
}

# Build one figure with execute => 0 and return the generated python as text,
# the script's path, and what was warned.
sub gen {
	my (%spec) = @_;
	$spec{output_file} //= out_file();
	$spec{execute} = 0;
	my ( $out, $err, $pyfile ) = capture { plt( \%spec ) };
	return ( slurp($pyfile), $pyfile, $err );
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

# The value of a python variable that write_data put into the script.
sub written {
	my ( $py, $name ) = @_;
	return undef unless $py =~ m/^\Q$name\E_b64 = '([^']*)'$/m;
	return JSON::MaybeXS->new->utf8->decode( decode_base64($1) );
}

# Draw a figure for real and return the SVG's text; '' if it failed.
sub render {
	my (%spec) = @_;
	$spec{output_file} //= out_file();
	local $ENV{MPLBACKEND} = 'Agg';
	my ( $out, $err, $died );
	( $out, $err ) = capture { $died = eval { plt( \%spec ); 1 } ? '' : "$@" };
	if ( length $died ) {
		$died =~ s/\n\t.*\z//s;
		diag("  died: $died");
		return '';
	}
	if ( $spec{output_file} =~ m/\.svgz\z/ ) {
		require IO::Uncompress::Gunzip;
		my $text;
		IO::Uncompress::Gunzip::gunzip( $spec{output_file} => \$text ) or die "can't gunzip $spec{output_file}";
		return Encode::decode( 'UTF-8', $text );
	}
	return slurp( $spec{output_file} );
}

# Each <title> in the SVG with the x of the marker it labels, in the order of
# the document. The text is unescaped as ElementTree escapes it: &, < and >.
sub titled_points {
	my ($svg) = @_;
	my %entity = ( amp => '&', lt => '<', gt => '>' );
	my @points;
	while ( $svg =~ m{<title>([^<]*)</title>.*?<use [^>]*?\bx="([-\d.]+)"}sg ) {
		my ( $text, $x ) = ( $1, $2 );
		$text =~ s/&(amp|lt|gt);/$entity{$1}/g;
		push @points, [ $text, $x ];
	}
	return @points;
}

# Labels in order of the x their markers are drawn at.
sub labels_by_x {
	return map { $_->[0] } sort { $a->[1] <=> $b->[1] } titled_points( $_[0] );
}

my %one = ( X => [ 1, 2, 3, 4 ], Y => [ 3, 1, 4, 2 ] );

# ----------------------------------------------------------------------------
# 1. One set: an array of one label per point, undef for a point without one.
# ----------------------------------------------------------------------------
{
	my ( $py, $file ) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ 'alpha', undef, 'gamma', 4 ] }, 'one set: an array of labels with an undef is accepted' );
	like( $py, qr/^ax0\.scatter\(x, y , urls = tooltip_urls\)$/m, 'one set: the urls reach ax.scatter' );
	is_deeply( written( $py, 'tooltip_urls' ), [ map { defined $_ ? "#matplotlib-simple-tooltip-$_" : undef } ( 0, undef, 1, 2 ) ],
		'one set: each labelled point has its own url, and the undef point none' );
	is_deeply( written( $py, 'tooltip_text' ), [ 'alpha', 'gamma', '4' ], 'one set: the labels are written as text, the number too' );
	like( $py, qr/svg_tree\.write\(/, 'one set: the SVG is rewritten with the titles' );
	parses_ok( $file, 'one set: the script parses' );
}

# ----------------------------------------------------------------------------
# 2. The array must have one entry per point.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ 'a', 'b', 'c' ] },
		qr/"tooltips" has 3 labels, but there are 4 points: give one per point, and undef for a point that has none/, 'too few labels is refused, with both counts' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ ('a') x 5 ] },
		qr/"tooltips" has 5 labels, but there are 4 points/, 'too many labels is refused' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ undef, undef, undef ] },
		qr/"tooltips" has 3 labels, but there are 4 points/, 'an array of undef is still counted' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => 'all of them' },
		qr/"tooltips" must be an array of one label per point, not "all of them"/, 'a string is refused' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => { X => [ 1 .. 4 ] } },
		qr/"tooltips" must be an array of one label per point, not a HASH reference/, 'a hash for one set is refused' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ 'a', ['b'], 'c', {} ] },
		qr/"tooltips" holds text, but index 1, 3 are references/, 'a reference among the labels is refused by index' );
}

# ----------------------------------------------------------------------------
# 3. Nothing to draw: undef throughout, or for the whole option.
# ----------------------------------------------------------------------------
{
	my ($py) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ (undef) x 4 ] }, 'every label undef is accepted' );
	unlike( $py, qr/tooltip_/, 'every label undef: no urls and no rewriting of the SVG' );
	($py) = lives( { plot_type => 'scatter', data => {%one}, tooltips => undef }, '"tooltips => undef" is accepted' );
	unlike( $py, qr/tooltip_/, '"tooltips => undef" writes nothing' );
}

# ----------------------------------------------------------------------------
# 4. Several sets: a hash of one array per set, keyed by the set's name.
# ----------------------------------------------------------------------------
{
	my %sets = (
		A => { X => [ 1, 2 ], Y => [ 1, 2 ] },
		B => { X => [ 3, 4, 5 ], Y => [ 3, 4, 5 ] },
		C => { X => [6], Y => [6] },
	);
	my ( $py, $file ) = lives( { plot_type => 'scatter', data => {%sets}, tooltips => { A => [ 'a0', undef ], B => [ 'b0', 'b1', 'b2' ] } },
		'several sets: a hash of arrays is accepted, a set may be left out' );
	my @calls = $py =~ m/^(ax0\.scatter\(.*\))$/mg;
	is( scalar @calls, 3, 'several sets: three sets are drawn' );
	like( $calls[0], qr/label = 'A', urls = tooltip_urls\)/, 'several sets: A has urls' );
	like( $calls[1], qr/label = 'B', urls = tooltip_urls\)/, 'several sets: B has urls' );
	unlike( $calls[2], qr/urls/, 'several sets: C, with no tooltips, has none' );
	is_deeply( written( $py, 'tooltip_text' ), [ 'a0', 'b0', 'b1', 'b2' ], 'several sets: every label is numbered once' );
	parses_ok( $file, 'several sets: the script parses' );
	# a set given undef in place of an array has no tooltips, as one left out
	($py) = lives( { plot_type => 'scatter', data => {%sets}, tooltips => { A => undef, C => ['c0'] } }, 'several sets: a set given undef is accepted' );
	is( scalar( () = $py =~ m/urls = tooltip_urls/g ), 1, 'several sets: only the set with labels has urls' );
	# one point per set, its values numbers rather than arrays
	($py) = lives( { plot_type => 'scatter', data => { m1 => { MAE => 0.4, R2 => 0.8 }, m2 => { MAE => 0.6, R2 => 0.6 } }, tooltips => { m1 => ['depth 6'] } },
		'one point per set: an array of one label is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), ['depth 6'], 'one point per set: the label is written' );
	dies_with( { plot_type => 'scatter', data => {%sets}, tooltips => { B => [ 'b0', 'b1' ] } },
		qr/"tooltips" of set "B" has 2 labels, but there are 3 points/, 'several sets: a short array is refused, naming the set' );
	dies_with( { plot_type => 'scatter', data => {%sets}, tooltips => [ 'a0', 'a1' ] },
		qr/"data" is a hash of sets, so "tooltips" is a hash of one array of labels per set, e.g. \{ A => \['first', 'second'\] \}, not an ARRAY reference/, 'several sets: an array is refused' );
	dies_with( { plot_type => 'scatter', data => {%sets}, tooltips => { A => [ 'a0', 'a1' ], D => ['d0'], E => ['e0'] } },
		qr/"tooltips" names "D", "E", which are not sets of "data"/, 'several sets: a set that is not in "data" is refused' );
	dies_with( { plot_type => 'scatter', data => {%sets}, tooltips => { A => 'a' } },
		qr/"tooltips" of set "A" must be an array of one label per point, not "a"/, 'several sets: a string for a set is refused' );
}

# ----------------------------------------------------------------------------
# 5. The tooltips are carried by the points' urls, so set_options cannot set one.
# ----------------------------------------------------------------------------
{
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], set_options => 'urls = ["a", "b", "c", "d"]' },
		qr/cannot be given with a "url" or "urls" in "set_options"/, 'one set: "urls" in set_options is refused beside tooltips' );
	dies_with( { plot_type => 'scatter', data => { A => {%one} }, tooltips => { A => [ 1 .. 4 ] }, set_options => { A => 'url = "x"' } },
		qr/"tooltips" of set "A" are drawn through the points' urls/, 'several sets: "url" in set_options is refused beside tooltips' );
	# kept: without tooltips, set_options is passed through as before
	my ($py) = lives( { plot_type => 'scatter', data => {%one}, set_options => 'url = "x"' }, 'set_options with a url and no tooltips is accepted' );
	like( $py, qr/url = "x"/, 'set_options with a url and no tooltips reaches the python' );
}

# ----------------------------------------------------------------------------
# 6. Only an SVG has tooltips. Anything else is warned of and drawn without
#    them, though the labels are still checked.
# ----------------------------------------------------------------------------
{
	my ( $py, $file, $err ) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], output_file => out_file('png') }, 'a PNG with tooltips is accepted' );
	like( $err, qr/"tooltips" are drawn only into an SVG, so they are left out of ".*\.png": give "output_file" a name ending in "\.svg"/, 'a PNG with tooltips warns, naming the file' );
	unlike( $py, qr/tooltip_/, 'a PNG has no urls and no rewriting' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 3 ], output_file => out_file('png') },
		qr/"tooltips" has 3 labels, but there are 4 points/, 'a PNG still has its labels counted' );
	( $py, $file, $err ) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ (undef) x 4 ], output_file => out_file('png') }, 'a PNG whose labels are all undef is accepted' );
	is( $err, '', 'a PNG whose labels are all undef does not warn' );
	foreach my $ext ( 'SVG', 'svgz' ) {
		($py) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], output_file => out_file($ext) }, ".$ext is accepted" );
		like( $py, qr/urls = tooltip_urls/, ".$ext has tooltips" );
	}
	my ( $out, $warned ) = capture { eval { plt( plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], show => 1, execute => 0 ) } };
	like( $warned, qr/left out of a figure that is only shown/, 'a figure only shown warns that it has no tooltips' );
}

# ----------------------------------------------------------------------------
# 7. Subplots and "add" graphs number their labels across the whole figure.
# ----------------------------------------------------------------------------
my %subplots = (
	plots => [
		{ plot_type => 'scatter', data => { X => [ 1, 2 ], Y => [ 1, 2 ] }, tooltips => [ 'first 0', 'first 1' ] },
		{ plot_type => 'bar', data => { A => 1, B => 2 } },
		{ plot_type => 'scatter', data => { X => [ 1, 2 ], Y => [ 2, 1 ] }, tooltips => [ undef, 'third 1' ],
		  add => [ { data => { X => [1.5], Y => [1.5] }, tooltips => ['added'] } ] },
	],
	ncols => 3,
);
{
	my ( $py, $file ) = lives( {%subplots}, 'subplots: tooltips in two subplots and an "add" graph are accepted' );
	is_deeply( written( $py, 'tooltip_text' ), [ 'first 0', 'first 1', 'added', 'third 1' ], 'subplots: the labels of every subplot are numbered in one list' );
	parses_ok( $file, 'subplots: the script parses' );
	dies_with( { plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 2 ] ] }, tooltips => [ 'a', 'b' ] },
		qr/"tooltips" isn't defined for plot_type "plot"/, 'plot refuses tooltips' );
}

# ----------------------------------------------------------------------------
# 8. The caller's data and labels are left as they were given.
# ----------------------------------------------------------------------------
{
	my @labels = ( 'a', undef, 3, 'd' );
	my %data   = ( X => [ 1, 2, 3, 4 ], Y => [ 1, 2, 3, 4 ] );
	my %sets   = ( A => { X => [ 1, 2 ], Y => [ 1, 2 ] } );
	lives( { plot_type => 'scatter', data => \%data, tooltips => \@labels }, 'one set, for the caller check' );
	is_deeply( \@labels, [ 'a', undef, 3, 'd' ], 'the labels are as they were given' );
	lives( { plot_type => 'scatter', data => \%sets, tooltips => undef }, 'several sets with undef tooltips, for the caller check' );
	is_deeply( [ sort keys %sets ], ['A'], 'no set is added to the caller\'s data' );
}

# ----------------------------------------------------------------------------
# 9. Rendered: each title sits on its own point.
# ----------------------------------------------------------------------------
SKIP: {
	skip( 'no matplotlib >= 3.10', 12 ) unless $mpl_available;
	# x increases with the label, so sorting the markers by x gives the labels
	# back in order if, and only if, each is on its own point
	my $svg = render( plot_type => 'scatter', data => { X => [ 1, 2, 3, 4 ], Y => [ 3, 1, 4, 2 ] }, tooltips => [ 'p1', undef, 'p3 <&> "ρ"', 'p4' ] );
	is_deeply( [ labels_by_x($svg) ], [ 'p1', 'p3 <&> "ρ"', 'p4' ], 'one set: each title is on its own point, the undef point has none' );
	# the url, not the bare name, which is also the class of each labelled <g>
	unlike( $svg, qr/#matplotlib-simple-tooltip-|<a /, 'one set: no link is left in the SVG' );
	like( $svg, qr/\A<\?xml version='1\.0' encoding='utf-8'\?>\n<svg xmlns="http:\/\/www\.w3\.org\/2000\/svg"/, 'one set: the SVG is written back with its own namespace as the default' );
	# matplotlib leaves out the NaN point and the one not above 0 on a log axis
	$svg = render( plot_type => 'scatter', data => { X => [ 1, 2, 3, 4, 5 ], Y => [ 1, 'nan', 3, -1, 5 ] }, logscale => ['y'], tooltips => [ map { "p$_" } 1 .. 5 ] );
	is_deeply( [ labels_by_x($svg) ], [ 'p1', 'p3', 'p5' ], 'points not drawn take their titles with them, and the rest keep theirs' );
	# several colored sets, in a gzipped SVG
	$svg = render(
		plot_type   => 'scatter',
		output_file => out_file('svgz'),
		data        => {
			A => { X => [ 1, 3 ], Y => [ 1, 3 ], Z => [ 1, 2 ] },
			B => { X => [ 2, 4 ], Y => [ 2, 4 ], Z => [ 3, 4 ] },
		},
		tooltips => { A => [ 'a1', 'a3' ], B => [ 'b2', undef ] },
	);
	is_deeply( [ labels_by_x($svg) ], [ 'a1', 'b2', 'a3' ], 'several colored sets in an .svgz: each title is on its own point' );
	# subplots: the markers of each subplot are in an axes of their own, so
	# the titles are checked in the order of the document
	$svg = render(%subplots);
	is_deeply( [ map { $_->[0] } titled_points($svg) ], [ 'first 0', 'first 1', 'added', 'third 1' ], 'subplots: every subplot and "add" graph has its titles, an "add" graph before its subplot' );
	# a figure that also has a link of the caller's own keeps it
	$svg = render( plot_type => 'scatter', data => { A => { X => [1], Y => [1] }, B => { X => [2], Y => [2] } }, tooltips => { A => ['a'] }, set_options => { B => 'urls = ["https://example.org/"]' } );
	like( $svg, qr/<a xlink:href="https:\/\/example\.org\/"/, 'a url of the caller\'s own is left as it was' );
	is_deeply( [ labels_by_x($svg) ], ['a'], 'beside a url of the caller\'s own, the tooltip is drawn' );
	# a number of points large enough that matplotlib draws the markers with
	# its <use> optimisation
	my @x = 1 .. 300;
	$svg = render( plot_type => 'scatter', data => { X => \@x, Y => [ map { $_ % 17 } @x ] }, tooltips => [ map { $_ % 2 ? "odd $_" : undef } @x ] );
	is_deeply( [ labels_by_x($svg) ], [ map { "odd $_" } grep { $_ % 2 } @x ], '300 points: each odd point has its title' );
	# the caller's file name is whatever it is, spaces and all
	my $spaced = File::Spec->catfile( $TMP, 'with space ' . $seq++ . '.svg' );
	$svg = render( plot_type => 'scatter', output_file => $spaced, data => {%one}, tooltips => [ 1 .. 4 ] );
	is_deeply( [ labels_by_x($svg) ], [ 1 .. 4 ], 'a file name with a space is rewritten in place' );
	# a single-point square marker, which matplotlib may draw as a <path>
	# rather than through its <use> optimisation
	$svg = render( plot_type => 'scatter', data => { X => [1], Y => [1] }, tooltips => ['only'], set_options => 'marker = "s"' );
	like( $svg, qr/<title>only<\/title>/, 'one square point has its title' );
	# the figure is otherwise what it was: the same number of markers drawn
	my $plain = render( plot_type => 'scatter', data => { X => \@x, Y => [ map { $_ % 17 } @x ] } );
	my $tipped = render( plot_type => 'scatter', data => { X => \@x, Y => [ map { $_ % 17 } @x ] }, tooltips => [ map {"p$_"} @x ] );
	is( scalar( () = $tipped =~ m/<use /g ), scalar( () = $plain =~ m/<use /g ), 'the same markers are drawn with tooltips as without' );
}

# ----------------------------------------------------------------------------
# 10. A label is text, reaching the SVG exactly as given: nothing in it is
#     python, and "0", "" and a dualvar are labels like any other.
# ----------------------------------------------------------------------------
my @awkward = (
	q{it's},                   # closes a '...' literal
	q{say "hi"},               # closes a "..." literal
	q{C:\build\new},           # \b and \n are escapes in a python literal
	"two\nlines",
	q{''' """},                # closes a triple-quoted literal
	'ρ = 0.5 ± 0.1',
	'0',                       # false in Perl, and still a label
	'',
	q{urls = ['x']},           # looks like an option, but is a label
);
{
	my @empty;
	my $dualvar = scalar @empty;    # a 0 that is also the string "0"; see CLAUDE.md
	my $big = 1e21;
	my @labels = ( @awkward, $dualvar, $big );
	my %data = ( X => [ 1 .. @labels ], Y => [ 1 .. @labels ] );
	my ( $py, $file ) = lives( { plot_type => 'scatter', data => \%data, tooltips => \@labels }, 'awkward text: accepted' );
	# "$big" and not '1e+21': quadmath and long-double perls print 1000000000000000000000, and Strawberry 5.24 prints 1e+021 (CPAN Testers, 0.321 and 0.322)
	is_deeply( written( $py, 'tooltip_text' ), [ @awkward, '0', "$big" ],'awkward text: each label is written as the text it is, numbers as Perl prints them' );
	is( scalar( grep { defined } @{ written( $py, 'tooltip_urls' ) } ), scalar @labels, 'awkward text: "0" and "" are labels, each with a url' );
	unlike( $py, qr/it's|C:\\build/, 'awkward text: no label is pasted into the python' );
	parses_ok( $file, 'awkward text: the script parses' );
}

# ----------------------------------------------------------------------------
# 11. The numbering starts again with each figure, even after one that died
#     part way through its labels.
# ----------------------------------------------------------------------------
{
	# A is counted before B is found to be short
	dies_with( { plot_type => 'scatter', data => { A => { X => [ 1, 2 ], Y => [ 1, 2 ] }, B => { X => [ 3, 4 ], Y => [ 3, 4 ] } }, tooltips => { A => [ 'a0', 'a1' ], B => ['b0'] } },
		qr/"tooltips" of set "B" has 1 labels, but there are 2 points/, 'a figure dies at its second set' );
	my ($py) = lives( { plot_type => 'scatter', data => { X => [1], Y => [1] }, tooltips => ['z'] }, 'the next figure is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), ['z'], 'the next figure has only its own label' );
	is_deeply( written( $py, 'tooltip_urls' ), ['#matplotlib-simple-tooltip-0'], 'the next figure numbers from 0' );
	($py) = lives( { plot_type => 'scatter', data => { X => [1], Y => [1] }, tooltips => ['y'] }, 'a figure after one that succeeded is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), ['y'], 'a figure after one that succeeded has only its own label' );
}

# ----------------------------------------------------------------------------
# 12. Beside the other scatter options: color, "keys", "key_order", and the
#     "label" and "marker" of set_options.
# ----------------------------------------------------------------------------
{
	my %colored = ( X => [ 1, 2, 3 ], Y => [ 1, 2, 3 ], Z => [ 5, 6, 7 ] );
	my ($py) = lives( { plot_type => 'scatter', data => {%colored}, tooltips => [qw(a b c)], cblabel => 'Z value' }, 'colored set: accepted' );
	like( $py, qr/^im = ax0\.scatter\(x, y, c = z, .*, urls = tooltip_urls\)$/m, 'colored set: the urls reach the colored ax.scatter' );
	like( $py, qr/^fig\.colorbar\(im, label = 'Z value'/m, 'colored set: the colorbar is still drawn' );
	# "keys" chooses which array is drawn as x; the labels go by index all the same
	($py) = lives( { plot_type => 'scatter', data => {%colored}, keys => [qw(Y X Z)], tooltips => [ 'a', undef, 'c' ] }, '"keys": accepted' );
	is_deeply( written( $py, 'tooltip_urls' ), [ '#matplotlib-simple-tooltip-0', undef, '#matplotlib-simple-tooltip-1' ], '"keys": the urls are by point, as given' );
	my %sets = ( A => { X => [1], Y => [1] }, B => { X => [2], Y => [2] } );
	($py) = lives( { plot_type => 'scatter', data => {%sets}, key_order => [qw(B A)], tooltips => { A => ['a'], B => ['b'] },
		set_options => { A => 'label = "first", marker = "s"' } }, 'key_order and set_options: accepted' );
	my @calls = $py =~ m/^(ax0\.scatter\(.*\))$/mg;
	like( $calls[0], qr/label = 'B', urls = tooltip_urls\)$/, 'key_order: B is drawn first, with its urls' );
	like( $calls[1], qr/label = "first", marker = "s", urls = tooltip_urls\)$/, 'set_options: the label and marker of A are kept beside its urls' );
}

# ----------------------------------------------------------------------------
# 13. The other ways into scatter: "p", "df", and an "add" graph on a plot of
#     another type.
# ----------------------------------------------------------------------------
my @rows = (
	{ name => 'Ann', height => 160, weight => 55, sex => 'F' },
	{ name => 'Bo',  height => 180, weight => 80, sex => 'M' },
	{ name => 'Cy',  height => 170, weight => 70, sex => 'M' },
);
{
	my ($py) = lives( { p => [ { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ] }, { plot_type => 'bar', data => { A => 1 } } ] }, '"p": accepted' );
	is_deeply( written( $py, 'tooltip_text' ), [ 1 .. 4 ], '"p": the labels are written' );
	($py) = lives( { plot_type => 'scatter', df => \@rows, x => 'height', y => 'weight', tooltips => [ map { $_->{name} } @rows ] }, '"df": one label per row is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), [qw(Ann Bo Cy)], '"df": the labels are written in the order of the rows' );
	($py) = lives( { plot_type => 'scatter', df => \@rows, x => 'height', y => 'weight', by => 'sex', tooltips => { F => ['Ann'], M => [ 'Bo', 'Cy' ] } }, '"df" with "by": a hash keyed by group is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), [qw(Ann Bo Cy)], '"df" with "by": the labels are written' );
	# A row without a value is left out of the plot, so a label for every row
	# no longer has a point each. It is refused rather than shifted onto the
	# next row's point.
	my @gappy = ( @rows, { name => 'Di', height => 175, weight => undef, sex => 'F' } );
	dies_with( { plot_type => 'scatter', df => \@gappy, x => 'height', y => 'weight', tooltips => [ map { $_->{name} } @gappy ] },
		qr/"tooltips" has 4 labels, but there are 3 points/, '"df" with a row left out: a label for every row is refused, not shifted' );
	($py) = lives( { plot_type => 'plot', data => { A => [ [ 1, 2 ], [ 1, 2 ] ] }, add => [ { plot_type => 'scatter', data => { X => [1.5], Y => [1.5] }, tooltips => ['added'] } ] },
		'an "add" scatter on a line plot is accepted' );
	is_deeply( written( $py, 'tooltip_text' ), ['added'], 'an "add" scatter on a line plot has its label' );
}

# ----------------------------------------------------------------------------
# 14. Refused where it would not reach a scatter.
# ----------------------------------------------------------------------------
{
	dies_with( { %subplots, tooltips => [ 'a', 'b' ] }, qr/"tooltips" belongs to one subplot: give it in the hash of the subplot it belongs to/,
		'at the top of a figure of subplots, it is refused' );
	dies_with( { plot_type => 'scatter', data => {%one}, tooltip => [ 1 .. 4 ] }, qr/"tooltip" isn't defined.*perhaps you meant one of these defined keywords: \([^)]*\btooltips\b/s,
		'"tooltip" is refused, with "tooltips" suggested' );
	dies_with( { plot_type => 'hexbin', data => {%one}, tooltips => [ 1 .. 4 ] }, qr/"tooltips" isn't defined for plot_type "hexbin"/, 'hexbin refuses it' );
}

# ----------------------------------------------------------------------------
# 15. The SVG is rewritten after it is saved and before it is shown, and its
#     name reaches python only as data.
# ----------------------------------------------------------------------------
{
	my ($py) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], show => 1 }, 'show and an SVG: accepted' );
	my ( $saved, $rewritten, $shown ) = map { index( $py, $_ ) } ( 'plt.savefig(', 'svg_tree.write(', 'plt.show()' );
	ok( $saved >= 0 && $saved < $rewritten, 'the SVG is rewritten after it is saved' );
	ok( $rewritten < $shown, 'the SVG is rewritten before the figure is shown' );
	my $quoted = File::Spec->catfile( $TMP, q{it's a \new} . $seq++ . '.svg' );
	my $file;
	( $py, $file ) = lives( { plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], output_file => $quoted }, 'a name with a quote and a backslash: accepted' );
	is( index( $py, q{it's} ), -1, 'a name with a quote and a backslash is not pasted into the python' );
	parses_ok( $file, 'a name with a quote and a backslash: the script parses' );
}

# ----------------------------------------------------------------------------
# 16. Subplots that share a colorbar.
# ----------------------------------------------------------------------------
my %shared = (
	plots => [
		{ plot_type => 'scatter', data => { X => [ 1, 2 ], Y => [ 1, 2 ], Z => [ 1, 2 ] }, tooltips => [ 'l0', 'l1' ] },
		{ plot_type => 'scatter', data => { X => [ 1, 2 ], Y => [ 1, 2 ], Z => [ 3, 4 ] }, tooltips => [ undef, 'r1' ] },
	],
	ncols           => 2,
	shared_colorbar => [ 0, 1 ],
);
{
	my ( $py, $file ) = lives( {%shared}, 'shared colorbar: accepted' );
	is_deeply( written( $py, 'tooltip_text' ), [qw(l0 l1 r1)], 'shared colorbar: the labels of both subplots are written' );
	parses_ok( $file, 'shared colorbar: the script parses' );
}

# ----------------------------------------------------------------------------
# 17. Rendered, for the blocks above.
# ----------------------------------------------------------------------------
SKIP: {
	skip( 'no matplotlib >= 3.10', 10 ) unless $mpl_available;
	my @labels = @awkward;
	my $svg = render( plot_type => 'scatter', data => { X => [ 1 .. @labels ], Y => [ 1 .. @labels ] }, tooltips => \@labels );
	# ElementTree writes an empty <title/>, which titled_points does not match
	is_deeply( [ labels_by_x($svg) ], [ grep { length } @awkward ], 'awkward text: each label is in the SVG as given' );
	like( $svg, qr{<title\s*/>}, 'awkward text: the empty label is an empty title' );
	# "keys" draws Y as x: sorted by the drawn x, the labels come back in the
	# order of Y, which is 10, 20, 30
	$svg = render( plot_type => 'scatter', data => { X => [ 1, 2, 3 ], Y => [ 30, 10, 20 ] }, keys => [ 'Y', 'X' ], tooltips => [qw(thirty ten twenty)] );
	is_deeply( [ labels_by_x($svg) ], [qw(ten twenty thirty)], '"keys": each title is on its own point when the axes are swapped' );
	$svg = render( plot_type => 'scatter', data => { X => [ 3, 1, 2 ], Y => [ 1, 2, 3 ], Z => [ 7, 8, 9 ] }, tooltips => [qw(c a b)] );
	is_deeply( [ labels_by_x($svg) ], [qw(a b c)], 'colored set: each title is on its own point' );
	$svg = render( p => [ { plot_type => 'scatter', data => { X => [ 2, 1 ], Y => [ 1, 2 ] }, tooltips => [qw(two one)] } ] );
	is_deeply( [ labels_by_x($svg) ], [qw(one two)], '"p": each title is on its own point' );
	$svg = render( plot_type => 'scatter', df => \@rows, x => 'height', y => 'weight', by => 'sex', tooltips => { F => ['Ann'], M => [ 'Bo', 'Cy' ] } );
	is_deeply( [ labels_by_x($svg) ], [qw(Ann Cy Bo)], '"df" with "by": each title is on its own point' );
	$svg = render(%shared);
	is_deeply( [ map { $_->[0] } titled_points($svg) ], [qw(l0 l1 r1)], 'shared colorbar: both subplots have their titles' );
	my $quoted = File::Spec->catfile( $TMP, q{it's a \new} . $seq++ . '.svg' );
	$svg = render( plot_type => 'scatter', output_file => $quoted, data => {%one}, tooltips => [ 1 .. 4 ] );
	is_deeply( [ labels_by_x($svg) ], [ 1 .. 4 ], 'a name with a quote and a backslash is rewritten in place' );
	# The script stands alone: written with execute => 0 and run later, it
	# still puts the titles in.
	my ( undef, $script ) = gen( plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ], output_file => ( my $later = out_file() ) );
	my ( $out, $err, $status ) = capture { local $ENV{MPLBACKEND} = 'Agg'; system( @PY, $script ) };
	is( $status, 0, 'a script written with execute => 0 runs later' ) or diag("  python: $err");
	is_deeply( [ labels_by_x( -e $later ? slurp($later) : '' ) ], [ 1 .. 4 ], 'a script run later puts the titles in' );
}

# ----------------------------------------------------------------------------
# 18. The label is drawn by a script in the SVG, not left to the browser: in
#     0.321 the <title>s alone showed nothing in Firefox or Chromium. The
#     script's behaviour in a browser is not tested here, since that needs
#     one; these check that it is there, once, and finds the points.
# ----------------------------------------------------------------------------
{
	my ($py) = gen( plot_type => 'scatter', data => {%one}, tooltips => [ 1 .. 4 ] );
	like( $py, qr/^tooltip_script = r'''/m, 'the script that draws the label is written into the python' );
	like( $py, qr/link\.set\('class', 'matplotlib-simple-tooltip'\)/, 'each labelled point is given the class the script looks for' );
}
SKIP: {
	skip( 'no matplotlib >= 3.10', 5 ) unless $mpl_available;
	my $svg = render( plot_type => 'scatter', data => {%one}, tooltips => [ 'a', undef, 'c', 'd' ] );
	my @classed = $svg =~ m{<g class="matplotlib-simple-tooltip">\s*<title>}g;
	is( scalar @classed, 3, 'each point with a label, and only those, is a <g> of the class, its <title> first' );
	my @scripts = $svg =~ m{<script\b}g;
	is( scalar @scripts, 1, 'the SVG has one script' );
	like( $svg, qr{<script type="text/javascript">[^<]*g\.matplotlib-simple-tooltip[^<]*</script>\s*</svg>\s*\z}, 'the script is the last thing in the SVG, so that it runs after every point and draws on top' );
	$svg = render( plot_type => 'scatter', output_file => out_file('svgz'), data => {%one}, tooltips => [ 1 .. 4 ] );
	like( $svg, qr{<script type="text/javascript">}, 'an .svgz has the script too' );
	$svg = render( plot_type => 'scatter', data => {%one} );
	unlike( $svg, qr{<script\b}, 'a scatter with no tooltips has no script' );
}

done_testing();
