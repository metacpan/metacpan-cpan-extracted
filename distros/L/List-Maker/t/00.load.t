use Test::More tests => 1;

BEGIN {
    use_ok( 'List::Maker' )
    or
    BAIL_OUT($@);
}

diag( "Testing List::Maker $List::Maker::VERSION" );
