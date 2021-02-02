#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Lingua::Guess;
use utf8;

my $guess = Lingua::Guess->new();

ok ($guess, "Created language guesser object");

my @text_lang = (
["This is a test of the language checker", "english", "en", "eng"],
["Verifions que le détecteur de langues marche", "french"],
["Sprawdźmy, czy odgadywacz języków pracuje", "polish"],
["авай проверить  узнает ли наш угадатель русски язык", "russian"],
["La respuesta de los acreedores a la oferta argentina para salir del default no ha sido muy positiv", "spanish"],
["Сайлау нәтижесінде дауыстардың басым бөлігін ел премьер министрі Виктор Янукович пен оның қарсыласы, оппозиция жетекшісі Виктор Ющенко алды.", "kazakh"], 
["милиция ва уч солиқ идораси ходимлари яраланган. Шаҳарда хавфсизлик чоралари кучайтирилган.", "uzbek"], 
["көрбөгөндөй элдик толкундоо болуп, Кокон шаарынын көчөлөрүндө бир нече миң киши нааразылык билдирди.", "kyrgyz"], 
["yakın tarihin en çekişmeli başkanlık seçiminde oy verme işlemi sürerken, katılımda rekor bekleniyor.", "turkish"], 
["Daxil olan xəbərlərdə deyilir ki, 6 nəfər Bağdadın mərkəzində yerləşən Təhsil Nazirliyinin binası yaxınlığında baş vermiş partlayış zamanı həlak olub.", "azeri"],
[" ملايين الناخبين الأمريكيين يدلون بأصواتهم وسط إقبال قياسي على انتخابات هي الأشد تنافسا منذ عقود", "arabic"],
["Американське суспільство, поділене суперечностями, збирається взяти активну участь у голосуванні", "ukrainian"],
["Francouzský ministr financí zmírnil výhrady vůči nízkým firemním daním v nových členských státech EU", "czech"],
["biće prilično izjednačena, sugerišu najnovije ankete. Oba kandidata tvrde da su sposobni da dobiju rat protiv terorizma", "croatian"],
[" е готов да даде гаранции, че няма да прави ядрено оръжие, ако му се разреши мирна атомна програма", "bulgarian"],
["на јавното мислење покажуваат дека трката е толку тесна, што се очекува двајцата соперници да ја прекршат традицијата и да се појават и на самиот изборен ден.", "macedonian"],
["în acest sens aparţinînd Adunării Generale a organizaţiei, în ciuda faptului că mai multe dintre solicitările organizaţiei privind organizarea scrutinului nu au fost soluţionate", "romanian"],
["kaluan ditën e fundit të fushatës në shtetet kryesore për të siguruar sa më shumë votues.", "albanian"],
["αναμένεται να σπάσουν παράδοση δεκαετιών και να συνεχίσουν την εκστρατεία τους ακόμη και τη μέρα των εκλογών", "greek"],
[" 美国各州选民今天开始正式投票。据信，", "chinese"],
[" Die kritiek was volgens hem bitter hard nodig, omdat Nederland binnen een paar jaar in een soort Belfast zou dreigen te veranderen", "dutch"],
["På denne side bringer vi billeder fra de mange forskellige forberedelser til arrangementet, efterhånden som vi får dem ", "danish"],
["Vi säger att Frälsningen är en gåva till alla, fritt och för intet.  Men som vi nämnt så finns det två villkor som måste", "swedish"],
["Nominasjonskomiteen i Akershus KrF har skviset ut Einar Holstad fra stortingslisten. Ytre Enebakk-mannen har plass p Stortinget s lenge Valgerd Svarstad Haugland sitter i", "norwegian"],
["on julkishallinnon verkkopalveluiden yhteinen osoite. Kansalaisten arkielämää helpottavaa tietoa on koottu eri aihealueisiin", "finnish"],
["Ennetamaks reisil ebameeldivaid vahejuhtumeid vii end kurssi reisidokumentide ja viisade reeglitega ning muu praktilise informatsiooniga", "estonian"],
["Hiába jön létre az önkéntes magyar haderő, hiába nem lesz többé bevonulás, változatlanul fennmarad a hadkötelezettség intézménye", "hungarian"],
["հարաբերական", "armenian"],
);

for my $pair (@text_lang) {
    is ($guess->simple_guess ($pair->[0]), $pair->[1], "Got $pair->[1]");
}
for my $pair (@text_lang) {
    my $out = $guess->identify ($pair->[0]);
    my $total = 0;
    for (@$out) {
	$total = $_->{score};
    }
    ok (abs ($total - 1) < 0.0001, "$pair->[1] scores add to about 1");
}

done_testing ();
 
