use Test::More tests => 2;
use vars qw( $class );

BEGIN {
    $class = 'Email::Thread';
    use_ok $class;
}

pass "Didn't crash and burn";
