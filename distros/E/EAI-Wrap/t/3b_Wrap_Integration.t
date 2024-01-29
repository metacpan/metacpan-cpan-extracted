sub INIT {
	use Test::More;
	if ($ENV{EAI_WRAP_AUTHORTEST}) {
		plan tests => 15;
	} else {
		plan skip_all => "tests not automatic in non-author environment";
	}
}
# to use these testcases, activate a local SFTP service and create $ENV{EAI_WRAP_CONFIG_PATH}."/t/site.config with a user/pwd in the prefix sftp there and set env variable EAI_WRAP_AUTHORTEST.
# following content of site.config is required:
#%config = (
#	sensitive => {sftp => {user => "yourSFTPUser", pwd => "yourSFTPUserPwd", privKey=>'yourPrivateKeyFileIfNeeded', hostkey=>'yourHostKeyIfNeeded'},},
#	checkLookup => {"3b_Wrap_Integration.tAddSuffix" => {errmailaddress => "foundEmailAddress"}},
#	executeOnInit => '$execute{addToScriptName} = "AddSuffix";',
#	or executeOnInit => sub {$execute{addToScriptName} = "AddSuffix";'},
#	folderEnvironmentMapping => {t => "t",},
#	errmailaddress => 'yourMailAddress',
#	errmailsubject => "No errMailSubject defined",
#	fromaddress => 'yourMailAddress',
#	smtpServer => "yourSMTPServer",
#	smtpTimeout => 60,
#	testerrmailaddress => 'yourMailAddress',
#	logRootPath => {"" => "yourLogPath",},
#	historyFolder => {"" => "History",},
#	historyFolderUpload => {"" => "HistoryUpload",},
#	redoDir => {"" => "redo",},
#	task => {
#		redoTimestampPatternPart => '[\d_]',
#		retrySecondsErr => 60*5, # 5 minutes pause with error retries
#		retrySecondsXfails => 2, # fail count after which the retrySecondsErr are changed to retrySecondsErrAfterXfails
#		retrySecondsPlanned => 60*15, # 15 minutes pause with planned retries
#		skipHolidaysDefault => "AT",
#	},
#	DB => {
#		server => {t => "yourDBServer(e.g. localhost)"},
#		database => "yourDBServerDatabase(e.g. testDB)",
#		DSN => 'driver={SQL Server};Server=$DB->{server}{$execute{env}};database=$DB->{database};TrustedConnection=Yes;',
#		schemaName => "dbo", # default schema name (especially important for MS SQL Server)
#	},
#	FTP => {
#		port => yourPort,
#		remoteHost => {t => "yourFTPHost"},
#		maxConnectionTries => 5, # try at most to connect maxConnectionTries, then give up
#		sshInstallationPath => "yourPathToPLINK.EXE", # path to external ssh executable for NET::SFTP::Foreign
#	},
#);

# also create a database testDB in the local sql server instance where the current account has dbo rights (tables are created/dropped)
use strict; use warnings;
use EAI::Wrap; use Archive::Zip qw( :ERROR_CODES :CONSTANTS ); use Test::File; use File::Spec; use Test::Timer; use Data::Dumper;
chdir "./t";

# set up EAI::Wrap definitions
%common = (
	DB => {longreadlen => 1024,schemaName => "dbo",DSN => 'driver={SQL Server};Server='.$config{DB}{server}{t}.';database='.$config{DB}{database}.';TrustedConnection=Yes;',primkey => "col1 = ?",tablename => "theTestTable",},
);
@loads = (
	{
		File => {localFilesystemPath => ".",dontKeepHistory => 1,filename => "test.zip",extract => 1,format_sep => qr/\t/,format_skip => 1,format_header => "col1	col2	col3",},
	},
	{
		DB => {query => "select * from theTestTable"},
		FTP => {remoteDir=>"",FTPdebugLevel=>0,prefix=>"sftp",dontUseTempFile=>1,fileToRemove=>1,SFTP=>1},
		File => {filename => "testTarget.txt",dontKeepHistory => 1,format_sep => "\t",format_skip => 2,format_header => "col1	col2	col3",},
	},
);
setupEAIWrap();

# set up DB environment for tests
openDBConn(\%common);
my ($dbHandle, $DSN) = getConn();
# 1
is(ref($dbHandle),"DBI::db","\$dbHandle set as expected");
# 2
is($DSN,'driver={SQL Server};Server='.$common{DB}{server}{$execute{env}}.';database='.$common{DB}{database}.';TrustedConnection=Yes;','$DSN set as expected');
doInDB({doString => "IF OBJECT_ID('dbo.theTestTable', 'U') IS NOT NULL DROP TABLE [dbo].[theTestTable];"});
my $createStmt = "CREATE TABLE [dbo].[theTestTable]([col1] [varchar](5) NOT NULL,[col2] [varchar](5) NOT NULL,[col3] [varchar](5) NOT NULL, CONSTRAINT [PK_theTestTable] PRIMARY KEY CLUSTERED (col1 ASC)) ON [PRIMARY]";
# 3
is(doInDB({doString => $createStmt}),1,'doInDB');

# create files for tests
my $expected_filecontent = "col1\tcol2\tcol3\nval11\tval21\tval31\nval12\tval22\tval32\n";
my $expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
my $zip = Archive::Zip->new();
my $string_member = $zip->addString($expected_filecontent, 'testContent.txt');
$string_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
die 'ziptest prepare error' unless ($zip->writeToFileNamed('test.zip') == AZ_OK);

my $result = getLocalFiles($loads[0]);;
# 4
is($result,1,"getLocalFiles \$loads[0] successful");
# 5
file_exists_ok("testContent.txt","extractArchives testContent.txt");
# 6
file_contains_like("testContent.txt",qr/$expected_filecontent/,"extractArchives testContent.txt expected content");
# 7
is_deeply($loads[0]{process}{filenames}, ["testContent.txt"], "extractArchives \$process{filenames} testContent.txt");
# 8
is_deeply($loads[0]{process}{archivefilenames}, ["test.zip"], "extractArchives \$process{archivefilenames} test.zip");
# 9
is_deeply($execute{retrievedFiles}, [], "extractArchives \$execute{retrievedFiles} empty");
readFileData($loads[0]);
# 10
is_deeply($loads[0]{process}{data},$expected_datastruct,"readFileData expected content");

dumpDataIntoDB($loads[0]);
markProcessed($loads[0]);

writeFileFromDB($loads[1]);
# 11
file_exists_ok("testTarget.txt","writeFileFromDB testTarget.txt");
# 12
file_contains_like("testTarget.txt",qr/$expected_filecontent/,"testTarget.txt expected content");

openFTPConn($loads[1]);
uploadFileToFTP($loads[1]);
$result = getFilesFromFTP($loads[1]);
# 13
is($result,1,"openFTPConn, uploadFileToFTP and getFilesFromFTP \$loads[1] successful");
markProcessed($loads[1]);
processingEnd();

# 14
is($execute{addToScriptName},"AddSuffix","addToScriptName set by executeOnInit");

# 15
is($config{checkLookup}{"3b_Wrap_Integration.tAddSuffix"}{"errmailaddress"},"foundEmailAddress","checkLookup working with set \$execute{addToScriptName}");


unlink "test.zip";
unlink "testContent.txt";
unlink "3b_Wrap_Integration.t.log";
done_testing();