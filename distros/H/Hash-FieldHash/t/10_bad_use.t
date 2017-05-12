#!perl -w

use strict;
use Test::More tests => 8;

#use Hash::Util::FieldHash::Compat qw(fieldhash fieldhashes);
use Hash::FieldHash qw(:all);

fieldhash my %hash;

eval{
	$hash{foo}++;
};
ok $@;

eval{
	$hash{1}++;
};
ok $@;

eval{
	my $o = {};
	$hash{"$o"}++;
};
ok $@;

eval{
	exists $hash{foo};
};

ok $@;

eval{
	my $x = $hash{foo};
};
ok $@;

eval{
	delete $hash{foo};
};
ok $@;

eval{
	fieldhashes [];
};
ok $@;

my $o = {foo => 'bar'};
{
	fieldhash my %hash;
	$hash{$o} = 42;
}

is_deeply $o, {foo => 'bar'};
