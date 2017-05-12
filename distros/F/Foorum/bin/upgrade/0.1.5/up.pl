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

# from Foorum v0.1.5 on,
# we change all DATETIME to INT(11) because it's better for test cases which use SQLite

my $dbh = $schema->storage->dbh;

my %changes = (
    comment         => [ 'post_on', 'update_on' ],
    log_action      => ['time'],
    log_error       => ['time'],
    log_path        => ['time'],
    message         => ['post_on'],
    scheduled_email => ['time'],
    topic           => ['last_update_date'],
    user            => ['last_login_on'],
);

# create a temp column then update as UNIX_TIMESTAMP
# then drop old column and rename temp column
foreach my $table ( keys %changes ) {
    print "Working on $table\n";
    my @columns = @{ $changes{$table} };
    foreach my $old_col (@columns) {
        my $new_col = "${old_col}_tmp";

        $dbh->do(<<SQL);
ALTER TABLE `$table` ADD `$new_col` INT(11) UNSIGNED NOT NULL DEFAULT '0';
SQL
        sleep 1;
        $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=UNIX_TIMESTAMP($old_col) WHERE $old_col IS NOT NULL;
SQL
        sleep 1;
        $dbh->do(<<SQL);
UPDATE `$table` SET $new_col=0 WHERE $old_col IS NULL;
SQL
        sleep 1;
        $dbh->do(<<SQL);
ALTER TABLE `$table` DROP `$old_col`;
SQL
        sleep 1;
        $dbh->do(<<SQL);
ALTER TABLE `$table` CHANGE `$new_col` `$old_col` INT(11) UNSIGNED NOT NULL DEFAULT '0';
SQL
        sleep 1;
    }
}

print "Done\n";

1;
