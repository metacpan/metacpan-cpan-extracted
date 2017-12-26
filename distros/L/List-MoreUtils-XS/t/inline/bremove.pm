
use Test::More;
use Test::LMU;

my @even = map { $_ * 2 } 1 .. 100;
my @odd  = map { $_ * 2 - 1 } 1 .. 100;
my (@expected, @in);

@expected = @even;
@in = mesh @odd, @even;
foreach my $v (@odd)
{
    is($v, (bremove { $_ <=> $v } @in), "$v in order removed");
}
is_deeply(\@in, \@expected, "bremove all odd elements succeeded");

@in = mesh @odd, @even;
foreach my $v (reverse @odd)
{
    is($v, (bremove { $_ <=> $v } @in), "$v reverse ordered removed");
}
is_deeply(\@in, \@expected, "bremove all odd elements reversely succeeded");

@expected = @odd;
@in = mesh @odd, @even;
foreach my $v (@even)
{
    is($v, (bremove { $_ <=> $v } @in), "$v in order removed");
}
is_deeply(\@in, \@expected, "bremove all even elements succeeded");

@in = mesh @odd, @even;
foreach my $v (reverse @even)
{
    is($v, (bremove { $_ <=> $v } @in), "$v reverse ordered removed");
}
is_deeply(\@in, \@expected, "bremove all even elements reversely succeeded");

# test from shawnlaffan from GH issue #2 of List-MoreUtils-XS
SCOPE:
{
    my @list   = ('somestring');
    my $target = $list[0];
    is($target, (bremove { $_ cmp $target } @list), 'removed from single item list');
}

leak_free_ok(
    'bremove first' => sub {
        my @list = (1 .. 100);
        my $v    = $list[0];
        bremove { $_ <=> $v } @list;
    },
    'bremove last' => sub {
        my @list = (1 .. 100);
        my $v    = $list[-1];
        bremove { $_ <=> $v } @list;
    },
    'bremove middle' => sub {
        my @list = (1 .. 100);
        my $v    = $list[int($#list / 2)];
        bremove { $_ <=> $v } @list;
    },
);

leak_free_ok(
    'bremove first with stack-growing' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[0];
        bremove { grow_stack(); $_ <=> $v } @list;
    },
    'bremove last with stack-growing' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[-1];
        bremove { grow_stack(); $_ <=> $v } @list;
    },
    'bremove middle with stack-growing' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[int($#list / 2)];
        bremove { grow_stack(); $_ <=> $v } @list;
    },
);

leak_free_ok(
    'bremove first with stack-growing and exception' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[0];
        eval {
            bremove { grow_stack(); $_ <=> $v or die "Goal!"; $_ <=> $v } @list;
        };
    },
    'bremove last with stack-growing and exception' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[-1];
        eval {
            bremove { grow_stack(); $_ <=> $v or die "Goal!"; $_ <=> $v } @list;
        };
    },
    'bremove middle with stack-growing and exception' => sub {
        my @list = mesh @odd, @even;
        my $v = $list[int($#list / 2)];
        eval {
            bremove { grow_stack(); $_ <=> $v or die "Goal!"; $_ <=> $v } @list;
        };
    },
);
is_dying('bremove without sub' => sub { &bremove(42, @even); });

done_testing;
