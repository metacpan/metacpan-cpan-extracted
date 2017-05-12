#!perl

use strict;
use warnings;

use Test::More qw(no_plan);
use File::Basename qw(fileparse_set_fstype);

use_ok('File::Basename::Object');

fileparse_set_fstype('Unix');

my($f1, $f2);

# basic basename ops
$f1 = File::Basename::Object->new("/path/to/foo.txt", ".txt");
is("$f1", "/path/to/foo.txt", "stringification");
is($f1->basename, "foo", "basename");
is($f1->dirname, "/path/to", "dirname");
is_deeply([$f1->fileparse], ["foo", "/path/to/", ".txt"], "fileparse");

# fancier stuff
$f2 = $f1->copy;
ok($f1 eq $f2, "compare full paths");
$f2 = $f1->copy("/other/path/to/foo.txt");
ok($f2 eq "/other/path/to/foo.txt", "reassignment");
ok($f1 ne $f2, "!compare full paths");
ok($f1 eq "/path/to/foo.txt", "compare full path with literal");
ok("/path/to/foo.txt", "compare full path with literal (backwards)");
ok($f1 == $f2, "compare basenames");
ok($f1 == "foo", "compare basename with literal");
ok("foo" == $f1, "compare basename with literal (backwards)");
is_deeply([$f2->suffixlist(qr{\.ba.})], [".txt"], "suffixes");
ok($f1 != $f2, "mismatched suffix");
is($f2->fullname("/other/path/to/foo.bar"), "/other/path/to/foo.txt", "path");
ok($f1 == $f2, "rematched suffix");
is_deeply([$f2->no_suffixes], [qr{\.ba.}], "no_suffixes");
is("$f2", "/other/path/to/foo.bar", "no_suffixes takes effect");
