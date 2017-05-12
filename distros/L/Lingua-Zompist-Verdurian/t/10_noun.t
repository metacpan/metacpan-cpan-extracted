# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 680;
use Carp;

use Lingua::Zompist::Verdurian 'noun';

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "nom.pl. of $noun");
    is($is->[5], $should->[5], "gen.pl. of $noun");
    is($is->[6], $should->[6], "acc.pl. of $noun");
    is($is->[7], $should->[7], "dat.pl. of $noun");
}

form_ok('redh', noun('redh'), [ qw( redh redhei redh redhán
                                    redhî redhië redhi redhin ) ]);
form_ok('dasco', noun('dasco'), [ qw( dasco dascei dascam dascon
                                      dascoi dascoë dascom dascoin ) ]);
form_ok('dalu', noun('dalu'), [ qw( dalu dalui dalum dalun
                                    dalî daluë dalom daluin ) ]);
form_ok('katy', noun('katy'), [ qw( katy katii katim katín
                                    katî katuë katom katuin ) ]);
form_ok('ciy', noun('ciy'), [ qw( ciy cii ciim ciín
                                    ciî cië ciom ciuin ) ]);
form_ok('esta', noun('esta'), [ qw( esta estei esta estan
                                    estai estaë estam estain ) ]);

form_ok('rana', noun('rana'), [ qw( rana rane rana ranan
                                    ranî ranië ranem ranen ) ]);
form_ok('lavísia', noun('lavísia'), [ qw( lavísia lavísë lavísiam lavísian
                                          lavísiî lavísië lavísem lavísen ) ]);
form_ok('casi', noun('casi'), [ qw( casi casë casa casin
                                    casî casië casem casin ) ]);
form_ok('leve', noun('leve'), [ qw( leve levei leva leven
                                    levî levië levem leven ) ]);
form_ok('gurë', noun('gurë'), [ qw( gurë gurëi gurä guren
                                    gurî gurië gurem guren ) ]);

# final accent remains on the ending
form_ok('aknó', noun('aknó'), [ qw( aknó aknéi aknám aknón
                                    aknói aknoë aknóm aknóin ) ]);
form_ok('pisá', noun('pisá'), [ qw( pisá pisé pisá pisán
                                    pisí pisië pisém pisén ) ]);

# irregular plural stem
# First those from morphology.htm (as of 2001-10-22)
form_ok('bröca', noun('bröca'), [ qw( bröca bröce bröca bröcan
                                      brösî brösië brösem brösen ) ]);
form_ok('kud', noun('kud'), [ qw( kud kudei kud kudán
                                  kuzî kuzië kuzi kuzin ) ]);
form_ok('log', noun('log'), [ qw( log logei log logán
                                  lozhi lozhië lozhi lozhin ) ]);
form_ok('rhit', noun('rhit'), [ qw( rhit rhitei rhit rhitán
                                    rhichi rhichië rhichi rhichin ) ]);
form_ok('verat', noun('verat'), [ qw( verat veratei verat veratán
                                      veradhi veradhië veradhi veradhin ) ]);

# Now those from the source code
# (These are derived from the dictionary)
# Some checks might be made twice; oh well :)
form_ok('aklog', noun('aklog'), [ qw( aklog aklogei aklog aklogán
                                      aklozhi aklozhië aklozhi aklozhin ) ]);
form_ok('ánselcud', noun('ánselcud'), [ qw( ánselcud ánselcudei ánselcud anselcudán
                                            ánselcuzî ánselcuzië ánselcuzi ánselcuzin ) ]);
form_ok('barsúc', noun('barsúc'), [ qw( barsúc barsúcei barsúc barsucán
                                        barsúsî barsúsië barsúsi barsúsin ) ]);
form_ok('belac', noun('belac'), [ qw( belac belacei belac belacán
                                      belasî belasië belasi belasin ) ]);
form_ok('boc', noun('boc'), [ qw( boc bocei boc bocán
                                  bosî bosië bosi bosin ) ]);
form_ok('bröca', noun('bröca'), [ qw( bröca bröce bröca bröcan
                                      brösî brösië brösem brösen ) ]);
form_ok('büt', noun('büt'), [ qw( büt bütei büt bütán
                                  büsî büsië büsi büsin ) ]);
form_ok('chedesnaga', noun('chedesnaga'), [ qw( chedesnaga chedesnage chedesnaga chedesnagan
                                                chedesnazhi chedesnazhië chedesnazhem chedesnazhen ) ]);
