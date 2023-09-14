use strict; use warnings; use Data::Dumper;
use EAI::Common; use Test::More; use Test::File; use File::Spec;
use Test::More tests => 19;

require './t/setup.pl';
chdir "./t";
our %config = (sensitive => {db => {user => "sensitiveDBuserInfo", pwd => "sensitiveDBPwdInfo"},ftp => {user => {Test => "sensitiveFTPuserInfo", Prod => ""}, pwd => {Test => "sensitiveFTPPwdInfo", Prod => ""}}});
our %execute = (env => "Test");

# 1 sensitive info direct set
is(getSensInfo("db","user"),"sensitiveDBuserInfo","sensitive info direct set");

# 2 sensitive info environment lookup
is(getSensInfo("ftp","pwd"),"sensitiveFTPPwdInfo","sensitive info environment lookup");

# 3 merge configs
$config{process} = {uploadCMD => "testcmd",};
%common = (process => {uploadCMDPath => "path_to_testcmd"});
# first prevents inheritance from %common (but NOT from %config!), second inherits from %common
@loads = ({process_ => {}},{process => {uploadCMDLogfile => "testcmd.log"}});
my @loads_expected=({process=>{uploadCMDPath=>undef,uploadCMD=>'testcmd'},File=>{},DB=>{},FTP=>{}},{process=>{uploadCMDPath=>'path_to_testcmd',uploadCMD=>'testcmd',uploadCMDLogfile=>'testcmd.log'},File=>{},DB=>{},FTP=>{}});
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
like($@, qr/key name not allowed: \$config\{invalid\}, when calling/, "invalid key exception");
delete $config{invalid};

# 11 detected invalid key value in hash
$config{smtpTimeout} = "invalid value";
is(checkHash(\%config,"config"),0,"detected invalid key value in hash");

# 12 invalid key value exception thrown
like($@, qr/wrong type for value: \$config\{smtpTimeout\}, when calling/, "invalid key value exception");
$config{smtpTimeout} = 60;

# 13 detected invalid key reference value in hash
$config{logRootPath} = "invalid value";
is(checkHash(\%config,"config"),0,"detected invalid key reference value in hash");

# 14 invalid key reference value exception thrown
like($@, qr/wrong reference type for value: \$config\{logRootPath\}:/, "invalid key reference value exception");

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
$common{task}{skipHolidays} = "TEST";
is(checkStartingCond(\%common),1,"starting condition exit because holiday");


unlink "config/site.config";
unlink "config/log.config";
rmdir "config";
done_testing();