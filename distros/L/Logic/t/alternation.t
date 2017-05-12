use Test::More tests => 14;

BEGIN { use_ok('Logic::Stack'); }
BEGIN { use_ok('Logic::Basic'); }

package Ten;

sub new {
    my ($class, $param) = @_;

    bless {
        param => $param,
    } => ref $class || $class;
}

sub create {
    my ($self) = @_;
    
    $self;
}

sub enter {
    my ($self, $stack, $state) = @_;
    
    $state->save;
    $state->{$self->{param}} = 1;
}

sub backtrack {
    my ($self, $stack, $state) = @_;
    if ($state->{$self->{param}} < 10) {
        $state->{$self->{param}}++;
    }
}

sub cleanup {
    my ($self, $stack, $state) = @_;
    $state->restore;
}

package main;

my $alt;
my $stack;

ok($alt = Logic::Basic::Alternation->new(qw<Logic::Basic::Identity>), "new alternation");
$stack = Logic::Stack->new($alt);
ok($stack->run, "identity alternated succeeds");
ok(!$stack->backtrack, "backtrack fails");

$alt = Logic::Basic::Alternation->new(qw<Logic::Basic::Identity Logic::Basic::Fail>);
$stack = Logic::Stack->new($alt);

ok($stack->run, "identity | fail is identity");
ok(!$stack->backtrack, "backtrack fails");

$alt = Logic::Basic::Alternation->new(qw<Logic::Basic::Fail Logic::Basic::Identity>);
$stack = Logic::Stack->new($alt);

ok($stack->run, "fail | identity is identity");
ok(!$stack->backtrack, "backtrack fails");

$alt = Logic::Basic::Alternation->new(qw<Logic::Basic::Identity Logic::Basic::Identity>);
$stack = Logic::Stack->new($alt);

ok($stack->run, "identity | identity is identity");
ok($stack->backtrack, "backtrack succeeds");
ok(!$stack->backtrack, "backtrack again fails");

my $count = 0;
my $counter = Logic::Basic::Assertion->new(sub { $count++; undef });
my $seq = Logic::Basic::Sequence->new(Ten->new('x'), $counter);
$alt = Logic::Basic::Alternation->new($seq, $seq);
$stack = Logic::Stack->new($alt);
ok(!$stack->run, "fail, but doesn't matter");
is($count, 20, 'alternation represents addition');

# vim: ft=perl :
