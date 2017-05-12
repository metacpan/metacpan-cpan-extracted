use strict;
use warnings;

use Test::More tests => 10;

use lib 'lib';
use t::data::QuoteSQL;

my $id = 6;
is([:sql|select * from Post|], 'select * from Post', 'constant sql');
is([:sql|select * from Post where $id = id|],
    "select * from Post where '6' = id", 'sql with a variable');
my $author = 'agentzh';
my $title = "Perl's quasiquoting \\:D//";
is([:sql|select * from Post where author = $author and title = $title |],
    "select * from Post where author = 'agentzh' and title = 'Perl''s quasiquoting \\\\:D//'", 'sql with a variable');

is([:sql|
    select *
    from Post
    where id
        = $id |],
    "select *     from Post     where id         = '6'",
    'multi-line sql');

is([:sql|select *
    from Post
    where id
        = $id |], "select *    from Post     where id         = '6'", 'multi-line sql');

is([:sql|select 1|] . [:sql|select 2|], 'select 1select 2', 'two quotes on a single line');
is([:sql|select 1|] . [:sql|select 2|] . [:sql|select 3|], 'select 1select 2select 3', '3 quotes on a single line');
is([:sql|select 1|] . [:sql|select 2|] . [:sql|select
    3|], "select 1select 2select    3", '3 quotes spanning 2 lines');

is([:sql|select 1|] . [:sql|select 2|] . [:sql|select
    3|] . [:sql|select 4|], "select 1select 2select    3select 4", '4 quotes spanning 2 lines');

is([:sql|select 1|] . [:sql|select 2|] . [:sql|select
    3|] . [:sql|select
    4|], "select 1select 2select    3select    4", '4 quotes spanning 3 lines');

