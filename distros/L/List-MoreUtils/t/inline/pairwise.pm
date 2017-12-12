
use Test::More;
use Test::LMU;

my @a = (1, 2, 3, 4, 5);
my @b = (2, 4, 6, 8, 10);
my @c = pairwise { $a + $b } @a, @b;
is_deeply(\@c, [3, 6, 9, 12, 15], "pw1");

@c = pairwise { $a * $b } @a, @b;    # returns (2, 8, 18)
is_deeply(\@c, [2, 8, 18, 32, 50], "pw2");

# Did we modify the input arrays?
is_deeply(\@a, [1, 2, 3, 4, 5],  "pw3");
is_deeply(\@b, [2, 4, 6, 8, 10], "pw4");

# $a and $b should be aliases: test
@b = @a = (1, 2, 3);
@c = pairwise { $a++; $b *= 2 } @a, @b;
is_deeply(\@a, [2, 3, 4], "pw5");
is_deeply(\@b, [2, 4, 6], "pw6");
is_deeply(\@c, [2, 4, 6], "pw7");

# sub returns more than two items
@a = (1, 1, 2, 3, 5);
@b = (2, 3, 5, 7, 11, 13);
@c = pairwise { ($a) x $b } @a, @b;
is_deeply(\@c, [(1) x 2, (1) x 3, (2) x 5, (3) x 7, (5) x 11, (undef) x 13], "pw8");
is_deeply(\@a, [1, 1, 2, 3, 5], "pw9");
is_deeply(\@b, [2, 3, 5, 7, 11, 13], "pwX");

(@a, @b) = ();
push @a, int rand(1000) for 0 .. rand(1000);
push @b, int rand(1000) for 0 .. rand(1000);
SCOPE:
{
    local $SIG{__WARN__} = sub { };    # XXX
    my @res1 = pairwise { $a + $b } @a, @b;
    # Test this one more thoroughly: the XS code looks flakey
    # correctness of pairwise_perl proved by human auditing. :-)
    my $limit = $#a > $#b ? $#a : $#b;
    my @res2 = map { $a[$_] + $b[$_] } 0 .. $limit;
    is_deeply(\@res1, \@res2);
}

@a = qw/a b c/;
@b = qw/1 2 3/;
@c = pairwise { ($a, $b) } @a, @b;
is_deeply(\@c, [qw/a 1 b 2 c 3/], "pw map");

SKIP:
{
    $ENV{PERL5OPT} and skip 'A defined PERL5OPT may inject extra deps crashing this test', 1;
    # Test that a die inside the code-reference will not be trapped
    eval {
        pairwise { die "I died\n" } @a, @b;
    };
    is($@, "I died\n");
}

leak_free_ok(
    pairwise => sub {
        @a = (1);
        @b = (2);
        @c = pairwise { $a + $b } @a, @b;
    }
);

leak_free_ok(
    'exceptional block' => sub {
        @a = qw/a b c/;
        @b = qw/1 2 3/;
        eval {
            @c = pairwise { $b == 3 and die "Primes suck!"; "$a:$b" } @a, @b;
        };
    }
);

SKIP:
{
    $INC{'List/MoreUtils/XS.pm'} or skip "PurePerl will warn here ...", 1;
    my ($a, $b, @t);
    eval {
        my @l1 = (1 .. 10);
        @t = pairwise { $a + $b } @l1, @l1;
    };
    my $err = $@;
    like($err, qr/Can't use lexical \$a or \$b in pairwise code block/, "pairwise die's on broken caller");
}

SKIP:
{
    $INC{'List/MoreUtils/XS.pm'} and skip "XS will die on purpose here ...", 1;
    my @warns = ();
    local $SIG{__WARN__} = sub { push @warns, @_ };
    my ($a, $b, @t);
    my @l1 = (1 .. 10);
    @t = pairwise { $a + $b } @l1, @l1;
    like(join("", @warns[0, 1]), qr/Use of uninitialized value.*? in addition/, "warning on broken caller");
}

is_dying('pairwise without sub' => sub { &pairwise(42, \@a, \@b); });
SKIP:
{
    $INC{'List/MoreUtils/XS.pm'} or skip "PurePerl will not core here ...", 2;
    is_dying(
        'pairwise without first ARRAY' => sub {
            @c = &pairwise(sub { }, 1, \@b);
        }
    );
    is_dying(
        'pairwise without second ARRAY' => sub {
            @c = &pairwise(sub { }, \@a, 2);
        }
    );
}

done_testing;
