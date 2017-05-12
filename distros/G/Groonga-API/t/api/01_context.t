use strict;
use warnings;
use Groonga::API::Test;

grn_test(sub { # open/close
  my $ctx = Groonga::API::ctx_open(GRN_CTX_USE_QL);
  ok defined $ctx, "opened context";
  is ref $ctx => "Groonga::API::ctx", "proper class";
  ok $$ctx, "context has some address: $$ctx";

  if (Groonga::API::get_major_version() > 1) {
    my $rc = Groonga::API::ctx_close($ctx);
    is $rc => GRN_SUCCESS, "closed context";
  } else {
    my $rc = Groonga::API::ctx_fin($ctx);
    is $rc => GRN_SUCCESS, "closed context";
  }
});

grn_test(sub { # init/fin
  my $rc = Groonga::API::ctx_init(my $ctx, GRN_CTX_USE_QL);
  is $rc => GRN_SUCCESS, "initialized context";
  ok defined $ctx, "defined context";
  is ref $ctx => "Groonga::API::ctx", "proper class";
  ok $$ctx, "context has some address: $$ctx";

  $rc = Groonga::API::ctx_fin($ctx);
  is $rc => GRN_SUCCESS, "finalized context";
});

done_testing;
