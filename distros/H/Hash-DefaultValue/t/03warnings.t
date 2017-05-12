use Test::More tests => 4;
use Test::Warn;
use Hash::DefaultValue;

tie my %hash, 'Hash::DefaultValue', 1;
my $key = undef;

warning_is {
	no warnings;
	is $hash{$key}, 1;
} undef;

warning_like {
	use warnings;
	is $hash{$key}, 1;
} qr{Use of uninitialized value( \$key)? in hash element};
