package # CPAN don't index
    SampleCode;

sub foo {
    5; # line 5
    6;
    7;
    8;
}

sub looper {
    for (my $i = 0; $i < 10; $i++) {
        13;
    }
    15;
}

sub takes_param {
    my($a) = @_;
    20;
    21;
}

1;
