use strict;
use warnings;
use Groonga::API::Test;
use Test::Differences;

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  my $rc = load_into_table($ctx, [
    {_key => 'key1', text => 'text1'},
    {_key => 'key2', text => 'text2'},
    {_key => 'key3', text => 'text3'},
  ]);
  is $rc => GRN_SUCCESS, "loaded";

  my $array = Groonga::API::table_create($ctx, undef, 0, undef, GRN_OBJ_TABLE_NO_KEY, undef, Groonga::API::ctx_at($ctx, GRN_DB_UINT32));
  ok defined $array, "created an array";
  is ref $array => "Groonga::API::obj", "correct object";

  my $sort_key_str = "-_id";
  my $sort_keys = Groonga::API::table_sort_key_from_str($ctx, $sort_key_str, bytes::length($sort_key_str), $table, my $num_of_keys);
  ok defined $sort_keys, "sort key";
  is ref $sort_keys => "Groonga::API::table_sort_key", "correct object";
  is $num_of_keys => 1, "correct num of keys";

  my $num = Groonga::API::table_sort($ctx, $table, 0, 3, $array, $sort_keys, $num_of_keys);
  ok $num, "sorted: $num";

  my $size = Groonga::API::table_size($ctx, $array);
  ok $size, "sorted size: $size";

  my $cursor = Groonga::API::table_cursor_open($ctx, $array, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);
  my @sorted;
  while(my $id = Groonga::API::table_cursor_next($ctx, $cursor)) {
    my $len = Groonga::API::table_cursor_get_value($ctx, $cursor, my $value);
    my $org_id = unpack 'L', substr($value, 0, $len);

    my $buf = ' ' x 4096;
    $len = Groonga::API::table_get_key($ctx, $table, $org_id, $buf, bytes::length($buf));
    push @sorted, substr($buf, 0, $len);
  }
  eq_or_diff \@sorted, [qw/key3 key2 key1/], "sorted correctly";

  $rc = Groonga::API::table_cursor_close($ctx, $cursor);
  is $rc => GRN_SUCCESS, "closed";

  Groonga::API::table_sort_key_close($ctx, $sort_keys, $num_of_keys);
  Groonga::API::obj_unlink($ctx, $array);
});

done_testing;
