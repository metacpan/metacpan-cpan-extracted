#!perl

# test actual generated logs: mixing per-output level and per-category level,
# category alias

use lib './t';
BEGIN {
    require 'testlib.pl';
    reset_vars(); # clear outside interference
}
use strict;
use warnings;

use File::Slurper qw(read_text);
use File::Temp qw/tempfile tempdir/;
my ($f0path, $f1path);
BEGIN {
    my ($fh);
    ($fh, $f0path) = tempfile();
    ($fh, $f1path) = tempfile();
    # untaint
    ($f0path) = $f0path =~ /(.*)/;
    ($f1path) = $f1path =~ /(.*)/;
}

use Log::Any::App '$log',
    -screen => 0,
    -category_alias => { -a1 => [qw/Foo::Bar Bar::Baz/] },
    -category_level => { -a1 => 'off' },
    -file => [
        { path => $f0path, pattern_style => 'plain', level=>'debug',
          category_level => { Foo => 'off', 'Bar::Baz::Qux' => 'trace' } },
        { path => $f1path, pattern_style => 'plain', level=>'error',
          category_level => { Bar => 'trace', 'Foo::Bar::Baz' => 'fatal' } },
    ];

use Test::More tests => 2;

package Foo;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package Foo::Bar;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package Foo::Bar::Baz;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package Bar;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package Bar::Baz;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package Bar::Baz::Qux;
use Log::Any::IfLOG '$log';
sub f {
    my $p = __PACKAGE__;
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
package main;
sub f {
    my $p = "main";
    $log->trace("(t,$p)"); $log->debug("(d,$p)"); $log->info ("(i,$p)");
    $log->warn ("(w,$p)"); $log->error("(e,$p)"); $log->fatal("(f,$p)");
}
f();
Foo::f();
Foo::Bar::f();
Foo::Bar::Baz::f();
Bar::f();
Bar::Baz::f();
Bar::Baz::Qux::f();

#print "f1:\n", read_text($f0path),"\n";
#print "f2:\n", read_text($f1path),"\n";

# general level         : warn
# general category_level: Foo::Bar=>off, Bar::Baz=>off
# FILE0 level           : debug
# FILE0 category_level  : Foo=>off, Bar::Baz::Qux => trace
# FILE1 level           : error
# FILE1 category_level  : Bar=>trace, Foo::Bar::Baz => fatal

my $f0content = join(
    "",
    # main = debug
    "(d,main)(i,main)(w,main)(e,main)(f,main)",
    # Foo = off (from general category_level)
    # Bar = debug (from FILE0 level)
    "(d,Bar)(i,Bar)(w,Bar)(e,Bar)(f,Bar)",
    # Bar::Baz = off (from general category_level)
    # Bar:Baz::Qux = trace (from FILE0 category_level)
    "(t,Bar::Baz::Qux)(d,Bar::Baz::Qux)(i,Bar::Baz::Qux)(w,Bar::Baz::Qux)(e,Bar::Baz::Qux)(f,Bar::Baz::Qux)",
);

my $f1content = join(
    "",
    # main = error
    "(e,main)(f,main)",
    # Foo = error (from FILE1 level)
    "(e,Foo)(f,Foo)",
    # Foo::Bar = off (from general category_level)
    # Foo::Bar::Baz = fatal (from FILE1 category_level)
    "(f,Foo::Bar::Baz)",
    # Bar = trace (from FILE1 category_level)
    "(t,Bar)(d,Bar)(i,Bar)(w,Bar)(e,Bar)(f,Bar)",
    # Bar::Baz = off (from general category_level)
);

is(read_text($f0path), $f0content, "FILE0");
is(read_text($f1path), $f1content, "FILE1");
