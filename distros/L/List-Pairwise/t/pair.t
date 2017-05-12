use strict;
use warnings;
use Test::More;

plan tests => 24 unless $::NO_PLAN && $::NO_PLAN;

use List::Pairwise 'pair';

my %a = (
	snoogy1  => 4,
	snoogy2  => 2, 
	NOT      => 4,
	snoogy3  => 5,
	hehe     => 12,
);

# scalar context
is(scalar(pair %a), scalar(keys %a), 'scalar context');

# list context
is_deeply(
	[pair %a], 
	[List::Pairwise::mapp {[$a, $b]} %a],
	'list context',
);

# void context
eval {pair %a};
is($@, '', 'void context');

# empty list, list context
is_deeply(
	[pair ()], 
	[],
	'empty list, list context',
);

# empty list, scalar context
is(scalar(pair ()), 0, 'empty list, scalar context');

# empty list, void context
eval {pair ()};
is($@, '', 'empty list, void context');

{
	no warnings;
	is_deeply(
		[map {@$_} pair (1..3)],
		[1..3, undef],
		'pair odd list',
	);
}

{
	no warnings;
	is(pair (), 0, 'scalar pair empty list');
	is(pair (1), 1, 'scalar pair 1 element');
	is(pair (1..2), 1, 'scalar pair 2 elements');
	is(pair (1..3), 2, 'scalar pair 3 elements');
	is_deeply(
		[pair (1)],
		[[1, undef]],
		'list pair 1 elements',
	);
	is_deeply(
		[pair (1..2)],
		[[1, 2]],
		'list pair 2 elements',
	);
	is_deeply(
		[pair (1..3)],
		[[1, 2], [3, undef]],
		'list pair 3 elements',
	);
}

# odd list
{
	my $file = quotemeta __FILE__;
	
	{
		no warnings;
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {pair (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings;
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {pair (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}

	{
		no warnings 'misc';
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {pair (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings 'misc';
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {pair (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}
}