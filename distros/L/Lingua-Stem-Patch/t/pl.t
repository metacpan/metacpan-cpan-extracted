use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 77;
use Lingua::Stem::Patch::PL qw( stem );

# nouns
is stem('gazetach'),    'gaze',    'remove -tach';
is stem('sytuacja'),    'syt',     'remove -acja';
is stem('sytuacją'),    'syt',     'remove -acją';
is stem('sytuacji'),    'syt',     'remove -acji';
is stem('kochanie'),    'koch',    'remove -anie';
is stem('ubraniu'),     'ubr',     'remove -aniu';
is stem('tłumaczenie'), 'tłumacz', 'remove -enie';
is stem('imieniu'),     'imi',     'remove -eniu';
is stem('spotyka'),     'spot',    'remove -ka from -tyka';
is stem('latach'),      'lat',     'remove -ach';
is stem('czasami'),     'czas',    'remove -ami';
is stem('miejsce'),     'miejs',   'remove -ce';
is stem('świata'),      'świ',     'remove -ta';
is stem('pojęcia'),     'poj',     'remove -cia';
is stem('pięciu'),      'pię',     'remove -ciu';
is stem('zobaczenia'),  'zobacze', 'remove -nia';
is stem('tygodniu'),    'tygod',   'remove -niu';
is stem('policja'),     'polic',   'remove -ja from -cja';
is stem('policją'),     'polic',   'remove -ją from -cją';
is stem('policji'),     'polic',   'remove -ji from -cji';

# diminutive
is stem('ptaszek'),   'pt',     'remove -aszek';
is stem('tyłeczek'),  'tył',    'remove -eczek';
is stem('policzek'),  'pol',    'remove -iczek';
is stem('kieliszek'), 'kiel',   'remove -iszek';
is stem('staruszek'), 'star',   'remove -uszek';
is stem('olejek'),    'olej',   'remove -ek from -ejek';
is stem('piosenek'),  'piosen', 'remove -ek from -enek';
is stem('derek'),     'der',    'remove -ek from -erek';
is stem('jednak'),    'jedn',   'remove -ak';
is stem('wypadek'),   'wypad',  'remove -ek';

# adjectives
is stem('najlepsze'),   'lep',   'remove naj- and -sze';
is stem('najlepszy'),   'lep',   'remove naj- and -szy';
is stem('najlepszych'), 'lep',   'remove naj- and -szych';
is stem('grzeczny'),    'grze',  'remove -czny';
is stem('dlaczego'),    'dlacz', 'remove -ego';
is stem('więcej'),      'więc',  'remove -ej';
is stem('żadnych'),     'żadn',  'remove -ych';
is stem('gotowa'),      'got',   'remove -owa';
is stem('gotowe'),      'got',   'remove -owe';
is stem('gotowy'),      'got',   'remove -owy';

# verbs
is stem('gdybym'),      'gdy',       'remove -bym';
is stem('oczywiście'),  'oczywiś',   'remove -cie';
is stem('miałem'),      'mia',       'remove -łem';
is stem('spotkamy'),    'spotk',     'remove -amy';
is stem('możemy'),      'moż',       'remove -emy';
is stem('pamiętasz'),   'pamięt',    'remove -asz';
is stem('chcesz'),      'chc',       'remove -esz';
is stem('ukraść'),      'ukr',       'remove -aść';
is stem('znieść'),      'zni',       'remove -eść';
is stem('mówiąc'),      'mów',       'remove -ąc';
is stem('zostać'),      'zost',      'remove -ać';
is stem('przepraszam'), 'przeprasz', 'remove -am';
is stem('miał'),        'mi',        'remove -ał';
is stem('mieć'),        'mi',        'remove -eć';
is stem('jestem'),      'jest',      'remove -em';
is stem('zrobić'),      'zrob',      'remove -ić';
is stem('zrobił'),      'zrob',      'remove -ił';
is stem('kraj'),        'kra',       'remove -j from -aj';
is stem('masz'),        'ma',        'remove -sz from -asz';
is stem('wpaść'),       'wpa',       'remove -ść from -aść';
is stem('wiesz'),       'wie',       'remove -sz from -esz';
is stem('cześć'),       'cze',       'remove -ść from -eść';

# adverbs
is stem('dobrze'), 'dobr', 'remove -ze from -rze';
is stem('panie'),  'pan',  'remove -ie from -nie';
is stem('prawie'), 'praw', 'remove -ie from -wie';

# plural
is stem('czasami'), 'czas',  'remove -ami';
is stem('poziom'),  'poz',   'remove -om';
is stem('dolarów'), 'dolar', 'remove -ów';

# others
is stem('dobra'),    'dobr',    'remove -a';
is stem('swoją'),    'swoj',    'remove -ą';
is stem('proszę'),   'prosz',   'remove -ę';
is stem('jeśli'),    'jeśl',    'remove -i';
is stem('pomysł'),   'pomys',   'remove -ł';
is stem('porządku'), 'porządk', 'remove -u';
is stem('kiedy'),    'kied',    'remove -y';
is stem('życia'),    'życ',     'remove -ia';
is stem('gdzie'),    'gdz',     'remove -ie';
