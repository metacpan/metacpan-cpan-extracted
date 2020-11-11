use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Hash::DotPath;

########################################################

my $init = {
	key1 => 1,
	key2 => 2,
	key3 => {
		foo  => 'bar',
		biz  => 'baz',
		list1 => [ 
		  'alpha',
		  { 10 => 100 },
		  { 20 => 200}
		  ],
	},
};

my $dot = Hash::DotPath->new($init);
is_deeply($init, $dot->toHashRef);

#
# happy path
#
my $val = $dot->get('key1');
ok($val == 1);

$val = $dot->get('key3.foo');
ok($val eq 'bar');

$val = $dot->get('key3.list1');
ok(ref($val) eq 'ARRAY');

$val = $dot->get('key3.list1.0');
ok($val eq 'alpha');

$val = $dot->get('key3.list1.1');
ok(ref($val) eq 'HASH');

$val = $dot->get('key3.list1.1.10');
ok($val == 100);

#
# error conditions
#
$val = $dot->get('key99');
ok(!defined $val);

$val = $dot->get('key3.list1.junk');
ok(!defined $val);


done_testing();

#########################################################
