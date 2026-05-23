package Genealogy::Relationship::Name;

# Genealogy::Relationship::Name - Return the name of a genealogical relationship
# given step counts to and from a common ancestor, the sex of person B, and a language.
#
# Author: Nigel Horne <njh@nigelhorne.com>
# Licence: GPL v2

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Object::Configure;
use Params::Get;
use Params::Validate::Strict 0.31;
use Readonly;

our $VERSION = '0.03';

# ---------------------------------------------------------------------------
# Constants – relationship table keys
# ---------------------------------------------------------------------------

# Supported language codes
Readonly::Array my @SUPPORTED_LANGUAGES => qw(de de_ch en es fa fr la);

# Default language when none supplied
Readonly::Scalar my $DEFAULT_LANGUAGE => 'en';

# Sex constants
Readonly::Scalar my $SEX_MALE   => 'M';
Readonly::Scalar my $SEX_FEMALE => 'F';

# ---------------------------------------------------------------------------
# English relationship tables
# Key: "$steps1,$steps2"  where steps1 = steps from A to ancestor,
#                                steps2 = steps from B to ancestor
# ---------------------------------------------------------------------------

Readonly::Hash my %EN_MALE_RELATIONSHIPS => (
	'0,0' => 'self',
	'0,1' => 'son',
	'0,2' => 'grandson',
	'0,3' => 'great-grandson',
	'0,4' => 'great-great-grandson',
	'0,5' => 'great-great-great-grandson',
	'0,6' => 'great-great-great-great-grandson',
	'0,7' => 'great-great-great-great-great-grandson',
	'0,8' => 'great-great-great-great-great-great-grandson',
	'0,9' => 'great-great-great-great-great-great-great-grandson',
	'0,10' => 'great-great-great-great-great-great-great-great-grandson',
	'1,0' => 'father',
	'1,1' => 'brother',
	'1,2' => 'nephew',
	'1,3' => 'great-nephew',
	'1,4' => 'great-great-nephew',
	'1,5' => 'great-great-great-nephew',
	'1,6' => 'great-great-great-great-nephew',
	'1,7' => 'great-great-great-great-great-nephew',
	'1,8' => 'great-great-great-great-great-great-nephew',
	'1,9' => 'great-great-great-great-great-great-great-nephew',
	'1,10' => 'great-great-great-great-great-great-great-great-nephew',
	'2,0' => 'grandfather',
	'2,1' => 'uncle',
	'2,2' => 'first cousin',
	'2,3' => 'first cousin once-removed',
	'2,4' => 'first cousin twice-removed',
	'2,5' => 'first cousin three-times-removed',
	'2,6' => 'first cousin four-times-removed',
	'2,7' => 'first cousin five-times-removed',
	'2,8' => 'first cousin six-times-removed',
	'2,9' => 'first cousin seven-times-removed',
	'2,10' => 'first cousin eight-times-removed',
	'3,0' => 'great-grandfather',
	'3,1' => 'great-uncle',
	'3,2' => 'first cousin once-removed',
	'3,3' => 'second cousin',
	'3,4' => 'second cousin once-removed',
	'3,5' => 'second cousin twice-removed',
	'3,6' => 'second cousin three-times-removed',
	'3,7' => 'second cousin four-times-removed',
	'3,8' => 'second cousin five-times-removed',
	'3,9' => 'second cousin six-times-removed',
	'3,10' => 'second cousin seven-times-removed',
	'4,0' => 'great-great-grandfather',
	'4,1' => 'great-great-uncle',
	'4,2' => 'first cousin twice-removed',
	'4,3' => 'second cousin once-removed',
	'4,4' => 'third cousin',
	'4,5' => 'third cousin once-removed',
	'4,6' => 'third cousin twice-removed',
	'4,7' => 'third cousin three-times-removed',
	'4,8' => 'third cousin four-times-removed',
	'4,9' => 'third cousin five-times-removed',
	'4,10' => 'third cousin six-times-removed',
	'5,0' => 'great-great-great-grandfather',
	'5,1' => 'great-great-great-uncle',
	'5,2' => 'first cousin three-times-removed',
	'5,3' => 'second cousin twice-removed',
	'5,4' => 'third cousin once-removed',
	'5,5' => 'fourth cousin',
	'5,6' => 'fourth cousin once-removed',
	'5,7' => 'fourth cousin twice-removed',
	'5,8' => 'fourth cousin three-times-removed',
	'5,9' => 'fourth cousin four-times-removed',
	'5,10' => 'fourth cousin five-times-removed',
	'6,0' => 'great-great-great-great-grandfather',
	'6,1' => 'great-great-great-great-uncle',
	'6,2' => 'first cousin four-times-removed',
	'6,3' => 'second cousin three-times-removed',
	'6,4' => 'third cousin twice-removed',
	'6,5' => 'fourth cousin once-removed',
	'6,6' => 'fifth cousin',
	'6,7' => 'fifth cousin once-removed',
	'6,8' => 'fifth cousin twice-removed',
	'6,9' => 'fifth cousin three-times-removed',
	'6,10' => 'fifth cousin four-times-removed',
	'7,0' => 'great-great-great-great-great-grandfather',
	'7,1' => 'great-great-great-great-great-uncle',
	'7,2' => 'first cousin five-times-removed',
	'7,3' => 'second cousin four-times-removed',
	'7,4' => 'third cousin three-times-removed',
	'7,5' => 'fourth cousin twice-removed',
	'7,6' => 'fifth cousin once-removed',
	'7,7' => 'sixth cousin',
	'7,8' => 'sixth cousin once-removed',
	'7,9' => 'sixth cousin twice-removed',
	'7,10' => 'sixth cousin three-times-removed',
	'8,0' => 'great-great-great-great-great-great-grandfather',
	'8,1' => 'great-great-great-great-great-great-uncle',
	'8,2' => 'first cousin six-times-removed',
	'8,3' => 'second cousin five-times-removed',
	'8,4' => 'third cousin four-times-removed',
	'8,5' => 'fourth cousin three-times-removed',
	'8,6' => 'fifth cousin twice-removed',
	'8,7' => 'sixth cousin once-removed',
	'8,8' => 'seventh cousin',
	'8,9' => 'seventh cousin once-removed',
	'8,10' => 'seventh cousin twice-removed',
	'9,0' => 'great-great-great-great-great-great-great-grandfather',
	'9,1' => 'great-great-great-great-great-great-great-uncle',
	'9,2' => 'first cousin seven-times-removed',
	'9,3' => 'second cousin six-times-removed',
	'9,4' => 'third cousin five-times-removed',
	'9,5' => 'fourth cousin four-times-removed',
	'9,6' => 'fifth cousin three-times-removed',
	'9,7' => 'sixth cousin twice-removed',
	'9,8' => 'seventh cousin once-removed',
	'9,9' => 'eighth cousin',
	'9,10' => 'eighth cousin once-removed',
	'10,0' => 'great-great-great-great-great-great-great-great-grandfather',
	'10,1' => 'great-great-great-great-great-great-great-great-uncle',
	'10,2' => 'first cousin eight-times-removed',
	'10,3' => 'second cousin seven-times-removed',
	'10,4' => 'third cousin six-times-removed',
	'10,5' => 'fourth cousin five-times-removed',
	'10,6' => 'fifth cousin four-times-removed',
	'10,7' => 'sixth cousin three-times-removed',
	'10,8' => 'seventh cousin twice-removed',
	'10,9' => 'eighth cousin once-removed',
	'10,10' => 'ninth cousin',
);

Readonly::Hash my %EN_FEMALE_RELATIONSHIPS => (
	'0,0' => 'self',
	'0,1' => 'daughter',
	'0,2' => 'granddaughter',
	'0,3' => 'great-granddaughter',
	'0,4' => 'great-great-granddaughter',
	'0,5' => 'great-great-great-granddaughter',
	'0,6' => 'great-great-great-great-granddaughter',
	'0,7' => 'great-great-great-great-great-granddaughter',
	'0,8' => 'great-great-great-great-great-great-granddaughter',
	'0,9' => 'great-great-great-great-great-great-great-granddaughter',
	'0,10' => 'great-great-great-great-great-great-great-great-granddaughter',
	'1,0' => 'mother',
	'1,1' => 'sister',
	'1,2' => 'niece',
	'1,3' => 'great-niece',
	'1,4' => 'great-great-niece',
	'1,5' => 'great-great-great-niece',
	'1,6' => 'great-great-great-great-niece',
	'1,7' => 'great-great-great-great-great-niece',
	'1,8' => 'great-great-great-great-great-great-niece',
	'1,9' => 'great-great-great-great-great-great-great-niece',
	'1,10' => 'great-great-great-great-great-great-great-great-niece',
	'2,0' => 'grandmother',
	'2,1' => 'aunt',
	'2,2' => 'first cousin',
	'2,3' => 'first cousin once-removed',
	'2,4' => 'first cousin twice-removed',
	'2,5' => 'first cousin three-times-removed',
	'2,6' => 'first cousin four-times-removed',
	'2,7' => 'first cousin five-times-removed',
	'2,8' => 'first cousin six-times-removed',
	'2,9' => 'first cousin seven-times-removed',
	'2,10' => 'first cousin eight-times-removed',
	'3,0' => 'great-grandmother',
	'3,1' => 'great-aunt',
	'3,2' => 'first cousin once-removed',
	'3,3' => 'second cousin',
	'3,4' => 'second cousin once-removed',
	'3,5' => 'second cousin twice-removed',
	'3,6' => 'second cousin three-times-removed',
	'3,7' => 'second cousin four-times-removed',
	'3,8' => 'second cousin five-times-removed',
	'3,9' => 'second cousin six-times-removed',
	'3,10' => 'second cousin seven-times-removed',
	'4,0' => 'great-great-grandmother',
	'4,1' => 'great-great-aunt',
	'4,2' => 'first cousin twice-removed',
	'4,3' => 'second cousin once-removed',
	'4,4' => 'third cousin',
	'4,5' => 'third cousin once-removed',
	'4,6' => 'third cousin twice-removed',
	'4,7' => 'third cousin three-times-removed',
	'4,8' => 'third cousin four-times-removed',
	'4,9' => 'third cousin five-times-removed',
	'4,10' => 'third cousin six-times-removed',
	'5,0' => 'great-great-great-grandmother',
	'5,1' => 'great-great-great-aunt',
	'5,2' => 'first cousin three-times-removed',
	'5,3' => 'second cousin twice-removed',
	'5,4' => 'third cousin once-removed',
	'5,5' => 'fourth cousin',
	'5,6' => 'fourth cousin once-removed',
	'5,7' => 'fourth cousin twice-removed',
	'5,8' => 'fourth cousin three-times-removed',
	'5,9' => 'fourth cousin four-times-removed',
	'5,10' => 'fourth cousin five-times-removed',
	'6,0' => 'great-great-great-great-grandmother',
	'6,1' => 'great-great-great-great-aunt',
	'6,2' => 'first cousin four-times-removed',
	'6,3' => 'second cousin three-times-removed',
	'6,4' => 'third cousin twice-removed',
	'6,5' => 'fourth cousin once-removed',
	'6,6' => 'fifth cousin',
	'6,7' => 'fifth cousin once-removed',
	'6,8' => 'fifth cousin twice-removed',
	'6,9' => 'fifth cousin three-times-removed',
	'6,10' => 'fifth cousin four-times-removed',
	'7,0' => 'great-great-great-great-great-grandmother',
	'7,1' => 'great-great-great-great-great-aunt',
	'7,2' => 'first cousin five-times-removed',
	'7,3' => 'second cousin four-times-removed',
	'7,4' => 'third cousin three-times-removed',
	'7,5' => 'fourth cousin twice-removed',
	'7,6' => 'fifth cousin once-removed',
	'7,7' => 'sixth cousin',
	'7,8' => 'sixth cousin once-removed',
	'7,9' => 'sixth cousin twice-removed',
	'7,10' => 'sixth cousin three-times-removed',
	'8,0' => 'great-great-great-great-great-great-grandmother',
	'8,1' => 'great-great-great-great-great-great-aunt',
	'8,2' => 'first cousin six-times-removed',
	'8,3' => 'second cousin five-times-removed',
	'8,4' => 'third cousin four-times-removed',
	'8,5' => 'fourth cousin three-times-removed',
	'8,6' => 'fifth cousin twice-removed',
	'8,7' => 'sixth cousin once-removed',
	'8,8' => 'seventh cousin',
	'8,9' => 'seventh cousin once-removed',
	'8,10' => 'seventh cousin twice-removed',
	'9,0' => 'great-great-great-great-great-great-great-grandmother',
	'9,1' => 'great-great-great-great-great-great-great-aunt',
	'9,2' => 'first cousin seven-times-removed',
	'9,3' => 'second cousin six-times-removed',
	'9,4' => 'third cousin five-times-removed',
	'9,5' => 'fourth cousin four-times-removed',
	'9,6' => 'fifth cousin three-times-removed',
	'9,7' => 'sixth cousin twice-removed',
	'9,8' => 'seventh cousin once-removed',
	'9,9' => 'eighth cousin',
	'9,10' => 'eighth cousin once-removed',
	'10,0' => 'great-great-great-great-great-great-great-great-grandmother',
	'10,1' => 'great-great-great-great-great-great-great-great-aunt',
	'10,2' => 'first cousin eight-times-removed',
	'10,3' => 'second cousin seven-times-removed',
	'10,4' => 'third cousin six-times-removed',
	'10,5' => 'fourth cousin five-times-removed',
	'10,6' => 'fifth cousin four-times-removed',
	'10,7' => 'sixth cousin three-times-removed',
	'10,8' => 'seventh cousin twice-removed',
	'10,9' => 'eighth cousin once-removed',
	'10,10' => 'ninth cousin',
);

