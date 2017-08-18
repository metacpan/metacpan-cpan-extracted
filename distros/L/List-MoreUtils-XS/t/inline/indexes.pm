
use Test::More;
use Test::LMU;

my @x = indexes { $_ > 5 } (4 .. 9);
is_deeply(\@x, [2 .. 5], "indexes > 5 ...");
@x = indexes { $_ > 5 } (1 .. 4);
is_deeply(\@x, [], 'Got the null list');

my ($lr, @s, @n, @o, @e);
leak_free_ok(
    indexes => sub {
        $lr = 1;
        @s  = indexes { $_ > 5 } (4 .. 9);
        @n  = indexes { $_ > 5 } (1 .. 5);
        @o  = indexes { $_ & 1 } (10 .. 15);
        @e  = indexes { !($_ & 1) } (10 .. 15);
    }
);
$lr and is_deeply(\@s, [2 .. 5], "indexes/leak: some");
$lr and is_deeply(\@n, [],       "indexes/leak: none");
$lr and is_deeply(\@o, [1, 3, 5], "indexes/leak: odd");
$lr and is_deeply(\@e, [0, 2, 4], "indexes/leak: even");

@n = map { $_ + 1 } @o = (0 .. 9);
@x = indexes { ++$_ > 7 } @o;
is_deeply(\@o, \@n, "indexes behaves like grep on modified \$_");
is_deeply(\@x, [7 .. 9], "indexes/modify");

not_dying(
    'indexes_on_set' => sub {
        @x = indexes { ++$_ > 7 } (0 .. 9);
    }
);
is_deeply(\@x, [7 .. 9], "indexes/modify set");

leak_free_ok(
    indexes => sub {
        @s = indexes { grow_stack; $_ > 5 } (4 .. 9);
        @n = indexes { grow_stack; $_ > 5 } (1 .. 4);
        @o = indexes { grow_stack; $_ & 1 } (10 .. 15);
        @e = indexes { grow_stack; !($_ & 1) } (10 .. 15);
    },
    'indexes interrupted by exception' => sub {
        eval {
            @s = indexes { $_ > 10 and die "range exceeded"; $_ > 5 } (1 .. 15);
        };
    },
);

$lr and is_deeply(\@s, [2 .. 5], "indexes/leak: some");
$lr and is_deeply(\@n, [],       "indexes/leak: none");
$lr and is_deeply(\@o, [1, 3, 5], "indexes/leak: odd");
$lr and is_deeply(\@e, [0, 2, 4], "indexes/leak: even");

my $have_scalar_util = eval { require Scalar::Util; 1 };

if ($have_scalar_util)
{
    my $ref = \(indexes(sub { 1 }, 123));
    Scalar::Util::weaken($ref);
    is($ref, undef, "weakened away");
}
is_dying('indexes without sub' => sub { &indexes(42, 4711); });

done_testing;
