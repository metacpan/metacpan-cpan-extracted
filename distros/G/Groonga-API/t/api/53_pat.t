use strict;
use warnings;
use Groonga::API::Test;
use Encode;

ctx_test(sub {
  my $ctx = shift;

  my $path = tmpfile('test_pat.db');
  {
    ok !-f $path, "not exists";

    my $key_size = my $value_size = 8; # XXX: arbitrary
    my $flags = 0;
    my $pat = Groonga::API::pat_create($ctx, $path, $key_size, $value_size, $flags);
    ok defined $pat, "created";
    ok -f $path, "exists";
    is ref $pat => "Groonga::API::pat", "correct object";

    my $rc = Groonga::API::pat_close($ctx, $pat);
    is $rc => GRN_SUCCESS, "closed";
  }

  {
    my $pat = Groonga::API::pat_open($ctx, $path);
    ok defined $pat, "opened";
    is ref $pat => "Groonga::API::pat", "correct object";

    my $rc = Groonga::API::pat_close($ctx, $pat);
    is $rc => GRN_SUCCESS, "closed";
  }

  {
    ok -f $path, "exists";
    my $rc = Groonga::API::pat_remove($ctx, $path);
    is $rc => GRN_SUCCESS, "removed";
    ok !-f $path, "no more exists";
  }
});

