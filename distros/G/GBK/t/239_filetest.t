# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

# Egbk::X 偲 -X (Perl偺僼傽僀儖僥僗僩墘嶼巕) 偺寢壥偑堦抳偡傞偙偲偺僥僗僩(懳徾偼僨傿儗僋僩儕)

my $__FILE__ = __FILE__;

use Egbk;
print "1..22\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    for my $tno (1..22) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

mkdir('directory',0777);

opendir(DIR,'directory');

if (((Egbk::r 'directory') ne '') == ((-r 'directory') ne '')) {
    print "ok - 1 Egbk::r 'directory' == -r 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 1 Egbk::r 'directory' == -r 'directory' $^X $__FILE__\n";
}

if (((Egbk::w 'directory') ne '') == ((-w 'directory') ne '')) {
    print "ok - 2 Egbk::w 'directory' == -w 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 2 Egbk::w 'directory' == -w 'directory' $^X $__FILE__\n";
}

if (((Egbk::x 'directory') ne '') == ((-x 'directory') ne '')) {
    print "ok - 3 Egbk::x 'directory' == -x 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 3 Egbk::x 'directory' == -x 'directory' $^X $__FILE__\n";
}

if (((Egbk::o 'directory') ne '') == ((-o 'directory') ne '')) {
    print "ok - 4 Egbk::o 'directory' == -o 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 4 Egbk::o 'directory' == -o 'directory' $^X $__FILE__\n";
}

if (((Egbk::R 'directory') ne '') == ((-R 'directory') ne '')) {
    print "ok - 5 Egbk::R 'directory' == -R 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 5 Egbk::R 'directory' == -R 'directory' $^X $__FILE__\n";
}

if (((Egbk::W 'directory') ne '') == ((-W 'directory') ne '')) {
    print "ok - 6 Egbk::W 'directory' == -W 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 6 Egbk::W 'directory' == -W 'directory' $^X $__FILE__\n";
}

if (((Egbk::X 'directory') ne '') == ((-X 'directory') ne '')) {
    print "ok - 7 Egbk::X 'directory' == -X 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 7 Egbk::X 'directory' == -X 'directory' $^X $__FILE__\n";
}

if (((Egbk::O 'directory') ne '') == ((-O 'directory') ne '')) {
    print "ok - 8 Egbk::O 'directory' == -O 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 8 Egbk::O 'directory' == -O 'directory' $^X $__FILE__\n";
}

if (((Egbk::e 'directory') ne '') == ((-e 'directory') ne '')) {
    print "ok - 9 Egbk::e 'directory' == -e 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 9 Egbk::e 'directory' == -e 'directory' $^X $__FILE__\n";
}

if (((Egbk::z 'directory') ne '') == ((-z 'directory') ne '')) {
    print "ok - 10 Egbk::z 'directory' == -z 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 10 Egbk::z 'directory' == -z 'directory' $^X $__FILE__\n";
}

if (((Egbk::s 'directory') ne '') == ((-s 'directory') ne '')) {
    print "ok - 11 Egbk::s 'directory' == -s 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 11 Egbk::s 'directory' == -s 'directory' $^X $__FILE__\n";
}

if (((Egbk::f 'directory') ne '') == ((-f 'directory') ne '')) {
    print "ok - 12 Egbk::f 'directory' == -f 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 12 Egbk::f 'directory' == -f 'directory' $^X $__FILE__\n";
}

if (((Egbk::d 'directory') ne '') == ((-d 'directory') ne '')) {
    print "ok - 13 Egbk::d 'directory' == -d 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 13 Egbk::d 'directory' == -d 'directory' $^X $__FILE__\n";
}

if (((Egbk::p 'directory') ne '') == ((-p 'directory') ne '')) {
    print "ok - 14 Egbk::p 'directory' == -p 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 14 Egbk::p 'directory' == -p 'directory' $^X $__FILE__\n";
}

if (((Egbk::S 'directory') ne '') == ((-S 'directory') ne '')) {
    print "ok - 15 Egbk::S 'directory' == -S 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 15 Egbk::S 'directory' == -S 'directory' $^X $__FILE__\n";
}

if (((Egbk::b 'directory') ne '') == ((-b 'directory') ne '')) {
    print "ok - 16 Egbk::b 'directory' == -b 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 16 Egbk::b 'directory' == -b 'directory' $^X $__FILE__\n";
}

if (((Egbk::c 'directory') ne '') == ((-c 'directory') ne '')) {
    print "ok - 17 Egbk::c 'directory' == -c 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 17 Egbk::c 'directory' == -c 'directory' $^X $__FILE__\n";
}

if (((Egbk::u 'directory') ne '') == ((-u 'directory') ne '')) {
    print "ok - 18 Egbk::u 'directory' == -u 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 18 Egbk::u 'directory' == -u 'directory' $^X $__FILE__\n";
}

if (((Egbk::g 'directory') ne '') == ((-g 'directory') ne '')) {
    print "ok - 19 Egbk::g 'directory' == -g 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 19 Egbk::g 'directory' == -g 'directory' $^X $__FILE__\n";
}

if (((Egbk::M 'directory') ne '') == ((-M 'directory') ne '')) {
    print "ok - 20 Egbk::M 'directory' == -M 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 20 Egbk::M 'directory' == -M 'directory' $^X $__FILE__\n";
}

if (((Egbk::A 'directory') ne '') == ((-A 'directory') ne '')) {
    print "ok - 21 Egbk::A 'directory' == -A 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 21 Egbk::A 'directory' == -A 'directory' $^X $__FILE__\n";
}

if (((Egbk::C 'directory') ne '') == ((-C 'directory') ne '')) {
    print "ok - 22 Egbk::C 'directory' == -C 'directory' $^X $__FILE__\n";
}
else {
    print "not ok - 22 Egbk::C 'directory' == -C 'directory' $^X $__FILE__\n";
}

closedir(DIR);
rmdir('directory');

__END__
