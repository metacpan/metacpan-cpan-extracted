use Test::More   tests => 2;

eval {
	my $foo = 0;
	my $bar = 1 / $foo; #!assert($foo != 0)!
};

like($@, qr/$foo/);
ok(!$bar);
