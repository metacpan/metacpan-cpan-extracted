use strict;
# Adjust the number here!
use Test::More tests => 28;

use_ok('Encode');
use_ok('Encode::EUCJPASCII');
test('eucjp');
test('7bit');
# Add more test here!

sub test {
    my $in = shift;
    local($/) = '';
    open WORDS, "testin/$in.txt" or die "open: $!";
    while (<WORDS>) {
	next if /^#/;
	my @w = split /\n/, $_;
	my ($renc, $rdec) = split /,/, shift @w;
	my $cset = shift @w;
	my $byte = eval(shift @w);
	die $@ if $@ or !$byte;
	my $uni = eval(join "\n", @w);
	die $@ if $@ or !$uni;
	my $enc = encode($cset, $uni);
	my $dec = decode($cset, $byte);

	$enc = sprintf "\\x%*v02X", "\\x", $enc;
	$byte = sprintf "\\x%*v02X", "\\x", $byte;
	$dec = sprintf "\\x{%*v04X}", "}\\x{", $dec;
	$uni = sprintf "\\x{%*v04X}", "}\\x{", $uni;

	if ($renc eq 'GOOD') {
	    is($enc, $byte);
	} elsif ($renc eq 'BAD') {
	    isnt($enc, $byte);
	}
	if ($rdec eq 'GOOD') {
	    is($dec, $uni);
	} elsif ($rdec eq 'BAD') {
	    isnt($dec, $uni);
	}
    }
}
