# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 498;
use Carp;

use Lingua::Zompist::Verdurian 'scrifel';

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

form_ok('lelen', scrifel('lelen'), [ qw( lelnai lelnei lelne lelnam lelno lelnu ) ]);
form_ok('badhir', scrifel('badhir'), [ qw( badhru badhreu badhre badhrum badhro badhrü ) ]);
form_ok('elirec', scrifel('elirec'), [ qw( elircao elirceo elirce elircom elirco elircu ) ]);

form_ok('ocan', scrifel('ocan'), [ qw( osnai osnei osne osnam osno osnu ) ]);
form_ok('zhechir', scrifel('zhechir'), [ qw( zhedru zhedreu zhedre zhedrum zhedro zhedrü ) ]);
form_ok('cuchec', scrifel('cuchec'), [ qw( cushcao cushceo cushce cushcom cushco cushcu ) ]);
form_ok('lädan', scrifel('lädan'), [ qw( läznai läznei läzne läznam läzno läznu ) ]);
form_ok('legan', scrifel('legan'), [ qw( lezhnai lezhnei lezhne lezhnam lezhno lezhnu ) ]);
form_ok('emec', scrifel('emec'), [ qw( encao enceo ence encom enco encu ) ]);
form_ok('visanir', scrifel('visanir'), [ qw( visandru visandreu visandre visandrum visandro visandrü ) ]);
form_ok('rizir', scrifel('rizir'), [ qw( ridru ridreu ridre ridrum ridro ridrü ) ]);
form_ok('mizec', scrifel('mizec'), [ qw( mizhao mizheo mizhe mizhom mizho mizhu ) ]);
form_ok('meclir', scrifel('meclir'), [ qw( mécliru meclireu méclire méclirum mécliro meclirü ) ]);
form_ok('ivrec', scrifel('ivrec'), [ qw( ivricao ivriceo ívrice ívricom ívrico ívricu ) ]);

form_ok('esan', scrifel('esan'), [ qw( fuai fuei fue/esne fuam fuo fueu/esnu ) ]);

# test the general replacements
form_ok('aaacan', scrifel('aaacan'), [ qw( aaasnai aaasnei aaasne aaasnam aaasno aaasnu ) ]);
form_ok('aaachan', scrifel('aaachan'), [ qw( aaadnai aaadnei aaadne aaadnam aaadno aaadnu ) ]);
# don't confuse with a form of 'dan'
form_ok('aaaden', scrifel('aaaden'), [ qw( aaaznai aaaznei aaazne aaaznam aaazno aaaznu ) ]);
form_ok('aaagan', scrifel('aaagan'), [ qw( aaazhnai aaazhnei aaazhne aaazhnam aaazhno aaazhnu ) ]);

form_ok('aaachir', scrifel('aaachir'), [ qw( aaadru aaadreu aaadre aaadrum aaadro aaadrü ) ]);
form_ok('aaamir', scrifel('aaamir'), [ qw( aaambru aaambreu aaambre aaambrum aaambro aaambrü ) ]);
form_ok('aaanir', scrifel('aaanir'), [ qw( aaandru aaandreu aaandre aaandrum aaandro aaandrü ) ]);
form_ok('aaazir', scrifel('aaazir'), [ qw( aaadru aaadreu aaadre aaadrum aaadro aaadrü ) ]);

form_ok('aaacec', scrifel('aaacec'), [ qw( aaascao aaasceo aaasce aaascom aaasco aaascu ) ]);
form_ok('aaachec', scrifel('aaachec'), [ qw( aaashcao aaashceo aaashce aaashcom aaashco aaashcu ) ]);
form_ok('aaamec', scrifel('aaamec'), [ qw( aaancao aaanceo aaance aaancom aaanco aaancu ) ]);
form_ok('aaasec', scrifel('aaasec'), [ qw( aaashao aaasheo aaashe aaashom aaasho aaashu ) ]);
form_ok('aaazec', scrifel('aaazec'), [ qw( aaazhao aaazheo aaazhe aaazhom aaazho aaazhu ) ]);