table_test(sub {
  my ($ctx, $db, $pat) = @_;

  for my $ct (1..4) {
    my $key = "key$ct";
    my $id = Groonga::API::pat_add($ctx, $pat, $key, bytes::length($key), my $value, my $added);
    ok $id, "added id: $id";
    ok $added, "flag";
  }

  {
    my $size = Groonga::API::pat_size($ctx, $pat);
    is $size => 4, "correct size";
  }

  {
    my $key = "key1";
    my $id = Groonga::API::pat_get($ctx, $pat, $key, bytes::length($key), my $value);
    is $id => 1, "got $id";
  }

  {
    my $buf = ' ' x 4096;
    my $len = Groonga::API::pat_get_key($ctx, $pat, 1, $buf, bytes::length($buf));
    ok $len, "key length: $len";
    is substr($buf, 0, $len) => "key1", "correct key";
  }

  {
    my $bulk = Groonga::API::obj_open($ctx, GRN_BULK, 0, GRN_DB_TEXT);
    my $len = Groonga::API::pat_get_key2($ctx, $pat, 1, $bulk);
    ok $len, "key length: $len";
    is substr(Groonga::API::TEXT_VALUE($bulk) || '', 0, $len) => "key1", "correct key";
    Groonga::API::bulk_fin($ctx, $bulk);
    Groonga::API::obj_unlink($ctx, $bulk);
  }

  {
    my $value = 10;
    my $rc = Groonga::API::pat_set_value($ctx, $pat, 1, pack('L', $value), GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "set";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::pat_get_value($ctx, $pat, 1, $buf);
    ok $len, "length: $len";
    is unpack('L', substr($buf, 0, $len)) => $value, "correct value";
  }

  {
    my $rc = Groonga::API::pat_delete_by_id($ctx, $pat, 4, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  {
    my $key = "key3";
    my $rc = Groonga::API::pat_delete($ctx, $pat, $key, bytes::length($key), undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  # pat_cursor
  my $cursor = Groonga::API::pat_cursor_open($ctx, $pat, undef, 0, undef, 0, 0, 10, GRN_CURSOR_ASCENDING);
  ok defined $cursor, "opened";
  is ref $cursor, "Groonga::API::pat_cursor", "correct object";

  {
    my $id = Groonga::API::pat_cursor_next($ctx, $cursor);
    is $id => 1, "correct id";
  }

  {
    my $buf = ' ' x 4096;
    my $len = Groonga::API::pat_cursor_get_key($ctx, $cursor, $buf);
    ok $len, "length: $len";
    is substr($buf, 0, $len) => "key1", "correct key";
  }

  {
    my $value = 100;
    my $rc = Groonga::API::pat_cursor_set_value($ctx, $cursor, pack('L', $value), GRN_OBJ_SET);
    is $rc => GRN_SUCCESS, "set";

    my $buf = ' ' x 4096;
    my $len = Groonga::API::pat_cursor_get_value($ctx, $cursor, $buf);
    ok $len, "length: $len";
    is unpack('L', substr($buf, 0, $len)) => $value, "correct value";
  }

  {
    my $key_buf = ' ' x 4096;
    my $value_buf = ' ' x 4096;
    my $value_len = Groonga::API::pat_cursor_get_key_value($ctx, $cursor, $key_buf, my $key_len, $value_buf);
    ok $key_len, "key length: $key_len";
    ok $value_len, "value length: $value_len";
    is substr($key_buf, 0, $key_len) => "key1", "correct key";
    is unpack('L', substr($value_buf, 0, $value_len)) => 100, "correct value";
  }

  {
    my $rc = Groonga::API::pat_cursor_delete($ctx, $cursor, undef);
    is $rc => GRN_SUCCESS, "deleted";
  }

  Groonga::API::pat_cursor_close($ctx, $cursor);
}, table_key => GRN_OBJ_PERSISTENT|GRN_OBJ_TABLE_PAT_KEY);

ctx_test(sub {
  my $ctx = shift;

  my @keys = (
    "セナ",
    "ナセナセ",
    "Groonga",
    "セナ + Ruby",
    "セナセナ",
  );

  my $key_size = 100;
  my $pat = Groonga::API::pat_create($ctx, undef, $key_size, 0, GRN_OBJ_KEY_VAR_SIZE|GRN_OBJ_KEY_WITH_SIS);
  ok defined $pat, "created";
  is ref $pat => "Groonga::API::pat", "correct object";

  for my $key (@keys) {
    my $id = Groonga::API::pat_add($ctx, $pat, $key, bytes::length($key), my $value, my $added);
    ok $id, "added $id";
  }

  my $key = "セ";
  my $id = Groonga::API::pat_lcp_search($ctx, $pat, $key, bytes::length($key));
  ok $id, "found $id";

  my $buf = ' ' x $key_size;
  my $len = Groonga::API::pat_get_key($ctx, $pat, $id, $buf, $key_size);
  is substr($buf, 0, $len) => "セ", "correct key";

  Groonga::API::pat_delete_with_sis($ctx, $pat, $id, undef);

  Groonga::API::pat_close($ctx, $pat);
});

ctx_test(sub {
  my $ctx = shift;

  # borrowed from groonga's unit test
  note "prefix search";
  _pat_search_test($ctx, \&Groonga::API::pat_prefix_search, (
    ["default - nonexistence", 0,
      "カッター", GRN_END_OF_DATA, [],
    ],
    ["default - short", 0,
      "セ", GRN_SUCCESS,
      ["セナ", "セナ + Ruby", "セナセナ"],
    ],
    ["default - exact", 0,
      "セナ", GRN_SUCCESS,
      ["セナ", "セナ + Ruby", "セナセナ"], 
    ],
    ["default - long", 0,
      "セナセナセナ", GRN_END_OF_DATA, [],
    ],
    ["sis - nonexistence", GRN_OBJ_KEY_WITH_SIS,
      "カッター", GRN_END_OF_DATA, [],
    ],
    ["sis - short", GRN_OBJ_KEY_WITH_SIS,
      "セ", GRN_SUCCESS,
      ["セ", "セナ", "セナ + Ruby", "セナセ", "セナセナ"],
    ],
    ["sis - exact", GRN_OBJ_KEY_WITH_SIS,
      "セナ", GRN_SUCCESS,
      ["セナ", "セナ + Ruby", "セナセ", "セナセナ"],
    ],
    ["sis - long", GRN_OBJ_KEY_WITH_SIS,
      "セナセナセナ", GRN_END_OF_DATA, [],
    ],
  ));

  note "suffix search";
  _pat_search_test($ctx, \&Groonga::API::pat_suffix_search, (
    ["default - nonexistence", 0,
      "カッター", GRN_END_OF_DATA, [],
    ],
    ["default - short", 0,
      "ナ", GRN_END_OF_DATA, [],
    ],
    ["default - exact", 0,
      "セナ", GRN_SUCCESS,
      ["セナ"], 
    ],
    ["default - long", 0,
      "セナセナセナ", GRN_END_OF_DATA, [],
    ],
    ["sis - nonexistence", GRN_OBJ_KEY_WITH_SIS,
      "カッター", GRN_END_OF_DATA, [],
    ],
    ["sis - short", GRN_OBJ_KEY_WITH_SIS,
      "ナ", GRN_SUCCESS,
      ["セナセナ", "ナセナ", "セナ", "ナ"],
    ],
    ["sis - exact", GRN_OBJ_KEY_WITH_SIS,
      "セナ", GRN_SUCCESS,
      ["セナセナ", "ナセナ", "セナ"],
    ],
    ["sis - long", GRN_OBJ_KEY_WITH_SIS,
      "セナセナセナ", GRN_END_OF_DATA, [],
    ],
  ));
});

done_testing;

sub _pat_search_test {
  my ($ctx, $func, @testdata) = @_;
  Groonga::API::set_default_encoding(GRN_ENC_UTF8);

  my @keys = (
    "セナ",
    "ナセナセ",
    "Groonga",
    "セナ + Ruby",
    "セナセナ",
  );

  for my $data (@testdata) {
    note $data->[0];
    my $key_size = my $value_size = 100; # XXX: arbitrary
    my $flags = GRN_OBJ_KEY_VAR_SIZE | $data->[1];
    my $pat = Groonga::API::pat_create($ctx, undef, $key_size, $value_size, $flags);
    ok defined $pat, "created";
    is ref $pat => "Groonga::API::pat", "correct object";

    for my $key (@keys) {
      my $id = Groonga::API::pat_add($ctx, $pat, $key, bytes::length($key), my $value, my $added);
      ok $id, "added $id";
    }

    my $hash = Groonga::API::hash_create($ctx, undef, $key_size, 0, GRN_OBJ_KEY_VAR_SIZE);
    my $key = $data->[2];
    my $rc = $func->($ctx, $pat, $key, bytes::length($key), $hash);
    is $rc => $data->[3], "correct result";

    if ($rc == GRN_SUCCESS) {
      my @found;
      my $cursor = Groonga::API::hash_cursor_open($ctx, $hash, undef, 0, undef, 0, 0, -1, GRN_CURSOR_ASCENDING);
      while(my $id = Groonga::API::hash_cursor_next($ctx, $cursor)) {
        my $len = Groonga::API::hash_cursor_get_key($ctx, $cursor, my $key);
        my $pat_id = unpack 'L', $key;
        my $buf = ' ' x $key_size;
        $len = Groonga::API::pat_get_key($ctx, $pat, $pat_id, $buf, $key_size);
        push @found, substr($buf, 0, $len);
      }
      Groonga::API::hash_cursor_close($ctx, $cursor);

      is_deeply [sort @found] => [sort @{$data->[4]}], "found correct keys";
    }

    Groonga::API::hash_close($ctx, $hash);
    Groonga::API::pat_close($ctx, $pat);
  }
}
