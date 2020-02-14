use strict;
use warnings;
use Test::More tests => 6;

use lib 't';

my @expected_warnings;
BEGIN {
    push @expected_warnings,
        'Devel::Hide: Too late to hide P.pm';
    $SIG{__WARN__} = sub {
        ok($_[0] eq shift(@expected_warnings)."\n",
            "got expected warning: $_[0]");
    }
}
END { ok(!@expected_warnings, "got all expected warnings") }

use_ok('P'); # loads P

# too late to hide P. Q will be hidden, but not mentioned
use_ok('Devel::Hide', '-quiet', 'P', 'Q');

eval { require P }; 
ok(!$@, "P was loaded (as it should)");

eval { require Q }; 
ok($@, "Q was not loaded");
