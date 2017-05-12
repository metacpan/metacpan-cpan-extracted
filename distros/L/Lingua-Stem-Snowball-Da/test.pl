# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
my $DEBUG = 1;

use Test;
BEGIN { plan tests => 2};
use Lingua::Stem::Snowball::Da;
my $stemmer = new Lingua::Stem::Snowball::Da (use_cache => 0);

ok(1); # If we made it this far, we're ok.
warn("Testing stemmer against database, this will take some time\n");

open(DIFFS, "<diffs.txt") or die "Couldn't open diffs.txt: $!\n";
while(<DIFFS>)
{
	chomp;
	my($orig, $result) = split(/\s+/, $_);
	my $stemmed = $stemmer->stem($orig);
	unless ($stemmed eq $result) {
		ok(0);
		warn("$orig, $stemmed cmp $result\n") if $DEBUG;
	}
}
ok(1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

