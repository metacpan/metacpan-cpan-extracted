#!/usr/bin/env perl
#
# The PROGRAMMES section links each programme by its URL in the repository, and
# the same repository is named in Makefile.PL.  Renaming or moving the
# repository - as has happened here once already - leaves those links dead, and
# nothing else would notice: the POD still reads well and the README still
# matches it.  So the links are checked against the metadata, and against the
# files they name.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

use File::Basename qw(dirname);
use File::Spec;

my $ROOT = File::Spec->catdir(dirname(File::Spec->rel2abs($0)), File::Spec->updir());
my $MODULE = File::Spec->catfile($ROOT, 'lib', 'Mail', 'Send', 'DKIM.pm');
my $MAKEFILE = File::Spec->catfile($ROOT, 'Makefile.PL');

plan skip_all => "Cannot find $MODULE" unless(-r $MODULE);
plan skip_all => "Cannot find $MAKEFILE" unless(-r $MAKEFILE);

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The POD links are https URLs, so take the web URL from the repository block
# rather than the git:// clone URL beside it.
my ($repository) = slurp($MAKEFILE) =~ /repository\s*=>\s*\{[^}]*?\bweb\s*=>\s*'([^']+)'/;
ok(defined($repository), 'Makefile.PL names the repository') or BAIL_OUT('no repository URL to compare the links with');
$repository =~ s{/+$}{};

# Each L<text|target> in the POD, keyed by the text that is shown.
my %target = slurp($MODULE) =~ /L<([^|>\n]+)\|([^>\n]+)>/g;

my @linked = grep { $target{$_} =~ m{/blob/} } sort keys %target;
ok(scalar(@linked), 'the POD links into the repository');

foreach my $text (@linked) {
	my $url = $target{$text};

	like($url, qr{\A\Q$repository\E/blob/[^/]+/}, "$text is linked under $repository");

	# The URL only keeps working while the file it names keeps its name.  A URL
	# under some other repository has failed above; there is no path to check.
	next unless($url =~ m{\A\Q$repository\E/blob/[^/]+/(.+)\z});

	ok(-f File::Spec->catfile($ROOT, split(m{/}, $1)), "$text points at a file in the distribution");
}

# A programme added to bin/ but left out of the section would be unlinked, and
# a link to a programme that has been renamed would fail above.
opendir(my $dh, File::Spec->catdir($ROOT, 'bin')) or BAIL_OUT("Cannot read $ROOT/bin");
my @programmes = sort grep { !/^\./ } readdir($dh);
closedir($dh);

foreach my $programme (@programmes) {
	ok(grep({ $target{$_} =~ m{/bin/\Q$programme\E\z} } keys %target), "the POD links bin/$programme");
}

done_testing();
