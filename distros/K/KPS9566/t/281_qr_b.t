# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{Ç†} ne "\x82\xa0";

use strict;
use KPS9566;
print "1..56\n";

my $__FILE__ = __FILE__;

if ('A' =~ qr/A/) {
    print qq{ok - 1 'A' =~ qr/A/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 'A' =~ qr/A/ $^X $__FILE__\n};
}

if ('A' =~ qr/A/b) {
    print qq{ok - 2 'A' =~ qr/A/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 'A' =~ qr/A/b $^X $__FILE__\n};
}

if ('A' =~ qr/a/i) {
    print qq{ok - 3 'A' =~ qr/a/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 'A' =~ qr/a/i $^X $__FILE__\n};
}

if ('A' =~ qr/a/ib) {
    print qq{ok - 4 'A' =~ qr/a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 'A' =~ qr/a/ib $^X $__FILE__\n};
}

if ('a' =~ qr/A/) {
    print qq{not ok - 5 'a' =~ qr/A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 5 'a' =~ qr/A/ $^X $__FILE__\n};
}

if ('a' =~ qr/A/b) {
    print qq{not ok - 6 'a' =~ qr/A/b $^X $__FILE__\n};
}
else {
    print qq{ok - 6 'a' =~ qr/A/b $^X $__FILE__\n};
}

if ('a' =~ qr/a/i) {
    print qq{ok - 7 'a' =~ qr/a/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 'a' =~ qr/a/i $^X $__FILE__\n};
}

if ('a' =~ qr/a/ib) {
    print qq{ok - 8 'a' =~ qr/a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 'a' =~ qr/a/ib $^X $__FILE__\n};
}

if ('A' =~ qr/ÉA/) {
    print qq{not ok - 9 'A' =~ qr/ÉA/ $^X $__FILE__\n};
}
else {
    print qq{ok - 9 'A' =~ qr/ÉA/ $^X $__FILE__\n};
}

if ('A' =~ qr/ÉA/b) {
    print qq{not ok - 10 'A' =~ qr/ÉA/b $^X $__FILE__\n};
}
else {
    print qq{ok - 10 'A' =~ qr/ÉA/b $^X $__FILE__\n};
}

if ('A' =~ qr/ÉA/i) {
    print qq{not ok - 11 'A' =~ qr/ÉA/i $^X $__FILE__\n};
}
else {
    print qq{ok - 11 'A' =~ qr/ÉA/i $^X $__FILE__\n};
}

if ('A' =~ qr/ÉA/ib) {
    print qq{not ok - 12 'A' =~ qr/ÉA/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 12 'A' =~ qr/ÉA/ib $^X $__FILE__\n};
}

if ('A' =~ qr/Éa/) {
    print qq{not ok - 13 'A' =~ qr/Éa/ $^X $__FILE__\n};
}
else {
    print qq{ok - 13 'A' =~ qr/Éa/ $^X $__FILE__\n};
}

if ('A' =~ qr/Éa/b) {
    print qq{not ok - 14 'A' =~ qr/Éa/b $^X $__FILE__\n};
}
else {
    print qq{ok - 14 'A' =~ qr/Éa/b $^X $__FILE__\n};
}

if ('A' =~ qr/Éa/i) {
    print qq{not ok - 15 'A' =~ qr/Éa/i $^X $__FILE__\n};
}
else {
    print qq{ok - 15 'A' =~ qr/Éa/i $^X $__FILE__\n};
}

if ('A' =~ qr/Éa/ib) {
    print qq{not ok - 16 'A' =~ qr/Éa/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 16 'A' =~ qr/Éa/ib $^X $__FILE__\n};
}

if ('a' =~ qr/ÉA/) {
    print qq{not ok - 17 'a' =~ qr/ÉA/ $^X $__FILE__\n};
}
else {
    print qq{ok - 17 'a' =~ qr/ÉA/ $^X $__FILE__\n};
}

if ('a' =~ qr/ÉA/b) {
    print qq{not ok - 18 'a' =~ qr/ÉA/b $^X $__FILE__\n};
}
else {
    print qq{ok - 18 'a' =~ qr/ÉA/b $^X $__FILE__\n};
}

