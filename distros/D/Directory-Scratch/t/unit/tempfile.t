#!/usr/bin/perl
# tempfile.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More tests => 8;
use Directory::Scratch;
use strict;
use warnings;

my $tmp = Directory::Scratch->new;
ok($tmp, 'created $tmp');
my ($fh, $filename) = $tmp->tempfile;
eval {
    print {$fh} "Foo\nbar\nbaz\n";
};
ok(!$@, 'writing to fh works');
ok(close $fh, 'closed fh');
ok(-e $filename, 'file exists');

# try this in scalar context
$fh = $tmp->tempfile;
ok($fh, 'got a filehandle');
ok(print {$fh} "A line\n");
ok(seek $fh, 0, 0);
is(<$fh>, "A line\n", 'read the line back');
