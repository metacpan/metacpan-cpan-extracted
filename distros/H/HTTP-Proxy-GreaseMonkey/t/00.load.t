use Test::More tests => 5;

BEGIN {
    use_ok( 'App::GreaseMonkeyProxy' );
    use_ok( 'HTTP::Proxy::GreaseMonkey' );
    use_ok( 'HTTP::Proxy::GreaseMonkey::Redirector' );
    use_ok( 'HTTP::Proxy::GreaseMonkey::Script' );
    use_ok( 'HTTP::Proxy::GreaseMonkey::ScriptHome' );
}

diag(
    "Testing HTTP::Proxy::GreaseMonkey $HTTP::Proxy::GreaseMonkey::VERSION"
);
