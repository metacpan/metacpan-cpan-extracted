use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Strict croaks on stray quote mid-unquoted-field
my $rc = eval { file_csv_parse_buf(qq(a"b,c\n), { strict => 1 }) };
ok(!$rc, 'strict croaks on stray quote mid-field');
like($@, qr/quot/i, 'error mentions quoting');
like($@, qr/byte offset/, 'error includes byte offset');

# Lenient passes the same input through
is_deeply(
    file_csv_parse_buf(qq(a"b,c\n)),
    [['a"b', 'c']],
    'lenient: stray quote preserved literally',
);

# Strict croaks on stray-data-after-closing-quote
$rc = eval { file_csv_parse_buf(qq("a"x,b\n), { strict => 1 }) };
ok(!$rc, 'strict croaks on data after closing quote');
like($@, qr/quot/i);

# Lenient yields ax + b
is_deeply(
    file_csv_parse_buf(qq("a"x,b\n)),
    [['ax', 'b']],
    'lenient: data after closing quote merged into field',
);

done_testing;
