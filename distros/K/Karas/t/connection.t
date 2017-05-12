use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

subtest 'dbh' => sub {
    my $db = create_karas();
    isa_ok($db->dbh, 'DBI::db');
};

subtest 'disconnect' => sub {
    my $db = create_karas();
    my $dbh = $db->dbh;
    $db->disconnect();
    ok(!$dbh->ping);
};

done_testing;

