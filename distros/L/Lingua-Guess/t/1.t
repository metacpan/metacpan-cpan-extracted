#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Lingua::Guess;
use utf8;

my $guess = Lingua::Guess->new();
ok( $guess, "Created langauge guesser object" );

my $lang;

is( $guess->simple_guess("This is a test of the language checker" ), "english");
is( $guess->simple_guess("Verifions que le détecteur de langues marche" ), "french");
is( $guess->simple_guess("Sprawdźmy, czy odgadywacz języków pracuje" ), "polish");
is( $guess->simple_guess("авай проверить  узнает ли наш угадатель русски язык"),"russian");

is( $guess->simple_guess("La respuesta de los acreedores a la oferta argentina para salir del default no ha sido muy positiv"),"spanish");
is( $guess->simple_guess("Сайлау нәтижесінде дауыстардың басым бөлігін ел премьер министрі Виктор Янукович пен оның қарсыласы, оппозиция жетекшісі Виктор Ющенко алды."),"kazakh"); 
is( $guess->simple_guess("милиция ва уч солиқ идораси ходимлари яраланган. Шаҳарда хавфсизлик чоралари кучайтирилган."),"uzbek"); 
is( $guess->simple_guess("көрбөгөндөй элдик толкундоо болуп, Кокон шаарынын көчөлөрүндө бир нече миң киши нааразылык билдирди."),"kyrgyz"); 
is( $guess->simple_guess("yakın tarihin en çekişmeli başkanlık seçiminde oy verme işlemi sürerken, katılımda rekor bekleniyor."),"turkish"); 
is( $guess->simple_guess("Daxil olan xəbərlərdə deyilir ki, 6 nəfər Bağdadın mərkəzində yerləşən Təhsil Nazirliyinin binası yaxınlığında baş vermiş partlayış zamanı həlak olub."),"azeri");
 
is( $guess->simple_guess(" ملايين الناخبين الأمريكيين يدلون بأصواتهم وسط إقبال قياسي على انتخابات هي الأشد تنافسا منذ عقود"), "arabic");
is( $guess->simple_guess("Американське суспільство, поділене суперечностями, збирається взяти активну участь у голосуванні"), "ukrainian");
is( $guess->simple_guess("Francouzský ministr financí zmírnil výhrady vůči nízkým firemním daním v nových členských státech EU"), "czech");
is( $guess->simple_guess("biće prilično izjednačena, sugerišu najnovije ankete. Oba kandidata tvrde da su sposobni da dobiju rat protiv terorizma"), "croatian");
is( $guess->simple_guess(" е готов да даде гаранции, че няма да прави ядрено оръжие, ако му се разреши мирна атомна програма"), "bulgarian");
is( $guess->simple_guess("на јавното мислење покажуваат дека трката е толку тесна, што се очекува двајцата соперници да ја прекршат традицијата и да се појават и на самиот изборен ден."), "macedonian");
is( $guess->simple_guess("în acest sens aparţinînd Adunării Generale a organizaţiei, în ciuda faptului că mai multe dintre solicitările organizaţiei privind organizarea scrutinului nu au fost soluţionate"), "romanian");
is( $guess->simple_guess("kaluan ditën e fundit të fushatës në shtetet kryesore për të siguruar sa më shumë votues."), "albanian");
is( $guess->simple_guess("αναμένεται να σπάσουν παράδοση δεκαετιών και να συνεχίσουν την εκστρατεία τους ακόμη και τη μέρα των εκλογών"), "greek");
is( $guess->simple_guess(" 美国各州选民今天开始正式投票。据信，"), "chinese");
is( $guess->simple_guess(" Die kritiek was volgens hem bitter hard nodig, omdat Nederland binnen een paar jaar in een soort Belfast zou dreigen te veranderen"), "dutch");
is( $guess->simple_guess("På denne side bringer vi billeder fra de mange forskellige forberedelser til arrangementet, efterhånden som vi får dem "), "danish");
is( $guess->simple_guess("Vi säger att Frälsningen är en gåva till alla, fritt och för intet.  Men som vi nämnt så finns det två villkor som måste"), "swedish");
is( $guess->simple_guess("Nominasjonskomiteen i Akershus KrF har skviset ut Einar Holstad fra stortingslisten. Ytre Enebakk-mannen har plass p Stortinget s lenge Valgerd Svarstad Haugland sitter i"), "norwegian");
is( $guess->simple_guess("on julkishallinnon verkkopalveluiden yhteinen osoite. Kansalaisten arkielämää helpottavaa tietoa on koottu eri aihealueisiin"), "finnish");
is( $guess->simple_guess("Ennetamaks reisil ebameeldivaid vahejuhtumeid vii end kurssi reisidokumentide ja viisade reeglitega ning muu praktilise informatsiooniga"), "estonian");
is( $guess->simple_guess("Hiába jön létre az önkéntes magyar haderő, hiába nem lesz többé bevonulás, változatlanul fennmarad a hadkötelezettség intézménye"), "hungarian");
is( $guess->simple_guess("հարաբերական"), "armenian");
 
done_testing ();
 
