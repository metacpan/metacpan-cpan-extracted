use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;


my $text = 'アカサ㌍タなのです！';

my $normalizer = Lingua::JA::NormalizeText->new( (qw/nfkc/, \&sunoharize) );
is($normalizer->normalize($text), 'アカサカロリータなのです!それと便座カバー');

done_testing;


sub sunoharize { my $text = shift; $text .= "それと便座カバー"; return $text; }
