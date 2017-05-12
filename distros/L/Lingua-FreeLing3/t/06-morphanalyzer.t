# -*- cperl -*-

use utf8;
use warnings;
use strict;

use Test::More tests => 40;
use Test::Warn;
use Lingua::FreeLing3::MorphAnalyzer;
use Lingua::FreeLing3::Tokenizer;
use Lingua::FreeLing3::Splitter;
use Data::Dumper;

my %options = (
               AffixAnalysis         => 1,
               AffixFile             => 'afixos.dat',
               MultiwordsDetection   => 1,
               NumbersDetection      => 1,
               DatesDetection        => 1,
               PunctuationDetection  => 1,
               DictionarySearch      => 1,
               ProbabilityAssignment => 1,
               QuantitiesDetection   => 0,
               NERecognition         => 1,
               PunctuationFile       => '../common/punct.dat',
               LocutionsFile         => 'locucions.dat',
               ProbabilityFile       => 'probabilitats.dat',
               DictionaryFile        => 'dicc.src',
               NPdataFile            => 'np.dat',
              );


my $maco = Lingua::FreeLing3::MorphAnalyzer->new("es", %options);

# defined
ok     $maco => 'We have a morphological analyzer';
isa_ok $maco => 'Lingua::FreeLing3::MorphAnalyzer';

ok exists($maco->{maco})         => 'Object has "maco" field';
ok exists($maco->{prefix})       => 'Object has "prefix" field';
ok exists($maco->{maco_options}) => 'Object has "maco_options" field';

isa_ok $maco->{maco}         => 'Lingua::FreeLing3::Bindings::maco';
isa_ok $maco->{maco_options} => 'Lingua::FreeLing3::Bindings::maco_options';

warning_is
  { ok !$maco->analyze() => "Can't analyze nothing" }
  { carped => "Error: analyze argument should be a list of sentences" },
  "Warning is issued";

warning_is
  { ok !$maco->analyze("") => "Can't analyze empty string" }
  { carped => "Error: analyze argument should be a list of sentences" },
  "Warning is issued";

warning_is
  { ok !$maco->analyze("foo") => "Can't analyze a string" }
  { carped => "Error: analyze argument should be a list of sentences" },
  "Warning is issued";

warning_is
  { ok !$maco->analyze(["foo","bar"])  => "Can't analyze a list of strings" }
  { carped => "Error: analyze argument should be a list of sentences" },
  "Warning is issued";

my $text = <<EOT;
2010 quedará como el año en el que la "economía española escapó", a
duras penas, de la QHFdjhfdfsD. Pero también, como el año en el que
la tasa de paro se instaló en el 20%. Además, la última cosecha
estadística de la Encuesta de Población Activa (EPA) certifica lo que
no fue: para dar por acabada la brutal destrucción de empleo que
acompaña a la crisis habrá que esperar. Tras encadenar dos trimestres
con "un leve aumento en la creación de puestos de trabajo", el mercado
laboral volvió, entre octubre y diciembre, a dar su peor cara. En el
trimestre de cierre de 2010, la EPA registró 138.600 personas ocupadas
menos, de las que 16.700 optaron por no seguir buscando trabajo. Las
otras 121.900 personas que perdieron el empleo engrosaron la lista del
paro.
EOT

my $tok = Lingua::FreeLing3::Tokenizer->new('es');
my $spl = Lingua::FreeLing3::Splitter->new('es');

my $tokens = $tok->tokenize($text);
my $sentences = $spl->split($tokens);
isa_ok $sentences->[0] => 'Lingua::FreeLing3::Sentence';

$sentences = $maco->analyze($sentences);
isa_ok $sentences->[0] => 'Lingua::FreeLing3::Sentence';

my $sentence = $sentences->[0];
my $words_have_lemma = 1;
for my $word ($sentence->words) {
    $words_have_lemma = 0 unless $word->lemma;
}
ok $words_have_lemma => 'All analyzed words have a lemma';

## -- año --

my $random_word = ($sentence->words)[4];
is $random_word->form  => "año", 'fifth word is "año"';
is $random_word->lemma => "año", 'fifth word lemma is also "año"';

my $analysis = $random_word->analysis;
is scalar(@$analysis) => 1, "'año' has just one analysis";

isa_ok $analysis => "ARRAY", "analysis";
isa_ok $analysis->[0] => "Lingua::FreeLing3::Word::Analysis", "Each analysis";

is $analysis->[0]->lemma  => "año", 'analysis lemma is "año"';
is $analysis->[0]->tag => "NCMS000", 'POS';
like $analysis->[0]->prob => qr/^\d(?:\.\d+)?$/, "probability is a number";

ok !$analysis->[0]->retokenizable, "This analysis is not retokenizable";

## -- el -- ##

my $other_word = ($sentence->words)[7];
is $other_word->form => "que", "Seventh word is 'que'";

## ok $other_word->in_dict;

$analysis = $other_word->analysis;
is scalar(@$analysis) => 2, "'que' has two possible analysis";

for my $a (@$analysis) {
    isa_ok $a => 'Lingua::FreeLing3::Word::Analysis', "Each analysis";
    is $a->lemma, "que", "both lemma are 'que'";
}
isnt $analysis->[0]->tag, $analysis->[1]->tag, "POS differ for the two analysis";

## -- QHFdjhfdfsD -- ##
my $nonword = $sentence->word(19);
is $nonword->form => "QHFdjhfdfsD", "twentieth word is 'QHFdjhfdfsD'";
## ok $nonword->in_dict;

ok $sentence->word(15)->is_multiword, "Is a multiword";

my @mwWords = $sentence->word(15)->get_mw_words;
is scalar(@mwWords) => 3, "Multiword has 3 words";
for my $i (0..2) {
    isa_ok $mwWords[$i] => 'Lingua::FreeLing3::Word';
}
