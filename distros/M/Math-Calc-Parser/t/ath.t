use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';

my $fh = tempfile();
{
	local *STDOUT = $fh;
	use ath;
	2+2
	no ath;
	use ath;
	round e^(i pi)
	no ath;
	use ath;
	5!
	no ath;
}

seek $fh, 0, 0;
chomp(my @lines = <$fh>);
is $lines[0], 4, 'Evaluated 2+2';
is $lines[1], -1, 'Evaluated round e^(i pi)';
is $lines[2], 120, 'Evaluated 5!';

done_testing;
