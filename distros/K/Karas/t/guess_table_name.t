use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

subtest 'guess_table_name' => sub {
    my $db = create_karas();
    is($db->guess_table_name(q{SELECT * FROM tb}), 'tb', 'normal');
    is($db->guess_table_name(q{SELECT * FROM tb INNER JOIN x ON (tb.x=x.y)}), 'tb', 'inner join');
};

done_testing;

