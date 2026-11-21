#!/usr/bin/env perl
#
# The fixes of 0.3345, one block each, in the form of t/21.review.fixes.0.3343.t.
#
# They came from the author's TODO.md and from the author's report of Eye of
# GNOME, both on 2026-11-20, and each was reproduced against 0.3344 before it
# was fixed. Each block also checks what the fix had to keep.
#
# Nothing here runs python, gnuplot or R: every figure is execute => 0, or run
# by a stand-in, so all of it runs on a Windows smoker.
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

sub figure {
	my (%spec) = @_;
	return sub { plt( output_file => out_file(), execute => 0, %spec ) };
}

#
# 1. "label" with a hash of hashes was dropped: bar and barh sorted the inner
#    keys and wrote over "label" with them, so nothing could put "staffed"
#    under "authorized" in a stack. It now gives the order of the series, in
#    every engine and style; ggplot2's native stack also put the first series
#    on top, and now puts it at the bottom.
#
{
	my $script_of = sub {
		my (%spec) = @_;
		my ( undef, undef, $file ) = capture { plt( output_file => out_file(), execute => 0, %spec ) };
		open my $fh, '<:encoding(UTF-8)', $file or die "can't read $file: $!";
		local $/;
		my $text = <$fh>;
		close $fh or die "can't close $file: $!";
		return $text;
	};
	my %staff = ( KDC => { authorized => 56, staffed => 12 } );
	my @order = ( 'staffed', 'authorized' );
	foreach my $engine ( 'matplotlib', 'gnuplot', 'ggplot2' ) {
		foreach my $style ( 'native', 'matplotlib' ) {
			foreach my $type ( 'bar', 'barh' ) {
				my $script = $script_of->( plot_type => $type, data => \%staff, label => [@order], stacked => 1, engine => $engine, style => $style );
				ok( index( $script, 'staffed' ) < index( $script, 'authorized' ), "$engine, $style, $type: \"staffed\", named first, is drawn first" );
				# kept: sorted, with no "label"
				$script = $script_of->( plot_type => $type, data => \%staff, stacked => 1, engine => $engine, style => $style );
				ok( index( $script, 'authorized' ) < index( $script, 'staffed' ), "$engine, $style, $type: sorted without \"label\"" );
			}
		}
	}
	my $script = $script_of->( plot_type => 'bar', data => \%staff, label => [@order], stacked => 1 );
	like( $script, qr/\[12\], width = 0\.8 +, label = 'staffed', bottom = \[0\]\)/, 'matplotlib: "staffed" stands on 0' );
	like( $script, qr/\[56\], width = 0\.8 +, label = 'authorized', bottom = \[12\]\)/, 'matplotlib: and "authorized" on it' );
	$script = $script_of->( plot_type => 'bar', data => \%staff, label => [@order], stacked => 1, engine => 'ggplot2', style => 'matplotlib' );
	like( $script, qr/ymin = c\(0, 12\), ymax = c\(12, 68\), s = c\("staffed", "authorized"\)/, 'ggplot2, matplotlib style: the same stack' );
	$script = $script_of->( plot_type => 'bar', data => \%staff, label => [@order], stacked => 1, engine => 'ggplot2', style => 'native' );
	like( $script, qr/position = ggplot2::position_stack\(reverse = TRUE\)/, 'ggplot2, native style: the first series at the bottom' );
	$script = $script_of->( plot_type => 'bar', data => \%staff, label => [@order], color => { authorized => 'red', staffed => 'blue' } );
	like( $script, qr/\[12\], width = [\d.]+ +, color = 'blue', label = 'staffed'/, 'a color hash follows the series to their new places' );
	my @given = @order;
	$script_of->( plot_type => 'bar', data => \%staff, label => \@given );
	is_deeply( \@given, \@order, "the caller's \"label\" is left as it was" );
	# kept: with a hash of arrays, "label" is the legend's text, by position
	$script = $script_of->( plot_type => 'bar', data => { A => [ 1, 2 ] }, label => [ 'North', 'South' ] );
	ok( index( $script, 'North' ) < index( $script, 'South' ), 'a hash of arrays: "label" names the series by position, as before' );
	foreach my $engine ( 'matplotlib', 'gnuplot', 'ggplot2' ) {
		my $hoh = sub { figure( plot_type => 'bar', data => \%staff, engine => $engine, @_ ) };
		dies_with( $hoh->( label => [ 'staffed', 'Authorized' ] ),
		 qr/^"label" names "Authorized" in \S+, but no hash in "data" has that key; with a hash of hashes, "label" gives the order of its inner keys: "authorized", "staffed"/,
		 "$engine: a name that is not an inner key is refused" );
		dies_with( $hoh->( label => ['staffed'] ),
		 qr/^"label" leaves out the series "authorized" in \S+; with a hash of hashes it gives the order of every inner key of "data"/,
		 "$engine: a series left out of \"label\" is refused" );
		dies_with( $hoh->( label => [ 'staffed', 'authorized', 'staffed' ] ),
		 qr/^"label" names "staffed" more than once in /, "$engine: a series named twice is refused" );
		dies_with( $hoh->( label => 'staffed' ),
		 qr/^"label" of a hash of hashes in \S+ is an array of the inner keys of "data", in the order to draw the series, not "staffed"/,
		 "$engine: a \"label\" that is not an array is refused" );
	}
}


