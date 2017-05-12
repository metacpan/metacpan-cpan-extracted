require 't/lib.pl';

main();

sub main {
    print "1..1\n";
    print (test() ? "ok 1\n" : "not ok 1\n");
}

sub test {
    $t = new HTML::CMTemplate();

    $t->import_template(
        filename => 't/def.ctpl',
        packagename => 'T_def',
        );
    T_def::cleanup_namespace();

    return compare_str_to_file( T_def::output(), 't/def.real' );
}
