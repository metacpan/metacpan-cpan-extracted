use strict;
use warnings;
use Test::More;

plan tests => 36 unless $::NO_PLAN && $::NO_PLAN;

use List::Pairwise 'mapp';
my %a = (
	snoogy1  => 40,
	snoogy2  => 20, 
	NOT      => 40,
	snoogy3  => 50,
	hehe     => 12,
);

# use Time::HiRes qw(time);
# my $t = time;
# my @a = (1..1000);
# no warnings;
# for (1..1000) {
# 	(mapp {$a} @a)
# }
# die time -$t;
# exit;

# count
is(scalar(mapp {$a} %a), scalar(keys %a), 'scalar context count 1');
is(scalar(mapp {$a => $b} %a), 2*scalar(keys %a), 'scalar context count 2');
is(scalar(mapp {$a, $b, 4} %a), 3*scalar(keys %a), 'scalar context count 3');

{
	no warnings;
	is(scalar(mapp {$a, $b, 4} (1..9)), 3*5, 'scalar context count odd');
}

my $count=0;
is(scalar(mapp {$count+=$b} %a), scalar(keys %a), 'scalar context increment 1/2');
is($count, 40+20+40+50+12, 'scalar context increment 2/2');

# copy
is_deeply(
	{
		mapp {$a => $b} %a
	}, {
		%a
	},
	'copy',
);
is_deeply(
	[
		mapp {$a} %a
	], [
		keys %a
	],
	'keys',
);
is_deeply(
	[
		mapp {$b} %a
	], [
		values %a
	],
	'values',
);
is_deeply(
	{
		mapp {lc($a) => $b} %a
	}, {
		snoogy1  => 40,
		snoogy2  => 20, 
		not      => 40,
		snoogy3  => 50,
		hehe     => 12,
	},
	'copy with lc keys',
);

# inplace
my %b;
%b = %a;
mapp {$b++} %b; # void context
is_deeply(
	{
		%b
	}, {
		snoogy1  => 41,
		snoogy2  => 21, 
		NOT      => 41,
		snoogy3  => 51,
		hehe     => 13,
	},
	'inc values inplace',
);

%b = %a;
mapp {$a = lc($a)} %b; # wrong => no modification
is_deeply(
	{
		%b
	}, {
		%a
	},
	'lc keys inplace shall not work',
);

{
	no warnings;
	is((scalar mapp {[$a, $b]} ()), 0, 'scalar mapp empty list');
	is((scalar mapp {[$a, $b]} (1)), 1, 'scalar mapp 1 element');
	is((scalar mapp {[$a, $b]} (1..2)), 1, 'scalar mapp 2 element2');
	is((scalar mapp {[$a, $b]} (1..3)), 2, 'scalar mapp 3 element2');
	is_deeply(
		[mapp {[$a, $b]} (1)],
		[[1, undef]],
		'list mapp 1 elements',
	);
	is_deeply(
		[mapp {[$a, $b]} (1..2)],
		[[1, 2]],
		'list mapp 2 elements',
	);
	is_deeply(
		[mapp {[$a, $b]} (1..3)],
		[[1, 2], [3, undef]],
		'list mapp 3 elements',
	);
}

{
	no warnings;

	is_deeply(
		[mapp {$a, $b} (1..3)],
		[1..3, undef],
		'mapp odd list',
	);

	{ # inc odd in list context
		my @list = (1..3);

		my $res = eval { [ mapp {++$a, ++$b} @list ] };
		like($@, qr/Modification of a read-only value attempted/, 'list context inc mapp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'list context inc mapp odd list 2/2'
		);
	}

	{ # inc odd in scalar context
		my @list = (1..3);

		my $res = eval { mapp {++$a, ++$b} @list };
		like($@, qr/Modification of a read-only value attempted/, 'scalar context inc mapp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'scalar context inc mapp odd list 2/2'
		);
	}

	{ # inc odd in void context
		my @list = (1..3);

		eval { mapp {++$a, ++$b} @list };
		like($@, qr/Modification of a read-only value attempted/, 'void context inc mapp odd list 1/2');
		
		is_deeply(
			\@list,
			[2..4],
			'void context inc mapp odd list 2/2'
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
		eval {mapp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings;
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {mapp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}

	{
		no warnings 'misc';
		my $ok = 1;
		local $SIG{__WARN__} = sub{$ok=0};
		eval {mapp {$a, $b} (1..5)};
		is($@, '', 'odd list, no warning');
		ok($ok, 'no warning occured');
	}
	
	{
		use warnings 'misc';
		my $ok = 0;
		my $warn;
		local $SIG{__WARN__} = sub{$ok=1; $warn=shift};
		eval {mapp {$a, $b} (1..5)};
		my $line = __LINE__ - 1;
		is($@, '', 'odd list');
		ok($ok, 'warning occured');
		like($warn, qr/^Odd number of elements\b/, 'odd list carp');
	}
	
}