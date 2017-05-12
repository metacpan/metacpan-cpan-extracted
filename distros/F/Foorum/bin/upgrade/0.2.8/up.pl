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

# from Foorum v0.2.8 on,

my $sql
    = q~ ALTER TABLE `forum_settings` CHANGE `value` `value` VARCHAR( 255 ) NOT NULL~;
$dbh->do($sql) or die $DBI::errstr;

{
    my $table   = 'log_error';
    my $old_col = 'level';
    my $new_col = "${old_col}_tmp";

    $dbh->do(<<SQL);
ALTER TABLE `$table` ADD `$new_col` SMALLINT(1) UNSIGNED NOT NULL DEFAULT '1';
SQL
    sleep 1;
    $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=2 WHERE $old_col='debug';
SQL
    sleep 1;
    $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=3 WHERE $old_col='warn';
SQL
    sleep 1;
    $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=4 WHERE $old_col='error';
SQL
    sleep 1;
    $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=5 WHERE $old_col='fatal';
SQL
    sleep 1;
    $dbh->do(<<SQL);
ALTER TABLE `$table` DROP `$old_col`;
SQL
    sleep 1;
    $dbh->do(<<SQL);
ALTER TABLE `$table` CHANGE `$new_col` `$old_col` SMALLINT(1) UNSIGNED NOT NULL DEFAULT '1';
SQL
    sleep 1;
}

print "Done\n";

1;
