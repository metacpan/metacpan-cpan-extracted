######################################################################
#
# 0319_euc_x0212_fill.t - JIS X 0212 restoration mechanism for
#                          'euc1990'/'jis1990' (see the __EUC_X0212__
#                          block appended to __DATA__ in Jacode4e.pm,
#                          and make__DATA__/JIS/fill_euc_codeset3.pl)
#
# Verifies structural properties of the fill, independent of any one
# example character: total JIS X 0212 repertoire size, how much of it
# is restored (only characters that already have a row through some
# other encoding), that eras other than 1990 are untouched, that a
# JIS X 0208 code always wins over a JIS X 0212 code for the same
# character, and that no EUC-JP code set 3 code is assigned twice.
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Jacode4e;

my $testno = 1;
sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }

print "1..8\n";

my $JIS0212_TXT = "$FindBin::Bin/../make__DATA__/LetsJ/http.__www.unicode.org_Public_MAPPINGS_OBSOLETE_EASTASIA_JIS_JIS0212.TXT";

sub utf8_of_ucs {
    my($ucs) = @_;
    if    ($ucs <  0x80)  { return chr($ucs); }
    elsif ($ucs <  0x800) { return chr(0xC0|($ucs>>6)) . chr(0x80|($ucs&0x3F)); }
    else                  { return chr(0xE0|($ucs>>12)) . chr(0x80|(($ucs>>6)&0x3F)) . chr(0x80|($ucs&0x3F)); }
}

my $SENTINEL = "\x01\x02";
my($total, $mapped, $geta) = (0, 0, 0);
my %euc_seen = ();
my $duplicate_euc = 0;

open(JIS0212_TXT_FH, "<$JIS0212_TXT") or die "cannot open $JIS0212_TXT: $!\n";
while (<JIS0212_TXT_FH>) {
    next if /^#/;
    chomp;
    my($j, $u) = split(/\t/, $_);
    next unless defined $u;
    next unless $j =~ /^0x([0-9A-F]{2})([0-9A-F]{2})$/;
    next unless $u =~ /^0x([0-9A-F]{4})$/;
    my $ucs  = hex($1);
    my $utf8 = utf8_of_ucs($ucs);
    $total++;

    my $line = $utf8;
    Jacode4e::convert(\$line, 'euc1990', 'utf8', { 'GETA' => $SENTINEL });
    if ($line eq $SENTINEL) {
        $geta++;
    }
    else {
        $mapped++;
        $euc_seen{$line}++;
        $duplicate_euc++ if $euc_seen{$line} > 1;
    }
}
close(JIS0212_TXT_FH);

# 1. total JIS X 0212 repertoire size in the bundled source table
ok($total == 6067, "JIS0212.TXT repertoire size is 6067 (got $total)");

# 2. restored coverage: characters that already had a row elsewhere
ok($mapped == 2959, "euc1990 restores 2959 of 6067 JIS X 0212 characters (got $mapped)");

# 3. the remainder (no row anywhere else) is still GETA
ok($geta == 3108, "the remaining 3108 (no other-encoding row) stay GETA (got $geta)");
ok(($mapped + $geta) == $total, "restored + GETA accounts for the whole repertoire ($mapped + $geta = @{[$mapped+$geta]}, want $total)");

# 4. no EUC-JP code set 3 code is assigned to two different characters
ok($duplicate_euc == 0, "no code set 3 target is assigned twice (duplicates=$duplicate_euc)");

# 5. a character that is in BOTH JIS X 0208-1990 and JIS X 0212 keeps
#    its JIS X 0208 (code set 1) code, never code set 3: ASCII tilde
#    U+007E is JIS X 0212 code 0x2237 in JIS0212.TXT, but euc1990
#    already has it as plain ASCII 0x7E.
{
    my $line = "\x7E";
    Jacode4e::convert(\$line, 'euc1990', 'utf8');
    ok($line eq "\x7E", "JIS X 0208/ASCII mapping wins over JIS X 0212 for the same character (got @{[uc unpack('H*',$line)]} want 7E)");
}

# 6. eras other than 1990 are completely untouched by the fill
#    (U+00A1, restored in euc1990, stays GETA in euc1978/euc1983)
for my $era (qw(euc1978 euc1983)) {
    my $line = "\xC2\xA1";
    Jacode4e::convert(\$line, $era, 'utf8', { 'GETA' => $SENTINEL });
    ok($line eq $SENTINEL, "$era is unaffected by the JIS X 0212 fill (U+00A1 still GETA)");
}
