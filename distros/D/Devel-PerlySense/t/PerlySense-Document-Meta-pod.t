#!/usr/bin/perl -w
use strict;

use Test::More tests => 27;
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


my $dirData = "data/simple-lib";
my $fileOrigin = "$dirData/lib/Win32/Word/Writer.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

my $oMeta = $oDocument->oMeta;

is(scalar(@{$oMeta->raLocationPod}), 69 + 7, " Correct number of pod chunks found");

my $oLocation;

ok($oLocation = $oMeta->raLocationPod->[3], "Got a POD chunk (head1 inside pod)");
is($oLocation->row, 106, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{podSection},
   q{},
   "  pod");
is($oLocation->rhProperty->{pod},
   q{=head1 CONCEPTS

Win32::Word::Writer uses an OLE instance of Word to create Word
documents.

The documents are constructed in a linear fashion, i.e. you add text
to the document and generally don't move around the document a lot.


},
   "  pod");



ok($oLocation = $oMeta->raLocationPod->[5], "Got a POD chunk (head1 at beginning of pod)");
is($oLocation->row, 168, "  row");
is($oLocation->rhProperty->{podSection},
   q{},
   "  pod");
is($oLocation->rhProperty->{pod},
   q{=head1 PROPERTIES

},
   "  pod");



ok($oLocation = $oMeta->raLocationPod->[7], "Got a POD chunk (head2 inside pod)");
is($oLocation->row, 175, "  row");
is($oLocation->rhProperty->{podSection},
   q{=head1 PROPERTIES

},
   "  pod");
is($oLocation->rhProperty->{pod},
   q{=head2 oDocument

A Win32::OLE object with the Application's Document object. Often used
shorthand.


},
   "  pod");



ok($oLocation = $oMeta->raLocationPod->[16], "Got a POD chunk (head2 first)");
is($oLocation->row, 365, "  row");
is($oLocation->rhProperty->{podSection},
   q{=head1 METHODS

},
   "  pod");
is($oLocation->rhProperty->{pod},
   q{=head2 Close()

Discard the current document no-questions-asked (i.e. even if it's not
saved).

Note that this object is in an unusable state until a new document is
created or opened.

},
   "  pod");



ok($oLocation = $oMeta->raLocationPod->[48], "Got a POD chunk (head2 first)");
is($oLocation->row, 981, "  row");
is($oLocation->rhProperty->{podSection},
   q{=head1 METHODS - UTILITY

},
   "  pod");
is($oLocation->rhProperty->{pod},
   q{=item MarkDocumentAsSaved()

Mark the Word document as "saved". This is in effect until
the document is changed again.

Being saved e.g. means it can be abandoned without
questions.

Return 1 on success, else die.

},
   "  pod");







#print Dumper($oMeta);



__END__
