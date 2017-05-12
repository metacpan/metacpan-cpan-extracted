# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan skip_all => "Perl 5.8.1 or better is required to test this" unless ( $] >= 5.008001 );
    local $@;
    eval { require Lingua::JA::Hepburn::Passport; };
    plan skip_all => "Lingua::JA::Hepburn::Passport is not available." if $@;
    plan tests => 12;
    use_ok('Lingua::JA::Romanize::Kana::Hepburn');
    my $roman = Lingua::JA::Romanize::Kana::Hepburn->new();
    &test_ja( $roman );
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
sub test_ja {
    my $roman = shift;
    ok( ref $roman, "new" );

    my $t = &read_data();
    ok( utf8::is_utf8($t->{phrase1}), "source: phrase1 utf8 flaged" );

    my $c1 = $roman->char($t->{a});
    ok( ! defined $c1, "char: ascii" );
    
    my $c2 = $roman->char($t->{hi});
    is( $c2, "hi", "char: hiragana hi" );
    
    my $c3 = $roman->char($t->{ka});
    is( $c3, "ka", "char: katakana ka" );

    my $c4 = $roman->char($t->{kan});
    ok( ! defined $c4, "char: kanji kan" );

    my $c5 = $roman->chars($t->{hello});
    $c5 =~ s/\s+//g;
    $c5 =~ tr/A-Z/a-z/;
    is( $c5 , "hello,world!", "chars: hello" );

    my @u1 = $roman->string($t->{phrase1});
    like( $u1[0]->[1], qr/^u/, "string: phrase1 u..." );
    like( $u1[$#u1]->[1], qr/go$/, "string: phrase1 ...go" );
    my $u1 = scalar { grep { ! utf8::is_utf8($_->[0]) } @u1 };
    ok( $u1, "string: phrase1 utf8 flaged" );
    my $j1 = join( "", map {$_->[0]} @u1 );
    is( $j1, $t->{phrase1}, "string: phrase1 round trip" );
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
phrase1         うつくしいにほんご
