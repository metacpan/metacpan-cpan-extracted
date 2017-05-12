use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub test_1 {
    # Simple test, intentional out-of-bounds access at the end. */
    $duk->eval_string("'foo\\u1234bar\\u00a0quux\\u0000baz'");
    my $n = $duk->get_length(-1) + 3; # access 3 times out-of-bounds */
    for (my $i = 0; $i < $n; $i++) {
        printf("i=%ld, n=%ld, charcode=%d\n", $i, $n, $duk->char_code_at(-1, $i));
    }
    $duk->pop();
    return 0;
}

sub test_2 {
# TypeError for invalid arg type
    $duk->push_int(123);
    $duk->char_code_at(-1, 10);
    $duk->pop();
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
i=0, n=19, charcode=102
i=1, n=19, charcode=111
i=2, n=19, charcode=111
i=3, n=19, charcode=4660
i=4, n=19, charcode=98
i=5, n=19, charcode=97
i=6, n=19, charcode=114
i=7, n=19, charcode=160
i=8, n=19, charcode=113
i=9, n=19, charcode=117
i=10, n=19, charcode=117
i=11, n=19, charcode=120
i=12, n=19, charcode=0
i=13, n=19, charcode=98
i=14, n=19, charcode=97
i=15, n=19, charcode=122
i=16, n=19, charcode=0
i=17, n=19, charcode=0
i=18, n=19, charcode=0
==> rc=0, result='undefined'
*** test_2 (duk_safe_call)
==> rc=1, result='TypeError: string required, found 123 (stack index -1)'
