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

# from Foorum v0.1.2 on,
# the comment posted to topic directly would let reply_to = $first_comment->comment_id
# before is 0

my $dbh = $schema->storage->dbh;
my $sql
    = q~select object_type, object_id FROM comment GROUP BY object_type, object_id~;
my $sth = $dbh->prepare($sql);
$sth->execute();

while ( my ( $object_type, $object_id ) = $sth->fetchrow_array ) {
    next if ( 'topic' ne $object_type );
    print "Working on $object_type + $object_id\n";

    # get the first comment
    my $rs = $schema->resultset('Comment')->search(
        {   object_type => $object_type,
            object_id   => $object_id,
        },
        {   order_by => 'post_on',
            rows     => 1,
            page     => 1,
            columns  => ['comment_id'],
        }
    )->first;
    my $reply_to = $rs->comment_id;
    $schema->resultset('Comment')->search(
        {   object_type => $object_type,
            object_id   => $object_id,
            comment_id  => { '!=', $reply_to },
            reply_to    => 0,
        }
    )->update( { reply_to => $reply_to } );
}

$dbh->do(<<SQL);
CREATE TABLE `forum_settings` (
  `forum_id` int(11) unsigned NOT NULL DEFAULT '0',
  `type` varchar(48) NOT NULL,
  `value` varchar(48) NOT NULL,
  PRIMARY KEY (`forum_id`,`type`),
  KEY `forum_id` (`forum_id`)
);
SQL

1;
