use Hook::LexWrap;

sub fibonacci {
	my ($n) = @_;
	return 1 if $n < 3;
	return fibonacci($n-1) + fibonacci($n-2);
}

MEMOIZE: {
	my %cache;
	wrap fibonacci,
		pre  => sub { $_[-1] = $cache{$_[0]} if $cache{$_[0]} },
		post => sub { $cache{$_[0]} = $_[-1] };
}

while (<>) {
	chomp;
	print fibonacci($_), "\n";
}
