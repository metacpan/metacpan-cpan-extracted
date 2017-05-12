use Test::More tests => 4;

BEGIN { use_ok('Logic::Stack') }
BEGIN { use_ok('Logic::Basic') }

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

my $count = 0;
my $mark = Logic::Stack::Mark->new;
my $stack = Logic::Stack->new(
    Ten->new('X'),
    $mark,
    Ten->new('Y'),
    Logic::Stack::Cut->new($mark),
    Logic::Basic::Assertion->new(sub { ++$count }),
    Logic::Basic::Fail->new,
);

ok(!$stack->run, "Ultimately fails");
is($count, 10, "Ran correctly");

# vim: ft=perl :
