# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More tests => 1;
use Carp;

ok(1);

__END__

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'budemeric'; }

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

form_ok('LIUBEC', budemeric('LIUBEC'), [ qw( LIUBETAO LIUBETEIS LIUBETES LIUBETOM LIUBETOS LIUBETONT ) ]);
TODO: {
    local $TODO = "LAUDAN and LEILEN have a different remote stem, but the paradigm is wrong";
    form_ok('LAUDAN', budemeric('LAUDAN'), [ qw( LAUDEMAI LAUDEMES  LAUDEMET LAUDEMAM LAUDEMUS LAUDEMONT ) ]);
    form_ok('LEILEN', budemeric('LEILEN'), [ qw( LEILEMAI LEILEMES  LEILEMET LEILEMEM LEILEMES LEILEMENT ) ]);
}
form_ok('CLAGER', budemeric('CLAGER'), [ qw( CLAGETU  CLAGETOS  CLAGETIS CLAGETUM CLAGETUS CLAGETINT ) ]);
TODO: {
    local $TODO = "NURIR has a different remote stem, but the paradigm is wrong";
    form_ok('NURIR',  budemeric('NURIR' ), [ qw( NURETU   NURETOS   NURETIS  NURETUM  NURETUS  NURETUNT  ) ]);
}

form_ok('ESAN',   budemeric('ESAN'  ), [ qw( ESTAO    ESTEIS    ESTES    ESTOM    ESTOS    ESTONT    ) ]);

# test general forms
form_ok('GGGEC',  budemeric('GGGEC' ), [ qw( GGGETAO  GGGETEIS  GGGETES  GGGETOM  GGGETOS  GGGETONT  ) ]);
form_ok('GGGAN',  budemeric('GGGAN' ), [ qw( GGGEMAI  GGGEMES   GGGEMET  GGGEMAM  GGGEMUS  GGGEMONT  ) ]);
form_ok('GGGEN',  budemeric('GGGEN' ), [ qw( GGGEMAI  GGGEMES   GGGEMET  GGGEMEM  GGGEMES  GGGEMENT  ) ]);
form_ok('GGGER',  budemeric('GGGER' ), [ qw( GGGETU   GGGETOS   GGGETIS  GGGETUM  GGGETUS  GGGETINT  ) ]);
form_ok('GGGIR',  budemeric('GGGIR' ), [ qw( GGGETU   GGGETOS   GGGETIS  GGGETUM  GGGETUS  GGGETUNT  ) ]);

# test stem-changing verbs
form_ok('KESCEN', budemeric('KESCEN'), [ qw( KESSAI KESSEIS KESSET KESSEM KESSES  KESSENT ) ]);
form_ok('TOSCEN', budemeric('TOSCEN'), [ qw( TOSSAI TOSSEIS TOSSET TOSSEM TOSSES  TOSSENT ) ]);
form_ok('FAR',    budemeric('FAR'   ), [ qw( FASSAO FASSEOS FASSES FASSOM FASSOUS FASSONT ) ]);
form_ok('LESCEN', budemeric('LESCEN'), [ qw( LESSAI LESSEIS LESSET LESSEM LESSES  LESSENT ) ]);

form_ok('SALTER', budemeric('SALTER'), [ qw( SELSU  SELSEUS SELSIT SELSUM SELSUS  SELSINT ) ]);
form_ok('VALTER', budemeric('VALTER'), [ qw( VELSU  VELSEUS VELSIT VELSUM VELSUS  VELSINT ) ]);
form_ok('METTAN', budemeric('METTAN'), [ qw( MESSAI MESSEIS MESSET MESSAM MESSUS  MESSONT ) ]);

form_ok('CURREC', budemeric('CURREC'), [ qw( CORSAO CORSEOS CORSES CORSOM CORSOUS CORSONT ) ]);
form_ok('DESIEN', budemeric('DESIEN'), [ qw( DESSAI DESSEIS DESSET DESSEM DESSES  DESSENT ) ]);
form_ok('STERER', budemeric('STERER'), [ qw( STERSU STERSEUS STERSIT STERSUM STERSUS STERSINT ) ]);
form_ok('MERIR',  budemeric('MERIR' ), [ qw( MERSU  MERSEUS MERSET MERSUM MERSUS  MERSUNT ) ]);
form_ok('FERIEN', budemeric('FERIEN'), [ qw( FERSAI FERSEIS FERSET FERSEM FERSES  FERSENT ) ]);
form_ok('LEILEN', budemeric('LEILEN'), [ qw( LELSAI LELSEIS LELSET LELSEM LELSES  LELSENT ) ]);
form_ok('NURIR',  budemeric('NURIR' ), [ qw( NORSU  NORSEUS NORSET NORSUM NORSUS  NORSUNT ) ]);
form_ok('AMARIR', budemeric('AMARIR'), [ qw( AMERSU AMERSEUS AMERSET AMERSUM AMERSUS AMERSUNT ) ]);

form_ok('DAN',    budemeric('DAN'   ), [ qw( DONAI  DONEIS  DONET  DONAM  DONUS   DONONT ) ]);
form_ok('NOER',   budemeric('NOER'  ), [ qw( NOSU   NOSEUS  NOSIT  NOSUM  NOSUS   NOSINT ) ]);

form_ok('PUGAN',  budemeric('PUGAN' ), [ qw( POGAI  POGEIS  POGET  POGAM  POGUS   POGONT ) ]);
form_ok('PUHAN',  budemeric('PUHAN' ), [ qw( POHAI  POHEIS  POHET  POHAM  POHUS   POHONT ) ]);
form_ok('BRIGAN', budemeric('BRIGAN'), [ qw( BROGAI BROGEIS BROGET BROGAM BROGUS  BROGONT ) ]);
form_ok('SUBRAN', budemeric('SUBRAN'), [ qw( SOBRAI SOBREIS SOBRET SOBRAM SOBRUS  SOBRONT ) ]);
form_ok('DUCIR',  budemeric('DUCIR' ), [ qw( DOCU   DOCEUS  DOCET  DOCUM  DOCUS   DOCUNT ) ]);
form_ok('LEGAN',  budemeric('LEGAN' ), [ qw( LOGAI  LOGEIS  LOGET  LOGAM  LOGUS   LOGONT ) ]);
form_ok('LAUDAN', budemeric('LAUDAN'), [ qw( LODAI  LODEIS  LODET  LODAM  LODUS   LODONT ) ]);
form_ok('KUSAN',  budemeric('KUSAN' ), [ qw( KOSSAI KOSSEIS KOSSET KOSSAM KOSSUS  KOSSONT ) ]);
form_ok('KETHEN', budemeric('KETHEN'), [ qw( KOTHAI KOTHEIS KOTHET KOTHEM KOTHES  KOTHENT ) ]);
form_ok('IUSIR',  budemeric('IUSIR' ), [ qw( IOSSU  IOSSEUS IOSSET IOSSUM IOSSUS  IOSSUNT ) ]);
