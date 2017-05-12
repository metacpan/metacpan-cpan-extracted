use strict;
use warnings;
use Groonga::API::Test;

table_column_test(sub {
  my ($ctx, $db, $table, $column) = @_;

  load_into_table($ctx, [
    {"_key" => "text1", text => "foo"},
    {"_key" => "text2", text => "bar"},
  ]);

  Groonga::API::EXPR_CREATE_FOR_QUERY($ctx, $table, my $expr, my $var);
  ok defined $expr, "created expr";
  is ref $expr => "Groonga::API::obj", "correct object";

  ok defined $var, "created var";
  is ref $var => "Groonga::API::obj", "correct object";

  for my $query ('text:foo', '_id:1', '_key:text1'){
    my $rc = Groonga::API::expr_parse($ctx, $expr, $query, bytes::length($query), undef, GRN_OP_MATCH, GRN_OP_OR, GRN_EXPR_SYNTAX_QUERY | GRN_EXPR_ALLOW_COLUMN);
    is $rc => GRN_SUCCESS, "parsed $query";

    my $res = Groonga::API::table_select($ctx, $table, $expr, undef, GRN_OP_OR);
    ok $res, "selected";
    is ref $res => "Groonga::API::obj", "correct object";

    my $size = Groonga::API::table_size($ctx, $res);
    is $size => 1, "found an entry";

    Groonga::API::obj_unlink($ctx, $res) if $res;
  }

  Groonga::API::obj_unlink($ctx, $expr) if $expr;
  Groonga::API::obj_unlink($ctx, $var) if $var;
});

done_testing;
