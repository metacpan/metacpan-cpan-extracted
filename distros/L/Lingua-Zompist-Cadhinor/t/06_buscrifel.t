# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 451;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'buscrifel'; }

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "I.sg. of $verb");
    is($is->[1], $should->[1], "II.sg. of $verb");
    is($is->[2], $should->[2], "III.sg. of $verb");
    is($is->[3], $should->[3], "I.pl. of $verb");
    is($is->[4], $should->[4], "II.pl. of $verb");
    is($is->[5], $should->[5], "III.pl. of $verb");
}

form_ok('DUMEC',  buscrifel('DUMEC' ), [ qw( DUMECAO  DUMECEIS  DUMECES  DUMECOM  DUMECOS  DUMECONT  ) ]);
form_ok('KEKAN',  buscrifel('KEKAN' ), [ qw( KEKINAI  KEKINES   KEKINET  KEKINAM  KEKINUS  KEKINONT  ) ]);
form_ok('NOMEN',  buscrifel('NOMEN' ), [ qw( NOMINAI  NOMINES   NOMINET  NOMINEM  NOMINES  NOMINENT  ) ]);
form_ok('CLAGER', buscrifel('CLAGER'), [ qw( CLAGIRU  CLAGIROS  CLAGIRIS CLAGIRUM CLAGIRUS CLAGIRUNT ) ]);
form_ok('PARIR',  buscrifel('PARIR' ), [ qw( PARIRU   PARIROS   PARIRIS  PARIRUM  PARIRUS  PARIRINT  ) ]);

form_ok('SUDRIR', buscrifel('SUDRIR'), [ qw( SUDDIRU  SUDDIROS  SUDDIRIS SUDDIRUM SUDDIRUS SUDDIRINT ) ]);

form_ok('ESAN',   buscrifel('ESAN'  ), [ qw( ESCAO    ESCEIS    ESCES    ESCOM    ESCOS    ESCONT    ) ]);

# test general forms
form_ok('GGGEC',  buscrifel('GGGEC' ), [ qw( GGGECAO  GGGECEIS  GGGECES  GGGECOM  GGGECOS  GGGECONT  ) ]);
form_ok('GGGAN',  buscrifel('GGGAN' ), [ qw( GGGINAI  GGGINES   GGGINET  GGGINAM  GGGINUS  GGGINONT  ) ]);
form_ok('GGGEN',  buscrifel('GGGEN' ), [ qw( GGGINAI  GGGINES   GGGINET  GGGINEM  GGGINES  GGGINENT  ) ]);
form_ok('GGGER',  buscrifel('GGGER' ), [ qw( GGGIRU   GGGIROS   GGGIRIS  GGGIRUM  GGGIRUS  GGGIRUNT  ) ]);
form_ok('GGGIR',  buscrifel('GGGIR' ), [ qw( GGGIRU   GGGIROS   GGGIRIS  GGGIRUM  GGGIRUS  GGGIRINT  ) ]);

form_ok('BBRER',  buscrifel('BBRER' ), [ qw( BBBIRU   BBBIROS   BBBIRIS  BBBIRUM  BBBIRUS  BBBIRUNT  ) ]);
form_ok('PPRER',  buscrifel('PPRER' ), [ qw( PPPIRU   PPPIROS   PPPIRIS  PPPIRUM  PPPIRUS  PPPIRUNT  ) ]);
form_ok('DDRER',  buscrifel('DDRER' ), [ qw( DDDIRU   DDDIROS   DDDIRIS  DDDIRUM  DDDIRUS  DDDIRUNT  ) ]);
form_ok('TTRER',  buscrifel('TTRER' ), [ qw( TTTIRU   TTTIROS   TTTIRIS  TTTIRUM  TTTIRUS  TTTIRUNT  ) ]);
form_ok('GGRER',  buscrifel('GGRER' ), [ qw( GGGIRU   GGGIROS   GGGIRIS  GGGIRUM  GGGIRUS  GGGIRUNT  ) ]);
form_ok('KKRER',  buscrifel('KKRER' ), [ qw( KKKIRU   KKKIROS   KKKIRIS  KKKIRUM  KKKIRUS  KKKIRUNT  ) ]);
form_ok('CCRER',  buscrifel('CCRER' ), [ qw( CCCIRU   CCCIROS   CCCIRIS  CCCIRUM  CCCIRUS  CCCIRUNT  ) ]);
form_ok('FFRER',  buscrifel('FFRER' ), [ qw( FFFIRU   FFFIROS   FFFIRIS  FFFIRUM  FFFIRUS  FFFIRUNT  ) ]);
form_ok('VVRER',  buscrifel('VVRER' ), [ qw( VVVIRU   VVVIROS   VVVIRIS  VVVIRUM  VVVIRUS  VVVIRUNT  ) ]);
form_ok('RRRER',  buscrifel('RRRER' ), [ qw( RRRIRU   RRRIROS   RRRIRIS  RRRIRUM  RRRIRUS  RRRIRUNT  ) ]);
form_ok('SSRER',  buscrifel('SSRER' ), [ qw( SSSIRU   SSSIROS   SSSIRIS  SSSIRUM  SSSIRUS  SSSIRUNT  ) ]);
form_ok('ZZRER',  buscrifel('ZZRER' ), [ qw( ZZZIRU   ZZZIROS   ZZZIRIS  ZZZIRUM  ZZZIRUS  ZZZIRUNT  ) ]);
form_ok('MMRER',  buscrifel('MMRER' ), [ qw( MMMIRU   MMMIROS   MMMIRIS  MMMIRUM  MMMIRUS  MMMIRUNT  ) ]);
form_ok('NNRER',  buscrifel('NNRER' ), [ qw( NNNIRU   NNNIROS   NNNIRIS  NNNIRUM  NNNIRUS  NNNIRUNT  ) ]);
form_ok('LLRER',  buscrifel('LLRER' ), [ qw( LLLIRU   LLLIROS   LLLIRIS  LLLIRUM  LLLIRUS  LLLIRUNT  ) ]);
form_ok('THRER',  buscrifel('THRER' ), [ qw( THTHIRU  THTHIROS  THTHIRIS THTHIRUM THTHIRUS THTHIRUNT ) ]);
form_ok('DHRER',  buscrifel('DHRER' ), [ qw( DHDHIRU  DHDHIROS  DHDHIRIS DHDHIRUM DHDHIRUS DHDHIRUNT ) ]);
form_ok('KHRER',  buscrifel('KHRER' ), [ qw( KHKHIRU  KHKHIROS  KHKHIRIS KHKHIRUM KHKHIRUS KHKHIRUNT ) ]);

