use strict;
use warnings;
use Groonga::API::Test;

plan skip_all => "grn_string was first introduced at 2.0.4" unless version_ge("2.0.4");

db_test(sub {
  my ($ctx, $db) = @_;

  my $org =
    "Groongaは組み込み型の全文検索エンジンです。DBMSやスクリプト言語処理系等に\n" .
    "組み込むことによって、その全文検索機能を強化することができます。n-gram\n" .
    "インデックスと単語インデックスの特徴を兼ね備えた、高速かつ高精度な転置\n" .
    "インデックスタイプのエンジンです。コンパクトな実装ですが、大規模な文書\n" .
    "量と検索要求を処理できるように設計されています。また、純粋なn-gramイン\n" .
    "デックスの作成も可能です。";

  my $normalized =
    "groongaは組み込み型の全文検索エンジンです。dbmsやスクリプト言語処理系等に" .
    "組み込むことによって、その全文検索機能を強化することができます。n-gram" .
    "インデックスと単語インデックスの特徴を兼ね備えた、高速かつ高精度な転置" .
    "インデックスタイプのエンジンです。コンパクトな実装ですが、大規模な文書" .
    "量と検索要求を処理できるように設計されています。また、純粋なn-gramイン" .
    "デックスの作成も可能です。";

  my $normalizer = Groonga::API::ctx_get($ctx, "NormalizerAuto", -1);
  ok defined $normalizer, "normalizer";

  my $flags = GRN_STRING_WITH_TYPES|GRN_STRING_WITH_CHECKS;
  my $str = Groonga::API::string_open($ctx, $org, bytes::length($org), $normalizer, $flags);
  ok defined $str, "opened";
  is ref $str => "Groonga::API::obj", "correct object";

  {
    my $rc = Groonga::API::string_get_original($ctx, $str, my $got, my $len);
    is $rc => GRN_SUCCESS, "got original";
    is $got => $org, "correct string";
    is $len => bytes::length($org), "correct length";
  }

  {
    my $int = Groonga::API::string_get_flags($ctx, $str);
    is $int => $flags, "correct flags";
  }

  my $chars;
  {
    my $rc = Groonga::API::string_get_normalized($ctx, $str, my $got, my $len, $chars);
    is $rc => GRN_SUCCESS, "got normalized";
    is $got => $normalized, "correct string";
    is $len => bytes::length($normalized), "correct length";
    ok $chars, "characters: $chars";
  }

  {
    my $checks = Groonga::API::string_get_checks($ctx, $str);
    ok defined $checks, "checks";
  }

  {
    my $type_str = Groonga::API::string_get_types($ctx, $str);
    ok defined $type_str, "got types";
    my @types = unpack 'C*', $type_str;
    is @types => $chars, "num of types";
    my @map = qw(
      null alpha digit symbol hiragana
      katakana kanji others
    );
    note join ',', map {Groonga::API::CHAR_IS_BLANK($_) ? 'blank' : $map[Groonga::API::CHAR_TYPE($_)] || "unknown: $_"} @types;
  }

  {
    my $encoding = Groonga::API::string_get_encoding($ctx, $str);
    is $encoding => GRN_ENC_UTF8, "correct encoding";
  }

  Groonga::API::obj_unlink($ctx, $str);
});

# XXX: Groonga::API::string_set_normalized()
# XXX: Groonga::API::string_set_checks()
# XXX: Groonga::API::string_set_types()

done_testing;
