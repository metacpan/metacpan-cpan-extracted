use strict;
use warnings;
use Groonga::API::Test;

db_test(sub {
  my ($ctx, $db) = @_;

  my $name = "my_table";
  my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
  ok defined $type, "type is defined";
  my $table = Groonga::API::table_create($ctx, $name, bytes::length($name), undef, GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_HASH_KEY, $type, undef);
  ok defined $table, "created table";
  is ref $table => "Groonga::API::obj", "correct object";
  my $pt = $$table;
  ok $pt, "pointer: $pt";

  my $table_ = Groonga::API::ctx_get($ctx, $name, bytes::length($name));
  ok defined $table_, "got table";
  is ref $table_ => "Groonga::API::obj", "correct object";
  my $pt_ = $$table_;
  ok $pt_, "pointer: $pt_";
  is $pt_ => $pt, "same pointer";

  if (Groonga::API::get_major_version() > 1) {
    my $new_name = "my_new_table";
    my $rc = Groonga::API::table_rename($ctx, $table, $new_name, bytes::length($new_name));
    is $rc => GRN_SUCCESS, "renamed";
  }

  if (Groonga::API::get_major_version() > 1) {
    my $new_name = "my_newest_table";
    my $rc = Groonga::API::obj_rename($ctx, $table, $new_name, bytes::length($new_name));
    is $rc => GRN_SUCCESS, "renamed";
  }

  Groonga::API::obj_unlink($ctx, $table_) if $table_;
  Groonga::API::obj_unlink($ctx, $table) if $table;
});

done_testing;
