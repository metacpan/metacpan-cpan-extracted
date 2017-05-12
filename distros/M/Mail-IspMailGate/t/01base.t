# -*- perl -*-
$| = 1;
print "1..2\n";
my($warn);
$SIG{__WARN__} = sub { $warn = @_ };
eval { require Mail::IspMailGate::Parser; };
if ($@) {
    print "not ok 1 Error $@\n";
} elsif ($warn) {
    print "not ok 1 Warning $warn\n";
} else {
    print "ok 1\n";
}

eval { require Mail::IspMailGate; };
if ($@) {
    print "not ok 2 Error $@\n";
} elsif ($warn) {
    print "not ok 2 Warning $warn\n";
} else {
    print "ok 2\n";
}
