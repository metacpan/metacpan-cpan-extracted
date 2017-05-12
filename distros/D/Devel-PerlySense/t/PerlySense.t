#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib", "lib";



use_ok("Devel::PerlySense");

ok(my $oPs = Devel::PerlySense->new(), "new ok");
isa_ok($oPs->oProject, "Devel::PerlySense::Project", "  oProject property");
isa_ok($oPs->oHome, "Devel::PerlySense::Home", "  oHome property");


is($oPs->fileFromModule("Foo"), "Foo.pm", "fileFromModule ok");
is($oPs->fileFromModule("Foo::Bar"), catfile("Foo", "Bar") . ".pm", "fileFromModule ok");
is($oPs->fileFromModule("Foo::Bar::Baz"), catfile("Foo", "Bar", "Baz") . ".pm", "fileFromModule ok");



__END__
