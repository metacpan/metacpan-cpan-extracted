#!perl

use 5.010001;
use strict;
use Test::More 0.98;
use DateTime;
use File::Slurp::Tiny qw(read_file);
use FindBin '$Bin';

use Finance::Bank::ID::BCA;

my $ibank = Finance::Bank::ID::BCA->new();

for my $f (
    ["stmt1.html", "personal, html"],
    ["stmt1.opera10linux.txt", "personal, txt, opera10linux"],
    ["stmt1.ff35linux.txt", "personal, txt, ff35linux"],
    ["stmt1-en.opera10linux.txt", "personal (en), txt, opera10linux"],
) {
    my $resp = $ibank->parse_statement(scalar read_file("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890", "$f->[1] (account)");
    is($stmt->{account_holder}, "STEVEN HARYANTO", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2009, month=>9, day=>14)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2009, month=>10, day=>14)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 17, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2009, month=>9, day=>15)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{branch}, "0000", "$f->[1] (tx0 branch)");
    is($stmt->{transactions}[0]{amount}, -1000000, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[0]{balance}, 12023039.77, "$f->[1] (tx0 balance)");
    is($stmt->{transactions}[0]{is_pending}, 0, "$f->[1] (tx0 is_pending)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[5]{amount}, 500000, "$f->[1] (credit)");

    is($stmt->{transactions}[2]{seq}, 3, "$f->[1] (seq 1)");
    is($stmt->{transactions}[3]{seq}, 1, "$f->[1] (seq 2)");
}

for my $f (
    ["stmt1b.chrome4linux.txt", "personal, txt, chrome4linux"],
) {
    my $resp = $ibank->parse_statement(scalar read_file("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890", "$f->[1] (account)");
    is($stmt->{account_holder}, "STEVEN HARYANTO", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2009, month=>10, day=>31)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2009, month=>11, day=>2)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 5, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2009, month=>10, day=>31)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{branch}, "0000", "$f->[1] (tx0 branch)");
    is($stmt->{transactions}[0]{amount}, -10000, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[0]{balance}, 28560526.20, "$f->[1] (tx0 balance)");
    is($stmt->{transactions}[0]{is_pending}, 0, "$f->[1] (tx0 is_pending)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[1]{amount}, 39.42, "$f->[1] (credit)");

    is($stmt->{transactions}[1]{seq}, 2, "$f->[1] (seq 1)");
    is($stmt->{transactions}[4]{seq}, 1, "$f->[1] (seq 2)");
}

for my $f (
    ["stmt2.txt", "bisnis, txt"],) {
    my $resp = $ibank->parse_statement(scalar read_file("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890", "$f->[1] (account)");
    is($stmt->{account_holder}, "MAJU MUNDUR PT", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2009, month=>8, day=>11)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2009, month=>8, day=>11)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 3, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2009, month=>8, day=>11)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{branch}, "0065", "$f->[1] (tx0 branch)");
    is($stmt->{transactions}[0]{amount}, 239850, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[0]{balance}, 4802989.39, "$f->[1] (tx0 balance)");
    is($stmt->{transactions}[0]{is_pending}, 0, "$f->[1] (tx0 is_pending)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[2]{amount}, -65137, "$f->[1] (debit)");

    is($stmt->{transactions}[1]{seq}, 2, "$f->[1] (seq 1)");
    is($stmt->{transactions}[2]{seq}, 3, "$f->[1] (seq 2)");
}

# check skip_NEXT
for my $f (
    ["stmt2-NEXT.txt", "bisnis, txt"],) {
    local $ibank->{skip_NEXT} = 1;
    my $resp = $ibank->parse_statement(scalar read_file("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 2, "$f->[1] (num tx)");
    is(scalar(@{ $stmt->{skipped_transactions} }), 1,
       "$f->[1] (num skipped tx)");
}

my $res = $ibank->parse_statement(scalar(read_file("$Bin/data/stmt1.html")), return_datetime_obj=>0);
my $stmt = $res->[2];
ok(!ref($stmt->{start_date}), "return_datetime_obj=0 (1)");

done_testing();
