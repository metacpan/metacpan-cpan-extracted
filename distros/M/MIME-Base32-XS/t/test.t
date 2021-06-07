use Test::More;

use_ok('MIME::Base32::XS');

my $numbers = {
    '0' => 'GA======',
    '1' => 'GE======',
    '2' => 'GI======',
    '3' => 'GM======',
    '4' => 'GQ======',
    '5' => 'GU======',
    '6' => 'GY======',
    '7' => 'G4======',
    '8' => 'HA======',
    '9' => 'HE======'
};

for (keys %$numbers) {
    is(MIME::Base32::XS::encode_base32($_), $numbers->{$_}, "Encode number $_");

    is(MIME::Base32::XS::decode_base32($numbers->{$_}), $_, "Decode number $_");
}

my $chars = {
    'a' => 'ME======',
    'b' => 'MI======',
    'c' => 'MM======',
    'd' => 'MQ======',
    'e' => 'MU======',
    'f' => 'MY======',
    'g' => 'M4======',
    'h' => 'NA======',
    'i' => 'NE======',
    'j' => 'NI======',
    'k' => 'NM======',
    'l' => 'NQ======',
    'm' => 'NU======',
    'n' => 'NY======',
    'o' => 'N4======',
    'p' => 'OA======',
    'q' => 'OE======',
    'r' => 'OI======',
    's' => 'OM======',
    't' => 'OQ======',
    'u' => 'OU======',
    'v' => 'OY======',
    'w' => 'O4======',
    'x' => 'PA======',
    'y' => 'PE======',
    'z' => 'PI======',
    'A' => 'IE======',
    'B' => 'II======',
    'C' => 'IM======',
    'D' => 'IQ======',
    'E' => 'IU======',
    'F' => 'IY======',
    'G' => 'I4======',
    'H' => 'JA======',
    'I' => 'JE======',
    'J' => 'JI======',
    'K' => 'JM======',
    'L' => 'JQ======',
    'M' => 'JU======',
    'N' => 'JY======',
    'O' => 'J4======',
    'P' => 'KA======',
    'Q' => 'KE======',
    'R' => 'KI======',
    'S' => 'KM======',
    'T' => 'KQ======',
    'U' => 'KU======',
    'V' => 'KY======',
    'W' => 'K4======',
    'X' => 'LA======',
    'Y' => 'LE======',
    'Z' => 'LI======'
};

for (keys %$chars) {
    is(MIME::Base32::XS::encode_base32($_), $chars->{$_}, "Encode char $_");

    is(MIME::Base32::XS::decode_base32($chars->{$_}), $_, "Decode char $_");
}

my $specials = {
    '!' => 'EE======',
    '"' => 'EI======',
    '#' => 'EM======',
    '$' => 'EQ======',
    '%' => 'EU======',
    '&' => 'EY======',
    "'" => 'E4======',
    '(' => 'FA======',
    ')' => 'FE======',
    '*' => 'FI======',
    '+' => 'FM======',
    ',' => 'FQ======',
    '-' => 'FU======',
    '.' => 'FY======',
    '/' => 'F4======',
    ':' => 'HI======',
    ';' => 'HM======',
    '<' => 'HQ======',
    '=' => 'HU======',
    '>' => 'HY======',
    '?' => 'H4======',
    '@' => 'IA======',
    '[' => 'LM======',
    ']' => 'LU======',
    '^' => 'LY======',
    '_' => 'L4======',
    '`' => 'MA======',
    '{' => 'PM======',
    '|' => 'PQ======',
    '}' => 'PU======',
    '~' => 'PY======',
};

for (keys %$specials) {
    is(MIME::Base32::XS::encode_base32($_), $specials->{$_}, "Encode special $_");

    is(MIME::Base32::XS::decode_base32($specials->{$_}), $_, "Decode special $_");
}

my $text = qq{Lorem Ipsum has been the industry's standard dummy text ever since
the 1500s, when an unknown printer took a galley of type and scrambled it to make
a type specimen book. It has survived not only five centuries, but also the leap
into electronic typesetting, remaining essentially unchanged. It was popularised
in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages,
and more recently with desktop publishing software like Aldus PageMaker
including versions of Lorem Ipsum.};

my $encoded = qq{JRXXEZLNEBEXA43VNUQGQYLTEBRGKZLOEB2GQZJANFXGI5LTORZHSJ3TEBZXIYLOMRQXEZBAMR2W23LZEB2GK6DUEBSXMZLSEBZWS3TDMUFHI2DFEAYTKMBQOMWCA53IMVXCAYLOEB2W423ON53W4IDQOJUW45DFOIQHI33PNMQGCIDHMFWGYZLZEBXWMIDUPFYGKIDBNZSCA43DOJQW2YTMMVSCA2LUEB2G6IDNMFVWKCTBEB2HS4DFEBZXAZLDNFWWK3RAMJXW62ZOEBEXIIDIMFZSA43VOJ3GS5TFMQQG433UEBXW43DZEBTGS5TFEBRWK3TUOVZGSZLTFQQGE5LUEBQWY43PEB2GQZJANRSWC4AKNFXHI3ZAMVWGKY3UOJXW42LDEB2HS4DFONSXI5DJNZTSYIDSMVWWC2LONFXGOIDFONZWK3TUNFQWY3DZEB2W4Y3IMFXGOZLEFYQES5BAO5QXGIDQN5YHK3DBOJUXGZLEBJUW4IDUNBSSAMJZGYYHGIDXNF2GQIDUNBSSA4TFNRSWC43FEBXWMICMMV2HEYLTMV2CA43IMVSXI4ZAMNXW45DBNFXGS3THEBGG64TFNUQES4DTOVWSA4DBONZWCZ3FOMWAUYLOMQQG233SMUQHEZLDMVXHI3DZEB3WS5DIEBSGK43LORXXAIDQOVRGY2LTNBUW4ZZAONXWM5DXMFZGKIDMNFVWKICBNRSHK4ZAKBQWOZKNMFVWK4QKNFXGG3DVMRUW4ZZAOZSXE43JN5XHGIDPMYQEY33SMVWSASLQON2W2LQ=};

my $text_encoded = MIME::Base32::XS::encode_base32($text);
my $text_decoded = MIME::Base32::XS::decode_base32($text_encoded);

is($encoded, $text_encoded, 'Test text encode');
is($text_decoded, $text, 'Test text decode');

done_testing;
