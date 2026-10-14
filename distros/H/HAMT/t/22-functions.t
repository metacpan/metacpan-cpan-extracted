#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use HAMT::Map qw(:all);
use HAMT::Set qw(:all);
use HAMT::Vector qw(:all);

# The function forms of the reads. Each must answer exactly as its method
# does, by every route a function can be called: a plain call, a call with an
# ampersand, and a call through a reference.

my $m = HAMT::Map->new(a => 1, b => undef, "caf\x{e9}" => 'latin', "\x{263a}" => 'wide');
my $s = HAMT::Set->new(qw(x y z), "\x{263a}");
my $v = HAMT::Vector->new(10, 20, 30);

is(hamt_map_get($m, 'a'), 1, 'hamt_map_get');
is(hamt_map_get($m, 'b'), undef, 'a stored undef');
is(hamt_map_get($m, 'nope'), undef, 'a missing key');
is(hamt_map_get($m, "\x{263a}"), 'wide', 'a wide key');
ok(hamt_map_exists($m, 'b'), 'hamt_map_exists of a stored undef');
ok(!hamt_map_exists($m, 'nope'), 'and of a missing key');
is(hamt_map_count($m), 4, 'hamt_map_count');
ok(hamt_set_has($s, 'y'), 'hamt_set_has');
ok(!hamt_set_has($s, 'w'), 'and of a missing member');
ok(hamt_set_has($s, "\x{263a}"), 'and of a wide one');
is(hamt_set_count($s), 4, 'hamt_set_count');
is(hamt_vector_get($v, 1), 20, 'hamt_vector_get');
is(hamt_vector_get($v, -1), 30, 'a negative index');
is(hamt_vector_get($v, 3), undef, 'past the end');
is(hamt_vector_get($v, -4), undef, 'before the start');
is(hamt_vector_count($v), 3, 'hamt_vector_count');

{
    my $up = "caf\x{e9}";
    utf8::upgrade($up);
    is(hamt_map_get($m, $up), 'latin', 'one key in either encoding');
}

is(refaddr(\hamt_map_get($m, 'a')), refaddr(\$m->get('a')),
   'hamt_map_get hands back the stored scalar, as get does');
ok(Internals::SvREADONLY(${\hamt_map_get($m, 'a')}), 'which is read-only');
{
    my $r = \hamt_map_get($m, 'nope');
    ok(!Internals::SvREADONLY($$r), 'a missing key is a scalar of its own');
    isnt(refaddr($r), refaddr(\undef), 'and not the shared undef');
}
is(refaddr(\hamt_vector_get($v, 0)), refaddr(\$v->get(0)), 'hamt_vector_get likewise');

# Every route.
{
    no strict 'refs';
    my @two = ([hamt_map_get => $m, 'a', 1], [hamt_map_exists => $m, 'b', 1],
               [hamt_set_has => $s, 'x', 1], [hamt_vector_get => $v, 2, 30]);
    for my $c (@two) {
        my ($name, $obj, $arg, $want) = @$c;
        my $class = ref $obj;
        my $code = \&{"main::$name"};
        is($code->($obj, $arg), $want, "$name through a reference");
        is(&$code($obj, $arg), $want, "$name with an ampersand");
        is(&{"${class}::$name"}($obj, $arg), $want, "${class}::$name by its full name");
    }
    for my $c ([hamt_map_count => $m, 4], [hamt_set_count => $s, 4], [hamt_vector_count => $v, 3]) {
        my ($name, $obj, $want) = @$c;
        my $class = ref $obj;
        my $code = \&{"main::$name"};
        is($code->($obj), $want, "$name through a reference");
        is(&{"${class}::$name"}($obj), $want, "${class}::$name by its full name");
    }
    ok(!eval { my $code = \&hamt_map_get; $code->($m); 1 }, 'too few arguments through a reference dies');
    like($@, qr/Usage: HAMT::Map::hamt_map_get\(self, key\)/, 'with the usage');
}
is(&hamt_map_get($m, 'a'), 1, 'a literal ampersand call');
is(HAMT::Map::hamt_map_get($m, 'a'), 1, 'a call by full name');

