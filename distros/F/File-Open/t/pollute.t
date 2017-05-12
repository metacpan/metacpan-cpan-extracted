use strict;
use warnings;

use Test::More tests => 12;

use File::Open;

ok defined &File::Open::fopen;
ok defined &File::Open::fopen_nothrow;
ok defined &File::Open::fsysopen;
ok defined &File::Open::fsysopen_nothrow;
ok defined &File::Open::fopendir;
ok defined &File::Open::fopendir_nothrow;

ok !exists &fopen;
ok !exists &fopen_nothrow;
ok !exists &fsysopen;
ok !exists &fsysopen_nothrow;
ok !exists &fopendir;
ok !exists &fopendir_nothrow;
