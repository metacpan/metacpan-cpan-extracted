# vim:set filetype=perl sw=4 et:

#########################

use Test::More tests => 17;
use Carp;

BEGIN {use_ok 'Lingua::Klingon::Collate', 'strcoll'; }

cmp_ok(strcoll('ngan', 'nob' ), '>',  0, "'ngan' gt 'nob'" );
cmp_ok(strcoll('nob',  'ngan'), '<',  0, "'nob'  lt 'ngan'");
cmp_ok(strcoll('ngan', 'ngan'), '==', 0, "'ngan' eq 'ngan'");
cmp_ok(strcoll('nob',  'nob' ), '==', 0, "'nob'  eq 'nob'" );

cmp_ok(strcoll('mongHom', 'monghom'), '>',  0, "'mongHom' gt 'monghom'");
cmp_ok(strcoll('monghom', 'mongHom'), '<',  0, "'monghom' lt 'mongHom'");
cmp_ok(strcoll('mongHom', 'mongHom'), '==', 0, "'mongHom' eq 'mongHom'");
cmp_ok(strcoll('monghom', 'monghom'), '==', 0, "'monghom' eq 'monghom'");

# Test multiple words
cmp_ok(strcoll('ngan legh', 'nob legh' ), '>',  0, "'ngan legh' gt 'nob legh'" );
cmp_ok(strcoll('nob legh',  'ngan legh'), '<',  0, "'nob legh'  lt 'ngan legh'");
cmp_ok(strcoll('ngan legh', 'ngan legh'), '==', 0, "'ngan legh' eq 'ngan legh'");
cmp_ok(strcoll('nob legh',  'nob legh' ), '==', 0, "'nob legh'  eq 'nob legh'" );
cmp_ok(strcoll('ngan legh', 'ngan let' ), '<',  0, "'ngan legh' lt 'ngan let'" );
cmp_ok(strcoll('ngan let',  'ngan legh'), '>',  0, "'ngan let'  gt 'ngan legh'");
cmp_ok(strcoll('nob legh',  'nob let'  ), '<',  0, "'nob legh'  lt 'nob let'"  );
cmp_ok(strcoll('nob let',   'nob legh' ), '>',  0, "'nob let'   gt 'nob legh'" );

# Don't test words where a letter contrasts with space, since the relative
# order of letters and ' ' is not defined in general. (In ASCII and, by
# extension, ISO-8859-1 and Unicode, space sorts before all letters, but
# I don't want to relay on that.)
