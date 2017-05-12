#!perl

use strict;

use Test::Most tests => 11;
use Test::TempDir::Tiny;
use File::Spec;

use_ok('File::pfopen', ('pfopen'));

my $tmpdir = tempdir();
my $filename = File::Spec->catfile($tmpdir, 'pfopen.txt');
open(my $fout, '>', $filename);
print $fout "Hello, world\n";
close $fout;
ok(defined(pfopen($tmpdir, 'pfopen', 'txt')));
ok(!defined(pfopen($tmpdir, 'pfopen', 'bar')));
ok(defined(pfopen($tmpdir, 'pfopen', 'bar:txt')));
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(defined(pfopen("/:$tmpdir", 'pfopen', 'bar:txt')));
ok(defined(pfopen("/:$tmpdir", 'pfopen', 'bar:txt')));
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(!defined(pfopen("/:$tmpdir", 'pfopen')));
ok(defined(pfopen($tmpdir, 'pfopen.txt')));
ok(defined(pfopen("/:$tmpdir", 'pfopen.txt')));
