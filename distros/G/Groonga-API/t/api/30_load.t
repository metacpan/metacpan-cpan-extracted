use strict;
use warnings;
use Groonga::API::Test;

table_test(sub {
  my ($ctx, $db, $table) = @_;

  my $name = "text";
  my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
  ok defined $type, "type is defined";

  my $column = Groonga::API::column_create($ctx, $table, $name, bytes::length($name), undef, GRN_OBJ_PERSISTENT, $type);
  ok defined $column, "created column";

  my $data = encode_json([
    {_key => 'key1', text => 'text1'},
    {_key => 'key2', text => 'text2'},
    {_key => 'key3', text => 'text3'},
  ]);

  my $rc = Groonga::API::load($ctx, GRN_CONTENT_JSON,
    "table", bytes::length("table"),
    undef, 0,
    $data, bytes::length($data),
    undef, 0,
    undef, 0,
  );
  is $rc => GRN_SUCCESS, "loaded";

  Groonga::API::obj_unlink($ctx, $column) if $column;
});

done_testing;