form_ok('chuca', noun('chuca'), [ qw( chuca chuce chuca chucan
                                      chusî chusië chusem chusen ) ]);
form_ok('dosic', noun('dosic'), [ qw( dosic dosicei dosic dosicán
                                      dosisî dosisië dosisi dosisin ) ]);
form_ok('drac', noun('drac'), [ qw( drac dracei drac dracán
                                    drasî drasië drasi drasin ) ]);
form_ok('dushic', noun('dushic'), [ qw( dushic dushicei dushic dushicán
                                        dushisî dushisië dushisi dushisin ) ]);
form_ok('dhac', noun('dhac'), [ qw( dhac dhacei dhac dhacán
                                    dhasî dhasië dhasi dhasin ) ]);
form_ok('dhiec', noun('dhiec'), [ qw( dhiec dhiecei dhiec dhiecán
                                      dhiesî dhiesië dhiesi dhiesin ) ]);
form_ok('ecelóg', noun('ecelóg'), [ qw( ecelóg ecelógei ecelóg ecelogán
                                        ecelózhi ecelózhië ecelózhi ecelózhin ) ]);
form_ok('etalóg', noun('etalóg'), [ qw( etalóg etalógei etalóg etalogán
                                        etalózhi etalózhië etalózhi etalózhin ) ]);
form_ok('ferica', noun('ferica'), [ qw( ferica ferice ferica ferican
                                        ferisî ferisië ferisem ferisen ) ]);
form_ok('fifachic', noun('fifachic'), [ qw( fifachic fifachicei fifachic fifachicán
                                            fifachisî fifachisië fifachisi fifachisin ) ]);
form_ok('formica', noun('formica'), [ qw( formica formice formica formican
                                          formisî formisië formisem formisen ) ]);
form_ok('gläca', noun('gläca'), [ qw( gläca gläce gläca gläcan
                                      gläsî gläsië gläsem gläsen ) ]);
form_ok('gorat', noun('gorat'), [ qw( gorat goratei gorat goratán
                                      goradhi goradhië goradhi goradhin ) ]);
form_ok('grak', noun('grak'), [ qw( grak grakei grak grakán
                                    grahî grahië grahi grahin ) ]);
form_ok('gut', noun('gut'), [ qw( gut gutei gut gután
                                  gudhi gudhië gudhi gudhin ) ]);
form_ok('huca', noun('huca'), [ qw( huca huce huca hucan
                                    husî husië husem husen ) ]);
form_ok('ktëlog', noun('ktëlog'), [ qw( ktëlog ktëlogei ktëlog ktëlogán
                                        ktëlozhi ktëlozhië ktëlozhi ktëlozhin ) ]);
form_ok('kud', noun('kud'), [ qw( kud kudei kud kudán
                                  kuzî kuzië kuzi kuzin ) ]);
form_ok('lertlog', noun('lertlog'), [ qw( lertlog lertlogei lertlog lertlogán
                                          lertlozhi lertlozhië lertlozhi lertlozhin ) ]);
form_ok('log', noun('log'), [ qw( log logei log logán
                                  lozhi lozhië lozhi lozhin ) ]);
form_ok('matica', noun('matica'), [ qw( matica matice matica matican
                                        matisî matisië matisem matisen ) ]);
form_ok('meca', noun('meca'), [ qw( meca mece meca mecan
                                    mesî mesië mesem mesen ) ]);
form_ok('mevlog', noun('mevlog'), [ qw( mevlog mevlogei mevlog mevlogán
                                        mevlozhi mevlozhië mevlozhi mevlozhin ) ]);
form_ok('morut', noun('morut'), [ qw( morut morutei morut morután
                                      morudhi morudhië morudhi morudhin ) ]);
form_ok('naga', noun('naga'), [ qw( naga nage naga nagan
                                    nazhi nazhië nazhem nazhen ) ]);
form_ok('nid', noun('nid'), [ qw( nid nidei nid nidán
                                  nizî nizië nizi nizin ) ]);
form_ok('pag', noun('pag'), [ qw( pag pagei pag pagán
                                  pazhi pazhië pazhi pazhin ) ]);
form_ok('prolog', noun('prolog'), [ qw( prolog prologei prolog prologán
                                        prolozhi prolozhië prolozhi prolozhin ) ]);
form_ok('rak', noun('rak'), [ qw( rak rakei rak rakán
                                  rahî rahië rahi rahin ) ]);
form_ok('rog', noun('rog'), [ qw( rog rogei rog rogán
                                  rozhi rozhië rozhi rozhin ) ]);
