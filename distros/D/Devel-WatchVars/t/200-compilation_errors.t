#!/usr/bin/env perl

our $VERSION = v0.0.1;

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);

use test_setup;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

#################################################

sub test_compilation_errors {
    banner;
    my @funcs = qw[watch unwatch];

    my $when = "throws expected exception during compilation";

    for my $func (@funcs) {

        note "testing $func function";

        local $@;

        $LINE = __LINE__; like dies_compiling($func),
            qr/^\QNot enough arguments for ${MAIN_PKG}::$func/,
            "${func}ing without any arguments $when";

        $LINE++;
        like $@, qr/\Q at $FILE line $LINE\E\b/, "exception chooses right line";

        like dies_compiling($func . '($0, $0, $0)'),
            qr/^\QToo many arguments for ${MAIN_PKG}::$func/,
            "${func}ing with three arguments $when";

        like dies_compiling($func . ' $0, $0, $0'),
            qr/^(?:Too many arguments for ${MAIN_PKG}::$func|Useless use of (?:single ref|reference) constructor in void context)\b/,
            "${func}ing without parens and three scalar arguments $when";

        like dies_compiling($func . ' %ENV'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not hash dereference)/,
            "${func}ing a hash $when";

        like dies_compiling($func . ' +{%ENV}'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not anonymous hash ({}))/,
            "${func}ing a hash $when";

        like dies_compiling($func . ' @ARGV'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not array dereference)/,
            "${func}ing an array $when";

        like dies_compiling($func . ' [@ARGV]'),
            qr/^Type of arg 1 to ${MAIN_PKG}::$func must be scalar \(not anonymous (?:list|array) \Q([]))/,
            "${func}ing an array $when";

        like dies_compiling($func . ' \@ARGV'),
            qr/^Type of arg 1 to ${MAIN_PKG}::$func must be scalar \(not (?:reference|single ref) constructor\)/,
            "${func}ing an array $when";

        like dies_compiling($func . ' \&main'),
            qr/^Type of arg 1 to ${MAIN_PKG}::$func must be scalar \(not (?:reference|single ref) constructor\)/,
            "${func}ing a coderef $when";

        like dies_compiling($func . ' sub{3}'),
            qr/^Type of arg 1 to ${MAIN_PKG}::$func must be scalar \(not (?:reference|single ref) constructor\)/,
            "${func}ing a coderef $when";

        like dies_compiling($func . ' 42'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not constant item)/,
            "${func}ing an integer literal $when";

        like dies_compiling($func . ' int(4.2)'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not constant item)/,
            "${func}ing a compile-time constant $when";

        like dies_compiling($func . ' rand(42)'),
            qr/^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not rand)/,
            "${func}ing rand $when";

        like dies_compiling($func . ' qr/bad/'),
            qr{^\QType of arg 1 to ${MAIN_PKG}::$func must be scalar (not pattern quote (qr//))},
            "${func}ing qr/bad/ $when";

    }

}
