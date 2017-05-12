# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 583;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'dynamic'; }

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ == 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "I.sg. of $verb");
    is($is->[1], $should->[1], "II.sg. of $verb");
    is($is->[2], $should->[2], "III.sg. of $verb");
    is($is->[3], $should->[3], "I.pl. of $verb");
    is($is->[4], $should->[4], "II.pl. of $verb");
    is($is->[5], $should->[5], "III.pl. of $verb");
}

# dynamic definite present
form_ok('DUMEC',  dynamic('DUMEC',  'prilise', 'demeric'), [ qw( DUMUI  DUMUIS  DUMUT  DUMIM  DUMIS  DUMINT  ) ]);
form_ok('KEKAN',  dynamic('KEKAN',  'prilise', 'demeric'), [ qw( KEKUI  KEKUIS  KEKUT  KEKIM  KEKIS  KEKINT  ) ]);
form_ok('NOMEN',  dynamic('NOMEN',  'prilise', 'demeric'), [ qw( NOMUI  NOMUIS  NOMUT  NOMIM  NOMIS  NOMINT  ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'demeric'), [ qw( CLAGUI CLAGUIS CLAGUT CLAGIM CLAGIS CLAGINT ) ]);
form_ok('PARIR',  dynamic('PARIR',  'prilise', 'demeric'), [ qw( PARUI  PARUIS  PARUT  PARIM  PARIS  PARINT  ) ]);

form_ok('KREDEC', dynamic('KREDEC', 'prilise', 'demeric'), [ qw( KREDHUI KREDHUIS KREDHUT KREDIM KREDIS KREDINT ) ]);
form_ok('CLAETER', dynamic('CLAETER', 'prilise', 'demeric'), [ qw( CLAETHUI CLAETHUIS CLAETHUT CLAETIM CLAETIS CLAETINT ) ]);
form_ok('CEPAN', dynamic('CEPAN', 'prilise', 'demeric'), [ qw( CEFUI CEFUIS CEFUT CEPIM CEPIS CEPINT ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'prilise', 'demeric'), [ qw( GGGUI GGGUIS GGGUT GGGIM GGGIS GGGINT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'prilise', 'demeric'), [ qw( GGGUI GGGUIS GGGUT GGGIM GGGIS GGGINT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'prilise', 'demeric'), [ qw( GGGUI GGGUIS GGGUT GGGIM GGGIS GGGINT ) ]);
form_ok('GGGER', dynamic('GGGER', 'prilise', 'demeric'), [ qw( GGGUI GGGUIS GGGUT GGGIM GGGIS GGGINT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'prilise', 'demeric'), [ qw( GGGUI GGGUIS GGGUT GGGIM GGGIS GGGINT ) ]);

form_ok('ADEC', dynamic('ADEC', 'prilise', 'demeric'), [ qw( ADHUI ADHUIS ADHUT ADIM ADIS ADINT ) ]);
form_ok('ADAN', dynamic('ADAN', 'prilise', 'demeric'), [ qw( ADHUI ADHUIS ADHUT ADIM ADIS ADINT ) ]);
form_ok('ADEN', dynamic('ADEN', 'prilise', 'demeric'), [ qw( ADHUI ADHUIS ADHUT ADIM ADIS ADINT ) ]);
form_ok('ADER', dynamic('ADER', 'prilise', 'demeric'), [ qw( ADHUI ADHUIS ADHUT ADIM ADIS ADINT ) ]);
form_ok('ADIR', dynamic('ADIR', 'prilise', 'demeric'), [ qw( ADHUI ADHUIS ADHUT ADIM ADIS ADINT ) ]);

form_ok('ETEC', dynamic('ETEC', 'prilise', 'demeric'), [ qw( ETHUI ETHUIS ETHUT ETIM ETIS ETINT ) ]);
form_ok('ETAN', dynamic('ETAN', 'prilise', 'demeric'), [ qw( ETHUI ETHUIS ETHUT ETIM ETIS ETINT ) ]);
form_ok('ETEN', dynamic('ETEN', 'prilise', 'demeric'), [ qw( ETHUI ETHUIS ETHUT ETIM ETIS ETINT ) ]);
form_ok('ETER', dynamic('ETER', 'prilise', 'demeric'), [ qw( ETHUI ETHUIS ETHUT ETIM ETIS ETINT ) ]);
form_ok('ETIR', dynamic('ETIR', 'prilise', 'demeric'), [ qw( ETHUI ETHUIS ETHUT ETIM ETIS ETINT ) ]);

form_ok('APEC', dynamic('APEC', 'prilise', 'demeric'), [ qw( AFUI AFUIS AFUT APIM APIS APINT ) ]);
form_ok('APAN', dynamic('APAN', 'prilise', 'demeric'), [ qw( AFUI AFUIS AFUT APIM APIS APINT ) ]);
form_ok('APEN', dynamic('APEN', 'prilise', 'demeric'), [ qw( AFUI AFUIS AFUT APIM APIS APINT ) ]);
form_ok('APER', dynamic('APER', 'prilise', 'demeric'), [ qw( AFUI AFUIS AFUT APIM APIS APINT ) ]);
form_ok('APIR', dynamic('APIR', 'prilise', 'demeric'), [ qw( AFUI AFUIS AFUT APIM APIS APINT ) ]);

# dynamic definite past
form_ok('DUMEC',  dynamic('DUMEC',  'prilise', 'scrifel'), [ qw( DUMEVUI  DUMEVUIS  DUMEVUT  DUMEVIM  DUMEVIS  DUMEVINT  ) ]);
form_ok('KEKAN',  dynamic('KEKAN',  'prilise', 'scrifel'), [ qw( KEKEVUI  KEKEVUIS  KEKEVUT  KEKEVIM  KEKEVIS  KEKEVINT  ) ]);
form_ok('NOMEN',  dynamic('NOMEN',  'prilise', 'scrifel'), [ qw( NOMEVUI  NOMEVUIS  NOMEVUT  NOMEVIM  NOMEVIS  NOMEVINT  ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'scrifel'), [ qw( CLAGEVUI CLAGEVUIS CLAGEVUT CLAGEVIM CLAGEVIS CLAGEVINT ) ]);
form_ok('PARIR',  dynamic('PARIR',  'prilise', 'scrifel'), [ qw( PAREVUI  PAREVUIS  PAREVUT  PAREVIM  PAREVIS  PAREVINT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGER', dynamic('GGGER', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);

# dynamic definite past anterior
form_ok('DUMEC',  dynamic('DUMEC',  'prilise', 'izhcrifel'), [ qw( DUMERUI  DUMERUIS  DUMERUT  DUMERIM  DUMERIS  DUMERINT  ) ]);
form_ok('KEKAN',  dynamic('KEKAN',  'prilise', 'izhcrifel'), [ qw( KEKERUI  KEKERUIS  KEKERUT  KEKERIM  KEKERIS  KEKERINT  ) ]);
form_ok('NOMEN',  dynamic('NOMEN',  'prilise', 'izhcrifel'), [ qw( NOMERUI  NOMERUIS  NOMERUT  NOMERIM  NOMERIS  NOMERINT  ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'izhcrifel'), [ qw( CLAGERUI CLAGERUIS CLAGERUT CLAGERIM CLAGERIS CLAGERINT ) ]);
form_ok('PARIR',  dynamic('PARIR',  'prilise', 'izhcrifel'), [ qw( PARERUI  PARERUIS  PARERUT  PARERIM  PARERIS  PARERINT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGER', dynamic('GGGER', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);

# dynamic remote present
form_ok('DUMEC',  dynamic('DUMEC',  'buprilise', 'demeric'), [ qw( DUMI  DUMIS  DUMUAT  DUMUAM  DUMUAS  DUMUANT  ) ]);
form_ok('KEKAN',  dynamic('KEKAN',  'buprilise', 'demeric'), [ qw( KEKI  KEKIS  KEKUAT  KEKUAM  KEKUAS  KEKUANT  ) ]);
form_ok('NOMEN',  dynamic('NOMEN',  'buprilise', 'demeric'), [ qw( NOMI  NOMIS  NOMUAT  NOMUAM  NOMUAS  NOMUANT  ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'buprilise', 'demeric'), [ qw( CLAGI CLAGIS CLAGUAT CLAGUAM CLAGUAS CLAGUANT ) ]);
form_ok('PARIR',  dynamic('PARIR',  'buprilise', 'demeric'), [ qw( PARI  PARIS  PARUAT  PARUAM  PARUAS  PARUANT  ) ]);

form_ok('KREDEC', dynamic('KREDEC', 'buprilise', 'demeric'), [ qw( KREDI KREDIS KREDHUAT KREDHUAM KREDHUAS KREDHUANT ) ]);
form_ok('CLAETER', dynamic('CLAETER', 'buprilise', 'demeric'), [ qw( CLAETI CLAETIS CLAETHUAT CLAETHUAM CLAETHUAS CLAETHUANT ) ]);
form_ok('CEPAN', dynamic('CEPAN', 'buprilise', 'demeric'), [ qw( CEPI CEPIS CEFUAT CEFUAM CEFUAS CEFUANT ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'buprilise', 'demeric'), [ qw( GGGI GGGIS GGGUAT GGGUAM GGGUAS GGGUANT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'buprilise', 'demeric'), [ qw( GGGI GGGIS GGGUAT GGGUAM GGGUAS GGGUANT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'buprilise', 'demeric'), [ qw( GGGI GGGIS GGGUAT GGGUAM GGGUAS GGGUANT ) ]);
form_ok('GGGER', dynamic('GGGER', 'buprilise', 'demeric'), [ qw( GGGI GGGIS GGGUAT GGGUAM GGGUAS GGGUANT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'buprilise', 'demeric'), [ qw( GGGI GGGIS GGGUAT GGGUAM GGGUAS GGGUANT ) ]);

form_ok('ADEC', dynamic('ADEC', 'buprilise', 'demeric'), [ qw( ADI ADIS ADHUAT ADHUAM ADHUAS ADHUANT ) ]);
form_ok('ADAN', dynamic('ADAN', 'buprilise', 'demeric'), [ qw( ADI ADIS ADHUAT ADHUAM ADHUAS ADHUANT ) ]);
form_ok('ADEN', dynamic('ADEN', 'buprilise', 'demeric'), [ qw( ADI ADIS ADHUAT ADHUAM ADHUAS ADHUANT ) ]);
form_ok('ADER', dynamic('ADER', 'buprilise', 'demeric'), [ qw( ADI ADIS ADHUAT ADHUAM ADHUAS ADHUANT ) ]);
form_ok('ADIR', dynamic('ADIR', 'buprilise', 'demeric'), [ qw( ADI ADIS ADHUAT ADHUAM ADHUAS ADHUANT ) ]);

form_ok('ETEC', dynamic('ETEC', 'buprilise', 'demeric'), [ qw( ETI ETIS ETHUAT ETHUAM ETHUAS ETHUANT ) ]);
form_ok('ETAN', dynamic('ETAN', 'buprilise', 'demeric'), [ qw( ETI ETIS ETHUAT ETHUAM ETHUAS ETHUANT ) ]);
form_ok('ETEN', dynamic('ETEN', 'buprilise', 'demeric'), [ qw( ETI ETIS ETHUAT ETHUAM ETHUAS ETHUANT ) ]);
form_ok('ETER', dynamic('ETER', 'buprilise', 'demeric'), [ qw( ETI ETIS ETHUAT ETHUAM ETHUAS ETHUANT ) ]);
form_ok('ETIR', dynamic('ETIR', 'buprilise', 'demeric'), [ qw( ETI ETIS ETHUAT ETHUAM ETHUAS ETHUANT ) ]);

form_ok('APEC', dynamic('APEC', 'buprilise', 'demeric'), [ qw( API APIS AFUAT AFUAM AFUAS AFUANT ) ]);
form_ok('APAN', dynamic('APAN', 'buprilise', 'demeric'), [ qw( API APIS AFUAT AFUAM AFUAS AFUANT ) ]);
form_ok('APEN', dynamic('APEN', 'buprilise', 'demeric'), [ qw( API APIS AFUAT AFUAM AFUAS AFUANT ) ]);
form_ok('APER', dynamic('APER', 'buprilise', 'demeric'), [ qw( API APIS AFUAT AFUAM AFUAS AFUANT ) ]);
form_ok('APIR', dynamic('APIR', 'buprilise', 'demeric'), [ qw( API APIS AFUAT AFUAM AFUAS AFUANT ) ]);

# dynamic remote past
form_ok('DUMEC',  dynamic('DUMEC',  'buprilise', 'scrifel'), [ qw( DUMISI  DUMISUS  DUMISAT  DUMISAM  DUMISAS  DUMISANT  ) ]);
form_ok('KEKAN',  dynamic('KEKAN',  'buprilise', 'scrifel'), [ qw( KEKISI  KEKISUS  KEKISAT  KEKISAM  KEKISAS  KEKISANT  ) ]);
form_ok('NOMEN',  dynamic('NOMEN',  'buprilise', 'scrifel'), [ qw( NOMISI  NOMISUS  NOMISAT  NOMISAM  NOMISAS  NOMISANT  ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'buprilise', 'scrifel'), [ qw( CLAGISI CLAGISUS CLAGISAT CLAGISAM CLAGISAS CLAGISANT ) ]);
form_ok('PARIR',  dynamic('PARIR',  'buprilise', 'scrifel'), [ qw( PARISI  PARISUS  PARISAT  PARISAM  PARISAS  PARISANT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGER', dynamic('GGGER', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);

# dynamic remote imperative -- should be the same as as static remote imperative

sub imp_ok {
    croak 'usage: imp_ok($verb, $is, $should)' unless @_ == 3;
    my($verb, $is, $should) = @_;

    is($is->[0], undef,        "I.sg. of $verb");
    is($is->[1], $should->[0], "II.sg. of $verb");
    is($is->[2], $should->[1], "III.sg. of $verb");
    is($is->[3], undef,        "I.pl. of $verb");
    is($is->[4], $should->[2], "II.pl. of $verb");
    is($is->[5], $should->[3], "III.pl. of $verb");
}

imp_ok('DUMEC',  dynamic('DUMEC', 'buprilise', 'befel'), [ qw( DUME  DUMUAS  DUMEL  DUMUANT  ) ]);
imp_ok('KEKAN',  dynamic('KEKAN', 'buprilise', 'befel'), [ qw( KEKI  KEKUAT  KEKIL  KEKUANT  ) ]);
imp_ok('NOMEN',  dynamic('NOMEN', 'buprilise', 'befel'), [ qw( NOMI  NOMUAT  NOMIL  NOMUANT  ) ]);
imp_ok('CLAGER', dynamic('CLAGER','buprilise', 'befel'), [ qw( CLAGU CLAGAS  CLAGUL CLAGANT  ) ]);
imp_ok('PARIR',  dynamic('PARIR', 'buprilise', 'befel'), [ qw( PARU  PARUAT  PARUL  PARUANT  ) ]);

# test verb with separate remote stem
imp_ok('LAUDAN', dynamic('LAUDAN','buprilise', 'befel'), [ qw( LODI  LODUAT  LODIL  LODUANT  ) ]);

# test general forms
imp_ok('GGGEC',  dynamic('GGGEC', 'buprilise', 'befel'), [ qw( GGGE  GGGUAS  GGGEL  GGGUANT  ) ]);
imp_ok('GGGAN',  dynamic('GGGAN', 'buprilise', 'befel'), [ qw( GGGI  GGGUAT  GGGIL  GGGUANT  ) ]);
imp_ok('GGGEN',  dynamic('GGGEN', 'buprilise', 'befel'), [ qw( GGGI  GGGUAT  GGGIL  GGGUANT  ) ]);
imp_ok('GGGER',  dynamic('GGGER', 'buprilise', 'befel'), [ qw( GGGU  GGGAS   GGGUL  GGGANT   ) ]);
imp_ok('GGGIR',  dynamic('GGGIR', 'buprilise', 'befel'), [ qw( GGGU  GGGUAT  GGGUL  GGGUANT  ) ]);
