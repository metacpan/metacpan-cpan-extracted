package Corpus;

use 5.010;
use strict;
use warnings;

use File::Spec;

our $VERSION = '0.01';

# THE ORACLE CORPUS, AND THE RULE ABOUT ITS ABSENCE.
#
# t/sgf/ holds real records written by somebody else, which with one
# implementation of everything are among the few things in this suite that are
# not the engine agreeing with itself. t/sgf/README says what a fixture must be
# shipped with and why the TB/TW convention is the line that bites.
#
# The directory ships EMPTY of records, because adding one is a licensing
# decision a person has to make. So the rule is:
#
#   a plain `make test`     SKIPS, with a message naming the README
#   RELEASE_TESTING         FAILS
#
# A release that goes out without its oracles has not been tested, and a skip
# that reports green forever is exactly how that happens without anyone
# noticing. A sibling distribution's t/manifest.t did it for its whole life.

sub dir { return File::Spec->catdir($_[0], 'sgf') }

sub records {
	my ($t_dir) = @_;
	my $dir = dir($t_dir);
	return () unless -d $dir;

	opendir my $dh, $dir or return ();
	my @files = sort grep { /\.sgf\z/ } readdir $dh;
	closedir $dh;

	return map { File::Spec->catfile($dir, $_) } @files;
}

# Every fixture must be accounted for in provenance.txt. A record with no
# provenance is a record nobody can argue with, so it is a failure and not a
# warning.
sub provenance {
	my ($t_dir) = @_;
	my $file = File::Spec->catfile(dir($t_dir), 'provenance.txt');
	return '' unless -f $file;
	open my $fh, '<', $file or return '';
	local $/;
	my $text = <$fh>;
	close $fh;
	return defined $text ? $text : '';
}

# What a test should do when the corpus is empty. Returns a reason to skip, or
# undef when there are records to work with. Dies under RELEASE_TESTING.
sub why_skip {
	my ($t_dir) = @_;
	my @records = records($t_dir);
	return undef if @records;

	my $why = 'the oracle corpus in t/sgf/ is empty: see t/sgf/README for what '
		. 'a fixture must be shipped with';

	die "$why\n\nThis is a FAILURE under RELEASE_TESTING and not a skip, because "
		. "a release without its oracles has not been tested.\n"
		if $ENV{RELEASE_TESTING};

	return $why;
}

1;
