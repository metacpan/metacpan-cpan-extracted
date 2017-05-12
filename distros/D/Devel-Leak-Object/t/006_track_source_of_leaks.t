#!/usr/bin/perl

use strict;
use Test::More tests => 2;

use File::Temp qw(tempfile);

(undef, my $temp) = tempfile();

system(qq{ $^X -Mblib t/tracksource.pl 2> $temp });
open(FILE, $temp) || die("Can't read $temp\n");
undef $/;
my $data = <FILE>;
close(FILE);
is_deeply($data, q{Tracked objects by class:
	FOO                                      1

Sources of leaks:
FOO
     1 from t/tracksource.pl line: 8
}, "can track a single leak to its source");

system(qq{ $^X -Mblib t/tracksource2.pl 2> $temp });
open(FILE, $temp) || die("Can't read $temp\n");
undef $/;
$data = <FILE>;
close(FILE);
is_deeply($data,
q{checkpoint:
	Devel::Leak::Object::Tests::tracksource  1
	FOO                                      2
checkpoint:
	LOOPYFOO                                 1
checkpoint:
	LOOPYFOO                                 1
Tracked objects by class:
	Devel::Leak::Object::Tests::tracksource  1
	FOO                                      2
	LOOPYFOO                                 3

Sources of leaks:
Devel::Leak::Object::Tests::tracksource
     1 from t/tracksource2.pl line: 14
FOO
     1 from t/tracksource2.pl line: 10
     1 from t/tracksource2.pl line: 12
LOOPYFOO
     3 from t/tracksource2.pl line: 18
},
"can track multiple leak sources in multiple files");
