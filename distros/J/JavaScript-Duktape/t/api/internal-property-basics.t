use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

sub test_1 {
    $duk->eval_string("(function (x) { print(Duktape.enc('jx', x)); })");
    $duk->push_object();

    #Ordinary property */
    $duk->push_int(1);
    $duk->put_prop_string(-2, "foo"); # obj.foo = 1 */

    # /* Internal property \xFF\xFFabc, technically enumerable (based on
    # * property attributes) but because of internal property special
    # * behavior, does not enumerate.
    # */

    $duk->push_int(2);
    $duk->put_prop_string(-2, "\xff\xff" . "abc"); # obj[\xff\xffabc] = 2, internal property */

    # /* Another property with invalid UTF-8 data but doesn't begin with
    # * \xFF => gets enumerated and JX prints out an approximate key.
    # */

    $duk->push_int(3);
    $duk->put_prop_string(-2, " \xff" . "bar"); # obj[ \xffbar] = 3, invalid utf-8 but not an internal property */
    $duk->call(1);
    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
{foo:1," \xffbar":3}
final top: 1
==> rc=0, result='undefined'
