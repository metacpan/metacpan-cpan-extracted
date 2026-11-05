#!/usr/bin/env perl
#
# The note that a saved figure carries about how it was made: matplotlib's
# "Creator" metadata, which an SVG holds as <dc:creator><cc:Agent><dc:title>.
# It ends ", by <user> on <host>", both read by the generated script as it
# runs, so they name whoever ran it and where.
#
# An SVG carries that note and nothing else of matplotlib's: no DOCTYPE, which
# matplotlib 3.11.2 writes from the fixed string svgProlog in backend_svg.py,
# and no <dc:date>, <dc:format> or <dc:type>. Other formats keep matplotlib's
# metadata as it was.
#
# The first block reads the generated python as text and runs everywhere,
# including a Windows smoker with no python. The rest need python3 and
# matplotlib >= 3.10, and skip without them.
#
# The gnuplot and ggplot2 engines put the same note in the same place in an
# SVG, naming their own versions where matplotlib's names Python's and its
# own. Neither gnuplot nor an R device writes metadata: Perl stamps gnuplot's
# SVG once gnuplot has run it (block 5, which needs nothing but Perl, and 6),
# and the R script stamps its own (7). Those blocks gate on gnuplot 5.2 and
# ggplot2 3.5.0, as t/17.gnuplot.t and t/18.ggplot2.t do.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Sys::Hostname ();
use Matplotlib::Simple;
# The interpreter the module itself runs; see t/07.review.fixes.t.
my @PY = Matplotlib::Simple::Matplotlib::python_command();
my $PY = join ' ', @PY;
use Test::More;

my $TMP = tempdir( CLEANUP => 1 );
my $seq = 0;

# "no warnings 'exec'" departs from this file's FATAL warnings on purpose. qx
# forks, and when python3 is absent the child's "Can't exec" warning is fatal:
# the child dies instead of _exit()ing, so it runs END blocks, and File::Temp
# 0.22 (shipped with perls up to 5.16) cleans up every tempdir in END without
# checking that the process which made it is the one exiting; 0.23 (perl
# 5.18) checks, and keeps the directory. The child removed $TMP from under the
# parent, and block 5 died with "can't write .../gen5.svg: No such file or
# directory" (CPAN Testers FAIL for 0.334, perl 5.14.4 on FreeBSD 15.0, no
# python). Every test's probe of @PY does the same; qx then returns undef,
# hence the "// ''".
my $python_raw = ( scalar @PY ? do { no warnings 'exec'; qx/$PY --version 2>&1/ } // '' : '' );    # 'exec': see t/16.creator.t
my $python_available = ( $? == 0 && $python_raw =~ m/Python\s+3\.\d+/i ) ? 1 : 0;
my $mpl_available = 0;
if ($python_available) {
	# 3.10 is the floor every render test gates on; see t/15.tooltips.t.
	my $raw = qx/$PY -c "import matplotlib; print(matplotlib.__version__)" 2>&1/;
	if ( $? == 0 && $raw =~ m/^\s*(\d+)\.(\d+)/ ) {
		$mpl_available = ( $1 > 3 || ( $1 == 3 && $2 >= 10 ) ) ? 1 : 0;
	}
}
diag( $mpl_available ? 'matplotlib >= 3.10 found (render checks ON)' : 'no matplotlib >= 3.10 (render checks skipped)' );

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

sub creator {
	my ($svg) = @_;
	return $svg =~ m{<dc:creator>\s*<cc:Agent>\s*<dc:title>(.*?)</dc:title>}s ? $1 : '';
}

my %bar = ( plot_type => 'bar', data => { A => 1, B => 2 } );

# ----------------------------------------------------------------------------
# 1. The script reads the user and the host itself.
# ----------------------------------------------------------------------------
my ( undef, undef, $script ) = capture { plt( {%bar, output_file => out_file(), execute => 0} ) };
my $py = slurp($script);
like( $py, qr/^\s*creator_user = getpass\.getuser\(\)$/m, 'the user is read by the script, from getpass' );
like( $py, qr/^creator_host = platform\.node\(\) or 'unknown host'/m, 'the host is read by the script, from platform.node' );
like( $py, qr/^plt\.savefig\(.*'Creator':.*\+ ', by ' \+ creator_user \+ ' on ' \+ creator_host(?:, 'Date': None.*)?\}\)$/m, 'both end the Creator note' );

