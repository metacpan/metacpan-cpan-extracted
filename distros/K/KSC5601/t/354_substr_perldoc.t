# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

print "1..3\n";

my $__FILE__ = __FILE__;

if ($] < 5.014) {
    for my $tno (1..3) {
        print "ok - $tno # SKIP $^X $__FILE__\n";
    }
    exit;
}

if (open(TEST,">@{[__FILE__]}.t")) {
    print TEST <DATA>;
    close(TEST);
    system(qq{$^X @{[__FILE__]}.t});
    unlink("@{[__FILE__]}.t");
    unlink("@{[__FILE__]}.t.e");
}

__END__
# encoding: KSC5601
use KSC5601;

my $__FILE__ = __FILE__;

my $x = '1234';
for (KSC5601::substr($x,1,2)) {
    $_ = 'a';
    if ($x eq '1a4') {
        print "ok - 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__\n";
    }

    $_ = 'xyz';
    if ($x eq '1xyz4') {
        print "ok - 2 $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 $^X $__FILE__\n";
    }

    $x = '56789';
    $_ = 'pq';
    if ($x eq '5pq9') {
        print "ok - 3 $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 $^X $__FILE__\n";
    }
}

__END__
http://perldoc.perl.org/functions/substr.html

1.    $x = '1234';
2.    for (substr($x,1,2)) {
3.        $_ = 'a';   print $x,"\n";    # prints 1a4
4.        $_ = 'xyz'; print $x,"\n";    # prints 1xyz4
5.        $x = '56789';
6.        $_ = 'pq';  print $x,"\n";    # prints 5pq9
7.    }
