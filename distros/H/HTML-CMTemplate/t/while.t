require 't/lib.pl';
use strict;
use vars qw($iterations);

BEGIN {
# Suppress warnings -- we do some setting of variables without using them
$^W = 0;
$HTML::CMTemplate::DEBUG=1;
$HTML::CMTemplate::DEBUG_FILE_NAME='t/debug.log';
}

main();

sub main {
    print "1..1\n";
    print (test() ? "ok 1\n" : "not ok 1\n");
}

sub test {
    $iterations = 0;

    my $t = new HTML::CMTemplate();

    $t->import_template(
        filename => 't/while.ctpl',
        packagename => 'T_while',
        warn => 1,
        );
    #print STDERR $t->output_perl();
    T_while::cleanup_namespace();

    $T_while::next = \&next;

    return compare_str_to_file( T_while::output(), 't/while.real' );
}

sub next {
    return ($iterations++ < 10);
}