# ----------------------------------------------------------------------------
# 2. Rendered: the SVG names this user and this host.
# ----------------------------------------------------------------------------
SKIP: {
	skip( 'no matplotlib >= 3.10', 3 ) unless $mpl_available;
	local $ENV{MPLBACKEND} = 'Agg';
	# The same calls, run by the same interpreter with the same environment.
	my ( $who ) = capture { system( @PY, '-c', 'import getpass, platform; print(getpass.getuser()); print(platform.node())' ) };
	my ( $user, $host ) = split /\r?\n/, $who;
	my $file = out_file();
	capture { plt( {%bar, output_file => $file} ) };
	is( creator( slurp($file) ) =~ m/, by (.*) on (.*)\z/ ? "$1|$2" : '', "$user|$host", 'the SVG ends its note with the user and the host' );
	# getpass.getuser() made to fail, as it does with no LOGNAME, USER, LNAME
	# or USERNAME and no password database.
	$file = out_file();
	( undef, undef, $script ) = capture { plt( {%bar, output_file => $file, execute => 0} ) };
	my ( undef, $err, $status ) = capture {
		system( @PY, '-c', 'import getpass, runpy, sys; getpass.getuser = lambda: (_ for _ in ()).throw(OSError(1)); runpy.run_path(sys.argv[1])', $script );
	};
	is( $status, 0, 'a user that cannot be found does not stop the figure being saved' ) or diag("  python: $err");
	like( creator( -e $file ? slurp($file) : '' ), qr/, by unknown user on \Q$host\E\z/, 'and is named "unknown user"' );
}

