package Enterprise::Licence::Validate;
use utf8; use warnings; use strict;
use parent 'Enterprise::Licence';
sub valid {
	my ($rs, $ns, $es, $ds) = split '-', $_[1];
	$rs =~ s/(_*)$//;
	my $lc = $_[0]->in($rs) - $_[0]->bin2dec($_[0]->customer_offset($_[2]));
	if ($lc) {
		my $bin = $_[0]->dec2bin($lc);
		$bin = (0 x length $1) . $bin;
		my $recovered = $_[0]->{ch}->decode($bin);
		if ($recovered) {
			my $sec = join("", @$recovered);
			if ($_[0]->{secret} eq $sec) {
				my ($ltime, $etime, $dtime) = ($_[0]->in($ns), $_[0]->in($es), $_[0]->in($ds));
				if (($etime - $ltime) == $dtime) {
					if ( $etime > time) {
						return 1;
					}
					return (0, 1);
				}
			}
		}
	}
	return (0, 0);
}
1;