if ('a' =~ qr/ÉA/i) {
    print qq{not ok - 19 'a' =~ qr/ÉA/i $^X $__FILE__\n};
}
else {
    print qq{ok - 19 'a' =~ qr/ÉA/i $^X $__FILE__\n};
}

if ('a' =~ qr/ÉA/ib) {
    print qq{not ok - 20 'a' =~ qr/ÉA/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 20 'a' =~ qr/ÉA/ib $^X $__FILE__\n};
}

if ('a' =~ qr/Éa/) {
    print qq{not ok - 21 'a' =~ qr/Éa/ $^X $__FILE__\n};
}
else {
    print qq{ok - 21 'a' =~ qr/Éa/ $^X $__FILE__\n};
}

if ('a' =~ qr/Éa/b) {
    print qq{not ok - 22 'a' =~ qr/Éa/b $^X $__FILE__\n};
}
else {
    print qq{ok - 22 'a' =~ qr/Éa/b $^X $__FILE__\n};
}

if ('a' =~ qr/Éa/i) {
    print qq{not ok - 23 'a' =~ qr/Éa/i $^X $__FILE__\n};
}
else {
    print qq{ok - 23 'a' =~ qr/Éa/i $^X $__FILE__\n};
}

if ('a' =~ qr/Éa/ib) {
    print qq{not ok - 24 'a' =~ qr/Éa/ib $^X $__FILE__\n};
}
else {
    print qq{ok - 24 'a' =~ qr/Éa/ib $^X $__FILE__\n};
}

if ('ÉA' =~ qr/A/) {
    print qq{not ok - 25 'ÉA' =~ qr/A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 25 'ÉA' =~ qr/A/ $^X $__FILE__\n};
}

if ('ÉA' =~ qr/A/b) {
    print qq{ok - 26 'ÉA' =~ qr/A/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 'ÉA' =~ qr/A/b $^X $__FILE__\n};
}

if ('ÉA' =~ qr/A/i) {
    print qq{not ok - 27 'ÉA' =~ qr/A/i $^X $__FILE__\n};
}
else {
    print qq{ok - 27 'ÉA' =~ qr/A/i $^X $__FILE__\n};
}

if ('ÉA' =~ qr/A/ib) {
    print qq{ok - 28 'ÉA' =~ qr/A/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 'ÉA' =~ qr/A/ib $^X $__FILE__\n};
}

if ('ÉA' =~ qr/a/) {
    print qq{not ok - 29 'ÉA' =~ qr/a/ $^X $__FILE__\n};
}
else {
    print qq{ok - 29 'ÉA' =~ qr/a/ $^X $__FILE__\n};
}

if ('ÉA' =~ qr/a/b) {
    print qq{not ok - 30 'ÉA' =~ qr/a/b $^X $__FILE__\n};
}
else {
    print qq{ok - 30 'ÉA' =~ qr/a/b $^X $__FILE__\n};
}

if ('ÉA' =~ qr/a/i) {
    print qq{not ok - 31 'ÉA' =~ qr/a/i $^X $__FILE__\n};
}
else {
    print qq{ok - 31 'ÉA' =~ qr/a/i $^X $__FILE__\n};
}

if ('ÉA' =~ qr/a/ib) {
    print qq{ok - 32 'ÉA' =~ qr/a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 'ÉA' =~ qr/a/ib $^X $__FILE__\n};
}

if ('Éa' =~ qr/A/) {
    print qq{not ok - 33 'Éa' =~ qr/A/ $^X $__FILE__\n};
}
else {
    print qq{ok - 33 'Éa' =~ qr/A/ $^X $__FILE__\n};
}

if ('Éa' =~ qr/A/b) {
    print qq{not ok - 34 'Éa' =~ qr/A/b $^X $__FILE__\n};
}
else {
    print qq{ok - 34 'Éa' =~ qr/A/b $^X $__FILE__\n};
}

if ('Éa' =~ qr/A/i) {
    print qq{not ok - 35 'Éa' =~ qr/A/i $^X $__FILE__\n};
}
else {
    print qq{ok - 35 'Éa' =~ qr/A/i $^X $__FILE__\n};
}

if ('Éa' =~ qr/A/ib) {
    print qq{ok - 36 'Éa' =~ qr/A/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 'Éa' =~ qr/A/ib $^X $__FILE__\n};
}

