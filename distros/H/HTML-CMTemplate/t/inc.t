require 't/lib.pl';
use strict;

BEGIN {
# Suppress warnings -- we do some setting of variables without using them
$^W = 0;
}

main();

sub main {
    print "1..1\n";
    print (test() ? "ok 1\n" : "not ok 1\n");
}

sub test {
    my $t = new HTML::CMTemplate();

    $t->import_template(
        filename => 't/inc.ctpl',
        packagename => 'T_inc',
        );
    T_inc::cleanup_namespace();

    return compare_str_to_file( T_inc::output(), 't/inc.real' );
}