form_ok('BBRIR',  buscrifel('BBRIR' ), [ qw( BBBIRU   BBBIROS   BBBIRIS  BBBIRUM  BBBIRUS  BBBIRINT  ) ]);
form_ok('PPRIR',  buscrifel('PPRIR' ), [ qw( PPPIRU   PPPIROS   PPPIRIS  PPPIRUM  PPPIRUS  PPPIRINT  ) ]);
form_ok('DDRIR',  buscrifel('DDRIR' ), [ qw( DDDIRU   DDDIROS   DDDIRIS  DDDIRUM  DDDIRUS  DDDIRINT  ) ]);
form_ok('TTRIR',  buscrifel('TTRIR' ), [ qw( TTTIRU   TTTIROS   TTTIRIS  TTTIRUM  TTTIRUS  TTTIRINT  ) ]);
form_ok('GGRIR',  buscrifel('GGRIR' ), [ qw( GGGIRU   GGGIROS   GGGIRIS  GGGIRUM  GGGIRUS  GGGIRINT  ) ]);
form_ok('KKRIR',  buscrifel('KKRIR' ), [ qw( KKKIRU   KKKIROS   KKKIRIS  KKKIRUM  KKKIRUS  KKKIRINT  ) ]);
form_ok('CCRIR',  buscrifel('CCRIR' ), [ qw( CCCIRU   CCCIROS   CCCIRIS  CCCIRUM  CCCIRUS  CCCIRINT  ) ]);
form_ok('FFRIR',  buscrifel('FFRIR' ), [ qw( FFFIRU   FFFIROS   FFFIRIS  FFFIRUM  FFFIRUS  FFFIRINT  ) ]);
form_ok('VVRIR',  buscrifel('VVRIR' ), [ qw( VVVIRU   VVVIROS   VVVIRIS  VVVIRUM  VVVIRUS  VVVIRINT  ) ]);
form_ok('RRRIR',  buscrifel('RRRIR' ), [ qw( RRRIRU   RRRIROS   RRRIRIS  RRRIRUM  RRRIRUS  RRRIRINT  ) ]);
form_ok('SSRIR',  buscrifel('SSRIR' ), [ qw( SSSIRU   SSSIROS   SSSIRIS  SSSIRUM  SSSIRUS  SSSIRINT  ) ]);
form_ok('ZZRIR',  buscrifel('ZZRIR' ), [ qw( ZZZIRU   ZZZIROS   ZZZIRIS  ZZZIRUM  ZZZIRUS  ZZZIRINT  ) ]);
form_ok('MMRIR',  buscrifel('MMRIR' ), [ qw( MMMIRU   MMMIROS   MMMIRIS  MMMIRUM  MMMIRUS  MMMIRINT  ) ]);
form_ok('NNRIR',  buscrifel('NNRIR' ), [ qw( NNNIRU   NNNIROS   NNNIRIS  NNNIRUM  NNNIRUS  NNNIRINT  ) ]);
form_ok('LLRIR',  buscrifel('LLRIR' ), [ qw( LLLIRU   LLLIROS   LLLIRIS  LLLIRUM  LLLIRUS  LLLIRINT  ) ]);
form_ok('THRIR',  buscrifel('THRIR' ), [ qw( THTHIRU  THTHIROS  THTHIRIS THTHIRUM THTHIRUS THTHIRINT ) ]);
form_ok('DHRIR',  buscrifel('DHRIR' ), [ qw( DHDHIRU  DHDHIROS  DHDHIRIS DHDHIRUM DHDHIRUS DHDHIRINT ) ]);
form_ok('KHRIR',  buscrifel('KHRIR' ), [ qw( KHKHIRU  KHKHIROS  KHKHIRIS KHKHIRUM KHKHIRUS KHKHIRINT ) ]);

