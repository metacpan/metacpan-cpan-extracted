use Test::More tests => 6;

BEGIN: { use_ok('HTML::HashTable'); }

use HTML::HashTable;

my $testhash = {
    grunt => {
                b => "c",
                d => [ qw( foo bar baz ) ],
           },
    snort => [ qw( wombat roo cocky ) ],
    blurf => "g",
};

ok(tablify({ DATA => $testhash }), "Tablify testhash");
like(tablify({ DATA => $testhash }), qr/blurf.*grunt.*snort/s, "output looks roughly right");
like(tablify({ DATA => $testhash, ORDER => 'desc'}), qr/snort.*grunt.*blurf/s, "sorting backwards works");
like(tablify({ DATA => $testhash, BORDER => 1}), qr/border=1/s, "with border");
like(tablify({ DATA => $testhash, BORDER => 0}), qr/border=0/s, "no border");