# Arguments that are not simple variables.
{
    my %h = (m => $m, k => 'a');
    my @a = ($v);
    is(hamt_map_get($h{m}, $h{k}), 1, 'hash elements');
    is(hamt_map_get($h{m}, 'c' . 'af' . "\x{e9}"), 'latin', 'an expression for the key');
    is(hamt_vector_get($a[0], 1 + 1), 30, 'an expression for the index');
    is(hamt_map_get(HAMT::Map->new(q => 7), 'q'), 7, 'a map that is a temporary');
    is(hamt_map_count($m->set(zz => 1)), 5, 'a method call for the argument');
    is(hamt_map_count($m) + hamt_set_count($s) + hamt_vector_count($v), 11, 'three counts in one expression');
    my $outer = HAMT::Map->new(inner => $m, vec => $v);
    is(hamt_map_get(hamt_map_get($outer, 'inner'), 'a'), 1, 'one call inside another');
    is(hamt_vector_get(hamt_map_get($outer, 'vec'), hamt_map_get($m, 'a')), 20, 'calls for both arguments');
    my @pair = ($m, 'a');
    ok(!eval { &hamt_map_get(@pair, 'extra'); 1 }, 'too many arguments with an ampersand dies');
    is(&hamt_map_get(@pair), 1, 'an array flattens with an ampersand');
}

# One value whatever the context.
{
    my @r = hamt_map_get($m, 'nope');
    is(scalar @r, 1, 'a missing key is one undef in list context');
    my @c = (hamt_map_count($m), hamt_set_count($s), hamt_map_count($m));
    is("@c", '4 4 4', 'counts in a list are each their own');
    my @d = (hamt_map_count($m), hamt_vector_count($v), hamt_map_count($m));
    is("@d", '4 3 4', 'and of different kinds');
    my @seen;
    push @seen, hamt_map_count($_) for $m, $m->set(q => 1), HAMT::Map->new;
    is("@seen", '4 5 0', 'one call site, three maps');
    my @got = map { hamt_vector_get($v, $_) } 0 .. 2;
    is("@got", '10 20 30', 'one call site, three indices');
    hamt_map_get($m, 'a');
    pass('void context');
}

# A key that runs Perl to become a string, and one that dies doing it.
{
    package Local::Key;
    use overload '""' => sub { my @grow = map { $_ } 1 .. 5000; ${ $_[0] } }, fallback => 1;
    package Local::Bomb;
    use overload '""' => sub { die "no key\n" }, fallback => 1;
    package main;
    my $k = bless \(my $name = 'a'), 'Local::Key';
    is(hamt_map_get($m, $k), 1, 'an object that stringifies');
    ok(hamt_map_exists($m, $k), 'and for exists');
    my $sk = bless \(my $member = 'y'), 'Local::Key';
    ok(hamt_set_has($s, $sk), 'and for a set');
    my $vk = bless \(my $at = 2), 'Local::Key';
    is(hamt_vector_get($v, $vk), 30, 'and for an index');
    my @row = (5, hamt_map_get($m, $k), 6, hamt_map_get($m, $k), 7);
    is("@row", '5 1 6 1 7', 'in a list with values either side');
    my $bomb = bless [], 'Local::Bomb';
    ok(!eval { hamt_map_get($m, $bomb); 1 }, 'a key that dies');
    is($@, "no key\n", 'dies with its own message');
    is(hamt_map_get($m, 'a'), 1, 'and the map is read as before');

    require Tie::Scalar;
    tie my $tied, 'Tie::StdScalar';
    $tied = 'a';
    is(hamt_map_get($m, $tied), 1, 'a tied key');
    tie my $ti, 'Tie::StdScalar';
    $ti = 2;
    is(hamt_vector_get($v, $ti), 30, 'a tied index');
}

