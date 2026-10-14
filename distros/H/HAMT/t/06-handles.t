#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(blessed refaddr);
use HAMT::Map;

# What is and is not a map, the void-context warning, subclasses, threads.

my $m = HAMT::Map->new(a => 1);

# ---- things that are not a map ----------------------------------------------
#
# The forged ones are the point. A blessed integer is what a class that keeps
# an address in an IV would dereference, and what a deserialiser builds when
# it is handed somebody else's bytes; here it is just not a map.
my @not = (
    [ 'a string'                  => 'HAMT::Map' ],
    [ 'undef'                     => undef ],
    [ 'a number'                  => 12345 ],
    [ 'an unblessed reference'    => {} ],
    [ 'an object of another class' => bless({}, 'Local::Other') ],
    [ 'a hash blessed into the class' => bless({}, 'HAMT::Map') ],
    [ 'an integer blessed into the class' => bless(\(my $n = 12345), 'HAMT::Map') ],
    [ 'the address of a real map, blessed into the class'
        => bless(\(my $a = refaddr($m)), 'HAMT::Map') ],
    [ 'an object carrying another extension\'s magic' => HAMT::_foreign_handle('HAMT::Map') ],
);
for my $case (@not) {
    my ($name, $thing) = @$case;
    for my $method (qw(get exists count keys values pairs to_hash set delete _check)) {
        my @args = $method =~ /^(?:get|exists|delete)$/ ? ('a')
                 : $method eq 'set'                     ? (a => 1)
                 :                                        ();
        no warnings 'uninitialized';
        my $ok = eval { my @r = HAMT::Map->can($method)->($thing, @args); 1 };
        ok(!$ok && $@ =~ /^HAMT::Map::\Q$method\E: not a map/, "$name is refused by $method")
            or diag("got: " . ($ok ? 'no error' : $@));
    }
}
undef $_ for map { $_->[1] } @not;      # and none of them crashes on the way out
pass('the forged objects were destroyed without incident');
is($m->get('a'), 1, 'and the real map is unharmed');

# ---- the handle -------------------------------------------------------------
ok(!HAMT::Map->can('DESTROY'), 'there is no DESTROY method to call twice');
ok(blessed($m) && $m->isa('HAMT::Map'), 'a map is an object of its class');
{
    my $copy = $m;
    is(refaddr($copy), refaddr($m), 'copying the reference is the same map');
    undef $copy;
    is($m->get('a'), 1, 'and dropping the copy leaves it alone');
}

# ---- subclasses -------------------------------------------------------------
{
    package Local::Sub;
    our @ISA = ('HAMT::Map');
    our $destroyed = 0;
    sub describe { 'a subclass with ' . $_[0]->count }
    sub DESTROY { $destroyed++ }
}
{
    my $s = Local::Sub->new(a => 1);
    isa_ok($s, 'Local::Sub');
    is($s->describe, 'a subclass with 1', 'its own methods work');
    isa_ok($s->set(b => 2), 'Local::Sub', 'set returns the subclass');
    isa_ok($s->delete('a'), 'Local::Sub', 'so does delete');
    isa_ok(Local::Sub->from_hash({ x => 1 }), 'Local::Sub', 'and from_hash');
    isa_ok($s->new(z => 1), 'Local::Sub', 'new called on an object makes one of its class');
    is($s->new->count, 0, 'which starts empty and does not copy the receiver');
    is($s->set(b => 2)->describe, 'a subclass with 2', 'and the result has the methods');
}
cmp_ok($Local::Sub::destroyed, '>=', 5, 'a subclass may have a DESTROY of its own, and it runs');

# ---- void context -----------------------------------------------------------
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };

    $m->set(b => 2);
    is(scalar @w, 1, 'set in void context warns');
    like($w[0], qr/^Useless use of HAMT::Map::set in void context at \Q${\ __FILE__}\E line \d+/,
         'naming itself and the caller\'s line');
    is($m->count, 1, 'and did nothing');

    @w = ();
    $m->delete('a');
    is(scalar @w, 1, 'delete in void context warns');
    like($w[0], qr/^Useless use of HAMT::Map::delete in void context/, 'naming itself');
    is($m->count, 1, 'and did nothing');

    @w = ();
    { no warnings 'void'; $m->set(b => 2); $m->delete('a'); }
    is(scalar @w, 0, 'no warnings \'void\' silences both');

    @w = ();
    { no warnings; $m->set(b => 2); }
    is(scalar @w, 0, 'and so does no warnings');

    @w = ();
    my $kept = $m->set(b => 2);
    my @list = $m->delete('a');
    $m->get('a'); $m->exists('a'); $m->count; $m->keys;
    is(scalar @w, 0, 'a result that is kept does not warn, nor does a read in void context');

    @w = ();
    ok(!eval { $m->set('odd'); 1 }, 'an odd list still croaks in void context');
    is(scalar @w, 0, 'rather than warning');
}

# ---- threads ----------------------------------------------------------------
SKIP: {
    skip 'this perl has no ithreads', 4 unless $Config{useithreads};
    skip 'threads.pm does not load', 4 unless eval { require threads; 1 };

    is(HAMT::Map->CLONE_SKIP, 1, 'the class asks not to be cloned');

    my $shared = HAMT::Map->new(map { ("k$_" => "v$_") } 1 .. 100);
    my ($seen, $own) = threads->create({ context => 'list' }, sub {
        my $fresh = HAMT::Map->new(x => 1)->set(y => 2);
        # Under CLONE_SKIP the clone is an unblessed reference to undef.
        my $usable = eval { $shared->count; 1 } ? 'usable' : 'dead';
        return ((Scalar::Util::blessed($shared) ? 'blessed' : 'unblessed') . " and $usable",
                $fresh->count);
    })->join;
    is($seen, 'unblessed and dead', 'a new thread does not get the parent\'s handle');
    is($own, 2, 'and can build maps of its own');
    is($shared->count, 100, 'the parent\'s map is intact after the thread has gone');
}

done_testing;
