# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

# Egbk::X 偲 -X (Perl偺僼傽僀儖僥僗僩墘嶼巕) 偺寢壥偑堦抳偡傞偙偲偺僥僗僩

my $__FILE__ = __FILE__;

use Egbk;
print "1..48\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..48) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

open(FILE,'>file');
close(FILE);

open(FILE,'file');

if (((Egbk::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Egbk::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Egbk::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Egbk::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Egbk::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Egbk::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Egbk::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Egbk::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Egbk::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Egbk::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Egbk::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Egbk::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Egbk::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Egbk::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Egbk::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Egbk::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Egbk::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Egbk::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Egbk::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Egbk::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Egbk::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Egbk::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Egbk::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Egbk::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Egbk::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Egbk::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Egbk::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Egbk::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Egbk::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Egbk::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Egbk::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Egbk::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egbk::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Egbk::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Egbk::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Egbk::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Egbk::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Egbk::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Egbk::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Egbk::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Egbk::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Egbk::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Egbk::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Egbk::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Egbk::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Egbk::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Egbk::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Egbk::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Egbk::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Egbk::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Egbk::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Egbk::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Egbk::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Egbk::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Egbk::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Egbk::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Egbk::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Egbk::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Egbk::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Egbk::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Egbk::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Egbk::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egbk::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Egbk::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Egbk::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egbk::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Egbk::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Egbk::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Egbk::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Egbk::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Egbk::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Egbk::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Egbk::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Egbk::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Egbk::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Egbk::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Egbk::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Egbk::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Egbk::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Egbk::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Egbk::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Egbk::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Egbk::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Egbk::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Egbk::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Egbk::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Egbk::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Egbk::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Egbk::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Egbk::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Egbk::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Egbk::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Egbk::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Egbk::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Egbk::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Egbk::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Egbk::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Egbk::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Egbk::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Egbk::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Egbk::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Egbk::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Egbk::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Egbk::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Egbk::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Egbk::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Egbk::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Egbk::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Egbk::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Egbk::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Egbk::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Egbk::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Egbk::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Egbk::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Egbk::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Egbk::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Egbk::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Egbk::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Egbk::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Egbk::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Egbk::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Egbk::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Egbk::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Egbk::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Egbk::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Egbk::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Egbk::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Egbk::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Egbk::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Egbk::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Egbk::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Egbk::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Egbk::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Egbk::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Egbk::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Egbk::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Egbk::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Egbk::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Egbk::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Egbk::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Egbk::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Egbk::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Egbk::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Egbk::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
