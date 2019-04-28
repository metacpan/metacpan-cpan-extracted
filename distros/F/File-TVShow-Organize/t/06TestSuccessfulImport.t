use strict;
use warnings;

use Test::More;
use Cwd;
use File::chdir;

my $file;
my $outputPath;
my $inputPath = "t/test-data/";

subtest "Check Folders. Verify import of files to their correct destinations" => sub {

$outputPath = "t/TV Shows/The Flash 2014/Season2/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "the.flash.2014.S02E09.hdtv-lol-eng.srt", "the.flash.2014.S02E09.hdtv-lol-eng.srt found in $outputPath");
ok(-e $file . "The.Flash.2014.S02E09.720p.HDTV.X264-DIMENSION[eztv].mkv", "The.Flash.2014.S02E09.720p.HDTV.X264-DIMENSION[eztv].mkv found in $outputPath");
ok(-e $file . "the.flash.2014.S02E09.hdtv-lol.mp4", "the.flash.2014.S02E09.hdtv-lol.mp4 found in $outputPath");
ok(-e $file . "the.flash.2014.S02E09.hdtv-por.srt", "the.flash.2014.S02E09.hdtv-por.srt found in $outputPath");

$outputPath = "t/TV Shows/Doctor Who (2005)/Specials/";
$file = getcwd . "/" . $outputPath;

ok(-e $file . "Doctor.Who.2005.S00E01.avi", "Doctor.Who.2005.S00E01.avi found in $outputPath");
ok(!-e $file . "Doctor.Who.2005.2014.Christmas.Special.Last.Christmas.720p.HDTV.x264-FoV.mkv", "Doctor.Who.2005.2014.Christmas.Special.Last.Christmas.720p.HDTV.x264-FoV.mkv was not processed");

$outputPath = "t/TV Shows/Luther/Specials/";
$file = getcwd . "/" . $outputPath;

ok(-e $file . "Luther-S00E06-The.Journey.So.Far.mp4", "Luther-S00E06-The.Journey.So.Far.mp4 found in $outputPath");
ok(-e $file . "Luther-S00E06-The.Journey.So.Far.srt", "Luther-S00E06-The.Journey.So.Far.srt found in $outputPath");

$outputPath = "t/TV Shows/S.W.A.T 2017/Season1/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "S.W.A.T.2017.S01E01.avi", "S.W.A.T.2017.S01E01.avi found in $outputPath");

};

subtest "Test that files have been renamed with an appended .done" => sub {
$outputPath = "t/test-data/done_list/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "S.W.A.T.2017.S01E01.avi.done", "S.W.A.T.2017.S01E01.avi.done was successfully imported and renamed.");
ok(-e $file . "the.flash.2014.S02E09.hdtv-lol-eng.srt.done", "the.flash.2014.S02E09.hdtv-lol-eng.srt.done was successfully imported and renamed.");
ok(-e $file . "Doctor.Who.2005.Special.The.Women.of.Doctor.Who.HDTV.x264-2HD.[VTV].mp4", "Doctor.Who.2005.Special.The.Women.of.Doctor.Who.HDTV.x264-2HD.[VTV].mp4 was not renamed. Was ignored as required.");
};

subtest "Recursion is disabled" => sub {
$outputPath = $outputPath . "test/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "true.blood.S01E01.avi", "true.blood.S01E01.avi was not processed as its in a sub folder. Recurusion not enabled.")
};

subtest "Test that processed files have been deleted." => sub {
$outputPath = "t/test-data/delete_list/";
$file = getcwd . "/" . $outputPath;

ok(!-e $file . "Luther-S00E06-The.Journey.So.Far.mp4", "Luther-S00E06-The.Journey.So.Far.mp4 has been unlinked.");
ok(!-e $file . "Luther-S00E06-The.Journey.So.Far.srt", "Luther-S00E06-The.Journey.So.Far.srt has been unlinked.");
ok(!-e $file . "Supergirl.S01E04.720p.HDTV.X264-DIMENSION[eztv].mkv", "Supergirl.S01E04.720p.HDTV.X264-DIMENSION[eztv].mkv has been unlinked.");
ok(!-e $file . "supergirl.S01E07.hdtv-lol[ettv].mp4", "supergirl.S01E07.hdtv-lol[ettv].mp4 has been unlinked.");
ok(-e $file . "S.W.A.T.2018.S01E01.avi", "S.W.A.T.2018.S01E01.avi has not been unlinked. It was not processed");

};

subtest "Test files not deleted as recursion is disabled" => sub {
$outputPath = $outputPath . "test/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "true.blood.S02E01.avi", "true.blood.S02E01.avi was not processed as recursion is disabled.");
};

subtest "Test seasonFolder option as false. Do not create season Folders " => sub {

$outputPath = "t/TV Shows/Winter/";
$file = getcwd . "/" . $outputPath;
ok(-e $file . "Winter.S01E01.avi", "Winter.S01E01.avi is found in $outputPath");
ok(-e $file . "Winter.S02E01.avi", "Winter.S02E01.avi is found in $outputPath");
};

done_testing();
