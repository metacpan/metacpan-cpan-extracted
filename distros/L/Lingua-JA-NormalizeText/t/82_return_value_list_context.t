use strict;
use warnings;
use Lingua::JA::NormalizeText qw/:all/;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $normalizer1 = Lingua::JA::NormalizeText->new([qw/lc/]);
my $normalizer2 = Lingua::JA::NormalizeText->new([qw/uc/]);

is_deeply( [ test() ], [] );
is_deeply( [ $normalizer1->normalize() ], [undef] );
is_deeply( [ $normalizer2->normalize() ], [undef] );
is_deeply( [ wave2tilde() ], [undef] );
is_deeply( [ tilde2wave() ], [undef] );
is_deeply( [ wavetilde2long() ], [undef] );
is_deeply( [ wave2long() ], [undef] );
is_deeply( [ tilde2long() ], [undef] );
is_deeply( [ fullminus2long() ], [undef] );
is_deeply( [ dashes2long() ], [undef] );
is_deeply( [ drawing_lines2long() ], [undef] );
is_deeply( [ unify_long_repeats() ], [undef] );
is_deeply( [ unify_long_spaces() ], [undef] );
is_deeply( [ unify_whitespaces() ], [undef] );
is_deeply( [ trim() ], [undef] );
is_deeply( [ ltrim() ], [undef] );
is_deeply( [ rtrim() ], [undef] );
is_deeply( [ nl2space() ], [undef] );
is_deeply( [ unify_nl() ], [undef] );
is_deeply( [ tab2space() ], [undef] );
is_deeply( [ old2new_kana() ], [undef] );
is_deeply( [ remove_controls() ], [undef] );
is_deeply( [ remove_spaces() ], [undef] );
is_deeply( [ remove_DFC() ], [undef] );
is_deeply( [ old2new_kanji() ], [ undef ] );
is_deeply( [ decompose_parenthesized_kanji() ], [ undef ] );

sub test { return; }

done_testing;
