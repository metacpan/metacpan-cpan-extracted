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
	},
};

my $dot = Hash::DotPath->new($init);
is_deeply( $init, $dot->toHashRef );

#
# happy path
#
my $path = 'key4';
my $val  = $dot->set( $path, 4 );
ok( $val == 4 );
$val = $dot->get($path);
ok( $val == 4 );

$path = 'key5.dog';
$val  = $dot->set( $path, 'cat' );
ok( $val eq 'cat' );
$val = $dot->get($path);
ok( $val eq 'cat' );

$path = 'key6.bird.0.eagle';
$val  = $dot->set( $path, 'fish' );
ok( $val eq 'fish' );
$val = $dot->get($path);
ok( $val eq 'fish' );
$val = $dot->get('key6.bird');
ok( $List->isArray($val) );

$path = 'key7.bird';
$val  = $dot->set( $path, [] );
ok( $List->isArray($val) );
$val = $dot->get($path);
ok( $List->isArray($val) );
$path .= '.0.hawk';
$val = $dot->set( $path, 1 );
$val = $dot->get($path);
ok( $val == 1 );

#
# error conditions
#
$path = 'key8.bird';
$val  = $dot->set( $path, [] );
ok( $List->isArray($val) );
$val = $dot->get($path);
ok( $List->isArray($val) );
$path .= '.eagle';
eval { $val = $dot->set( $path, 1 ); };
ok($@);

done_testing();

#########################################################
