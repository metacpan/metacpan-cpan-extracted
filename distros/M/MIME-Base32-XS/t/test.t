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

done_testing;
