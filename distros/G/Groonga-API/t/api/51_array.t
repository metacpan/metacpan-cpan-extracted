use strict;
use warnings;
use Groonga::API::Test;

ctx_test(sub {
  my $ctx = shift;

  my $path = tmpfile('test_array.db');
  {
    ok !-f $path, "not exists";

    my $value_size = 8; # XXX: arbitrary
    my $flags = 0;
    my $array = Groonga::API::array_create($ctx, $path, $value_size, $flags);
    ok defined $array, "created";
    ok -f $path, "exists";
    is ref $array => "Groonga::API::array", "correct object";

    my $rc = Groonga::API::array_close($ctx, $array);
    is $rc => GRN_SUCCESS, "closed";
  }

  {
    my $array = Groonga::API::array_open($ctx, $path);
    ok defined $array, "opened";
    is ref $array => "Groonga::API::array", "correct object";

    my $rc = Groonga::API::array_close($ctx, $array);
    is $rc => GRN_SUCCESS, "closed";
  }
});

table_test(sub {
  my ($ctx, $db, $array) = @_;

  for my $ct (1..4) {
    my $id = Groonga::API::array_add($ctx, $array, my $value);
    ok $id, "added id: $id";
  }

  {
    my $value = 10;
    my $rc = Groonga::API::array_set_value($ctx, $array, 1, pack('L', $value), GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "set";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::array_get_value($ctx, $array, 1, $buf);
    ok $len, "length: $len";
    is unpack('L', substr($buf, 0, $len)) => $value, "correct value";
  }

  {
    my $id = Groonga::API::array_next($ctx, $array, 1);
    is $id => 2, "correct id";
  }

  {
    my $rc = Groonga::API::array_delete_by_id($ctx, $array, 4, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  # array_cursor
  my $cursor = Groonga::API::array_cursor_open($ctx, $array, 0, 0, 0, 10, GRN_CURSOR_ASCENDING);
  ok defined $cursor, "opened";
  is ref $cursor, "Groonga::API::array_cursor", "correct object";

  {
    my $id = Groonga::API::array_cursor_next($ctx, $cursor);
    is $id => 1, "correct id";
  }

  {
    my $value = 100;
    my $rc = Groonga::API::array_cursor_set_value($ctx, $cursor, pack('L', $value), GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "set";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::array_cursor_get_value($ctx, $cursor, $buf);
    ok $len, "length: $len";
    is unpack('L', substr($buf, 0, $len)) => $value, "correct value";
  }

  {
    my $rc = Groonga::API::array_cursor_delete($ctx, $cursor, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  Groonga::API::array_cursor_close($ctx, $cursor);
}, table_key => GRN_OBJ_PERSISTENT|GRN_TABLE_NO_KEY);

done_testing;
