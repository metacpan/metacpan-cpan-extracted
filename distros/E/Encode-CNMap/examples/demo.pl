    use Encode;
    use Encode::CNMap;
    no warnings;  # disable utf8 output warning
    my $data;

    $data = "中華中华";
    printf "Mix [GBK]  %s\n", $data;
    printf "   -> Simp[GB]   %s\n", simp_to_gb( $data );
    printf "   -> Trad[Big5] %s\n", simp_to_b5( $data );
    printf "   -> Mix [utf8] %s\n", simp_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", simp_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", simp_to_tradutf8( $data );

    $data = "い地い地";
    printf "Trad[Big5] %s\n", $data;
    printf "   -> Simp[GB]   %s\n", trad_to_gb( $data );
    printf "   -> Mix [GBK]  %s\n", trad_to_gbk( $data );
    printf "   -> Mix [utf8] %s\n", trad_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", trad_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", trad_to_tradutf8( $data );

    $data = Encode::decode("gbk", "中華中华");
    printf "Mix [utf8] %s\n", $data;
    printf "   -> Simp[GB]   %s\n", utf8_to_gb( $data );
    printf "   -> Mix [GBK]  %s\n", utf8_to_gbk( $data );
    printf "   -> Trad[Big5] %s\n", utf8_to_b5( $data );
    printf "   -> Mix [utf8] %s\n", utf8_to_utf8( $data );
    printf "   -> Simp[utf8] %s\n", utf8_to_simputf8( $data );
    printf "   -> Trad[utf8] %s\n", utf8_to_tradutf8( $data );
