use Test::More;
use strict;
use warnings;
use Foreign::Sort;

{
    package X1;
    sub nsort { $a <=> $b }
    sub lsort { $a cmp $b }
    sub rsort { $b <=> $a }
    sub revsort { reverse($a) cmp reverse($b) }
}

{
    package X2;
    use Foreign::Sort;
    sub nsort : Foreign { $a <=> $b }
    sub lsort : Foreign { $a cmp $b }
    sub rsort { no warnings 'numeric'; $b <=> $a }
    sub revsort { reverse($a) cmp reverse($b) }
}

my @x = (125,3125,5,625,25);

my $uninit = 0;
$SIG{__WARN__} = sub {
    if ($_[0] =~ /uninitialized value/) {
	$uninit++;
    } else {
	goto &CORE::warn
    }
};


my $u = $uninit;
my @x1 = sort X1::nsort @x;
ok($uninit > $u, "X1::nsort received uninit values");
ok("@x" eq "@x1", "X1::nsort had no effect");

@x1 = do { package X1; sort X1::nsort @x };
ok("@x1" eq "5 25 125 625 3125", "X1::nsort works in package X1");
@x1 = do { package X1; sort nsort @x };
ok("@x1" eq "5 25 125 625 3125", "bare nsort works in package X1");


$u = $uninit;
my @x2 = sort X2::nsort @x;
ok($uninit == $u, "X2::nsort did not receive uninit values");
ok("@x" ne "@x2", "X2::nsort had an effect");
ok("@x2" eq "5 25 125 625 3125", "X2::nsort had the right effect");
$u = $uninit;
@x2 = do { package X5; sort X2::nsort @x };
ok($uninit == $u, "X2::nsort from other pkg receives init values");
ok("@x2" eq "5 25 125 625 3125", "X2::nsort works from other pkg");

$X1::a = "foo";
$X2::b = "bar";
$main::a = "baz";
$main::b = "quux";
$u = $uninit;
@x2 = sort X2::lsort @x;
ok($uninit == $u, "X2::lsort did not receive uninit values");
ok("@x2" eq "125 25 3125 5 625", "X2::lsort had the right effect");
ok($X1::a eq 'foo' && $X2::b eq 'bar' && $main::a eq 'baz'
   && $main::b eq 'quux',
   "package variables \$a and \$b preserved through sort")
    or diag $X1::a, $X1::b, $X2::a, $X2::b, $main::a, $main::b;

$u = $uninit;
@x2 = sort X2::rsort @x;
ok($uninit > $u, "X2::rsort does not have Foreign attr and received uninit");
ok("@x2" eq "@x", "X2::rsort had no effect on input");


done_testing;
