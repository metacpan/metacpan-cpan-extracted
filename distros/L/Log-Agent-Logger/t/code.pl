#!./perl
###########################################################################
#
#   code.t
#
#   Copyright (C) 1999-2000 Raphael Manfredi.
#   Copyright (C) 2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

sub ok {
	my ($num, $ok) = @_;
	print "not " unless $ok;
	print "ok $num\n";
}

sub contains {
	my ($file, $pattern) = @_;
	local *FILE;
	local $_;
	open(FILE, $file) || die "can't open $file: $!\n";
	my $found = 0;
	while (<FILE>) {
		$found++ if /$pattern/;
	}
	close FILE;
	return $found;
}

1;
