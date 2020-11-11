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
my %orig = %$init;
my $href = {
    key4 => { dog => 'cat', bird=> 'fish' }
};
my $merged = $dot->merge($href);	
ok(ref($merged) eq 'Hash::DotPath');
$orig{key4} = { dog => 'cat', bird=> 'fish' };
is_deeply(\%orig, $merged->toHashRef);

	
#
# error conditions
#

done_testing();

#########################################################
