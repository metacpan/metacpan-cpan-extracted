use strict;
use warnings;
use Test::More tests => 7;

use lib 't';

my @expected_warnings;
BEGIN {
    push @expected_warnings,
        'Devel::Hide: Too late to hide P.pm',
        'Devel::Hide hides Q.pm';
    $SIG{__WARN__} = sub {
        ok($_[0] eq shift(@expected_warnings)."\n",
            "got expected warning: $_[0]");
    }
}
END { ok(!@expected_warnings, "got all expected warnings") }

use_ok('P'); # loads P
use_ok('Devel::Hide', 'P', 'Q'); # too late to hide P

eval { require P }; 
ok(!$@, "P was loaded (as it should)");

eval { require Q }; 
ok($@, "Q was not loaded");
