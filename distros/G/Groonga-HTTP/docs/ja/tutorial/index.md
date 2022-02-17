---
title: Tutorial
---

# チュートリアル

このドキュメントは、Groonga-HTTPの使い方を段階的に説明しています。まだ、Groonga-HTTPをインストールしていない場合は、このドキュメントを読む前にGroonga-HTTPをインストールしてください。

## ドリルダウン {#drilldown}

drilldown はカラムの値ごとにレコード数を数える機能を提供します。値ごとに別々のクエリーになるのではなく、1回のクエリーですべての値に対してレコード数を数えます。

例:

```perl
use Groonga::HTTP;

my $groonga = Groonga::HTTP->new;

my @result = $groonga->select(
   table => 'Entries',
   output_columns => '_key,tag',
   drilldown => 'tag'
);

#Result
#[
#  [
#    "Hello",
#    1
#  ],
#  [
#    "Groonga",
#    2
#  ],
#  [
#    "Senna",
#    2
#  ]
#]
```

上記の例は以下のことを示しています。

  * ``tag`` の値が "Hello" であるレコードの数は1。
  * ``tag`` の値が "Groonga" であるレコードの数は2。
  * ``tag`` の値が "Senna" であるレコードの数は2。

## ドリルダウン結果のフィルター {#drilldown-filter}

``drilldown_filter`` を使ってドリルダウン結果をフィルターできます。
``drilldown_filter`` にドリルダウン結果に対するフィルター条件を指定します。

以下は1回しか出現していないタグを除く例です。

例:

```perl
use Groonga::HTTP;

my $groonga = Groonga::HTTP->new;

my @result = $groonga->select(
   table => 'Entries',
   output_columns => '_key,tag',
   drilldown => 'tag',
   drilldown_filter => '_nsubrecs > 1'
);

#Result
#[
#  [
#    "Groonga",
#    2
#  ],
#  [
#    "Senna",
#    2
#  ]
#]
```

## 結果のソート {#sort-of-result}

Groonga-HTTPは、検索結果を特定のカラムの値でソートできます。デフォルトの順序は昇順です。
"-"接頭辞によって、順序を逆にできます。

例:

```perl
use Groonga::HTTP;

my $groonga = Groonga::HTTP->new;

# Ascending order

my @result = $groonga->select(
  table => 'Site',
  columns => 'title',
  query => 'six OR seven',
  output_columns => '_id, title',
  sort_keys => 'id'
);

# Result
#    [
#      [
#        6,
#        'test test test test record six.'
#      ],
#      [
#        7,
#        'test test test record seven.'
#      ],
#    ],

# Descending order

my @result = $groonga->select(
  table => 'Site',
  columns => 'title',
  query => 'six OR seven',
  output_columns => '_id, title',
  sort_keys => '-id'
);

# Result
#    [
#      [
#        7,
#        'test test test record seven.'
#      ],
#      [
#        6,
#        'test test test test record six.'
#      ],
#    ],

```

## カラムに重みを設定する

Groonga-HTTPはカラムに重みを設定できます。
この機能によってスコアーの値を調整できます。

例えば、以下の例では、 content カラムの重みを2倍しています。
これは、 _key カラムの値より content カラムの値のほうが重要だという意味になります。

例:

```
my @result = $groonga->select(
   table => 'Entries',
   match_columns => '_key || content * 2',
   query => 'groonga',
   output_columns => '_key,content,_score'
);

# Result
# [
#   [
#     "Groonga",
#     "I started to use Groonga. It's very fast!",
#     3,
#   ]
# ],
```

[install]:../install/
