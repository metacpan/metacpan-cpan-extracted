use warnings;
use strict;
use utf8;
use Test::More;

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Lingua::JA::FindDates qw/subsjdate/;
#$Lingua::JA::FindDates::verbose =1;
my $warning;
{
    local $SIG{__WARN__} = sub { $warning = "@_"; };
    ok (Lingua::JA::FindDates::kanji2number ('3百三十五') == 0, 'bad kanji number failure test');
    like ($warning, qr/can't cope with '3' of input '3百三十五'/);
};
ok (Lingua::JA::FindDates::kanji2number ('二百三十五') == 235, 'kanji number');
ok (Lingua::JA::FindDates::kanji2number ('二三五') == 235, 'kanji number');
ok (Lingua::JA::FindDates::kanji2number ('二三五五') == 2355, 'kanji number');

my @tests= qw/平成２０年７月３日（木） H二十年七月三日(木曜日) 二千八年7月三日(木曜)/;
for my $d (@tests) {
    note subsjdate ($d);
    ok (subsjdate ($d) eq 'Thursday, July 3, 2008', 
	'year + month + day + weekday');
}

sub mymakedate
{
    my ($data, $original, $datehash) = @_;
    print "KEYS: ",join (" ", keys %$datehash), "\n";
    my ($year, $month, $date, $wday, $jun) = 
	@{$datehash}{qw/year month date wday jun/};
    return qw{Bad Mo Tu We Th Fr Sa Su}[$wday]." $year/$month/$date";
}

for my $d (@tests) {
    note subsjdate ($d);
    is (subsjdate ($d, {make_date => \&mymakedate}),
	'Th 2008/7/3', 'test make_date callback with own function');
}

my @tests2= ('昭和 ４１年　３月１６日', 'Ｓ４１年三月十六日', '千九百六十六年3月16日');
for my $c (@tests2) {
#    print "$d, [>>",subsjdate ($d),"<<]\n";
    ok (subsjdate ($c) eq 'March 16, 1966', 'year + month + day combination');
}
my @tests3= ('昭和 ４１年', 'Ｓ４１年', '千九百六十六年');
for my $c (@tests3) {
#    print "$c, [>>",subsjdate ($c),"<<]\n";
    ok (subsjdate ($c) eq '1966', 'year combination');
}
my @tests4= ('３ 月 １６日', '三月十六日', '3月16日');
for my $c (@tests4) {
#    print "$d, [>>",subsjdate ($d),"<<]\n";
    ok (subsjdate ($c) eq 'March 16', 'month + day combination');
}

my $test5 =<<EOF;
2008年07月03日 01:39:21 投稿
【西村修平・桜井誠編】平成20年7月2日毎日新聞社前抗議行動！
最低賃金法が大きく改正され、平成２０年７月１日から施行されました。
平成二十年七月四日
Opera 9.51(Windows版)を入れてみたけれども相變らず使ひ物にならない。何なんだらう。
日本義塾 平成二十年七月公開講義
公開日時：2008年06月28日 01時09分
更新日時：2008年06月29日 00時08分

◎【日本義塾七月公開講義】

　◎日　時　平成二十年七月二十五日（金）
　　　　　　午後六時半～九時（六時開場）
H20年7月壁紙
7月壁紙（1024×768）を作成しました（クリックすると拡大します）。
昭和４９年度
1999年度
EOF

my %jdates = 
(
'2008年07月03日' =>'July 3, 2008',
'平成20年7月2日' =>'July 2, 2008',
'平成２０年７月１日' =>'July 1, 2008',
'平成二十年七月四日' =>'July 4, 2008',
'平成二十年七月' =>'July 2008',
'2008年06月28日' =>'June 28, 2008',
'2008年06月29日' =>'June 29, 2008',
'平成二十年七月二十五日（金）' =>'Friday, July 25, 2008',
'H20年7月' => 'July 2008',
'7月' => 'July',
'七月' => 'July',
'昭和４９年度' => 'fiscal 1974',
'1999年度' => 'fiscal 1999',
'明19' => '1886',
);

sub replace_callback
{
    my ($data, $jdate, $edate) = @_;
#    print "[$jdate] [$edate] [$jdates{$jdate}]\n";
    ok ($jdates{$jdate} eq $edate, "replace_callback");
}

subsjdate ($test5, {replace => \&replace_callback});

ok ($Lingua::JA::FindDates::verbose == 0, 'verbose option switched off by default');

my @tests_interval = 
('昭和41年3月1〜12日',
 '昭和41年3月1日〜12日',
 '昭和41年1〜12月',
 '昭和41年1月〜12月',
 '昭和41年3月1日〜4月12日',);

for my $c (@tests_interval[0..1]) {
    note "Looking for $c\n";
    note $c, " ", subsjdate($c),"\n";
    ok (subsjdate($c) eq 'March 1-12, 1966', "two days interval");
}
for my $c (@tests_interval[2..3]) {
    note "Looking for $c\n";
    note $c, " ", subsjdate($c),"\n";
    ok (subsjdate($c) eq 'January-December 1966', "month-month interval");
}

for my $c ($tests_interval[4]) {
    note "Looking for $c\n";
    note $c, " ", subsjdate($c),"\n";
    ok (subsjdate($c) eq 'March 1-April 12, 1966', "two days interval");
}
# Test there is no weird match to a following word.

my $has_newline =<<EOF;
平成二十年七月一日
    日本論・日本人論は非常に面白いものだ。
EOF

ok (subsjdate($has_newline) !~ 'Sunday', 'do not match next kanji if it\'s not a weekday');

ok (subsjdate('平成元年') eq '1989', 'gannen dates');

ok (subsjdate('三月一日（木）〜３日（土）') eq 'Thursday 1-Saturday 3 March','interval with month, (day, weekday) x 2)');
go:
ok (subsjdate('2008年7月一日（木）〜八月３日（土)') eq 'Thursday 1 July-Saturday 3 August, 2008', 'interval with year, 2 x (month, day, weekday)');
ok (subsjdate('2008年7月一日（木）〜３日（土)') eq 'Thursday 1-Saturday 3 July, 2008', 'interval with year, 2 x (month, day, weekday)');
ok (subsjdate ('平成９年１０月１７日（火）〜２０日（金）') eq 'Tuesday 17-Friday 20 October, 1997');
ok (subsjdate ('平成９年１０月１７日（火）~２０日（金）') eq 'Tuesday 17-Friday 20 October, 1997');

ok (subsjdate ('平成９年 月　日') eq 'MM DD, 1997', "Blank dates");
ok (subsjdate ('３月初旬') eq 'early March', "disappearing jun bug");

my $date_with_linebreak = <<EOF;
平成21年
11月 4日
EOF

ok (subsjdate ($date_with_linebreak) =~ /2009\nNovember 4/,
    "Two dates on two lines not turned into one date");

ok (subsjdate ('\'79年4月21日') eq 'April 21, \'79', "Apostrophe dates");

# Test for the "kanji zero".

is (subsjdate ('平成二〇年一二月二六日'), 'December 26, 2008',
    "kanji zero handling");

# Test for romaji-swallowing

my $tbs =
'赤い迷路	TBS	1974年10月4日 - 1975年3月27日	赤いシリーズ第1作目';

like (subsjdate ($tbs),
      qr/October 4, 1974/,
      "Do not convert romaji strings using the S-digit rule");

#my $doubletrouble = 
#'昭和３４年１月１７日（土）〜平成9年12月20日（土）';
my $doubletrouble = 
'昭和３４年１月１７日〜平成9年12月20日';

#note (subsjdate ($doubletrouble));
like (subsjdate ($doubletrouble), qr/January 17, 1959-December 20, 1997/);

my $meiji = '明治36年';
is (subsjdate ($meiji), 1903, "Meiji conversion");

my @squares = qw/
		    ㍻1年
		    ㍼1年
		    ㍽1年
		    ㍾1年
		/;
my @years = (1989, 1926, 1912, 1868);

for my $i (0..$#squares) {
    is (subsjdate ($squares[$i]), $years[$i], "square years");
}

# Different years.

my $twoyears = Lingua::JA::FindDates::default_make_date_interval (
    {
        # 19 February 2010
        year => 2010,
        month => 2,
        date => 19,
        wday => 5,
    },
    # Monday 19th March 2012.
    {
        year => 2012,
        month => 3,
        date => 19,
        wday => 1,
    },);

is ($twoyears, 'Friday 19 February, 2010-Monday 19 March, 2012');

TODO: {
    local $TODO = 'bugs';
}; 

done_testing ();
exit;
