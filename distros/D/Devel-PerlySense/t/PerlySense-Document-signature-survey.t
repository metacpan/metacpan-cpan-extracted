#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

is(
    $oDocument->stringSignatureSurveyFromFile(),
    q|===;;;";"";"";";";";";";";";";";";;";;";;";;;;;";;";;;";;";;;;";;;;;;";;";;;;";;";;;";;";;";==S{";};;';;;;;;;;;";;'";;=====;===S{;;;;;;;';;";";;";";;';';}=S{;;;";"'";;{'};;";;;;}=S{;;";{"}";;{};{;"{";};};}=S{;;;}=S{;;;{};;;}==S{;;;;;}=S{;;{;}{;};;;}=S{;;;;;;;}=S{;;";;;;{;};{;"{";};};}=S{";";}=S{;;;;";";}=S{;;;}=S{;;;;;}=S{;;;}=S{;;;;;}==S{;;{;}{;};;;}=S{;{;};;}=S{;;{;}{';;}{;};;;}==S{;;";;;;;}=S{;;;;}=S{;;;;}=S{;;;;";;}==S{;{};;}=S{;;;}==S{;";";;;;;;;}=S{;;{;";";};}==S{;;;;}=S{;;{};;}=S{;;;;;}==S{;;;}=SA{;"";;}=S{;;;;';;{"";}};=============;============;|,
    "Signature survey for Writer ok",
);




__END__
