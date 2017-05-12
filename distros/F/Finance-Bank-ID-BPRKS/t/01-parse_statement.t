#!perl

use strict;
use warnings;

use Test::More;
use DateTime;
use File::Slurp::Tiny qw(read_file write_file);
use FindBin '$Bin';

use Finance::Bank::ID::BPRKS;

my $ibank = Finance::Bank::ID::BPRKS->new();

for my $f (
    ["stmt1.html", "invididual, html"],
) {
    my $resp = $ibank->parse_statement(scalar read_file("$Bin/data/$f->[0]"));
    die "status=$resp->[0], error=$resp->[1]\n" if $resp->[0] != 200;
    my $stmt = $resp->[2];

    # metadata
    is($stmt->{account}, "1234567890", "$f->[1] (account)");
    is($stmt->{account_holder}, "AAAAA", "$f->[1] (account_holder)");
    is(DateTime->compare($stmt->{start_date},
                         DateTime->new(year=>2012, month=>5, day=>14)),
       0, "$f->[1] (start_date)");
    is(DateTime->compare($stmt->{end_date},
                         DateTime->new(year=>2012, month=>6, day=>12)),
       0, "$f->[1] (end_date)");
    is($stmt->{currency}, "IDR", "$f->[1] (currency)");

    # transactions
    is(scalar(@{ $stmt->{transactions} }), 2, "$f->[1] (num tx)");
    is(DateTime->compare($stmt->{transactions}[0]{date},
                         DateTime->new(year=>2012, month=>5, day=>25)),
       0, "$f->[1] (tx0 date)");
    is($stmt->{transactions}[0]{amount}, 1000.01, "$f->[1] (tx0 amount)");
    is($stmt->{transactions}[0]{balance}, 2000.01, "$f->[1] (tx0 balance)");
    is($stmt->{transactions}[0]{seq}, 1, "$f->[1] (tx0 seq)");

    is($stmt->{transactions}[1]{amount}, -100, "$f->[1] (debit)");

    is($stmt->{transactions}[1]{seq}, 2, "$f->[1] (seq 1)");
    #is($stmt->{transactions}[2]{seq}, 1, "$f->[1] (seq 2)");
}

my $res = $ibank->parse_statement(scalar(read_file("$Bin/data/stmt1.html")), return_datetime_obj=>0);
my $stmt = $res->[2];
ok(!ref($stmt->{start_date}), "return_datetime_obj=0 (1)");

done_testing();
