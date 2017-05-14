use Test::More;
use Carp 'verbose';
use Net::Objwrap ':all-test';
use 5.012;
use Scalar::Util 'reftype';

my $wrap_cfg = 't/11.cfg';
unlink $wrap_cfg;

my $r0 = ArrayThing->new(1,2,3,4);

ok($r0 && ref($r0) eq 'ArrayThing', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,$r0), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my ($r1) = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
is(ref($r1), 'Net::Objwrap::Proxy', 'client ref');

ok(Net::Objwrap::ref($r1) eq 'ArrayThing', 'remote ref');
ok(Net::Objwrap::reftype($r1) eq 'ARRAY', 'remote reftype');

is($r1->[3], 4, 'array access');

push @$r1, [15,16,17], 18;
is($r1->[-3], 4, 'push to remote array');

$r1->[2] = 19;
is($r1->[2], 19, 'set remote array');

is(shift @$r1, 1, 'shift from remote array');

unshift @$r1, (25 .. 31);
is($r1->[6], 31, 'unshift to remote array');
is($r1->[7], 2, 'unshift to remote array');

is(pop @$r1, 18, 'pop from remote array');
my $r2 = pop @$r1;
is("@$r2","15 16 17", 'pop array ref from remote array');

ok(18 == $r1->reverse, 'called remote method');

is("@$r1", "4 19 2 31 30 29 28 27 26 25",
   'remote method affects object');

is($r1->[4], $r1->get(4), 'remote method ok');

my @x = $r1->context_dependent;
my $x = $r1->context_dependent;

is($x, $r1->get(1), 'context dependent in scalar context');
    is("@x", "5 6 7", 'context dependent in list context');

done_testing;


# ArrayThing - a blessed ARRAY reference with a couple of
# methods to exercise remote manipulation

sub ArrayThing::new {
    my ($pkg,@list) = @_;
    return bless [ @list ], 'ArrayThing';
}

sub ArrayThing::reverse {
    my $self = shift;
    @$self = reverse @$self;
    return 18;
}

sub ArrayThing::increment {
    my ($self, $n) = @_;
    $n //= 1;
    $_ += $n for @$self;
    return;
}

sub ArrayThing::get {
    my ($self,$index) = @_;
    return $self->[$index];
}

sub ArrayThing::context_dependent {
    my $self = shift;
    if (wantarray) {
	return (5,6,7);
    } else {
	return $self->[1];
    }
}
