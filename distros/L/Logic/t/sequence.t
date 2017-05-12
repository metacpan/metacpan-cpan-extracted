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

my $seq;
my $stack;

ok($seq = Logic::Basic::Sequence->new(qw<Logic::Basic::Identity>), "Sequence->new");
$stack = Logic::Stack->new($seq);

ok($stack->run, "identity sequence");
ok(!$stack->backtrack, "backtrack is noop");

$seq = Logic::Basic::Sequence->new(qw<Logic::Basic::Identity Logic::Basic::Identity>);
$stack = Logic::Stack->new($seq);

ok($stack->run, "double identity");
ok(!$stack->backtrack, "backtrack is noop");

$seq = Logic::Basic::Sequence->new(qw<Logic::Basic::Fail>);
$stack = Logic::Stack->new($seq);

ok(!$stack->run, "fail fails");

$seq = Logic::Basic::Sequence->new(qw<Logic::Basic::Fail Logic::Basic::Identity>);
$stack = Logic::Stack->new($seq);

ok(!$stack->run, "fail . identity fails");

$seq = Logic::Basic::Sequence->new(qw<Logic::Basic::Identity Logic::Basic::Fail>);
$stack = Logic::Stack->new($seq);

ok(!$stack->run, "identity . fail fails");

my $counter;

my $count = 0;
$counter = Logic::Basic::Assertion->new(sub { $count++; undef });
$seq = Logic::Basic::Sequence->new(Ten->new('a'), $counter);
$stack = Logic::Stack->new($seq);

ok(!$stack->run, "counter will always fail");
is($count, 10, "counted to ten properly");

$count = 0;
$seq = Logic::Basic::Sequence->new(Ten->new('a'), Ten->new('b'), $counter);
$stack = Logic::Stack->new($seq);

ok(!$stack->run, "counter always fails");
is($count, 100, "10 x 10 = 100");

# vim: ft=perl :
