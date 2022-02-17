---
title: Tutorial
---

# Tutorial

This document describes how to use Groonga-HTTP step by step.
If you don't install Groonga-HTTP yet, [install][install] Groonga-HTTP before you read this document.

## Drilldown {#drilldown}

drilldown enables us to get the number of records which belongs to specific the value of column at once.

Example:

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

The above example shows the following.

  * The number of records that the value of ``tag`` is "Hello" is 1.
  * The number of records that the value of ``tag`` is "Groonga" is 2.
  * The number of records that the value of ``tag`` is "Senna" is 2.

## Filter of the result of drilldown {#drilldown-filter}

We can filter the result of drilldown by ``drilldown_filter``.
We specify the filter condition against the drilled down result into ``drilldown_filter``.

Here is an example to suppress tags that are occurred only once.

Example:

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

## Sort of result {#sort-of-result}

Groonga-HTTP can sort search results by a specific value of a column.
The default of the order is ascending order.
We can reverse the order by the prefix of "-".

Example:

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

## Set weight to the column

Groonga-HTTP can set the weight to a column.
We adjust the value of score by this feature.

For example, the weight of the content column is twice in the following example.
This weight allocation means content column value is more important rather than _key column value.

Example:

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
