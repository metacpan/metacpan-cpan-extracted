use Test::More tests=>7;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

#1
ok($itr = iarray ['foo','bar','bazz','fizz'] );


#2-3
{
	$itr = iarray ['foo','bar','bazz','fizz'];
	ok(($itr = imap { $_ . '_' } $itr ), 'imap creation');
	is_deeply(list($itr), [qw(foo_ bar_ bazz_ fizz_)], 'imap result');
}

#4-5
{
	$itr = iarray ['foo','bar','bazz','fizz'];
	ok(($itr = igrep { /^b/ } $itr ), 'igrep creation');
	is_deeply(list($itr), [qw(bar bazz)], 'igrep result');
}

#6-7
{
	$itr = iarray ['foo','bar','bazz','fizz'];
	ok(($itr = igrep { /^_b/ } imap { '_' . $_ } $itr ), 'chain creation');
	is_deeply(list($itr), [qw(_bar _bazz)], 'chain result');
}
