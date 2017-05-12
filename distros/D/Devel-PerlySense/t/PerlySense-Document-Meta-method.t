#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");


my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

my $oMeta = $oDocument->oMeta;

is(scalar(keys %{$oMeta->rhRowColMethod}), 31, " found correct number of methods");

is($oMeta->rhRowColMethod->{126}->{30}->{oNode} . "", "raBodyLocation", " got method");
is($oMeta->rhRowColMethod->{126}->{30}->{oNodeObject} . "", '$self', " got method invocant");

is($oMeta->rhRowColMethod->{149}->{22}->{oNode} . "", "SUPER::new", " got super method");
is($oMeta->rhRowColMethod->{149}->{22}->{oNodeObject} . "", '$pkg', " got method invocant");

is($oMeta->rhRowColMethod->{149}->{50}->{oNode} . "", "new", " got nested method");
is($oMeta->rhRowColMethod->{149}->{50}->{oNodeObject} . "", 'Game::Location', " got module invocant");

is($oMeta->rhRowColMethod->{259}->{31}->{oNode} . "", "direction", " got chained method");
is($oMeta->rhRowColMethod->{259}->{31}->{oNodeObject} . "", 'oDirection', " got method invocant");





is($oMeta->rhRowColMethod->{126}->{25}, undef, " no module at self");

#print join(", ", keys %{$oMeta->rhRowColMethod}) . "\n";



__END__
