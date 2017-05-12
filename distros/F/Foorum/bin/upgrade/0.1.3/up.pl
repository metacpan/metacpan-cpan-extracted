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

# from Foorum v0.1.3 on,
# we add a new table 'user_forum'

my $dbh = $schema->storage->dbh;
$dbh->do('DROP TABLE `user_forum`;');
my $sql = <<'SQL';
CREATE TABLE `user_forum` (
  `user_id` int(11) unsigned NOT NULL DEFAULT '0',
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `status` ENUM( 'admin', 'moderator', 'user', 'blocked', 'pending', 'rejected' ) NOT NULL DEFAULT 'user',
  `time` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`,`forum_id`)
);
SQL
my $sth = $dbh->prepare($sql);
$sth->execute();

print "Create Table OK\n";

# populate data from user_role to user_forum
my $rs
    = $schema->resultset('UserRole')->search( { field => { '!=', 'site' } } );
while ( my $r = $rs->next ) {
    $schema->resultset('UserForum')->create(
        {   forum_id => $r->field,
            status   => $r->role,
            user_id  => $r->user_id,
        }
    );
    print 'Migrate For ', $r->user_id, '-', $r->field, '-', $r->role, "\n";
}

$schema->resultset('UserRole')->search( { field => { '!=', 'site' } } )
    ->delete;

print "Done\n";

1;
