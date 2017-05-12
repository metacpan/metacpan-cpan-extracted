use strict;
use warnings;
use utf8;
use Lingua::JA::NormalizeText qw/nfkc nfkd nfc nfd/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

is( nfkc('ｶﾞ'), "\x{30AC}",         'NFKC' );
is( nfkd('ｶﾞ'), "\x{30AB}\x{3099}", 'NFKD' );
is( nfc('ド'),  "\x{30C9}",         'NFC' );
is( nfd('ド'),  "\x{30C8}\x{3099}", 'NFD' );

my $normalizer = Lingua::JA::NormalizeText->new(qw/nfkc/);
is($normalizer->normalize('㌻' x 2), 'ページ' x 2, 'NFKC normalizer');

done_testing;
