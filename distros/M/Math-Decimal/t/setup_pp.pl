require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Math::Decimal"
		if ($_[0] || "") eq "Math::Decimal";
	goto &$orig_load;
};

1;
