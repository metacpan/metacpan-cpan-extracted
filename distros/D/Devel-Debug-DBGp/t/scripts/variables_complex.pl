my $foo = 1;
my $aref = [1, 2];
my $undef;

sub foo {
    my @foo = (1, 2);

    {
        my %bar = (a => 1);
    }

    my %baz = my %roo = (1, 2);
    my @baz = my @roo = (1);
    each %baz; each %roo; each %roo;
    each @baz; each @roo; each @roo;

    $DB::single = 1;

    my $bar = 3;
}

foo();

$DB::single = 1;

1; # to avoid the program terminating
