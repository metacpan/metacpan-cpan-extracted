use strict;
use warnings;

use Test::More;
use Test::Deep;

use Devel::Gladiator;
use Scalar::Util qw(weaken);

use Memory::Leak::Hunter;


plan tests => 8;

my $c0 = Devel::Gladiator::arena_ref_counts;
good() for 1..100;
my $c1 = Devel::Gladiator::arena_ref_counts;

leak() for 1..100;
my $c2 = Devel::Gladiator::arena_ref_counts;

good() for 1..100;
my $c3 = Devel::Gladiator::arena_ref_counts;

#diag explain $c0;
sub range {
	my ($x, $y) = @_;

	return code(sub {
		my $val = shift;
		if ($x <= $val and $val <= $y) {
			return 1;
		} else {
			return (0, "Expected $x <= VALUE <= $y\nReceived $val");
		}
	});
}

cmp_deeply Memory::Leak::Hunter::_diff($c0, $c1), {
  'HASH'     => 1,
  'REF'      => 1,
  'REF-HASH' => 1,
  'SCALAR'   => range(19, 26),
}, '100 times weaken';

cmp_deeply Memory::Leak::Hunter::_diff($c1, $c2), {
  'HASH'     => 201,
  'REF'      => 201,
  'REF-HASH' => 201,
  'SCALAR'   => range(219, 226),
}, '100 times with memory leak';

cmp_deeply Memory::Leak::Hunter::_diff($c2, $c3), {
  'HASH'     => 1,
  'REF'      => 1,
  'REF-HASH' => 1,
  'SCALAR'   => range(19, 26),
}, '100 times weaken';

my $mlh = Memory::Leak::Hunter->new;
$mlh->record('start');
$mlh->record('second');
cmp_deeply $mlh->last_diff, {
	'REF-HASH' => 2, 
	SCALAR     => range(24, 31),
	HASH       => 2, 
	REF        => 2,
}, 'self';
$mlh->record('third');
cmp_deeply $mlh->last_diff, {
	SCALAR     => range(29, 36),
	REF        => 3,
    'REF-HASH' => 3,
    HASH       => 3,
}, 'self + is_deeply';

good();
cmp_deeply $mlh->last_diff, {
	'REF-HASH' => 3,
	HASH       => 3,
	REF        => 3,
	SCALAR     => range(29,36),
}, 'good';

leak();
cmp_deeply $mlh->last_diff, {
	HASH       => 3,
	REF        => 3,
	SCALAR     => range(29, 36),
	'REF-HASH' => 3},
, 'leak';


my $records = $mlh->records;
isa_ok $records, 'ARRAY';

#diag explain $records;
my $report = $mlh->report;
#diag $report;


sub leak {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
}

sub good {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
	weaken $y->{partner};
}

