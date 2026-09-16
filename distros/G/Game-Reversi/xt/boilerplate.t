#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# No Module::Starter placeholder text survives anywhere in the distribution.
#
# THE TODO BLOCK IS GONE, AND THAT IS THE POINT OF THIS REWRITE. The stock
# version of this file wraps every check in
#
#     TODO: { local $TODO = "Need to replace the boilerplate text"; ... }
#
# which means a file still full of placeholders reports as an expected failure
# and a clean suite looks exactly the same either way. Once the boilerplate IS
# replaced the checks report "TODO passed", which is noise rather than a
# result. Either way the test is declawed: it can never fail.
#
# That is the same family of fault as the stock t/manifest.t, which skipped
# itself into a permanent PASS. A check that cannot fail is not a check.

unless ($ENV{RELEASE_TESTING}) {
	plan skip_all => 'author test: set RELEASE_TESTING to check for boilerplate';
}

# The phrases Module::Starter leaves behind, and one of our own: a stub POD that
# says nothing is worse than none, because it looks finished.
my @BOILERPLATE = (
	qr/\bboilerplate description\b/i,
	qr/\bstub file for (?:a|the) module\b/i,
	qr/\bQuick summary of what the module does\b/i,
	qr/A little code example\b/i,
	qr/\bBlah blah blah\b/i,
	qr/\bplacetext\b/i,
	qr/\bTODO:? *(?:write|fill|replace)\b/i,
	qr/\bFIXME\b/,
	qr/\bXXX\b/,
	qr/\byour name here\b/i,
	qr/\bEXAMPLE\.COM\b/i,
	qr/\bfoo\@bar\b/i,
);

my @files = ('README', 'Changes', 'Makefile.PL', 'bin/reversi');
File::Find::find({
	no_chdir => 1,
	wanted => sub { push @files, $File::Find::name if /\.pm\z/ },
}, 'lib');

plan tests => scalar @files;

for my $path (sort @files) {
	subtest $path => sub {
		open my $fh, '<', $path or do {
			fail("cannot read $path: $!");
			done_testing();
			return;
		};

		my @found;
		my $line = 0;
		while (my $text = <$fh>) {
			$line++;
			for my $pattern (@BOILERPLATE) {
				push @found, "$path:$line: $text" if $text =~ $pattern;
			}
		}
		close $fh;

		is_deeply(\@found, [], "$path has no placeholder text left in it")
			or diag(join '', @found);
		done_testing();
	};
}
