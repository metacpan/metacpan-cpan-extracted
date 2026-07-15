######################################################################
#
# fill_euc_codeset3.pl
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com> in a CPAN
######################################################################

# Regenerates the "__EUC_X0212__" supplement appended after the main
# __DATA__ table in lib/Jacode4e.pm:
#
#     perl JIS/fill_euc_codeset3.pl > EUC_X0212_SUPPLEMENT.txt
#
# then replace everything from the "__EUC_X0212__" line to the end of
# lib/Jacode4e.pm with:
#
#     __EUC_X0212__
#     (contents of EUC_X0212_SUPPLEMENT.txt)
#
# Each output line is "GLGL UUUU": GLGL is the two JIS X 0212 GL
# octets (0x21-0x7E each, hex, high bit NOT set), UUUU is the Unicode
# BMP code point (hex). Jacode4e.pm reads this block at load time,
# AFTER 'euc1990' has been built from 'sjis1990' (see the comment
# above the "JIS X 0212 (EUC-JP code set 3 ...) supplement" block in
# lib/Jacode4e.pm), and for every table row whose Unicode code point
# matches a line here, fills euc1990's SS3 (0x8F + GLGL with the high
# bit set) form -- UNLESS that row already has a euc1990 code from
# JIS X 0208-1990 (sjis1990 always wins), and UNLESS the resulting
# SS3 code was already given to an earlier row (first row in __DATA__
# order wins, so the mapping stays one-to-one and deterministic; see
# t/0319_euc_x0212_fill.t). Because of this row-order-dependent
# dedup, filling happens at Jacode4e.pm load time against the actual
# table, not here.
#
# When the SOURCE Unicode-mapping table below assigns two or more
# JIS X 0212 GL octet pairs to the SAME Unicode code point, the LAST
# one in the source file wins (this only affects which GL pair is
# recorded per Unicode code point; it is independent of the row-order
# dedup done at Jacode4e.pm load time, described above).
#
# A character whose ONLY repertoire membership is JIS X 0212 has no
# row in the table at all (no other encoding maps it), so it is not
# affected by this block and remains GETA; see Changes and
# t/0312_euc_codeset3.t for the resulting coverage.
#
# JIS X 0212 (1990) to Unicode 1.1 Table
# http://www.unicode.org/Public/MAPPINGS/OBSOLETE/EASTASIA/JIS/JIS0212.TXT

use strict; die $_ if ($_=`$^X -cw @{[__FILE__]} 2>&1`) !~ /^.+ syntax OK$/;
use File::Basename;

my %gl_by_unicode = ();
my $JIS0212_TXT = File::Basename::dirname(__FILE__) . '/../LetsJ/http.__www.unicode.org_Public_MAPPINGS_OBSOLETE_EASTASIA_JIS_JIS0212.TXT';
open(JIS0212_TXT, $JIS0212_TXT) or die "@{[__FILE__]} cannot open '$JIS0212_TXT'\n";
while (<JIS0212_TXT>) {
    chomp;
    next if /^#/;
    my($jisx0212, $unicode) = split(/\t/, $_);
    next if not defined $unicode;
    my($gl1, $gl2) = $jisx0212 =~ /^0x([0123456789ABCDEF]{2})([0123456789ABCDEF]{2})$/;
    next if not defined $gl1;
    my($ucs) = $unicode =~ /^0x([0123456789ABCDEF]{4})$/;
    next if not defined $ucs;

    # last line in the source file wins for a given Unicode code point
    $gl_by_unicode{$ucs} = "$gl1$gl2";
}
close(JIS0212_TXT);

binmode(STDOUT);
for my $ucs (sort keys %gl_by_unicode) {
    print "$gl_by_unicode{$ucs} $ucs\n";
}

__END__
