use strict;
use warnings;

use Data::Dumper;
use Path::Tiny;
use Test::More;
use Test::Output;
use JavaScript::Duktape::XS;

sub load_js_file {
    my ($duk, $file) = @_;

    my $path = Path::Tiny::path($file);
    my $code = $path->slurp_utf8();
    $duk->eval($code);
    ok(1, "loaded file '$file'");
}

sub test_js_timeout {
    my ($duk) = @_;

    my $js = <<JS;
var perl_ret = 'EMPTY';
var perl_err = 'EMPTY';

function main() {
    perl_ret += 1

    setTimeout(function () {
        perl_ret += 7
    }, 1000)

    perl_ret += 2

    setTimeout(function () {
        perl_ret += 6
    }, 100)

    perl_ret += 3

    setTimeout(function () {
        perl_ret += 5
    })

    perl_ret += 4
}
JS
    my $got_eval = $duk->eval($js);
    my $got_run = $duk->dispatch_function_in_event_loop('main');
    my $perl_ret = $duk->get('perl_ret');
    is($perl_ret, 'EMPTY1234567', "timeouts dispatched correctly");
}

sub test_timeout_with_error {
    my ($duk) = @_;

    my $js = <<JS;
function main() {
    setTimeout(function () {
        var notdef;
        console.log(notdef.length);
    })
}
JS
    my $got_eval = $duk->eval($js);
    stderr_like sub { $duk->dispatch_function_in_event_loop('main'); },
                qr/Error:/,
                "got correct error from setTimeout";
}

sub main {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my @js_files = qw/
        c_eventloop.js
    /;
    foreach my $js_file (@js_files) {
        load_js_file($duk, $js_file);
    }

    test_js_timeout($duk);
    test_timeout_with_error($duk);

    done_testing;
    return 0;
}

exit main();
