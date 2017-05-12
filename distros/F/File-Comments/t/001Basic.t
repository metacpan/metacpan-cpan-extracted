######################################################################
# Test suite for File::Comments
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('File::Comments') };

ok(1, "Loading");

my $snoop = File::Comments->new();
ok($snoop->suffix_registered(".c"), ".c suffix registered");
