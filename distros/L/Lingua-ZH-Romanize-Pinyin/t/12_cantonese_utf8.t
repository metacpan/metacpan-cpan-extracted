# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan skip_all => "Perl 5.8.1 or better is required to test this" unless ( $] >= 5.008001 );
    plan tests => 20;
    use_ok('Lingua::ZH::Romanize::Cantonese');
    my $roman = Lingua::ZH::Romanize::Cantonese->new();
    &test_zh( $roman );
}
# ----------------------------------------------------------------
sub read_data {
    local $/ = undef;
    my $all = <DATA>;
    utf8::decode( $all );
    my $hash = { split( /\s+/, $all ) };
    $hash;
}
# ----------------------------------------------------------------
sub test_zh {
    my $roman = shift;
    ok( ref $roman, "new" );

    my $t = &read_data();
    ok( utf8::is_utf8($t->{hello}), "source: hello utf8 flaged" );

    my $c1 = $roman->char("a");
    ok( ! defined $c1, "char: ascii" );

    my $c2 = $roman->char($t->{hon1});
    is( $c2, "hon", "char: hon (big5)" );

    my $c3 = $roman->char($t->{hon2});
    is( $c3, "hon",  "char: hon (gb2312)" );

    my $c4 = $roman->chars($t->{honyue1});
    is( $c4, "hon yue", "chars: honyue (big5)" );

    my $c5 = $roman->chars($t->{honyue2});
    is( $c5, "hon yue", "chars: honyue (gb2312)" );

    my @u0 = $roman->string($t->{hello});
    is( $u0[0][1], "nei", "string: nei" );
    is( $u0[1][1], "ho",  "string: ho" );

    my @u1 = $roman->string($t->{photo1});
    is( scalar(@u1), 8, "string: photo1 length" );
    like( $u1[0]->[1], qr/nei/, "string: photo1 nei..." );
    like( $u1[$#u1]->[1], qr/ma/, "string: photo1 ...ma" );
    my $u1 = scalar grep { utf8::is_utf8($_->[0]) } @u1;
    is( $u1, 8, "string: photo1 utf8 flaged" );
    my $j1 = join( "", map {$_->[0]} @u1 );
    is( $j1, $t->{photo1}, "string: photo1 round trip" );

    my @u2 = $roman->string($t->{photo2});
    is( scalar(@u2), 8, "string: photo2 length" );
    like( $u2[0]->[1], qr/^nei/, "string: photo2 nei..." );
    like( $u2[$#u2]->[1], qr/^ma/, "string: photo2 ...ma" );
    my $u2 = scalar grep { utf8::is_utf8($_->[0]) } @u2;
    is( $u2, 8, "string: photo2 utf8 flaged" );
    my $j2 = join( "", map {$_->[0]} @u2 );
    is( $j2, $t->{photo2}, "string: photo2 round trip" );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
__END__
hon1    漢
hon2    汉
honyue1 漢語
honyue2 汉语
hello   你好
photo1  您可以给我拍照吗
photo2  您可以給我拍照嗎
