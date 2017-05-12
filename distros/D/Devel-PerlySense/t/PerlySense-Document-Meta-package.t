#!/usr/bin/perl -w
use strict;

use Test::More tests => 11;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");


my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer/Table.pm";

is($oDocument->oMeta, undef, " oDocument is ok");
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");
is($oDocument->file, $fileOrigin, " file set ok");
isnt($oDocument->oDocument, undef, " oDocument is ok");
isnt($oDocument->oMeta, undef, " oDocument is ok");


my $oMeta = $oDocument->oMeta;

is(scalar(@{$oMeta->raPackage}), 1, " correct no of package declarations");
is($oMeta->raPackage->[0]->namespace, "Win32::Word::Writer::Table", " correct namespace");




__END__
