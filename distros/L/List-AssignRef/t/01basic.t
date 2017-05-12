use Test::More tests => 5;
use List::AssignRef;
use List::MoreUtils qw( part );

deref(my @input) = [qw(
	Ape
	Bear
	Bunny
	Alligator
	Bison
	Badger
)];

(deref(my @A), deref(my @B)) = part { !!/^B/ } sort @input;

is_deeply(
	\@A,
	[qw( Alligator Ape )],
);

is_deeply(
	\@B,
	[qw( Badger Bear Bison Bunny )],
);

deref(my %H) = +{ foo => 1, bar => 2 };
is_deeply(
	\%H,
	+{ foo => 1, bar => 2 },
);


deref(my $S) = \"Hello World";
is(
	$S,
	"Hello World",
);

ok not eval {
	deref(my %H2) = [];
};
