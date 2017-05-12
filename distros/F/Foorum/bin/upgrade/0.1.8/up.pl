#!/usr/bin/perl

use strict;
use warnings;

# for both Linux/Win32
my $has_proc_pid_file
    = eval 'use Proc::PID::File; 1;';    ## no critic (ProhibitStringyEval)
my $has_home_dir
    = eval 'use File::HomeDir; 1;';      ## no critic (ProhibitStringyEval)
if ( $has_proc_pid_file and $has_home_dir ) {

    # If already running, then exit
    if ( Proc::PID::File->running( { dir => File::HomeDir->my_home } ) ) {
        exit(0);
    }
}

use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', '..', 'lib' );
use Foorum::SUtils qw/schema/;

my $schema = schema();

# from Foorum v0.1.8 on,
# we add a table 'user_online' and drop user_id in 'session' table

my $dbh = $schema->storage->dbh;
my $sql = q~CREATE TABLE IF NOT EXISTS `user_online` (
  `sessionid` varchar(72) NOT NULL default '0',
  `user_id` int(11) unsigned NOT NULL default '0',
  `path` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `start_time` int(11) unsigned NOT NULL default '0',
  `last_time` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`sessionid`),
  KEY `start_time` (`start_time`),
  KEY `last_time` (`last_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;~;
$dbh->do($sql) or die $dbh->errstr;
print "[OK]$sql\n";

$sql = q~ALTER TABLE `session` DROP `user_id`;~;
$dbh->do($sql) or die $dbh->errstr;
print "[OK]$sql\n";

$sql = q~ALTER TABLE `session` DROP `path`;~;
$dbh->do($sql) or die $dbh->errstr;
print "[OK]$sql\n";

print "Done\n";

1;
