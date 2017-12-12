use Test::More tests => 7;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

{
	$_ = 'DUMMY';
	
	list(igrep { $_ % 5 } [1..20]);
	
	is($_, 'DUMMY', 'preserve $_ value after igrep');

	list(imap { $_ + 2 } [1..20]);

	is($_, 'DUMMY', 'preserve $_ value after imap');

	$itr = ifilter [1 .. 20], sub {
		if($_ % 5 == 0) {
			return iter([1 .. $_]); #inflate
		}
		elsif($_ % 3 == 0) {
			return; #skip
		}
		else {
			return $_;
		}
	};

	list($itr);

	is($_, 'DUMMY', 'preserve $_ value after ifilter');

	list(izip(['dogs', 'cats', 'pigs'], ['bowow','mew','oink']));

	is($_, 'DUMMY', 'preserve $_ value after izip');

	list(ichain ['blah', 'bla', 'bl'], ['foo', 'bar', 'baz']);

	is($_, 'DUMMY', 'preserve $_ value after ichain');

	list(ienumerate(['foo','bar','baz']));

	is($_, 'DUMMY', 'preserve $_ value after ienumerate');

	list(islice([1..100], 3, 20, 2));

	is($_, 'DUMMY', 'preserve $_ value after islice');
}

