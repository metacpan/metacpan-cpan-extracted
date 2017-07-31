package t::NumForms;

use warnings;
use strict;

use parent "Exporter";
our @EXPORT_OK = qw(num_forms);

sub num_forms($) {
	my($a) = @_;
	my @signs = $a eq "0" ? ("", "+", "-") :
		$a =~ s/\A-// ? ("-") : ("", "+");
	my @prefixes = ("", "0", "00");
	my @suffixes = $a =~ /\./ ? ("", "0", "00") : ("", ".0", ".00");
	return map {
		my $sign = $_;
		map {
			my $prefix = $_;
			map { $sign.$prefix.$a.$_ } @suffixes;
		} @prefixes;
	} @signs;
}

1;
