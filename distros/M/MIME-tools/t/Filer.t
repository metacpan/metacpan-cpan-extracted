#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 17;

use Config;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
binmode( Test::More->builder()->output(), ':encoding(utf-8)' );

# Perl < 5.10.0 did not handle Unicode at all...
my $wookie;

if ($Config{'PERL_REVISION'} == 5 &&
    $Config{'PERL_VERSION'} <= 8) {
	$wookie = 'wookie%D0.doc';
} else {
	$wookie = 'wookie%42D.doc';
}

BEGIN {
	use_ok('MIME::Parser::Filer');
}

# Tests for CPAN ticket 6789, and others
{
	my $filer = MIME::Parser::Filer->new();

	# All of these filenames should be considered evil
	my %evil = (
		' '               => '.dat' ,
		' leading_space'  => 'leading_space.dat',
		'trailing_space ' => 'trailing_space.dat',
		'.'               => '..dat',
		'..'              => '...dat',
		'index[1].html'   => 'index_1_.html',
		" wookie\x{f8}.doc" => "wookie%F8.doc",
		" wookie\x{042d}.doc" => $wookie,
	);

	foreach my $name (keys %evil) {
		ok( $filer->evil_filename( $name ), "$name is evil");
	}

	while( my ($evil, $clean) = each %evil ) {
		is( $filer->exorcise_filename( $evil), $clean, "$evil was exorcised");
	}

}
