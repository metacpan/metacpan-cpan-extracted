# Stuff used by most of the test scripts gets thrown in here.

# Stop Test::Builder 0.17 (included with perl 5.8.6) from trying to mess
# with threads
unshift @INC, sub {
	no warnings 'redefine';
	if ($_[1] =~ /^threads\b/) {
		$_[1] eq 'threads/shared.pm' and
			*Test::Builder::share =
			*Test::Builder::lock = sub {0};
		open my $fh, '<', \1;
		return $fh;
	}
	undef
}	