# ---------------------------------------------------------------------------
# French relationship tables
# ---------------------------------------------------------------------------

Readonly::Hash my %FR_MALE_RELATIONSHIPS => (
	'0,0' => 'soi-meme',
	'0,1' => 'fils',
	'0,2' => 'petit-fils',
	'0,3' => 'arriere-petit-fils',
	'0,4' => 'arriere-arriere-petit-fils',
	'0,5' => 'arriere-arriere-arriere-petit-fils',
	'0,6' => 'arriere-arriere-arriere-arriere-petit-fils',
	'0,7' => 'arriere-arriere-arriere-arriere-arriere-petit-fils',
	'0,8' => 'arriere-arriere-arriere-arriere-arriere-arriere-petit-fils',
	'0,9' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-petit-fils',
	'0,10' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-arriere-petit-fils',
	'1,0' => 'pere',
	'1,1' => "fr\N{U+00E8}re",
	'1,2' => 'neveu',
	'1,3' => 'grand-neveu',
	'1,4' => 'arriere-grand-neveu',
	'1,5' => 'arriere-arriere-grand-neveu',
	'1,6' => 'arriere-arriere-arriere-grand-neveu',
	'1,7' => 'arriere-arriere-arriere-arriere-grand-neveu',
	'1,8' => 'arriere-arriere-arriere-arriere-arriere-grand-neveu',
	'1,9' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-neveu',
	'1,10' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-neveu',
	'2,0' => 'grand-pere',
	'2,1' => 'oncle',
	'2,2' => 'cousin germain',
	'2,3' => "cousin germain \N{U+00E9}loign\N{U+00E9} au 1er degr\N{U+00E9}",
	'2,4' => 'cousin germain deux fois eloigne',
	'2,5' => 'cousin germain trois fois eloigne',
	'2,6' => 'cousin germain quatre fois eloigne',
	'2,7' => 'cousin germain cinq fois eloigne',
	'2,8' => 'cousin germain six fois eloigne',
	'2,9' => 'cousin germain sept fois eloigne',
	'2,10' => 'cousin germain huit fois eloigne',
	'3,0' => 'arriere-grand-pere',
	'3,1' => 'grand-oncle',
	'3,2' => 'cousin germain une fois eloigne',
	'3,2' => "cousin germain \N{U+00E9}loign\N{U+00E9} au 1er degr\N{U+00E9}",
	'3,3' => 'cousin issu de germain',
	'3,4' => 'cousin issu de germain une fois eloigne',
	'3,5' => "cousin issu de germains \N{U+00E9}loign\N{U+00E9} au 2e degr\N{U+00E9}",
	'3,6' => 'cousin issu de germain trois fois eloigne',
	'3,7' => 'cousin issu de germain quatre fois eloigne',
	'3,8' => 'cousin issu de germain cinq fois eloigne',
	'3,9' => 'cousin issu de germain six fois eloigne',
	'3,10' => 'cousin issu de germain sept fois eloigne',
	'4,0' => 'arriere-arriere-grand-pere',
	'4,1' => 'arriere-grand-oncle',
	'4,2' => 'cousin germain deux fois eloigne',
	'4,3' => 'cousin issu de germain une fois eloigne',
	'4,4' => 'cousin au quatrieme degre',
	'4,5' => 'cousin au quatrieme degre une fois eloigne',
	'4,6' => 'cousin au quatrieme degre deux fois eloigne',
	'4,7' => "petit-cousin \N{U+00E9}loign\N{U+00E9} au 3e degr\N{U+00E9}",
	'4,8' => 'cousin au quatrieme degre quatre fois eloigne',
	'4,9' => 'cousin au quatrieme degre cinq fois eloigne',
	'4,10' => 'cousin au quatrieme degre six fois eloigne',
	'5,0' => 'arriere-arriere-arriere-grand-pere',
	'5,1' => 'arriere-arriere-grand-oncle',
	'5,2' => 'cousin germain trois fois eloigne',
	'5,3' => "cousin issu de germains \N{U+00E9}loign\N{U+00E9} au 2e degr\N{U+00E9}",
	'5,4' => 'cousin au quatrieme degre une fois eloigne',
	'5,5' => 'cousin au cinquieme degre',
	'5,6' => "arri\N{U+00E8}re-petit-cousin \N{U+00E9}loign\N{U+00E9} au 1er degr\N{U+00E9}",
	'5,7' => "arri\N{U+00E8}re-petit-cousin \N{U+00E9}loign\N{U+00E9} au 2e degr\N{U+00E9}",
	'5,8' => 'cousin au cinquieme degre trois fois eloigne',
	'5,9' => 'cousin au cinquieme degre quatre fois eloigne',
	'5,10' => 'cousin au cinquieme degre cinq fois eloigne',
	'6,0' => 'arriere-arriere-arriere-arriere-grand-pere',
	'6,1' => 'arriere-arriere-arriere-grand-oncle',
	'6,2' => 'cousin germain quatre fois eloigne',
	'6,3' => 'cousin issu de germain trois fois eloigne',
	'6,4' => 'cousin au quatrieme degre deux fois eloigne',
	'6,5' => "arri\N{U+00E8}re-petit-cousin \N{U+00E9}loign\N{U+00E9} au 1er degr\N{U+00E9}",
	'6,6' => "arri\N{U+00E8}re-arri\N{U+00E8}re-petit-cousin",
	'6,7' => 'cousin au sixieme degre une fois eloigne',
	'6,8' => 'cousin au sixieme degre deux fois eloigne',
	'6,9' => 'cousin au sixieme degre trois fois eloigne',
	'6,10' => 'cousin au sixieme degre quatre fois eloigne',
	'7,0' => 'arriere-arriere-arriere-arriere-arriere-grand-pere',
	'7,1' => 'arriere-arriere-arriere-arriere-grand-oncle',
	'7,2' => 'cousin germain cinq fois eloigne',
	'7,3' => 'cousin issu de germain quatre fois eloigne',
	'7,4' => "petit-cousin \N{U+00E9}loign\N{U+00E9} au 3e degr\N{U+00E9}",
	'7,5' => "arri\N{U+00E8}re-petit-cousin \N{U+00E9}loign\N{U+00E9} au 2e degr\N{U+00E9}",
	'7,6' => 'cousin au sixieme degre une fois eloigne',
	'7,7' => "sixi\N{U+00E8}me cousin",
	'7,8' => "sixi\N{U+00E8}me cousin uns fois eloinge",
	'7,9' => 'cousin au septieme degre deux fois eloigne',
	'7,10' => 'cousin au septieme degre trois fois eloigne',
	'8,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-pere',
	'8,1' => 'arriere-arriere-arriere-arriere-arriere-grand-oncle',
	'8,2' => 'cousin germain six fois eloigne',
	'8,3' => 'cousin issu de germain cinq fois eloigne',
	'8,4' => 'cousin au quatrieme degre quatre fois eloigne',
	'8,5' => 'cousin au cinquieme degre trois fois eloigne',
	'8,6' => 'cousin au sixieme degre deux fois eloigne',
	'8,7' => "sixi\N{U+00E8}me cousin uns fois eloinge",
	'8,8' => 'cousin au huitieme degre',
	'8,9' => 'cousin au huitieme degre une fois eloigne',
	'8,10' => 'cousin au huitieme degre deux fois eloigne',
	'9,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-pere',
	'9,1' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-oncle',
	'9,2' => 'cousin germain sept fois eloigne',
	'9,3' => 'cousin issu de germain six fois eloigne',
	'9,4' => 'cousin au quatrieme degre cinq fois eloigne',
	'9,5' => 'cousin au cinquieme degre quatre fois eloigne',
	'9,6' => 'cousin au sixieme degre trois fois eloigne',
	'9,7' => 'cousin au septieme degre deux fois eloigne',
	'9,8' => 'cousin au huitieme degre une fois eloigne',
	'9,9' => 'cousin au neuvieme degre',
	'9,10' => 'cousin au neuvieme degre une fois eloigne',
	'10,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-pere',
	'10,1' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-oncle',
	'10,2' => 'cousin germain huit fois eloigne',
	'10,3' => 'cousin issu de germain sept fois eloigne',
	'10,4' => 'cousin au quatrieme degre six fois eloigne',
	'10,5' => 'cousin au cinquieme degre cinq fois eloigne',
	'10,6' => 'cousin au sixieme degre quatre fois eloigne',
	'10,7' => 'cousin au septieme degre trois fois eloigne',
	'10,8' => 'cousin au huitieme degre deux fois eloigne',
	'10,9' => 'cousin au neuvieme degre une fois eloigne',
	'10,10' => 'cousin au dixieme degre',
);

