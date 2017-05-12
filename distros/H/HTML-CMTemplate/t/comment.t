require 't/lib.pl';

main();

sub main {
    print "1..1\n";
    print (test() ? "ok 1\n" : "not ok 1\n");
}

sub test {
    $t = new HTML::CMTemplate();

    $t->import_template(
        filename => 't/comment.ctpl',
        packagename => 'T_comment',
        );
    T_comment::cleanup_namespace();

    return T_comment::output() eq '';
}
