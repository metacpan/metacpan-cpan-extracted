# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{あ} ne "\x82\xa0";

# Ekps9566::X と -X (Perlのファイルテスト演算子) の結果が一致することのテスト

my $__FILE__ = __FILE__;

use Ekps9566;
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

if (((Ekps9566::r 'file') ne '') == ((-r 'file') ne '')) {
    print "ok - 1 Ekps9566::r 'file' == -r 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Ekps9566::r 'file' == -r 'file' $^X $__FILE__\n";
}

if (((Ekps9566::r FILE) ne '') == ((-r FILE) ne '')) {
    print "ok - 2 Ekps9566::r FILE == -r FILE $^X $__FILE__\n";
}
else {
    print "not ok - 2 Ekps9566::r FILE == -r FILE $^X $__FILE__\n";
}

if (((Ekps9566::w 'file') ne '') == ((-w 'file') ne '')) {
    print "ok - 3 Ekps9566::w 'file' == -w 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Ekps9566::w 'file' == -w 'file' $^X $__FILE__\n";
}

if (((Ekps9566::w FILE) ne '') == ((-w FILE) ne '')) {
    print "ok - 4 Ekps9566::w FILE == -w FILE $^X $__FILE__\n";
}
else {
    print "not ok - 4 Ekps9566::w FILE == -w FILE $^X $__FILE__\n";
}

if (((Ekps9566::x 'file') ne '') == ((-x 'file') ne '')) {
    print "ok - 5 Ekps9566::x 'file' == -x 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Ekps9566::x 'file' == -x 'file' $^X $__FILE__\n";
}

if (((Ekps9566::x FILE) ne '') == ((-x FILE) ne '')) {
    print "ok - 6 Ekps9566::x FILE == -x FILE $^X $__FILE__\n";
}
else {
    print "not ok - 6 Ekps9566::x FILE == -x FILE $^X $__FILE__\n";
}

if (((Ekps9566::o 'file') ne '') == ((-o 'file') ne '')) {
    print "ok - 7 Ekps9566::o 'file' == -o 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Ekps9566::o 'file' == -o 'file' $^X $__FILE__\n";
}

if (((Ekps9566::o FILE) ne '') == ((-o FILE) ne '')) {
    print "ok - 8 Ekps9566::o FILE == -o FILE $^X $__FILE__\n";
}
else {
    print "not ok - 8 Ekps9566::o FILE == -o FILE $^X $__FILE__\n";
}

if (((Ekps9566::R 'file') ne '') == ((-R 'file') ne '')) {
    print "ok - 9 Ekps9566::R 'file' == -R 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Ekps9566::R 'file' == -R 'file' $^X $__FILE__\n";
}

if (((Ekps9566::R FILE) ne '') == ((-R FILE) ne '')) {
    print "ok - 10 Ekps9566::R FILE == -R FILE $^X $__FILE__\n";
}
else {
    print "not ok - 10 Ekps9566::R FILE == -R FILE $^X $__FILE__\n";
}

if (((Ekps9566::W 'file') ne '') == ((-W 'file') ne '')) {
    print "ok - 11 Ekps9566::W 'file' == -W 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Ekps9566::W 'file' == -W 'file' $^X $__FILE__\n";
}

if (((Ekps9566::W FILE) ne '') == ((-W FILE) ne '')) {
    print "ok - 12 Ekps9566::W FILE == -W FILE $^X $__FILE__\n";
}
else {
    print "not ok - 12 Ekps9566::W FILE == -W FILE $^X $__FILE__\n";
}

if (((Ekps9566::X 'file') ne '') == ((-X 'file') ne '')) {
    print "ok - 13 Ekps9566::X 'file' == -X 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Ekps9566::X 'file' == -X 'file' $^X $__FILE__\n";
}

if (((Ekps9566::X FILE) ne '') == ((-X FILE) ne '')) {
    print "ok - 14 Ekps9566::X FILE == -X FILE $^X $__FILE__\n";
}
else {
    print "not ok - 14 Ekps9566::X FILE == -X FILE $^X $__FILE__\n";
}

if (((Ekps9566::O 'file') ne '') == ((-O 'file') ne '')) {
    print "ok - 15 Ekps9566::O 'file' == -O 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Ekps9566::O 'file' == -O 'file' $^X $__FILE__\n";
}

if (((Ekps9566::O FILE) ne '') == ((-O FILE) ne '')) {
    print "ok - 16 Ekps9566::O FILE == -O FILE $^X $__FILE__\n";
}
else {
    print "not ok - 16 Ekps9566::O FILE == -O FILE $^X $__FILE__\n";
}

