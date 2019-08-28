# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

open(FILE,">$__FILE__.txt") || die;
print FILE <DATA>;
close(FILE);

open(GETC,"<$__FILE__.txt") || die;
my @getc = ();
while (my $c = KSC5601::getc(GETC)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
close(GETC);

my $result = join('', map {"($_)"} @getc);
if ($result eq '(1)(2)(A)(B)(ㄲ)(ㄴ)') {
    print "ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
}

{
    package Getc::Test;

    open(GETC2,"<$__FILE__.txt") || die;
    my @getc = ();
    while (my $c = KSC5601::getc(GETC2)) {
        last if $c =~ /\A[\r\n]\z/;
        push @getc, $c;
    }
    close(GETC2);

    my $result = join('', map {"($_)"} @getc);
    if ($result eq '(1)(2)(A)(B)(ㄲ)(ㄴ)') {
        print "ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
    }
}

unlink("$__FILE__.txt");

__END__
12ABㄲㄴ
