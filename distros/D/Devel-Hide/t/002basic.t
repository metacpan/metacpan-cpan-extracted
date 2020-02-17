use strict;
use warnings;
use Test::More tests => 14;

use lib 't';

my @expected_warnings;
BEGIN {
    push @expected_warnings,
        'Devel::Hide hides Q.pm, R.pm';
    $SIG{__WARN__} = sub {
        ok($_[0] eq shift(@expected_warnings)."\n",
            "got expected warning: $_[0]");
    }
}
END { ok(!@expected_warnings, "got all expected warnings") }

use Devel::Hide qw(Q.pm R);

# do this twice, see https://rt.cpan.org/Ticket/Display.html?id=120220
foreach my $pass (1, 2) {
    eval { require P }; 
    ok(!$@, "nothing moaned about loading P".
        ($pass == 2 ? ' again' : ''));
    ok(exists($INC{"P.pm"}), "P is loaded");
    
    eval { require Q }; 
    like($@, qr/^Can't locate Q\.pm in \@INC/,
        "correctly moaned about loading Q".
        ($pass == 2 ? ' again' : ''));
    ok(!exists($INC{"Q.pm"}), "correctly didn't load Q");
    
    eval { require R }; 
    like($@, qr/^Can't locate R\.pm in \@INC/,
        "correctly moaned about loading R".
        ($pass == 2 ? ' again' : ''));
    ok(!exists($INC{"R.pm"}), "correctly didn't load R");
}
