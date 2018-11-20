use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Lingua::JA::FindDates qw!kanji2number regjnums!;

#$Lingua::JA::FindDates::verbose = 1;

{
    my $warning;
    # Test failures
    local $SIG{__WARN__} = sub { $warning = "@_"; };
    ok (kanji2number ('3百三十五') == 0, 'bad kanji number failure test');
    like ($warning, qr/can't cope with '3' of input '3百三十五'/);

    # Test putting in a non-number kanji.

    my $value = kanji2number ('袖');
    ok ($value == 0, "Bad kanji gives zero");
    ok ($warning, "Got a warning with non-numerical kanji");
    like ($warning, qr!can't cope with '袖' of input '袖'!);
};

ok (kanji2number ('二百三十五') == 235, 'kanji number 235 with keta');
ok (kanji2number ('二三五') == 235, 'kanji number 235 no keta');
ok (kanji2number ('二三五五') == 2355, 'kanji number 2355');
# This tests the code "if ($val_next > 10) {"
is (kanji2number ('千百十一'), '1111', 'kanji number 1111');

my $k1234 = kanji2number ('一二三四');
is ($k1234, '1234', "Got number for 1234");

my $nothing = kanji2number ('');
is ($nothing, '0', "Got zero for empty string");

my $wide = '０１２３４５６７８９';
is (regjnums ($wide), '0123456789', "Wide to ascii");
my $two35 = '二百三十五 monkeys';
is (regjnums ($two35), '235 monkeys');

done_testing ();
