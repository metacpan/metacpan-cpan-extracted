use Test::More tests => 3;
BEGIN { use_ok('Lingua::EO::Supersignoj') };

my $out;

my $transkodigilo = Lingua::EO::Supersignoj->nova(de => 'X');
can_ok($transkodigilo, qw(transkodigu de al u U));

for (qw(X x H h poste fronte apostrofoj iso unikodo)) {
    $transkodigilo->al = $_;
    $out .= $transkodigilo->transkodigu(
        'Laux Ludoviko Zamenhof bongustas ' .
        'fresxa cxecxa mangxajxo kun spicoj.'
    );
}
use utf8;
ok($out eq 
"Laux Ludoviko Zamenhof bongustas fresxa cxecxa mangxajxo kun spicoj." .
"Laux Ludoviko Zamenhof bongustas fresxa cxecxa mangxajxo kun spicoj." .
"Lauw Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj." .
"Lauw Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj." .
"Lau^ Ludoviko Zamenhof bongustas fres^a c^ec^a mang^aj^o kun spicoj." .
"La^u Ludoviko Zamenhof bongustas fre^sa ^ce^ca man^ga^jo kun spicoj." .
"Lau' Ludoviko Zamenhof bongustas fres'a c'ec'a mang'aj'o kun spicoj." .
"La\x{fd} Ludoviko Zamenhof bongustas fre\x{fe}a \x{e6}e\x{e6}a man\x{f8}a\x{bc}o kun spicoj." .
"La\x{16d} Ludoviko Zamenhof bongustas fre\x{15d}a \x{109}e\x{109}a man\x{11d}a\x{135}o kun spicoj.");

