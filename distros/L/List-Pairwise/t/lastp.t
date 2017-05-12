use strict;
use warnings;
use Test::More;

plan tests => 27 unless $::NO_PLAN && $::NO_PLAN;

use List::Pairwise 'lastp';

my @b = (
	snoogy1  => 4,
	snoogy2  => 2, 
	NOT      => 4,
	snoogy3  => 5,
	hehe     => 12,
);
my %a = @b;

# count
is(scalar(lastp {$a =~ /snoogy/} %a), 1, 'scalar context true 1');
is(scalar(lastp {$b < 5} %a), 1, 'scalar context true 2');
is(scalar(lastp {$a =~ /snoogy/ && $b < 5} %a), 1, 'scalar context true 3');
{
	no warnings;
	is(scalar(lastp {$b > 5} (1..9)), 1, 'scalar context true odd');
}
is(scalar(lastp {$a =~ /bla/} %a), undef, 'scalar context false');

# count vs list
is (scalar(lastp {$a =~ /snoogy/} %a), 1/2 * scalar(my @a = lastp {$a =~ /snoogy/} %a), 'scalar and list count');

# copy
is_deeply(
	{
		lastp {$a =~ /snoogy/} @b
	}, {
		snoogy3  => 5,
	},
	'extract 1',
);
is_deeply(
	{
		lastp {$b < 5} @b
	}, {
		NOT  => 4,
	},
	'extract 2',
);
is_deeply(
	{
		lastp {$a =~ /snoogy/ && $b < 5} @b
	}, {
		snoogy2  => 2,
	},
	'extract 3',
);

is_deeply(
	{
		lastp {$a =~ /bla/} @b
	}, {
	},
	'extract 4',
);


{
	no warnings;

	is_deeply(
		[lastp {$a==3} (1..3)],
		[3, undef],
		'lastp odd list',
	);

	{ # inc odd in list context
		my @list = (1..3);

		my $res = eval { [ lastp {++$a; ++$b; $a==4} @list ] };
		like($@, qr/Modification of a read-only value attempted/, 'list context inc lastp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'list context inc lastp odd list 2/2'
		);
	}

	{ # inc odd in scalar context
		my @list = (1..3);

		my $res = eval { lastp {++$a; ++$b; $a==4} @list };
		like($@, qr/Modification of a read-only value attempted/, 'scalar context inc lastp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'scalar context inc lastp odd list 2/2'
		);
	}

	{ # inc odd in void context
		my @list = (1..3);

		eval { lastp {++$a; ++$b; $a==4} @list };
		like($@, qr/Modification of a read-only value attempted/, 'void context inc lastp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'void context inc lastp odd list 2/2'
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
		eval {lastp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings;
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {lastp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}

	{
		no warnings 'misc';
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {lastp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings 'misc';
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {lastp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}
}