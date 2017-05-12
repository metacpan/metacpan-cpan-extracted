# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 492;
use Carp;

use Lingua::Zompist::Verdurian 'izhcrifel';

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

form_ok('lelen', izhcrifel('lelen'), [ qw( lelnerai lelnerei lelnere lelneram lelnero lelneru ) ]);
form_ok('badhir', izhcrifel('badhir'), [ qw( badhreu badhreeu badhree badhreum badhreo badhreü ) ]);
form_ok('elirec', izhcrifel('elirec'), [ qw( elircerao elircereo elircere elircerom elircero elirceru ) ]);

form_ok('ocan', izhcrifel('ocan'), [ qw( osnerai osnerei osnere osneram osnero osneru ) ]);
form_ok('zhechir', izhcrifel('zhechir'), [ qw( zhedreu zhedreeu zhedree zhedreum zhedreo zhedreü ) ]);
form_ok('cuchec', izhcrifel('cuchec'), [ qw( cushcerao cushcereo cushcere cushcerom cushcero cushceru ) ]);
form_ok('lädan', izhcrifel('lädan'), [ qw( läznerai läznerei läznere läzneram läznero läzneru ) ]);
form_ok('legan', izhcrifel('legan'), [ qw( lezhnerai lezhnerei lezhnere lezhneram lezhnero lezhneru ) ]);
form_ok('emec', izhcrifel('emec'), [ qw( encerao encereo encere encerom encero enceru ) ]);
form_ok('visanir', izhcrifel('visanir'), [ qw( visandreu visandreeu visandree visandreum visandreo visandreü ) ]);
form_ok('rizir', izhcrifel('rizir'), [ qw( ridreu ridreeu ridree ridreum ridreo ridreü ) ]);
form_ok('mizec', izhcrifel('mizec'), [ qw( mizherao mizhereo mizhere mizherom mizhero mizheru ) ]);
form_ok('meclir', izhcrifel('meclir'), [ qw( meclireu meclireeu mecliree meclireum meclireo meclireü ) ]);
form_ok('ivrec', izhcrifel('ivrec'), [ qw( ivricerao ivricereo ivricere ivricerom ivricero ivriceru ) ]);

form_ok('esan', izhcrifel('esan'), [ qw( esnerai esnerei esnere esneram esnero esneru ) ]);

# test the general replacements
form_ok('aaacan', izhcrifel('aaacan'), [ qw( aaasnerai aaasnerei aaasnere aaasneram aaasnero aaasneru ) ]);
form_ok('aaachan', izhcrifel('aaachan'), [ qw( aaadnerai aaadnerei aaadnere aaadneram aaadnero aaadneru ) ]);
# don't confuse with a form of 'dan'
form_ok('aaaden', izhcrifel('aaaden'), [ qw( aaaznerai aaaznerei aaaznere aaazneram aaaznero aaazneru ) ]);
form_ok('aaagan', izhcrifel('aaagan'), [ qw( aaazhnerai aaazhnerei aaazhnere aaazhneram aaazhnero aaazhneru ) ]);

form_ok('aaachir', izhcrifel('aaachir'), [ qw( aaadreu aaadreeu aaadree aaadreum aaadreo aaadreü ) ]);
form_ok('aaamir', izhcrifel('aaamir'), [ qw( aaambreu aaambreeu aaambree aaambreum aaambreo aaambreü ) ]);
form_ok('aaanir', izhcrifel('aaanir'), [ qw( aaandreu aaandreeu aaandree aaandreum aaandreo aaandreü ) ]);
form_ok('aaazir', izhcrifel('aaazir'), [ qw( aaadreu aaadreeu aaadree aaadreum aaadreo aaadreü ) ]);

form_ok('aaacec', izhcrifel('aaacec'), [ qw( aaascerao aaascereo aaascere aaascerom aaascero aaasceru ) ]);
form_ok('aaachec', izhcrifel('aaachec'), [ qw( aaashcerao aaashcereo aaashcere aaashcerom aaashcero aaashceru ) ]);
form_ok('aaamec', izhcrifel('aaamec'), [ qw( aaancerao aaancereo aaancere aaancerom aaancero aaanceru ) ]);
form_ok('aaasec', izhcrifel('aaasec'), [ qw( aaasherao aaashereo aaashere aaasherom aaashero aaasheru ) ]);
form_ok('aaazec', izhcrifel('aaazec'), [ qw( aaazherao aaazhereo aaazhere aaazherom aaazhero aaazheru ) ]);