# test stem-changing verbs
form_ok('KESCEN', buscrifel('KESCEN'), [ qw( KESSIO KESSIOS KESSAE KESSUOM KESSUES KESSIONT ) ]);
form_ok('TOSCEN', buscrifel('TOSCEN'), [ qw( TOSSIO TOSSIOS TOSSAE TOSSUOM TOSSUES TOSSIONT ) ]);
form_ok('FAR',    buscrifel('FAR'   ), [ qw( FASSI  FASSIUS FASSU  FASSUM  FASSUS  FASSIUNT ) ]);
form_ok('LESCEN', buscrifel('LESCEN'), [ qw( LESSIO LESSIOS LESSAE LESSUOM LESSUES LESSIONT ) ]);

form_ok('SALTER', buscrifel('SALTER'), [ qw( SELSIE SELSIES SELSE  SELSEM  SELSES  SELSIENT ) ]);
form_ok('VALTER', buscrifel('VALTER'), [ qw( VELSIE VELSIES VELSE  VELSEM  VELSES  VELSIENT ) ]);
form_ok('METTAN', buscrifel('METTAN'), [ qw( MESSIO MESSIOS MESSAE MESSUOM MESSUOS MESSIONT ) ]);

form_ok('CURREC', buscrifel('CURREC'), [ qw( CORSI  CORSIUS CORSU  CORSUM  CORSUS  CORSIUNT ) ]);
form_ok('DESIEN', buscrifel('DESIEN'), [ qw( DESSIO DESSIOS DESSAE DESSUOM DESSUES DESSIONT ) ]);
form_ok('STERER', buscrifel('STERER'), [ qw( STERSIE STERSIES STERSE STERSEM STERSES STERSIENT ) ]);
form_ok('MERIR',  buscrifel('MERIR' ), [ qw( MERSIE MERSIES MERSAE MERSEM  MERSES  MERSIENT ) ]);
form_ok('FERIEN', buscrifel('FERIEN'), [ qw( FERSIO FERSIOS FERSAE FERSUOM FERSUES FERSIONT ) ]);
form_ok('LEILEN', buscrifel('LEILEN'), [ qw( LELSIO LELSIOS LELSAE LELSUOM LELSUES LELSIONT ) ]);
form_ok('NURIR',  buscrifel('NURIR' ), [ qw( NORSIE NORSIES NORSAE NORSEM  NORSES  NORSIENT ) ]);
form_ok('AMARIR', buscrifel('AMARIR'), [ qw( AMERSIE AMERSIES AMERSAE AMERSEM AMERSES AMERSIENT ) ]);

form_ok('DAN',    buscrifel('DAN'   ), [ qw( DONIO  DONIOS  DONAE  DONUOM  DONUOS  DONIONT ) ]);
form_ok('NOER',   buscrifel('NOER'  ), [ qw( NOSIE  NOSIES  NOSE   NOSEM   NOSES   NOSIENT ) ]);

form_ok('PUGAN',  buscrifel('PUGAN' ), [ qw( POGIO  POGIOS  POGAE  POGUOM  POGUOS  POGIONT ) ]);
form_ok('PUHAN',  buscrifel('PUHAN' ), [ qw( POHIO  POHIOS  POHAE  POHUOM  POHUOS  POHIONT ) ]);
form_ok('BRIGAN', buscrifel('BRIGAN'), [ qw( BROGIO BROGIOS BROGAE BROGUOM BROGUOS BROGIONT ) ]);
form_ok('SUBRAN', buscrifel('SUBRAN'), [ qw( SOBRIO SOBRIOS SOBRAE SOBRUOM SOBRUOS SOBRIONT ) ]);
form_ok('DUCIR',  buscrifel('DUCIR' ), [ qw( DOCIE  DOCIES  DOCAE  DOCEM   DOCES   DOCIENT ) ]);
form_ok('LEGAN',  buscrifel('LEGAN' ), [ qw( LOGIO  LOGIOS  LOGAE  LOGUOM  LOGUOS  LOGIONT ) ]);
form_ok('LAUDAN', buscrifel('LAUDAN'), [ qw( LODIO  LODIOS  LODAE  LODUOM  LODUOS  LODIONT ) ]);
form_ok('KUSAN',  buscrifel('KUSAN' ), [ qw( KOSSIO KOSSIOS KOSSAE KOSSUOM KOSSUOS KOSSIONT ) ]);
form_ok('KETHEN', buscrifel('KETHEN'), [ qw( KOTHIO KOTHIOS KOTHAE KOTHUOM KOTHUES KOTHIONT ) ]);
form_ok('IUSIR',  buscrifel('IUSIR' ), [ qw( IOSSIE IOSSIES IOSSAE IOSSEM  IOSSES  IOSSIENT ) ]);
