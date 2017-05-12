use strict;
use warnings;
use Groonga::API::Test;
use utf8;

# cf. http://www.clear-code.com/blog/2011/9/13.html

db_test(sub {
  my ($ctx, $db) = @_;

  my $table = Groonga::API::table_create($ctx, "Shops", bytes::length("Shops"), undef, GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_HASH_KEY, Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT), undef);
  ok defined $table, "Shops table";

  my $column = Groonga::API::column_create($ctx, $table, "location", bytes::length("location"), undef, GRN_OBJ_PERSISTENT|GRN_OBJ_COLUMN_SCALAR, Groonga::API::ctx_at($ctx, GRN_DB_WGS84_GEO_POINT));
  ok defined $column, "location column";

  is load_into_table($ctx, [
    {_key => "根津のたいやき", location => "35.720253,139.762573"},
    {_key => "たい焼 カタオカ", location => "35.712521,139.715591"},
    {_key => "たい焼き写楽", location => "35.716969,139.794846"},
    {_key => "横浜 くりこ庵 浅草店", location => "35.712013,139.796829"},
  ], table_name => "Shops") => GRN_SUCCESS, "loaded";
  is Groonga::API::table_size($ctx, $table) => 4, "correct size";

  my $index_table = Groonga::API::table_create($ctx, "Locations", bytes::length("Locations"), undef, GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_PAT_KEY, Groonga::API::ctx_at($ctx, GRN_DB_WGS84_GEO_POINT), undef);
  ok defined $index_table, "Locations table";

  my $index_column = Groonga::API::column_create($ctx, $index_table, "shop", bytes::length("shop"), undef, GRN_OBJ_PERSISTENT|GRN_OBJ_COLUMN_INDEX, $table);
  ok defined $index_column, "index column";

  my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_UINT32);
  my $source_id = pack 'L', Groonga::API::obj_id($ctx, $column);
  Groonga::API::bulk_write($ctx, $bulk, $source_id, bytes::length($source_id));
  my $rc = Groonga::API::obj_set_info($ctx, $index_column, GRN_INFO_SOURCE, $bulk);
  is $rc => GRN_SUCCESS, "set source";

  {
    my $top_left = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    my $top_left_coord = "35.7185,139.7912";
    Groonga::API::bulk_write($ctx, $top_left, $top_left_coord, bytes::length($top_left_coord));
    my $bottom_right = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    my $bottom_right_coord = "35.7065,139.8069";
    Groonga::API::bulk_write($ctx, $bottom_right, $bottom_right_coord, bytes::length($bottom_right_coord));

    my $res = Groonga::API::table_create($ctx, undef, 0, undef, GRN_OBJ_TABLE_HASH_KEY, Groonga::API::ctx_at($ctx, GRN_DB_WGS84_GEO_POINT), undef);

    my $num = Groonga::API::geo_estimate_in_rectangle($ctx, $index_column, $top_left, $bottom_right);
    ok $num > 0, "estimated: $num";

    my $rc = Groonga::API::geo_select_in_rectangle($ctx, $index_column, $top_left, $bottom_right, $res, GRN_OP_OR);
    is $rc => GRN_SUCCESS, "select in rectangle";

    is Groonga::API::table_size($ctx, $res) => 2, "correct size";

    my $cursor = Groonga::API::table_cursor_open($ctx, $res, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);
    my @found;
    while(my $id = Groonga::API::table_cursor_next($ctx, $cursor)) {
      my $key = ' ' x 4096;
      my $len = Groonga::API::table_cursor_get_key($ctx, $cursor, $key);
      my $tid = unpack 'L', substr($key, 0, $len);
      push @found, $tid;

      my $buf = ' ' x 4096;
      $len = Groonga::API::table_get_key($ctx, $table, $tid, $buf, bytes::length($buf));
      note "$tid: ".substr($buf, 0, $len);
    }
    is_deeply [sort @found] => [3, 4], "selected correctly";
    Groonga::API::table_cursor_close($ctx, $cursor);
    Groonga::API::obj_unlink($ctx, $res);

    my $geo_cursor = Groonga::API::geo_cursor_open_in_rectangle($ctx, $index_column, $top_left, $bottom_right, 0, 100);
    ok defined $geo_cursor, "geo cursor";
    is ref $geo_cursor => "Groonga::API::obj", "correct object";
    while(my $posting = Groonga::API::geo_cursor_next($ctx, $geo_cursor)) {
      my ($rid, $sid) = ($posting->rid, $posting->sid);
      note "rid: $rid, sid: $sid";
    }
    Groonga::API::obj_unlink($ctx, $geo_cursor);
  }

  Groonga::API::obj_unlink($ctx, $index_column);
  Groonga::API::obj_unlink($ctx, $index_table);

  Groonga::API::obj_unlink($ctx, $column);
  Groonga::API::obj_unlink($ctx, $table);
});

done_testing;
