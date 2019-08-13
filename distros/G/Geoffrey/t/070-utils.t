use Test::More tests => 6;

use strict;
use FindBin;
use warnings;
use Test::Exception;

require_ok('Geoffrey::Utils');
use_ok 'Geoffrey::Utils';

throws_ok { Geoffrey::Utils::replace_spare(); } 'Geoffrey::Exception::RequiredValue',
    'Unknown action thrown';

is( Geoffrey::Utils::add_name( { name => 'test_name' } ), 'test_name', 'Success with name key' );

ok( Geoffrey::Utils::add_name( { prefix => 'ix' } ) =~ /^ix_\d+$/, 'OK with prefix  key' );

ok( Geoffrey::Utils::add_name( { prefix => 'ix', context => 'any_context' } )
        =~ /^ix_any_context_\d+$/,
    'Success with prefix and context key'
);
