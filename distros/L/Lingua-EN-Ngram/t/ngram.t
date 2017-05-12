#!/usr/bin/perl

use lib './lib';
use strict;
use Test::Exception;
use Test::More tests => 25;

# ngram.t - regression texts for Lingua::EN::Ngram

# Eric Lease Morgan <eric_morgan@infomotions.com>
# September 12, 2010 - first cut; based on Lingua::EN::Bigram
# November 25, 2010  - modified for non-Latin chacters; Happy Thanksgiving!


# initialize
my $ngram = '';

# use 
use_ok( 'Lingua::EN::Ngram' );

# constructor
$ngram = Lingua::EN::Ngram->new;
isa_ok( $ngram, 'Lingua::EN::Ngram' );

# constructor with too many options
dies_ok { Lingua::EN::Ngram->new( foo => 'foo', bar => 'bar' ) } 'trapped too many options';

# constructor with optional text
$ngram = Lingua::EN::Ngram->new( text => 'Digital humanities are cool!' );
like( $ngram->text, qr/^Digital/, 'new with optional text argument' );

# constructor with invalid file option
dies_ok { Lingua::EN::Ngram->new( file => 'hello-world.txt' ) } 'trapped can not open file';

# constructor with optional file
$ngram = Lingua::EN::Ngram->new( file => './etc/rivers.txt' );
like( $ngram->text, qr/^The Project Gutenberg Etext/, 'new with optional file argument' );

# constructor with invalid option
dies_ok { Lingua::EN::Ngram->new( foo => 'foo' ) } 'trapped invalid option';

# set/get text
my $text = do { local $/; <DATA> };
$ngram->text( $text );
like( $ngram->text, qr/^ANNALES GATLIOLIQUES TROISIEME ANNRE /, 'set/get text' );

# ngram sanity checks
dies_ok { $ngram->ngram } 'trapped not passing an argument to ngram';
dies_ok { $ngram->ngram( 5.5 ) } 'trapped need to pass an integer to ngram';

# individual words
my $ngrams = $ngram->ngram( 1 );
is( scalar( keys %$ngrams ), 2738, 'ngrams(1) in a hash reference with 2738 keys' );
is( $$ngrams{ 'éditeur' }, 1, '"éditeur" is a key that appears once' );

# bigrams
$ngrams = $ngram->ngram( 2 );
is( scalar( keys %$ngrams ), 7039, 'ngrams(2) in a hash reference with 7039 keys' );
is( $$ngrams{ 'éditeur des' }, 1, '"éditeur des" is as bigram appearing once' );

# trigram
$ngrams = $ngram->ngram( 3 );
is( scalar( keys %$ngrams ), 8668, 'ngrams(3) in a hash reference with 8668 keys' );
is( $$ngrams{ 'éditeur des annales' }, 1, '"éditeur des annales" is as trigram appearing once' );

# n-gram
$ngrams = $ngram->ngram( 8 );
is( scalar( keys %$ngrams ), 9063, 'ngrams(8) in a hash reference with 9063 keys' );
is( $$ngrams{ 'ber sur nous tout le fardeau matériel de' }, 1, '"ber sur nous tout le fardeau matériel de" is as n-gram appearing once' );

# tscore
my $tscore = $ngram->tscore;
is( ref( $tscore ), 'HASH', 'tscore is a hash' );
like( $$tscore{ 'tous les' }, qr/^3/, '"tous les" has a tscore starting with 1' );

# intersections error trapping
my $walden = Lingua::EN::Ngram->new( file => './etc/walden.txt' );
my $rivers = Lingua::EN::Ngram->new( file => './etc/rivers.txt' );
my $corpus = Lingua::EN::Ngram->new;
dies_ok { $corpus->intersection } 'trapped no options passed to intersection';
dies_ok { $corpus->intersection( foo => 'foo' ) } 'trapped wrong number of options passed to intersection';
dies_ok { $corpus->intersection( corpus => $walden, length => 5 ); } 'trapped no array reference passed to intersections';
dies_ok { $corpus->intersection( corpus => [ ( $walden, $rivers ) ], length => 5.5 ); } 'no integer passed as a length to intersections';

# intersections
my $intersections = $corpus->intersection( corpus => [ ( $walden, $rivers ) ], length => 5 );
is( $$intersections{ 'a quarter of a mile' }, 14, 'intersections' );

# done, whew!
exit;


# sample data
__DATA__
ANNALES GATLIOLIQUES TROISIEME ANNRE 

IX 

JUILLET — SEPTEMBRE 

1874 


PARIS. — B. DE SOYE ET FILS, IMPR., 5, PL. DO PANTHÉON. 


ANNALES 


CATHOLIQUES 


TRANSI 


^^ 


REVUE RELIGIEUSE HEBDOMADAIRE 


DE LA FRANCE ET DE L'ÉGLISE 


PUBLIÉE AVEC l'APPROBATION ET l'ENCOURAGEMENT 

DE LEURS EMINENCES Mgr LE CARDINAL - ARCHEVÊQUE DE ROUEN 

ET LE CARDINAL-ARCHEVÊQUE DE CAMBRAI, 

DB LL. EXC. Mgr L'aRCHEVÈQUE DE REIMS, Mgr l'aRCHEVÊQUE DE TOULOUSE, 

ET Mgr L'aRCHEVÉQOE DE BOURGES, ET DE NN. SS. LES ÉVÉQUES D'aRRAS, 

DE BEADVAIS, D'aNGERS, DE BLOIS, d'ÉVREUX, DU MANS, DU PUY, 

DE MEAUX, DE MENDE, DE NANCY, DE NANTES, D'ORLÉANS , DE PAMIERS 

DE SAINT-CLAUDE, DE SAINT-DIÉ , DE TARENTAISE , D'aUTUN, DE VANNES, 

DE FRÉJUS, DE COMSTANTINE, D'HÉBRON, ETC., ETC. 


J. CHANTREL 

RÉDACTEUR EN CHEF 


TROISIEME ANNEE — TOME IX - 


JUILLEX — SEPXEMBRE 



PARIS 
13, RUE DE L'ABBAYE, 13. 


N0V.2 9ig57 


A NOS LKCTEURS. 


Nous commençons aujourd'hui le neuvième volume 
des Annales catholiques, et nous éprouvons le besoin de 
faire connaître à nos lecteurs la situation aduelle de 
l'œuvre que nous avons entreprise. 

11 y a un an, les Annales catholiques paraissaient par 
livraisons de 32 pnges; depuis un an, elles paraissent 
par livraisons de 64 pages, sans augmentation de prix. 11 y 
a un an, le nombre des Abonnés était loin de suffire à 
faire les frais matériels; aujourd'hui, malgré l'augmen- 
tation si considérable donnée aux livraisons, le nombre 
des Abonnés nous permet de joindre, comme on dit, les 
deux bouts ensemble. 

Bien entendu, nous ne parlons ni des frais d'adminis- 
tration, ni des frais de rédaction : jusqu'à présent, admi- 
nistrateurs et rédacteurs consacrent gratuitement leur 
temps à rOEuvre. 

