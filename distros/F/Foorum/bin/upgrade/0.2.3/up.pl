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

# from Foorum v0.2.3 on,
# `stat` table 'date' column is INT(8)

# 1, create an temp column 'new_date' INT(8)
# 2, update new_date from old 'date' column
# 3, drop old 'date' then rename 'new_date' to 'date'

# step 1
$dbh->do(<<SQL);
ALTER TABLE `stat` ADD `new_date` INT(8) UNSIGNED NOT NULL DEFAULT '0';
SQL

# step 2
my $sql = q~SELECT stat_id, date FROM stat~;
my $sth = $dbh->prepare($sql);
$sth->execute();

while ( my ( $stat_id, $date ) = $sth->fetchrow_array ) {
    $date =~ s/\-//isg;
    $dbh->do(qq~UPDATE stat SET new_date = $date WHERE stat_id = $stat_id~);
    print "Process $stat_id\n";
}

# step 3
$dbh->do(<<SQL);
ALTER TABLE `stat` DROP `date`;
SQL
sleep 1;
$dbh->do(<<SQL);
ALTER TABLE `stat` CHANGE `new_date` `date` INT(11) UNSIGNED NOT NULL DEFAULT '0';
SQL

print "Done\n";

1;
