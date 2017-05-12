# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 521;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'noun'; }

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "abl.sg. of $noun");
    is($is->[5], $should->[5], "nom.pl. of $noun");
    is($is->[6], $should->[6], "gen.pl. of $noun");
    is($is->[7], $should->[7], "acc.pl. of $noun");
    is($is->[8], $should->[8], "dat.pl. of $noun");
    is($is->[9], $should->[9], "abl.pl. of $noun");
}

# masculine
form_ok('OKH', noun('OKH'), [ qw( OKH OKHEI OKH OKHAN OKHOTH
                                  OKHIT OKHIE OKHI OKHIN OKHITH ) ]);
form_ok('AIDHOS', noun('AIDHOS'), [ qw( AIDHOS AIDHEI AIDH AIDHAN AIDHOTH
                                        AIDHIT AIDHIE AIDHI AIDHIN AIDHITH ) ]);
form_ok('AESTAS', noun('AESTAS'), [ qw( AESTAS AESTAI AESTA AESTAN AESTATH
                                        AESTAIT AESTAIE AESTAI AESTAIN AESTAITH ) ]);

# neuter
form_ok('CITRO', noun('CITRO'), [ qw( CITRO CITROI CITROM CITRON CITROTH
                                      CITROI CITROIE CITROIM CITROIN CITROITH ) ]);
form_ok('URESTU', noun('URESTU'), [ qw( URESTU URESTUI URESTUM URESTUN URESTUTH
                                        URESTUI URESTUIE URESTUIM URESTUIN URESTUITH ) ]);
form_ok('FUELIS', noun('FUELIS'), [ qw( FUELIS FUELII FUELIM FUELIN FUELITH
                                        FUELUI FUELUIE FUELUIM FUELUIN FUELUITH ) ]);
form_ok('MANUS', noun('MANUS'), [ qw( MANUS MANOI MANO MANUN MANUTH
                                      MANUIT MANUIE MANUI MANUIN MANUITH ) ]);

# feminine
form_ok('AIDHA', noun('AIDHA'), [ qw( AIDHA AIDHAE AIDHAA AIDHAN AIDHAD
                                      AIDHET AIDHEIE AIDHEIM AIDHEIN AIDHEID ) ]);
form_ok('UNGE', noun('UNGE'), [ qw( UNGE UNGEI UNGEA UNGEN UNGED
                                    UNGET UNGEIE UNGEIM UNGEIN UNGEID ) ]);
form_ok('SURIS', noun('SURIS'), [ qw( SURIS SURIE SURIA SURIN SURID
                                      SURIAT SURIAE SURIAM SURIAN SURIAD ) ]);

# test general forms
# masculine
form_ok('GGG', noun('GGG'), [ qw( GGG GGGEI GGG GGGAN GGGOTH
                                  GGGIT GGGIE GGGI GGGIN GGGITH ) ]);
form_ok('GGGOS', noun('GGGOS'), [ qw( GGGOS GGGEI GGG GGGAN GGGOTH
                                      GGGIT GGGIE GGGI GGGIN GGGITH ) ]);
form_ok('GGGAS', noun('GGGAS'), [ qw( GGGAS GGGAI GGGA GGGAN GGGATH
                                      GGGAIT GGGAIE GGGAI GGGAIN GGGAITH ) ]);

# neuter
form_ok('GGGO', noun('GGGO'), [ qw( GGGO GGGOI GGGOM GGGON GGGOTH
                                    GGGOI GGGOIE GGGOIM GGGOIN GGGOITH ) ]);
form_ok('GGGU', noun('GGGU'), [ qw( GGGU GGGUI GGGUM GGGUN GGGUTH
                                    GGGUI GGGUIE GGGUIM GGGUIN GGGUITH ) ]);
# can't test generic neuter '-IS', but see at end
# form_ok('GGGIS', noun('GGGIS'), [ qw( GGGIS GGGII GGGIM GGGIN GGGITH
#                                       GGGUI GGGUIE GGGUIM GGGUIN GGGUITH ) ]);
form_ok('GGGUS', noun('GGGUS'), [ qw( GGGUS GGGOI GGGO GGGUN GGGUTH
                                      GGGUIT GGGUIE GGGUI GGGUIN GGGUITH ) ]);

