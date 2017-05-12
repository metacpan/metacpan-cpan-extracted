# -*- perl -*-

$| = 1;
$^W = 1;

print "1..1\n";

eval "use HTML::EP::Explorer ()";
if ($@) {
    print STDERR "$@\n";
    print "not ok 1\n";
} else {
    print "ok 1\n";
}
