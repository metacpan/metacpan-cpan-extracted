#!perl -l

my @a = (3, 6, 2, 19, 5);

for my $n (sort { $a <=> $b } @a) {
    print $n;
}

# see https://rt.cpan.org/Public/Bug/Display.html?id=29956