# feminine
form_ok('GGGA', noun('GGGA'), [ qw( GGGA GGGAE GGGAA GGGAN GGGAD
                                    GGGET GGGEIE GGGEIM GGGEIN GGGEID ) ]);
form_ok('GGGE', noun('GGGE'), [ qw( GGGE GGGEI GGGEA GGGEN GGGED
                                    GGGET GGGEIE GGGEIM GGGEIN GGGEID ) ]);
form_ok('GGGIS', noun('GGGIS'), [ qw( GGGIS GGGIE GGGIA GGGIN GGGID
                                      GGGIAT GGGIAE GGGIAM GGGIAN GGGIAD ) ]);

# test neuter nouns
form_ok('ATITRIS', noun('ATITRIS'), [ qw( ATITRIS ATITRII ATITRIM ATITRIN ATITRITH
                                          ATITRUI ATITRUIE ATITRUIM ATITRUIN ATITRUITH ) ]);
form_ok('CRENIS', noun('CRENIS'), [ qw( CRENIS CRENII CRENIM CRENIN CRENITH
                                        CRENUI CRENUIE CRENUIM CRENUIN CRENUITH ) ]);
form_ok('DACTIS', noun('DACTIS'), [ qw( DACTIS DACTII DACTIM DACTIN DACTITH
                                        DACTUI DACTUIE DACTUIM DACTUIN DACTUITH ) ]);
form_ok('DROGIS', noun('DROGIS'), [ qw( DROGIS DROGII DROGIM DROGIN DROGITH
                                        DROGUI DROGUIE DROGUIM DROGUIN DROGUITH ) ]);
form_ok('FILIS', noun('FILIS'), [ qw( FILIS FILII FILIM FILIN FILITH
                                      FILUI FILUIE FILUIM FILUIN FILUITH ) ]);
form_ok('FUELIS', noun('FUELIS'), [ qw( FUELIS FUELII FUELIM FUELIN FUELITH
                                        FUELUI FUELUIE FUELUIM FUELUIN FUELUITH ) ]);
form_ok('ISCRENILIS', noun('ISCRENILIS'), [ qw( ISCRENILIS ISCRENILII ISCRENILIM ISCRENILIN ISCRENILITH
                                                ISCRENILUI ISCRENILUIE ISCRENILUIM ISCRENILUIN ISCRENILUITH ) ]);
form_ok('IULIS', noun('IULIS'), [ qw( IULIS IULII IULIM IULIN IULITH
                                      IULUI IULUIE IULUIM IULUIN IULUITH ) ]);
form_ok('KATTIS', noun('KATTIS'), [ qw( KATTIS KATTII KATTIM KATTIN KATTITH
                                        KATTUI KATTUIE KATTUIM KATTUIN KATTUITH ) ]);
form_ok('KILIS', noun('KILIS'), [ qw( KILIS KILII KILIM KILIN KILITH
                                      KILUI KILUIE KILUIM KILUIN KILUITH ) ]);
form_ok('KRAIS', noun('KRAIS'), [ qw( KRAIS KRAII KRAIM KRAIN KRAITH
                                      KRAUI KRAUIE KRAUIM KRAUIN KRAUITH ) ]);
form_ok('LENTILIS', noun('LENTILIS'), [ qw( LENTILIS LENTILII LENTILIM LENTILIN LENTILITH
                                            LENTILUI LENTILUIE LENTILUIM LENTILUIN LENTILUITH ) ]);
form_ok('LITIS', noun('LITIS'), [ qw( LITIS LITII LITIM LITIN LITITH
                                      LITUI LITUIE LITUIM LITUIN LITUITH ) ]);
form_ok('LOIS', noun('LOIS'), [ qw( LOIS LOII LOIM LOIN LOITH
                                    LOUI LOUIE LOUIM LOUIN LOUITH ) ]);
form_ok('MEIS', noun('MEIS'), [ qw( MEIS MEII MEIM MEIN MEITH
                                    MEUI MEUIE MEUIM MEUIN MEUITH ) ]);
