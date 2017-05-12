# vim:set filetype=perl sw=4 et:

#########################

use Test::More tests => 7;
use Test::Differences;
use Carp;

BEGIN {use_ok 'Lingua::Klingon::Collate', ':all'; }

eq_or_diff [ strxfrm('monghom', 'mongHom') ],
           [ 'knlfnk', 'knmgnk'            ],
           "list output of strxfrm";

is(strxfrm('monghom', 'mongHom'), 'knlfnk', 'scalar output of strxfrm');

eq_or_diff [ strunxfrm('knlfnk', 'knmgnk') ],
           [ 'monghom', 'mongHom'          ],
           "list output of strunxfrm";

is(strunxfrm('knlfnk', 'knmgnk'), 'monghom', 'scalar output of strunxfrm');

# Test with phrases

eq_or_diff [ strxfrm(
    "tlhIngan Hol DajatlhlaH'a', tera'ngan?",
    "wa'/cha',wej.loS vagh:jav!Soch?chorgh") ],
    [ 'uhmal gnj daiaujagzaz, terazmal?',
      'xaz/caz,xei.jns waf:iaw!snc?cnrf' ],
    "list output of strxform (phrases)";

eq_or_diff [ strunxfrm(
    'uhmal gnj daiaujagzaz, terazmal?',
    'xaz/caz,xei.jns waf:iaw!snc?cnrf') ],
    [ "tlhIngan Hol DajatlhlaH'a', tera'ngan?",
      "wa'/cha',wej.loS vagh:jav!Soch?chorgh" ],
    "list output of strunxfrm (phrases)";