# What is not the right thing.
for my $c (['hamt_map_get($s, "a")', qr/^hamt_map_get: not a map/],
           ['hamt_map_exists($v, "a")', qr/^hamt_map_exists: not a map/],
           ['hamt_map_count($s)', qr/^hamt_map_count: not a map/],
           ['hamt_set_has($m, "a")', qr/^hamt_set_has: not a set/],
           ['hamt_set_count($m)', qr/^hamt_set_count: not a set/],
           ['hamt_vector_get($m, 0)', qr/^hamt_vector_get: not a vector/],
           ['hamt_vector_count($s)', qr/^hamt_vector_count: not a vector/],
           ['hamt_map_get(undef, "a")', qr/^hamt_map_get: not a map/],
           ['hamt_map_get({}, "a")', qr/^hamt_map_get: not a map/],
           ['hamt_map_get("HAMT::Map", "a")', qr/^hamt_map_get: not a map/],
           ['hamt_map_count($m->transient)', qr/^hamt_map_count: not a map/]) {
    my ($code, $re) = @$c;
    ok(!eval "$code; 1", "$code dies");
    like($@, $re, 'and says what it wanted');
}

# The prototypes, which are the arity check of a plain call.
is(prototype(\&hamt_map_get), '$$', 'hamt_map_get takes two scalars');
is(prototype(\&hamt_map_exists), '$$', 'hamt_map_exists');
is(prototype(\&hamt_set_has), '$$', 'hamt_set_has');
is(prototype(\&hamt_vector_get), '$$', 'hamt_vector_get');
is(prototype(\&hamt_map_count), '$', 'hamt_map_count takes one');
is(prototype(\&hamt_set_count), '$', 'hamt_set_count');
is(prototype(\&hamt_vector_count), '$', 'hamt_vector_count');
ok(!eval 'hamt_map_get($m); 1', 'one argument does not compile');
like($@, qr/Not enough arguments for (?:HAMT::Map|main)::hamt_map_get/, 'and says so');
ok(!eval 'hamt_map_get($m, "a", "b"); 1', 'three do not compile');
like($@, qr/Too many arguments for (?:HAMT::Map|main)::hamt_map_get/, 'and says so');
ok(!eval 'hamt_map_count(); 1', 'a count of nothing does not compile');
ok(!eval 'hamt_map_count($m, 1); 1', 'nor of two things');
{
    my @list = ($m, 'a');
    ok(!eval { no warnings; hamt_map_get(@list, 'a'); 1 }, 'an array is one scalar to a plain call');
}

# The value outlives the container it was read from.
{
    my $got;
    {
        my $short = HAMT::Map->new(k => [1, 2, 3]);
        $got = hamt_map_get($short, 'k');
    }
    is_deeply($got, [1, 2, 3], 'a value read from a map that is gone');
    my $n = 0;
    {
        package Local::Counted;
        sub DESTROY { $n++ }
    }
    {
        my $vec = HAMT::Vector->new(bless([], 'Local::Counted'));
        my $held = hamt_vector_get($vec, 0);
        undef $vec;
        is($n, 0, 'a value read from a vector is alive while it is held');
    }
    is($n, 1, 'and destroyed once when it is not');

    # The container is dropped while the value is still on its way.
    $n = 0;
    my $gone = HAMT::Map->new(k => bless([], 'Local::Counted'));
    my @r = (hamt_map_get($gone, 'k'), do { undef $gone; $n });
    is($r[1], 0, 'a value read from a map dropped in the same expression is still alive');
    isa_ok($r[0], 'Local::Counted');
    @r = ();
    is($n, 1, 'and destroyed once after');
    $n = 0;
    my $vgone = HAMT::Vector->new(bless([], 'Local::Counted'));
    @r = (hamt_vector_get($vgone, 0), do { undef $vgone; $n });
    is($r[1], 0, 'and one read from a vector');
    @r = ();
    is($n, 1, 'destroyed once after');
}

