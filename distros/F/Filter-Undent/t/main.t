#!perl -T

use Test::More tests => 4;

diag( "Testing Filter::Undent $Filter::Undent::VERSION, Perl $], $^X" );

BEGIN {
    use_ok( 'Filter::Undent' ) || print "Bail out!\n";
}

my $str = <<'EOF';

    FIRST
        INDENTED_RELATIVE
OUTDENTED
EOF

is(
    $str,
    "\nFIRST\n    INDENTED_RELATIVE\nOUTDENTED\n",
    'undented successfully via heredoc w/spaces'
);

$str = undent "\tFIRST\n\t\tINDENTED_RELATIVE\nOUTDENTED";

is(
    $str,
    "FIRST\n\tINDENTED_RELATIVE\nOUTDENTED",
    'undented successfully via function w/tabs'
);

no Filter::Undent;

$str = <<'EOF';

    FIRST
        INDENTED_RELATIVE
OUTDENTED
EOF

is(
    $str,
    "\n    FIRST\n        INDENTED_RELATIVE\nOUTDENTED\n",
    'not undented when filter is disabled'
);
