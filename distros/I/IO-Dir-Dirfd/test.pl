# $Id: test.pl,v 1.1.1.1 2001/11/21 17:30:15 tobez Exp $

BEGIN { $| = 1; print "1..41\n"; }
END {print "not ok 1\n" unless $loaded;}
use Symbol;
use IO::Dir::Dirfd;
$^W = 1;
$loaded = 1;
use strict;
print "ok 1\n";

my $d;
opendir D, "." or die $!;
print "not " unless defined($d = dirfd(D)) && $d =~ /^\d+$/;
print "ok 2\n";

my $d2;
print "not " unless defined($d2 = dirfd(*D)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 3\n";

print "not " unless defined($d2 = dirfd(\*D)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 4\n";

eval { $d2 = dirfd("bla") };
print "not " unless $@ && $@ =~ /^Bad filehandle:/;
print "ok 5\n";

$d2 = dirfd(STDOUT);
print "not " if defined($d2) || $! !~ /^Bad file descriptor/;
print "ok 6\n";

closedir(D);
$d2 = dirfd(D);
print "not " if defined($d2) || $! !~ /^Bad file descriptor/;
print "ok 7\n";

my $dir = gensym;
opendir $dir, "." or die $!;

print "not " unless defined($d = dirfd($dir)) && $d =~ /^\d+$/;
print "ok 8\n";

print "not " unless defined($d2 = dirfd(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 9\n";

print "not " unless defined($d2 = dirfd(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 10\n";

print "not " unless defined($d2 = dirfd(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 11\n";

closedir($dir);
$d2 = dirfd($dir);
print "not " if defined($d2) || $! !~ /^Bad file descriptor/;
print "ok 12\n";

eval { require DirHandle };
if ($@) {
	foreach (13..16) {print "ok $_ # skipped in absence of DirHandle\n"};
} else {
	$dir = new DirHandle ".";
	die $! unless defined $dir;

	print "not " unless defined($d = dirfd($dir)) && $d =~ /^\d+$/;
	print "ok 13\n";

	print "not " unless defined($d2 = dirfd(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 14\n";

	print "not " unless defined($d2 = dirfd(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 15\n";

	print "not " unless defined($d2 = dirfd(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 16\n";

	undef $dir;
}

eval { require IO::Dir };
if ($@) {
	foreach (17..20) {print "ok $_ # skipped in absence of IO::Dir\n"};
} else {
	$dir = new IO::Dir ".";
	die $! unless defined $dir;

	print "not " unless defined($d = dirfd($dir)) && $d =~ /^\d+$/;
	print "ok 17\n";

	print "not " unless defined($d2 = dirfd(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 18\n";

	print "not " unless defined($d2 = dirfd(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 19\n";

	print "not " unless defined($d2 = dirfd(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 20\n";

	undef $dir;
}

# duplicate (almost) all tests with fileno() in-place of dirfd()
use IO::Dir::Dirfd qw(fileno);

print "not " unless defined($d = fileno(STDIN)) && $d == 0;
print "ok 21\n";
print "not " unless defined($d = fileno(STDOUT)) && $d == 1;
print "ok 22\n";
print "not " unless defined($d = fileno(STDERR)) && $d == 2;
print "ok 23\n";

my $d;
opendir D, "." or die $!;
print "not " unless defined($d = fileno(D)) && $d =~ /^\d+$/;
print "ok 24\n";

my $d2;
print "not " unless defined($d2 = fileno(*D)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 25\n";

print "not " unless defined($d2 = fileno(\*D)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 26\n";

eval { $d2 = fileno("bla") };
print "not " unless $@ && $@ =~ /^Bad filehandle:/;
print "ok 27\n";

closedir(D);
$d2 = fileno(D);
print "not " if defined($d2) || $! !~ /^Bad file descriptor/;
print "ok 28\n";

my $dir = gensym;
opendir $dir, "." or die $!;

print "not " unless defined($d = fileno($dir)) && $d =~ /^\d+$/;
print "ok 29\n";

print "not " unless defined($d2 = fileno(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 30\n";

print "not " unless defined($d2 = fileno(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 31\n";

print "not " unless defined($d2 = fileno(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
print "ok 32\n";

closedir($dir);
$d2 = dirfd($dir);
print "not " if defined($d2) || $! !~ /^Bad file descriptor/;
print "ok 33\n";

eval { require DirHandle };
if ($@) {
	foreach (34..37) {print "ok $_ # skipped in absence of DirHandle\n"};
} else {
	$dir = new DirHandle ".";
	die $! unless defined $dir;

	print "not " unless defined($d = fileno($dir)) && $d =~ /^\d+$/;
	print "ok 34\n";

	print "not " unless defined($d2 = fileno(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 35\n";

	print "not " unless defined($d2 = fileno(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 36\n";

	print "not " unless defined($d2 = fileno(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 37\n";

	undef $dir;
}

eval { require IO::Dir };
if ($@) {
	foreach (38..41) {print "ok $_ # skipped in absence of IO::Dir\n"};
} else {
	$dir = new IO::Dir ".";
	die $! unless defined $dir;

	print "not " unless defined($d = fileno($dir)) && $d =~ /^\d+$/;
	print "ok 38\n";

	print "not " unless defined($d2 = fileno(\$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 39\n";

	print "not " unless defined($d2 = fileno(*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 40\n";

	print "not " unless defined($d2 = fileno(\*$dir)) && $d2 =~ /^\d+$/ && $d2 == $d;
	print "ok 41\n";

	undef $dir;
}
