# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan tests => 17;
    use_ok('Lingua::ZH::Romanize::Pinyin');
    my $roman = Lingua::ZH::Romanize::Pinyin->new();
    &test_zh( $roman );
}
# ----------------------------------------------------------------
sub read_data {
    local $/ = undef;
    my $all = <DATA>;
    my $hash = { split( /\s+/, $all ) };
    $hash;
}
# ----------------------------------------------------------------
sub test_zh {
    my $roman = shift;
    ok( ref $roman, "new" );

    my $t = &read_data();

    my $c1 = $roman->char("a");
    ok( ! defined $c1, "char: ascii" );

    my $c2 = $roman->char($t->{han1});
    is( $c2, "han4", "char: han (big5)" );

    my $c3 = $roman->char($t->{han2});
    is( $c3, "han",  "char: han (gb2312)" );

    my $c4 = $roman->chars($t->{hanyu1});
    is( $c4, "han4 yu3/yu4", "chars: hanyu (big5)" );

    my $c5 = $roman->chars($t->{hanyu2});
    is( $c5, "han yu", "chars: hanyu (gb2312)" );

    my @u0 = $roman->string($t->{hello});
    is( $u0[0][1], "ni3",       "string: ni" );
    is( $u0[1][1], "hao3/hao4", "string: hao" );

    my @u1 = $roman->string($t->{photo1});
    is( scalar(@u1), 8, "string: photo1 length" );
    like( $u1[0]->[1], qr/ni/, "string: photo1 ni..." );
    like( $u1[$#u1]->[1], qr/ma/, "string: photo1 ...ma" );
    my $j1 = join( "", map {$_->[0]} @u1 );
    is( $j1, $t->{photo1}, "string: photo1 round trip" );

    my @u2 = $roman->string($t->{photo2});
    is( scalar(@u2), 8, "string: photo2 length" );
    like( $u2[0]->[1], qr/^ni/, "string: photo2 ni..." );
    like( $u2[$#u2]->[1], qr/^ma/, "string: photo2 ...ma" );
    my $j2 = join( "", map {$_->[0]} @u2 );
    is( $j2, $t->{photo2}, "string: photo2 round trip" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
__END__
han1    漢
han2    汉
hanyu1  漢語
hanyu2  汉语
hello   你好
photo1  您可以给我拍照吗
photo2  您可以給我拍照嗎
