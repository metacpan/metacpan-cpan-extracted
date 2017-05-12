# vim:set filetype=perl encoding=utf-8 fileencoding=utf-8 sw=4 et keymap=cuezi:
#########################

use Test::More tests => 1;
use Carp;

ok(1);

__END__

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'dynamic'; }

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

# dynamic definite present
form_ok('LIUBEC', dynamic('LIUBEC', 'prilise', 'demeric'), [ qw( LIUBUI LIUBUIS LIUBUT LIUBIM LIUBIS LIUBINT ) ]);
form_ok('LAUDAN', dynamic('LAUDAN', 'prilise', 'demeric'), [ qw( LAUDHUI LAUDHUIS LAUDHUT LAUDIM LAUDIS LAUDINT ) ]);
form_ok('LEILEN', dynamic('LEILEN', 'prilise', 'demeric'), [ qw( LEILUI LEILUIS LEILUT LEILIM LEILIS LEILINT ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'demeric'), [ qw( CLAGUI CLAGUIS CLAGUT CLAGIM CLAGIS CLAGINT ) ]);
form_ok('NURIR',  dynamic('NURIR',  'prilise', 'demeric'), [ qw( NURUI  NURUIS  NURUT  NURIM  NURIS  NURINT  ) ]);

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
form_ok('LIUBEC', dynamic('LIUBEC', 'prilise', 'scrifel'), [ qw( LIUBEVUI LIUBEVUIS LIUBEVUT LIUBEVIM LIUBEVIS LIUBEVINT ) ]);
form_ok('LAUDAN', dynamic('LAUDAN', 'prilise', 'scrifel'), [ qw( LAUDEVUI LAUDEVUIS LAUDEVUT LAUDEVIM LAUDEVIS LAUDEVINT ) ]);
form_ok('LEILEN', dynamic('LEILEN', 'prilise', 'scrifel'), [ qw( LEILEVUI LEILEVUIS LEILEVUT LEILEVIM LEILEVIS LEILEVINT ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'scrifel'), [ qw( CLAGEVUI CLAGEVUIS CLAGEVUT CLAGEVIM CLAGEVIS CLAGEVINT ) ]);
form_ok('NURIR',  dynamic('NURIR',  'prilise', 'scrifel'), [ qw( NUREVUI  NUREVUIS  NUREVUT  NUREVIM  NUREVIS  NUREVINT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGER', dynamic('GGGER', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'prilise', 'scrifel'), [ qw( GGGEVUI GGGEVUIS GGGEVUT GGGEVIM GGGEVIS GGGEVINT ) ]);

# dynamic definite past anterior
form_ok('LIUBEC', dynamic('LIUBEC', 'prilise', 'izhcrifel'), [ qw( LIUBERUI LIUBERUIS LIUBERUT LIUBERIM LIUBERIS LIUBERINT ) ]);
form_ok('LAUDAN', dynamic('LAUDAN', 'prilise', 'izhcrifel'), [ qw( LAUDERUI LAUDERUIS LAUDERUT LAUDERIM LAUDERIS LAUDERINT ) ]);
form_ok('LEILEN', dynamic('LEILEN', 'prilise', 'izhcrifel'), [ qw( LEILERUI LEILERUIS LEILERUT LEILERIM LEILERIS LEILERINT ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'prilise', 'izhcrifel'), [ qw( CLAGERUI CLAGERUIS CLAGERUT CLAGERIM CLAGERIS CLAGERINT ) ]);
form_ok('NURIR',  dynamic('NURIR',  'prilise', 'izhcrifel'), [ qw( NURERUI  NURERUIS  NURERUT  NURERIM  NURERIS  NURERINT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGER', dynamic('GGGER', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'prilise', 'izhcrifel'), [ qw( GGGERUI GGGERUIS GGGERUT GGGERIM GGGERIS GGGERINT ) ]);

# dynamic remote present
form_ok('LIUBEC', dynamic('LIUBEC', 'buprilise', 'demeric'), [ qw( LIUBI LIUBIS LIUBUAT LIUBUAM LIUBUAS LIUBUANT ) ]);
form_ok('LAUDAN', dynamic('LAUDAN', 'buprilise', 'demeric'), [ qw( LAUDI LAUDIS LAUDHUAT LAUDHUAM LAUDHUAS LAUDHUANT ) ]);
form_ok('LEILEN', dynamic('LEILEN', 'buprilise', 'demeric'), [ qw( LEILI LEILIS LEILUAT LEILUAM LEILUAS LEILUANT ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'buprilise', 'demeric'), [ qw( CLAGI CLAGIS CLAGUAT CLAGUAM CLAGUAS CLAGUANT ) ]);
form_ok('NURIR',  dynamic('NURIR',  'buprilise', 'demeric'), [ qw( NURI  NURIS  NURUAT  NURUAM  NURUAS  NURUANT  ) ]);

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
form_ok('LIUBEC', dynamic('LIUBEC', 'buprilise', 'scrifel'), [ qw( LIUBISI LIUBISUS LIUBISAT LIUBISAM LIUBISAS LIUBISANT ) ]);
form_ok('LAUDAN', dynamic('LAUDAN', 'buprilise', 'scrifel'), [ qw( LAUDISI LAUDISUS LAUDISAT LAUDISAM LAUDISAS LAUDISANT ) ]);
form_ok('LEILEN', dynamic('LEILEN', 'buprilise', 'scrifel'), [ qw( LEILISI LEILISUS LEILISAT LEILISAM LEILISAS LEILISANT ) ]);
form_ok('CLAGER', dynamic('CLAGER', 'buprilise', 'scrifel'), [ qw( CLAGISI CLAGISUS CLAGISAT CLAGISAM CLAGISAS CLAGISANT ) ]);
form_ok('NURIR',  dynamic('NURIR',  'buprilise', 'scrifel'), [ qw( NURISI  NURISUS  NURISAT  NURISAM  NURISAS  NURISANT  ) ]);

form_ok('GGGEC', dynamic('GGGEC', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGAN', dynamic('GGGAN', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGEN', dynamic('GGGEN', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGER', dynamic('GGGER', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);
form_ok('GGGIR', dynamic('GGGIR', 'buprilise', 'scrifel'), [ qw( GGGISI GGGISUS GGGISAT GGGISAM GGGISAS GGGISANT ) ]);

