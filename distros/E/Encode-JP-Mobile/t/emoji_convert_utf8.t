use strict;
use Test::More;
use Encode;
use Encode::JP::Mobile;

# -------------------------------------------------------------------------
# test data

my @carriers = qw( docomo kddi softbank);

my @blocks = (
    +{
        name => 'sunny',
        code => {
            docomo   => "\xEE\x98\xBE",
            kddi     => "\xEE\xBD\xA0",
            softbank => "\xEE\x81\x8A",
        }
    },
    +{
        name => 'number 4',
        code => {
            docomo   => "\xEE\x9B\xA5",
            kddi     => "\xEF\x81\x81",
            softbank => "\xEE\x88\x9F",
        }
    },
    +{
        name => 'funny',
        code => {
            docomo   => "\xee\x98\xbe",
            kddi     => "\xee\xbd\xa0",
            softbank => "\xee\x81\x8a",
        }
    }
);

# -------------------------------------------------------------------------
# planning

plan tests => (@carriers * @carriers) * @blocks + 9 + 1;

# -------------------------------------------------------------------------
# do it

simple_pair($_) for @blocks;

sub _h {
    # for better Test::More log
    my $bytes = shift;
    my $out = unpack "H*", $bytes;
    $out =~ s/(..)/\\x$1/g;
    $out;
}

# testing roundtrip-safe pictograms
sub simple_pair {
    my $args = shift;

    for my $from (@carriers) {
        for my $to (@carriers) {
            my $char = decode("x-utf8-" . $from, $args->{code}->{$from});
            my $hex  = sprintf '%X', ord $char;
            is _h(encode("x-utf8-" . $to, $char)), _h($args->{code}->{$to}), "$from -> $to (U+$hex) $args->{name}";
        }
    }
}

# -------------------------------------------------------------------------

{   # fish
    # XXX これ、なにをテストしてるんだろ?
    my $docomo   = "\xEE\x9D\x91";
    my $kddi     = "\xEE\xB3\x9E";
    my $softbank = "\xEE\x94\xA2";

    is encode('x-utf8-docomo',   decode('x-utf8-docomo', $docomo)), $docomo;
    is encode('x-utf8-kddi',     decode('x-utf8-docomo', $docomo)), "\xEE\xBD\xB2"; # kddi Pisces sign
    is encode('x-utf8-softbank', decode('x-utf8-docomo', $docomo)), "\xEE\x80\x99"; # softbank Pisces sign

    is encode('x-utf8-docomo',   decode('x-utf8-kddi', $kddi)), $docomo;
    is encode('x-utf8-kddi',     decode('x-utf8-kddi', $kddi)), $kddi, 'E => E';
    is encode('x-utf8-softbank', decode('x-utf8-kddi', $kddi)), $softbank;

    is encode('x-utf8-docomo',   decode('x-utf8-softbank', $softbank)), $docomo;
    is encode('x-utf8-kddi',     decode('x-utf8-softbank', $softbank)), $kddi, 'V => E';
    is encode('x-utf8-softbank', decode('x-utf8-softbank', $softbank)), $softbank;
}

# -------------------------------------------------------------------------

is decode('utf8', encode('x-utf8-kddi', "\x{E722}")), "\x{ef49}\x{f0ce}", 'pictogram pair';

