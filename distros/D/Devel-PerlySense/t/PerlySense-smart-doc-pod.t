#!/usr/bin/perl -w
use strict;

use Test::More tests => 55;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
my $text;
my $oLocation;
my $rex;


print "\n* Docs for method call\n";


#Should be reinstated / changed to either report the variable or not find anything at all, once variables are parsed for
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 420, col => 17), "Didn't find hOpt");
is($oLocation->file, $fileOrigin, " In correct file");
is($oLocation->row, 1, " row");
is($oLocation->col, 1, " col");



$text = q{METHODS - ADDING TEXT
  NewParagraph([heading => $level], [style => $name])
    Start a new paragraph of heading $level or with style $name. The style
    overrides heading. The style should be a paragraph style.

    The default style is "Normal".};
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 423, col => 21), "Found POD ok");
is($oLocation->rhProperty->{text}, $text, " Found POD text ok");
is($oLocation->file, $fileOrigin, " In correct file");
is($oLocation->row, 438, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{docType}, "hint", " docType method");
is($oLocation->rhProperty->{found}, "method", " docType method");
is($oLocation->rhProperty->{name}, "NewParagraph", " name");


$text = q{METHODS - ADDING TEXT
  Write($text)
    Append $text to the document (using the current style etc).};
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 429, col => 14), "Found POD ok");
is($oLocation->rhProperty->{text}, $text, " Found POD text ok");
is($oLocation->file, $fileOrigin, " In correct file");
is($oLocation->row, 391, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{docType}, "hint", " docType method");
is($oLocation->rhProperty->{found}, "method", " docType method");
is($oLocation->rhProperty->{name}, "Write", " name");



print "\n* Docs for module POD\n";


$rex = qr{Win32::Word::Writer::Table - Add tables to Word documents}s;
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 157, col => 14), "Found module POD ok");
like($oLocation->rhProperty->{text}, $rex, " Found POD text ok");
like($oLocation->file, qr/Writer.Table\.pm/, " In correct file");
is($oLocation->row, 1, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{"found"}, "module", " docType module");
is($oLocation->rhProperty->{docType}, "document", " docType module");
is($oLocation->rhProperty->{name}, "Win32::Word::Writer::Table", " name");



$rex = qr{Win32::Word::Writer - Create Microsoft Word documents}s;
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 201, col => 3), "Found nothing, in between tokens");
like($oLocation->rhProperty->{text}, $rex, " Found POD text ok");
like($oLocation->file, qr/Writer\.pm/, " In correct file");
is($oLocation->row, 1, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{"found"}, "module", " docType module");
is($oLocation->rhProperty->{docType}, "document", " docType module");
is($oLocation->rhProperty->{name}, "Win32::Word::Writer", " name");


ok( $oPs->oLocationSmartDoc(file => $fileOrigin, row => 420, col => 5234), "Didn't find anything at point at far right, returned entire POD for the file");
like($oLocation->rhProperty->{text}, $rex, " Found POD text ok");
like($oLocation->file, qr/Writer\.pm/, " In correct file");
is($oLocation->row, 1, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{"found"}, "module", " docType module");
is($oLocation->rhProperty->{docType}, "document", " docType module");
is($oLocation->rhProperty->{name}, "Win32::Word::Writer", " name");




print "\n* Docs for class method POD in base class\n";


$dirData = "data/project-lib";
$fileOrigin = "$dirData/Game/Application.pm";
my $rexFile = qr/Game.Object.Worm.pm/;

$text = q{CLASS METHODS
  loadFile($file)
    Bogus test method to have something to test with.

From <Game::Object::Worm>};
ok($oLocation = $oPs->oLocationSmartDoc(file => $fileOrigin, row => 167, col => 44), "Found POD ok");
is($oLocation->rhProperty->{text}, $text, " Found POD text ok");
like($oLocation->file, $rexFile, " In correct file");
is($oLocation->row, 355, " row");
is($oLocation->col, 1, " col");
is($oLocation->rhProperty->{docType}, "hint", " docType method");
is($oLocation->rhProperty->{found}, "method", " docType method");
is($oLocation->rhProperty->{name}, "loadFile", " name");





__END__
