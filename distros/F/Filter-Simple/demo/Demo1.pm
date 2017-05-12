package Demo1;
$VERSION = '0.01';

use Filter::Simple sub {
	my $class = shift;
	while (my ($from, $to) = splice @_, 0, 2) {
		s/$from/$to/g;
	}
};

1;
