use strict;
use warnings;

use Encode             qw( encode_utf8 );
use LWP::ConsoleLogger ();
use Test::More import => [qw( done_testing is ok subtest )];
use Test::Warnings;

my $cl = LWP::ConsoleLogger->new;

subtest 'undef returns undef' => sub {
    is( $cl->_decode_header_value(undef), undef, 'undef passes through' );
};

subtest 'empty string returns empty' => sub {
    is( $cl->_decode_header_value(q{}), q{}, 'empty string passes through' );
};

subtest 'pure ASCII bytes return equivalent characters' => sub {
    my $got = $cl->_decode_header_value('hello');
    is( $got, 'hello', 'ASCII passes through' );
};

subtest 'raw UTF-8 bytes are decoded' => sub {
    my $bytes
        = encode_utf8("\x{03B1}\x{03B9}\x{03C1}\x{03B5}\x{03AF}\x{03B1}");
    my $got = $cl->_decode_header_value($bytes);
    is(
        $got, "\x{03B1}\x{03B9}\x{03C1}\x{03B5}\x{03AF}\x{03B1}",
        'UTF-8 bytes decoded to Greek characters'
    );
    ok( utf8::is_utf8($got), 'result has utf8 flag' );
};

subtest 'invalid UTF-8 falls back to Latin-1' => sub {

    # \xE9 alone is not valid UTF-8 (it would start a 3-byte sequence)
    my $got = $cl->_decode_header_value("\xE9");
    is( $got, "\x{00E9}", 'Latin-1 byte decoded as character é' );
};

subtest 'already-decoded character string is preserved' => sub {
    my $chars = "\x{03B1}";
    my $got   = $cl->_decode_header_value($chars);
    is( $got, "\x{03B1}", 'decoded char passes through unchanged' );
};

done_testing;
