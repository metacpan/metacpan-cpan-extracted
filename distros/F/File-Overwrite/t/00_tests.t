#!/usr/bin/perl -w

my $loaded;
my $r;

use strict;

BEGIN { $| = 1; print "1..5\n"; }
END { print "not ok 1\n" unless $loaded; }

use File::Overwrite qw(overwrite overwrite_and_unlink);

$loaded=1;
my $test = 0;
print "ok ".(++$test)." load and compile\n";

open(FILE, '>t/foo') || die("Yow! can't write temp file for testing\n");
print FILE '123456789';
close(FILE);

my $inode = (stat('t/foo'))[1];

overwrite 't/foo';
print 'not ' unless(-s 't/foo' == 9);
print 'ok '.(++$test)." overwritten file is the right length\n";
print 'not ' unless($inode == (stat('t/foo'))[1]);
print 'ok '.(++$test)." overwritten file has right inode number\n";

open(FOO, 't/foo');
my $foo = <FOO>;
print 'not ' if($foo =~ /[^X]/);
print 'ok '.(++$test)." and was overwritten\n";
close(FOO);

open(FILE, '>t/foo') || die("Yow! can't write temp file for testing\n");
print FILE '123456789';
close(FILE);

overwrite_and_unlink 't/foo';
print 'not ' if(-e 't/foo');
print 'ok '.(++$test)." file was unlinked\n";