form_ok('rhit', noun('rhit'), [ qw( rhit rhitei rhit rhitán
                                    rhichi rhichië rhichi rhichin ) ]);
form_ok('sfica', noun('sfica'), [ qw( sfica sfice sfica sfican
                                      sfisî sfisië sfisem sfisen ) ]);
form_ok('shank', noun('shank'), [ qw( shank shankei shank shankán
                                      shanhî shanhië shanhi shanhin ) ]);
form_ok('smeric', noun('smeric'), [ qw( smeric smericei smeric smericán
                                        smerisî smerisië smerisi smerisin ) ]);
form_ok('verat', noun('verat'), [ qw( verat veratei verat veratán
                                      veradhi veradhië veradhi veradhin ) ]);
form_ok('yag', noun('yag'), [ qw( yag yagei yag yagán
                                  yazhi yazhië yazhi yazhin ) ]);

# Test generic conjugation
form_ok('ggg', noun('ggg'), [ qw( ggg gggei ggg gggán
                                  gggî gggië gggi gggin ) ]);
form_ok('gggia', noun('gggia'), [ qw( gggia gggë gggiam gggian
                                      gggiî gggië gggem gggen ) ]);
form_ok('ggga', noun('ggga'), [ qw( ggga ggge ggga gggan
                                    gggî gggië gggem gggen ) ]);
form_ok('gggá', noun('gggá'), [ qw( gggá gggé gggá gggán
                                    gggí gggië gggém gggén ) ]);
form_ok('gggo', noun('gggo'), [ qw( gggo gggei gggam gggon
                                    gggoi gggoë gggom gggoin ) ]);
form_ok('gggó', noun('gggó'), [ qw( gggó gggéi gggám gggón
                                    gggói gggoë gggóm gggóin ) ]);
form_ok('gggu', noun('gggu'), [ qw( gggu gggui gggum gggun
                                    gggî ggguë gggom ggguin ) ]);
form_ok('gggú', noun('gggú'), [ qw( gggú gggúi gggúm gggún
                                    gggí ggguë gggóm gggúin ) ]);
form_ok('gggiy', noun('gggiy'), [ qw( gggiy gggii gggiim gggiín
                                      gggiî gggië gggiom gggiuin ) ]);
form_ok('gggíy', noun('gggíy'), [ qw( gggíy gggíi gggíim gggiín
                                      gggíî gggíë gggíom gggíuin ) ]);
form_ok('gggy', noun('gggy'), [ qw( gggy gggii gggim gggín
                                    gggî ggguë gggom ggguin ) ]);
# Can't test generic masculine in -a, but see further down
form_ok('gggi', noun('gggi'), [ qw( gggi gggë ggga gggin
                                    gggî gggië gggem gggin ) ]);
form_ok('gggí', noun('gggí'), [ qw( gggí gggë gggá gggín
                                    gggí gggië gggém gggín ) ]);
form_ok('ggge', noun('ggge'), [ qw( ggge gggei ggga gggen
                                    gggî gggië gggem gggen ) ]);
form_ok('gggé', noun('gggé'), [ qw( gggé gggéi gggá gggén
                                    gggí gggië gggém gggén ) ]);
form_ok('gggë', noun('gggë'), [ qw( gggë gggëi gggä gggen
                                    gggî gggië gggem gggen ) ]);

# Test known masculine nouns in -a
form_ok('creza', noun('creza'), [ qw( creza crezei creza crezan
                                      crezai crezaë crezam crezain ) ]);
form_ok('Ervëa', noun('Ervëa'), [ qw( Ervëa Ervëei Ervëa Ervëan
                                      Ervëai Ervëaë Ervëam Ervëain ) ]);
form_ok('esta', noun('esta'), [ qw( esta estei esta estan
                                    estai estaë estam estain ) ]);
form_ok('hezhiosa', noun('hezhiosa'), [ qw( hezhiosa hezhiosei hezhiosa hezhiosan
                                            hezhiosai hezhiosaë hezhiosam hezhiosain ) ]);
form_ok('rhena', noun('rhena'), [ qw( rhena rhenei rhena rhenan
                                      rhenai rhenaë rhenam rhenain ) ]);
form_ok('didha', noun('didha'), [ qw( didha didhei didha didhan
                                      didhai didhaë didham didhain ) ]);
form_ok('vyozha', noun('vyozha'), [ qw( vyozha vyozhei vyozha vyozhan
                                        vyozhai vyozhaë vyozham vyozhain ) ]);
