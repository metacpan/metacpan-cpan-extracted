#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 5;
use File::Spec;
use File::Temp;
use Locale::Msgfmt;

SKIP: {
	unless ( eval("use Locale::Maketext::Gettext; 1;") ) {
		skip( "Test needs Locale::Maketext::Gettext", 5 );
	}

	sub my_read_mo {
		return +{ read_mo(shift) };
	}

	sub my_msgfmt {
		my ( $fh, $filename ) = File::Temp::tempfile();
		close $fh;
		my $in = shift;
		utime( undef, undef, $in );
		my $fuzzy = $_[0] ? 1 : 0;
		msgfmt( { in => $in, out => $filename, fuzzy => $fuzzy } );
		return $filename;
	}

	sub do_one_test {
		my $basename = shift;
		my $po       = File::Spec->catfile( "t", "samples", $basename . ".po" );
		my $mo       = File::Spec->catfile( "t", "samples", $basename . ".mo" );
		my $good     = my_read_mo($mo);
		my $filename = my_msgfmt($po);
		my $test     = my_read_mo($filename);
		is_deeply( $test, $good );
		if ( $basename eq "basic" ) {
			unlink($filename);
			$filename = my_msgfmt( $po, 1 );
			$good = my_read_mo( File::Spec->catfile( "t", "samples", "fuzz.mo" ) );
			$test = my_read_mo($filename);
			is_deeply( $test, $good );
		}
		unlink($filename);
	}
	do_one_test("basic");
	do_one_test("ja");
	do_one_test("context");
	do_one_test("ngettext");
}
