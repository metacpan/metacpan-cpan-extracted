use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/decompose_parenthesized_kanji/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $normalizer = Lingua::JA::NormalizeText->new(qw/decompose_parenthesized_kanji/);

my $all_parenthesized_kanji = '㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩㈪㈫㈬㈭㈮㈯㈰㈱㈲㈳㈴㈵㈶㈷㈸㈹㈺㈻㈼㈽㈾㈿㉀㉁㉂㉃';
is( length decompose_parenthesized_kanji($all_parenthesized_kanji), (length $all_parenthesized_kanji) * 3 );

is(decompose_parenthesized_kanji('㈠㈱㉃！'), '(一)(株)(至)！');
is($normalizer->normalize('㈠㈱㉃！' x 2), '(一)(株)(至)！' x 2);

done_testing;