if (((Ekps9566::e 'file') ne '') == ((-e 'file') ne '')) {
    print "ok - 17 Ekps9566::e 'file' == -e 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Ekps9566::e 'file' == -e 'file' $^X $__FILE__\n";
}

if (((Ekps9566::e FILE) ne '') == ((-e FILE) ne '')) {
    print "ok - 18 Ekps9566::e FILE == -e FILE $^X $__FILE__\n";
}
else {
    print "not ok - 18 Ekps9566::e FILE == -e FILE $^X $__FILE__\n";
}

if (((Ekps9566::z 'file') ne '') == ((-z 'file') ne '')) {
    print "ok - 19 Ekps9566::z 'file' == -z 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Ekps9566::z 'file' == -z 'file' $^X $__FILE__\n";
}

if (((Ekps9566::z FILE) ne '') == ((-z FILE) ne '')) {
    print "ok - 20 Ekps9566::z FILE == -z FILE $^X $__FILE__\n";
}
else {
    print "not ok - 20 Ekps9566::z FILE == -z FILE $^X $__FILE__\n";
}

if (((Ekps9566::s 'file') ne '') == ((-s 'file') ne '')) {
    print "ok - 21 Ekps9566::s 'file' == -s 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Ekps9566::s 'file' == -s 'file' $^X $__FILE__\n";
}

if (((Ekps9566::s FILE) ne '') == ((-s FILE) ne '')) {
    print "ok - 22 Ekps9566::s FILE == -s FILE $^X $__FILE__\n";
}
else {
    print "not ok - 22 Ekps9566::s FILE == -s FILE $^X $__FILE__\n";
}

if (((Ekps9566::f 'file') ne '') == ((-f 'file') ne '')) {
    print "ok - 23 Ekps9566::f 'file' == -f 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 23 Ekps9566::f 'file' == -f 'file' $^X $__FILE__\n";
}

if (((Ekps9566::f FILE) ne '') == ((-f FILE) ne '')) {
    print "ok - 24 Ekps9566::f FILE == -f FILE $^X $__FILE__\n";
}
else {
    print "not ok - 24 Ekps9566::f FILE == -f FILE $^X $__FILE__\n";
}

if (((Ekps9566::d 'file') ne '') == ((-d 'file') ne '')) {
    print "ok - 25 Ekps9566::d 'file' == -d 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 25 Ekps9566::d 'file' == -d 'file' $^X $__FILE__\n";
}

if (((Ekps9566::d FILE) ne '') == ((-d FILE) ne '')) {
    print "ok - 26 Ekps9566::d FILE == -d FILE $^X $__FILE__\n";
}
else {
    print "not ok - 26 Ekps9566::d FILE == -d FILE $^X $__FILE__\n";
}

if (((Ekps9566::p 'file') ne '') == ((-p 'file') ne '')) {
    print "ok - 27 Ekps9566::p 'file' == -p 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 27 Ekps9566::p 'file' == -p 'file' $^X $__FILE__\n";
}

if (((Ekps9566::p FILE) ne '') == ((-p FILE) ne '')) {
    print "ok - 28 Ekps9566::p FILE == -p FILE $^X $__FILE__\n";
}
else {
    print "not ok - 28 Ekps9566::p FILE == -p FILE $^X $__FILE__\n";
}

if (((Ekps9566::S 'file') ne '') == ((-S 'file') ne '')) {
    print "ok - 29 Ekps9566::S 'file' == -S 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 29 Ekps9566::S 'file' == -S 'file' $^X $__FILE__\n";
}

if (((Ekps9566::S FILE) ne '') == ((-S FILE) ne '')) {
    print "ok - 30 Ekps9566::S FILE == -S FILE $^X $__FILE__\n";
}
else {
    print "not ok - 30 Ekps9566::S FILE == -S FILE $^X $__FILE__\n";
}

if (((Ekps9566::b 'file') ne '') == ((-b 'file') ne '')) {
    print "ok - 31 Ekps9566::b 'file' == -b 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 31 Ekps9566::b 'file' == -b 'file' $^X $__FILE__\n";
}

if (((Ekps9566::b FILE) ne '') == ((-b FILE) ne '')) {
    print "ok - 32 Ekps9566::b FILE == -b FILE $^X $__FILE__\n";
}
else {
    print "not ok - 32 Ekps9566::b FILE == -b FILE $^X $__FILE__\n";
}

