# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
#   plan skip_all => "Perl 5.8.1 or better is required to test this" unless ( $] >= 5.008001 );
    plan tests => 18;
    use_ok('Lingua::JA::Romanize::Japanese');
    my $roman = Lingua::JA::Romanize::Japanese->new();
    &test_ja( $roman );
}
# ----------------------------------------------------------------
sub read_data {
    local $/ = undef;
    my $all = <DATA>;
#   utf8::decode( $all );
    my $hash = { split( /\s+/, $all ) };
    $hash;
}
# ----------------------------------------------------------------
sub test_ja {
    my $roman = shift;
    ok( ref $roman, "new" );

    my $t = &read_data();
#   ok( utf8::is_utf8($t->{phrase1}), "source: phrase1 utf8 flaged" );
#   ok( utf8::is_utf8($t->{phrase2}), "source: phrase2 utf8 flaged" );

    my $c1 = $roman->char($t->{a});
    ok( ! defined $c1, "char: ascii" );
    
    my $c2 = $roman->char($t->{hi});
    is( $c2, "hi", "char: hiragana hi" );
    
    my $c3 = $roman->char($t->{ka});
    is( $c3, "ka", "char: katakana ka" );

    my $c4 = $roman->char($t->{kan});
    like( $c4, qr/(^|\W)kan(\W|$)/, "char: kanji kan" );

    my $c5 = $roman->chars($t->{hello});
    $c5 =~ s/\s+//g;
    $c5 =~ tr/A-Z/a-z/;
    is( $c5 , "hello,world!", "chars: hello" );

    my $c6 = $roman->chars($t->{nihongo});
    $c6 =~ s/\s+//g;
    like( $c6, qr/^(nihongo|nippongo|\/)+$/, "chars: nihongo" );

    my @t1 = $roman->string($t->{kanji});
    like( $t1[0][1], qr/(^|\W)kanji(\W|$)/, "string: okuri-nashi kanji" );

    my @t2 = $roman->string($t->{warau});
    like( $t2[0][1], qr/(^|\W)wara(u)?(\W|$)/, "string: okuri-ari warau" );

    my @t3 = $roman->string($t->{aru});
    like( $t3[0][1], qr/(^|\W)a(ru)?(\W|$)/, "string: okuri-ari aru" );

    my @t4 = $roman->string($t->{yuu});
    like( $t4[0][1], qr/(^|\W)(yuu|u)(\W|$)/, "string: okuri-nashi yuu or u" );

    my @t5 = $roman->string($t->{sashidasu});
    like( $t5[0][1], qr/(^|\W)sashida(su)?(\W|$)/, "string: okuri-ari sashidasu" );

    my @t6 = $roman->string($t->{sashidashinin});
    like( $t6[0][1], qr/(^|\W)sashidashinin(\W|$)/, "string: okuri-nashi sashidashinin" );

    my @u1 = $roman->string($t->{phrase1});
    like( $u1[0]->[1], qr/^u/, "string: phrase1 u..." );
    like( $u1[$#u1]->[1], qr/go$/, "string: phrase1 ...go" );
#   my $u1 = scalar { grep { ! utf8::is_utf8($_->[0]) } @u1 };
#   ok( $u1 >= 2, "string: phrase1 utf8 flaged" );
    my $j1 = join( "", map {$_->[0]} @u1 );
    is( $j1, $t->{phrase1}, "string: phrase1 round trip" );

    my @u2 = $roman->string($t->{phrase2});
#   my $u2 = scalar { grep { ! utf8::is_utf8($_->[0]) } @u2 };
#   ok( $u2 >= 6, "string: phrase2 utf8 flaged" );
    my $j2 = join( "", map {$_->[0]} @u2 );
    is( $j2, $t->{phrase2}, "string: phrase2 round trip" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
__END__
a               a
hi              ひ
ka              カ
kan             漢
hello           Hello,world!
nihongo         日本語
kanji           漢字
warau           笑う
aru             有る
yuu             有
sashidasu       差出す
sashidashinin   差出人
phrase1         美しい日本語
phrase2         太郎はこの本を二郎を見た女性に渡した。
