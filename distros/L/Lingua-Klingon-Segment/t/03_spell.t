# vim:set filetype=perl sw=4 et:

#########################

use Test::More tests => 31;
use Test::Differences;
use Carp;

BEGIN {use_ok 'Lingua::Klingon::Segment', 'spell'; }

eq_or_diff [ spell 'monghom'  ],
           [ qw(m o n gh o m) ],
           'monghom';

eq_or_diff [ spell 'mongHom'  ],
           [ qw(m o ng H o m) ],
           'mongHom';

eq_or_diff [ spell 'mongghom'  ],
           [ qw(m o ng gh o m) ],
           'mongghom';

eq_or_diff [ spell 'vavoy' ],
           [ qw(v a v o y) ],
           'vavoy';

eq_or_diff [ spell "tu'lu'"  ],
           [ qw(t u ' l u ') ],
           "tu'lu'";

eq_or_diff [ spell "yIghuS" ],
           [ qw(y I gh u S) ],
           "yIghuS";

eq_or_diff [ spell "pa''a'"  ],
           [ qw(p a ' ' a ') ],
           "pa''a'";

eq_or_diff [ spell "cha'a'" ],
           [ qw(ch a ' a ') ],
           "cha'a'";

eq_or_diff [ spell "cha''a'"  ],
           [ qw(ch a ' ' a ') ],
           "cha''a'";

eq_or_diff [ spell 'cha' ],
           [ qw(ch a)    ],
           "cha";

eq_or_diff [ spell "rolIj" ],
           [ qw(r o l I j) ],
           "rolIj";

eq_or_diff [ spell "ro'lIj"  ],
           [ qw(r o ' l I j) ],
           "ro'lIj";

eq_or_diff [ spell "paw" ],
           [ qw(p a w)   ],
           "paw";

eq_or_diff [ spell "paw'" ],
           [ qw(p a w ')  ],
           "paw'";

eq_or_diff [ spell "pawbej"  ],
           [ qw(p a w b e j) ],
           "pawbej";

eq_or_diff [ spell "paw'bej"   ],
           [ qw(p a w ' b e j) ],
           "paw'bej";

eq_or_diff [ spell "paw'a'"  ],
           [ qw(p a w ' a ') ],
           "paw'a'";

eq_or_diff [ spell "paw''a'"   ],
           [ qw(p a w ' ' a ') ],
           "paw''a'";

eq_or_diff [ spell "Suy" ],
           [ qw(S u y)   ],
           "Suy";

eq_or_diff [ spell "Suy'" ],
           [ qw(S u y ')  ],
           "Suy'";

eq_or_diff [ spell "Suyvetlh"  ],
           [ qw(S u y v e tlh) ],
           "Suyvetlh";

eq_or_diff [ spell "Suy'vetlh"   ],
           [ qw(S u y ' v e tlh) ],
           "Suy'vetlh";

eq_or_diff [ spell "ghargh" ],
           [ qw(gh a r gh)  ],
           "ghargh";

eq_or_diff [ spell "gharghmey"   ],
           [ qw(gh a r gh m e y) ],
           "gharghmey";

eq_or_diff [ spell "ghargho" ],
           [ qw(gh a r gh o) ],
           "ghargho";

eq_or_diff [ spell "tlhIngan Hol Dajatlh'a'?"         ],
           [ qw(tlh I ng a n H o l D a j a tlh ' a ') ],
           "tlhIngan Hol Dajatlh'a'?";

# Test a long word
eq_or_diff [ spell "QaghHommeyHeylIjmo'"              ],
           [ qw(Q a gh H o m m e y H e y l I j m o ') ],
           "QaghHommeyHeylIjmo'";

# Test a long non-word
eq_or_diff [ spell "QaghHommeyHeylIjmoqqq"                ],
           [ qw(Q a gh H o m m e y H e y l I j m o q q q) ],
           "QaghHommeyHeylIjmoqqq";

# Test several long words
# From http://www.kli.org/wiki/index.php?Klingon%20Wordplay%20Contests
eq_or_diff [ spell "nobwI''a'pu'qoqvam'e' nuHegh'eghrupqa'moHlaHbe'law'lI'neS SeH'eghtaHghach'a'na'chajmo'" ],
           [ qw(n o b w I ' ' a ' p u ' q o q v a m ' e '
                n u H e gh ' e gh r u p q a ' m o H l a H b e ' l a w ' l I ' n e S
                S e H ' e gh t a H gh a ch ' a ' n a ' ch a j m o ') ],
           "The so-called great benefactors are seemingly unable to cause us to prepare to resume honorable suicide (in progress) due to their definite self control.";

eq_or_diff [ spell "be'HomDu'na'wIjtIq'a'Du'na'vaD ghur'eghqangqa'moHlaHqu'be'taH'a' Somraw'a'meyna'wIj'e'" ],
           [ qw(b e ' H o m D u ' n a ' w I j t I q ' a ' D u ' n a ' v a D
                gh u r ' e gh q a ng q a ' m o H l a H q u ' b e ' t a H ' a '
                S o m r a w ' a ' m e y n a ' w I j ' e ') ],
           "Is it not that my many, large, scattered muscles are quite capable of swelling for the benefit of the hearts of many scattered little women?";
