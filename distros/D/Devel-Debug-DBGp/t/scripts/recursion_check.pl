sub foo {
    my ($n) = @_;

    $n > 0 ? foo($n - 1) + $n : 0;
}

foo(70);

$DB::single = 1;

1; # avoid the program exiting
