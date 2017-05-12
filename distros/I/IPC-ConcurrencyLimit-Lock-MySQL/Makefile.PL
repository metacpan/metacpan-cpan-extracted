use 5.008001;
use ExtUtils::MakeMaker;
use strict;
use Data::Dumper;

my $conf_file = 'mysql.dat';

my $host = 'localhost';
my $port = '3306';
my $db = 'test';
my $usr = 'test';
my $pwd = 'test';

if (not -e $conf_file) {
  print <<EOFTEXT;
To test properly I will need access to a MySQL database 
with the priviledge to call GET_LOCK and RELEASE_LOCK.
To do this I will need to ask some more questions to
complete configuration.

What you answer will be stored in the file '$conf_file' 
and will not be removed unless you do a make clean, thus
you wont have to go through this process again even if you
rerun this script. If you wish to change your answer 
delete the file (or run make clean) and rerun Makefile.PL.

If you wish to set things up now the db, username, and 
password will by default be '$db', '$usr', '$pwd'.

EOFTEXT

  my $do_mysql_config = prompt "Run MySQL tests? [yes/no]", 'no';
  my @connect;
  if ($do_mysql_config=~/^y/i) {
    $db  = prompt "Please enter database name:", $db;
    $host  = prompt "Please enter hostname:", $host;
    $port  = prompt "Please enter port:", $port;
    $usr = prompt "Please enter user name to connect to $db with:", $usr;
    $pwd = prompt "Please enter password to use for $usr:", $pwd;
    push @connect, $host, $port, $db, $usr, $pwd;
  }
  open my $fh, ">", $conf_file
    or die "Cant open '$conf_file' for writing: $!";
  print $fh Data::Dumper->Dump([@connect],[qw(*host *port *db *usr *pwd)]);
  close $fh;
}



WriteMakefile(
  NAME              => 'IPC::ConcurrencyLimit::Lock::MySQL',
  VERSION_FROM      => 'lib/IPC/ConcurrencyLimit/Lock/MySQL.pm', # finds $VERSION
  PREREQ_PM         => {
    'Carp' => '0',
    'DBI' => 0,
    'DBD::mysql' => '0',
    'Class::XSAccessor' => '1.11',
    'Data::Dumper' => '0',
    'IPC::ConcurrencyLimit' => '0.01',
    'IPC::ConcurrencyLimit::Lock' => '0',
  }, # e.g., Module::Name => 1.1
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/IPC/ConcurrencyLimit/Lock/MySQL.pm', # retrieve abstract from module
      AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => "IPC-ConcurrencyLimit-Lock-MySQL-* *~ $conf_file" },
);