Readonly::Hash my %FR_FEMALE_RELATIONSHIPS => (
	'0,0' => 'soi-meme',
	'0,1' => 'fille',
	'0,2' => 'petite-fille',
	'0,3' => 'arriere-petite-fille',
	'0,4' => 'arriere-arriere-petite-fille',
	'0,5' => 'arriere-arriere-arriere-petite-fille',
	'0,6' => 'arriere-arriere-arriere-arriere-petite-fille',
	'0,7' => 'arriere-arriere-arriere-arriere-arriere-petite-fille',
	'0,8' => 'arriere-arriere-arriere-arriere-arriere-arriere-petite-fille',
	'0,9' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-petite-fille',
	'0,10' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-arriere-petite-fille',
	'1,0' => 'mere',
	'1,1' => "s\N{U+0153}ur",
	'1,2' => "ni\N{U+00E8}ce",
	'1,3' => 'grand-niece',
	'1,4' => 'arriere-grand-niece',
	'1,5' => 'arriere-arriere-grand-niece',
	'1,6' => 'arriere-arriere-arriere-grand-niece',
	'1,7' => 'arriere-arriere-arriere-arriere-grand-niece',
	'1,8' => 'arriere-arriere-arriere-arriere-arriere-grand-niece',
	'1,9' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-niece',
	'1,10' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-niece',
	'2,0' => 'grand-mere',
	'2,1' => 'tante',
	'2,2' => 'cousine germaine',
	'2,3' => "cousine germaine \N{U+00E9}loign\N{U+00E9}e au 1er degr\N{U+00E9}",
	'2,4' => 'cousine germaine deux fois eloignee',
	'2,5' => 'cousine germaine trois fois eloignee',
	'2,6' => 'cousine germaine quatre fois eloignee',
	'2,7' => 'cousine germaine cinq fois eloignee',
	'2,8' => 'cousine germaine six fois eloignee',
	'2,9' => 'cousine germaine sept fois eloignee',
	'2,10' => 'cousine germaine huit fois eloignee',
	'3,0' => 'arriere-grand-mere',
	'3,1' => 'grand-tante',
	'3,2' => "cousine germaine \N{U+00E9}loign\N{U+00E9}e au 1er degr\N{U+00E9}",
	'3,3' => 'cousine issue de germaine',
	'3,4' => 'cousine issue de germaine une fois eloignee',
	'3,5' => "cousine issue de germains \N{U+00E9}loign\N{U+00E9}e au 2e degr\N{U+00E9}",
	'3,6' => 'cousine issue de germaine trois fois eloignee',
	'3,7' => 'cousine issue de germaine quatre fois eloignee',
	'3,8' => 'cousine issue de germaine cinq fois eloignee',
	'3,9' => 'cousine issue de germaine six fois eloignee',
	'3,10' => 'cousine issue de germaine sept fois eloignee',
	'4,0' => 'arriere-arriere-grand-mere',
	'4,1' => 'arriere-grand-tante',
	'4,2' => 'cousine germaine deux fois eloignee',
	'4,3' => 'cousine issue de germaine une fois eloignee',
	'4,4' => 'cousine au quatrieme degre',
	'4,5' => 'cousine au quatrieme degre une fois eloignee',
	'4,6' => 'cousine au quatrieme degre deux fois eloignee',
	'4,7' => "petite-cousine \N{U+00E9}loign\N{U+00E9}e au 3e degr\N{U+00E9}",
	'4,8' => 'cousine au quatrieme degre quatre fois eloignee',
	'4,9' => 'cousine au quatrieme degre cinq fois eloignee',
	'4,10' => 'cousine au quatrieme degre six fois eloignee',
	'5,0' => 'arriere-arriere-arriere-grand-mere',
	'5,1' => 'arriere-arriere-grand-tante',
	'5,2' => 'cousine germaine trois fois eloignee',
	'5,3' => "cousine issue de germains \N{U+00E9}loign\N{U+00E9}e au 2e degr\N{U+00E9}",
	'5,4' => 'cousine au quatrieme degre une fois eloignee',
	'5,5' => 'cousine au cinquieme degre',
	'5,6' => "arri\N{U+00E8}re-petite-cousine \N{U+00E9}loign\N{U+00E9}e au 1er degr\N{U+00E9}",
	'5,7' => "arri\N{U+00E8}re-petite-cousine \N{U+00E9}loign\N{U+00E9}e au 2e degr\N{U+00E9}",
	'5,8' => 'cousine au cinquieme degre trois fois eloignee',
	'5,9' => 'cousine au cinquieme degre quatre fois eloignee',
	'5,10' => 'cousine au cinquieme degre cinq fois eloignee',
	'6,0' => 'arriere-arriere-arriere-arriere-grand-mere',
	'6,1' => 'arriere-arriere-arriere-grand-tante',
	'6,2' => 'cousine germaine quatre fois eloignee',
	'6,3' => 'cousine issue de germaine trois fois eloignee',
	'6,4' => 'cousine au quatrieme degre deux fois eloignee',
	'6,6' => "arri\N{U+00E8}re-arri\N{U+00E8}re-petite-cousine",
	'6,6' => 'cousine au sixieme degre',
	'6,7' => 'cousine au sixieme degre une fois eloignee',
	'6,8' => 'cousine au sixieme degre deux fois eloignee',
	'6,9' => 'cousine au sixieme degre trois fois eloignee',
	'6,10' => 'cousine au sixieme degre quatre fois eloignee',
	'7,0' => 'arriere-arriere-arriere-arriere-arriere-grand-mere',
	'7,1' => 'arriere-arriere-arriere-arriere-grand-tante',
	'7,2' => 'cousine germaine cinq fois eloignee',
	'7,3' => 'cousine issue de germaine quatre fois eloignee',
	'7,4' => "petite-cousine \N{U+00E9}loign\N{U+00E9}e au 3e degr\N{U+00E9}",
	'7,5' => "arri\N{U+00E8}re-petite-cousine \N{U+00E9}loign\N{U+00E9}e au 2e degr\N{U+00E9}",
	'7,6' => 'cousine au sixieme degre une fois eloignee',
	'7,7' => "sixi\N{U+00E8}me cousin",
	'7,8' => "sixi\N{U+00E8}me cousin once-removed",
	'7,9' => 'cousine au septieme degre deux fois eloignee',
	'7,10' => 'cousine au septieme degre trois fois eloignee',
	'8,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-mere',
	'8,1' => 'arriere-arriere-arriere-arriere-arriere-grand-tante',
	'8,2' => 'cousine germaine six fois eloignee',
	'8,3' => 'cousine issue de germaine cinq fois eloignee',
	'8,4' => 'cousine au quatrieme degre quatre fois eloignee',
	'8,5' => 'cousine au cinquieme degre trois fois eloignee',
	'8,6' => 'cousine au sixieme degre deux fois eloignee',
	'8,7' => "sixi\N{U+00E8}me cousin once-removed",
	'8,8' => 'cousine au huitieme degre',
	'8,9' => 'cousine au huitieme degre une fois eloignee',
	'8,10' => 'cousine au huitieme degre deux fois eloignee',
	'9,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-mere',
	'9,1' => 'arriere-arriere-arriere-arriere-arriere-arriere-grand-tante',
	'9,2' => 'cousine germaine sept fois eloignee',
	'9,3' => 'cousine issue de germaine six fois eloignee',
	'9,4' => 'cousine au quatrieme degre cinq fois eloignee',
	'9,5' => 'cousine au cinquieme degre quatre fois eloignee',
	'9,6' => 'cousine au sixieme degre trois fois eloignee',
	'9,7' => 'cousine au septieme degre deux fois eloignee',
	'9,8' => 'cousine au huitieme degre une fois eloignee',
	'9,9' => 'cousine au neuvieme degre',
	'9,10' => 'cousine au neuvieme degre une fois eloignee',
	'10,0' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-mere',
	'10,1' => 'arriere-arriere-arriere-arriere-arriere-arriere-arriere-grand-tante',
	'10,2' => 'cousine germaine huit fois eloignee',
	'10,3' => 'cousine issue de germaine sept fois eloignee',
	'10,4' => 'cousine au quatrieme degre six fois eloignee',
	'10,5' => 'cousine au cinquieme degre cinq fois eloignee',
	'10,6' => 'cousine au sixieme degre quatre fois eloignee',
	'10,7' => 'cousine au septieme degre trois fois eloignee',
	'10,8' => 'cousine au huitieme degre deux fois eloignee',
	'10,9' => 'cousine au neuvieme degre une fois eloignee',
	'10,10' => 'cousine au dixieme degre',
);

# ---------------------------------------------------------------------------
# German relationship tables
# ---------------------------------------------------------------------------

Readonly::Hash my %DE_MALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Sohn',
	'0,2' => 'Enkel',
	'0,3' => 'Urenkel',
	'0,4' => 'Ururenkel',
	'0,5' => 'Urururenkel',
	'0,6' => 'Ururururenkel',
	'0,7' => 'Urururururenkel',
	'0,8' => 'Ururururururenkel',
	'0,9' => 'Urururururururenkel',
	'0,10' => 'Ururururururururenkel',
	'1,0' => 'Vater',
	'1,1' => 'Bruder',
	'1,2' => 'Neffe',
	'1,3' => "Gro\N{U+00DF}neffe",
	'1,4' => 'Urgrossneffe',
	'1,5' => 'Ururgrossneffe',
	'1,6' => 'Urururgrossneffe',
	'1,7' => 'Ururururgrossneffe',
	'1,8' => 'Urururururgrossneffe',
	'1,9' => 'Ururururururgrossneffe',
	'1,10' => 'Urururururururgrossneffe',
	'2,0' => "Gro\N{U+00DF}vater",
	'2,1' => 'Onkel',
	'2,2' => 'Cousin',
	'2,3' => 'Cousin einmal entfernt',
	'2,4' => 'Cousin zweimal entfernt',
	'2,5' => 'Cousin dreimal entfernt',
	'2,6' => 'Cousin viermal entfernt',
	'2,7' => 'Cousin fuenfmal entfernt',
	'2,8' => 'Cousin sechsmal entfernt',
	'2,9' => 'Cousin siebenmal entfernt',
	'2,10' => 'Cousin achtmal entfernt',
	'3,0' => 'Urgrossvater',
	'3,1' => "Gro\N{U+00DF}onkel",
	'3,2' => 'Cousin einmal entfernt',
	'3,3' => 'Cousin zweiten Grades',
	'3,4' => 'Cousin zweiten Grades einmal entfernt',
	'3,5' => 'Cousin zweiten Grades zweimal entfernt',
	'3,6' => 'Cousin zweiten Grades dreimal entfernt',
	'3,7' => 'Cousin zweiten Grades viermal entfernt',
	'3,8' => 'Cousin zweiten Grades fuenfmal entfernt',
	'3,9' => 'Cousin zweiten Grades sechsmal entfernt',
	'3,10' => 'Cousin zweiten Grades siebenmal entfernt',
	'4,0' => 'Ururgrossvater',
	'4,1' => 'Urgrossonkel',
	'4,2' => 'Cousin zweimal entfernt',
	'4,3' => 'Cousin zweiten Grades einmal entfernt',
	'4,4' => 'Cousin dritten Grades',
	'4,5' => 'Cousin dritten Grades einmal entfernt',
	'4,6' => 'Cousin dritten Grades zweimal entfernt',
	'4,7' => 'Cousin dritten Grades dreimal entfernt',
	'4,8' => 'Cousin dritten Grades viermal entfernt',
	'4,9' => 'Cousin dritten Grades fuenfmal entfernt',
	'4,10' => 'Cousin dritten Grades sechsmal entfernt',
	'5,0' => 'Urururgrossvater',
	'5,1' => 'Ururgrossonkel',
	'5,2' => 'Cousin dreimal entfernt',
	'5,3' => 'Cousin zweiten Grades zweimal entfernt',
	'5,4' => 'Cousin dritten Grades einmal entfernt',
	'5,5' => 'Cousin vierten Grades',
	'5,6' => 'Cousin vierten Grades einmal entfernt',
	'5,7' => 'Cousin vierten Grades zweimal entfernt',
	'5,8' => 'Cousin vierten Grades dreimal entfernt',
	'5,9' => 'Cousin vierten Grades viermal entfernt',
	'5,10' => 'Cousin vierten Grades fuenfmal entfernt',
	'6,0' => 'Ururururgrossvater',
	'6,1' => 'Urururgrossonkel',
	'6,2' => 'Cousin viermal entfernt',
	'6,3' => 'Cousin zweiten Grades dreimal entfernt',
	'6,4' => 'Cousin dritten Grades zweimal entfernt',
	'6,5' => 'Cousin vierten Grades einmal entfernt',
	'6,6' => 'Cousin fuenften Grades',
	'6,7' => 'Cousin fuenften Grades einmal entfernt',
	'6,8' => 'Cousin fuenften Grades zweimal entfernt',
	'6,9' => 'Cousin fuenften Grades dreimal entfernt',
	'6,10' => 'Cousin fuenften Grades viermal entfernt',
	'7,0' => 'Urururururgrossvater',
	'7,1' => 'Ururururgrossonkel',
	'7,2' => 'Cousin fuenfmal entfernt',
	'7,3' => 'Cousin zweiten Grades viermal entfernt',
	'7,4' => 'Cousin dritten Grades dreimal entfernt',
	'7,5' => 'Cousin vierten Grades zweimal entfernt',
	'7,6' => 'Cousin fuenften Grades einmal entfernt',
	'7,7' => 'Cousin sechsten Grades',
	'7,8' => 'Cousin sechsten Grades einmal entfernt',
	'7,9' => 'Cousin sechsten Grades zweimal entfernt',
	'7,10' => 'Cousin sechsten Grades dreimal entfernt',
	'8,0' => 'Ururururururgrossvater',
	'8,1' => 'Urururururgrossonkel',
	'8,2' => 'Cousin sechsmal entfernt',
	'8,3' => 'Cousin zweiten Grades fuenfmal entfernt',
	'8,4' => 'Cousin dritten Grades viermal entfernt',
	'8,5' => 'Cousin vierten Grades dreimal entfernt',
	'8,6' => 'Cousin fuenften Grades zweimal entfernt',
	'8,7' => 'Cousin sechsten Grades einmal entfernt',
	'8,8' => 'Cousin siebten Grades',
	'8,9' => 'Cousin siebten Grades einmal entfernt',
	'8,10' => 'Cousin siebten Grades zweimal entfernt',
	'9,0' => 'Urururururururgrossvater',
	'9,1' => 'Ururururururgrossonkel',
	'9,2' => 'Cousin siebenmal entfernt',
	'9,3' => 'Cousin zweiten Grades sechsmal entfernt',
	'9,4' => 'Cousin dritten Grades fuenfmal entfernt',
	'9,5' => 'Cousin vierten Grades viermal entfernt',
	'9,6' => 'Cousin fuenften Grades dreimal entfernt',
	'9,7' => 'Cousin sechsten Grades zweimal entfernt',
	'9,8' => 'Cousin siebten Grades einmal entfernt',
	'9,9' => 'Cousin achten Grades',
	'9,10' => 'Cousin achten Grades einmal entfernt',
	'10,0' => 'Ururururururururgrossvater',
	'10,1' => 'Urururururururgrossonkel',
	'10,2' => 'Cousin achtmal entfernt',
	'10,3' => 'Cousin zweiten Grades siebenmal entfernt',
	'10,4' => 'Cousin dritten Grades sechsmal entfernt',
	'10,5' => 'Cousin vierten Grades fuenfmal entfernt',
	'10,6' => 'Cousin fuenften Grades viermal entfernt',
	'10,7' => 'Cousin sechsten Grades dreimal entfernt',
	'10,8' => 'Cousin siebten Grades zweimal entfernt',
	'10,9' => 'Cousin achten Grades einmal entfernt',
	'10,10' => 'Cousin neunten Grades',
);