form_ok('MIHIS', noun('MIHIS'), [ qw( MIHIS MIHII MIHIM MIHIN MIHITH
                                      MIHUI MIHUIE MIHUIM MIHUIN MIHUITH ) ]);
form_ok('MILGIS', noun('MILGIS'), [ qw( MILGIS MILGII MILGIM MILGIN MILGITH
                                        MILGUI MILGUIE MILGUIM MILGUIN MILGUITH ) ]);
form_ok('MITIS', noun('MITIS'), [ qw( MITIS MITII MITIM MITIN MITITH
                                      MITUI MITUIE MITUIM MITUIN MITUITH ) ]);
form_ok('NACUIS', noun('NACUIS'), [ qw( NACUIS NACUII NACUIM NACUIN NACUITH
                                        NACUUI NACUUIE NACUUIM NACUUIN NACUUITH ) ]);
form_ok('NMURTHANIS', noun('NMURTHANIS'), [ qw( NMURTHANIS NMURTHANII NMURTHANIM NMURTHANIN NMURTHANITH
                                                NMURTHANUI NMURTHANUIE NMURTHANUIM NMURTHANUIN NMURTHANUITH ) ]);
form_ok('NOTHONIS', noun('NOTHONIS'), [ qw( NOTHONIS NOTHONII NOTHONIM NOTHONIN NOTHONITH
                                            NOTHONUI NOTHONUIE NOTHONUIM NOTHONUIN NOTHONUITH ) ]);
form_ok('OBELIS', noun('OBELIS'), [ qw( OBELIS OBELII OBELIM OBELIN OBELITH
                                        OBELUI OBELUIE OBELUIM OBELUIN OBELUITH ) ]);
form_ok('ORAIS', noun('ORAIS'), [ qw( ORAIS ORAII ORAIM ORAIN ORAITH
                                      ORAUI ORAUIE ORAUIM ORAUIN ORAUITH ) ]);
form_ok('PENGIS', noun('PENGIS'), [ qw( PENGIS PENGII PENGIM PENGIN PENGITH
                                        PENGUI PENGUIE PENGUIM PENGUIN PENGUITH ) ]);
form_ok('PLASIS', noun('PLASIS'), [ qw( PLASIS PLASII PLASIM PLASIN PLASITH
                                        PLASUI PLASUIE PLASUIM PLASUIN PLASUITH ) ]);
form_ok('RAIS', noun('RAIS'), [ qw( RAIS RAII RAIM RAIN RAITH
                                    RAUI RAUIE RAUIM RAUIN RAUITH ) ]);
form_ok('SABLIS', noun('SABLIS'), [ qw( SABLIS SABLII SABLIM SABLIN SABLITH
                                        SABLUI SABLUIE SABLUIM SABLUIN SABLUITH ) ]);
form_ok('SCRAIS', noun('SCRAIS'), [ qw( SCRAIS SCRAII SCRAIM SCRAIN SCRAITH
                                        SCRAUI SCRAUIE SCRAUIM SCRAUIN SCRAUITH ) ]);
form_ok('SEGLIS', noun('SEGLIS'), [ qw( SEGLIS SEGLII SEGLIM SEGLIN SEGLITH
                                        SEGLUI SEGLUIE SEGLUIM SEGLUIN SEGLUITH ) ]);
form_ok('SPAIS', noun('SPAIS'), [ qw( SPAIS SPAII SPAIM SPAIN SPAITH
                                      SPAUI SPAUIE SPAUIM SPAUIN SPAUITH ) ]);
form_ok('SUIS', noun('SUIS'), [ qw( SUIS SUII SUIM SUIN SUITH
                                    SUUI SUUIE SUUIM SUUIN SUUITH ) ]);
form_ok('VELAIS', noun('VELAIS'), [ qw( VELAIS VELAII VELAIM VELAIN VELAITH
                                        VELAUI VELAUIE VELAUIM VELAUIN VELAUITH ) ]);
form_ok('ZURRIS', noun('ZURRIS'), [ qw( ZURRIS ZURRII ZURRIM ZURRIN ZURRITH
                                        ZURRUI ZURRUIE ZURRUIM ZURRUIN ZURRUITH ) ]);
