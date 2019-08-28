# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = KSC5601::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(A)(B)(ㄲ)(ㄴ)') {
    print "ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12ABㄲㄴ --> $result.\n";
}

__END__
12ABㄲㄴ