Readonly::Hash my %DE_FEMALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Tochter',
	'0,2' => 'Enkelin',
	'0,3' => 'Urenkelin',
	'0,4' => 'Ururenkelin',
	'0,5' => 'Urururenkelin',
	'0,6' => 'Ururururenkelin',
	'0,7' => 'Urururururenkelin',
	'0,8' => 'Ururururururenkelin',
	'0,9' => 'Urururururururenkelin',
	'0,10' => 'Ururururururururenkelin',
	'1,0' => 'Mutter',
	'1,1' => 'Schwester',
	'1,2' => 'Nichte',
	'1,3' => "Gro\N{U+00DF}nichte",
	'1,4' => 'Urgrossnichte',
	'1,5' => 'Ururgrossnichte',
	'1,6' => 'Urururgrossnichte',
	'1,7' => 'Ururururgrossnichte',
	'1,8' => 'Urururururgrossnichte',
	'1,9' => 'Ururururururgrossnichte',
	'1,10' => 'Urururururururgrossnichte',
	'2,0' => "Gro\N{U+00DF}mutter",
	'2,1' => 'Tante',
	'2,2' => 'Cousine',
	'2,3' => 'Cousine einmal entfernt',
	'2,4' => 'Cousine zweimal entfernt',
	'2,5' => 'Cousine dreimal entfernt',
	'2,6' => 'Cousine viermal entfernt',
	'2,7' => 'Cousine fuenfmal entfernt',
	'2,8' => 'Cousine sechsmal entfernt',
	'2,9' => 'Cousine siebenmal entfernt',
	'2,10' => 'Cousine achtmal entfernt',
	'3,0' => 'Urgrossmutter',
	'3,1' => "Gro\N{U+00DF}tante",
	'3,2' => 'Cousine einmal entfernt',
	'3,3' => 'Cousine zweiten Grades',
	'3,4' => 'Cousine zweiten Grades einmal entfernt',
	'3,5' => 'Cousine zweiten Grades zweimal entfernt',
	'3,6' => 'Cousine zweiten Grades dreimal entfernt',
	'3,7' => 'Cousine zweiten Grades viermal entfernt',
	'3,8' => 'Cousine zweiten Grades fuenfmal entfernt',
	'3,9' => 'Cousine zweiten Grades sechsmal entfernt',
	'3,10' => 'Cousine zweiten Grades siebenmal entfernt',
	'4,0' => 'Ururgrossmutter',
	'4,1' => 'Urgrosstante',
	'4,2' => 'Cousine zweimal entfernt',
	'4,3' => 'Cousine zweiten Grades einmal entfernt',
	'4,4' => 'Cousine dritten Grades',
	'4,5' => 'Cousine dritten Grades einmal entfernt',
	'4,6' => 'Cousine dritten Grades zweimal entfernt',
	'4,7' => 'Cousine dritten Grades dreimal entfernt',
	'4,8' => 'Cousine dritten Grades viermal entfernt',
	'4,9' => 'Cousine dritten Grades fuenfmal entfernt',
	'4,10' => 'Cousine dritten Grades sechsmal entfernt',
	'5,0' => 'Urururgrossmutter',
	'5,1' => 'Ururgrosstante',
	'5,2' => 'Cousine dreimal entfernt',
	'5,3' => 'Cousine zweiten Grades zweimal entfernt',
	'5,4' => 'Cousine dritten Grades einmal entfernt',
	'5,5' => 'Cousine vierten Grades',
	'5,6' => 'Cousine vierten Grades einmal entfernt',
	'5,7' => 'Cousine vierten Grades zweimal entfernt',
	'5,8' => 'Cousine vierten Grades dreimal entfernt',
	'5,9' => 'Cousine vierten Grades viermal entfernt',
	'5,10' => 'Cousine vierten Grades fuenfmal entfernt',
	'6,0' => 'Ururururgrossmutter',
	'6,1' => 'Urururgrosstante',
	'6,2' => 'Cousine viermal entfernt',
	'6,3' => 'Cousine zweiten Grades dreimal entfernt',
	'6,4' => 'Cousine dritten Grades zweimal entfernt',
	'6,5' => 'Cousine vierten Grades einmal entfernt',
	'6,6' => 'Cousine fuenften Grades',
	'6,7' => 'Cousine fuenften Grades einmal entfernt',
	'6,8' => 'Cousine fuenften Grades zweimal entfernt',
	'6,9' => 'Cousine fuenften Grades dreimal entfernt',
	'6,10' => 'Cousine fuenften Grades viermal entfernt',
	'7,0' => 'Urururururgrossmutter',
	'7,1' => 'Ururururgrosstante',
	'7,2' => 'Cousine fuenfmal entfernt',
	'7,3' => 'Cousine zweiten Grades viermal entfernt',
	'7,4' => 'Cousine dritten Grades dreimal entfernt',
	'7,5' => 'Cousine vierten Grades zweimal entfernt',
	'7,6' => 'Cousine fuenften Grades einmal entfernt',
	'7,7' => 'Cousine sechsten Grades',
	'7,8' => 'Cousine sechsten Grades einmal entfernt',
	'7,9' => 'Cousine sechsten Grades zweimal entfernt',
	'7,10' => 'Cousine sechsten Grades dreimal entfernt',
	'8,0' => 'Ururururururgrossmutter',
	'8,1' => 'Urururururgrosstante',
	'8,2' => 'Cousine sechsmal entfernt',
	'8,3' => 'Cousine zweiten Grades fuenfmal entfernt',
	'8,4' => 'Cousine dritten Grades viermal entfernt',
	'8,5' => 'Cousine vierten Grades dreimal entfernt',
	'8,6' => 'Cousine fuenften Grades zweimal entfernt',
	'8,7' => 'Cousine sechsten Grades einmal entfernt',
	'8,8' => 'Cousine siebten Grades',
	'8,9' => 'Cousine siebten Grades einmal entfernt',
	'8,10' => 'Cousine siebten Grades zweimal entfernt',
	'9,0' => 'Urururururururgrossmutter',
	'9,1' => 'Ururururururgrosstante',
	'9,2' => 'Cousine siebenmal entfernt',
	'9,3' => 'Cousine zweiten Grades sechsmal entfernt',
	'9,4' => 'Cousine dritten Grades fuenfmal entfernt',
	'9,5' => 'Cousine vierten Grades viermal entfernt',
	'9,6' => 'Cousine fuenften Grades dreimal entfernt',
	'9,7' => 'Cousine sechsten Grades zweimal entfernt',
	'9,8' => 'Cousine siebten Grades einmal entfernt',
	'9,9' => 'Cousine achten Grades',
	'9,10' => 'Cousine achten Grades einmal entfernt',
	'10,0' => 'Ururururururururgrossmutter',
	'10,1' => 'Urururururururgrosstante',
	'10,2' => 'Cousine achtmal entfernt',
	'10,3' => 'Cousine zweiten Grades siebenmal entfernt',
	'10,4' => 'Cousine dritten Grades sechsmal entfernt',
	'10,5' => 'Cousine vierten Grades fuenfmal entfernt',
	'10,6' => 'Cousine fuenften Grades viermal entfernt',
	'10,7' => 'Cousine sechsten Grades dreimal entfernt',
	'10,8' => 'Cousine siebten Grades zweimal entfernt',
	'10,9' => 'Cousine achten Grades einmal entfernt',
	'10,10' => 'Cousine neunten Grades',
);

# ---------------------------------------------------------------------------
# Swiss German (de-CH) relationship tables
# Uses 'ss' instead of Eszett (\N{U+00DF}); Switzerland abolished ß in 1934
# ---------------------------------------------------------------------------

