#!perl

use strict;
use warnings;
use Test::More;
use DateTime;
use File::Slurper qw(read_text);
use FindBin '$Bin';
use Finance::Bank::ID::Mandiri;

my $ibank = Finance::Bank::ID::Mandiri->new();

for my $f (
    ["stmt1.html", "ib, html"],
    ["stmt1.opera10linux.txt", "ib, txt, opera10linux"],
    ["stmt1.ff35linux.txt", "ib, txt, ff35linux"]) {
    my $resp = $ibank->parse_statement(read_text("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890123", "$f->[1] (account)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2009, month=>8, day=>13)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2009, month=>8, day=>13)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 2, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2009, month=>8, day=>13)),
       0, "$f->[1] (tx0 date)");
    # remember, order is reversed
    is($stmt->{transactions}[0]{amount}, -222222, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[1]{amount}, 111111, "$f->[1] (amount)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");
    is($stmt->{transactions}[1]{seq}, 2, "$f->[1] (seq)");
}

for my $f (
    ["stmt-cms.txt", "cms, txt"],) {
    my $resp = $ibank->parse_statement(read_text("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890123", "$f->[1] (account)");
    is($stmt->{account_holder}, "MAJU MUNDUR", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2009, month=>8, day=>10)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2009, month=>8, day=>15)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 3, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2009, month=>8, day=>10)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{amount}, 111111, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[1]{amount}, -2000, "$f->[1] (debit)");

    is($stmt->{transactions}[1]{seq}, 1, "$f->[1] (seq 1)");
    is($stmt->{transactions}[2]{seq}, 2, "$f->[1] (seq 2)");
}

for my $f (
    ["stmt-mcm-v201103.csv", "mcm v201103, semicolon"],) {
    my $resp = $ibank->parse_statement(read_text("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890123", "$f->[1] (account)");
    ##is($stmt->{account_holder}, "MAJU MUNDUR", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2010, month=>8, day=>31)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2010, month=>9, day=>1)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 4, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2010, month=>8, day=>31)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{amount}, -25000, "$f->[1] (tx0 amount, debit)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[1]{amount}, 1.55, "$f->[1] (credit)");

    is($stmt->{transactions}[2]{seq}, 3, "$f->[1] (seq 1)");
    is($stmt->{transactions}[3]{seq}, 1, "$f->[1] (seq 2)");
}

for my $f (
    ["stmt-mcm-v201107.csv", "mcm v201107, semicolon"],) {
    my $resp = $ibank->parse_statement(read_text("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890123", "$f->[1] (account)");
    ##is($stmt->{account_holder}, "MAJU MUNDUR", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2011, month=>6, day=>29)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2011, month=>6, day=>30)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 4, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2011, month=>6, day=>29)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{amount}, 769780,
       "$f->[1] (tx0 amount, credit)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[3]{amount}, -200, "$f->[1] (debit)");

    is($stmt->{transactions}[1]{seq}, 1, "$f->[1] (seq 1)");
    is($stmt->{transactions}[3]{seq}, 3, "$f->[1] (seq 2)");
}

for my $f (
    ["stmt-mcm-v201901.csv", "mcm v201901, comma"],) {
    my $resp = $ibank->parse_statement(read_text("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1030001026344", "$f->[1] (account)");
    ##is($stmt->{account_holder}, "MAJU MUNDUR", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2019, month=>1, day=>5)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2019, month=>1, day=>5)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 5, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2019, month=>1, day=>5)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{amount}, 917180,
       "$f->[1] (tx0 amount, credit)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[1]{amount}, -152900,
       "$f->[1] (tx1 amount, debit)");
    is($stmt->{transactions}[1]{seq}, 2, "$f->[1] (tx1 seq)");
}

done_testing();
