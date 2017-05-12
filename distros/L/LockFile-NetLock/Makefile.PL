use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use constant NETLOCK_CFG => 'netlock.cfg';

WriteMakefile(
    'NAME'      => 'LockFile::NetLock',
    'VERSION_FROM' => 'lib/LockFile/NetLock.pm', # finds $VERSION
    'EXE_FILES' => ['netlock'],
    'realclean' => {FILES => NETLOCK_CFG},
    INSTALLDIRS => 'site'
);

my $old_cfg_href;
if (-r NETLOCK_CFG) {
        $old_cfg_href = do &NETLOCK_CFG;
}
else {
        $old_cfg_href = {test_host => '', test_user => '', test_pass => '',
                test_dir => 'lockdir.lck'};
}

my ($ftp_server, $ftp_user, $ftp_pass, $ftp_dir);

print <<EOT;

To run the FTP locking tests we will need an FTP host and user on that host
with privileges to login and create directories.  If you have a .netrc
file with an appropriate host entry just hit enter for user name and
password and the tests will use the .netrc entry instead.  You will
now be prompted for the FTP host, user name and password.

EOT

foreach (1 .. 5) {
        $ftp_server = prompt(
                "FTP host where you have directory creation " .
                "privileges.", $old_cfg_href->{test_host}
        );
        last if gethostbyname($ftp_server);
        last if (prompt(
                "Could not verify host name - try again?(y|n)"
        ) =~ /n/i);
}
$ftp_user = prompt(
        "User name with directory creation privileges " .
        "at $ftp_server.", $old_cfg_href->{test_user}
);
$ftp_pass = prompt(
        "Enter password for $ftp_user.", $old_cfg_href->{test_pass}
);
$ftp_dir = prompt(
        "Enter test directory path.", $old_cfg_href->{test_dir}
);

if (open(FH, '>' . NETLOCK_CFG)) {
        print FH <<EOT;
{
        test_host => '$ftp_server',
        test_user => '$ftp_user',
        test_pass => '$ftp_pass',
        test_dir => '$ftp_dir'
}
EOT
        close(FH);
}
else {
        print "Could not write test configuration file\n";
}
