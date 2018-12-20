# demo script for t/ppi/85-smoke.pl
# a script with a naked top-level block structure

my ($y,$x);
{

    ($x,$y) = split(/,/, "foo,bar");
    print "$x => $y\n";

}

foo();

sub foo {
    ($x,$y) = split(/,/, "hello,world");
    print "$x => $y\n";
}
