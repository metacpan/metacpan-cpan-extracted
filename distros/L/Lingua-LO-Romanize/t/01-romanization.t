#!perl -T

use warnings;
use strict;
use utf8;

use Lingua::LO::Romanize;
use Test::More tests => 60;

my $words = [
    [qw/ ນາ           na            na               /],
    [qw/ ນ່າ          na            na               /],
    [qw/ ນ້າ          na            na               /],
    [qw/ ນ໊າ          na            na               /],
    [qw/ ນ໋າ          na            na               /],
    [qw/ ອີກ          ik            ik               /],
    [qw/ ຊະເອມ        xa-ém         xa-ém            /],
    [qw/ ບ້ານແກ້ງອີ   bankèng-i     ban-kèng-i       /],
    [qw/ ຫລວງພະບາງ    louangphabang louang-pha-bang  /],
    [qw/ ຫຍ້າ         gna           gna              /],
    [qw/ ແຫນ          hèn           hèn              /],
    [qw/ ແໜ           nè            nè               /],
    [qw/ ວັດ          vat           vat              /],
    [qw/ ທັນວາ        thanva        than-va          /],
    [qw/ ບ້ານວັດພຣະໄຊ banvatphraxai ban-vat-phra-xai /],
    [qw/ ສວາຽ         soay          soay             /],
    [qw/ ແຂວງ         khoèng        khoèng           /],
    [qw/ ສະຫວັນນະເຂດ  savannakhét   sa-van-na-khét   /],
    [qw/ ຊວາ          xoa           xoa              /],
    [qw/ ຂວານ         khoan         khoan            /],
    [qw/ ສະວານ        savan         sa-van           /],
    [qw/ ຄິວ          khiou         khiou            /],
    [qw/ ຕີວ          tiou          tiou             /],
    [qw/ ຈົວ          choua         choua            /],
    [qw/ ນາວ          nao           nao              /],
    [qw/ ແກວ          kèo           kèo              /],
    [qw/ ດຽວ          diao          diao             /],
    [qw/ ເບີຣ໌        beur          beur             /],
    [qw/ເບຍ           bia           bia              /],
    [qw/ ໐໑໒໓໔໕໖໗໘໙   0123456789    0123456789       /],
];

foreach my $pair (@$words) {
    my $rom = Lingua::LO::Romanize->new(text => $pair->[0]);
    ok ( $rom->romanize eq $pair->[1], 'should recieve "' . $pair->[1] . '" got "'. $rom->romanize.'"');
    ok ( $rom->romanize(hyphen => 1) eq $pair->[2], 'should recieve "' . $pair->[2] . '" got "'. $rom->romanize(hyphen => 1).'"');
}