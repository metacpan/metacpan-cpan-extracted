#!perl -T

use Test::More tests => 3;

BEGIN { use_ok( 'DhMakePerl::Utils', qw( split_version_relation ) ) };

is_deeply(
    [ split_version_relation('0.45') ],
    [ '>=', '0.45' ],
);

is_deeply(
    [ split_version_relation('> 0.56') ],
    [ '>>', '0.56' ],
);
