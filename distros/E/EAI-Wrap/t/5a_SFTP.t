# to use these testcases, activate a local SFTP service, create $ENV{EAI_WRAP_CONFIG_PATH}."/Test/site.config with a user/pwd in the prefix sftp there and set env variable EAI_WRAP_AUTHORTEST.
use strict; use warnings;
use EAI::FTP; use Test::More; use Test::File; use File::Spec; use Data::Dumper;

if ($ENV{EAI_WRAP_AUTHORTEST}) {
	plan tests => 13;
} else {
	plan skip_all => "tests not automatic in non-author environment";
}
chdir "./t";
my $sshExecutable = 'C:/dev/EAI/putty/PLINK.EXE';
my $filecontent = "skipped line\nID1\tID2\tName\tNumber\n234234\t2\tFirstLast2\t123123.0\n543453\t1\tFirstLast1\t546123.0\n";
open (FH,">test.txt");
print FH $filecontent;
close FH;

open (LOGCONF, ">log.config");
print LOGCONF "log4perl.rootLogger = ERROR, SCREEN\nlog4perl.appender.SCREEN=Log::Log4perl::Appender::Screen\nlog4perl.appender.SCREEN.layout = PatternLayout\nlog4perl.appender.SCREEN.layout.ConversionPattern = %d	%P	%p	%M-%L	%m%n\n";
close LOGCONF;
Log::Log4perl::init("log.config"); 

my %config;
my $siteCONFIGFILE;
open (CONFIGFILE, "<$ENV{EAI_WRAP_CONFIG_PATH}/Test/site.config") or die("couldn't open $ENV{EAI_WRAP_CONFIG_PATH}/Test/site.config");
{
	local $/=undef;
	$siteCONFIGFILE = <CONFIGFILE>;
	close CONFIGFILE;
}
unless (my $return = eval $siteCONFIGFILE) {
	die("Error parsing config file: $@") if $@;
	die("Error executing config file: $!") unless defined $return;
	die("Error executing config file") unless $return;
}

# 1
my ($ftpHandle, $ftpHost);
login({remoteHost => {Prod => "unknown", Test => "unknown"}, sshInstallationPath => $sshExecutable, maxConnectionTries => 2,privKey => "",FTPdebugLevel => 0,user => "", pwd => ""},{env => "Test"});
($ftpHandle, $ftpHost) = getHandle();
ok(!defined($ftpHandle),"expected login failure");

# 2
login({remoteHost => {Prod => "localhost",Test => "localhost"}, sshInstallationPath => $sshExecutable, maxConnectionTries => 2,privKey => "",FTPdebugLevel => 0,hostkey => $config{sensitive}{sftp}{hostkey},user => $config{sensitive}{sftp}{user}, pwd => $config{sensitive}{sftp}{pwd}},{env => "Test"});
($ftpHandle, $ftpHost) = getHandle();
ok(defined($ftpHandle) && $ftpHost eq "localhost","login success");
setHandle($ftpHandle) or print "error: $@";

# create an archive dir
$ftpHandle->mkdir("Archive");
$ftpHandle->mkdir("relativepath");

# 3
putFile({remoteDir => "/relativepath", dontUseTempFile=>1},{fileToWrite => "test.txt"});
my $fileUploaded1 = $ftpHandle->ls(".", wanted => qr/test\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok($fileUploaded1->[0] eq "test.txt","test.txt uploaded file relativepath");

# 4
putFile({remoteDir => "/relativepath", dontMoveTempImmediately=>1},{fileToWrite => "test.txt"});
my $fileUploaded2 = $ftpHandle->ls(".", wanted => qr/temp\.test\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok($fileUploaded2->[0] eq "temp.test.txt","test.txt uploaded temp file relativepath");

# 5
putFile({remoteDir => "/",dontMoveTempImmediately =>1},{fileToWrite => "test.txt"});
my $fileUploaded3 = $ftpHandle->ls(".", wanted => qr/temp\.test\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok($fileUploaded3->[0] eq "temp.test.txt","test.txt uploaded temp file");
unlink "test.txt",

# 6
moveTempFile({remoteDir => "."},{fileToWrite => "test.txt"});
my $fileMoved = $ftpHandle->ls(".", wanted => qr/^test\.txt$/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok($fileMoved->[0] eq "test.txt","test.txt renamed temp file");

# 7
my @retrieved;
fetchFiles({remoteDir => "",localDir => "."},{retrievedFiles=>\@retrieved},{fileToRetrieve => "test.txt"});
ok($retrieved[0] eq "test.txt","retrieved file in returned array");
# 8
file_contains_like("test.txt",qr/$filecontent/,"test.txt downloaded file");

# 9
my @retrieved2;
fetchFiles({remoteDir => "",localDir => "."},{retrievedFiles=>\@retrieved2},{fileToRetrieve => "relativepath/*.txt"});
ok($retrieved2[0] eq "temp.test.txt","retrieved file in returned array");
# 10
ok($retrieved2[1] eq "test.txt","retrieved file in returned array");

# 11
archiveFiles({remoteDir => "", archiveDir => "Archive", timestamp => "date_time.", filesToArchive => ["test.txt"]});
my $fileArchived = $ftpHandle->ls("Archive", wanted => qr/date_time\.test\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok($fileArchived->[0] eq "date_time.test.txt","test.txt archived file to date_time.test.txt");

# 12
removeFiles({remoteDir => "relativepath", filesToRemove => ["temp.test.txt", "test.txt"]});
my $fileExisting1 = $ftpHandle->ls(".", wanted => qr/.*\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok(@$fileExisting1 == 0, "removeFiles removed multiple files");

# 13
removeFilesOlderX({remoteDir => "/", remove => {removeFolders => ["Archive"], day=>-1, mon=>0, year=>0},});
# we're still in Archive, so ls "."
my $fileExisting2 = $ftpHandle->ls(".", wanted => qr/date_time\.test\.txt/, names_only => 1) or die "unable to retrieve directory: ".$ftpHandle->error;
ok(@$fileExisting2 == 0,"removeFilesOlderX removed file");

# cleanup
$ftpHandle->setcwd(undef);
$ftpHandle->rmdir("Archive") or print "error: $@";
$ftpHandle->rmdir("relativepath") or print "error: $@";
unlink "test.txt";
unlink "temp.test.txt";
unlink "log.config";
done_testing();