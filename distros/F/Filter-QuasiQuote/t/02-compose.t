use strict;
use warnings;

use Test::More tests => 10;

use lib 'lib';
BEGIN {
    #$Filter::QuasiQuote::Debug = 1;
}

use t::data::QuoteSQL;
use t::data::QuoteEval;

my $id = 6;
is([:eval|3 + int(2.75)|], '5', 'simple eval');
is([:sql|select * from Post where $id = id|],
    "select * from Post where '6' = id", 'sql with a variable');
my $author = 'agentzh';
my $title = "Perl's quasiquoting \\:D//";
is([:eval|1-5|].[:sql|select * from Post where author = $author and title = $title |],
    "-4select * from Post where author = 'agentzh' and title = 'Perl''s quasiquoting \\\\:D//'", 'eval + sql');

is([:sql|select 3 |] . [:eval| 5*
    7 - 3|] . [:sql| select 7|],
    "select 332select 7",
    'select + eval + select');

is([:eval|6 / 3 |] . [:eval| 5*
    7 - 3|] . [:eval| 7-7|],
    "2320",
    'eval + eval + eval');

is([:eval|6 / 3 |] . [:sql| select
    7 - 3|] . [:eval| 7-7|],
    "2select    7 - 30",
    'eval + eval + eval');

is([:eval|'hello'|] . [:sql|select 3|], 'helloselect 3', 'two quotes on a single line');
is([:sql|select 1|] . [:eval|'hello'|] . [:sql|select 2|], 'select 1helloselect 2', '3 quotes on a single line');
is([:eval| 3|] . [:sql|select 2|] . [:eval|
    4|], "3select 24", '3 quotes spanning 2 lines');
is([:sql|select 3|] . [:eval| 6|] . [:eval|
    9|] . [:eval| 7|], "select 3697", '4 quotes spanning 2 lines');

