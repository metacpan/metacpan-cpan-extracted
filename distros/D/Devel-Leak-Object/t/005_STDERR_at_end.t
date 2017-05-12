#!/usr/bin/perl

use strict;
use Test::More tests => 1;

use File::Temp qw(tempfile);

(undef, my $temp) = tempfile();

system(qq{ $^X -Mblib -MDevel::Leak::Object=GLOBAL_bless -e '\$foo=bless({},FOO);\$foo->{foo}=\$foo' 2> $temp });

open(FILE, $temp) || die("Can't read $temp\n");
my $preamble = <FILE>;
chomp(my $data = <FILE>);

my($tab, $class, $count) = split(/\s+/, $data);
ok($class eq 'FOO' && $count == 1, "Dump to STDERR at END works");

