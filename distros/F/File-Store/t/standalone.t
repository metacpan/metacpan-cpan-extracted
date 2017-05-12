#!perl -T

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;

use Test::More tests => 4;

# Tests
BEGIN { use_ok('File::Store'); }

# Test the routine.
{
	my $str = File::Store::get('Makefile.PL');
	ok($str, "file contents");
}


{
	my $str = File::Store::get('Makefile.PL');
	ok($str, "file contents");
}

eval { File::Store::clear(); };
ok(!$@, "clear");

#use Data::Dumper;
#print Dumper($File::Store::base);

