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
        filename => 't/for.ctpl',
        packagename => 'T_for',
        );
    T_for::cleanup_namespace();

    $T_for::aarray = ['a','b','c','d','e'];
    $T_for::barray = [1,2,3,4,5];
    $T_for::carray = [1,2,3,0,5];

    return compare_str_to_file( T_for::output(), 't/for.real' );
}
