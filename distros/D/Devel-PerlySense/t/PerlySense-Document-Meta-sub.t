#!/usr/bin/perl -w
use strict;

use Test::More tests => 22;
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

is(scalar(@{$oMeta->raLocationSub}), 33, " Correct number of pod chunks found");

my $oLocation;

ok($oLocation = $oMeta->raLocationSub->[3], "Got a POD chunk (head1 inside pod)");
is($oLocation->row, 314, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{nameSub}, "SaveAs", "  nameSub");
is($oLocation->rhProperty->{namePackage}, "Win32::Word::Writer", "  namePackage");
is($oLocation->rhProperty->{source}, q'sub SaveAs {
    my $self = shift;
    my ($file, %hOpt) = @_;
    my $format = $hOpt{format} || "Document";

    defined(my $formatConst = $self->rhConst->{"wdFormat$format"}) or croak("Invalid format ($format), use Document, DOSText, DOSTextLineBreaks, EncodedText, HTML, RTF, Template, Text, TextLineBreaks, UnicodeText");

    $file = File::Spec->rel2abs($file);

    eval { $self->oDocument->SaveAs({ FileName => $file, FileFormat => $formatConst }) };
    if($@) {
        my $err = $@;
        if($err =~ /OLE exception from "Microsoft Word":\n\n(.+?)\nWin32::OLE/si) {
            die("Could not save file ($file): $1\n");
        }
        die($err);
    }

    return(1);
}', "  sourceSub");
is($oLocation->rhProperty->{oLocationEnd}->row, 333, "  end row");
is($oLocation->rhProperty->{oLocationEnd}->col, 2, "  end col");




ok($oLocation = $oMeta->raLocationSub->[32], "Got a POD chunk (head1 inside pod)");
is($oLocation->row, 1031, "  row");
is($oLocation->col, 1, "  col");
is($oLocation->rhProperty->{nameSub}, "DESTROY", "  nameSub");
is($oLocation->rhProperty->{namePackage}, "Win32::Word::Writer", "  namePackage");
is($oLocation->rhProperty->{source}, q/sub DESTROY {
    my $self = shift;
    $self->oTable(undef);

    $self->oWord->{DisplayAlerts} = $rhConst->{wdAlertsNone};
    $self->MarkDocumentAsSaved();        ##workaround: wdAlertsNone doesn't work in Word2000 so we insist that the document is already saved to avoid the dialog box

    $self->oWord->Quit();
    $self->oWord(undef);        #This destroys the OLE object

    #Save after quitting to keep Word from locking the file
    if($self->fileTemp and -e $self->fileTemp) {
        unlink($self->fileTemp) or ($^W and warn("Could not delete temp file (" . $self->fileTemp . "): $!\n"));
    }
}/, "  sourceSub");
is($oLocation->rhProperty->{oLocationEnd}->row, 1045, "  end row");
is($oLocation->rhProperty->{oLocationEnd}->col, 2, "  end col");






#print Dumper($oMeta);



__END__
