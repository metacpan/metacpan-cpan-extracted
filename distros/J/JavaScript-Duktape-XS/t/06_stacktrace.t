use strict;
use warnings;

use Data::Dumper;
use Path::Tiny;
use Test::More;
use Test::Output qw/ stderr_from /;
use JavaScript::Duktape::XS;

sub load_js_file {
    my ($duk, $file) = @_;

    my $path = Path::Tiny::path($file);
    my $code = $path->slurp_utf8();
    $duk->eval($code);
    ok(1, "loaded file '$file'");
}

sub check_functions {
    my ($type, $err, $file, $funcs) = @_;

    foreach my $func (@$funcs) {
        my $expected = quotemeta("at $func") . '.*' . quotemeta("($file:") . '[0-9]+' . quotemeta(')');
        like($err, qr/$expected/, "found function $file:$func in stack trace type $type");
    }
}

sub check_variables {
    my ($type, $err, $file, $vars) = @_;

    foreach my $var (@$vars) {
        my $expected = "[^a-zA-Z0-9_]" . quotemeta("$var") . "[^a-zA-Z0-9_]";
        like($err, qr/$expected/, "found variable $file:$var in stack trace type $type");
    }
}

sub test_stacktrace {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my @js_files = qw/
        c_eventloop.js
    /;
    foreach my $js_file (@js_files) {
        load_js_file($duk, $js_file);
    }

    my $js_code = <<EOS;
var fail = true;
function d() { if (fail) { throw new Error("failed"); } }
function c() { if (fail) { return gonzo.length; } }
function b() { c(); }
function a() { b(); return "ok"; }
EOS

    my $js_file = 'myFileName.js';
    $duk->eval($js_code, $js_file);

    my @funcs = qw/ a b c /;
    my @vars = qw/ gonzo /;
    my $call = 'a';
    my %types = (
        normal     => {
            method => 'eval',
            args   => [ "$call()", $js_file ],
        },
        event_loop => {
            method => 'dispatch_function_in_event_loop',
            args   => [ $call ],
        },
    );
    foreach my $type (sort keys %types) {
        my $code = $types{$type};
        my $method = $code->{method};
        next unless $method;
        my $err = stderr_from(sub { $duk->$method(@{ $code->{args} }) });

        check_functions($type, $err, $js_file, \@funcs);
        check_variables($type, $err, $js_file, \@vars);
    }
}

sub main {
    test_stacktrace();
    done_testing;
    return 0;
}

exit main();
