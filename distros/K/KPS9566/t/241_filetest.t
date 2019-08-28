# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

# ˆø”‚ªÈ—ª‚³‚ê‚½ê‡‚ÌƒeƒXƒg

my $__FILE__ = __FILE__;

use Ekps9566;
print "1..24\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..24) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

$_ = 'file';
if ((Ekps9566::r_ ne '') == (-r ne '')) {
    print "ok - 1 Ekps9566::r_ == -r  $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ekps9566::r_ == -r  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::w_ ne '') == (-w ne '')) {
    print "ok - 2 Ekps9566::w_ == -w  $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ekps9566::w_ == -w  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::x_ ne '') == (-x ne '')) {
    print "ok - 3 Ekps9566::x_ == -x  $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ekps9566::x_ == -x  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::o_ ne '') == (-o ne '')) {
    print "ok - 4 Ekps9566::o_ == -o  $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ekps9566::o_ == -o  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::R_ ne '') == (-R ne '')) {
    print "ok - 5 Ekps9566::R_ == -R  $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ekps9566::R_ == -R  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::W_ ne '') == (-W ne '')) {
    print "ok - 6 Ekps9566::W_ == -W  $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ekps9566::W_ == -W  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::X_ ne '') == (-X ne '')) {
    print "ok - 7 Ekps9566::X_ == -X  $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ekps9566::X_ == -X  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::O_ ne '') == (-O ne '')) {
    print "ok - 8 Ekps9566::O_ == -O  $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ekps9566::O_ == -O  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::e_ ne '') == (-e ne '')) {
    print "ok - 9 Ekps9566::e_ == -e  $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ekps9566::e_ == -e  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::z_ ne '') == (-z ne '')) {
    print "ok - 10 Ekps9566::z_ == -z  $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ekps9566::z_ == -z  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::s_ ne '') == (-s ne '')) {
    print "ok - 11 Ekps9566::s_ == -s  $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ekps9566::s_ == -s  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::f_ ne '') == (-f ne '')) {
    print "ok - 12 Ekps9566::f_ == -f  $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ekps9566::f_ == -f  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::d_ ne '') == (-d ne '')) {
    print "ok - 13 Ekps9566::d_ == -d  $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ekps9566::d_ == -d  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::p_ ne '') == (-p ne '')) {
    print "ok - 14 Ekps9566::p_ == -p  $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ekps9566::p_ == -p  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::S_ ne '') == (-S ne '')) {
    print "ok - 15 Ekps9566::S_ == -S  $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ekps9566::S_ == -S  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::b_ ne '') == (-b ne '')) {
    print "ok - 16 Ekps9566::b_ == -b  $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ekps9566::b_ == -b  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::c_ ne '') == (-c ne '')) {
    print "ok - 17 Ekps9566::c_ == -c  $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ekps9566::c_ == -c  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::u_ ne '') == (-u ne '')) {
    print "ok - 18 Ekps9566::u_ == -u  $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ekps9566::u_ == -u  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::g_ ne '') == (-g ne '')) {
    print "ok - 19 Ekps9566::g_ == -g  $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ekps9566::g_ == -g  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::T_ ne '') == (-T ne '')) {
    print "ok - 20 Ekps9566::T_ == -T  $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ekps9566::T_ == -T  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::B_ ne '') == (-B ne '')) {
    print "ok - 21 Ekps9566::B_ == -B  $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ekps9566::B_ == -B  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::M_ ne '') == (-M ne '')) {
    print "ok - 22 Ekps9566::M_ == -M  $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ekps9566::M_ == -M  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::A_ ne '') == (-A ne '')) {
    print "ok - 23 Ekps9566::A_ == -A  $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ekps9566::A_ == -A  $^X $__FILE__\n";
}

$_ = 'file';
if ((Ekps9566::C_ ne '') == (-C ne '')) {
    print "ok - 24 Ekps9566::C_ == -C  $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ekps9566::C_ == -C  $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
