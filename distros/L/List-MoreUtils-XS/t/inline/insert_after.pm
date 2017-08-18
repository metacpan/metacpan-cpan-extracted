
use Test::More;
use Test::LMU;

my @list = qw{This is a list};
insert_after { $_ eq "a" } "longer" => @list;
is(join(' ', @list), "This is a longer list");
insert_after { 0 } "bla" => @list;
is(join(' ', @list), "This is a longer list");
insert_after { $_ eq "list" } "!" => @list;
is(join(' ', @list), "This is a longer list !");
@list = (qw{This is}, undef, qw{list});
insert_after { not defined($_) } "longer" => @list;
$list[2] = "a";
is(join(' ', @list), "This is a longer list");

leak_free_ok(
    insert_after => sub {
        @list = qw{This is a list};
        insert_after { $_ eq 'a' } "longer" => @list;
    }
);
leak_free_ok(
    'insert_after with exception' => sub {
        eval {
            my @list = (qw{This is}, DieOnStringify->new, qw{a list});
            insert_after { $_ eq 'a' } "longer" => @list;
        };
    }
);
is_dying('insert_after without sub' => sub { &insert_after(42, 4711, [qw(die bart die)]); });
is_dying('insert_after without sub and array' => sub { &insert_after(42, 4711, "13"); });
is_dying(
    'insert_after without array' => sub {
        &insert_after(sub { }, 4711, "13");
    }
);

done_testing;
