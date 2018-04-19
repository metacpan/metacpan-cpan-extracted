use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ stderr_from /;
use JavaScript::Duktape::XS;

sub check_functions {
    my ($err, $file, $funcs) = @_;

    foreach my $func (@$funcs) {
        my $expected = quotemeta("at $func") . '.*' . quotemeta("($file:") . '[0-9]+' . quotemeta(')');
        like($err, qr/$expected/, "found function $file:$func in stack trace");
    }
}

sub check_variables {
    my ($err, $file, $vars) = @_;

    foreach my $var (@$vars) {
        my $expected = "[^a-zA-Z0-9_]" . quotemeta("$var") . "[^a-zA-Z0-9_]";
        like($err, qr/$expected/, "found variable $file:$var in stack trace");
    }
}

sub test_stacktrace {
    my $js = <<EOS;
var fail = true;
function d(x) { if (fail) { throw new Error("failed"); } }
function c(x) { if (fail) { return gonzo.length; } }
function b(x) { c(x); }
function a(x) { b(x); return "ok"; }
var ret;
// ret = gonzo.length;
ret = a(0);
// try { ret = a(0) } catch(e) { console.error(e.message); ret = e; };
EOS
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $file = 'myFileName.js';
    my @funcs = qw/ a b c /;
    my @vars = qw/ gonzo /;
    my $err = stderr_from(sub { $duk->eval($js, $file); });

    check_functions($err, $file, \@funcs);
    check_variables($err, $file, \@vars);
}

sub main {
    test_stacktrace();
    done_testing;
    return 0;
}

exit main();
