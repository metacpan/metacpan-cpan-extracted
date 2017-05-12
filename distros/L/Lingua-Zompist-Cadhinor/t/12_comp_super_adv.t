# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 30;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', qw(comp super adv); }

is(comp('ZOL'     ), 'ZOLOR',     'comparative of ZOL'     );
is(comp('ALETES'  ), 'ALETEDHES', 'comparative of ALETES'  );
is(comp('ILIS'    ), 'ILIOR',     'comparative of ILIS'    );
is(comp('GGG'     ), 'GGGOR',     'comparative of GGG'     );
is(comp('GGGES'   ), 'GGGEDHES',  'comparative of GGGES'   );
is(comp('GGGIS'   ), 'GGGIOR',    'comparative of GGGIS'   );
is(comp('MELIS'   ), 'MELIOR',    'comparative of MELIS'   );
is(comp('DURENGES'), 'AVECOR',    'comparative of DURENGES');

is(super('ZOL'     ), 'ZOLASTES',  'superlative of ZOL'     );
is(super('ALETES'  ), 'ALETASCES', 'superlative of ALETES'  );
is(super('ILIS'    ), 'ILISCES',   'superlative of ILIS'    );
is(super('GGG'     ), 'GGGASTES',  'superlative of GGG'     );
is(super('GGGES'   ), 'GGGASCES',  'superlative of GGGES'   );
is(super('GGGIS'   ), 'GGGISCES',  'superlative of GGGIS'   );
is(super('MELIS'   ), 'MELASTES',  'superlative of MELIS'   );
is(super('DURENGES'), 'AVESTES',   'superlative of DURENGES');

is(adv('ZOL'     ), 'ZOLA',      'adverb from ZOL'     );
is(adv('KAR'     ), 'KARA',      'adverb from KAR'     );
is(adv('GGG'     ), 'GGGA',      'adverb from GGG'     );
is(adv('ALETES'  ), 'ALETECUE',  'adverb from ALETES'  );
is(adv('BREVES'  ), 'BREVECUE',  'adverb from BREVES'  );
is(adv('DHAHES'  ), 'DHAHECUE',  'adverb from DHAHES'  );
is(adv('GGGES'   ), 'GGGECUE',   'adverb from GGGES'   );
is(adv('ILIS'    ), 'ILICUE',    'adverb from ILIS'    );
is(adv('TECNIS'  ), 'TECNICUE',  'adverb from TECNIS'  );
is(adv('CLECNIS' ), 'CLECNICUE', 'adverb from CLECNIS' );
is(adv('GGGIS'   ), 'GGGICUE',   'adverb from GGGIS'   );
is(adv('MELIS'   ), 'MELIO',     'adverb from MELIS'   );
is(adv('DURENGES'), 'AVECUE',    'adverb from DURENGES');