# ----------------------------------------------------------------------------
# 3. Only an SVG's script asks for less metadata and cuts the DOCTYPE.
# ----------------------------------------------------------------------------
for my $ext (qw(svg SVGZ)) {
	( undef, undef, $script ) = capture { plt( {%bar, output_file => out_file($ext), execute => 0} ) };
	$py = slurp($script);
	like( $py, qr/^plt\.savefig\(.*'Creator':.*, 'Date': None, 'Format': None, 'Type': None\}\)$/m, ".$ext: Date, Format and Type are left out" );
	like( $py, qr/re\.sub\(rb'<!DOCTYPE/, ".$ext: the DOCTYPE is cut" );
}
for my $ext (qw(png pdf)) {
	( undef, undef, $script ) = capture { plt( {%bar, output_file => out_file($ext), execute => 0} ) };
	$py = slurp($script);
	unlike( $py, qr/'Date': None/, ".$ext: matplotlib's metadata is left as it was" );
	unlike( $py, qr/DOCTYPE/, ".$ext: and there is no DOCTYPE to cut" );
}

# ----------------------------------------------------------------------------
# 4. Rendered: the SVG holds the Creator, and no DOCTYPE, date, format or type.
# ----------------------------------------------------------------------------
SKIP: {
	skip( 'no matplotlib >= 3.10', 12 ) unless $mpl_available;
	local $ENV{MPLBACKEND} = 'Agg';
	my $plain = out_file();
	my $zipped = out_file('svgz');
	# A tooltip SVG is written back by ElementTree, which is a second way of
	# writing the file and must give the same result.
	my $tipped = out_file();
	capture {
		plt( {%bar, output_file => $plain} );
		plt( {%bar, output_file => $zipped} );
		plt( {plot_type => 'scatter', data => { x => [1, 2], y => [3, 4] }, tooltips => ['a', 'b'], output_file => $tipped} );
	};
	my ( $unzipped, $gz_err, $gz_status ) = capture { system( @PY, '-c', 'import gzip, sys; sys.stdout.buffer.write(gzip.open(sys.argv[1]).read())', $zipped ) };
	is( $gz_status, 0, '.svgz could be read' ) or diag("  python: $gz_err");
	for my $case ( [ '.svg', -e $plain ? slurp($plain) : '' ], [ '.svgz', $unzipped ], [ 'tooltips', -e $tipped ? slurp($tipped) : '' ] ) {
		my ( $name, $svg ) = @$case;
		unlike( $svg, qr/<!DOCTYPE/, "$name: no DOCTYPE" );
		unlike( $svg, qr/<dc:(?:date|format|type)\b/, "$name: no dc:date, dc:format or dc:type" );
		like( creator($svg), qr/ called using "plt" in .*, by .+ on .+\z/, "$name: the Creator is kept" );
	}
	my $pdf = out_file('pdf');
	my ( undef, $pdf_err ) = capture { plt( {%bar, output_file => $pdf} ) };
	unlike( $pdf_err, qr/Unknown infodict keyword/, '.pdf: matplotlib does not warn about the metadata' );
	ok( -s $pdf, '.pdf: and it is written' );
}

# ----------------------------------------------------------------------------
# 5. gnuplot: the note Perl adds to an SVG, without gnuplot.
# ----------------------------------------------------------------------------
{
	require Matplotlib::Simple::Gnuplot;
	my $file = out_file();
	open my $o, '>:raw', $file or die "can't write $file: $!";
	# The head of an SVG from gnuplot 6.0's svg terminal.
	print {$o} qq{<?xml version="1.0" encoding="utf-8"  standalone="no"?>\n<svg \n viewBox="0 0 640 480"\n xmlns="http://www.w3.org/2000/svg"\n>\n\n<title>Gnuplot</title>\n<desc>Produced by GNUPLOT 6.0 patchlevel 0 </desc>\n\n<g id="gnuplot_canvas">\n\t<title>gnuplot_plot_1</title>\n</g>\n</svg>\n};
	close $o or die "can't close $file: $!";
	{
		local $ENV{LOGNAME} = "r\xcf\x81&<o>";    # an environment holds bytes: this is UTF-8 for "r\x{3c1}&<o>"
		Matplotlib::Simple::Gnuplot::creator_svg( $file, "/R&D/\x{3c1}.pl called using \"plt\"", '6.0.0' );
	}
	my $svg = slurp($file);
	my $host = eval { Sys::Hostname::hostname() } // 'unknown host';
	is( creator($svg), "/R&amp;D/\x{3c1}.pl called using \"plt\", gnuplot 6.0.0, by r\x{3c1}&amp;&lt;o&gt; on $host", 'the note, as UTF-8 and escaped for XML, ends with the gnuplot version, the user and the host' );
	like( $svg, qr{<svg [^>]*>\n <metadata>\n  <rdf:RDF }, 'in <metadata>, right after the <svg> tag, as matplotlib puts it' );
	unlike( $svg, qr{<title>Gnuplot</title>|<desc>}, "gnuplot's own title and description are gone" );
	like( $svg, qr{<title>gnuplot_plot_1</title>}, 'the titles of the plots are not' );
	my ( undef, undef, $gp ) = capture { plt( {%bar, engine => 'gnuplot', output_file => out_file(), execute => 0} ) };
	like( slurp($gp), qr/^print sprintf\("Matplotlib::Simple gnuplot %\.1f\.%s", GPVAL_VERSION, GPVAL_PATCHLEVEL\)$/m, 'the script names the gnuplot that ran it' );
}

# ----------------------------------------------------------------------------
# 6. gnuplot, rendered: each SVG it draws carries the note.
# ----------------------------------------------------------------------------
my $GP = Matplotlib::Simple::program_from_env('MATPLOTLIB_SIMPLE_GNUPLOT') // 'gnuplot';
my ( $gp_out, undef, $gp_status ) = capture {
	no warnings 'exec';    # a missing gnuplot is a skip, not a failure
	system( $GP, '--version' );
};
# Only "gnuplot" and a major.minor are relied on: a smoker's gnuplot (Fedora 43,
# 0.333) passed this gate but did not print " patchlevel " after the version, and
# the version left undef died under FATAL warnings.
my ($gp_version) = ( $gp_status == 0 ) ? $gp_out =~ m/^gnuplot\s+(\d+\.\d+)/ : ();
my $gp_available = ( defined $gp_version && $gp_version =~ m/^(\d+)\.(\d+)\z/ && ( $1 > 5 || ( $1 == 5 && $2 >= 2 ) ) ) ? 1 : 0;
SKIP: {
	skip( 'no gnuplot >= 5.2', 4 ) unless $gp_available;
	my $version = $gp_version;    # the script prints GPVAL_VERSION as %.1f, then the patch level
	my $file = out_file();
	capture { plt( {%bar, engine => 'gnuplot', output_file => $file} ) };
	like( creator( slurp($file) ), qr/ called using "plt" in .* with Perl [\d.]+, gnuplot \Q$version.\E\S+, by \Q${\ Matplotlib::Simple::Gnuplot::creator_user() }\E on .+\z/, 'the SVG names gnuplot, its version and who ran it' );
	# Two figures in one script, run by the second.
	my $fh = File::Temp->new( DIR => $TMP, SUFFIX => '.gp', UNLINK => 1 );
	my @files = ( out_file(), out_file() );
	capture {
		plt( {%bar, engine => 'gnuplot', fh => $fh, output_file => $files[0], execute => 0} );
		plt( {%bar, engine => 'gnuplot', fh => $fh, output_file => $files[1]} );
	};
	like( creator( slurp($_) ), qr/, gnuplot /, 'a shared script: figure ' . ( $_ eq $files[0] ? 1 : 2 ) . ' carries the note' ) foreach @files;
	# gnuplot cannot write the note, so a script run without Perl leaves none.
	$file = out_file();
	my ( undef, undef, $gp ) = capture { plt( {%bar, engine => 'gnuplot', output_file => $file, execute => 0} ) };
	capture { system( $GP, $gp ) };
	is( creator( slurp($file) ), '', 'a script written with execute => 0 and run by gnuplot alone gives none' );
}

# ----------------------------------------------------------------------------
# 7. ggplot2: the R script stamps its own SVG.
# ----------------------------------------------------------------------------
{
	my ( undef, undef, $r ) = capture { plt( {%bar, engine => 'ggplot2', output_file => out_file(), execute => 0} ) };
	like( slurp($r), qr/^\t\tnote <- paste0\(.*, ", R ", getRversion\(\), ", ggplot2 ", utils::packageVersion\("ggplot2"\),$/m, 'ggplot2: the script reads the R and ggplot2 versions as it runs' );
	( undef, undef, $r ) = capture { plt( {%bar, engine => 'ggplot2', output_file => out_file('png'), execute => 0} ) };
	unlike( slurp($r), qr/Sys\.info/, 'ggplot2: and only for an SVG' );
}
my @R = ( Matplotlib::Simple::program_from_env('MATPLOTLIB_SIMPLE_RSCRIPT') // 'Rscript' );
my ( $r_out, undef, $r_status ) = capture {
	no warnings 'exec';
	# single quotes only: see CLAUDE.md on list-form system on Win32
	system( @R, '-e', q{cat(if (requireNamespace('ggplot2', quietly = TRUE) && utils::packageVersion('ggplot2') >= '3.5.0') 'yes' else 'no', Sys.info()[['user']], Sys.info()[['nodename']], sep = '\n')} );
};
my ( $gg_ok, $r_user, $r_host ) = ( $r_status == 0 ) ? split( /\r?\n/, $r_out ) : ('no');
SKIP: {
	skip( 'no ggplot2 >= 3.5.0', 4 ) unless ( $gg_ok // '' ) eq 'yes';
	my $file = out_file();
	capture { plt( {%bar, engine => 'ggplot2', output_file => $file} ) };
	like( creator( slurp($file) ), qr/ called using "plt" in .* with Perl [\d.]+, R [\d.]+, ggplot2 [\d.]+, by \Q$r_user\E on \Q$r_host\E\z/, 'the SVG names R, ggplot2, their versions and who ran it' );
	my $fh = File::Temp->new( DIR => $TMP, SUFFIX => '.R', UNLINK => 1 );
	my @files = ( out_file(), out_file() );
	capture {
		plt( {%bar, engine => 'ggplot2', fh => $fh, output_file => $files[0], execute => 0} );
		plt( {%bar, engine => 'ggplot2', fh => $fh, output_file => $files[1]} );
	};
	like( creator( slurp($_) ), qr/, ggplot2 /, 'a shared script: figure ' . ( $_ eq $files[0] ? 1 : 2 ) . ' carries the note' ) foreach @files;
	$file = out_file();
	my ( undef, undef, $r ) = capture { plt( {%bar, engine => 'ggplot2', output_file => $file, execute => 0} ) };
	capture { system( @R, $r ) };
	like( creator( slurp($file) ), qr/, ggplot2 [\d.]+, by /, 'a script written with execute => 0 and run later gives it too' );
}

done_testing();
