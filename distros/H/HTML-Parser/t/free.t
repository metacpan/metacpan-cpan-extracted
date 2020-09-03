use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 1;


my $p;
$p = HTML::Parser->new(
    start_h => [
        sub {
            undef $p;
        }
    ],
);

$p->parse(q(<foo>));

pass 'no SEGV';
