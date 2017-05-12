sub bar {
    $DB::single = 1;

    1; # to avoid an early return
}

sub foo {
    $DB::single = 1;
    bar("bar", $_[1] - 2);
}

sub baz {
    eval {
        $DB::single = 1;

        1; # to avoid an early return
    }
}

foo("foo", 7);

baz({ a => { b => 3 } }, [1, [2]]);

$DB::single = 1;

1; # to avoid the program terminating