Readonly::Hash my %DE_CH_MALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Sohn',
	'0,2' => 'Enkel',
	'0,3' => 'Urenkel',
	'0,4' => 'Ururenkel',
	'0,5' => 'Urururenkel',
	'0,6' => 'Ururururenkel',
	'0,7' => 'Urururururenkel',
	'0,8' => 'Ururururururenkel',
	'0,9' => 'Urururururururenkel',
	'0,10' => 'Ururururururururenkel',
	'1,0' => 'Vater',
	'1,1' => 'Bruder',
	'1,2' => 'Neffe',
	'1,3' => 'Grossneffe',
	'1,4' => 'Urgrossneffe',
	'1,5' => 'Ururgrossneffe',
	'1,6' => 'Urururgrossneffe',
	'1,7' => 'Ururururgrossneffe',
	'1,8' => 'Urururururgrossneffe',
	'1,9' => 'Ururururururgrossneffe',
	'1,10' => 'Urururururururgrossneffe',
	'2,0' => 'Grossvater',
	'2,1' => 'Onkel',
	'2,2' => 'Cousin',
	'2,3' => 'Cousin einmal entfernt',
	'2,4' => 'Cousin zweimal entfernt',
	'2,5' => 'Cousin dreimal entfernt',
	'2,6' => 'Cousin viermal entfernt',
	'2,7' => 'Cousin fuenfmal entfernt',
	'2,8' => 'Cousin sechsmal entfernt',
	'2,9' => 'Cousin siebenmal entfernt',
	'2,10' => 'Cousin achtmal entfernt',
	'3,0' => 'Urgrossvater',
	'3,1' => 'Grossonkel',
	'3,2' => 'Cousin einmal entfernt',
	'3,3' => 'Cousin zweiten Grades',
	'3,4' => 'Cousin zweiten Grades einmal entfernt',
	'3,5' => 'Cousin zweiten Grades zweimal entfernt',
	'3,6' => 'Cousin zweiten Grades dreimal entfernt',
	'3,7' => 'Cousin zweiten Grades viermal entfernt',
	'3,8' => 'Cousin zweiten Grades fuenfmal entfernt',
	'3,9' => 'Cousin zweiten Grades sechsmal entfernt',
	'3,10' => 'Cousin zweiten Grades siebenmal entfernt',
	'4,0' => 'Ururgrossvater',
	'4,1' => 'Urgrossonkel',
	'4,2' => 'Cousin zweimal entfernt',
	'4,3' => 'Cousin zweiten Grades einmal entfernt',
	'4,4' => 'Cousin dritten Grades',
	'4,5' => 'Cousin dritten Grades einmal entfernt',
	'4,6' => 'Cousin dritten Grades zweimal entfernt',
	'4,7' => 'Cousin dritten Grades dreimal entfernt',
	'4,8' => 'Cousin dritten Grades viermal entfernt',
	'4,9' => 'Cousin dritten Grades fuenfmal entfernt',
	'4,10' => 'Cousin dritten Grades sechsmal entfernt',
	'5,0' => 'Urururgrossvater',
	'5,1' => 'Ururgrossonkel',
	'5,2' => 'Cousin dreimal entfernt',
	'5,3' => 'Cousin zweiten Grades zweimal entfernt',
	'5,4' => 'Cousin dritten Grades einmal entfernt',
	'5,5' => 'Cousin vierten Grades',
	'5,6' => 'Cousin vierten Grades einmal entfernt',
	'5,7' => 'Cousin vierten Grades zweimal entfernt',
	'5,8' => 'Cousin vierten Grades dreimal entfernt',
	'5,9' => 'Cousin vierten Grades viermal entfernt',
	'5,10' => 'Cousin vierten Grades fuenfmal entfernt',
	'6,0' => 'Ururururgrossvater',
	'6,1' => 'Urururgrossonkel',
	'6,2' => 'Cousin viermal entfernt',
	'6,3' => 'Cousin zweiten Grades dreimal entfernt',
	'6,4' => 'Cousin dritten Grades zweimal entfernt',
	'6,5' => 'Cousin vierten Grades einmal entfernt',
	'6,6' => 'Cousin fuenften Grades',
	'6,7' => 'Cousin fuenften Grades einmal entfernt',
	'6,8' => 'Cousin fuenften Grades zweimal entfernt',
	'6,9' => 'Cousin fuenften Grades dreimal entfernt',
	'6,10' => 'Cousin fuenften Grades viermal entfernt',
	'7,0' => 'Urururururgrossvater',
	'7,1' => 'Ururururgrossonkel',
	'7,2' => 'Cousin fuenfmal entfernt',
	'7,3' => 'Cousin zweiten Grades viermal entfernt',
	'7,4' => 'Cousin dritten Grades dreimal entfernt',
	'7,5' => 'Cousin vierten Grades zweimal entfernt',
	'7,6' => 'Cousin fuenften Grades einmal entfernt',
	'7,7' => 'Cousin sechsten Grades',
	'7,8' => 'Cousin sechsten Grades einmal entfernt',
	'7,9' => 'Cousin sechsten Grades zweimal entfernt',
	'7,10' => 'Cousin sechsten Grades dreimal entfernt',
	'8,0' => 'Ururururururgrossvater',
	'8,1' => 'Urururururgrossonkel',
	'8,2' => 'Cousin sechsmal entfernt',
	'8,3' => 'Cousin zweiten Grades fuenfmal entfernt',
	'8,4' => 'Cousin dritten Grades viermal entfernt',
	'8,5' => 'Cousin vierten Grades dreimal entfernt',
	'8,6' => 'Cousin fuenften Grades zweimal entfernt',
	'8,7' => 'Cousin sechsten Grades einmal entfernt',
	'8,8' => 'Cousin siebten Grades',
	'8,9' => 'Cousin siebten Grades einmal entfernt',
	'8,10' => 'Cousin siebten Grades zweimal entfernt',
	'9,0' => 'Urururururururgrossvater',
	'9,1' => 'Ururururururgrossonkel',
	'9,2' => 'Cousin siebenmal entfernt',
	'9,3' => 'Cousin zweiten Grades sechsmal entfernt',
	'9,4' => 'Cousin dritten Grades fuenfmal entfernt',
	'9,5' => 'Cousin vierten Grades viermal entfernt',
	'9,6' => 'Cousin fuenften Grades dreimal entfernt',
	'9,7' => 'Cousin sechsten Grades zweimal entfernt',
	'9,8' => 'Cousin siebten Grades einmal entfernt',
	'9,9' => 'Cousin achten Grades',
	'9,10' => 'Cousin achten Grades einmal entfernt',
	'10,0' => 'Ururururururururgrossvater',
	'10,1' => 'Urururururururgrossonkel',
	'10,2' => 'Cousin achtmal entfernt',
	'10,3' => 'Cousin zweiten Grades siebenmal entfernt',
	'10,4' => 'Cousin dritten Grades sechsmal entfernt',
	'10,5' => 'Cousin vierten Grades fuenfmal entfernt',
	'10,6' => 'Cousin fuenften Grades viermal entfernt',
	'10,7' => 'Cousin sechsten Grades dreimal entfernt',
	'10,8' => 'Cousin siebten Grades zweimal entfernt',
	'10,9' => 'Cousin achten Grades einmal entfernt',
	'10,10' => 'Cousin neunten Grades',
);

Readonly::Hash my %DE_CH_FEMALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Tochter',
	'0,2' => 'Enkelin',
	'0,3' => 'Urenkelin',
	'0,4' => 'Ururenkelin',
	'0,5' => 'Urururenkelin',
	'0,6' => 'Ururururenkelin',
	'0,7' => 'Urururururenkelin',
	'0,8' => 'Ururururururenkelin',
	'0,9' => 'Urururururururenkelin',
	'0,10' => 'Ururururururururenkelin',
	'1,0' => 'Mutter',
	'1,1' => 'Schwester',
	'1,2' => 'Nichte',
	'1,3' => 'Grossnichte',
	'1,4' => 'Urgrossnichte',
	'1,5' => 'Ururgrossnichte',
	'1,6' => 'Urururgrossnichte',
	'1,7' => 'Ururururgrossnichte',
	'1,8' => 'Urururururgrossnichte',
	'1,9' => 'Ururururururgrossnichte',
	'1,10' => 'Urururururururgrossnichte',
	'2,0' => 'Grossmutter',
	'2,1' => 'Tante',
	'2,2' => 'Cousine',
	'2,3' => 'Cousine einmal entfernt',
	'2,4' => 'Cousine zweimal entfernt',
	'2,5' => 'Cousine dreimal entfernt',
	'2,6' => 'Cousine viermal entfernt',
	'2,7' => 'Cousine fuenfmal entfernt',
	'2,8' => 'Cousine sechsmal entfernt',
	'2,9' => 'Cousine siebenmal entfernt',
	'2,10' => 'Cousine achtmal entfernt',
	'3,0' => 'Urgrossmutter',
	'3,1' => 'Grosstante',
	'3,2' => 'Cousine einmal entfernt',
	'3,3' => 'Cousine zweiten Grades',
	'3,4' => 'Cousine zweiten Grades einmal entfernt',
	'3,5' => 'Cousine zweiten Grades zweimal entfernt',
	'3,6' => 'Cousine zweiten Grades dreimal entfernt',
	'3,7' => 'Cousine zweiten Grades viermal entfernt',
	'3,8' => 'Cousine zweiten Grades fuenfmal entfernt',
	'3,9' => 'Cousine zweiten Grades sechsmal entfernt',
	'3,10' => 'Cousine zweiten Grades siebenmal entfernt',
	'4,0' => 'Ururgrossmutter',
	'4,1' => 'Urgrosstante',
	'4,2' => 'Cousine zweimal entfernt',
	'4,3' => 'Cousine zweiten Grades einmal entfernt',
	'4,4' => 'Cousine dritten Grades',
	'4,5' => 'Cousine dritten Grades einmal entfernt',
	'4,6' => 'Cousine dritten Grades zweimal entfernt',
	'4,7' => 'Cousine dritten Grades dreimal entfernt',
	'4,8' => 'Cousine dritten Grades viermal entfernt',
	'4,9' => 'Cousine dritten Grades fuenfmal entfernt',
	'4,10' => 'Cousine dritten Grades sechsmal entfernt',
	'5,0' => 'Urururgrossmutter',
	'5,1' => 'Ururgrosstante',
	'5,2' => 'Cousine dreimal entfernt',
	'5,3' => 'Cousine zweiten Grades zweimal entfernt',
	'5,4' => 'Cousine dritten Grades einmal entfernt',
	'5,5' => 'Cousine vierten Grades',
	'5,6' => 'Cousine vierten Grades einmal entfernt',
	'5,7' => 'Cousine vierten Grades zweimal entfernt',
	'5,8' => 'Cousine vierten Grades dreimal entfernt',
	'5,9' => 'Cousine vierten Grades viermal entfernt',
	'5,10' => 'Cousine vierten Grades fuenfmal entfernt',
	'6,0' => 'Ururururgrossmutter',
	'6,1' => 'Urururgrosstante',
	'6,2' => 'Cousine viermal entfernt',
	'6,3' => 'Cousine zweiten Grades dreimal entfernt',
	'6,4' => 'Cousine dritten Grades zweimal entfernt',
	'6,5' => 'Cousine vierten Grades einmal entfernt',
	'6,6' => 'Cousine fuenften Grades',
	'6,7' => 'Cousine fuenften Grades einmal entfernt',
	'6,8' => 'Cousine fuenften Grades zweimal entfernt',
	'6,9' => 'Cousine fuenften Grades dreimal entfernt',
	'6,10' => 'Cousine fuenften Grades viermal entfernt',
	'7,0' => 'Urururururgrossmutter',
	'7,1' => 'Ururururgrosstante',
	'7,2' => 'Cousine fuenfmal entfernt',
	'7,3' => 'Cousine zweiten Grades viermal entfernt',
	'7,4' => 'Cousine dritten Grades dreimal entfernt',
	'7,5' => 'Cousine vierten Grades zweimal entfernt',
	'7,6' => 'Cousine fuenften Grades einmal entfernt',
	'7,7' => 'Cousine sechsten Grades',
	'7,8' => 'Cousine sechsten Grades einmal entfernt',
	'7,9' => 'Cousine sechsten Grades zweimal entfernt',
	'7,10' => 'Cousine sechsten Grades dreimal entfernt',
	'8,0' => 'Ururururururgrossmutter',
	'8,1' => 'Urururururgrosstante',
	'8,2' => 'Cousine sechsmal entfernt',
	'8,3' => 'Cousine zweiten Grades fuenfmal entfernt',
	'8,4' => 'Cousine dritten Grades viermal entfernt',
	'8,5' => 'Cousine vierten Grades dreimal entfernt',
	'8,6' => 'Cousine fuenften Grades zweimal entfernt',
	'8,7' => 'Cousine sechsten Grades einmal entfernt',
	'8,8' => 'Cousine siebten Grades',
	'8,9' => 'Cousine siebten Grades einmal entfernt',
	'8,10' => 'Cousine siebten Grades zweimal entfernt',
	'9,0' => 'Urururururururgrossmutter',
	'9,1' => 'Ururururururgrosstante',
	'9,2' => 'Cousine siebenmal entfernt',
	'9,3' => 'Cousine zweiten Grades sechsmal entfernt',
	'9,4' => 'Cousine dritten Grades fuenfmal entfernt',
	'9,5' => 'Cousine vierten Grades viermal entfernt',
	'9,6' => 'Cousine fuenften Grades dreimal entfernt',
	'9,7' => 'Cousine sechsten Grades zweimal entfernt',
	'9,8' => 'Cousine siebten Grades einmal entfernt',
	'9,9' => 'Cousine achten Grades',
	'9,10' => 'Cousine achten Grades einmal entfernt',
	'10,0' => 'Ururururururururgrossmutter',
	'10,1' => 'Urururururururgrosstante',
	'10,2' => 'Cousine achtmal entfernt',
	'10,3' => 'Cousine zweiten Grades siebenmal entfernt',
	'10,4' => 'Cousine dritten Grades sechsmal entfernt',
	'10,5' => 'Cousine vierten Grades fuenfmal entfernt',
	'10,6' => 'Cousine fuenften Grades viermal entfernt',
	'10,7' => 'Cousine sechsten Grades dreimal entfernt',
	'10,8' => 'Cousine siebten Grades zweimal entfernt',
	'10,9' => 'Cousine achten Grades einmal entfernt',
	'10,10' => 'Cousine neunten Grades',
);

