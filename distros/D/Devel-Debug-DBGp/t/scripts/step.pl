my $i = 0;

sub baz {
    $i = $i;
    1; # so step does not return directly
}

sub bar {
    $i = $i;
    baz();
    1; # so step does not return directly
}

sub foo {
    ++$i;
    bar();
    foo() if $i < 30;
    1; # so step does not return directly
}

foo();

1; # to avoid the program terminating