if (((Ekps9566::c 'file') ne '') == ((-c 'file') ne '')) {
    print "ok - 33 Ekps9566::c 'file' == -c 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 33 Ekps9566::c 'file' == -c 'file' $^X $__FILE__\n";
}

if (((Ekps9566::c FILE) ne '') == ((-c FILE) ne '')) {
    print "ok - 34 Ekps9566::c FILE == -c FILE $^X $__FILE__\n";
}
else {
    print "not ok - 34 Ekps9566::c FILE == -c FILE $^X $__FILE__\n";
}

if (((Ekps9566::u 'file') ne '') == ((-u 'file') ne '')) {
    print "ok - 35 Ekps9566::u 'file' == -u 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 35 Ekps9566::u 'file' == -u 'file' $^X $__FILE__\n";
}

if (((Ekps9566::u FILE) ne '') == ((-u FILE) ne '')) {
    print "ok - 36 Ekps9566::u FILE == -u FILE $^X $__FILE__\n";
}
else {
    print "not ok - 36 Ekps9566::u FILE == -u FILE $^X $__FILE__\n";
}

if (((Ekps9566::g 'file') ne '') == ((-g 'file') ne '')) {
    print "ok - 37 Ekps9566::g 'file' == -g 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 37 Ekps9566::g 'file' == -g 'file' $^X $__FILE__\n";
}

if (((Ekps9566::g FILE) ne '') == ((-g FILE) ne '')) {
    print "ok - 38 Ekps9566::g FILE == -g FILE $^X $__FILE__\n";
}
else {
    print "not ok - 38 Ekps9566::g FILE == -g FILE $^X $__FILE__\n";
}

if (((Ekps9566::T 'file') ne '') == ((-T 'file') ne '')) {
    print "ok - 39 Ekps9566::T 'file' == -T 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 39 Ekps9566::T 'file' == -T 'file' $^X $__FILE__\n";
}

if (((Ekps9566::T FILE) ne '') == ((-T FILE) ne '')) {
    print "ok - 40 Ekps9566::T FILE == -T FILE $^X $__FILE__\n";
}
else {
    print "not ok - 40 Ekps9566::T FILE == -T FILE $^X $__FILE__\n";
}

if (((Ekps9566::B 'file') ne '') == ((-B 'file') ne '')) {
    print "ok - 41 Ekps9566::B 'file' == -B 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 41 Ekps9566::B 'file' == -B 'file' $^X $__FILE__\n";
}

if (((Ekps9566::B FILE) ne '') == ((-B FILE) ne '')) {
    print "ok - 42 Ekps9566::B FILE == -B FILE $^X $__FILE__\n";
}
else {
    print "not ok - 42 Ekps9566::B FILE == -B FILE $^X $__FILE__\n";
}

if (((Ekps9566::M 'file') ne '') == ((-M 'file') ne '')) {
    print "ok - 43 Ekps9566::M 'file' == -M 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 43 Ekps9566::M 'file' == -M 'file' $^X $__FILE__\n";
}

if (((Ekps9566::M FILE) ne '') == ((-M FILE) ne '')) {
    print "ok - 44 Ekps9566::M FILE == -M FILE $^X $__FILE__\n";
}
else {
    print "not ok - 44 Ekps9566::M FILE == -M FILE $^X $__FILE__\n";
}

if (((Ekps9566::A 'file') ne '') == ((-A 'file') ne '')) {
    print "ok - 45 Ekps9566::A 'file' == -A 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 45 Ekps9566::A 'file' == -A 'file' $^X $__FILE__\n";
}

if (((Ekps9566::A FILE) ne '') == ((-A FILE) ne '')) {
    print "ok - 46 Ekps9566::A FILE == -A FILE $^X $__FILE__\n";
}
else {
    print "not ok - 46 Ekps9566::A FILE == -A FILE $^X $__FILE__\n";
}

if (((Ekps9566::C 'file') ne '') == ((-C 'file') ne '')) {
    print "ok - 47 Ekps9566::C 'file' == -C 'file' $^X $__FILE__\n";
}
else {
    print "not ok - 47 Ekps9566::C 'file' == -C 'file' $^X $__FILE__\n";
}

if (((Ekps9566::C FILE) ne '') == ((-C FILE) ne '')) {
    print "ok - 48 Ekps9566::C FILE == -C FILE $^X $__FILE__\n";
}
else {
    print "not ok - 48 Ekps9566::C FILE == -C FILE $^X $__FILE__\n";
}

close(FILE);
unlink('file');

__END__
