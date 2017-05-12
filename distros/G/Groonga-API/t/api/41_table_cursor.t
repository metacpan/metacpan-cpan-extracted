use strict;
use warnings;
use Groonga::API::Test;

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  my $epoch = time;

  my $rc = load_into_table($ctx, [
    {_key => 'key1', _value => $epoch, text => 'text1'},
    {_key => 'key2', _value => $epoch, text => 'text2'},
    {_key => 'key3', _value => $epoch, text => 'text3'},
  ]);
  is $rc => GRN_SUCCESS;

  my $cursor = Groonga::API::table_cursor_open($ctx, $table, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);
  ok defined $cursor, "opened a table cursor";
  is ref $cursor => "Groonga::API::table_cursor", "correct object";

  {
    my $id = Groonga::API::table_cursor_next($ctx, $cursor);
    isnt $id => GRN_ID_NIL, "next id is not null";
    note "ID: $id";
  }

  {
    my $len = Groonga::API::table_cursor_get_key($ctx, $cursor, my $key);
    is $len => 4, "key length: $len";
    is substr($key, 0, $len) => "key1", "got a key: $key";
  }

  {
    my $len = Groonga::API::table_cursor_get_value($ctx, $cursor, my $value);
    ok $len, "key length: $len";
    my $packed = substr($value, 0, $len);
    my $unpacked = unpack("L", $packed); # this conversion naturally depends on the value_type definition
    is $unpacked => $epoch, "got a value: $unpacked";
  }

  {
    my $new_value = $epoch + 100;
    my $packed = pack("L", $new_value); # needs to pack beforehand
    my $rc = Groonga::API::table_cursor_set_value($ctx, $cursor, $packed, GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "set an value";
  }

  {
    my $len = Groonga::API::table_cursor_get_value($ctx, $cursor, my $value);
    ok $len, "key length: $len";
    my $packed = substr($value, 0, $len);
    my $unpacked = unpack("L", $packed); # this conversion naturally depends on the value_type definition
    is $unpacked => $epoch + 100, "got a value: $unpacked";
  }

  {
    my $rc = Groonga::API::table_cursor_delete($ctx, $cursor);
    is $rc => GRN_SUCCESS, "removed the current record";
  }

  {
    my $table_ = Groonga::API::table_cursor_table($ctx, $cursor);
    ok defined $table_, "defined table";
    is $$table_ => $$table, "same pointer";
  }

  {
    my $rc = Groonga::API::table_cursor_close($ctx, $cursor);
    is $rc => GRN_SUCCESS, "closed the cursor";
  }
});

done_testing;
