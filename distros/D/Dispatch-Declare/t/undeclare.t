use Test::More tests => 3;

BEGIN {
    use_ok( 'Dispatch::Declare' );
}

my $action = 'TEST1';

declare_once TEST1 => sub {
    return 'ONE'
};

declare TEST2 => sub {
    return 'TWO'
};

undeclare 'TEST1';

my $result = run $action;

ok !$result,'The action has been removed';

my $result2 = run 'TEST2';

is $result2, 'TWO', 'I can still get other actions';
