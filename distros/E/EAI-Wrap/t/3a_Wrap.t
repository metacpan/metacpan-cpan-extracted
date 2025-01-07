sub INIT {require './t/setup.pl';}
use strict; use warnings;
use EAI::Wrap; use Data::Dumper; use Archive::Zip qw( :ERROR_CODES :CONSTANTS ); use File::Copy 'move';
use Test::More; use Test::File; use File::Spec; use Test::Timer;
use Test::More tests => 29;
chdir "./t";

# 1
setupEAIWrap();
is($execute{scriptname},"3a_Wrap.t","scriptname set by INIT");
my $zip = Archive::Zip->new();
my $string_member = $zip->addString('testcontent', 'testContent.txt' );
$string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
die 'ziptest prepare error' unless ($zip->writeToFileNamed('test.zip') == AZ_OK );

# 2
$common{task}{redoFile} = 1;
mkdir "redo"; mkdir "History"; mkdir "localDir";
open (TESTFILE, ">redo/test_20230101.txt");
close TESTFILE;
my %process;
redoFiles({File => {filename => "test.txt"}, process => \%process});
file_exists_ok("redo/test.txt","test.txt available for redo");
# 3
is($process{retrievedFiles}->[0],"test.txt","test.txt in retrievedFiles");
delete $process{retrievedFiles};

# 4
open (TESTFILE, ">redo/test_1.csv");
close TESTFILE;
open (TESTFILE, ">redo/test_2.csv");
close TESTFILE;
redoFiles({File => {filename => "*.csv"}, process => \%process});
is($process{retrievedFiles}->[0],"test_1.csv","test_1.csv in retrievedFiles");

# 5
is($process{retrievedFiles}->[1],"test_2.csv","test_2.csv in retrievedFiles");

# turn off redoFile to simulate getLocalFiles with redo folder as localFilesystemPath (otherwise getLocalFiles would call redoFiles)
$common{task}{redoFile} = 0;
delete $process{retrievedFiles};
$process{filenames} = ();

# 6
getLocalFiles({File => {localFilesystemPath => "redo", filename => "test.txt"}, process => \%process});
file_exists_ok("test.txt","getLocalFiles test.txt");
# 7
like($process{successfullyDone}, qr/getLocalFiles/, "getLocalFiles set \$process{successfullyDone} for reprocessing");

# 8
#checkFiles({File => {filename => "test.txt"}, process => \%process});
is_deeply($process{filenames},["test.txt"],"checkFiles test.txt");
markProcessed({File => {filename => "test.txt"}, process => \%process});

# 9
is_deeply($process{filesProcessed},{"test.txt"=>1},"markProcessed \$process{filesProcessed} test.txt");
# 10
is_deeply($execute{filesToMoveinHistory},["test.txt"],"markProcessed \$execute{filesToMoveinHistory} test.txt");

# 11
moveFilesToHistory("DefinedTimestamp");
file_not_exists_ok("test.txt","moveFilesToHistory test.txt not here");
# 12
file_exists_ok("History/test_DefinedTimestamp.txt","moveFilesToHistory test.txt moved");

delete $process{retrievedFiles};
delete $process{filenames};
$process{successfullyDone} = "";
getLocalFiles({File => {localFilesystemPath => "redo", filename => "*.csv"}, process => \%process});
# 13
file_exists_ok("test_1.csv","getLocalFiles test_1.csv");
# 14
file_exists_ok("test_2.csv","getLocalFiles test_2.csv");
# 15
delete $process{filenames};
checkFiles({File => {filename => "*.csv"}, process => \%process});
is_deeply($process{filenames},["test_1.csv","test_2.csv"],"checkFiles \$process{filenames} test_1.csv test_2.csv");

# 16
markUploadForHistoryDelete({File => {filename => "test_1.csv", dontKeepHistory => 1}});
markUploadForHistoryDelete({File => {filename => "test_2.csv", dontKeepHistory => 1}});
is_deeply($execute{filesUploadedToDelete},["test_1.csv","test_2.csv"],"processingEnd/deleteFiles \$execute{filesUploadedToDelete} test_1.csv test_2.csv");

# 17
processingEnd();
file_not_exists_ok("test_1.csv","processingEnd/deleteFiles test_1.csv not here");
# 18
is($execute{processEnd},1,"processingEnd \$execute{processEnd}");

# 19
$common{task}{redoFile} = 1; # set redoFile again to delete files in redo folder
markUploadForHistoryDelete({File => {filename => "test_1.csv", dontKeepHistory => 1}});
markUploadForHistoryDelete({File => {filename => "test_2.csv", dontKeepHistory => 1}});
deleteFiles();
file_not_exists_ok("redo/test_1.csv","deleteFiles redo/test_1.csv not here");
# 20
file_not_exists_ok("redo/test_2.csv","deleteFiles redo/test_2.csv not here");

# 21
move "redo/test.txt", ".";
putFileInLocalDir({File => {localFilesystemPath => "localDir", filename => "test.txt"}});
file_not_exists_ok("test.txt","putFileInLocalDir test.txt not here");
# 22
file_exists_ok("localDir/test.txt","putFileInLocalDir test.txt moved");

# 23
$common{task}{redoFile} = 0;
$process{retrievedFiles} =["test.zip"];
$process{filenames} = ();
extractArchives({process => \%process});
file_exists_ok("testContent.txt","extractArchives testContent.txt");
# 24
file_contains_like("testContent.txt",qr/testcontent/,"extractArchives testContent.txt content");
# 25
is_deeply($process{filenames}, ["testContent.txt"], "extractArchives \$process{filenames} testContent.txt");
# 26
is_deeply($process{archivefilenames}, ["test.zip"], "extractArchives \$process{archivefilenames} test.zip");
# 27
is_deeply($process{retrievedFiles}, [], "extractArchives \$process{retrievedFiles} empty");
# 28
my $hadDBErrors = 0;
EAI::Wrap::evalCustomCode(sub {$hadDBErrors = 1;},"evalCustomCodeTest1",\$hadDBErrors);
is($hadDBErrors,1,"evalCustomCode set \$hadDBErrors correctly with anon sub");
# 29
EAI::Wrap::evalCustomCode('$hadDBErrors = 2;',"evalCustomCodeTest2",\$hadDBErrors);
is($hadDBErrors,2,"evalCustomCode set \$hadDBErrors correctly with string eval");


unlink "test.zip";
unlink "test.txt";
unlink "testContent.txt";
unlink "localDir/test.txt";
unlink "History/test_DefinedTimestamp.txt";
rmdir "redo" or print "can't remove redo: $!\n"; rmdir "History"; rmdir "localDir";
unlink "config/site.config";
unlink "config/log.config";
rmdir "config";
done_testing();