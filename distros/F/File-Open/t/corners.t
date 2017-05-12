use strict;
use warnings;

use Test::More tests => 82;

use Test::Fatal;
use File::Spec;

use File::Open qw(
    fopen    fopen_nothrow
    fsysopen fsysopen_nothrow
    fopendir fopendir_nothrow
);

my $file = File::Spec->catfile(File::Spec->tmpdir, 'AAAAAAAA');

like $_, qr/^Not enough arguments / for
    exception { fopen },
    exception { fopen_nothrow },
    exception { fsysopen },
    exception { fsysopen_nothrow },
    exception { fsysopen $file },
    exception { fsysopen_nothrow $file },
    exception { fopendir },
    exception { fopendir_nothrow },
;

like $_, qr/^Too many arguments / for
    exception { fopen 1, 2, 3, 4 },
    exception { fopen_nothrow 1, 2, 3, 4 },
    exception { fsysopen 1, 2, 3, 4 },
    exception { fsysopen_nothrow 1, 2, 3, 4 },
    exception { fopendir 1, 2 },
    exception { fopendir_nothrow 1, 2 },
;

like $_, qr/^Unknown fopen\(\) mode / for
    exception { fopen $file, 'c' },
    exception { fopen $file, '' },
    exception { fopen $file, '0' },
    exception { fopen $file, '1' },
    exception { fopen $file, 'b' },
    exception { fopen $file, '|-' },
    exception { fopen $file, '<&' },
    exception { fopen $file, '<&' },
    exception { fopen $file, '<&=' },
    exception { fopen $file, 'b+r' },
    exception { fopen $file, 'br' },
    exception { fopen $file, '+a' },
    exception { fopen $file, '<+' },
    exception { fopen $file, '>+' },
;

like $_, qr/^Unknown fopen_nothrow\(\) mode / for
    exception { fopen_nothrow $file, 'c' },
    exception { fopen_nothrow $file, '' },
    exception { fopen_nothrow $file, '0' },
    exception { fopen_nothrow $file, '1' },
    exception { fopen_nothrow $file, 'b' },
    exception { fopen_nothrow $file, '|-' },
    exception { fopen_nothrow $file, '<&' },
    exception { fopen_nothrow $file, '<&' },
    exception { fopen_nothrow $file, '<&=' },
    exception { fopen_nothrow $file, 'b+r' },
    exception { fopen_nothrow $file, 'br' },
    exception { fopen_nothrow $file, '+a' },
    exception { fopen_nothrow $file, '<+' },
    exception { fopen_nothrow $file, '>+' },
;

like $_, qr/^Unknown fsysopen\(\) mode / for
    exception { fsysopen $file, '' },
    exception { fsysopen $file, '0' },
    exception { fsysopen $file, '1' },
    exception { fsysopen $file, 'a' },
    exception { fsysopen $file, '<' },
    exception { fsysopen $file, '>' },
    exception { fsysopen $file, 'O_RDONLY' },
    exception { fsysopen $file, 'rb' },
    exception { fsysopen $file, 'br' },
    exception { fsysopen $file, 'b' },
    exception { fsysopen $file, {} },
;

like $_, qr/^Unknown fsysopen_nothrow\(\) mode / for
    exception { fsysopen_nothrow $file, '' },
    exception { fsysopen_nothrow $file, '0' },
    exception { fsysopen_nothrow $file, '1' },
    exception { fsysopen_nothrow $file, 'a' },
    exception { fsysopen_nothrow $file, '<' },
    exception { fsysopen_nothrow $file, '>' },
    exception { fsysopen_nothrow $file, 'O_RDONLY' },
    exception { fsysopen_nothrow $file, 'rb' },
    exception { fsysopen_nothrow $file, 'br' },
    exception { fsysopen_nothrow $file, 'b' },
    exception { fsysopen_nothrow $file, {} },
;

like $_, qr/^Unknown fsysopen\(\) flag / for
    exception { fsysopen $file, 'r', { '' => 0 } },
    exception { fsysopen $file, 'r', { '0' => 0 } },
    exception { fsysopen $file, 'r', { '1' => 0 } },
    exception { fsysopen $file, 'r', { '128' => 0 } },
    exception { fsysopen $file, 'r', { 'O_APPEND' => 0 } },
    exception { fsysopen $file, 'r', { 'Append' => 0 } },
    exception { fsysopen $file, 'r', { 'append' => 1, 'rdwr' => 1 } },
    exception { fsysopen $file, 'r', { 'append' => 1, 'rdwr' => 0, 'excl' => 1 } },
    exception { fsysopen $file, 'r', { 'append' => 1, 'excl' => 0, 'rdonly' => 1 } },
;

like $_, qr/^Unknown fsysopen_nothrow\(\) flag / for
    exception { fsysopen_nothrow $file, 'r', { '' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { '0' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { '1' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { '128' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { 'O_APPEND' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { 'Append' => 0 } },
    exception { fsysopen_nothrow $file, 'r', { 'append' => 1, 'rdwr' => 1 } },
    exception { fsysopen_nothrow $file, 'r', { 'append' => 1, 'rdwr' => 0, 'excl' => 1 } },
    exception { fsysopen_nothrow $file, 'r', { 'append' => 1, 'excl' => 0, 'rdonly' => 1 } },
;

