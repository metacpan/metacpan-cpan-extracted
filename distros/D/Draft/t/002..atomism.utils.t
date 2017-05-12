#!/usr/bin/perl

use lib qw (. lib);

use Test;
BEGIN { plan tests => 8 };

use File::Atomism::utils qw /Hostname Pid Inode Unixdate Dir File Extension/;

print "ok 1\n";

print "ok 2\n" if (Hostname =~ /^[a-z0-9._-]+$/i);
print "ok 3\n" if (Pid =~ /^[0-9]+$/);
print "ok 4\n" if (Inode ('t/data/01.yml') =~ /^[0-9]+$/);
print "ok 5\n" if (Unixdate =~ /^[0-9]+$/);
print "ok 6\n" if (Dir ('t/data/01.yml') eq 't/data/');
print "ok 7\n" if (File ('t/data/01.yml') eq '01.yml');
print "ok 8\n" if (Extension ('t/data/01.yml') eq 'yml');


