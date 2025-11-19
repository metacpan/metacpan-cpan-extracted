#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Spelling' => '0.17';
use Test::Spelling 0.17;

use Test2::Require::Module 'Pod::Wordlist';
use Pod::Wordlist;

add_stopwords(<DATA>);
all_pod_files_spelling_ok(qw( bin lib examples));
__DATA__
AnnoCPAN
CMD
FH
Readonly
SunOS
UTF
YYYYMMDD
ascii
buf
cmd
cmds
dir
dirs
fattr
ftypes
importables
lib
msg
noecho
readonly
rtn
v2
