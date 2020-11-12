#!perl

use 5.010001;
use strict;
use warnings;
use Test::Deep;
use Test::More 0.98;

use Health::BladderDiary::GenTable qw(gen_bladder_diary_table_from_entries);

my $entries1 = <<'_';
0700 d 300ml
0715 u 200ml u4 c0
0900 drink: vol=250 comment=test comment, type=milk
_
cmp_deeply(gen_bladder_diary_table_from_entries(entries => $entries1, _raw=>1), [
    200,
    "OK",
    {
        intakes => [
            superhashof({time=>'07.00', vol=>'300'}),
            superhashof({time=>'09.00', vol=>'250', comment=>'test comment', type=>'milk'}),
        ],
        urinations => [
            superhashof({time=>'07.15', vol=>'200', urgency=>4, color=>'clear'}),
        ],
    }]);

my $entries2 = <<'_';
0700 d 300ml

0715 u 200ml u4 c0

0900 drink: vol=250 comment=test comment,
type=milk
_
cmp_deeply(gen_bladder_diary_table_from_entries(entries => $entries2, _raw=>1), [
    200,
    "OK",
    {
        intakes => [
            superhashof({time=>'07.00', vol=>'300'}),
            superhashof({time=>'09.00', vol=>'250', comment=>'test comment', type=>'milk'}),
        ],
        urinations => [
            superhashof({time=>'07.15', vol=>'200', urgency=>4, color=>'clear'}),
        ],
    }]);

done_testing;