# ---------------------------------------------------------------------------
# Spanish relationship tables
# ---------------------------------------------------------------------------

Readonly::Hash my %ES_MALE_RELATIONSHIPS => (
	'0,0' => 'uno mismo',
	'0,1' => 'hijo',
	'0,2' => 'nieto',
	'0,3' => 'bisnieto',
	'0,4' => 'tataranieto',
	'0,5' => 'chozno',
	'0,6' => 'bisnieto quinto',
	'0,7' => 'descendiente lejano',
	'0,8' => 'descendiente lejano',
	'0,9' => 'descendiente lejano',
	'0,10' => 'descendiente lejano',
	'1,0' => 'padre',
	'1,1' => 'hermano',
	'1,2' => 'sobrino',
	'1,3' => 'sobrino nieto',
	'1,4' => 'sobrino bisnieto',
	'1,5' => 'sobrino tataranieto',
	'1,6' => 'sobrino lejano',
	'1,7' => 'sobrino lejano',
	'1,8' => 'sobrino lejano',
	'1,9' => 'sobrino lejano',
	'1,10' => 'sobrino lejano',
	'2,0' => 'abuelo',
	'2,1' => 'tio',
	'2,2' => 'primo hermano',
	'2,3' => 'primo hermano una vez removido',
	'2,4' => 'primo hermano dos veces removido',
	'2,5' => 'primo hermano tres veces removido',
	'2,6' => 'primo hermano cuatro veces removido',
	'2,7' => 'primo hermano cinco veces removido',
	'2,8' => 'primo hermano seis veces removido',
	'2,9' => 'primo hermano siete veces removido',
	'2,10' => 'primo hermano ocho veces removido',
	'3,0' => 'bisabuelo',
	'3,1' => 'tio abuelo',
	'3,2' => 'primo hermano una vez removido',
	'3,3' => 'primo segundo',
	'3,4' => 'primo segundo una vez removido',
	'3,5' => 'primo segundo dos veces removido',
	'3,6' => 'primo segundo tres veces removido',
	'3,7' => 'primo segundo cuatro veces removido',
	'3,8' => 'primo segundo cinco veces removido',
	'3,9' => 'primo segundo seis veces removido',
	'3,10' => 'primo segundo siete veces removido',
	'4,0' => 'tatarabuelo',
	'4,1' => 'tio bisabuelo',
	'4,2' => 'primo hermano dos veces removido',
	'4,3' => 'primo segundo una vez removido',
	'4,4' => 'primo tercero',
	'4,5' => 'primo tercero una vez removido',
	'4,6' => 'primo tercero dos veces removido',
	'4,7' => 'primo tercero tres veces removido',
	'4,8' => 'primo tercero cuatro veces removido',
	'4,9' => 'primo tercero cinco veces removido',
	'4,10' => 'primo tercero seis veces removido',
	'5,0' => 'chozno',
	'5,1' => 'tio tatarabuelo',
	'5,2' => 'primo hermano tres veces removido',
	'5,3' => 'primo segundo dos veces removido',
	'5,4' => 'primo tercero una vez removido',
	'5,5' => 'primo cuarto',
	'5,6' => 'primo cuarto una vez removido',
	'5,7' => 'primo cuarto dos veces removido',
	'5,8' => 'primo cuarto tres veces removido',
	'5,9' => 'primo cuarto cuatro veces removido',
	'5,10' => 'primo cuarto cinco veces removido',
	'6,0' => 'bisabuelo quinto',
	'6,1' => 'tio lejano',
	'6,2' => 'primo hermano cuatro veces removido',
	'6,3' => 'primo segundo tres veces removido',
	'6,4' => 'primo tercero dos veces removido',
	'6,5' => 'primo cuarto una vez removido',
	'6,6' => 'primo quinto',
	'6,7' => 'primo quinto una vez removido',
	'6,8' => 'primo quinto dos veces removido',
	'6,9' => 'primo quinto tres veces removido',
	'6,10' => 'primo quinto cuatro veces removido',
	'7,0' => 'antepasado lejano',
	'7,1' => 'tio lejano',
	'7,2' => 'primo hermano cinco veces removido',
	'7,3' => 'primo segundo cuatro veces removido',
	'7,4' => 'primo tercero tres veces removido',
	'7,5' => 'primo cuarto dos veces removido',
	'7,6' => 'primo quinto una vez removido',
	'7,7' => 'primo sexto',
	'7,8' => 'primo sexto una vez removido',
	'7,9' => 'primo sexto dos veces removido',
	'7,10' => 'primo sexto tres veces removido',
	'8,0' => 'antepasado lejano',
	'8,1' => 'tio lejano',
	'8,2' => 'primo hermano seis veces removido',
	'8,3' => 'primo segundo cinco veces removido',
	'8,4' => 'primo tercero cuatro veces removido',
	'8,5' => 'primo cuarto tres veces removido',
	'8,6' => 'primo quinto dos veces removido',
	'8,7' => 'primo sexto una vez removido',
	'8,8' => 'primo septimo',
	'8,9' => 'primo septimo una vez removido',
	'8,10' => 'primo septimo dos veces removido',
	'9,0' => 'antepasado lejano',
	'9,1' => 'tio lejano',
	'9,2' => 'primo hermano siete veces removido',
	'9,3' => 'primo segundo seis veces removido',
	'9,4' => 'primo tercero cinco veces removido',
	'9,5' => 'primo cuarto cuatro veces removido',
	'9,6' => 'primo quinto tres veces removido',
	'9,7' => 'primo sexto dos veces removido',
	'9,8' => 'primo septimo una vez removido',
	'9,9' => 'primo octavo',
	'9,10' => 'primo octavo una vez removido',
	'10,0' => 'antepasado lejano',
	'10,1' => 'tio lejano',
	'10,2' => 'primo hermano ocho veces removido',
	'10,3' => 'primo segundo siete veces removido',
	'10,4' => 'primo tercero seis veces removido',
	'10,5' => 'primo cuarto cinco veces removido',
	'10,6' => 'primo quinto cuatro veces removido',
	'10,7' => 'primo sexto tres veces removido',
	'10,8' => 'primo septimo dos veces removido',
	'10,9' => 'primo octavo una vez removido',
	'10,10' => 'primo noveno',
);

Readonly::Hash my %ES_FEMALE_RELATIONSHIPS => (
	'0,0' => 'una misma',
	'0,1' => 'hija',
	'0,2' => 'nieta',
	'0,3' => 'bisnieta',
	'0,4' => 'tataranieta',
	'0,5' => 'chozna',
	'0,6' => 'bisnieta quinta',
	'0,7' => 'descendiente lejana',
	'0,8' => 'descendiente lejana',
	'0,9' => 'descendiente lejana',
	'0,10' => 'descendiente lejana',
	'1,0' => 'madre',
	'1,1' => 'hermana',
	'1,2' => 'sobrina',
	'1,3' => 'sobrina nieta',
	'1,4' => 'sobrina bisnieta',
	'1,5' => 'sobrina tataranieta',
	'1,6' => 'sobrina lejana',
	'1,7' => 'sobrina lejana',
	'1,8' => 'sobrina lejana',
	'1,9' => 'sobrina lejana',
	'1,10' => 'sobrina lejana',
	'2,0' => 'abuela',
	'2,1' => 'tia',
	'2,2' => 'prima hermana',
	'2,3' => 'prima hermana una vez removida',
	'2,4' => 'prima hermana dos veces removida',
	'2,5' => 'prima hermana tres veces removida',
	'2,6' => 'prima hermana cuatro veces removida',
	'2,7' => 'prima hermana cinco veces removida',
	'2,8' => 'prima hermana seis veces removida',
	'2,9' => 'prima hermana siete veces removida',
	'2,10' => 'prima hermana ocho veces removida',
	'3,0' => 'bisabuela',
	'3,1' => 'tia abuela',
	'3,2' => 'prima hermana una vez removida',
	'3,3' => 'prima segunda',
	'3,4' => 'prima segunda una vez removida',
	'3,5' => 'prima segunda dos veces removida',
	'3,6' => 'prima segunda tres veces removida',
	'3,7' => 'prima segunda cuatro veces removida',
	'3,8' => 'prima segunda cinco veces removida',
	'3,9' => 'prima segunda seis veces removida',
	'3,10' => 'prima segunda siete veces removida',
	'4,0' => 'tatarabuela',
	'4,1' => 'tia bisabuela',
	'4,2' => 'prima hermana dos veces removida',
	'4,3' => 'prima segunda una vez removida',
	'4,4' => 'prima tercera',
	'4,5' => 'prima tercera una vez removida',
	'4,6' => 'prima tercera dos veces removida',
	'4,7' => 'prima tercera tres veces removida',
	'4,8' => 'prima tercera cuatro veces removida',
	'4,9' => 'prima tercera cinco veces removida',
	'4,10' => 'prima tercera seis veces removida',
	'5,0' => 'chozna',
	'5,1' => 'tia tatarabuela',
	'5,2' => 'prima hermana tres veces removida',
	'5,3' => 'prima segunda dos veces removida',
	'5,4' => 'prima tercera una vez removida',
	'5,5' => 'prima cuarta',
	'5,6' => 'prima cuarta una vez removida',
	'5,7' => 'prima cuarta dos veces removida',
	'5,8' => 'prima cuarta tres veces removida',
	'5,9' => 'prima cuarta cuatro veces removida',
	'5,10' => 'prima cuarta cinco veces removida',
	'6,0' => 'bisabuela quinta',
	'6,1' => 'tia lejana',
	'6,2' => 'prima hermana cuatro veces removida',
	'6,3' => 'prima segunda tres veces removida',
	'6,4' => 'prima tercera dos veces removida',
	'6,5' => 'prima cuarta una vez removida',
	'6,6' => 'prima quinta',
	'6,7' => 'prima quinta una vez removida',
	'6,8' => 'prima quinta dos veces removida',
	'6,9' => 'prima quinta tres veces removida',
	'6,10' => 'prima quinta cuatro veces removida',
	'7,0' => 'antepasada lejana',
	'7,1' => 'tia lejana',
	'7,2' => 'prima hermana cinco veces removida',
	'7,3' => 'prima segunda cuatro veces removida',
	'7,4' => 'prima tercera tres veces removida',
	'7,5' => 'prima cuarta dos veces removida',
	'7,6' => 'prima quinta una vez removida',
	'7,7' => 'prima sexta',
	'7,8' => 'prima sexta una vez removida',
	'7,9' => 'prima sexta dos veces removida',
	'7,10' => 'prima sexta tres veces removida',
	'8,0' => 'antepasada lejana',
	'8,1' => 'tia lejana',
	'8,2' => 'prima hermana seis veces removida',
	'8,3' => 'prima segunda cinco veces removida',
	'8,4' => 'prima tercera cuatro veces removida',
	'8,5' => 'prima cuarta tres veces removida',
	'8,6' => 'prima quinta dos veces removida',
	'8,7' => 'prima sexta una vez removida',
	'8,8' => 'prima septima',
	'8,9' => 'prima septima una vez removida',
	'8,10' => 'prima septima dos veces removida',
	'9,0' => 'antepasada lejana',
	'9,1' => 'tia lejana',
	'9,2' => 'prima hermana siete veces removida',
	'9,3' => 'prima segunda seis veces removida',
	'9,4' => 'prima tercera cinco veces removida',
	'9,5' => 'prima cuarta cuatro veces removida',
	'9,6' => 'prima quinta tres veces removida',
	'9,7' => 'prima sexta dos veces removida',
	'9,8' => 'prima septima una vez removida',
	'9,9' => 'prima octava',
	'9,10' => 'prima octava una vez removida',
	'10,0' => 'antepasada lejana',
	'10,1' => 'tia lejana',
	'10,2' => 'prima hermana ocho veces removida',
	'10,3' => 'prima segunda siete veces removida',
	'10,4' => 'prima tercera seis veces removida',
	'10,5' => 'prima cuarta cinco veces removida',
	'10,6' => 'prima quinta cuatro veces removida',
	'10,7' => 'prima sexta tres veces removida',
	'10,8' => 'prima septima dos veces removida',
	'10,9' => 'prima octava una vez removida',
	'10,10' => 'prima novena',
);