# test the unstressed vowel insertion
form_ok('aaaccclan', scrifel('aaaccclan'), [ qw( aaaccclinai aaaccclinei aaácccline aaáccclinam aaáccclino aaáccclinu ) ]);
form_ok('aaacccran', scrifel('aaacccran'), [ qw( aaacccrinai aaacccrinei aaácccrine aaácccrinam aaácccrino aaácccrinu ) ]);
form_ok('eeeccclan', scrifel('eeeccclan'), [ qw( eeeccclinai eeeccclinei eeécccline eeéccclinam eeéccclino eeéccclinu ) ]);
form_ok('eeecccran', scrifel('eeecccran'), [ qw( eeecccrinai eeecccrinei eeécccrine eeécccrinam eeécccrino eeécccrinu ) ]);
form_ok('iiiccclan', scrifel('iiiccclan'), [ qw( iiiccclinai iiiccclinei iiícccline iiíccclinam iiíccclino iiíccclinu ) ]);
form_ok('iiicccran', scrifel('iiicccran'), [ qw( iiicccrinai iiicccrinei iiícccrine iiícccrinam iiícccrino iiícccrinu ) ]);
form_ok('oooccclan', scrifel('oooccclan'), [ qw( oooccclinai oooccclinei ooócccline ooóccclinam ooóccclino ooóccclinu ) ]);
form_ok('ooocccran', scrifel('ooocccran'), [ qw( ooocccrinai ooocccrinei ooócccrine ooócccrinam ooócccrino ooócccrinu ) ]);
form_ok('uuuccclan', scrifel('uuuccclan'), [ qw( uuuccclinai uuuccclinei uuúcccline uuúccclinam uuúccclino uuúccclinu ) ]);
form_ok('uuucccran', scrifel('uuucccran'), [ qw( uuucccrinai uuucccrinei uuúcccrine uuúcccrinam uuúcccrino uuúcccrinu ) ]);

form_ok('aaaccclen', scrifel('aaaccclen'), [ qw( aaaccclinai aaaccclinei aaácccline aaáccclinam aaáccclino aaáccclinu ) ]);
form_ok('aaacccren', scrifel('aaacccren'), [ qw( aaacccrinai aaacccrinei aaácccrine aaácccrinam aaácccrino aaácccrinu ) ]);
form_ok('eeeccclen', scrifel('eeeccclen'), [ qw( eeeccclinai eeeccclinei eeécccline eeéccclinam eeéccclino eeéccclinu ) ]);
form_ok('eeecccren', scrifel('eeecccren'), [ qw( eeecccrinai eeecccrinei eeécccrine eeécccrinam eeécccrino eeécccrinu ) ]);
form_ok('iiiccclen', scrifel('iiiccclen'), [ qw( iiiccclinai iiiccclinei iiícccline iiíccclinam iiíccclino iiíccclinu ) ]);
form_ok('iiicccren', scrifel('iiicccren'), [ qw( iiicccrinai iiicccrinei iiícccrine iiícccrinam iiícccrino iiícccrinu ) ]);
form_ok('oooccclen', scrifel('oooccclen'), [ qw( oooccclinai oooccclinei ooócccline ooóccclinam ooóccclino ooóccclinu ) ]);
form_ok('ooocccren', scrifel('ooocccren'), [ qw( ooocccrinai ooocccrinei ooócccrine ooócccrinam ooócccrino ooócccrinu ) ]);
form_ok('uuuccclen', scrifel('uuuccclen'), [ qw( uuuccclinai uuuccclinei uuúcccline uuúccclinam uuúccclino uuúccclinu ) ]);
form_ok('uuucccren', scrifel('uuucccren'), [ qw( uuucccrinai uuucccrinei uuúcccrine uuúcccrinam uuúcccrino uuúcccrinu ) ]);

form_ok('aaaccclir', scrifel('aaaccclir'), [ qw( aaácccliru aaaccclireu aaáccclire aaáccclirum aaácccliro aaaccclirü ) ]);
form_ok('aaacccrir', scrifel('aaacccrir'), [ qw( aaácccriru aaacccrireu aaácccrire aaácccrirum aaácccriro aaacccrirü ) ]);
form_ok('eeeccclir', scrifel('eeeccclir'), [ qw( eeécccliru eeeccclireu eeéccclire eeéccclirum eeécccliro eeeccclirü ) ]);
form_ok('eeecccrir', scrifel('eeecccrir'), [ qw( eeécccriru eeecccrireu eeécccrire eeécccrirum eeécccriro eeecccrirü ) ]);
form_ok('iiiccclir', scrifel('iiiccclir'), [ qw( iiícccliru iiiccclireu iiíccclire iiíccclirum iiícccliro iiiccclirü ) ]);
form_ok('iiicccrir', scrifel('iiicccrir'), [ qw( iiícccriru iiicccrireu iiícccrire iiícccrirum iiícccriro iiicccrirü ) ]);
form_ok('oooccclir', scrifel('oooccclir'), [ qw( ooócccliru oooccclireu ooóccclire ooóccclirum ooócccliro oooccclirü ) ]);
form_ok('ooocccrir', scrifel('ooocccrir'), [ qw( ooócccriru ooocccrireu ooócccrire ooócccrirum ooócccriro ooocccrirü ) ]);
form_ok('uuuccclir', scrifel('uuuccclir'), [ qw( uuúcccliru uuuccclireu uuúccclire uuúccclirum uuúcccliro uuuccclirü ) ]);
form_ok('uuucccrir', scrifel('uuucccrir'), [ qw( uuúcccriru uuucccrireu uuúcccrire uuúcccrirum uuúcccriro uuucccrirü ) ]);

