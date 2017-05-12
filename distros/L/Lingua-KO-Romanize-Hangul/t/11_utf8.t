# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    plan skip_all => "Perl 5.8.1 or better is required to test this" unless ( $] >= 5.008001 );
    plan tests => 14;
    use_ok('Lingua::KO::Romanize::Hangul');
    my $roman = Lingua::KO::Romanize::Hangul->new();
    &test_ko( $roman );
}
# ----------------------------------------------------------------
sub test_ko {
    my $roman = shift;
    ok( ref $roman, "new" );

    eval '
        ok( (! defined $roman->char("\x{0061}")), "char: ascii (0061)" );
        is( $roman->char("\x{AC00}"), "ga", "char: ga (AC00)" );
        is( $roman->char("\x{D7A3}"), "hih", "char: hih (D7A3)" );

        my $c4 = $roman->chars("\x{C5EC}\x{BCF4}\x{C138}\x{C694}");
        is( $c4, "yeo bo se yo", "chars: yeoboseyo" );

        my @s1 = $roman->string("\xED\x95\x9C\xEA\xB8\x80");
        is( $s1[0][1], "han", "string: han (octets)" );
        ok( ! utf8::is_utf8($s1[0][0]), "string: han utf8 flag off" );
        is( $s1[1][1], "geul", "string: geul (octets)" );
        ok( ! utf8::is_utf8($s1[1][0]), "string: geul utf8 flag off" );

        my @s2 = $roman->string("\x{D55C}\x{AE00}");
        is( $s2[0][1], "han", "string: han (string)" );
        ok( utf8::is_utf8($s2[0][0]), "string: han utf8 flag on" );
        is( $s2[1][1], "geul", "string: geul (string)" );
        ok( utf8::is_utf8($s2[1][0]), "string: geul utf8 flag on" );
    ';
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