if ('Éa' =~ qr/a/) {
    print qq{not ok - 37 'Éa' =~ qr/a/ $^X $__FILE__\n};
}
else {
    print qq{ok - 37 'Éa' =~ qr/a/ $^X $__FILE__\n};
}

if ('Éa' =~ qr/a/b) {
    print qq{ok - 38 'Éa' =~ qr/a/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 'Éa' =~ qr/a/b $^X $__FILE__\n};
}

if ('Éa' =~ qr/a/i) {
    print qq{not ok - 39 'Éa' =~ qr/a/i $^X $__FILE__\n};
}
else {
    print qq{ok - 39 'Éa' =~ qr/a/i $^X $__FILE__\n};
}

if ('Éa' =~ qr/a/ib) {
    print qq{ok - 40 'Éa' =~ qr/a/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 'Éa' =~ qr/a/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/ÉA/) {
    print qq{not ok - 41 'ÉÉA' =~ qr/ÉA/ $^X $__FILE__\n};
}
else {
    print qq{ok - 41 'ÉÉA' =~ qr/ÉA/ $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/ÉA/b) {
    print qq{ok - 42 'ÉÉA' =~ qr/ÉA/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 42 'ÉÉA' =~ qr/ÉA/b $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/ÉA/i) {
    print qq{not ok - 43 'ÉÉA' =~ qr/ÉA/i $^X $__FILE__\n};
}
else {
    print qq{ok - 43 'ÉÉA' =~ qr/ÉA/i $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/ÉA/ib) {
    print qq{ok - 44 'ÉÉA' =~ qr/ÉA/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 44 'ÉÉA' =~ qr/ÉA/ib $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/Éa/) {
    print qq{not ok - 45 'ÉÉA' =~ qr/Éa/ $^X $__FILE__\n};
}
else {
    print qq{ok - 45 'ÉÉA' =~ qr/Éa/ $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/Éa/b) {
    print qq{not ok - 46 'ÉÉA' =~ qr/Éa/b $^X $__FILE__\n};
}
else {
    print qq{ok - 46 'ÉÉA' =~ qr/Éa/b $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/Éa/i) {
    print qq{not ok - 47 'ÉÉA' =~ qr/Éa/i $^X $__FILE__\n};
}
else {
    print qq{ok - 47 'ÉÉA' =~ qr/Éa/i $^X $__FILE__\n};
}

if ('ÉÉA' =~ qr/Éa/ib) {
    print qq{ok - 48 'ÉÉA' =~ qr/Éa/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 48 'ÉÉA' =~ qr/Éa/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/ÉA/) {
    print qq{not ok - 49 'ÉÉa' =~ qr/ÉA/ $^X $__FILE__\n};
}
else {
    print qq{ok - 49 'ÉÉa' =~ qr/ÉA/ $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/ÉA/b) {
    print qq{not ok - 50 'ÉÉa' =~ qr/ÉA/b $^X $__FILE__\n};
}
else {
    print qq{ok - 50 'ÉÉa' =~ qr/ÉA/b $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/ÉA/i) {
    print qq{not ok - 51 'ÉÉa' =~ qr/ÉA/i $^X $__FILE__\n};
}
else {
    print qq{ok - 51 'ÉÉa' =~ qr/ÉA/i $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/ÉA/ib) {
    print qq{ok - 52 'ÉÉa' =~ qr/ÉA/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 52 'ÉÉa' =~ qr/ÉA/ib $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/Éa/) {
    print qq{not ok - 53 'ÉÉa' =~ qr/Éa/ $^X $__FILE__\n};
}
else {
    print qq{ok - 53 'ÉÉa' =~ qr/Éa/ $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/Éa/b) {
    print qq{ok - 54 'ÉÉa' =~ qr/Éa/b $^X $__FILE__\n};
}
else {
    print qq{not ok - 54 'ÉÉa' =~ qr/Éa/b $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/Éa/i) {
    print qq{not ok - 55 'ÉÉa' =~ qr/Éa/i $^X $__FILE__\n};
}
else {
    print qq{ok - 55 'ÉÉa' =~ qr/Éa/i $^X $__FILE__\n};
}

if ('ÉÉa' =~ qr/Éa/ib) {
    print qq{ok - 56 'ÉÉa' =~ qr/Éa/ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 56 'ÉÉa' =~ qr/Éa/ib $^X $__FILE__\n};
}

__END__