# test the unstressed vowel insertion
form_ok('aaaccclan', izhcrifel('aaaccclan'), [ qw( aaaccclinerai aaaccclinerei aaaccclinere aaaccclineram aaaccclinero aaaccclineru ) ]);
form_ok('aaacccran', izhcrifel('aaacccran'), [ qw( aaacccrinerai aaacccrinerei aaacccrinere aaacccrineram aaacccrinero aaacccrineru ) ]);
form_ok('eeeccclan', izhcrifel('eeeccclan'), [ qw( eeeccclinerai eeeccclinerei eeeccclinere eeeccclineram eeeccclinero eeeccclineru ) ]);
form_ok('eeecccran', izhcrifel('eeecccran'), [ qw( eeecccrinerai eeecccrinerei eeecccrinere eeecccrineram eeecccrinero eeecccrineru ) ]);
form_ok('iiiccclan', izhcrifel('iiiccclan'), [ qw( iiiccclinerai iiiccclinerei iiiccclinere iiiccclineram iiiccclinero iiiccclineru ) ]);
form_ok('iiicccran', izhcrifel('iiicccran'), [ qw( iiicccrinerai iiicccrinerei iiicccrinere iiicccrineram iiicccrinero iiicccrineru ) ]);
form_ok('oooccclan', izhcrifel('oooccclan'), [ qw( oooccclinerai oooccclinerei oooccclinere oooccclineram oooccclinero oooccclineru ) ]);
form_ok('ooocccran', izhcrifel('ooocccran'), [ qw( ooocccrinerai ooocccrinerei ooocccrinere ooocccrineram ooocccrinero ooocccrineru ) ]);
form_ok('uuuccclan', izhcrifel('uuuccclan'), [ qw( uuuccclinerai uuuccclinerei uuuccclinere uuuccclineram uuuccclinero uuuccclineru ) ]);
form_ok('uuucccran', izhcrifel('uuucccran'), [ qw( uuucccrinerai uuucccrinerei uuucccrinere uuucccrineram uuucccrinero uuucccrineru ) ]);

form_ok('aaaccclen', izhcrifel('aaaccclen'), [ qw( aaaccclinerai aaaccclinerei aaaccclinere aaaccclineram aaaccclinero aaaccclineru ) ]);
form_ok('aaacccren', izhcrifel('aaacccren'), [ qw( aaacccrinerai aaacccrinerei aaacccrinere aaacccrineram aaacccrinero aaacccrineru ) ]);
form_ok('eeeccclen', izhcrifel('eeeccclen'), [ qw( eeeccclinerai eeeccclinerei eeeccclinere eeeccclineram eeeccclinero eeeccclineru ) ]);
form_ok('eeecccren', izhcrifel('eeecccren'), [ qw( eeecccrinerai eeecccrinerei eeecccrinere eeecccrineram eeecccrinero eeecccrineru ) ]);
form_ok('iiiccclen', izhcrifel('iiiccclen'), [ qw( iiiccclinerai iiiccclinerei iiiccclinere iiiccclineram iiiccclinero iiiccclineru ) ]);
form_ok('iiicccren', izhcrifel('iiicccren'), [ qw( iiicccrinerai iiicccrinerei iiicccrinere iiicccrineram iiicccrinero iiicccrineru ) ]);
form_ok('oooccclen', izhcrifel('oooccclen'), [ qw( oooccclinerai oooccclinerei oooccclinere oooccclineram oooccclinero oooccclineru ) ]);
form_ok('ooocccren', izhcrifel('ooocccren'), [ qw( ooocccrinerai ooocccrinerei ooocccrinere ooocccrineram ooocccrinero ooocccrineru ) ]);
form_ok('uuuccclen', izhcrifel('uuuccclen'), [ qw( uuuccclinerai uuuccclinerei uuuccclinere uuuccclineram uuuccclinero uuuccclineru ) ]);
form_ok('uuucccren', izhcrifel('uuucccren'), [ qw( uuucccrinerai uuucccrinerei uuucccrinere uuucccrineram uuucccrinero uuucccrineru ) ]);

form_ok('aaaccclir', izhcrifel('aaaccclir'), [ qw( aaaccclireu aaaccclireeu aaacccliree aaaccclireum aaaccclireo aaaccclireü ) ]);
form_ok('aaacccrir', izhcrifel('aaacccrir'), [ qw( aaacccrireu aaacccrireeu aaacccriree aaacccrireum aaacccrireo aaacccrireü ) ]);
form_ok('eeeccclir', izhcrifel('eeeccclir'), [ qw( eeeccclireu eeeccclireeu eeecccliree eeeccclireum eeeccclireo eeeccclireü ) ]);
form_ok('eeecccrir', izhcrifel('eeecccrir'), [ qw( eeecccrireu eeecccrireeu eeecccriree eeecccrireum eeecccrireo eeecccrireü ) ]);
form_ok('iiiccclir', izhcrifel('iiiccclir'), [ qw( iiiccclireu iiiccclireeu iiicccliree iiiccclireum iiiccclireo iiiccclireü ) ]);
form_ok('iiicccrir', izhcrifel('iiicccrir'), [ qw( iiicccrireu iiicccrireeu iiicccriree iiicccrireum iiicccrireo iiicccrireü ) ]);
form_ok('oooccclir', izhcrifel('oooccclir'), [ qw( oooccclireu oooccclireeu ooocccliree oooccclireum oooccclireo oooccclireü ) ]);
form_ok('ooocccrir', izhcrifel('ooocccrir'), [ qw( ooocccrireu ooocccrireeu ooocccriree ooocccrireum ooocccrireo ooocccrireü ) ]);
form_ok('uuuccclir', izhcrifel('uuuccclir'), [ qw( uuuccclireu uuuccclireeu uuucccliree uuuccclireum uuuccclireo uuuccclireü ) ]);
form_ok('uuucccrir', izhcrifel('uuucccrir'), [ qw( uuucccrireu uuucccrireeu uuucccriree uuucccrireum uuucccrireo uuucccrireü ) ]);

