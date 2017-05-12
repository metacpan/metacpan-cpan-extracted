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
my $dbh    = $schema->storage->dbh;

# from Foorum v0.2.9 on,
# we have a new table security_code

my $sql = q~CREATE TABLE `security_code` (
`security_code_id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY ,
`user_id` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0',
`type` TINYINT( 1 ) UNSIGNED NOT NULL DEFAULT '0',
`code` VARCHAR( 12 ) NOT NULL ,
`time` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0'
);~;
$dbh->do($sql) or die $DBI::errstr;

print "Done\n";

1;
