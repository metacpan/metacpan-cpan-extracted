use Test::More tests => 4;

use Locale::Maketext::Utils::MarkPhrase;

ok( defined &translatable, 'translatable() imported' );
is( \&translatable, \&Locale::Maketext::Utils::MarkPhrase::translatable, 'imported translatable() is the same as full NS version' );

{

    # we could fiddle w/ the string w/ Encode:: or utf8:: to get a failure to display pretty but that'd defeat the
    # purpose of the test since we'd probably be testing a byte string at that point. Keep it simple for sanity I say.
    no warnings 'utf8';
    is( translatable("JAPH\x{00AE}"), "JAPH\x{00AE}", 'translatable() does not modify unicode string' );
}

is( translatable("JAPH®"), "JAPH®", 'translatable() does not modify bytes string' );
