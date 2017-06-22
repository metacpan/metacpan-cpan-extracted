#!perl

use strict;
use warnings;

use Test::Most tests => 17;
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
my $fh;
($fh, $filename) = pfopen($tmpdir, 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen($tmpdir, 'pfopen', 'txt:baz');
ok(<$fh> eq "Hello, world\n");
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(defined(pfopen("/:$tmpdir", 'pfopen', 'bar:txt')));
($fh, $filename) = pfopen("/:$tmpdir", 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen("/:$tmpdir", 'pfopen', 'bar:txt');
ok(<$fh> eq "Hello, world\n");
ok(!defined(pfopen('/', 'pfopen', 'txt')));
ok(!defined(pfopen("/:$tmpdir", 'pfopen')));
ok(defined(pfopen($tmpdir, 'pfopen.txt')));
($fh, $filename) = pfopen("/:$tmpdir", 'pfopen.txt');
ok(<$fh> eq "Hello, world\n");
ok($filename =~ /pfopen\.txt$/);
$fh = pfopen("/:$tmpdir", 'pfopen.txt');
ok(<$fh> eq "Hello, world\n");
