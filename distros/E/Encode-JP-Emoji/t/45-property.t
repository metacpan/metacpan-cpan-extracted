use strict;
use warnings;
use Test::More;
use Encode::JP::Emoji;
use Encode::JP::Emoji::Property;

plan tests => 27;

ok( "a" =~ /\p{ASCII}/,                  "ASCII ASCII" );
ok( "a" =~ /\P{InCJKUnifiedIdeographs}/, "ASCII InCJKUnifiedIdeographs" );
ok( "a" =~ /\P{InEmojiDoCoMo}/,   "ASCII InEmojiDocomo" );
ok( "a" =~ /\P{InEmojiKDDIapp}/,  "ASCII InEmojiKddi" );
ok( "a" =~ /\P{InEmojiKDDIweb}/,  "ASCII InEmojiKddiweb" );
ok( "a" =~ /\P{InEmojiSoftBank}/, "ASCII InEmojiSoftbank" );
ok( "a" =~ /\P{InEmojiUnicode}/,  "ASCII InEmojiUnicode" );
ok( "a" =~ /\P{InEmojiGoogle}/,   "ASCII InEmojiGoogle" );
ok( "a" =~ /\P{InEmojiAny}/,      "ASCII InEmojiAny" );

ok( "\x{6F22}" =~ /\P{ASCII}/,                  "Kanji ASCII" );
ok( "\x{6F22}" =~ /\p{InCJKUnifiedIdeographs}/, "Kanji InCJKUnifiedIdeographs" );
ok( "\x{6F22}" =~ /\P{InEmojiDoCoMo}/,   "Kanji InEmojiDocomo" );
ok( "\x{6F22}" =~ /\P{InEmojiKDDIapp}/,  "Kanji InEmojiKddi" );
ok( "\x{6F22}" =~ /\P{InEmojiKDDIweb}/,  "Kanji InEmojiKddiweb" );
ok( "\x{6F22}" =~ /\P{InEmojiSoftBank}/, "Kanji InEmojiSoftbank" );
ok( "\x{6F22}" =~ /\P{InEmojiUnicode}/,  "Kanji InEmojiUnicode" );
ok( "\x{6F22}" =~ /\P{InEmojiGoogle}/,   "Kanji InEmojiGoogle" );
ok( "\x{6F22}" =~ /\P{InEmojiAny}/,      "Kanji InEmojiAny" );

ok( "\x{FE000}" =~ /\P{ASCII}/,                  "Sun ASCII" );
ok( "\x{FE000}" =~ /\P{InCJKUnifiedIdeographs}/, "Sun InCJKUnifiedIdeographs" );
ok( "\x{E63E}"  =~ /\p{InEmojiDoCoMo}/,   "Sun InEmojiDocomo" );
ok( "\x{E488}"  =~ /\p{InEmojiKDDIapp}/,  "Sun InEmojiKddi" );
ok( "\x{EC40}"  =~ /\p{InEmojiKDDIweb}/,  "Sun InEmojiKddiweb" );
ok( "\x{E04A}"  =~ /\p{InEmojiSoftBank}/, "Sun InEmojiSoftbank" );
ok( "\x{2600}"  =~ /\p{InEmojiUnicode}/,  "Sun InEmojiUnicode" );
ok( "\x{FE000}" =~ /\p{InEmojiGoogle}/,   "Sun InEmojiGoogle" );
ok( "\x{FE000}" =~ /\p{InEmojiAny}/,      "Sun InEmojiAny" );
