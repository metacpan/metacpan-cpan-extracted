use strict;
use warnings;
use Groonga::API::Test;

table_test(sub {
  my ($ctx, $db, $table) = @_;

  my $key_type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
  ok defined $key_type, "defined key type";

  my $value_type = Groonga::API::ctx_at($ctx, GRN_DB_UINT32);
  ok defined $value_type, "defined value type";

  my $table2 = Groonga::API::table_create($ctx, undef, 0, undef, GRN_OBJ_TABLE_HASH_KEY, $key_type, $value_type);
  ok defined $table2, "defined table2";

  for (qw/key1 key2 key3/) {
    my $id = Groonga::API::table_add($ctx, $table, $_, bytes::length($_), my $added);
    ok $id, "got an id";
  }

  for (qw/key1 key4 key5 key6/) {
    my $id = Groonga::API::table_add($ctx, $table2, $_, bytes::length($_), my $added);
    ok $id, "got an id";
  }

  my $rc = Groonga::API::table_difference($ctx, $table, $table2, $table, $table2);
  is $rc => GRN_SUCCESS, "difference";

  my $cursor = Groonga::API::table_cursor_open($ctx, $table, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);

  while ((my $id = Groonga::API::table_cursor_next($ctx, $cursor)) != GRN_ID_NIL) {
    isnt $id => 1, "table ID: $id";
  }

  Groonga::API::table_cursor_close($ctx, $cursor);

  $cursor = Groonga::API::table_cursor_open($ctx, $table2, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);

  while ((my $id = Groonga::API::table_cursor_next($ctx, $cursor)) != GRN_ID_NIL) {
    isnt $id => 1, "table2 ID: $id";
  }

  Groonga::API::table_cursor_close($ctx, $cursor);

  Groonga::API::obj_unlink($ctx, $table2);
});

done_testing;
