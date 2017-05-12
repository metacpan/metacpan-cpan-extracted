use strict;
use warnings;
use FindBin;
use File::Path;
use Test::More;
use Test::Differences;
use Ploonga;

my $tmpdir = "$FindBin::Bin/../tmp";
rmtree $tmpdir if -d $tmpdir;
mkpath $tmpdir;

my $ploonga = Ploonga->new(
  dbfile => "$tmpdir/test.db",
);

# Try the official tutorial
# http://groonga.org/docs/tutorial/introduction.html

{
  my $status = $ploonga->do('status');
  ok $status, "status is not empty";
  note explain $status;
}

{
  my $rc = $ploonga->do('table_create --name Site --flags TABLE_HASH_KEY --key_type ShortText');
  ok $rc, "created a table";
}

{
  my $rows = $ploonga->do('select --table Site');
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        0
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ]
      ]
    ]
  ];
}

{
  my $rc = $ploonga->do('column_create --table Site --name title --type ShortText');
  ok $rc, "created a column";
}

{
  my $rows = $ploonga->do('select --table Site');
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        0
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ]
    ]
  ];
}

{
  my $rc = $ploonga->do('load --table Site', <<'JSON');
[
{"_key":"http://example.org/","title":"This is test record 1!"},
{"_key":"http://example.net/","title":"test record 2."},
{"_key":"http://example.com/","title":"test test record three."},
{"_key":"http://example.net/afr","title":"test record four."},
{"_key":"http://example.org/aba","title":"test test test record five."},
{"_key":"http://example.com/rab","title":"test test test test record six."},
{"_key":"http://example.net/atv","title":"test test test record seven."},
{"_key":"http://example.org/gat","title":"test test record eight."},
{"_key":"http://example.com/vdw","title":"test test record nine."},
]
JSON

  is $rc => 9, "loaded";
}

{
  my $rows = $ploonga->do('select --table Site');
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ],
      [
        2,
        "http://example.net/",
        "test record 2."
      ],
      [
        3,
        "http://example.com/",
        "test test record three."
      ],
      [
        4,
        "http://example.net/afr",
        "test record four."
      ],
      [
        5,
        "http://example.org/aba",
        "test test test record five."
      ],
      [
        6,
        "http://example.com/rab",
        "test test test test record six."
      ],
      [
        7,
        "http://example.net/atv",
        "test test test record seven."
      ],
      [
        8,
        "http://example.org/gat",
        "test test record eight."
      ],
      [
        9,
        "http://example.com/vdw",
        "test test record nine."
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do('select --table Site --query _id:1');
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        1
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --query '_key:"http://example.org/"'});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        1
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ]
    ]
  ];
}

{
  my $rc = $ploonga->do(q{table_create --name Terms --flags TABLE_PAT_KEY|KEY_NORMALIZE --key_type ShortText --default_tokenizer TokenBigram});
  ok $rc, "created another table";
}

{
  my $rc = $ploonga->do(q{column_create --table Terms --name blog_title --flags COLUMN_INDEX|WITH_POSITION --type Site --source title});
  ok $rc, "created an index";
}

{
  my $rows = $ploonga->do(q{select --table Site --query title:@this});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        1
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --match_columns title --query this});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        1
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --output_columns _key,title,_score --query title:@test});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ],
        [
          "_score",
          "Int32"
        ]
      ],
      [
        "http://example.org/",
        "This is test record 1!",
        1
      ],
      [
        "http://example.net/",
        "test record 2.",
        1
      ],
      [
        "http://example.com/",
        "test test record three.",
        2
      ],
      [
        "http://example.net/afr",
        "test record four.",
        1
      ],
      [
        "http://example.org/aba",
        "test test test record five.",
        3
      ],
      [
        "http://example.com/rab",
        "test test test test record six.",
        4
      ],
      [
        "http://example.net/atv",
        "test test test record seven.",
        3
      ],
      [
        "http://example.org/gat",
        "test test record eight.",
        2
      ],
      [
        "http://example.com/vdw",
        "test test record nine.",
        2
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --offset 0 --limit 3});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ],
      [
        2,
        "http://example.net/",
        "test record 2."
      ],
      [
        3,
        "http://example.com/",
        "test test record three."
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --offset 3 --limit 3});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        4,
        "http://example.net/afr",
        "test record four."
      ],
      [
        5,
        "http://example.org/aba",
        "test test test record five."
      ],
      [
        6,
        "http://example.com/rab",
        "test test test test record six."
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --offset 7 --limit 3});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        8,
        "http://example.org/gat",
        "test test record eight."
      ],
      [
        9,
        "http://example.com/vdw",
        "test test record nine."
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --sortby -_id});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_key",
          "ShortText"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        9,
        "http://example.com/vdw",
        "test test record nine."
      ],
      [
        8,
        "http://example.org/gat",
        "test test record eight."
      ],
      [
        7,
        "http://example.net/atv",
        "test test test record seven."
      ],
      [
        6,
        "http://example.com/rab",
        "test test test test record six."
      ],
      [
        5,
        "http://example.org/aba",
        "test test test record five."
      ],
      [
        4,
        "http://example.net/afr",
        "test record four."
      ],
      [
        3,
        "http://example.com/",
        "test test record three."
      ],
      [
        2,
        "http://example.net/",
        "test record 2."
      ],
      [
        1,
        "http://example.org/",
        "This is test record 1!"
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --query title:@test --output_columns _id,_score,title --sortby -_score});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_score",
          "Int32"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        6,
        4,
        "test test test test record six."
      ],
      [
        5,
        3,
        "test test test record five."
      ],
      [
        7,
        3,
        "test test test record seven."
      ],
      [
        8,
        2,
        "test test record eight."
      ],
      [
        3,
        2,
        "test test record three."
      ],
      [
        9,
        2,
        "test test record nine."
      ],
      [
        1,
        1,
        "This is test record 1!"
      ],
      [
        4,
        1,
        "test record four."
      ],
      [
        2,
        1,
        "test record 2."
      ]
    ]
  ];
}

{
  my $rows = $ploonga->do(q{select --table Site --query title:@test --output_columns _id,_score,title --sortby -_score,_id});
  ok $rows, "select table";
  eq_or_diff $rows => [
    [
      [
        9
      ],
      [
        [
          "_id",
          "UInt32"
        ],
        [
          "_score",
          "Int32"
        ],
        [
          "title",
          "ShortText"
        ]
      ],
      [
        6,
        4,
        "test test test test record six."
      ],
      [
        5,
        3,
        "test test test record five."
      ],
      [
        7,
        3,
        "test test test record seven."
      ],
      [
        3,
        2,
        "test test record three."
      ],
      [
        8,
        2,
        "test test record eight."
      ],
      [
        9,
        2,
        "test test record nine."
      ],
      [
        1,
        1,
        "This is test record 1!"
      ],
      [
        2,
        1,
        "test record 2."
      ],
      [
        4,
        1,
        "test record four."
      ]
    ]
  ];
}

undef $ploonga;

rmtree $tmpdir if Test::More->builder->is_passing;

done_testing;
