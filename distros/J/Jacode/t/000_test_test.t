######################################################################
#
# 000_test_test.t for test environmtnt of testing jacode.pl
#
# Copyright (c) 2016 INABA Hitoshi <ina@cpan.org>
#
######################################################################

print "1..2\n";

$tno = 1;
chdir('t');

$cr = 0;
for $file (<*.txt *.want>) {
    open(FILE,$file) || die "Can't open file: $file\n";
    binmode(FILE);
    $cr += grep(/\x0d/,<FILE>);
    close(FILE);
}
if ($cr == 0) {
    print "ok - $tno *.txt and *.want file must have no CR.\n";
}
else {
    print "not ok - $tno *.txt and *.want file must have no CR.\n";
}
$tno++;

unlink <*.got>;
if (scalar(@_=<*.got>) == 0) {
    print "ok - $tno *.got file found.\n";
}
else {
    print "not ok - $tno *.got file found.\n";
}
$tno++;

1;
__END__
