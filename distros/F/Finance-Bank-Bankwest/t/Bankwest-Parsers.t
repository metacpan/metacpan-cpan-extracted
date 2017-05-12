use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

use Module::Loaded 'is_loaded';

test 'parsers loaded when Parsers used' => sub {
    ok(
        (not is_loaded 'Finance::Bank::Bankwest::Parser::Login'),
        'Parser::Login must not be loaded before Parsers used',
    );
    use_ok('Finance::Bank::Bankwest::Parsers');
    ok(
        (is_loaded 'Finance::Bank::Bankwest::Parser::Login'),
        'Parser::Login must be loaded after Parsers used',
    );
};

test 'Login handler must be called by default' => sub {
    is_deeply(
        [ Finance::Bank::Bankwest::Parsers->default_handlers ],
        [ 'Login' ],
    );
};

test 'correct default exception must be thrown' => sub {
    is
        Finance::Bank::Bankwest::Parsers->default_exception,
        'Finance::Bank::Bankwest::Error::BadResponse';
};

run_me;
done_testing;