form_ok('aaacccler', scrifel('aaacccler'), [ qw( aaácccliru aaaccclireu aaáccclire aaáccclirum aaácccliro aaaccclirü ) ]);
form_ok('aaacccrer', scrifel('aaacccrer'), [ qw( aaácccriru aaacccrireu aaácccrire aaácccrirum aaácccriro aaacccrirü ) ]);
form_ok('eeecccler', scrifel('eeecccler'), [ qw( eeécccliru eeeccclireu eeéccclire eeéccclirum eeécccliro eeeccclirü ) ]);
form_ok('eeecccrer', scrifel('eeecccrer'), [ qw( eeécccriru eeecccrireu eeécccrire eeécccrirum eeécccriro eeecccrirü ) ]);
form_ok('iiicccler', scrifel('iiicccler'), [ qw( iiícccliru iiiccclireu iiíccclire iiíccclirum iiícccliro iiiccclirü ) ]);
form_ok('iiicccrer', scrifel('iiicccrer'), [ qw( iiícccriru iiicccrireu iiícccrire iiícccrirum iiícccriro iiicccrirü ) ]);
form_ok('ooocccler', scrifel('ooocccler'), [ qw( ooócccliru oooccclireu ooóccclire ooóccclirum ooócccliro oooccclirü ) ]);
form_ok('ooocccrer', scrifel('ooocccrer'), [ qw( ooócccriru ooocccrireu ooócccrire ooócccrirum ooócccriro ooocccrirü ) ]);
form_ok('uuucccler', scrifel('uuucccler'), [ qw( uuúcccliru uuuccclireu uuúccclire uuúccclirum uuúcccliro uuuccclirü ) ]);
form_ok('uuucccrer', scrifel('uuucccrer'), [ qw( uuúcccriru uuucccrireu uuúcccrire uuúcccrirum uuúcccriro uuucccrirü ) ]);

form_ok('aaaccclec', scrifel('aaaccclec'), [ qw( aaaccclicao aaacccliceo aaáccclice aaáccclicom aaáccclico aaáccclicu ) ]);
form_ok('aaacccrec', scrifel('aaacccrec'), [ qw( aaacccricao aaacccriceo aaácccrice aaácccricom aaácccrico aaácccricu ) ]);
form_ok('eeeccclec', scrifel('eeeccclec'), [ qw( eeeccclicao eeecccliceo eeéccclice eeéccclicom eeéccclico eeéccclicu ) ]);
form_ok('eeecccrec', scrifel('eeecccrec'), [ qw( eeecccricao eeecccriceo eeécccrice eeécccricom eeécccrico eeécccricu ) ]);
form_ok('iiiccclec', scrifel('iiiccclec'), [ qw( iiiccclicao iiicccliceo iiíccclice iiíccclicom iiíccclico iiíccclicu ) ]);
form_ok('iiicccrec', scrifel('iiicccrec'), [ qw( iiicccricao iiicccriceo iiícccrice iiícccricom iiícccrico iiícccricu ) ]);
form_ok('oooccclec', scrifel('oooccclec'), [ qw( oooccclicao ooocccliceo ooóccclice ooóccclicom ooóccclico ooóccclicu ) ]);
form_ok('ooocccrec', scrifel('ooocccrec'), [ qw( ooocccricao ooocccriceo ooócccrice ooócccricom ooócccrico ooócccricu ) ]);
form_ok('uuuccclec', scrifel('uuuccclec'), [ qw( uuuccclicao uuucccliceo uuúccclice uuúccclicom uuúccclico uuúccclicu ) ]);
form_ok('uuucccrec', scrifel('uuucccrec'), [ qw( uuucccricao uuucccriceo uuúcccrice uuúcccricom uuúcccrico uuúcccricu ) ]);


form_ok('dan', scrifel('dan'), [ qw( donai donei done donam dono donu ) ]);
form_ok('kies', scrifel('kies'), [ qw( kaivai kaivei kaive kaivam kaivo kaivu ) ]);

# I think 'fassec' should conjugate like this:
form_ok('fassec', scrifel('fassec'), [ qw( fashshao fashsheo fashshe fashshom fashsho fashshu ) ]);
# and 'shushchan' like this:
form_ok('shushchan', scrifel('shushchan'), [ qw( shushdai shushdei shushde shushdam shushdo shushdu ) ]);

# "numonten" did the wrong thing in the past -- o went to í
form_ok('numonten', scrifel('numonten'), [ qw( numontnai numontnei numontne numontnam numontno numontnu ) ]);
