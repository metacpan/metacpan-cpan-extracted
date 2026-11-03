# Fixture for t/52-scrape-args.t: what follows the strings is code.
l("PL var %s", $name);
my $y = l("PL assign %s", $x);
ln("PL count one", "PL count many", $n);
ln("PL zero one", "PL zero many", 0);
ln("PL method %d", "PL methods %d", $obj->count, $h->{name}[0]);
ln("PL fn %d", "PL fns %d", scalar(@items));
l("PL paren %s", ")");
l("PL comma %s %s", ",", 'it\'s, (');
l("PL escape %s", "tab\t(");
l("PL nested %s and %s", l("PL Apple"), $x);
lp("PL_ctx", "PL ctx %s", $user->{'first, last'});
ldnp("PL_dom", "PL_ctx", "PL dnp one", "PL dnp many", count_of(\@items, { a => [1, 2] }), "x" . $y);
l(
    "PL multi %s %s",
    $first,
    join(", ", map { $_->name } @list),
);
ln(
    "PL multi one",
    "PL multi many",
    $#list + 1
);
ln("PL nested count one", "PL nested count many", count(l("PL in count")));
l($not_constant, l("PL inside skipped"));
# Broken code: the call inside the broken calls is still recorded, once.
l("PL broken %s", foo(l("PL broken inner", l("PL once") ]));
