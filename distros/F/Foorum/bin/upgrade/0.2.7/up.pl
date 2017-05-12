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

# from Foorum v0.2.7 on,
# we add a new column 'point' to user table
# and a new 'type' value 'created_time' in 'forum_settings' table

# new 'point'
my $sql
    = q~ALTER TABLE `user` ADD `point` INT( 8 ) NOT NULL DEFAULT '0' AFTER `email` ;~;
$dbh->do($sql) or die $DBI::errstr;
$sql = q~ALTER TABLE `user` ADD INDEX ( `point` ) ;~;
$dbh->do($sql) or die $DBI::errstr;

# calc the points
my $rs = $schema->resultset('User');
while ( my $r = $rs->next ) {
    my $point = $r->threads * 2 + $r->replies + $r->login_times;
    $r->update( { point => $point } );
    print 'Working on User ', $r->user_id, "\n";
}

# for 'created_time'
# 1, get all forums
my $frs = $schema->resultset('Forum');
while ( my $r = $frs->next ) {

    # 2, check if the forum_settings have that already
    my $count = $schema->resultset('ForumSettings')
        ->count( { forum_id => $r->forum_id } );
    unless ($count) {
        print 'Working on Forum ', $r->forum_id, "\n";

        # 3, get the min time from topic
        my $sql = q~SELECT MIN(post_on) FROM topic WHERE forum_id = ?~;
        my $sth = $dbh->prepare($sql);
        $sth->execute( $r->forum_id );
        my ($min_time) = $sth->fetchrow_array;

        # 4, insert into forum_settings
        $schema->resultset('ForumSettings')->create(
            {   forum_id => $r->forum_id,
                type     => 'created_time',
                value    => $min_time || time(),
            }
        );
    }
}

print "Done\n";

1;
