use strict;
use Test::More tests => 15;
use Test::Exception;
use Hash::DefaultValue;

tie my %hash, 'Hash::DefaultValue', sub { no warnings; $_ + 10 };

ok tied %hash, 'is tied';

ok !keys %hash, 'is empty';

$hash{foo} = 5;

is_deeply [sort keys %hash], [qw(foo)], 'can store';

is $hash{foo}, 5, 'stores correct value';

is $hash{bar}, 10, 'can fetch something using default value';

is $hash{50}, 60;

$hash{50}++;

is $hash{50}, 61;

is_deeply [sort keys %hash], [qw(50 foo)], 'autovivification';

is delete $hash{50}, 61;

is delete $hash{60}, undef;

is_deeply [sort keys %hash], [qw(foo)];

tie my %hash2, 'Hash::DefaultValue', sub { is $_->[0][0] => 'ok'; 4 };

my $key = [['ok']];
is $hash2{$key}, 4, 'keys can be non-scalars';

tie my %hash3, 'Hash::DefaultValue', 6;
is $hash3{x}, 6, 'constant values work';

throws_ok {
	$hash3{y}{z} = 4;
} qr{Can't use .+ as a HASH ref};