#
# 2. An SVG was written to output_file, read back and written again -- by the
#    matplotlib engine to cut the DOCTYPE and again for tooltips, by Perl after
#    gnuplot to add the creator note, and by the R script after svg() to add
#    it -- so that a viewer watching the file saw it change two or three
#    times, and empty in between. Eye of GNOME 45.3 stopped reloading it,
#    though it reloads a PNG, which was always written once. Each engine now
#    finishes the SVG elsewhere and writes output_file once.
#
#    Seen by tracing a run (strace -e trace=openat) and by "gio monitor": three
#    opens of the file and two "changes done" from the matplotlib engine before
#    the fix, one and one after, and the SVG the same but for matplotlib's
#    random ids. gnuplot is not run here: a stand-in for run_script reads the
#    script it is handed, as gnuplot would.
#
{
	my $slurp = sub {
		my ($file) = @_;
		open my $fh, '<:raw', $file or die "can't read $file: $!";
		local $/;
		my $text = <$fh>;
		close $fh or die "can't close $file: $!";
		return $text;
	};
	my $script_of = sub {
		my (%spec) = @_;
		my ( undef, undef, $file ) = capture { plt( execute => 0, plot_type => 'bar', data => { A => 1, B => 2 }, %spec ) };
		return $slurp->($file);
	};
	my %tips = ( plot_type => 'scatter', data => { x => [ 1, 2 ], y => [ 2, 1 ] }, tooltips => [ 'a', 'b' ] );
	foreach my $case ( [ '.svg', () ], [ '.svgz', () ], [ '.svg, with tooltips', %tips ], [ '.svgz, with tooltips', %tips ] ) {
		my ( $name, %spec ) = @{$case};
		( my $ext = $name ) =~ s/,.*//;
		my $py = $script_of->( output_file => out_file() . $ext, %spec );
		like( $py, qr/^plt\.savefig\(svg_buffer, format = 'svg', bbox_inches = 'tight', metadata=/m, "matplotlib, $name: drawn into memory" );
		my @opens = $py =~ m/\(output_file, '(\w+)'\)/g;
		is_deeply( \@opens, ['wb'], "matplotlib, $name: and output_file opened once, to write" );
		unlike( $py, qr/svg_buffer.*\n(?:.*\n)*plt\.savefig\(output_file/, "matplotlib, $name: and not saved to it as well" );
	}
	# kept: every other format is saved by savefig itself, as a PNG always was
	my $py = $script_of->( output_file => out_file() . '.png' );
	like( $py, qr/^plt\.savefig\(output_file, bbox_inches = 'tight', metadata=/m, 'matplotlib, .png: saved by savefig' );
	unlike( $py, qr/svg_buffer|svg_bytes/, 'matplotlib, .png: with nothing written after it' );

	my $path = out_file() . '.svg';
	my $r = $script_of->( engine => 'ggplot2', output_file => $path );
	like( $r, qr/^\tsvg_drawn <- tempfile\(fileext = "\.svg"\)\n\tgrDevices::svg\(gsub\("%", "%%", svg_drawn, fixed = TRUE\), /m, 'ggplot2: svg() draws into a temporary file' );
	my $quoted = quotemeta( Matplotlib::Simple::Ggplot2::r_str($path) );
	my @named = $r =~ m/$quoted/g;
	is( scalar @named, 1, 'ggplot2: output_file is named once' );
	like( $r, qr/\twriteBin\([^\n]*, $quoted\)\n\t\tunlink\(svg_drawn\)\n/, 'ggplot2: by the one writeBin of the finished SVG' );

	# gnuplot, through a stand-in for run_script that draws what the script
	# it is given asks for, as gnuplot would.
	# The paths a gnuplot script writes to, as paths: gp_str escapes "\" and
	# '"', and a path on MSWin32 is full of the one.
	my $outputs_of = sub {
		my ($gp) = @_;
		return map { ( my $path = $_ ) =~ s/\\(.)/$1/g; $path } $gp =~ m/^set output "((?:[^"\\\n]|\\.)*)"\r?$/mg;
	};
	my $svg = out_file();
	my $png = out_file() . '.png';
	my ( @ran, $svg_existed );
	my $stand_in = sub {
		my ($command) = @_;
		my $gp = $slurp->( $command->[-1] );
		push @ran, $gp;
		foreach my $unescaped ( $outputs_of->($gp) ) {
			open my $o, '>:raw', $unescaped or die "can't write $unescaped: $!";
			print {$o} qq{<?xml version="1.0"?>\n<svg \n xmlns="http://www.w3.org/2000/svg"\n>\n<title>Gnuplot</title>\n<desc>Produced by GNUPLOT 6.0 patchlevel 0 </desc>\n<g id="drawn"/>\n</svg>\n};
			close $o or die "can't close $unescaped: $!";
		}
		$svg_existed = -e $svg ? 1 : 0;    # once all is drawn: gnuplot never wrote it
		return "Matplotlib::Simple gnuplot 6.0.0\n";
	};
	my $returned;
	{
		no warnings qw(once redefine);
		local *Matplotlib::Simple::Gnuplot::run_script = $stand_in;
		require File::Temp;
		my $fh = File::Temp->new( DIR => $TMP, SUFFIX => '.gp' );
		capture { plt( fh => $fh, execute => 0, engine => 'gnuplot', plot_type => 'bar', data => { A => 1 }, output_file => $svg ) };
		capture { plt( fh => $fh, execute => 0, engine => 'gnuplot', plot_type => 'bar', data => { A => 1 }, output_file => $png ) };
		( undef, undef, $returned ) = capture { plt( fh => $fh, execute => 1, engine => 'gnuplot', plot_type => 'bar', data => { A => 2 }, output_file => $svg ) };
		$returned = $slurp->($returned);
	}
	is( scalar @ran, 1, 'gnuplot: run once' );
	my @outputs = $outputs_of->( $ran[0] );
	is( scalar @outputs, 3, 'gnuplot: three figures' );
	is( scalar( grep { $_ eq $svg } @outputs ), 0, 'gnuplot: the script it runs never names the SVG' );
	is( $outputs[0], $outputs[2], 'gnuplot: the SVG named twice is drawn into one temporary file' );
	like( $outputs[0], qr/\.svg\z/, 'gnuplot: a temporary .svg' );
	is( scalar( grep { $_ eq $png } @outputs ), 1, 'gnuplot: kept: a PNG is drawn where it is to go' );
	is( $svg_existed, 0, 'gnuplot: the SVG did not exist once gnuplot had run' );
	my $written = $slurp->($svg);
	like( $written, qr/<g id="drawn"\/>/, 'gnuplot: then holds what was drawn' );
	is( scalar( () = $written =~ m/<dc:title>/g ), 1, 'gnuplot: with one creator note' );
	ok( !-e $outputs[0], 'gnuplot: and the temporary file is gone' );
	is_deeply( [ $outputs_of->($returned) ], [ $svg, $png, $svg ], 'gnuplot: the script returned still names the SVG, to be run by hand, and not the temporary file' );
}

done_testing();
