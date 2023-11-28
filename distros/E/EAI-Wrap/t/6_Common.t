use strict; use warnings; use Data::Dumper;
use EAI::Common; use EAI::DateUtil; use Test::More; use Test::File; use File::Spec;
use Test::More tests => 23;

require './t/setup.pl';
chdir "./t";
our %config = (sensitive => {db => {user => "sensitiveDBuserInfo", pwd => "sensitiveDBPwdInfo"},ftp => {user => {Test => "sensitiveFTPuserInfo", Prod => ""}, pwd => {Test => "sensitiveFTPPwdInfo", Prod => ""}}}, FTP => {ftpprefix => {remoteHost => "theRemoteHost"},}, DB => {dbprefix => {DSN => {Test => "theSetDSN", Prod=>""}}});
our %execute = (env => "Test");

# 1 sensitive info direct set
is(getKeyInfo("db","user","sensitive"),"sensitiveDBuserInfo","sensitive info direct set");

# 2 sensitive info environment lookup
is(getKeyInfo("ftp","pwd","sensitive"),"sensitiveFTPPwdInfo","sensitive info environment lookup");

# 3 merge configs
$config{process} = {uploadCMD => "testcmd",};
%common = (process => {uploadCMDPath => "path_to_testcmd"});
# first prevents inheritance from %common (but NOT from %config!), second inherits from %common
@loads = ({process_ => {}},{process => {uploadCMDLogfile => "testcmd.log"}});
my @loads_expected=({process=>{uploadCMDPath=>undef,uploadCMD=>'testcmd'},File=>{},DB=>{},FTP=>{ftpprefix=>{remoteHost=>'theRemoteHost'}},DB=>{dbprefix=>{DSN=>{Test =>'theSetDSN', Prod=>''}}}},{process=>{uploadCMDPath=>'path_to_testcmd',uploadCMD=>'testcmd',uploadCMDLogfile=>'testcmd.log'},File=>{},DB=>{},FTP=>{ftpprefix=>{remoteHost=>'theRemoteHost'}},DB=>{dbprefix=>{DSN=>{Test =>'theSetDSN', Prod=>''}}}});
setupConfigMerge();
is_deeply(\@loads,\@loads_expected,"merge configs");

# 4 command line parsing into common
@ARGV = ('--process','uploadCMD=testcmd from opt','--load0process','uploadCMDPath=path_to_testcmd from opt');
getOptions();
is($opt{process}{uploadCMD},"testcmd from opt","command line parsing into common");

# 5 command line parsing into loads
is($optload[0]{process}{uploadCMDPath},"path_to_testcmd from opt","command line parsing into loads");

# 6 testcmd from opt
setupConfigMerge(); # need to call merge again to bring options into config
is($common{process}{uploadCMD},"testcmd from opt","command line parsing into common in config");

# 7 path_to_testcmd from opt
is($loads[0]{process}{uploadCMDPath},"path_to_testcmd from opt","command line parsing into loads in config");

# 8 extractConfigs
my ($process) = extractConfigs("",\%common,"process");
my $process_expected = {uploadCMDPath=>'path_to_testcmd',uploadCMD=>'testcmd from opt'};
is_deeply($process,$process_expected,"extractConfigs");

# 9 detected invalid key in hash
$config{invalid} = "invalid key";
is(checkHash(\%config,"config"),0,"detected invalid key in hash");

# 10 invalid key exception thrown
like($@, qr/key name not allowed: \$config\{invalid\}/, "invalid key exception");
delete $config{invalid};  # remove otherwise this will be potentially thrown below...

# 11 detected invalid key value in hash
$config{smtpTimeout} = "invalid value";
is(checkHash(\%config,"config"),0,"detected invalid key value in hash");

# 12 invalid key value exception thrown
like($@, qr/wrong non-numeric type for value: \$config\{smtpTimeout\}/, "invalid key value exception");
$config{smtpTimeout} = 60; # reset to correct type otherwise this will be thrown below...

# 13 detected invalid key reference value in hash
$config{logRootPath} = "invalid value";
is(checkHash(\%config,"config"),0,"detected invalid key reference value in hash");

# 14 invalid key reference value exception thrown
like($@, qr/wrong reference type for value: \$config\{logRootPath\}/, "invalid key reference value exception");
$config{logRootPath} = {}; # reset to correct type otherwise this will be thrown below...

# 15 checkParam found $process{uploadCMDPath}
is(checkParam($process,"uploadCMDPath"),1,"checkParam found \$process{uploadCMDPath}");

# 16 checkParam didn't find $process{uploadCMDPaht}
is(checkParam($process,"uploadCMDPaht"),0,"checkParam didn't find \$process{uploadCMDPaht}");

# 17 checkParam didn't find anything in undefined hash
my %DB;
is(checkParam(\%DB,"irrelevant"),0,"checkParam didn't find anything in undefined hash");

# 18 no starting condition exit
is(checkStartingCond(\%common),0,"no starting condition exit");

# 19 starting condition exit because holiday
sub testCalSpecial {
	return 1;
}
addCalendar("TEST",{},{},\&testCalSpecial);
$common{task}{skipHolidays} = "TEST";
is(checkStartingCond(\%common),1,"starting condition exit because holiday");

# 20 detected invalid key value in hash having alternative type
$config{executeOnInit} = 1;
is(checkHash(\%config,"config"),0,"detected invalid key value in hash having alternative type");

# 21 invalid key value exception thrown
like($@, qr/wrong numeric type for value: \$config\{executeOnInit\}/, "invalid key value exception");

# 22 ftpprefix info direct set
is(getKeyInfo("ftpprefix","remoteHost","FTP"),"theRemoteHost","remoteHost info set via ftpprefix");

# 23 dbprefix info direct set, regarding environment
is(getKeyInfo("dbprefix","DSN","DB"),"theSetDSN","DSN info set via dbprefix regarding environment");


unlink "config/site.config";
unlink "config/log.config";
rmdir "config";
done_testing();