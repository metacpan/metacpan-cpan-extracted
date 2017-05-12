use strict;
use warnings;
use Groonga::API::Test;

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  my $rc = load_into_table($ctx, [
    {_key => 'key1', text => 'text1'},
    {_key => 'key2', text => 'text2'},
    {_key => 'key3', text => 'text3'},
  ]);
  is $rc => GRN_SUCCESS, "loaded";

  {
    my $size = Groonga::API::table_size($ctx, $table);
    is $size => 3, "table size: $size";
  }

  {
    my $id = Groonga::API::table_at($ctx, $table, 1);
    is $id => 1, "record #1 exists";
  }

  {
    my $key = "key1";
    my $id = Groonga::API::table_get($ctx, $table, $key, bytes::length($key));
    is $id => 1, "got by key";
  }

  {
    my $buf = " " x 4096;
    my $len = Groonga::API::table_get_key($ctx, $table, 1, $buf, bytes::length($buf));
    my $key = $len ? substr($buf, 0, $len) : "";

    ok $len, "key1 length: $len";
    is $key => "key1", "key1: $key";
  }

  {
    my $name = "key1";
    my $new_id = Groonga::API::table_add($ctx, $table, $name, bytes::length($name), my $added);
    is $new_id => 1, "added an existing record";
    ok !$added, "added flag indicates false";
  }

  {
    my $name = "key4";
    my $new_id = Groonga::API::table_add($ctx, $table, $name, bytes::length($name), my $added);
    is $new_id => 4, "added a new record";
    ok $added, "added flag indicates true";
  }

  {
    my $name = "key4";
    my $id = Groonga::API::table_lcp_search($ctx, $table, $name, bytes::length($name));
    is $id => 4, "found the id";
  }

  {
    my $name = "key4";
    my $rc = Groonga::API::table_delete($ctx, $table, $name, bytes::length($name));
    is $rc => GRN_SUCCESS, "deleted a record";
  }

  {
    my $rc = Groonga::API::table_delete_by_id($ctx, $table, 3);
    is $rc => GRN_SUCCESS, "deleted a record by id";
  }

  {
    Groonga::API::obj_defrag($ctx, $table, 0);
    Groonga::API::obj_defrag($ctx, $db, 0);
  }

  {
    my $rc = Groonga::API::table_truncate($ctx, $table);
    is $rc => GRN_SUCCESS, "truncated";
  }
});

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  my $rc = load_into_table($ctx, [
    {_key => 'key1', text => 'text1'},
    {_key => 'key2', text => 'text2'},
    {_key => 'key3', text => 'text3'},
  ]);
  is $rc => GRN_SUCCESS, "loaded";

  {
    my $belongs_to = Groonga::API::obj_db($ctx, $table);
    ok defined $belongs_to, "got db";
    is ref $belongs_to => "Groonga::API::obj", "correct object";
    is $$belongs_to => $$db, "correct pointer";
  }

  {
    my $buf = ' ' x 4096;
    my $len = Groonga::API::obj_name($ctx, $table, $buf, bytes::length($buf));
    is substr($buf, 0, $len) => "table", "correct name";
  }

  {
    my $key_type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
    my $res = Groonga::API::table_create($ctx, undef, 0, undef, GRN_OBJ_TABLE_HASH_KEY, $key_type, undef);

    my $num = Groonga::API::table_columns($ctx, $table, undef, 0, $res);
    ok $num, "found $num column(s)";

    my $cursor = Groonga::API::table_cursor_open($ctx, $res, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);
    my @found;
    while(my $id = Groonga::API::table_cursor_next($ctx, $cursor)) {
      my $buf = ' ' x 4096;
      my $len = Groonga::API::table_cursor_get_key($ctx, $cursor, $buf);
      my $col_id = unpack 'L', substr($buf, 0, $len);
      my $col = Groonga::API::ctx_at($ctx, $col_id);
      $buf = ' ' x 4096;
      $len = Groonga::API::obj_name($ctx, $col, $buf, bytes::length($buf));
      push @found, substr($buf, 0, $len);
    }
    is_deeply [sort @found] => ["table.text"], "correct column(s)";

    Groonga::API::table_cursor_close($ctx, $cursor);
    Groonga::API::obj_unlink($ctx, $res);
  }

  {
    my $res = Groonga::API::obj_open($ctx, GRN_PVECTOR, 0, GRN_DB_OBJECT);
    my $rc = Groonga::API::obj_columns($ctx, $table, "*", bytes::length("*"), $res);
    is $rc => GRN_SUCCESS, "got columns";
    my $first_col = Groonga::API::PTR_VALUE_AT($res, 0);
    ok defined $first_col, "first column";

    my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    Groonga::API::obj_get_value($ctx, $first_col, 1, $bulk);
    is Groonga::API::TEXT_VALUE($bulk) => "text1", "correct column value";
  }

  {
    my $id = Groonga::API::obj_get_range($ctx, $column);
    is $id => GRN_DB_SHORT_TEXT, "correct range";
  }

  {
    my $value = Groonga::API::obj_get_value($ctx, $column, 1, undef);
    is Groonga::API::TEXT_VALUE($value) => "text1", "correct column value";
  }

  {
    my $new_value = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    Groonga::API::bulk_write($ctx, $new_value, "new_text1", bytes::length("new_text1"));
    my $rc = Groonga::API::obj_set_value($ctx, $column, 1, $new_value, GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "new text";
  }

  {
    my $value = Groonga::API::obj_get_value($ctx, $column, 1, undef);
    is Groonga::API::TEXT_VALUE($value) => "new_text1", "correct column value";
  }
});

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  my $rc = load_into_table($ctx, [
    {_key => 'key1', text => 'text1'},
    {_key => 'key2', text => 'text2'},
    {_key => 'key3', text => 'text3'},
  ]);
  is $rc => GRN_SUCCESS, "loaded";

  {
    my $new_key = "new_key1";
    $rc = Groonga::API::table_update_by_id($ctx, $table, 1, $new_key, bytes::length($new_key));

    my $buf = " " x 4096;
    my $len = Groonga::API::table_get_key($ctx, $table, 1, $buf, bytes::length($buf));
    my $key = $len ? substr($buf, 0, $len) : "";

    ok $len, "new key1 length: $len";
    is $key => "new_key1", "new key1: $key";
  }

  {
    my $src_key = "key1";
    my $dest_key = "new_key1";
    $rc = Groonga::API::table_update($ctx, $table, $src_key, bytes::length($src_key), $dest_key, bytes::length($dest_key));

    my $buf = " " x 4096;
    my $len = Groonga::API::table_get_key($ctx, $table, 1, $buf, bytes::length($buf));
    my $key = $len ? substr($buf, 0, $len) : "";

    ok $len, "new key1 length: $len";
    is $key => $dest_key, "new key1: $key";
  }


}, table_key => GRN_OBJ_PERSISTENT|GRN_TABLE_DAT_KEY);

done_testing;
