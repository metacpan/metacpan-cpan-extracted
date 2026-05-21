use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);
use EV;
use EV::cares qw(:status);

# default loop (no option)
{
    my $r = EV::cares->new(lookups => 'f');
    isa_ok($r, 'EV::cares', 'default loop construction');
}

# explicit non-default loop
{
    my $loop = EV::Loop->new;
    isa_ok($loop, 'EV::Loop', 'EV::Loop->new');

    my $r = EV::cares->new(loop => $loop, lookups => 'f');
    isa_ok($r, 'EV::cares', 'construction with custom loop');

    my @got;
    my $done;
    $r->resolve('localhost', sub { @got = @_; $done = 1 });

    # run only the custom loop (not EV_DEFAULT) — proves wiring
    my $timer = $loop->timer(5, 0, sub { $done = 1 });
    $loop->run until $done;

    is($got[0], ARES_SUCCESS, 'resolve completed on custom loop');
    ok(@got > 1, 'got addresses');
}

# undef loop falls back to default
{
    my $r = EV::cares->new(loop => undef, lookups => 'f');
    isa_ok($r, 'EV::cares', 'undef loop -> default');
}

# bad loop value rejected
{
    eval { EV::cares->new(loop => 42) };
    like($@, qr/EV::Loop/, 'non-EV::Loop value rejected');

    eval { EV::cares->new(loop => bless {}, 'Wrong::Class') };
    like($@, qr/EV::Loop/, 'wrong-class blessed ref rejected');
}

# resolver retains the loop SV: dropping the user's last ref must not
# free the loop until the resolver itself is gone
{
    my $loop = EV::Loop->new;
    my $weak = $loop;
    weaken($weak);

    my $r = EV::cares->new(loop => $loop, lookups => 'f');
    undef $loop;
    ok(defined $weak, 'loop SV retained while resolver is alive');

    undef $r;
    ok(!defined $weak, 'loop SV released after resolver destroyed');
}

done_testing;
