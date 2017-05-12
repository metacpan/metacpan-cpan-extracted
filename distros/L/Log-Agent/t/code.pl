#!perl
###########################################################################
#
#   code.pl
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
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
	my $line = 0;
	while (<FILE>) {
                s/[\n\r]//sg;
		$line++;
		if (/$pattern/) {
			$found = 1;
			last;
		}
	}
	close FILE;
	return $found ? $line : 0;
}

1;
