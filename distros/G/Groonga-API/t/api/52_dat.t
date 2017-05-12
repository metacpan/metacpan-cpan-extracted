use strict;
use warnings;
use Groonga::API::Test;

ctx_test(sub {
  my $ctx = shift;

  my $path = tmpfile('test_dat.db');
  {
    ok !-f $path, "not exists";

    my $key_size = my $value_size = 8; # XXX: arbitrary
    my $flags = 0;
    my $dat = Groonga::API::dat_create($ctx, $path, $key_size, $value_size, $flags);
    ok defined $dat, "created";
    ok -f $path, "exists";
    is ref $dat => "Groonga::API::dat", "correct object";

    my $rc = Groonga::API::dat_close($ctx, $dat);
    is $rc => GRN_SUCCESS, "closed";
  }

  {
    my $dat = Groonga::API::dat_open($ctx, $path);
    ok defined $dat, "opened";
    is ref $dat => "Groonga::API::dat", "correct object";

    my $rc = Groonga::API::dat_close($ctx, $dat);
    is $rc => GRN_SUCCESS, "closed";
  }

  {
    ok -f $path, "exists";
    my $rc = Groonga::API::dat_remove($ctx, $path);
    is $rc => GRN_SUCCESS, "removed";
    ok !-f $path, "no more exists";
  }
});

table_test(sub {
  my ($ctx, $db, $dat) = @_;

  for my $ct (1..4) {
    my $key = "key$ct";
    my $id = Groonga::API::dat_add($ctx, $dat, $key, bytes::length($key), undef, my $added);
    ok $id, "added id: $id";
    ok $added, "flag";
  }

  {
    my $size = Groonga::API::dat_size($ctx, $dat);
    is $size => 4, "correct size";
  }

  {
    my $key = "key1";
    my $id = Groonga::API::dat_get($ctx, $dat, $key, bytes::length($key), my $value);
    is $id => 1, "got $id";
  }

  {
    my $buf = ' ' x 4096;
    my $len = Groonga::API::dat_get_key($ctx, $dat, 1, $buf, bytes::length($buf));
    ok $len, "key length: $len";
    is substr($buf, 0, $len) => "key1", "correct key";
  }

  {
    my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    my $len = Groonga::API::dat_get_key2($ctx, $dat, 1, $bulk);
    ok $len, "key length: $len";
    is substr(Groonga::API::TEXT_VALUE($bulk) || '', 0, $len) => "key1", "correct key";
    Groonga::API::bulk_fin($ctx, $bulk);
    Groonga::API::obj_unlink($ctx, $bulk);
  }

  {
    my $rc = Groonga::API::dat_delete_by_id($ctx, $dat, 4, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  {
    my $key = "key3";
    my $rc = Groonga::API::dat_delete($ctx, $dat, $key, bytes::length($key), undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  {
    my $new_key = "new_key2";
    my $rc = Groonga::API::dat_update_by_id($ctx, $dat, 2, $new_key, bytes::length($new_key));
    is $rc => GRN_SUCCESS, "updated";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::dat_get_key($ctx, $dat, 2, $buf, bytes::length($buf));
    ok $len, "key length: $len";
    is substr($buf, 0, $len) => "new_key2", "correct key";
  }

  {
    my $old_key = "new_key2";
    my $new_key = "updated_key2";
    my $rc = Groonga::API::dat_update($ctx, $dat, $old_key, bytes::length($old_key), $new_key, bytes::length($new_key));
    is $rc => GRN_SUCCESS, "updated";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::dat_get_key($ctx, $dat, 2, $buf, bytes::length($buf));
    ok $len, "key length: $len";
    is substr($buf, 0, $len) => "updated_key2", "correct key";
  }

  # dat_cursor
  my $cursor = Groonga::API::dat_cursor_open($ctx, $dat, undef, 0, undef, 0, 0, 10, GRN_CURSOR_ASCENDING);
  ok defined $cursor, "opened";
  is ref $cursor, "Groonga::API::dat_cursor", "correct object";

  {
    my $id = Groonga::API::dat_cursor_next($ctx, $cursor);
    is $id => 1, "correct id";
  }

  {
    my $buf = ' ' x 4096;
    my $len = Groonga::API::dat_cursor_get_key($ctx, $cursor, $buf);
    ok $len, "length: $len";
    is substr($buf, 0, $len) => "key1", "correct key";
  }

  {
    my $rc = Groonga::API::dat_cursor_delete($ctx, $cursor, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  Groonga::API::dat_cursor_close($ctx, $cursor);
}, table_key => GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_DAT_KEY);

done_testing;