form_ok('aaacccler', izhcrifel('aaacccler'), [ qw( aaaccclireu aaaccclireeu aaacccliree aaaccclireum aaaccclireo aaaccclireü ) ]);
form_ok('aaacccrer', izhcrifel('aaacccrer'), [ qw( aaacccrireu aaacccrireeu aaacccriree aaacccrireum aaacccrireo aaacccrireü ) ]);
form_ok('eeecccler', izhcrifel('eeecccler'), [ qw( eeeccclireu eeeccclireeu eeecccliree eeeccclireum eeeccclireo eeeccclireü ) ]);
form_ok('eeecccrer', izhcrifel('eeecccrer'), [ qw( eeecccrireu eeecccrireeu eeecccriree eeecccrireum eeecccrireo eeecccrireü ) ]);
form_ok('iiicccler', izhcrifel('iiicccler'), [ qw( iiiccclireu iiiccclireeu iiicccliree iiiccclireum iiiccclireo iiiccclireü ) ]);
form_ok('iiicccrer', izhcrifel('iiicccrer'), [ qw( iiicccrireu iiicccrireeu iiicccriree iiicccrireum iiicccrireo iiicccrireü ) ]);
form_ok('ooocccler', izhcrifel('ooocccler'), [ qw( oooccclireu oooccclireeu ooocccliree oooccclireum oooccclireo oooccclireü ) ]);
form_ok('ooocccrer', izhcrifel('ooocccrer'), [ qw( ooocccrireu ooocccrireeu ooocccriree ooocccrireum ooocccrireo ooocccrireü ) ]);
form_ok('uuucccler', izhcrifel('uuucccler'), [ qw( uuuccclireu uuuccclireeu uuucccliree uuuccclireum uuuccclireo uuuccclireü ) ]);
form_ok('uuucccrer', izhcrifel('uuucccrer'), [ qw( uuucccrireu uuucccrireeu uuucccriree uuucccrireum uuucccrireo uuucccrireü ) ]);

form_ok('aaaccclec', izhcrifel('aaaccclec'), [ qw( aaaccclicerao aaaccclicereo aaaccclicere aaaccclicerom aaaccclicero aaacccliceru ) ]);
form_ok('aaacccrec', izhcrifel('aaacccrec'), [ qw( aaacccricerao aaacccricereo aaacccricere aaacccricerom aaacccricero aaacccriceru ) ]);
form_ok('eeeccclec', izhcrifel('eeeccclec'), [ qw( eeeccclicerao eeeccclicereo eeeccclicere eeeccclicerom eeeccclicero eeecccliceru ) ]);
form_ok('eeecccrec', izhcrifel('eeecccrec'), [ qw( eeecccricerao eeecccricereo eeecccricere eeecccricerom eeecccricero eeecccriceru ) ]);
form_ok('iiiccclec', izhcrifel('iiiccclec'), [ qw( iiiccclicerao iiiccclicereo iiiccclicere iiiccclicerom iiiccclicero iiicccliceru ) ]);
form_ok('iiicccrec', izhcrifel('iiicccrec'), [ qw( iiicccricerao iiicccricereo iiicccricere iiicccricerom iiicccricero iiicccriceru ) ]);
form_ok('oooccclec', izhcrifel('oooccclec'), [ qw( oooccclicerao oooccclicereo oooccclicere oooccclicerom oooccclicero ooocccliceru ) ]);
form_ok('ooocccrec', izhcrifel('ooocccrec'), [ qw( ooocccricerao ooocccricereo ooocccricere ooocccricerom ooocccricero ooocccriceru ) ]);
form_ok('uuuccclec', izhcrifel('uuuccclec'), [ qw( uuuccclicerao uuuccclicereo uuuccclicere uuuccclicerom uuuccclicero uuucccliceru ) ]);
form_ok('uuucccrec', izhcrifel('uuucccrec'), [ qw( uuucccricerao uuucccricereo uuucccricere uuucccricerom uuucccricero uuucccriceru ) ]);


form_ok('dan', izhcrifel('dan'), [ qw( donerai donerei donere doneram donero doneru ) ]);
form_ok('kies', izhcrifel('kies'), [ qw( kaiverai kaiverei kaivere kaiveram kaivero kaiveru ) ]);

# I think 'fassec' should conjugate like this:
form_ok('fassec', izhcrifel('fassec'), [ qw( fashsherao fashshereo fashshere fashsherom fashshero fashsheru ) ]);
# and 'shushchan' like this:
form_ok('shushchan', izhcrifel('shushchan'), [ qw( shushderai shushderei shushdere shushderam shushdero shushderu ) ]);
