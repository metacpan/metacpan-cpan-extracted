use strict;
use warnings;
use Groonga::API::Test;

table_test(sub {
  my ($ctx, $db, $table) = @_;

  my $name = "my_col";
  my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
  ok defined $type, "type is defined";

  my $column = Groonga::API::column_create($ctx, $table, $name, bytes::length($name), undef, GRN_OBJ_PERSISTENT, $type);
  ok defined $column, "created column";
  is ref $column => "Groonga::API::obj", "correct object";

  my $buf = " " x 4096;
  my $len = Groonga::API::column_name($ctx, $column, $buf, bytes::length($buf));
  is $len => bytes::length($name), "length: $len";
  is substr($buf, 0, $len) => $name, "correct name";

  my $table_ = Groonga::API::column_table($ctx, $column);
  ok defined $table_, "found column table";
  is $$table_ => $$table, "correct pointer";

  if (Groonga::API::get_major_version() > 1) {
    my $new_name = "my_new_col";
    my $rc = Groonga::API::column_rename($ctx, $column, $new_name, bytes::length($new_name));
    is $rc => GRN_SUCCESS, "renamed column";

    my $new_len = Groonga::API::column_name($ctx, $column, $buf, bytes::length($buf));
    is $new_len => bytes::length($new_name), "length: $new_len";
    is substr($buf, 0, $new_len) => $new_name, "correct new name";

    my $column_ = Groonga::API::obj_column($ctx, $table, $new_name, bytes::length($new_name));
    ok defined $column_, "found obj column";
    is $$column_ => $$column, "same pointer";

    Groonga::API::obj_unlink($ctx, $column_) if $column_;
  }

  Groonga::API::obj_unlink($ctx, $column) if $column;
});

done_testing;
