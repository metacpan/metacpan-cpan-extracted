#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

#use Carp::Always;

use lib "lib";
use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");
use_ok("Devel::PerlySense::Plugin::Syntax::Moose");


ok(my $oMeta = Devel::PerlySense::Document::Meta->new, "Created meta object ok");

is(
    scalar $oMeta->aPluginSyntax,
    1,
    "Found one plugin",
);
isa_ok(($oMeta->aPluginSyntax)[0], "Devel::PerlySense::Plugin::Syntax::Moose");




__END__
