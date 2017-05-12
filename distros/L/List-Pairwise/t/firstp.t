use strict;
use warnings;
use Test::More;

plan tests => 27 unless $::NO_PLAN && $::NO_PLAN;

use List::Pairwise 'firstp';

my @b = (
	snoogy1  => 4,
	snoogy2  => 2, 
	NOT      => 4,
	snoogy3  => 5,
	hehe     => 12,
);
my %a = @b;

# count
is(scalar(firstp {$a =~ /snoogy/} %a), 1, 'scalar context true 1');
is(scalar(firstp {$b < 5} %a), 1, 'scalar context true 2');
is(scalar(firstp {$a =~ /snoogy/ && $b < 5} %a), 1, 'scalar context true 3');
{
	no warnings;
	is(scalar(firstp {$b > 5} (1..9)), 1, 'scalar context true odd');
}
is(scalar(firstp {$a =~ /bla/} %a), undef, 'scalar context false');

# count vs list
is (scalar(firstp {$a =~ /snoogy/} %a), 1/2 * scalar(my @a = firstp {$a =~ /snoogy/} %a), 'scalar and list count');

# copy
is_deeply(
	{
		firstp {$a =~ /snoogy/} @b
	}, {
		snoogy1  => 4,
	},
	'extract 1',
);
is_deeply(
	{
		firstp {$b < 5} @b
	}, {
		snoogy1  => 4,
	},
	'extract 2',
);
is_deeply(
	{
		firstp {$a =~ /snoogy/ && $b < 5} @b
	}, {
		snoogy1  => 4,
	},
	'extract 3',
);

is_deeply(
	{
		firstp {$a =~ /bla/} @b
	}, {
	},
	'extract 4',
);


{
	no warnings;

	is_deeply(
		[firstp {$a==3} (1..3)],
		[3, undef],
		'firstp odd list',
	);

	{ # inc odd in list context
		my @list = (1..3);

		my $res = eval { [ firstp {++$a; ++$b; $a==4} @list ] };
		like($@, qr/Modification of a read-only value attempted/, 'list context inc firstp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'list context inc firstp odd list 2/2'
		);
	}

	{ # inc odd in scalar context
		my @list = (1..3);

		my $res = eval { firstp {++$a; ++$b; $a==4} @list };
		like($@, qr/Modification of a read-only value attempted/, 'scalar context inc firstp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'scalar context inc firstp odd list 2/2'
		);
	}

	{ # inc odd in void context
		my @list = (1..3);

		eval { firstp {++$a; ++$b; $a==4} @list };
		like($@, qr/Modification of a read-only value attempted/, 'void context inc firstp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'void context inc firstp odd list 2/2'
		);
	}
}



# odd list
{
	my $file = quotemeta __FILE__;

	{
		no warnings;
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {firstp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings;
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {firstp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}

	{
		no warnings 'misc';
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {firstp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings 'misc';
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {firstp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}
}