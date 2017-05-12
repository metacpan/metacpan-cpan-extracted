use strict;
use warnings;
use Test::More tests => 8;
use Encode qw(encode);

use charnames qw(:full);
use Encode::Repair qw(learn_recoding repair_encoding);

is_deeply learn_recoding( from => '1', to => '1', encodings => ['Latin-1']),
          [], 'empty array if from eq to';

ok !defined(learn_recoding( from => '1', to => '2', encodings => ['Latin-1'])),
            'different strings go to undef';

my $str = "\N{LATIN SMALL LETTER A WITH DIAERESIS}";

my $res = learn_recoding(
        from        => encode('UTF-8', $str),
        to          => $str,
        encodings   => ['UTF-8', 'Latin-1'],
);

is_deeply $res, ['decode', 'UTF-8'], 'Can detect UTF-8 decoding';

$res = learn_recoding(
        from        => $str,
        to          => encode('UTF-8', $str),
        encodings   => ['UTF-8', 'Latin-1'],
);

is_deeply $res, ['encode', 'UTF-8'], 'Can detect UTF-8 encoding';

$res = learn_recoding(
        from        => "small ae: \xc3\x83\xc2\xa4",
        to          => "small ae: \N{LATIN SMALL LETTER A WITH DIAERESIS}",
        encodings   => ['UTF-8', 'Latin-1', 'Latin-7'],
);

#is_deeply $res, ['decode', 'UTF-8', 'encode', 'Latin-1', 'decode', 'UTF-8'],
#          'Can detect double encoding via Latin-1';


is repair_encoding("small ae: \xc3\x83\xc2\xa4", $res),
    "small ae: \N{LATIN SMALL LETTER A WITH DIAERESIS}",
    'Can repair double encoding via Latin-1 with autodetection';

TODO: {
    $res = learn_recoding(
            from        => encode('UTF-8', $str),
            to          => $str,
            encodings   => ['UTF-8', 'UTF-8'],
            search      => 'shallow',
    );
    cmp_ok scalar(@$res), '>=', 2,
        'Found at least two ways to decode UTF-8 when UTF-8 is provided twice';
};

$res = learn_recoding(
        from        => "beta: \xc4\xaa\xc2\xb2",
        to          => "beta: \N{GREEK SMALL LETTER BETA}",
        encodings   => ['UTF-8', 'Latin-1', 'Latin-7'],
);

is_deeply $res, ['decode', 'UTF-8', 'encode', 'Latin-7', 'decode', 'UTF-8'],
          'Can detect double encoding via Latin-7';
is repair_encoding("beta: \xc4\xaa\xc2\xb2", $res),
   "beta: \N{GREEK SMALL LETTER BETA}",
    'Can repair double encoding via Latin-7 with autodetection';

# vim: ts=4 sw=4 expandtab tw=80
