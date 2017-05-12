use strict;
use warnings;
use Groonga::API::Test;

ctx_test(sub {
  my $ctx = shift;

  my $dbfile = tmpfile("test.db");
  my $db = Groonga::API::db_create($ctx, $dbfile, undef);
  ok defined $db, "created another db";
  is ref $db => "Groonga::API::obj", "correct object";
  my $pt = $$db;
  ok $pt, "db pointer: $pt";

  my $path = Groonga::API::obj_path($ctx, $db);
  is $path => "$dbfile", "correct path";

  Groonga::API::obj_close($ctx, $db);

  ok -f $dbfile, "dbfile exists";

  my $db_ = Groonga::API::db_open($ctx, $dbfile);
  ok defined $db_, "opened db";
  is ref $db_ => "Groonga::API::obj", "correct object";
  my $pt_ = $$db_;

  my $db_c = Groonga::API::ctx_db($ctx);
  ok defined $db_c, "context db";
  is ref $db_c => "Groonga::API::obj", "correct object";
  my $pt_c = $$db_c;
  is $pt_c => $pt_, "correct pointer";

  my $db2 = Groonga::API::db_create($ctx, undef, undef);
  ok defined $db2, "created temp db";
  is ref $db2 => "Groonga::API::obj", "correct object";
  my $pt2 = $$db2;
  ok $pt2, "db pointer: $pt2";

  my $rc = Groonga::API::ctx_use($ctx, $db2);
  is $rc => GRN_SUCCESS, "use temp db";

  $rc = Groonga::API::ctx_push($ctx, $db2);
  is $rc => GRN_SUCCESS, "pushed temp db";

  my $db2_ = Groonga::API::ctx_pop($ctx);
  ok defined $db2_, "popped temp db";
  is ref $db2_ => "Groonga::API::obj", "correct object";
  my $pt2_ = $$db2_;
  is $pt2 => $pt2_, "correct pointer";

  # no need to unlink db2_
  Groonga::API::obj_unlink($ctx, $db2) if $db2;
  Groonga::API::obj_unlink($ctx, $db_) if $db_;

  ok -f $dbfile, "dbfile still exists";

  {
    my $db = Groonga::API::db_open($ctx, $dbfile);
    ok defined $db, "opened";
    is ref $db => "Groonga::API::obj", "correct object";
    my $rc = Groonga::API::obj_remove($ctx, $db);
    is $rc => GRN_SUCCESS, "removed";
  }
  ok !-f $dbfile, "dbfile does not exist";
});

db_test(sub {
  my ($ctx, $db) = @_;

  {
    my $rc = Groonga::API::obj_lock($ctx, $db, GRN_ID_NIL, 0);
    is $rc => GRN_SUCCESS, "locked";
  }

  {
    ok Groonga::API::obj_is_locked($ctx, $db), "db is locked";
  }

  {
    my $rc = Groonga::API::obj_unlock($ctx, $db, GRN_ID_NIL);
    is $rc => GRN_SUCCESS, "unlocked";
  }

  {
    my $rc = Groonga::API::obj_lock($ctx, $db, GRN_ID_NIL, 0);
    is $rc => GRN_SUCCESS, "locked again";
  }

  {
    my $rc = Groonga::API::obj_clear_lock($ctx, $db);
    is $rc => GRN_SUCCESS, "cleared lock";
  }
});

done_testing;

# TODO: Groonga::API::obj_check()
# TODO: Groonga::API::obj_expire()