# ---------------------------------------------------------------------------
# Farsi (Persian) relationship tables
# Values use \N{U+XXXX} Unicode escapes (right-to-left script)
# Side-specific keys: "s1,s2,paternal" / "s1,s2,maternal"
# ---------------------------------------------------------------------------

Readonly::Hash my %FA_MALE_RELATIONSHIPS => (
	'0,0' => "\N{U+062E}\N{U+0648}\N{U+062F}",
	'0,1' => "\N{U+067E}\N{U+0633}\N{U+0631}",
	'0,2' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,3' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,4' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,5' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,6' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,7' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,8' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,9' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,10' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'1,0' => "\N{U+067E}\N{U+062F}\N{U+0631}",
	'1,1' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}",
	'1,2' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,3' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,4' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,5' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,6' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,7' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,8' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,9' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,10' => "\N{U+0628}\N{U+0631}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'2,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'2,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'3,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'4,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'5,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'6,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'7,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'8,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'9,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,0' => "\N{U+067E}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'10,1' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,2' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,3' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,4' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,5' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,6' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,7' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,8' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,9' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,10' => "\N{U+067E}\N{U+0633}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'2,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'3,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'4,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'5,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'6,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'7,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'8,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'9,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,1,maternal' => "\N{U+062F}\N{U+0627}\N{U+06CC}\N{U+06CC}",
	'10,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0648}",
);

Readonly::Hash my %FA_FEMALE_RELATIONSHIPS => (
	'0,0' => "\N{U+062E}\N{U+0648}\N{U+062F}",
	'0,1' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}",
	'0,2' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,3' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,4' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,5' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,6' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,7' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,8' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,9' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'0,10' => "\N{U+0646}\N{U+0648}\N{U+0647}",
	'1,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}",
	'1,1' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}",
	'1,2' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,3' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,4' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,5' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,6' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,7' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,8' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,9' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'1,10' => "\N{U+062E}\N{U+0648}\N{U+0627}\N{U+0647}\N{U+0631}\N{U+0632}\N{U+0627}\N{U+062F}\N{U+0647}",
	'2,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'2,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'2,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'3,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'3,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'3,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'4,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'4,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'4,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'5,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'5,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'5,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'6,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'6,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'6,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'7,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'7,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'7,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'8,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'8,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'8,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'9,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'9,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'9,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,0' => "\N{U+0645}\N{U+0627}\N{U+062F}\N{U+0631}\N{U+0628}\N{U+0632}\N{U+0631}\N{U+06AF}",
	'10,1' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'10,2' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,3' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,4' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,5' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,6' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,7' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,8' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,9' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'10,10' => "\N{U+062F}\N{U+062E}\N{U+062A}\N{U+0631}\N{U+0639}\N{U+0645}\N{U+0648}",
	'2,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'2,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'3,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'3,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'4,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'4,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'5,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'5,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'6,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'6,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'7,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'7,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'8,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'8,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'9,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'9,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
	'10,1,maternal' => "\N{U+062E}\N{U+0627}\N{U+0644}\N{U+0647}",
	'10,1,paternal' => "\N{U+0639}\N{U+0645}\N{U+0647}",
);

# ---------------------------------------------------------------------------
# Classical Latin relationship tables
# Many step-count combinations have no classical term; those keys are absent.
# Side-specific keys: "s1,s2,paternal" / "s1,s2,maternal"
# ---------------------------------------------------------------------------

Readonly::Hash my %LA_MALE_RELATIONSHIPS => (
	'0,0' => 'ipse',
	'0,1' => 'filius',
	'0,2' => 'nepos',
	'0,3' => 'pronepos',
	'0,4' => 'abnepos',
	'0,5' => 'atnepos',
	'0,6' => 'trinepos',
	'1,0' => 'pater',
	'1,1' => 'frater',
	'1,2' => 'nepos',
	'2,0' => 'avus',
	'2,1' => 'patruus',
	'2,2' => 'consobrinus',
	'3,0' => 'proavus',
	'3,1' => 'patruus magnus',
	'4,0' => 'abavus',
	'4,1' => 'patruus maior',
	'5,0' => 'atavus',
	'5,1' => 'patruus maximus',
	'6,0' => 'tritavus',
	'2,1,maternal' => 'avunculus',
	'2,1,paternal' => 'patruus',
	'2,2,maternal' => 'consobrinus',
	'2,2,paternal' => 'patruelis',
	'3,1,maternal' => 'avunculus magnus',
	'3,1,paternal' => 'patruus magnus',
	'4,1,maternal' => 'avunculus maior',
	'4,1,paternal' => 'patruus maior',
	'5,1,maternal' => 'avunculus maximus',
	'5,1,paternal' => 'patruus maximus',
);

Readonly::Hash my %LA_FEMALE_RELATIONSHIPS => (
	'0,0' => 'ipsa',
	'0,1' => 'filia',
	'0,2' => 'neptis',
	'0,3' => 'proneptis',
	'0,4' => 'abneptis',
	'0,5' => 'atneptis',
	'0,6' => 'trineptis',
	'1,0' => 'mater',
	'1,1' => 'soror',
	'1,2' => 'neptis',
	'2,0' => 'avia',
	'2,1' => 'amita',
	'2,2' => 'consobrina',
	'3,0' => 'proavia',
	'3,1' => 'amita magna',
	'4,0' => 'abavia',
	'4,1' => 'amita maior',
	'5,0' => 'atavia',
	'5,1' => 'amita maxima',
	'6,0' => 'tritavia',
	'2,1,maternal' => 'matertera',
	'2,1,paternal' => 'amita',
	'2,2,maternal' => 'consobrina',
	'2,2,paternal' => 'patruelis',
	'3,1,maternal' => 'matertera magna',
	'3,1,paternal' => 'amita magna',
	'4,1,maternal' => 'matertera maior',
	'4,1,paternal' => 'amita maior',
	'5,1,maternal' => 'matertera maxima',
	'5,1,paternal' => 'amita maxima',
);

# ---------------------------------------------------------------------------
# Master dispatch table: lang -> sex -> hashref
# ---------------------------------------------------------------------------

Readonly::Hash my %RELATIONSHIP_TABLES => (
	'en' => {
		$SEX_MALE   => \%EN_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%EN_FEMALE_RELATIONSHIPS,
	}, 'es' => {
		$SEX_MALE   => \%ES_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%ES_FEMALE_RELATIONSHIPS,
	}, 'fa' => {
		$SEX_MALE   => \%FA_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%FA_FEMALE_RELATIONSHIPS,
	}, 'fr' => {
		$SEX_MALE   => \%FR_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%FR_FEMALE_RELATIONSHIPS,
	}, 'de' => {
		$SEX_MALE   => \%DE_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%DE_FEMALE_RELATIONSHIPS,
	}, 'de_ch' => {
		$SEX_MALE   => \%DE_CH_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%DE_CH_FEMALE_RELATIONSHIPS,
	}, 'la' => {
		$SEX_MALE   => \%LA_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%LA_FEMALE_RELATIONSHIPS,
	},
);
# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head1 NAME

Genealogy::Relationship::Name - Return a genealogical relationship name from step counts

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Genealogy::Relationship::Name;

    my $namer = Genealogy::Relationship::Name->new();

    my $name = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );
    # Returns 'first cousin once-removed'

    # With language
    my $name_fr = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 2,
        sex                 => 'M',
        language            => 'fr',
    );
    # Returns 'cousin germain'

=head1 DESCRIPTION

C<Genealogy::Relationship::Name> maps a pair of step-counts (person A to common
ancestor, common ancestor to person B) plus the sex of person B and an optional
language code to a human-readable relationship name string.

The relationship tables were originally embedded in the C<gedcom> and C<ged2site>
distributions inside C<Gedcom::Individual::relationship_up()>; this module
extracts them into a reusable, installable CPAN distribution.

Supported languages: C<en> (English, default), C<de> (German), C<es> (Spanish),
C<fa> (Farsi/Persian), C<fr> (French), C<la> (Classical Latin).

=head1 METHODS

=head2 new

Constructor.  Creates and returns a blessed C<Genealogy::Relationship::Name>
object.

=head3 PURPOSE

Initialises the object with optional configuration: a default language for
subsequent C<name()> calls, and an optional L<Log::Abstraction> object to
use as the error logger.  Configuration may also be loaded from an INI-style
file via L<Object::Configure>.

=head3 ARGUMENTS

=over 4

=item C<language> (string, optional)

Default BCP-47 language tag (primary subtag only) for all C<name()> calls
on this object.  Supported values: C<en> (default), C<fr>, C<de>.  May be
overridden per-call by passing C<language> to C<name()>.

=item C<logger>

A pre-constructed loggining object.  When a required argument is
passed as C<undef> to C<name()>, the error is reported via
C<< $logger->error($msg) >> rather than C<croak>.  This allows
programs to route errors through their own
infrastructure with full C<ctx> context.

See L<Log::Abstraction> and the L</CONFIGURATION> section for the
recommended construction pattern.

=item C<config_file> (string, optional)

Path to an INI-style configuration file processed by L<Object::Configure>.
Any keys it sets may be overridden by arguments passed directly to C<new()>.

=back

=head3 RETURNS

A blessed C<Genealogy::Relationship::Name> object.

=head3 SIDE EFFECTS

Calls L<Object::Configure> C<configure()>, which may read from a
configuration file on disk if C<config_file> is supplied or if a default
configuration file exists for the class.

=head3 NOTES

L<Object::Configure> cannot handle object or coderef values (it treats
unknown scalar values as configuration file paths).  The C<logger> key is
therefore stashed before the C<configure()> call and restored afterward.
Any future object-valued constructor arguments must follow the same pattern.

=head3 EXAMPLE

    use Genealogy::Relationship::Name;
    use Log::Abstraction;

    # Minimal construction
    my $namer = Genealogy::Relationship::Name->new();

    # With a default language
    my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');

    # With a Log::Abstraction logger
    my $la = Log::Abstraction->new(
        logger => sub {
            my $args = shift;
            my $msg = $args->{ctx}
                ? $args->{ctx}->as_string() . ': ' . join('', @{$args->{message}})
                : join('', @{$args->{message}});
            complain({ message => $msg, person => $args->{ctx} });
        },
        ctx => $individual,
    );
    my $namer = Genealogy::Relationship::Name->new(language => 'en', logger => $la);

=head3 API SPECIFICATION

=head4 Input

    {
	language => { type => 'string', regex => qr/^(?:en|de(?:-ch)?|es|fa|fr|la)/, optional => 1 },
        logger   => { type => 'object', optional => 1 },
    }

=head4 Output

    {
        type  => 'object',
        class => 'Genealogy::Relationship::Name',
    }

=cut

sub new {
	# Create and return a blessed object
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_);

	# Stash keys that are coderefs or objects before passing to Object::Configure,
	# which cannot handle them (it treats unknown scalar values as config file paths)
	my %stash;
	for my $key (qw(logger)) {
		next unless exists $params->{$key};
		$stash{$key} = delete $params->{$key};
	}

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	# Restore the stashed coderefs and objects after configure()
	@{$params}{keys %stash} = values %stash;

	# Bless and return the object; logger/ctx/level keys from params
	# are stored directly and accessed via $self->{logger} etc.
	return bless {
		# Store any constructor-time config for Object::Configure compatibility
		%{$params},
	}, ref($class) || $class;
}

# ---------------------------------------------------------------------------
# Public method: name()
# ---------------------------------------------------------------------------

=head2 name

Returns the name of the relationship between person A and person B.

=head3 PURPOSE

Given the number of steps from person A up to the nearest common ancestor
(C<steps_to_ancestor>) and the number of steps from that ancestor down to
person B (C<steps_from_ancestor>), plus the sex of person B and a language
code, returns a localised relationship-name string.

