use strict;
use warnings;
use Groonga::API qw/:all/;
use Groonga::API::Test;

db_test(sub {
  my ($ctx, $db) = @_;
  my $command = "status";
  my $ret = ctx_send($ctx, $command, bytes::length($command), 0);
  is $ret => GRN_SUCCESS, "sent status";

  if (get_major_version() > 1) {
    my $ctype = ctx_get_mime_type($ctx);
    is $ctype => "application/json", "content type";
  }

  $ret = ctx_recv($ctx, my $result, my $len, my $flags);  is $ret => GRN_SUCCESS, "received status";
  ok $result, "status: $result";
  ok $len, "result length: $len";
  note "flags: $flags";
});

# TODO: ctx_connect() support

done_testing;