11 y a là, certes^ un grand résultat acquis : il assure 
l'existence des Annales catholigues, et nous sommes heu- 
reux de remercier ici les souscripteurs zélés, les écrivains 
de la presse religieuse, et, par-dessus tout, les vénérables 
Prélats qui nous ont aidé a atteindre ce résultat en si 
peu de temps. Au moment où la mort si regrettable du 
premier éditeur des Annales, M. Putois-Cretlé, fit retom- 
ber sur nous tout le fardeau matériel de cette publication, 
nous avons pu hésiter un moment : nous avions reconnu 
que le nombre des pages était insuffisant pour répondre 
à l'importance et à la multiplicité des événements reli- 
gieux qui s'accomplissent et des questions religieuses qui 
se débattent de nos jours; mais, voulant faire une œuvre 
de propagande et qui fût à la portée des plus modestes 
bourses, nous reculions devant une augmentation de 
prix que paraissait exiger une augmentation du nombre 
■de pages par livraisons. Persuadé, pourtant, par les té- 
moignages qui nous venaient de toutes parts, que l'OEuvre 


6 ANNALES CATHOLIQUES 

était bonne, qu'elle avait déjà fait quelque bien et qu'elle 
pouvait en faire davantage, nous nous sommes décidé : 
au lieu de 32 pages, les livraison^ des Annales ont paru 
avec 64 pages, et nous avons pu ne pas augmenter le prix 
de l'abonnement pour la France, nous ne l'avons que 
très-légèrement augmenté pour quelques pays étrangers, 
après avoir reconnu la nécessité de le faire à cause des 
fra^s de poste. 

Notre confiance n'a pas été trompée, puisque l'OEuvre, 
moyennant des sacrifices personnels dont nous n'avons 
pas besoin de parler, a pu se suffire à elle-même et qu'elle 
a aujourd'hui surmonté toutes les difficultés d une nou- 
velle création. 

Mais, comme nous le disions dans la dernière livraison 
dutomeVllI, si l'existence est assurée, le but n'est pas 
encore complètement atteint, puisque nous ne pouvons 
pas encore dormeraux laits et aux questions tous les déve- 
loppements qu'ils demanderaient. Nos Souscripteurs nous 
ont, depuis un ans, |:)rocuré en moyenne trois souscrip- 
teurs nouveaux; serait-ce trop présumer de leur zèle que 
d'attendre de chacun d'eux encore un souscripteur? Si 
ce résultat élait obtenu, nous pourrions sans augmen- 
tation de prix pour ceux qui seraient nos abonnés au mo- 
ment de cette nouvelle amélioration, ajouter quelques 
pages aux livraisons des Annales^ et donner ainsi la pho- 
tographie complète de la semaine religieuse. 

