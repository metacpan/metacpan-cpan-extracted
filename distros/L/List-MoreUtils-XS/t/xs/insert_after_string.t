#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;

my @list = qw{This is a list};
insert_after_string "a", "longer" => @list;
is(join(' ', @list), "This is a longer list");
@list = (undef, qw{This is a list});
insert_after_string "a", "longer", @list;
shift @list;
is(join(' ', @list), "This is a longer list");
@list = ("This\0", "is\0", "a\0", "list\0");
insert_after_string "a\0", "longer\0", @list;
is(join(' ', @list), "This\0 is\0 a\0 longer\0 list\0");

leak_free_ok(
    insert_after_string => sub {
        @list = qw{This is a list};
        insert_after_string "a", "longer", @list;
    }
);
leak_free_ok(
    'insert_after_string with exception' => sub {
        eval {
            my @list = (qw{This is}, DieOnStringify->new, qw{a list});
            insert_after_string "a", "longer", @list;
        };
    }
);
is_dying('insert_after_string without array' => sub { &insert_after_string(42, 4711, "13"); });

done_testing;


