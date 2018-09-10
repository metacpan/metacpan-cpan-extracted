use strict;
use warnings;

use Data::Dumper;
use Path::Tiny;
use Test::More;
use Test::Output qw/ stderr_from /;

my $CLASS = 'JavaScript::Duktape::XS';

sub load_js_file {
    my ($vm, $file) = @_;

    my $path = Path::Tiny::path($file);
    my $code = $path->slurp_utf8();
    $vm->eval($code);
    ok(1, "loaded file '$file'");
}

sub check_functions {
    my ($type, $err, $file, $funcs) = @_;

    foreach my $func (@$funcs) {
        my $expected = quotemeta("at $func") . '.*' . quotemeta("($file:") . '[0-9]+(:[0-9]+)?' . quotemeta(')');
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
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $js_code = <<EOS;
var fail = true;
function d() { if (fail) { throw new Error("failed"); } }
function c() { if (fail) { return gonzo.length; } }
function b() { c(); }
function main() { b(); return "ok"; }
EOS

    my $js_file = 'myFileName.js';
    $vm->eval($js_code, $js_file);

    my $name = 'main';
    my @funcs;
    push @funcs, $name;
    push @funcs, qw/ b c /;
    my @vars = qw/ gonzo /;
    my %types = (
        eval => {
            method => 'eval',
            args   => [ "$name()", $js_file ],
        },
        dispatch_function_in_event_loop => {
            method => 'dispatch_function_in_event_loop',
            args   => [ $name ],
        },
    );
    foreach my $type (sort keys %types) {
        my $code = $types{$type};
        my $method = $code->{method};
        my $args = $code->{args};
        next unless $method;
        my $err = stderr_from(sub { $vm->$method(@$args) });
        # print STDERR Dumper($err);

        check_functions($type, $err, $js_file, \@funcs);
        check_variables($type, $err, $js_file, \@vars);
    }
}

sub main {
    use_ok($CLASS);

    test_stacktrace();
    done_testing;
    return 0;
}

exit main();
