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
ok($dot->exists('key1'));
ok($dot->exists('key3.foo'));
ok($dot->exists('key3.list1'));
ok($dot->exists('key3.list1.0'));
ok($dot->exists('key3.list1.1'));
ok($dot->exists('key3.list1.1.10'));

#
# error conditions
#
ok(!$dot->exists('key99'));
ok(!$dot->exists('key3.list1.junk'));

done_testing();

#########################################################
