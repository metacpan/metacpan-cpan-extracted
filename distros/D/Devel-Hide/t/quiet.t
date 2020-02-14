use strict;
use warnings;
use Test::More tests => 2;

use lib 't';

my $warnings;
BEGIN { $SIG{__WARN__} = sub { $warnings++ } }
END { ok(!$warnings, "suppressed warnings"); }

use Devel::Hide qw(-quiet Q);

eval { require Q }; 
like($@, qr/^Can't locate Q\.pm in \@INC/,
    "correctly moaned about loading Q");
