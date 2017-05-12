# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
BEGIN { $^W = 1 }

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..17\n"; }
my $loaded;
END {print "not ok 1\n" unless $loaded;}
use List::Permutor;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

{
    my $perm = new List::Permutor qw/ fred barney betty /;

    my @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "fred barney betty";
    print "ok 2\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "fred betty barney";
    print "ok 3\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "barney fred betty";
    print "ok 4\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "barney betty fred";
    print "ok 5\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "betty fred barney";
    print "ok 6\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "betty barney fred";
    print "ok 7\n";

    @set = $perm->next;
    print "# @set.\nnot " unless "@set" eq "";
    print "ok 8\n";
}

{
    my $perm = new List::Permutor 1..5;
    my %seen;
    while (my $set = join '', $perm->next) {
        if ($seen{$set}++) {
	    print "# Dup: $set\nnot ";
	    last;
	}
	last if 1000 < keys %seen;	# In case of infinite loop
    }
    print "ok 9\n";
    my $count = keys %seen;
    print "# Count was $count\nnot " unless $count == 120;
    print "ok 10\n";
}

{
    my $perm = new List::Permutor;
    my @list = $perm->next;
    print "not " if @list;
    print "ok 11\n";
}

{
    my $perm = new List::Permutor 1..3;
    my @list = $perm->peek;
    print "not " unless "@list" eq "1 2 3";
    print "ok 12\n";

    for (1..5) {
        $perm->next;
    }
    @list = $perm->peek;
    print "not " unless "@list" eq "3 2 1";
    print "ok 13\n";

    $perm->next;
    @list = $perm->peek;
    print "not " if @list;
    print "ok 14\n";
}

{
    my $perm = new List::Permutor 1..3;
    $perm->next;
    $perm->reset;
    my @list = $perm->peek;
    print "not " unless "@list" eq "1 2 3";
    print "ok 15\n";

    for (1..6) {
        $perm->next;
    }
    @list = $perm->peek;
    print "not " if @list;
    print "ok 16\n";

    $perm->reset;
    @list = $perm->peek;
    print "not " unless "@list" eq "1 2 3";
    print "ok 17\n";
}

