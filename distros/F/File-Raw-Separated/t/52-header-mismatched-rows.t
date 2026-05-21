use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Row arity > header arity: croaks
my $rc = eval {
    file_csv_parse_buf("a,b\n1,2,3\n", { header => 1 });
    1;
};
ok(!$rc, 'row longer than header croaks');
like($@, qr/3 field|field.*3.*header/i, 'error mentions arity mismatch')
    or diag("got: $@");

# Row arity < header arity: missing keys default to undef
my $r = file_csv_parse_buf("a,b,c\n1,2\n", { header => 1 });
is_deeply(
    $r,
    [{ a => 1, b => 2, c => undef }],
    'row shorter than header pads missing keys with undef',
);

# All-empty body row
my $r2 = file_csv_parse_buf("a,b,c\n,,\n", { header => 1 });
is_deeply(
    $r2,
    [{ a => '', b => '', c => '' }],
    'empty fields stay empty strings (no header-mode special case)',
);

done_testing;
