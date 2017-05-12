use IO::Interactive qw( interactive );

print "1..2\n";

if (-t *STDIN && -t *STDOUT ) {
    print {interactive}          "ok 1\n";

    print {interactive(*STDOUT)} "ok 2\n";
}
else {
    print {interactive}          "not ";
    print "ok 1\n";

    print {interactive(*STDOUT)} "not ";
    print "ok 2\n";
}
