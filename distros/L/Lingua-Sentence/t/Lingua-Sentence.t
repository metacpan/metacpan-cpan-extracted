use strict;
use warnings;
use Lingua::Sentence;
use Test::More tests => 32;

# English split test string and array results
my $splitter = Lingua::Sentence->new("en");
isa_ok($splitter,'Lingua::Sentence');
is($splitter->split('Foo'),"Foo\n",'Line break appended to single word');
is($splitter->split('This is a paragraph. It contains several sentences. "But why," you ask?'),"This is a paragraph.\nIt contains several sentences.\n\"But why,\" you ask?\n", 'Three test sentences split');

my @split = $splitter->split_array('This is a paragraph. It contains several sentences. "But why," you ask?');
is(@split,3,'Three elements in split array');
is($split[0],'This is a paragraph.','First array element correct');
is($split[1],'It contains several sentences.','Second array element correct');
is($split[2],'"But why," you ask?','Third array element correct');

@split = $splitter->split_array('Hey! Now.');
is(@split,2,'Two elements in split array');
is($split[0],'Hey!','First array element correct');
is($split[1],'Now.','Second array element correct');

@split = $splitter->split_array('Hey... Now.');
is(@split,2,'Two elements in split array');
is($split[0],'Hey...','First array element correct');
is($split[1],'Now.','Second array element correct');

@split = $splitter->split_array('Hey. Now.');
is(@split,2,'Two elements in split array');
is($split[0],'Hey.','First array element correct');
is($split[1],'Now.','Second array element correct');

@split = $splitter->split_array('Hey.  Now.');
is(@split,2,'Two elements in split array');
is($split[0],'Hey.','First array element correct');
is($split[1],'Now.','Second array element correct');

# Create splitter for language that does not exist in current ISO 639-2 list
my $xo_splitter = Lingua::Sentence->new("xo");
isa_ok($xo_splitter,'Lingua::Sentence');
is($xo_splitter->split('This is a paragraph. It contains several sentences. "But why," you ask?'),"This is a paragraph.\nIt contains several sentences.\n\"But why,\" you ask?\n", 'Three test sentences split');
# Once a member variable for the language code is defined this could be checked here

# German split test
my $de_splitter = Lingua::Sentence->new("de");
isa_ok($de_splitter,'Lingua::Sentence');
is($de_splitter->split('Nie hätte das passieren sollen. Dr. Soltan sagte: "Der Fluxcompensator war doch kalibriert!".'),"Nie hätte das passieren sollen.\nDr. Soltan sagte: \"Der Fluxcompensator war doch kalibriert!\".\n","German split test");

# Greek split test
my $el_splitter = Lingua::Sentence->new("el");
isa_ok($el_splitter,'Lingua::Sentence');
is($el_splitter->split('Όλα τα συστήματα ανώτατης εκπαίδευσης σχεδιάζονται σε εθνικό επίπεδο. Η ΕΕ αναλαμβάνει κυρίως να συμβάλει στη βελτίωση της συγκρισιμότητας μεταξύ των διάφορων συστημάτων και να βοηθά φοιτητές και καθηγητές να μετακινούνται με ευκολία μεταξύ των συστημάτων των κρατών μελών.'),"Όλα τα συστήματα ανώτατης εκπαίδευσης σχεδιάζονται σε εθνικό επίπεδο.\nΗ ΕΕ αναλαμβάνει κυρίως να συμβάλει στη βελτίωση της συγκρισιμότητας μεταξύ των διάφορων συστημάτων και να βοηθά φοιτητές και καθηγητές να μετακινούνται με ευκολία μεταξύ των συστημάτων των κρατών μελών.\n","Greek split test");

# Portuguese split test
my $pt_splitter = Lingua::Sentence->new("pt");
isa_ok($pt_splitter,'Lingua::Sentence');
is($pt_splitter->split('Isto é um parágrafo. Contém várias frases. «Mas porquê,» perguntas tu?'),"Isto é um parágrafo.\nContém várias frases.\n«Mas porquê,» perguntas tu?\n","Portuguese split test");

# Spanish split test
my $es_splitter = Lingua::Sentence->new("es");
isa_ok($es_splitter,'Lingua::Sentence');
is($es_splitter->split('La UE ofrece una gran variedad de empleos en un entorno multinacional y multilingüe. La Oficina Europea de Selección de Personal (EPSO) se ocupa de la contratación, sobre todo mediante oposiciones generales.'),"La UE ofrece una gran variedad de empleos en un entorno multinacional y multilingüe.\nLa Oficina Europea de Selección de Personal (EPSO) se ocupa de la contratación, sobre todo mediante oposiciones generales.\n","Spanish split test");

# Split test with custom prefix file
ok( -e 't/nonbreaking_prefix.de');
my $de_custom_splitter = Lingua::Sentence->new("de","t/nonbreaking_prefix.de");
isa_ok($de_custom_splitter,'Lingua::Sentence');
is($de_custom_splitter->split('Nie hätte das passieren sollen. Dr. Soltan sagte: "Der Fluxcompensator war doch kalibriert!".'),"Nie hätte das passieren sollen.\nDr. Soltan sagte: \"Der Fluxcompensator war doch kalibriert!\".\n","German split test");
