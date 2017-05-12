use strict;
use warnings;
use Groonga::API::Test;

ctx_test(sub {
  my $ctx = shift;

  my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
  ok defined $bulk, "created a bulk";
  is ref $bulk => "Groonga::API::obj", "correct object";

  {
    my $str = "text";
    my $rc = Groonga::API::bulk_write($ctx, $bulk, $str, bytes::length($str));
    is $rc => GRN_SUCCESS, "written";
    is substr(Groonga::API::TEXT_VALUE($bulk), 0, Groonga::API::TEXT_LEN($bulk)) => $str, "written correctly";
  }

  {
    my $rc = Groonga::API::bulk_resize($ctx, $bulk, 10);
    is $rc => GRN_SUCCESS, "resized";
    note explain $bulk->ub;
  }

  {
    my $rc = Groonga::API::bulk_reinit($ctx, $bulk, 12);
    is $rc => GRN_SUCCESS, "reinitialized";
    note explain $bulk->ub;
  }

  {
    my $rc = Groonga::API::bulk_reserve($ctx, $bulk, 10);
    is $rc => GRN_SUCCESS, "reserved";
    note explain $bulk->ub;
  }

  {
    my $rc = Groonga::API::bulk_space($ctx, $bulk, 3);
    is $rc => GRN_SUCCESS, "spaced";
    note explain $bulk->ub;
  }

  {
    my $rc = Groonga::API::bulk_truncate($ctx, $bulk, 2);
    is $rc => GRN_SUCCESS, "truncated";
    note explain $bulk->ub;
  }

  {
    my $str = "new_text";
    my $rc = Groonga::API::bulk_write_from($ctx, $bulk, $str, 2, bytes::length($str));
    is $rc => GRN_SUCCESS, "written";
    is substr(Groonga::API::TEXT_VALUE($bulk), 0, Groonga::API::TEXT_LEN($bulk)) => "tenew_text", "written correctly";
    note explain $bulk->ub;
  }

  {
    my $rc = Groonga::API::obj_reinit($ctx, $bulk, GRN_DB_UINT32, 0);
    is $rc => GRN_SUCCESS, "reinit";
    is $bulk->header->{domain} => GRN_DB_UINT32, "correct domain";
  }

  Groonga::API::bulk_fin($ctx, $bulk);
  Groonga::API::obj_unlink($ctx, $bulk);
});

ctx_test(sub {
  my $ctx = shift;

  my $text = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
  ok defined $text, "created a text";
  is ref $text => "Groonga::API::obj", "correct object";

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_itoa($ctx, $text, 10);
    is $rc => GRN_SUCCESS, "itoa";
    is substr(Groonga::API::TEXT_VALUE($text), 0, Groonga::API::TEXT_LEN($text)) => '10';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_itoa_padded($ctx, $text, 10, ' ', 5);
    is $rc => GRN_SUCCESS, "itoa_padded";
    is $text->ub->{head} => '   10';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  { # XXX: use a larger number (better use Math::BigInt?)
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_lltoa($ctx, $text, 100000000);
    is $rc => GRN_SUCCESS, "lltoa";
    is $text->ub->{head} => '100000000';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_ftoa($ctx, $text, 1.5);
    is $rc => GRN_SUCCESS, "ftoa";
    is substr($text->ub->{head}, 0, 3) => '1.5';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_itoh($ctx, $text, 255, 2);
    is $rc => GRN_SUCCESS, "itoh";
    is $text->ub->{head} => 'FF';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_itob($ctx, $text, GRN_DB_SHORT_TEXT);
    is $rc => GRN_SUCCESS, "itob";
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_lltob32h($ctx, $text, 10000);
    is $rc => GRN_SUCCESS, "lltob32h";
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_benc($ctx, $text, 97);
    is $rc => GRN_SUCCESS, "benc";
    is $text->ub->{head} => 'a';
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $str = "['\\]";
    my $rc = Groonga::API::text_esc($ctx, $text, $str, bytes::length($str));
    is $rc => GRN_SUCCESS, "esc";
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $str = "http://foo.bar/?foo=bar";
    my $rc = Groonga::API::text_urlenc($ctx, $text, $str, bytes::length($str));
    is $rc => GRN_SUCCESS, "urlenc";

    is substr(Groonga::API::TEXT_VALUE($text), 0, Groonga::API::TEXT_LEN($text)) => "http%3A%2F%2Ffoo.bar%2F%3Ffoo%3Dbar";
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $str = q{<xml><foo bar="<baz>"></foo></xml>};
    my $rc = Groonga::API::text_escape_xml($ctx, $text, $str, bytes::length($str));
    is $rc => GRN_SUCCESS, "escape_xml";

    is substr(Groonga::API::TEXT_VALUE($text), 0, Groonga::API::TEXT_LEN($text)) => "&lt;xml&gt;&lt;foo bar=&quot;&lt;baz&gt;&quot;&gt;&lt;/foo&gt;&lt;/xml&gt;";
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  {
    Groonga::API::bulk_reinit($ctx, $text, 0);
    my $rc = Groonga::API::text_time2rfc1123($ctx, $text, time);
    is $rc => GRN_SUCCESS, "time2rfc1123";
    like substr(Groonga::API::TEXT_VALUE($text), 0, Groonga::API::TEXT_LEN($text)) => qr/^\w{3}, \d{1,2} \w{3} \d{4} \d{2}:\d{2}:\d{2}/;

    # TODO: hmm, needs to clear more explicitly?
    note explain $text->ub;
    Groonga::API::bulk_fin($ctx, $text);
  }

  Groonga::API::obj_unlink($ctx, $text);
});

# XXX: Groonga::API::text_urldec()

done_testing;
