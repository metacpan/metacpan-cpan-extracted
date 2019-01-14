package Enterprise::Licence::Generate;
use utf8; use warnings; use strict;
use parent 'Enterprise::Licence';
sub generate {
	my $msg = $_[0]->{ch}->encode([split '', $_[0]->{secret}]);
	$msg =~ s/^(0*)//;
	my $n = '_' x length $1;
	my ($dec, $time, $end) = (
		$_[0]->bin2dec($msg) + $_[0]->bin2dec($_[0]->customer_offset($_[1])),
		DateTime->now()->epoch(),
		DateTime->now()->add(%{ $_[2] })->epoch(),
	);
	return sprintf("%s-%s-%s-%s",
		$_[0]->bi($dec) . $n,
		$_[0]->bi($time),
		$_[0]->bi($end),
		$_[0]->bi($end - $time)
	);
}
1;
