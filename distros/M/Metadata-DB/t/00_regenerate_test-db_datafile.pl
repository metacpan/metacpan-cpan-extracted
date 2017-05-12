require './t/testlib.pl';
use strict;

my $ammount = 2000;

print STDERR "generating $ammount entries\n";

_gen_people_metadata($ammount);

print STDERR "done\n";




