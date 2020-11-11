use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Hash::DotPath;
use Util::Medley::List;
use Util::Medley::Hash;

use vars qw($List $Hash);

########################################################

$Hash = Util::Medley::Hash->new;
$List = Util::Medley::List->new;

my $init = {
	key1 => 1,
	key2 => 2,
	key3 => {
		foo   => 'bar',
		biz   => 'baz',
		list1 => [ 'alpha', { 10 => 100 }, { 20 => 200 } ],
		list2 => ['a', 'b', 'c']
	},
};

my $dot = Hash::DotPath->new($init);
is_deeply( $init, $dot->toHashRef );

#
# happy path
#
my $path = 'key2';
my $val  = $dot->delete($path);
ok($val == 2);
$val = $dot->get($path);
ok(!defined $val);

$path = 'key3.foo';
$val  = $dot->delete($path);
$val = $dot->get($path);
ok(!defined $val);

$path = 'key3.list2.1';
$val = $dot->delete($path);
ok($val eq 'b');
$val = $dot->get($path);
ok($val eq 'c');

#
# error conditions
#
$path = 'key3.list1.invalid';
eval {
    $val = $dot->delete($path);
};
ok($@);

done_testing();

#########################################################
