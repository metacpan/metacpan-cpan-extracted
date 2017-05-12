use strict;
use warnings;
use Groonga::API::Test;

db_test(sub { # builtin type
  my ($ctx, $db) = @_;

  my $type = Groonga::API::ctx_at($ctx, GRN_DB_SHORT_TEXT);
  ok defined $type, "defined type";
  is ref $type => "Groonga::API::obj", "correct object";
  ok $$type, "type pointer: $$type";

  my $header = $type->header;
  ok $header->{flags} & GRN_OBJ_KEY_VAR_SIZE, "short text is variable size";

  is Groonga::API::obj_id($ctx, $type) => GRN_DB_SHORT_TEXT, "correct object id";

  is Groonga::API::obj_is_builtin($ctx, $type) => GRN_TRUE, "builtin object";

  Groonga::API::obj_unlink($ctx, $type) if $type;
});

db_test(sub { # builtin type
  my ($ctx, $db) = @_;

  my $type = Groonga::API::ctx_at($ctx, GRN_DB_UINT32);
  ok defined $type, "defined type";
  is ref $type => "Groonga::API::obj", "correct object";
  ok $$type, "type pointer: $$type";

  my $header = $type->header;
  ok !($header->{flags} & GRN_OBJ_KEY_VAR_SIZE), "uint32 is fixed size";

  is Groonga::API::obj_id($ctx, $type) => GRN_DB_UINT32, "correct object id";

  is Groonga::API::obj_is_builtin($ctx, $type) => GRN_TRUE, "builtin object";


  Groonga::API::obj_unlink($ctx, $type) if $type;
});

db_test(sub { # new type
  my ($ctx, $db) = @_;

  my $name = "NewType";
  my $type = Groonga::API::type_create($ctx, $name, bytes::length($name), GRN_OBJ_KEY_VAR_SIZE, 2147483647);
  ok defined $type, "defined type";
  is ref $type => "Groonga::API::obj", "correct object";
  ok $$type, "type pointer: $$type";

  is Groonga::API::obj_is_builtin($ctx, $type) => GRN_FALSE, "not a builtin object";

  Groonga::API::obj_unlink($ctx, $type) if $type;
});

done_testing;