# A plain call is compiled into an op of that name and makes no sub call.
SKIP: {
    skip 'call checkers are perl 5.14 and later', 9 if $] < 5.014;
    require B;
    my %site = (
        hamt_map_get      => sub { hamt_map_get($m, 'a') },
        hamt_map_exists   => sub { hamt_map_exists($m, 'a') },
        hamt_map_count    => sub { hamt_map_count($m) },
        hamt_set_has      => sub { hamt_set_has($s, 'x') },
        hamt_set_count    => sub { hamt_set_count($s) },
        hamt_vector_get   => sub { hamt_vector_get($v, 0) },
        hamt_vector_count => sub { hamt_vector_count($v) },
    );
    my $ops = sub {
        my %n;
        my $walk;
        $walk = sub {
            my $op = shift;
            return unless $$op;
            $n{ $op->name }++;
            if ($op->flags & B::OPf_KIDS()) {
                for (my $k = $op->first; $$k; $k = $k->sibling) { $walk->($k) }
            }
        };
        $walk->(B::svref_2object(shift)->ROOT);
        undef $walk;
        return \%n;
    };
    for my $name (sort keys %site) {
        my $n = $ops->($site{$name});
        ok($n->{$name} && !$n->{entersub}, "$name is an op and not a call")
            or diag(join ' ', map { "$_=$n->{$_}" } sort keys %$n);
    }
    my $n = $ops->(sub { &hamt_map_get($m, 'a') });
    ok($n->{entersub} && !$n->{hamt_map_get}, 'an ampersand call stays a call');
    $n = $ops->(sub { $m->get('a') });
    ok($n->{entersub}, 'and so does the method');
}

# Importing.
{
    package Local::One;
    HAMT::Set->import('hamt_set_has');
    package main;
    ok(defined &Local::One::hamt_set_has, 'one name is imported');
    ok(!defined &Local::One::hamt_set_count, 'and only that one');
    is(\&Local::One::hamt_set_has, \&HAMT::Set::hamt_set_has, 'it is the same sub');
    package Local::None;
    HAMT::Map->import;
    HAMT::Set->import;
    HAMT::Vector->import;
    package main;
    ok(!defined &Local::None::hamt_map_get, 'nothing is imported unasked');
    ok(!defined &Local::None::hamt_set_has, 'from a set either');
    ok(!defined &Local::None::hamt_vector_get, 'or a vector');
    package Local::All;
    HAMT::Map->import(':all');
    package main;
    is(join(' ', sort grep { defined &{"Local::All::$_"} } keys %Local::All::),
       'hamt_map_count hamt_map_exists hamt_map_get', ':all is the three of that class and no other');
    package Local::Vec;
    HAMT::Vector->import(':all');
    package main;
    is(join(' ', sort grep { defined &{"Local::Vec::$_"} } keys %Local::Vec::),
       'hamt_vector_count hamt_vector_get', 'and the two of a vector');
    ok(!eval { package Local::Bad; HAMT::Map->import('hamt_map_set'); 1 }, 'an unknown name dies');
    like($@, qr/^HAMT::Map does not export "hamt_map_set"/, 'and names it and the class');
    ok(!eval { package Local::Bad; HAMT::Map->import('hamt_set_has'); 1 }, 'a class does not export another\'s');
    like($@, qr/^HAMT::Map does not export "hamt_set_has"/, 'and says so');
    ok(!eval { package Local::Bad; HAMT::Vector->import('hamt_map_get'); 1 }, 'nor a vector a map\'s');
    like($@, qr/^HAMT::Vector does not export "hamt_map_get"/, 'and says so');
    ok(!eval { package Local::Bad; HAMT::Set->import(':reads'); 1 }, 'an unknown tag dies');
    ok(!defined &Local::Bad::hamt_set_has, 'and nothing was imported by the failures');
    ok(!defined &HAMT::import, 'HAMT itself exports nothing');
    ok(eval q{package Local::Lex; use HAMT::Vector qw(hamt_vector_count); hamt_vector_count($v) == 3}, 'use with a list')
        or diag $@;
    {
        package Local::Sub;
        our @ISA = ('HAMT::Map');
        package Local::User;
        Local::Sub->import('hamt_map_get');
        package main;
        is(\&Local::User::hamt_map_get, \&HAMT::Map::hamt_map_get, 'a subclass exports its parent\'s');
        is(Local::User::hamt_map_get(Local::Sub->new(k => 1), 'k'), 1, 'and it reads a subclass object');
    }
}

done_testing;
