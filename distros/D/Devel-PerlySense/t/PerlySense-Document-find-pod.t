#!/usr/bin/perl -w
use strict;

use Test::More tests => 44;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";
my $oLocation;

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

is($oDocument->oLocationPod(name => "sdfasjdfjasdkfj", lookFor => "method"), undef, "Didn't find missing pod line");

ok($oLocation = $oDocument->oLocationPod(name => "Close", lookFor => "method"), "Found correct POD line =head (leading in POD block)");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 365, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{pod}, q{=head1 METHODS

=head2 Close()

Discard the current document no-questions-asked (i.e. even if it's not
saved).

Note that this object is in an unusable state until a new document is
created or opened.

}, " Got POD");
is($oLocation->rhProperty->{name}, "Close", " Got name ok");
is($oLocation->rhProperty->{docType}, "hint", " Got docType ok");
is($oLocation->rhProperty->{found}, "method", " Got found ok");

ok($oLocation = $oDocument->oLocationPod(name => "Write", lookFor => "method"), "Found correct POD line (inside POD block)");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 391, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{pod}, q{=head1 METHODS - ADDING TEXT

=head2 Write($text)

Append $text to the document (using the current style etc).

}, " Got POD");
is($oLocation->rhProperty->{name}, "Write", " Got name ok");
is($oLocation->rhProperty->{docType}, "hint", " Got docType ok");
is($oLocation->rhProperty->{found}, "method", " Got found ok");


ok($oLocation = $oDocument->oLocationPod(name => "hasWrittenParagraph", lookFor => "method"), "Found correct POD line =item");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 1193, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{pod}, q{=head1 PRIVATE PROPERTIES

=over 4

=item hasWrittenParagraph

Whether the writer has written a paragraph yet.




=back
}, " Got POD");
is($oLocation->rhProperty->{name}, "hasWrittenParagraph", " Got name ok");
is($oLocation->rhProperty->{docType}, "hint", " Got docType ok");
is($oLocation->rhProperty->{found}, "method", " Got found ok");


ok($oLocation = $oDocument->oLocationPod(name => "hasWrittenText", lookFor => "method"), "Found correct POD line =item (B<>)");
is($oLocation->file, $fileOrigin, " Got file");
is($oLocation->row, 1198, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{pod}, q{=head1 PRIVATE PROPERTIES

=over 4

=item B<hasWrittenText>

Whether the writer has written any text or paragraph yet.




=back
}, " Got POD");
is($oLocation->rhProperty->{name}, "hasWrittenText", " Got name ok");
is($oLocation->rhProperty->{docType}, "hint", " Got docType ok");
is($oLocation->rhProperty->{found}, "method", " Got found ok");





note("Base classes");

$dirData = "data/project-lib";
my $rexFileDest = qr/Game.Object.Worm.pm/;

ok($oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
$fileOrigin = "$dirData/Game/Object/Worm/Bot.pm";
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");



ok(! $oDocument->oLocationPod(name => "loadFile", lookFor => "method", ignoreBaseModules => 1), "Did not find anything in current package only");



ok($oLocation = $oDocument->oLocationPod(name => "loadFile", lookFor => "method"), "Found correct POD in base package");
like($oLocation->file, $rexFileDest, " Got file");
is($oLocation->row, 355, "  row");
is($oLocation->col, 1, "  col");





__END__
