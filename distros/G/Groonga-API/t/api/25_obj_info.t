use strict;
use warnings;
use Groonga::API::Test;

table_test(sub {
  my ($ctx, $db, $table) = @_;

  for my $type (GRN_INFO_SUPPORT_ZLIB, GRN_INFO_SUPPORT_LZO) {
    my $ret = Groonga::API::obj_get_info($ctx, undef, $type, undef);
    ok defined $ret, "got info: $type";
    is ref $ret => "Groonga::API::obj";
    Groonga::API::obj_unlink($ctx, $ret);
  }

  {
    my $type = GRN_INFO_SOURCE;
    my $ret = Groonga::API::obj_get_info($ctx, $db, $type, undef);
    ok defined $ret, "got info: $type";
    is ref $ret => "Groonga::API::obj";
    Groonga::API::obj_unlink($ctx, $ret);
  }

  {
    my $type = GRN_INFO_ENCODING;
    my $ret = Groonga::API::obj_get_info($ctx, $table, $type, undef);
    ok defined $ret, "got info: $type";
    is ref $ret => "Groonga::API::obj";
    note unpack 'L', $ret->ub->{head};
    Groonga::API::obj_unlink($ctx, $ret);
  }

  {
    my $type = GRN_INFO_DEFAULT_TOKENIZER;
    my $tokenizer = Groonga::API::ctx_at($ctx, GRN_DB_BIGRAM);
    my $rc = Groonga::API::obj_set_info($ctx, $table, $type, $tokenizer);
    is $rc => GRN_SUCCESS, "set tokenizer";

    my $ret = Groonga::API::obj_get_info($ctx, $table, $type, undef);
    ok defined $ret, "got info: $type";
    is ref $ret => "Groonga::API::obj";
    Groonga::API::obj_unlink($ctx, $tokenizer);
    Groonga::API::obj_unlink($ctx, $ret);
  }

  {
    my $type = GRN_INFO_NORMALIZER;

    # XXX: GRN_NORMALIZER_AUTO_NAME is not public yet.
    my $normalizer = Groonga::API::ctx_get($ctx, "NormalizerAuto", -1);
    my $rc = Groonga::API::obj_set_info($ctx, $table, $type, $normalizer);
    is $rc => GRN_SUCCESS, "set normalizer";

    my $ret = Groonga::API::obj_get_info($ctx, $table, $type, undef);
    ok defined $ret, "got info: $type";
    is ref $ret => "Groonga::API::obj";
    Groonga::API::obj_unlink($ctx, $normalizer);
    Groonga::API::obj_unlink($ctx, $ret);
  }
});

# TODO: Groonga::API::obj_get_element_info()
# TODO: Groonga::API::obj_set_element_info()

done_testing;
