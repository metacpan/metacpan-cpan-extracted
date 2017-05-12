use Test::More tests => 6;

use strict;
use warnings;

use Iterator::Simple qw(:all);

my $itr;

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = islice($ary, 2, 8);
	is_deeply list($itr) => [qw(c d e f g h)], 'islice';
}

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = islice($ary, 2, 8, 2);
	is_deeply list($itr) => [qw(c e g)], 'islice with step';
}

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = islice($ary, 1, 8, 2);
	is_deeply list($itr) => [qw(b d f h)], 'islice with step2';
}

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = islice($ary, 4, undef, 2);
	is_deeply list($itr) => [qw(e g i )], 'islice with step without $end';
}

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = ihead(5, $ary);
	is_deeply list($itr) => [qw(a b c d e)], 'ihead';
}

{
	my $ary = [qw(a b c d e f g h i j)];
	$itr = iskip(5, $ary);
	is_deeply list($itr) => [qw(f g h i j)], 'iskip';
}


