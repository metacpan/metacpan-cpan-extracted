# -*- perl -*-

print "1..1\n";

eval { require ExtUtils::PerlPP };
if ($@) {
    print "not ok 1\n$@\n";
} else {
    print "ok 1\n";
}
