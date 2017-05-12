use EZDBI;
print "1..2\n";

print "ok 1\n";

print 'not ' unless defined($EZDBI::VERSION);
print "ok 2\n";

1;
