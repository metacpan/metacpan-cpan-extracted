#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Markdown::Table;
use Test::More;

my $markdown = q~
Those blogposts are planned

# Q4 2020

| **Themenkomplex** | **Thema**                      | **Autor** | **(gepl.) Datum** | **Status**                                                                                         |
|-------------------|--------------------------------|-----------|-------------------|-------------------------------------------------------------|
| Modul des Monats  | PPI                            | Renée     | 18\. Okt 2020     | [Ideen](https://internal.link)                              |
| News              | Kurse rund um GPW2021          | Renée     | 22\. Okt 2020     |                                                             |
| Allgemeines       | Unser Hacktoberfest 2020       | Renée     | 30  Okt 2020      |                                                             |
| Allgemeines       | Perl::Critic-Regeln entwickeln | Renée     | 5\. Nov 2020      | Ideen                                                       |

~;

my @tables = Markdown::Table->parse(
    $markdown,
);

is_deeply $tables[0]->cols, [
    "**Themenkomplex**", "**Thema**", "**Autor**", "**(gepl.) Datum**", "**Status**"
];

is_deeply $tables[0]->rows, [
    [ 'Modul des Monats', 'PPI', 'Renée', '18\. Okt 2020', '[Ideen](https://internal.link)' ],
    [ 'News', 'Kurse rund um GPW2021', 'Renée', '22\. Okt 2020' ],
    [ 'Allgemeines', 'Unser Hacktoberfest 2020', 'Renée', '30  Okt 2020' ],
    [ 'Allgemeines', 'Perl::Critic-Regeln entwickeln', 'Renée', '5\. Nov 2020', 'Ideen' ],
];

done_testing();
