use strict;
use warnings;
use Test::More tests => 4;
use Google::Spanner::V1::Spanner;
use Google::Cloud::Spanner::V1;

my $req_bytes = Google::Cloud::Spanner::V1->new_execute_sql_request({
    session => 'projects/p/instances/i/databases/d/sessions/s1',
    sql     => 'SELECT id, name FROM spanner_table',
});

ok($req_bytes, 'Encoded ExecuteSqlRequest protobuf bytes');
cmp_ok(length($req_bytes), '>', 0, 'Protobuf payload is non-empty');

my $res_msg = Google::Spanner::V1::ResultSet::PartialResultSet->new({
    values => [ { string_value => '101' }, { string_value => 'Spanner' } ],
});
my $res_bytes = $res_msg->serialize();

my $decoded = Google::Cloud::Spanner::V1->parse_partial_result_set($res_bytes);
ok($decoded, 'Decoded PartialResultSet protobuf message');
is($decoded->values->[1]->string_value, 'Spanner', 'Parsed value matches Spanner');
