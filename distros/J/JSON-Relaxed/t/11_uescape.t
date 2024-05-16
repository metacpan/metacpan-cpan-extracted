# perl

use v5.26;

use Test::More tests => 3;
use JSON::Relaxed;
use utf8;

binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';
my $p = JSON::Relaxed::Parser->new;

is( $p->parse( q{ \uD834\uDD0E } ), "\x{1d10e}",   "\\uD834\\uDD0E" );
diag( $p->is_error ) if $p->is_error;
is( $p->parse( '\u{1d10e}' ), "\x{1d10e}",   "\\x{1d10e}" );
diag( $p->is_error ) if $p->is_error;
is( $p->parse(q{"[*<span face=chordprosymbols size=150% rise=15% color=#000000>\uD834\uDD0E</span>]"}), "[*<span face=chordprosymbols size=150% rise=15% color=#000000>𝄎</span>]", "span" );
diag( $p->is_error ) if $p->is_error;