Les Annales, nous écrit-on de tontes parts, font du 
bien : nos lecteurs sont témoins des etforls que nous fai- 
sons depuis trois ans |)Our les reu'lre de plus en plus di- 
gnes du succès (ju'elles obtiennent, des encouragements 
et des hautes approbations qui les honorent : ne pou- 
vons-nous donc espérer que les amis de la religion, que 
les personnes (pli s'occup<'nl de la propagation des bonnes 
lectures, que tous ceux qui savent couibien l'aumône in- 
tellectuelle et njoraleesl supérieure à l'aumône matérielle, 
ne reculerontpasdevaiiti:nedépensean!mellede 12 francs, 
une dépense mensuel le de w/i francpour procurer celte au 
mône à tant d't\mes (jui en ont besoin, et pour enrichir, 
par exemple, chacpie anut-e, les bibliothèques paroissiales 
ou autres, de quatre volumes in-octavo de plus de 750 
pages chacun, ne coulant pas, par conséquent plus de 


A NOS LECTEURS 


Irais francs^ei }>rësen(ant des lectures varices, la rëfutalion 
des plus habituelles objections centre la religion, des 
éclaircissements complets sur les questions les plus diffi- 
ciles, l'enseignement des évèqnes, les paroles et les actes du 
Souverain- Pontife, le récit des épreuves, des travaux, des 
bienfaits et des triomphes de notre sainte mère l'Eglise ca- 
tholique? 

Nous savons que la propagande est parfois difficile : il 
faut, pour réussir, des démarches, des insistances, des 
sollicitations souvent pénibles; mais le bien ne se fait 
pas sans quelque effort, et, quand il s'agit de sauver une 
société qui périt, d'éclairer des âmes qui s'égarent, de 
défendre la religion et l'Eglise, peut-ôn reculer, a-t-on le 
droit de reculer devant quelques démarches ennuyeuses 
et de se rebuter pour quelques insuccès? 

Nous demandons ici la permission de citer une lettre 
qu'on nous écrit, et qui nous paraît résoudre heureuse- 
ment la question de propagande que nous venons de 
citer. « Monsieur le Rédacteur, nous écrit un de nos 
« zélés Souscripteurs, je vousenvoie ci-inclus un mandat 
« de %i francs; la moitié de celle somme est pour renou- 
« vêler mon abonnement, l'autre pour un second abonne- 
a ment que vous voudrez bien me servir, jusqu'à ce que 
« je vous en indique la destination. J'ai voulu me forcer 
«ainsi à trouver le nouvel Abonné que vous demandez à 
« chacun de vos Souscripteurs. J'ai remarqué, et je m'en 
« accuse, que je me rebutais facilement daris les démar- 
« ches que je fais en vue de la propagande des bonnes pu- 
« blications. Une fois mes 12fr. versés, je sens que j'au- 
« rai plus d'ardeur à trouver l'Abonné qui me les rem- 
« boursera. Si je réussis, je recommencerai, et si vous 
« trouvez que mon procédé est bon, je vous autorise bien 
«volontiers à donner à ma lettre la publicité qui vous 
« paraîtra convenable. » 

Nous remercions bien vivement notre zélé Souscripteur. 
S'il veut bien nous le permettre, nous ajouterons que son 
procédé, qui nous parait excellent, peut être employé à 
moins de frais et être encore amélioré. Quel est celui de nos 
Abonnés qui ne pourrait pas ainsi faire l'avance d'un sim- 
ple abonnement trimestriel, qui ne lui ferait provisoire- 
ment débourser que 4 francs ? El, quant à ceux qui peu- 


9 ANNALES CATHOLIODES 

vent débourser 12 francs, qui les empêche de faire trois 
abonnements trimestriels, au lieu d'un .ibonnement d'un 
an? Pour ce dernier cas, du reste, et aûn de venir en 
aide à celte bonne volonté, nous dirons que nous sommes 
parfaitement disposé à recevoir 4 abonnements de trois 
mois pour 12 francs, ou 2 abonnements de six mois 
pour 7 frnncs, à ceux de nos Souscripteurs qui pren- 
draient ce moyen de propager les Annales catkoliqiœs : 
nos Souscripteurs étrangers jouiraient des mêmes avan- 
tages d'apr>s les prix indiqués pour les divers pays. 

Nous travaillons à une œuvre commune : la connais- 
sance et la défense de la vérité et de l'Eglise; si nous 
mettons ainsi en commun nos efforts pour soutenir et 
pour répandre la publication des Annales catholiques^ 
sans aucun doute l'OEuvre pourra prendre une .xtension 
qui, tout en la rendant moins indigne de la grande cause 
à IcKiue^lie nous lavons consacrée, lai mettra plus en état 
de la déi'endre; or, défendre l'Eglise, c'est défendre la 
société, c't'st défendre les plus chers intérêts du temps 
et de l'éternité. 

JN'ous plaçons de nouveau notre OEuvre sous la protec- 
sion du Sacré-Cœur, dont le beau mois vi<'nt de tiiiir; 
sous la protection de la sainte Vierge, la Mère de toute 
glace, qui vient de recevoir de si splendides hommages 
à Lille, et dont les sanctuaires de la Salette, de Lourdes et 
de Fontniain proclament si hautement l'amour pour la 
France; sous la protection, enfin, de l'apotre saint Paul, 
que Pie l\ adonné [)Our patron à la [tresse, en disant ainsi 
à tous les publicistes que leur mission est un véritable 
apostolat. 

J. Chantrel. 


Paris, 30 juin 187 4, en la fôte de la Commémoration de 
(le £ainl-PUuJ. 


ANNALES CATHOLIQUES 


CHRONIQUE ET FAITS DIVERS. 

Sommaire. — Situation générale. — Rome et V Italie : Santé du 
Pape ; désastres de Milan ; Garibaldi ; Mgr Isoard ; Mgr Nf groni. 
Fra?ice : Les diocèses (Paris, Alger, Annecy, Autun, Beauvais, 
Besançon, Bourges, Cahors, Le Mans, Marseille, Orléans, Péri- 
gueux, Reims, Kouen, Saint-Denis, Tarbes, Toulouse) ; don fait 
au cardinal Guibert par Pie IX ; Mgr Maret ; sacre de Mgr Perraud; 
Association noyonnaise ; conciles d'Alger et du Puy ; la procession 
de Marseille; les frères de Rouen; les pèlerins de la Réunion; 
miracle à Lourdes ; Notre-Dame la Noire de Toulouse. — Alle- 
magne : réunion épiscopale de Fulda ; Mgr Ledochowïfki ; le 16 
juin à Munich; le petit séminaire de Strasbourg; bref de Pie IX 
à Mgr Kuebel. — Belgique : réunion des étudiants de Louvain. — 
Brésil : mort de l'archevêque de Bahia. — Espagne : Scèue 
scandaleuse à Palencia. — Hollande : le nouvel évêque de Biéda. 

— Portugal : la secte antichrétienne. — Turquie : les Armé- 
niens. — Venezuela : persécution. 

2 juillet 1874. 

La situation religieuse du monde est restée telle que nous 
i'avons décrite il y a huit jours : c'est partout la continuation 
de la persécution et de la lutte admirable de l'épiscopat, du 
clergé et des laïques fidèles. Maison sent que l'impiété devient 
de plus en plus impatiente, et qu'elle n'attend, pour ainsi dire, 
qu'un signal pour se livrer à toutes ses violences. Nous nous 
contenterons aujourd'hui de donner les faits que nous n'avons 
pu qu'indiquer d'une manière générale dans notre dernière li- 
vraison. 

ROME ET l'iTALIE. 

La santé du Saint-Père est excellente : Pie IX résiste admirable- 
aux fatigues des réceptions qui se multiplient depuis quinze jours à 
l'occasion de son exaltation au souverain Pontificat, de son couron- 
nement et de la fête de saint Pierre ; on trouvera plus loin des dé- 
tails sur ces faits, 

— Le Saint-Père recevant, il y a quelques mois, une députation 
d'agriculteurs lombards, les exhorta très-vivement à prier beaucoup 
afin de détourner de dessus leur province les graves châtiments 
dont elle était menacée, à cause des insultes réitérées dont la reli- 
gion, ses cérémonies, sa discipline étaient l'objet. Les Ubres-pen- 
seurs de Milan se moquèrent de cet avertissement paternel du Pape, 


iO ANNALES CATHOLIQUES 

et ils saisirent la première occasion " qui se présenta pour jeter en 
quelque sorte un déll à la divinité. Lorsque, en mai dernier, l'ar- 
chevêque de Milan avait déjà pris toutes les dispositions pour faire 
transporter avec une grande pompe les reliques de saint Ambroise 
de la vieille collégiale ambrosienne dans la belle cattiédrale gothi- 
que où repose déjà saint Charles Borromée, ces libres-penseurs s'op- 
posèrent avec beaucoup de tapage à cette démonstration religieuse; 
ils firent tant et si bien que le préfet de Milan se rangea de leur 
côté, et la procession solennelle fut défendue, bien qu'elle eût été 
autorisée par une ordonnance du conseil provincial et par un décret 
ministériel. L'Eglise dut courber le front devant l'impiété. 

Le châtiment ne s'est pas fait attendre longtemps. 

Les journaux de Milan nous apportent la triste description d'un 
ouragan épouvantable qui a éclaté le samedi, 13 juin, sur la ville de 
Milan et les campagnes environnantes. Une grêle comme on n'en a 
jamais vu de pareille a tout détruit : la récolte est entièrement 
perdue ; les grêlons avaient la grosseur d'un œuf de poule. Les 
beaux vitraux de la cathédrale ont énonmément souffert ; la galerie 
Victor-Emmanuel et une partie de la gare ont eu leur toiture de 
verre pilée. Tous les arbres, toutes les plantes rares des jardins et 
des promenades publiques sont comme hachés par la main de 
l'homme. Un grand nombre de personnes ont été blessées par les 
grêlons. * 

Les princes de Piémont, arrivés à Milan l'avant-veille, ont été té- 
moins de cette terrible c itustrophe. 

— GaribaMi est si mal, dit le Times, qu'il ne peut remuer son 
bras, ni tenir une plume, ni môme porter ses aliments à sa bouche; 
en un mot, il ne peut faire un mouvement. Il ne reçoit absolument 
que ses plus intimes amis. 

— Mgr [soaul, amliteur de la sainte Hôte, vient de quitter Rome 
pour un congé de quelques semaines. Ce tribunal suprême de la 
Ilote est fermé, hélas! Mais les jugrts demeuient, et c'est la plus 
noble protestation que puisse opposer le Saint-Sirge aux violateurs 
de la justice. 

— Les ennemis de l'Eglise sont en ce moment stupéfaits de la ré. 
solution que vient de prendre Mgr Negroni, ex-ministre de l'inté- 
I ieur de Sa Sainteté, qui a renoncé à l'espérance de li pourpre et 
quitté loutes ses digmilis [lour entrer dan^ la Coiiipa^uie de Jésus. 
Mgr Negroni est en ce moment au noviciat des Jésuite?, à .\n- 
gors. 


CliRONlODE ET FAITS DIVERS , H 

FRANCE. 

Paris. — Durant son séjour k Rome, Mgr l'Archevêque a eu 
l'honneur d'être reçu plusieurs fois par lo Saint-Père de la manière 
la plus affectueuse. Monseigneur a entretenu longuement Sa Sain- 
teté de la situation de Paris et des œuvres de charité et de religion 
qui y fleurissent malgré tant d'influences contraires. Notre Saint- 
Père a pris ]<i plus grand plaisir à écouter ces consolants détails, et 
c'est avec une joie marquée qu'il a appris de la bouche de l'Arche- 
vêque le succès de l'Œuvre de l'église du Sacré-Cœur. Près d'un 
million et demi recueilli en moins de deux années, dans des temps 
si difficiles et pour un but exclusivement religieux et mystique, 
voilà qui a paru au chef de l'Eglise tout à fait digne d'admiration 
et d'encouragement. Aussi, à ses bénédictions et à ses vœux sympa- 
thiques, Pie IX a voulu joindre une offrande qui témoignât à tous 
del'intérêt qu'il porte à la construction de la grande église du Sacré- 
Cœur à Montmartre. 

Cette offrande qui est destinée au trésor de la nouvelle église 
consiste en un magniûque calice en vermeil, orné des plus riches 
émaux. 

Cette belle pièce d'orfèvrerie sort de la fabrique de M. Armand 
Calliat, de Lyon. Sur le pied sont ciselés avec une délicatesse re- 
marquable des sujets de l'Ancien Testament, représentant les figures 
du sacrifice eucharistique : Abel, Hénoch, Melchisédech, Isaac ; au- 
tour de la coupe les quatre principales scènes de la Passion. Sur la 
face extérieure de la patène on voit retracés avec leurs emblèmes les 
quatre évangélistes : saint Mathieu, saint Marc, saint Luc et saint 
Jean. Sous le double rapport du prix de la matière et du fini du tra- 
vail, on ne saurait rien imaginer de plus riche et de plus artistique 
que ce vase. {Semaine religieuse de Paris.) 

— Mgr Maret, évêque de Sura in partibm, et primicier du cha- 
pitre de Saint-Denis, vient de quitter Rome, où il se trouvait depuis 
plusieurs mois. On sait qu'il était venu soumettre à l'examen et à 
l'approbation du Saint-Siège les constitutions de l'insigne chapitre. 
L'examen a été fait par la sainte congrégation du Concile avec la 
sagesse et la maturité que les congrégations romaines apportent à 
tous leurs travaux, et le samedi 27 juin, son jugement a dû être 
soumis à la sanction suprême du Pape. Le rescrit pourra être dressé 
conformément à cette sanction. Les dernières formaUtés à remphr 
n'exigeront probablem'ent plus que quinze ou vingt jours, et 
Mgr Maret pourra recevoir, aussitôt à Paris, le rescrit pontifical. 


12 ANNALES CATHOLIQUES 

Alger. — La sainte congrégation du Concile vient de terminer 
l'examen des Actes du concile provincial d'Alger. Mgr Lavigerie a 
■ ainsi renoué la chaîne des conciles de l'antique et grande Eglise 
d'Afrique. 

Annecy. — MgrjMagnin a procédé dernièrement à la bénédiction 
solennelle de la Croix du Salève, croix monumentale haute de 
12 mètres, «'■levée sur l'extrémité nord du Grand-Salève, au-dessus du 
village de Monnatier, et qui domine à la fois le bassin de Genève et le 
bassin de l' Arve en Faucigny ; on l'aperçoit du centre même de la ville 
de Genève, du pont du Mont-Blanc, du plateau des Tranchées, et de 
de plusieurs rues et maisons du quartier de Saint-Gervais. Plus 
de 15,000 personnes assistaient à cette belle cérémonie, et ont ac- 
clamé, à la voix de l'abbé Joseph, ancien aumônier militaire, la 
France, le. Souveruir, -Pontife, les évêques, le clergé et la catholique 
Savoie, qui peut, dit le Couturier de Genève, « enregistrer une fois 
de plus dans ses annales une page de triomphe et d'honneur. « 

AuiLN. — Le sacre de Mgr Perraud a eu lieu très-solennelle- 
ment daus l'église Saint-Sulpice, à Paris, le 29 juin, fête de Saint- 
Pierre. Le prélat consécrateur était le cardinal Guibert, archevêque 
de Paris, assisté de Mgr de Marguerye, ancien évêque d'Autun, et de 
Mgr Bourrcl, évoque de Rodez, ancien collègue, à la Sorbonne, du 
nouvel évêque. Mgr Meglia, nonce apostolique, assistait à la céré- 
monie, à laquelle avait voulu être aussi présent le maréchal de 
Mac-Mahon, qui est un ancien élève du petit séminaire d'Autun. 

On remarquait aussi deux députations d'Irlande et de Pologne, 
avec des bannières aux couleurs nationales, venues au sacre de 
Mgr Perraud en témoignage de sympathie et do reconnaissance 
pour l'écrivain qui a plusieurs fois défendu éloquemment la cause 
des deux nobles pays, et pour le religieux qui s' e^t occupé avec 
zèle des œuvres établies, K Paris, en faveur des émigrés irlandais 
et des exilés polonais. 

Beaivais. — Le IS juin a eu lieu, au petit séminaire de Noyon, 
sous la présidence (le Mgr Gignoiix, la réunion annnclledes anciens 
élèves de celte maison d'éducation, ([ui a fourni au clergé, à la ma- 
gistrature, à l'armée, à la presse, à tous les rangs de la société, UQ 
grand noinbio d'hommes (|ui. font honneur à l'éducation chrétienne 
qu'ils ont icçui-. Un banquet fraternel a réuni, dans le réfectoire 
inéuu5 (lu sémiiinire, tous les membres présents de l'Associ.ilion 
noyonnaise. Ltj» l(jasls portés à Pic IX, à Mgr l'évêque de Beauvais, 
h. tons les anciens supérieurs et maîtres do rétablissement, ont été 
vigoureubemeul applaudis, et l'on a non moins vigoureusement 


• CHRONIQUE ET FAITS DIVERS 43 

acclamé les vers aussi ingénieux que bien tournés d'un ancien 
élève, aujourd'hui juge de paix, qui a su évoquer les meilleurs 
sentiment? en môme temps que les vieux souvenirs du collège. 
Ces associations entre les anciens élèves des établissements d'ins- 
truction se multiplient heureusegienf ; nous n'en connaissons pas 
où les bons et vrais sentiments de camaraderie et de fraternité se 
montrent avec une plus vérilable expansion que dans les réunions 
des anciens élèves des maisons d'éducation religieuses. 

Besançon. — Le « Vénérable » de la Loge maçonnique de Besan- 
çon vient de mourir, après avoir riçu les secours de la religion. 
Malgré les obsessions de ses confrères de Paris, de Strasbourg et de 
Mulhouse, venus à son lit de mort pour le circonvenir, il a voulu 
s'entretenir avec deux prêtres, faire abjuration, et recevoir les sa- 
crements. Sa (in a été édifiante. 

Bourges. — La sainte Congrégation du concile s'occupe de 
l'examen du concile provincial de Bourges, tenu au Puy, que 
Mgr de la Tour d'Auvergne Lauragais a apportera Roine. Le véné- 
rable archevêque a reçu de Pie IX l'accueil le plus bienveillant. Il 
a remis au Pape une somme d'environ 50,000 francs pour le Denier 
de Saint-Pierre. A celte somme en était jointe une autre de 330 fr. 
dont la provenance mérite d'être signalée. Quelques pieuses per- 
sonnes de la ville de Bourges ont réuni ensemble tous les vieux 
papiers qu'elles ont pu trouver, les ont vendus et ont ainsi recueilli 
ladite somme de 330 francs qui a été apportée h Sa Grandeur la 
veille de son départ pour Rome. Les donateurs avaient joint h ce 
produit de leur piense industrie une touchante lettre que Sa Gran- 
deur a en même temps remise au Saint-l'ère. 

Cahors. — Mgr Grimardias vient d'adresser la circulaire sui- 
vante aux fidèles de son diocèse : 

« Vous n'ignorez pas les terribles effets qu'a produits l'ouragan 
de dimanche dernier. Une grande partie de notre diocèse a été ra- 
vagée de telle sorte que toutes les récoltes de cette année sont per- 
dues, et que, pendant plusieurs années peut-être, le travail le plus 
assidu restera sans récompense. 

« Touché de catte situation, qu'il a constatée par lui-même, M. le 
préfet du Lot a nommé une commission dont nous avons accepté la 
présidence, pour essayer de trouver quelque remède à tant de souf- 
frances. 

« J'espère que la bonne volonté viendra en aide à nos efforts, et 
qu'ils ne seront pas inutiles. Mais dès aujourd'hui j'ai hâte de faire 
appel k la générosité des fidèles en prescrivant dans toutes les égli- 


14 ANNALES CATHOLIQUES 

ses des paroisses qui furent épargnées, une quête en faveur de ceux 
qui ont souffert. » 

Le Mans. — La santé de Mgr Fillion, qui a donné de sérieuses 
inquiétudes depuis quelque temps, coinmence à s'améliorer; tout 
fait espérer aujourd'hui que l'éminent prélat sera conservé à son 
diocèse. 

Marseille. — Nous avons dit un mot de la magnifique proces- 
sion qui a eu lieu à Marseille en l'honneur du Sacré-Cœur. Dans 
un discours plein d'éloquence, Mgr Place a principalement consi- 
déré au point de vue social la dévotion au Sacré-Cœur de Jésus, et 
salué l'accrcissement merveilleux de cette dévotion parmi nous. 
« On a dit avec raison, s'est-il écrié, que la dévotion au Sacré-Cœur 
était française dans son origine et ses développements. Elle est sur- 
tout une dévotion marseillaise : c'est à Marseille qu'un culte pu- 
blic, solennel, au Sacré-Cœur a été rendu, pour la première fois, au 
milieu des événements dont nous rappelons en ce jour l'anniver- 
saire; c'est l'objet même de cette imposante et pieuse réunion. Au- 
jourd'hui encore, Marseille est le missionnaire et l'apôtre du Sacré- 
Cœur. Deux ans de suite, elle a inauguré ces magnifiques pèlerina- 
ges de Paray-le-Monial qui ont donné l'élan à toute la France. Notre 
fête annuelle, dont lécho retentit dans le monde, est comme l^ac- 
clamaUon des bienfaits dont le Sacré-Cœur est la source. Que ce 
soit donc, pour Marseille et le diocèse, l'occasion des bénédictions 
les plus abondantes. Que le Sacré-Cœur nous bénisse, ainsi que la 
patrie tout entière, ainsi que l'Eglise et son auguste chef si cruelle- 
ment éprouvé ! » 

ORLÉANb. — La santé de Mgr Dupanloup, qui avait donné des 
inquiétudes pendant quelques jours, s'est alfermie, et l'illustre pré* 
lat a pu reprendre le cours de ses travaux parlementaires et épisco- 
paiix. 

PÉRiGUEux. — Mgr Dabert s'est inscrit pour 300 fr. sur la liste 
des souscriptions ouvertes dans son diocèse pour venir en aide aux 
victimes des derniers orages. 

Reims. — On parle de Mgr Freppel, évoque d'Angers, pour le 
siège archiépiscopal de lU'ims. 

llouEN. — A la séance de la distribution des prix faite dernière- 
meul aux soldats de la garnison de Ilouen, qui suivent les cours des 
Frères des Ecoles chrétiennes, M. le général Lebrun, commandant 
le 3* corps d'armée, a prononcé le discours suivant : 


• cAronique et faits divers 15 

« Messieurs les Frères, 

« L'armée n'a pas perdu le souvenir des services que vous lui 
avez rendus avec tant d'abnégation, pendant la dernière guerre, 
alors que vous alliez, au péril de vos jours, relever sur nos champs 
de bataille fios malheureux soldats tombés sous l'excès des fatigues 
ou frappés par les balles ennemies. 

« L'armée a la mémoire du cœur, c'est pour cela que je saisis 
avec bonheur l'occasion de renouveler auprès de vous l'expression 
de son admiration et de sa vive reconnaissance. 

« Aujourd'hui que, pendant la paix, vous poursuivez, sous une 
nouvelle forme, l'œuvre de patriotisme que vous avez si noblement 
accomplie pendant la guerre, je vous adresse, au nom de l'armée, 
ses remerciements et ses félicitations les plus chaleureuses. 

« Qui travaille comme vous pour l'armée, mérite bien de la pa- 
trie. M 

De telles paroles, dans une telle bouche, vengent suffisamment 
les Frères des injures que les radicaux leur adressent journelle- 
ment. 

Saint-Denis (Réunion). — Un certain nombre de pèlerins de l'île 
de la Réunion (Rourbon), viennent d'arriver en France et se sont 
rendus à Paray-le-Monial où ils ont déposé, le 2 juillet, fête de la 
V^isitation, une magnifique bannière en velours rouge, portant celte 
Inscription : l'île Bourbon au Sacré- Cœur de Jésus ; au milieu sont 
brodées les armes de Mgr Delannoy, se composant de Notre-Dame 
de la Treille, de la croix de Saint-André, double souvenir du pays 
de l'évêque, Lille, dont Notre-Dame de la Treille est la patronne 
vénérée, et de la paroisse de Saint-André, dont il a été longtemps 
le curé, enfin de l'ancre d'espérance avec cette devise : hœc spes 
hostra. Au bas delà bannière est brodée une louffe de cannes à su- 
cre en fljurs. De chaque côté sont deux palmiers, dont les feuilles 
vont se rejoindre au haut de la bannière, et autour desquelles s'en- 
roulent deux banderolles, oti sont inscrits les noms des douze quar- 
tiers de l'île Bourbon : Saint-Denis, Sainte-Marie, Sainte-Suzanne, 
Saint-André, Saint-Benoît, Sainte-Rose, Saint-Philippe, Saint-Jo- 
seph, Saint-Pierre, Saint-Louis, Saint-Leu et Saint-Paul; douze 
noms de saints, car à Bourbon la France s'est montrée chrétienne. 

Tarées. — Voici d'intéressants détails sur un prodige arrivé à 
Lourdes, le 28 mai, en faveur de l'une des Dames qui font partie 
du pèlerinage américain. — M"" Baker, de Boston (Etats-Unis), 
était entièrement paralysée depuis plusieurs mois; c'est à peine si 


16 ANNALES CATHOLIQUES 

elle pouvait faire quelques pas à l'aide d'un appui et sur un plan 
toul-à-fait horizontal. L'épine dorsale s'était deux fois brisée, et cette 
fracture, jugée incurable par les médecins, lui causait des douleurs 
continuelles. La traversée de l'Océan augmenta ses souffrances. 
Cependant, la voilà arrivée à Lourdes, mais tellement fatiguée, qu'il 
a fallu attendre deux jours pour oser la conduire à la Grotte et la 
plonger lians la piscine. Enfin, dans la malinée du 28, elle voulut 
braver la souffrance et la froideur de la température. Une voiture la 
transporta à la Grotte, et h l'aide de bras élrangf^rs elle descendit 
dans la piscine. Elle y. était à peine plongée que ses souffrances 
devinrent plus aiguës et que la douleur sembla vouloir triompher 
de sa patience. « \lafoi ! lui disait sa sœur, protestante, pour prendre 
un bain d'eau froide, vous n'aviez pas besoin de venir si loin. » 
Mais la confiance de la malade était toujours la même. Aussitôt elle 
éprouve dans tout son corps un bien-être .imlicible : quelques 
instants après, ellecourt aie Grotte pour rendregiàces à son auguste 
bienfaitrice. Son mari, quoique protestant, se mit à verser des larmes 
de joie, s'agenouilla à côté de sa femme et prit part aux actions de 
grcàces qu'elle rendait à Marie. «Espérons, dit le Journal de Lourdes, 
que ce grand miracle sera suivi d'un autre encore plus grand, celui 
de la conversion de ces deux protestants, le mari et la sœur de la 
miraculée. » Cette dame était encore à Lourdes le 6 juin, continuant 
de marcher, de courir et de se bien porter. 

Toulouse. — Le couronnement de .Notre-Dame la Noire a eu lieu 
le dimanche, T juin, dans l'église de la Daurade, avec un grand éclat.- 
Les murs de l'édifice sacré avaient disparu sous les tenturcB et sous 
les (leurs; mais ce qui allait le plus à l'àme ( t la remuait le plus 
profonilément, c'était une foule immense et pieusement recueillie, 
c'étaient toutes ces voix chantant les gloires de la Vierge Mère, 
c'i'tait cette multitude de prêtres associant leurs acclamations à celles 
de toute une ville- représentée par l'élite de sa population, qui, elle 
aussi, tenait à payer son tribut de reconnaissance et d'amour à 
l'antique patronne de la France. Mgr l'Archevêque de Toulouse a 
présidé la cérémonie et le R. P. Caussette a prononcé, en l'honneur 
de la saii'te Vierge, un éloquent discours qui a fuit l^a plus vive 
impression sur son auditoire. 

ALLEMAGNE. 

On -^crit do Fulda (iiS juin), que la Lettre pastorale rédigt^e par 
les mcmbrep do la conférence épiscopale indique aux populations la 
conduite à tcnip le jour où toutes les paroisses, toutes les cures, 


i:iIRONIQUE ET FAITS DIVERS 17 

tons les évôcbés, se Ironveronl vacants, par suite de l'emprisonne- 
iiient de leurs chefs .spirituels. 

En les invitant au calme, elle les invile à refuser tout pasteur 
nommé par l'autorité civile. La publication de cette pastorale est 
destinée à produire en Allemagne une profonde impression. 

— L'extrait suivant d'une correspondance adressée d'Ostrowo à 
la Oermania de Berlin, montrera avec quel acharnement sont persé- 
cutés les évêques prussiens : 

(( L'arehevêque avait été condamné à une nouvelle aniende de 
1,000 Ihaler? pour infraction aux lois de Mai. Comme on avait déjà 
tout saisi à Posen, on donna au tribunal du cercle d'Ostrowo l'ordre 
de faire >une saisie dans la prison de l'archevêque. L'huissier M... 
se présenta donc le 15 juin à la prison du tribunal de corcle et fut 
conduit dans la cellule de l'archevêque après avoir montré l'ordre 
de réquisition du tribunal de Posen. Après avoir fait connaître au 
prélat l'ordre qu'il était chargé d'exécuter, il ouvrit la seule armoire 
qui se trouvait dans la chambre pour chercher des objets suscep- 
tibles d'être saisis et ne trouva naturellement rien. Il demanda 
ensuite à qui apjiartenaient les malles. On lui répondit qu'elles ap- 
partenaient au fisc. L'huissier partit donc sans avoir rien pu saisir; 
mais il revint une heure après pour examiner la croix épiscopale 
et l'anneau qu'il avait vue sur la personne de Mgr Ledochowski. 
Seulement, il n'était pas chargé par l'autorité judiciaire d'entrer 
une seconde fois dans la prison de l'archevêque ; on refusa de le 
recevoir. » 

— Le 28* anniversaire de l'exaltation de Pie IX a été magnifi- 
quement célébré à .Munich, d'abord à la cathédrale, ensuite, le soir, 
dans une nombreuse réunion de catholiques, qui s'est tenue dans 
la halle de la grande brasserie royale située In'der Au. M. Schut- 
tinger, député au Reichstag et à la chambre bavaroise, monta d'a- 
bord à la tribune au milieu des applaudissements universels. Après 
avoir traité de la situation de l'Eglise catholique partout persécutée, 
et surtout en Allemagne, il dit : « Nous catholiques, nous nous 
glorifions de ce vieillard d'outre-monts, de ce Pape saint et véné- 
rable qui souffre persécution pour la vérité, le droit et la liberté ; 
on nous appelle ultramontains ; mais c'est là r.n titre d'honneur, 
car nous sommes en réalité ultramontains attachés de cœur, de 
volonté et d'esprit au Chef suprême de l'Eglise, le seul et véritable 
représentant de Dieu sur la terre. Combien 'il est admirable de voir 
ce Pontife, abandonné par tous les grands de la terre, malgré les 
tempêtes qui assaillent sa barque, malgré sa faiblesse apparente, 


18 ANNALES CATHOLIQUES 

rester ferme, vigoureux et fort de la force de Dieu, ne s'appuyaut 
que sur les principes éternels pour déjouer tous les projets de 
l'enfer ! La lutte que l'empire a engagée avec lui ne peut l'ébranler; 
les efforts du libéralisme se briseront au roc sur lequel Pie IX se 
tient inébranlable, car les portes de l'enfer ne prévaudront jamais 
contre l'Eglise et la chaire de Pierre. » 

Quand M. Schultinger eut cessé de parler, on cria des vivats en 
l'honneur du Pontife-Roi. Après le discours, la musique militaire 
exécuta une brillante symphonie de Beethoven, et la société cho- 
rale la Concordia chanta un hymne à Pie IX. 

A peine les accords de cet hymne magnitique eurent-ils cessé 
de retentir, que le député "Westermayer monta à la tribun^. lî 
commença par établir un parallèle entre les principes révolution- 
tionnaires de 1789 et les principes de l'Etat moderne. Il induisit 
de la situation que ces principes font à l'Eglise catholique, la né- 
cessité pour tous les fidèles de s'unir en rangs serrés pour défendre 
les principes éternels du christianisme contre tous les ennemis de 
la foi et de la conscience. M. "Westermayer développa cette thèse, 
indiqua les devoirs qu'il y avait à remplir et la position qu'il y 
avait à prendre pour ne se laisser ni séduire ni' vaincre. «Gloire 
à Dieu, fidélité à la sainte Eglise, dévoùment sans bornes au Sou- 
verain Pontife, attachement inviolable à l'épiscopat, telles sont les 
vertus qui doivent briller aujourd'hui dans tout catholique, et avec 
ces vertus, quelque grands et puissants que soient les ennemis de 
noire foi, nous les vaincrons. Vive Pie IX ! vive le Pontife-Uoi ! » 
Près de dix mille poitrines répétèrent cette acclamation, et l'im- 
mense auditoire se sépara au son du Te Deum allemand, exécuté 
par la musique militaire. 

— Le Courrier du Bas-Rhin annonce que « par ordre supérieur, 
les Frères instituteurs et les Sœurs institutrices appartenant à des 
ordres religieux étrangers et fonctionnant en Alsace-Lorraine, de- 
' vront cesser leurs fonctions h i)artir du I" octobre prochain. » 

Le lundi 2-1 juin, arrivait de Berlin c\ M. l'abbé Miiry, supérieur 
du petit séminaire de Strasbourg, l'avis ot'liciel que son recours au 
chancelier de l'empire, — recours interjeté après le décret de fer- 
meture de l'établissement, signé du président supérieur d' Alsace- 
Lorraine, — était rejeté comme non fondé. 

Le lendemain soir, le directeur de polici', M. Mannss, venait de- 
mander au supérieur s'il voulait fermer lui-même rétiii)lissement 
ou si la police devait le faire. M. Mury répondit qu'assurémeiii ii 
ne fermeiait pas lui-môme sa propre' niiiison : il d^-mandait jus 


CDRONIQUE ET FAITS DIVERS VJ 

qu'au lendemain pour prendre les instructions de son évoque. 

Le matin du 2û juin, à neuf heures, M. Mury est allé, au nom 
do l'évoque, prier le directeur de police de surseoir h l'exécution. 
Réponse lui fut faite qu'à moins de contre-ordre du président supé- 
rieur, le petit séminaire serait fermé dans la journée. 

De là, le supérieur, toujours au nom de l'évoque, se présenta 
chez M. de Mœller, président supérieur d'Alsace-Lorraine, et lui 
annonça la visite du prélat, ajoutant que Mgr Raess préparait, peur 
l'envoyer à Berlin, un nouveau mémoire de protestation. « Toutes 
les instances sont épuisées, répondit M. de Mœller; toute nouvelle 
démarche est inutile. » 

Le soir donc, à quatre heures, un inspecteur et un commissaire 
de police, assistés de quatre agents, arrivent au petit séminaire. Ils 
demandent le supérieur. On était réuni à la chapelle. Le supérieur 
sort. Ces messieurs lui annoncent qu'ils viennent pour fermer l'é- 
tablissement, et lui demandent quelle heure lui convient le mieux. 
« L'heure m'est indift'érente, » répond M. Mury. 

II retourne à la chapelle : « Cher.s élèves, dit-il, vous venez d'as- 
sister au dernier office du petit séminaire de Strasbourg. En ce 
moment, les agents de police envahissent la maison et viennent 
fermer les salles de classes. Conservez en face de la persécution le 
calme et la dignité du silence. Une dernière fois recommandez la 
cause du petit séminaire à Dieu et à la justice. » 

Après ces quelques paroles, accueillies par une douloureuse émo- 
tion, le supérieur va rejoindre les agents, qui lui demandent les 
clefs et le prient de lui indiquer les salles de la classe. 

Les portes de ces salles sont fermées à clef par l'inspecteur de 
police. Puis, lecture est faite d'un article de loi punissant de cent 
Ihalers d'amende tout essai de faire classe. 

Le supérieur fait consigner au procès-verballa protestation qu'il 
élève au nom de. son évêque, en son propre nom, au nom des pro- 
fesseurSj^es élèves, de leurs parents et de tous les catholiques 
d'Alsace-Lorraine. Puis, tout est terminé ! ! ! 

— 11 paraît qu'une entente est à la veille de s'établir entre la cour 
de Rome et le gouvernement badois, relativement à l'archevêché 
de Fribourg. Le gouvernement a laissé 5 noms sur la list3 des 
14 candidats qui lui ont été présentés par le chapitre. Ce sont 
NN. SS. Haneberg et Héfélé, évêques de Spire et de Rottenbourg ; 
les trois chanoines Behrle, Dieringer et Alzog. Ce derni'^r surtout 
est connu pour de savants travaux théologique?. 

A cette occasion, nous devons faire connaître le bref adressé par 


20 ANSALES CATHOLIQUES 

le Pape à Mgr Kaebel, évêque administpateur de l'archidiocèse da 
Fribourg en Brisgau (grand-duché de Bade) : 

Vénérable Fr^re, salut et bénédiction apostolique. 

De nos jo .rs, vénérable frère, chaque fois qu'on apprend qu'une 
mesure de persécution a été proposée contre l'Eglise, on ne peut 
plus guère douter que bientôt elle ne passe en loi. 

C'est pour C3tte raison que Nous ne Nous étonnons aucunement 
de ce qu'on ait ajouté au code du grand-duché de Bade, la loi que 
vous Nous avez signalée d'avance à la tin de l'année dernière, 
comme devant entraver les fonctions épiscopales et sacerdotales, 
fouler aux pieds les droits sacrés, supprimer les séminaires et dé- 
truire toute la constitution de l'Eglise. 

Mais taudis que les puissances des ténèbres s'acharnent de toutes 
parts contre le roc que le Christ a établi, et unissent leurs efforts 
pour le saper, — ce roc ne s'en montre que plus ferme dans son 
immobilité et soutient, sans être ébranlé, le choc des ennemis, 
dont la main ne semble frapper que des coups d'enfant. Car partout 
les évoques, quoique exposés aux amendes, aux spoliations, aux 
souffrances, à la prison, k l'exil, et, avec eux, le clergé en butte aux 
mêmes maux, deviennent, devant les droits sacrés, une colonne de 
fer et un mur d'airain. Non-seulement ils ne tremblent pas devant 
les puissants ; mais le front haut, ils font connaître et condamnent 
les lois perverses, et ils s'efforcent, autant qu'il est en leur pouvoir, 
d'empôcher qu'elles ne soient proposées. Si malgré cela elles sont 
votées, ils déclarent sans crainte qu'ils ne peuvent pas leur obéir, 
et ils élèvent la voix pour engager leur troupeau à obéir à Dieu 
plutôt qu'aux hommes. 

Car, en effet, on ne refuse pas la soumission due au pouvoir 
civil, lorsqu'on ne veut pas obéir à de pareilles ordonnances, 
puisque celles-ci ne sont aucunement des lois, soit piirce qu'elles 
sont portées par des hommes qui n'ont auiuu pouvoir sur l'Eglise, 
soit parce que quiconque contredit la doctrine do l'Eglise se met en 
opposition avec la loi de Dieu, à laquelle la Volonté de l'homme ne 
peut rien chinger. 

Nous vous félicitons donc, vénérable Frère, Nius félicitons votre 
clergé. Ni vous ni lui, vous ne le cédez à aucun de vos frères : prêts 
à subir loules les épreuves [)our Dieu, vous donnez à l'Eglise, par 
cette très-noble constance, un triomphe plus beau qu'aucune vic- 
toire matérielle. 
Résistez donc, eu demeuiunt fermes dans lu foi, et combattez le 


à 


CHRONIQUE ET FAITS DIVERS 21 

serment antique. Cnr toutes vos souffrances seront convertios en 
couronii(\s, puisque Dieu a appelé bieul.eiireux ceux qui souffrent 
perbt'cution pour la justice. 

Pour Nous, Nous vous souhaitons, dans cette lutte difficile, à 
vous, à votre clergé ei à vo3 fidèles, les secours eflicaces et abon- 
dants de la grâce céleste, — et en attendant, Nous vous accordons 
avec une grande ;iffection la bénédiction apostolique, comme pré- 
sage de la laveur divine et gage de Notre bienveillance toute spé- 
ciale. 

Donné à Rome, près Saint-Pierre, le 20' jour d'avril 1874, de 
Notre Pontiûcat l'année vingt-huitième. 

PIE IX, PAPE. 

BELGIQUE. 

Dans une réunion ^es Anciens étudiants de l'Université catholique 
de Louvain, qui a eu lieu le 21 juin, Mgr Cartuyvels, vice-recteur 
de l'Université, a fait entendre ces paroles, accueillies par d'una- 
nimes applaudissements : 

« Naguère, l'Eglise universelle célébrait le centenaire de saint 
Thomas d'Aquin, de saint Thomas, cette personnification du génie 
grandi à des proportions surhumaines au service de la foi et de la 
verlu. A l'époque où saint Thomas illustrait les académies, la chré- 
tienté se couvrait d'une floraison d'écoles aussi splendidç que celle 
des cathédrales qui s'élevaieut alors d'un bout à l'autre de l'Europe. 
De Naples à Paris, en passant par Bologne et Cologne, le docteur 
angélique rencontrait partout des milliers de disciples, réunis autour 
des chaires éiigées par les Papes, et du haut desquelles la science 
et la foi se prêtant un mutuel appui préparaient au monde la ma- 
gnifique expansion de la civilisation chélienne du treizième siècle. 
Presque lotîtes ces grandes écoles sont tombées sous les atteintes 
de r^.érésie ou sous les coups du marteau révolutionnaire; mais 
voici que le centenaire de saint Thomas d'Aquin éclaire partout des 
germes nouveaux, soulève la poussière des ruines; et au milieu de 
l'ébranlement général qui fait crouler autour de nous ce qui reste 
des institutions des anciens âges, il nous est permis de saluer dans 
la résurrection des universités catholiques les centres providentiels 
de l'avenir. 

« En ce moment le monde chrétien tout entier s'émeut d'un triom- 
phant anniversaire : le couronnement de Pie IX! (Acclamations.) 
Messieurs, toute parole est ici superflue, et nulle déraonstation ne 
rendra jamais l'émotion que ce nom vénéré fait vibrer dans nos 


22 ANNALES CATHOLIQUES , 

âmes! (Acclamations et vivats.) Autour de ce front vénérable où 
l'onction sacrée a fixé la tiare, l'histoire à son tour a posé trois 
rayonnantes couronnes : la couronne de la vérité et de la doctrine, 
des dogmes, par d'immortelle^.- encycliques, par les canons du con- 
cile, par des paroles de feu tombant à toute heure de cette bouche 
de prophète: la couronne austère des tribulations supportées pour 
la justice avec un cœur magnanime qui soutient le courage de tous 
les persécutés de l'univers. La couronne, enfin, des grandes œuvres 
qui ont dilaté l'apostolat jusqu'aux confins de la terre, rétabli la 
hiérarchie, resserré l'unité, fait briller l'héroïsme de la foi, et qui 
préparent la restauration chrétienne des temps modernes. Messieurs, 
qu'il me soit permis d'unir dans mon cœur votre association aux 
gloires du Pontificat de Fie IX ! Puisse-t-elle à jamais s'inspirer de 
notre esprit! Puisse-t-elle mériter d'être un joyau de sa couronne! 
Puisse-t-elle grandir chaque jour en nombre, en puissance, en 
œuvres pour la prospérité de VAltna Mater, la gloire de l'Eglise et 
Ib salut de notre pays ! h 

BRÉSIL. 

Un câble transocéanique vient d'être placé entre le Portugal et le 
Brésil. L'une des premières dépêches qu'il a transmises, le 25 juin, 
nous a apport ■; la douloureuse nouvelle de la mort de Mgr de Sil- 
veira, comte de San Salvador, archevêque de Bahia et primat du 
Brésil, dont nous avons dernièrement fait connaître la courageuse 
protestation contre les actes de persécution qui affligent cet empire. 

ESPAGNE. 

Une scène des plus scandaleuses s'est passée il y a quelques 
semaines, à Palencia, petite ville de la province de Léon. Les caril- 
loni'eurs de Palencia ayant reçu l'ordre de sonner les cloches pour 
se conformer au rituel, quelques jeunes gens se sont imaginé que 
le clergé voulait se livrer à une démonstration carliste, et aussitôt 
toutes les églises ont été envahies par une foule en fureur. Les 
portes de la cathédrale ont été d'abord renversées. Puis les jeunes 
gens de la ville, ontcnnant des chansons obscènes, ont profané le 
sanctuaire et sont tour h tour montés en chaire pour faille entendre 
les cris de l'impiété. Dans l'église de Notre-Dame, le scandale a 
revêtu encore un caractère plus odieux. Lorsque, dans son délire, la 
foule a inondé la nef de ses fiots tumulluoux, il y aviiil adoration 
perpétuelle; l'ostensoir et l'hostie consacrée resplendissaient au 
milieu des lampes et des cierges allumés. Les profanateurs se sont 


CHRONIQUE ET FAITS DIVERS 23 

rués sur 1(? rnaîlre-autel, ont brisé le Saint-Sacrement, ont mis en 
pièces la sainte hostie; ensuite, tournant leur fureur sur le sacris- 
tain, ils l'ont obligé à leur apporter tous les missels, dont les 
fenillels ont été arrachés par eux, ainsi que les surplis dont ils ont 
fait un fou de joie. Enlin, pour couronner leur œuvre satanique, ils 
ont descellé le tabernacle, réduit en mille morceaux la croix et 
l'autel, lacéré des tableaux de grand*^ valeur et ont brûlé les confes- 
sionnaux. Quand l'autorité s'est présentée avec la guardia cioil 
pour mettre fin à ce désordre abominable, il n'étuit plus temps de 
rien empêcher, le sacrilège était consommé. L'évèqu*' du diocèse a 
fait fermer l'église Notre-Dame jusqu'à ce qu'elle pût ôtre puri- 
fiée solennellement de ces indignes profanations. 

HOLLANDE. 

Mgr Van Beck, qui vient d'être appelé au siège épiscopal de 
Bréda, en remplacement de Mgr Gheuk, décédé, avait occupé jus- 
que-là l(-s fonctions de vicaire général de l'évêché de Harlem ; il 
était en même temps doyen à Harlem et prévô!. du chapitre de la 
cathédrale ; il est très-regretté des ouailles qu'il va quitter. C'est 
un homme de profondes connaissances, d'un caractère élevé, pieux, 
affable, en un mot le bon pasteur auquel- se rallie le troupeau 
confié à sa garde. 

L'évêché de Bréda est le moins important de tout le pays; il 
compte 8 doyennés, 83 paroisses et 139,000 fidèles. Li,e jour de la 
consécration et de l'inslallatioa du nouveau prélat n'est pas encore 
fixé. 

Mgr Claessen, nommé évêque de Tripoli, administrateur aposto- 
lique de Batavia, en remplacement de Mgr Vranken, démission- 
naire, doit être consacré à Sitlard (duché de Limbourg), son lieu 
natal, oii demeure encore sa vieille mère, et oii fat également con- 
sacré son prédécesseur, Mgr Vranken, en 1847. Ce dernier occu- 
pait alors les fonctions de curé-doyen dans la petite ville limbour- 
geoise, de sorte que cet endroit semble choisi pour donner aux 
colonies hollandaises ses chefs ecclésiastiques. 

Ce fut Mgr Paredis, évêque de Ruremonde, qui consacra Mgr 
Vranken, il y a vingt-sept ans, et ce sera sans encore la même noble 
et saint vieillard qui consacrera son successeur. 

Quant à Mgr Vranken, après s'être voué pendant un quart de 
siècle à propager la foi aux Indes, il est revenu, forcé de prendre 
cette décision pour cause de santé. Il faut vivement regretter que 
Mgr Vranken ait dû quitter le ministère évangélique, car c'est un 
