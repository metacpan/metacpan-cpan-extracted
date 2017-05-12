use Test::More;
use Test::Warn;
use Hash::Missing;

tie my %h, 'Hash::Missing';

warning_like {
	my $x = $h{x};
} qr{^missing hash key: x};

warning_is {
	$h{x} = 1;
	my $x = $h{x};
} undef;

done_testing;
