use Test2::V0;
use File::Spec;

use File::Open qw(
    fopen    fopen_nothrow
    fsysopen fsysopen_nothrow
    fopendir fopendir_nothrow
);

my $file = File::Spec->catfile(File::Spec->tmpdir, 'AAAAAAAA');

like $_, qr/^Not enough arguments / for
    dies { fopen },
    dies { fopen_nothrow },
    dies { fsysopen },
    dies { fsysopen_nothrow },
    dies { fsysopen $file },
    dies { fsysopen_nothrow $file },
    dies { fopendir },
    dies { fopendir_nothrow },
;

like $_, qr/^Too many arguments / for
    dies { fopen 1, 2, 3, 4 },
    dies { fopen_nothrow 1, 2, 3, 4 },
    dies { fsysopen 1, 2, 3, 4 },
    dies { fsysopen_nothrow 1, 2, 3, 4 },
    dies { fopendir 1, 2 },
    dies { fopendir_nothrow 1, 2 },
;

like $_, qr/^Unknown fopen\(\) mode / for
    dies { fopen $file, 'c' },
    dies { fopen $file, '' },
    dies { fopen $file, '0' },
    dies { fopen $file, '1' },
    dies { fopen $file, 'b' },
    dies { fopen $file, '|-' },
    dies { fopen $file, '<&' },
    dies { fopen $file, '<&' },
    dies { fopen $file, '<&=' },
    dies { fopen $file, 'b+r' },
    dies { fopen $file, 'br' },
    dies { fopen $file, '+a' },
    dies { fopen $file, '<+' },
    dies { fopen $file, '>+' },
;

like $_, qr/^Unknown fopen_nothrow\(\) mode / for
    dies { fopen_nothrow $file, 'c' },
    dies { fopen_nothrow $file, '' },
    dies { fopen_nothrow $file, '0' },
    dies { fopen_nothrow $file, '1' },
    dies { fopen_nothrow $file, 'b' },
    dies { fopen_nothrow $file, '|-' },
    dies { fopen_nothrow $file, '<&' },
    dies { fopen_nothrow $file, '<&' },
    dies { fopen_nothrow $file, '<&=' },
    dies { fopen_nothrow $file, 'b+r' },
    dies { fopen_nothrow $file, 'br' },
    dies { fopen_nothrow $file, '+a' },
    dies { fopen_nothrow $file, '<+' },
    dies { fopen_nothrow $file, '>+' },
;

like $_, qr/^Unknown fsysopen\(\) mode / for
    dies { fsysopen $file, '' },
    dies { fsysopen $file, '0' },
    dies { fsysopen $file, '1' },
    dies { fsysopen $file, 'a' },
    dies { fsysopen $file, '<' },
    dies { fsysopen $file, '>' },
    dies { fsysopen $file, 'O_RDONLY' },
    dies { fsysopen $file, 'rb' },
    dies { fsysopen $file, 'br' },
    dies { fsysopen $file, 'b' },
    dies { fsysopen $file, {} },
;

like $_, qr/^Unknown fsysopen_nothrow\(\) mode / for
    dies { fsysopen_nothrow $file, '' },
    dies { fsysopen_nothrow $file, '0' },
    dies { fsysopen_nothrow $file, '1' },
    dies { fsysopen_nothrow $file, 'a' },
    dies { fsysopen_nothrow $file, '<' },
    dies { fsysopen_nothrow $file, '>' },
    dies { fsysopen_nothrow $file, 'O_RDONLY' },
    dies { fsysopen_nothrow $file, 'rb' },
    dies { fsysopen_nothrow $file, 'br' },
    dies { fsysopen_nothrow $file, 'b' },
    dies { fsysopen_nothrow $file, {} },
;

like $_, qr/^Unknown fsysopen\(\) flag / for
    dies { fsysopen $file, 'r', { '' => 0 } },
    dies { fsysopen $file, 'r', { '0' => 0 } },
    dies { fsysopen $file, 'r', { '1' => 0 } },
    dies { fsysopen $file, 'r', { '128' => 0 } },
    dies { fsysopen $file, 'r', { 'O_APPEND' => 0 } },
    dies { fsysopen $file, 'r', { 'Append' => 0 } },
    dies { fsysopen $file, 'r', { 'append' => 1, 'rdwr' => 1 } },
    dies { fsysopen $file, 'r', { 'append' => 1, 'rdwr' => 0, 'excl' => 1 } },
    dies { fsysopen $file, 'r', { 'append' => 1, 'excl' => 0, 'rdonly' => 1 } },
;

like $_, qr/^Unknown fsysopen_nothrow\(\) flag / for
    dies { fsysopen_nothrow $file, 'r', { '' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { '0' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { '1' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { '128' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { 'O_APPEND' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { 'Append' => 0 } },
    dies { fsysopen_nothrow $file, 'r', { 'append' => 1, 'rdwr' => 1 } },
    dies { fsysopen_nothrow $file, 'r', { 'append' => 1, 'rdwr' => 0, 'excl' => 1 } },
    dies { fsysopen_nothrow $file, 'r', { 'append' => 1, 'excl' => 0, 'rdonly' => 1 } },
;

done_testing;
