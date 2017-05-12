package Log::Saftpresse::Constants;

use strict;
use warnings;

# ABSTRACT: class to hold the constants used in pflogsumm
our $VERSION = '1.6'; # VERSION

our (@ISA, @EXPORT);

our ($divByOneKAt, $divByOneMegAt, $oneK, $oneMeg);
our (@monthNames, %monthNums, $thisMon, $thisYr);

BEGIN {
	require Exporter;

	# Some constants used by display routines.  I arbitrarily chose to
	# display in kilobytes and megabytes at the 512k and 512m boundaries,
	# respectively.  Season to taste.
	$divByOneKAt   = 524288;	# 512k
	$divByOneMegAt = 536870912;	# 512m
	$oneK          = 1024;		# 1k
	$oneMeg        = 1048576;	# 1m

	# Constants used throughout pflogsumm
	@monthNames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	%monthNums = qw(
	    Jan  0 Feb  1 Mar  2 Apr  3 May  4 Jun  5
	    Jul  6 Aug  7 Sep  8 Oct  9 Nov 10 Dec 11);
	($thisMon, $thisYr) = (localtime(time()))[4,5];
	$thisYr += 1900;

	@ISA = qw(Exporter);
	@EXPORT = qw(
		$divByOneKAt $divByOneMegAt $oneK $oneMeg
		@monthNames %monthNums $thisMon $thisYr
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Constants - class to hold the constants used in pflogsumm

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
