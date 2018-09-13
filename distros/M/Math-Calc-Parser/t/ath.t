use strict;
use warnings;
use utf8;
use Test::More;
use Encode 'encode';
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
	use ath;
	int 2π
	no ath;
}

seek $fh, 0, 0;
chomp(my @lines = <$fh>);
is $lines[0], 4, 'Evaluated 2+2';
is $lines[1], -1, 'Evaluated round e^(i pi)';
is $lines[2], 120, 'Evaluated 5!';
is $lines[3], 6, encode 'UTF-8', 'Evaluated int 2π';

done_testing;
