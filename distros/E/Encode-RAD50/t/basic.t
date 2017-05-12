package main;

use strict;
use warnings;

use Encode;
use Test::More 0.88;

{
    my $written = '';
    open my $fh, '>', \$written
	or plan skip_all => 'PerlIO unsupported';
    close $fh;
}

require_ok 'Encode::RAD50'
    or BAIL_OUT "Can not continue without loading Encode::RAD50: $@";

{
    my $written = '';
    open my $fh, '>:encoding(RAD50)', \$written;
    ok binmode( $fh, ':encoding(RAD50)' ),
	    q{open '>:encoding(RAD50)'}
	or BAIL_OUT "Can not continue without binmode: $!";
    close $fh;
}

Encode::RAD50->silence_warnings( 1 );

my @tests = (
    '   ' => 0,
    FOO => 10215,
    BAR => 3258,
    'A B' => 1602,
    '  A' => 1,
    ' AB' => 42,
    'A#C' => 2763,	# Invalid, encodes as 'A?C'.
    'AXM' => 2573,	# <cr><lf>
    '  J' => 10,	# <lf>
);

while ( @tests ) {
    my ( $string, $value ) = splice @tests, 0, 2;
    ( my $output = $string ) =~ tr/A-Z0-9.$ /?/c;	# Unknown char
    my $tplt = 'n';		# 16 bits, big-endian. Assumes 3 chars only.

    cmp_ok unpack( $tplt, encode( 'RAD50', $string ) ), '==', $value,
	"'$string' should encode to $value.";

    is decode( 'RAD50', pack $tplt, $value ), $output,
	"$value should decode to '$output'.";

    my $written = '';
    if ( open my $fh, '>:encoding(RAD50)', \$written ) {
	print { $fh } $string;
	close $fh;
	cmp_ok unpack( $tplt, $written ), '==', $value,
	"Print '$string' to file, and see if we got $value";
    } else {
	fail "Unable to open temp file for output: $!";
    }

    if ( open my $fh, '<:encoding(RAD50)', \$written ) {
	my $buffer = '0';
	read $fh, $buffer, length $string;
	close $fh;
	is $buffer, $output,
	    "Read $value from file and see if we got '$output'";
    } else {
	fail "Unable to open temp file for input: $!";
    }
}

done_testing;

1;

# ex: set textwidth=72 :
