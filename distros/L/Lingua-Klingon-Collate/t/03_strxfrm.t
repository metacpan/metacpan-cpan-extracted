# vim:set filetype=perl sw=4 et:

#########################

use Test::More tests => 31;
use Carp;

BEGIN {use_ok 'Lingua::Klingon::Collate', 'strxfrm'; }

# Test individual characters
is(strxfrm('a'),   'a', 'a'  );
is(strxfrm('b'),   'b', 'b'  );
is(strxfrm('ch'),  'c', 'ch' );
is(strxfrm('D'),   'd', 'D'  );
is(strxfrm('e'),   'e', 'e'  );
is(strxfrm('gh'),  'f', 'gh' );
is(strxfrm('H'),   'g', 'H'  );
is(strxfrm('I'),   'h', 'I'  );
is(strxfrm('j'),   'i', 'j'  );
is(strxfrm('l'),   'j', 'l'  );
is(strxfrm('m'),   'k', 'm'  );
is(strxfrm('n'),   'l', 'n'  );
is(strxfrm('ng'),  'm', 'ng' );
is(strxfrm('o'),   'n', 'o'  );
is(strxfrm('p'),   'o', 'p'  );
is(strxfrm('q'),   'p', 'q'  );
is(strxfrm('Q'),   'q', 'Q'  );
is(strxfrm('r'),   'r', 'r'  );
is(strxfrm('S'),   's', 'S'  );
is(strxfrm('t'),   't', 't'  );
is(strxfrm('tlh'), 'u', 'tlh');
is(strxfrm('u'),   'v', 'u'  );
is(strxfrm('v'),   'w', 'v'  );
is(strxfrm('w'),   'x', 'w'  );
is(strxfrm('y'),   'y', 'y'  );
is(strxfrm("'"),   'z', "'"  );

# And a couple of words
is(strxfrm('monghom'), 'knlfnk', 'monghom');
is(strxfrm('mongHom'), 'knmgnk', 'mongHom');

# And some phrases of more than one word
# Non-letters should remain unchanged
is(strxfrm("tlhIngan Hol DajatlhlaH'a', tera'ngan?"),
   'uhmal gnj daiaujagzaz, terazmal?',
   "tlhIngan Hol DajatlhlaH'a', tera'ngan?");
is(strxfrm("wa'/cha',wej.loS vagh:jav!Soch?chorgh"),
   'xaz/caz,xei.jns waf:iaw!snc?cnrf',
   "wa'/cha',wej.loS vagh:jav!Soch?chorgh");