=head3 ARGUMENTS

=over 4

=item C<steps_to_ancestor> (integer, required)

Number of generational steps from person A up to the common ancestor.
Must be a non-negative integer.  Zero means person A I<is> the ancestor.

=item C<steps_from_ancestor> (integer, required)

Number of generational steps from the common ancestor down to person B.
Must be a non-negative integer.

=item C<sex> (string, required)

Sex of person B.  Must be C<'M'> (male) or C<'F'> (female).

=item C<language> (string, optional)

BCP-47-style language tag (only the primary subtag is used).
Supported values: C<en> (default), C<de>, C<es>, C<fa>, C<fr>, C<la>.

Note: C<fa> (Farsi/Persian) values are stored as C<\N{U+XXXX}> Unicode
escapes and render correctly in any Unicode-aware context.  C<la>
(Classical Latin) has a sparse table; many step-count combinations have
no classical term and return C<undef>.

=item C<person> (object, optional)

An optional person object (e.g. a C<Gedcom::Individual> instance) passed
through to the error handler when an error occurs.  Takes priority over the
C<ctx> set at construction time.  The handler receives it as C<ctx> (logger
path) or C<person> (on_error path), matching the C<complain()> interface
in C<gedcom>/C<ged2site>.

=item C<family_side> (string, optional)

C<'paternal'> or C<'maternal'>.  Used by languages that distinguish the
paternal from the maternal line for the same step counts.  Currently
relevant for:

=over 4

=item * C<la> (Latin) -- uncle/aunt (C<patruus>/C<avunculus>,
C<amita>/C<matertera>) and first cousin (C<patruelis>/C<consobrinus>)

=item * C<fa> (Farsi) -- uncle (C<amoo>/C<dayi>) and aunt
(C<ammeh>/C<khaleh>)

=back

When C<family_side> is not supplied, the table falls back to the generic
(non-side-specific) entry for that step-count pair.

=back

=head3 RETURNS

A string containing the relationship name, or C<undef> if the combination
is not found in the lookup table.

=head3 EXAMPLE

    my $namer = Genealogy::Relationship::Name->new();

    # Person A is the grandparent (2 steps up) of the common ancestor,
    # and person B is 3 steps below the ancestor; B is female => first cousin once-removed
    my $rel = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );

=head3 API SPECIFICATION

=head4 Input

    {
	steps_to_ancestor   => { type => 'integer', minimum => 0 },
	steps_from_ancestor => { type => 'integer', minimum => 0 },
	sex                 => { type => 'string', memberof => ['M', 'F'] },
        language => { type => 'string', regex => qr/^(?:en|de(?:-ch)?|es|fa|fr|la)/, optional => 1 },
	# person is handled before validate_strict (PVS infers constraints from objects)
	family_side => { type => 'string', memberof => ['paternal','maternal'], optional => 1 },
    }

=head4 Output

    {
        type     => 'string',
        optional => 1,     # undef when the combination is not tabulated
    }

=head3 FORMAL SPECIFICATION

    name ______________________________________________________
    [In]  steps_to_ancestor   : N0
          steps_from_ancestor : N0
          sex                 : {M, F}
          language            : {en, es, fa, fr, de, la}?  (default en)
          person              : Object?
    [Out] result              : String | undef

    Let key      == steps_to_ancestor ++ "," ++ steps_from_ancestor
    Let side_key == key ++ "," ++ family_side  if family_side defined
    Let table    == RELATIONSHIP_TABLES(language)(sex)
    result == table(side_key)  if family_side defined and side_key in dom table
           == table(key)       if key in dom table
           == undef            otherwise

=cut

sub name {
	my $self = shift;

	# Validate and extract the remaining parameters; capture the return value
	my $args = Params::Validate::Strict::validate_strict(
		args   => Params::Get::get_params(undef, \@_) || {},
		schema => {
			steps_to_ancestor   => { type => 'integer', minimum => 0 },
			steps_from_ancestor => { type => 'integer', minimum => 0 },
			sex                 => { type => 'string', memberof => ['M', 'F'] },
			language => { type => 'string', regex => qr/^(?:en|de(?:-ch)?|es|fa|fr|la)/, optional => 1 },
			person              => { type => 'object', optional => 1 },
			family_side         => { type => 'string', memberof => ['paternal','maternal'],
			                         optional => 1 },
		}
	);

	# Extract individual parameters; undef means arg was given as undef, so
	# report via logger if set, otherwise croak
	foreach my $arg(qw(steps_to_ancestor steps_from_ancestor sex)) {
		if(!defined($args->{$arg})) {
			if(my $logger = $self->{logger}) {
				$logger->error("$arg not given");
			}
			croak("$arg not given");
		}
	}
	my $steps1 = $args->{steps_to_ancestor};
	my $steps2 = $args->{steps_from_ancestor};
	my $sex    = $args->{sex};
	my $person      = $args->{person};
	my $family_side = $args->{family_side};

	# Fall back to constructor default or hard default if no per-call language given
	my $lang = lc($args->{language} // $self->{language} // $DEFAULT_LANGUAGE);

	# Swiss German (de-CH) maps to its own table before subtag stripping,
	# because it uses 'ss' where standard German uses Eszett
	if($lang eq 'de-ch') {
		$lang = 'de_ch';
	} else {
		# Strip any region subtag (e.g. 'en-GB' -> 'en') after lowercasing
		($lang) = split /-/, $lang;
	}

	# Build lookup key from the two step counts; try side-specific key first
	# for languages that distinguish paternal/maternal (Latin, Farsi)
	my $key      = "${steps1},${steps2}";
	my $side_key = defined($family_side) ? "${key},${family_side}" : undef;

	# Retrieve the correct gender-specific table for the chosen language
	my $table = $RELATIONSHIP_TABLES{$lang}{$sex};

	# Prefer side-specific entry when family_side is given; fall back to generic key
	my $result = (defined($side_key) && exists $table->{$side_key})
	             ? $table->{$side_key}
	             : $table->{$key};

	return $result;
}

# ---------------------------------------------------------------------------
# Public method: supported_languages()
# ---------------------------------------------------------------------------

=head2 supported_languages

Returns a sorted list of the language codes that the module supports.

=head3 PURPOSE

Allows calling code to enumerate the languages available for C<name()>
without hard-coding them.

=head3 ARGUMENTS

None.

=head3 RETURNS

A list (or array-ref in scalar context) of language code strings,
currently C<('de', 'de_ch', 'en', 'es', 'fa', 'fr', 'la')>.

=head3 EXAMPLE

    my @langs = $namer->supported_languages();
    # ( 'de', 'de_ch', 'en', 'es', 'fa', 'fr', 'la' )

=head3 API SPECIFICATION

=head4 Input

    {}   # no arguments

=head4 Output

    {
        type => ARRAYREF,   # sorted list of language codes
    }

=cut

sub supported_languages {
	# Return the sorted set of keys from the master dispatch table
	my @langs = sort keys %RELATIONSHIP_TABLES;
	return wantarray ? @langs : \@langs;
}

# ---------------------------------------------------------------------------
# Public method: known_sexes()
# ---------------------------------------------------------------------------

=head2 known_sexes

Returns the list of sex codes accepted by C<name()>.

=head3 PURPOSE

Documents and exposes the set of valid C<sex> values so that callers can
validate their own input without duplicating knowledge.

=head3 ARGUMENTS

None.

=head3 RETURNS

A list (or array-ref in scalar context) of valid sex code strings: C<('F', 'M')>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my @sexes = $namer->known_sexes();
    # ( 'F', 'M' )

=head3 API SPECIFICATION

=head4 Input

    {}   # no arguments

=head4 Output

    {
        type => ARRAYREF,
    }

=cut

sub known_sexes {
	# Return the two valid sex codes in sorted order
	my @sexes = sort($SEX_FEMALE, $SEX_MALE);
	return wantarray ? @sexes : \@sexes;
}

1;

__END__

=head1 CONFIGURATION

The constructor accepts an optional C<language> key which sets the default
language for all subsequent calls to C<name()>:

    my $namer = Genealogy::Relationship::Name->new(language => 'fr');

This default can be overridden per-call by passing C<language> to C<name()>.
The object is also compatible with C<Object::Configure> for runtime
reconfiguration.

=head2 Error handling

Errors are dispatched through the following priority chain:

=over 4

=item 1. L<Log::Abstraction> object (preferred)

Construct a C<Log::Abstraction> object with the desired logger coderef and
C<ctx> (typically a C<Gedcom::Individual>), then pass it as C<logger> to
C<new()>.  On error, this module simply calls C<< $logger->error($msg) >>
and Log::Abstraction handles ctx forwarding, formatting, and dispatch.

    use Log::Abstraction;

    my $logger = Log::Abstraction->new(
        logger => sub {
            my $args = shift;
            my $msg = $args->{ctx}
                ? $args->{ctx}->as_string() . ': ' . join('', @{$args->{message}})
                : join('', @{$args->{message}});
            complain({ message => $msg, person => $args->{ctx} });
        },
        ctx => $individual,
    );

    my $namer = Genealogy::Relationship::Name->new(logger => $logger);

=back

If any handler returns without dying (e.g. a warning-only handler in
L<Log::Abstraction>), C<name()> returns C<undef>.

=head1 DIAGNOSTICS

=over 4

=item steps_to_ancestor not given

C<steps_to_ancestor> was passed as C<undef>. Passing C<undef> explicitly is
distinct from omitting the argument; use a defined non-negative integer.

=item steps_from_ancestor not given

As above, for C<steps_from_ancestor>.

=item sex not given

C<sex> was passed as C<undef>. Supply C<'M'> or C<'F'>.

=back

=head1 DEPENDENCIES

L<Carp>, L<Object::Configure>

Optionally L<Log::Abstraction> (E<gt>= 0.28) for the C<logger>/C<ctx> error
dispatch path.
L<Params::Get>, L<Params::Validate::Strict>, L<Readonly>

=head1 BUGS AND LIMITATIONS

The lookup tables currently cover steps 0-6 in both directions.  Relationships
further removed (seventh cousin, etc.) return C<undef>.  Pull requests adding
deeper tables are welcome.

=head1 TODO

=over 4

=item * Extract and integrate the Latin relationship handling code currently
embedded in the C<gedcom> and C<ged2site> programs, adding C<la> as a
supported language alongside C<en>, C<fr>, and C<de>.

=back

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Genealogy-Relationship-Name/coverage/>

=item * L<Gedcom::Individual>, L<Genealogy::Relationship>, L<https://www.tfcg.ca/tableau-des-liens-de-parente>,

=back

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Genealogy-Relationship-Name>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-genealogy-relationship-name at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Relationship::Name

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Genealogy-Relationship-Name>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::Relationship::Name>

=back

=head1 FORMAL SPECIFICATION

=head2 new

    new ________________________________________________________
    [In]  class    : String                  (class name or object)
          language            : {en, es, fa, fr, de, la}?  (optional default language
          logger   : Log::Abstraction?       (optional error logger)
    [Out] self     : Genealogy::Relationship::Name

    Let params == get_params(args)
    Let params' == configure(class, params \ {logger})
                   union {logger -> params.logger}  if logger in dom params
    self == bless(params', class)

    post: self.language == params.language  if language in dom params
          self.logger   == params.logger    if logger   in dom params
          ref(self)     == 'Genealogy::Relationship::Name'

=head2 name

    name ______________________________________________________
    [In]  steps_to_ancestor   : N0
          steps_from_ancestor : N0
          sex                 : {M, F}
          language            : {en, fr, de}?  (default en)
          person              : Object?
    [Out] result              : String | undef

    Let key == steps_to_ancestor ++ "," ++ steps_from_ancestor
    Let table == RELATIONSHIP_TABLES(language)(sex)
    result == table(key)  if key in dom table
           == undef       otherwise

=head2 supported_languages

    supported_languages ______________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort(dom RELATIONSHIP_TABLES)

=head2 known_sexes

    known_sexes ______________________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort { $SEX_FEMALE, $SEX_MALE }

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
