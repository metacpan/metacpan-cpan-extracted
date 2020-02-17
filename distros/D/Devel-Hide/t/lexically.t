use strict;
use warnings;

BEGIN {
    require Test::More;
    $] < 5.010
        ? Test::More->import(skip_all => "perl too old")
        : Test::More->import(tests => 9);
}

use lib 't';

my @expected_warnings;
BEGIN {
    push @expected_warnings,
        'Devel::Hide hides R.pm',
        'Devel::Hide hides Q.pm';
    $SIG{__WARN__} = sub {
        if(!@expected_warnings) {
            fail("Got unexpected warning '$_[0]'")
        } else {
            is($_[0], shift(@expected_warnings)."\n",
                "got expected warning: $_[0]");
        }
    }
}
END { ok(!@expected_warnings, "got all expected warnings") }

# hide R globally
use Devel::Hide qw(R);
note("R hidden globally, and noisily");

eval { require R }; 
like($@, qr/^Can't locate R\.pm in \@INC/,
    "correctly moaned about hiding R (globally)");

{
    use Devel::Hide qw(-lexically -quiet Q.pm);
    note("Q hidden lexically, quietly");

    eval { require Q }; 
    like($@, qr/^Can't locate Q\.pm in \@INC/,
        "correctly moaned about loading Q");

    eval { require R }; 
    like($@, qr/^Can't locate R\.pm in \@INC/,
        "still can't load R which is globally hidden");
}

{
    use Devel::Hide qw(-lexically Q);
    note("Q hidden in a different scope, noisily");

    eval { require Q }; 
    like($@, qr/^Can't locate Q\.pm in \@INC/,
        "correctly moaned about loading Q");
}

note("Now we're outside that lexical scope");

eval { require Q };
ok(!$@, "nothing moaned about loading Q");

eval { require R }; 
like($@, qr/^Can't locate R\.pm in \@INC/,
    "still can't load R");
