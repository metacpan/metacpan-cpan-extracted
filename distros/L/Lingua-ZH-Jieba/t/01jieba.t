#!perl

use strict;
use warnings;
use utf8;

use Data::Dumper;
use File::ShareDir qw(dist_file);
use Lingua::ZH::Jieba;
use List::Util qw(reduce);
use Path::Tiny;

use Test::More;
use Test::Deep;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

my $jieba = Lingua::ZH::Jieba->new();
ok( ( defined $jieba ), "Lingua::ZH::Jieba->new()" );

sub cut_ok {
    my ( $sentence, $opts, $expected, $msg ) = @_;

    my $words = $jieba->cut( $sentence, $opts );
    is( join( '/', @$words ), $expected, "cut() " . $msg );

    my $words_ex = $jieba->cut_ex( $sentence, $opts );
    is( join( '/', map { $_->[0] } @$words_ex ), $expected,
        "cut_ex() " . $msg );
    ok(
        (
            reduce { $a and $b } 1,
            map {
                my ( $word, $offset, $length ) = @$_;
                substr( $sentence, $offset, $length ) eq $word;
            } @$words_ex
        ),
        "cut_ex() offset and length correct"
    );
}

sub cut_for_search_ok {
    my ( $sentence, $opts, $expected, $msg ) = @_;

    my $words = $jieba->cut_for_search( $sentence, $opts );
    is( join( '/', @$words ), $expected, "cut_for_search() " . $msg );

    my $words_ex = $jieba->cut_for_search_ex( $sentence, $opts );
    is( join( '/', map { $_->[0] } @$words_ex ),
        $expected, "cut_for_search_ex() " . $msg );

    ok(
        (
            reduce { $a and $b } 1,
            map {
                my ( $word, $offset, $length ) = @$_;
                substr( $sentence, $offset, $length ) eq $word;
            } @$words_ex
        ),
        "cut_for_search_ex() offset and length correct"
    );
}

cut_ok(
    "他来到了网易杭研大厦", {},
    "他/来到/了/网易/杭研/大厦", "with HMM"
);

cut_ok(
    "他来到了网易杭研大厦", { no_hmm => 1 },
    "他/来到/了/网易/杭/研/大厦", "without HMM"
);

cut_ok(
    "我来到北京清华大学",
    { cut_all => 1 },
    "我/来到/北京/清华/清华大学/华大/大学", "all"
);

cut_for_search_ok(
"小明硕士毕业于中国科学院计算所，后在日本京都大学深造",
    {},
"小明/硕士/毕业/于/中国/科学/学院/科学院/中国科学院/计算/计算所/，/后/在/日本/京都/大学/日本京都大学/深造",
    ""
);

# insert user word
{
    cut_ok( "男默女泪", {}, "男默/女泪", "before insert 男默女泪" );

    $jieba->insert_user_word("男默女泪");

    cut_ok( "男默女泪", {}, "男默女泪", "after insert 男默女泪" );
}

# part-of-speech tagging
{
    my $sentence =
      "我是蓝翔技工拖拉机学院手扶拖拉机专业的。";
    my $words = $jieba->tag($sentence);
    is_deeply(
        $words,
        [
            [ "我",             "r" ],
            [ "是",             "v" ],
            [ "蓝翔",          "nz" ],
            [ "技工",          "n" ],
            [ "拖拉机",       "n" ],
            [ "学院",          "n" ],
            [ "手扶拖拉机", "n" ],
            [ "专业",          "n" ],
            [ "的",             "uj" ],
            [ "。",             "x" ],
        ],
        "part-of-speech tagging"
    );
}

# keyword extractor
{
    my $extractor = $jieba->extractor();
    my $sentence =
"我是拖拉机学院手扶拖拉机专业的。不用多久，我就会升职加薪，当上CEO，走上人生巅峰。";
    my $word_scores = $extractor->extract( $sentence, 5 );
    for (@$word_scores) {
        $_->[1] = sprintf( "%.3f", $_->[1] );
    }

    is_deeply(
        $word_scores,
        [
            [ "CEO",             11.739 ],
            [ "升职",          10.856 ],
            [ "加薪",          10.643 ],
            [ "手扶拖拉机", 10.009 ],
            [ "巅峰",          '9.494' ],
        ],
        "extractor->extract()"
    );
}

# custom data
{
    my $default_user_dict_path =
      dist_file( 'Lingua-ZH-Jieba', 'dict/user.dict.utf8' );
    my $data = path($default_user_dict_path)->slurp_utf8;

    unlink( $data, qr/男默女泪/,
        "Not having the word in default user dict" );

    my $tempfile = Path::Tiny->tempfile;
    $tempfile->spew_utf8( $data . "\n男默女泪\n" );

    my $jieba_custom =
      Lingua::ZH::Jieba->new( { user_dict_path => $tempfile . "" } );
    ok( defined($jieba_custom), "custom user_dict_path" );
    cut_ok( "男默女泪", {},
        "男默女泪", "custom user_dict_path: cut with HMM" );
}

done_testing();
