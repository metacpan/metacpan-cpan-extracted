use strict;
use warnings;

BEGIN {
    # Need to do this before importing Test::More
    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");
};

use Encode;
use Test::More;
use JavaScript::Duktape::XS;

sub test_encoding {
    my %data = (
        portuguese => 'Calendário',
        icelandic => 'fjörð',
    );
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    foreach my $key (sort keys %data) {
        my $expected = $data{$key};
        Encode::_utf8_on($expected);  # mark as UTF-8
        $duk->set($key, $expected);

        my $got = $duk->get($key); # should get as UTF-8 always
        is($got, $expected, "got encoded data $key: $expected => $got");
    }
}

sub main {

    test_encoding();
    done_testing;

    return 0;
}

exit main();
