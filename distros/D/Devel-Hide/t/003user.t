
use strict;
use warnings;
use Test::More tests => 5;

use_ok('lib', 't');

# this script tests setting @HIDDEN before using Devel::Hide

{
no warnings 'once'; # @HIDDEN is used by Devel::Hide
@Devel::Hide::HIDDEN = qw(Q.pm R);
}

use_ok('Devel::Hide');

eval { require P }; 
ok(!$@, "P was loaded (as it should)");

eval { require Q }; 
like($@, qr/^Can't locate Q\.pm/, "Q not found (as it should)");

eval { require R }; 
like($@, qr/^Can't locate R\.pm/, "R not found (as it should)");
