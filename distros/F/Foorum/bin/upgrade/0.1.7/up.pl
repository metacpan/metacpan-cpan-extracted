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

# from Foorum v0.1.7 on,
# we add a new column 'post_on' for table 'topic'

my $dbh = $schema->storage->dbh;
$dbh->do(
    'ALTER TABLE `topic` ADD `post_on` INT( 11 ) UNSIGNED NOT NULL DEFAULT "0" AFTER `title` ;'
) or die $dbh->errstr;

print
    "[OK]ALTER TABLE `topic` ADD `post_on` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0' AFTER `title` ;\n";

# populate data from comment to topic
my $rs = $schema->resultset('Comment')->search(
    {   object_type => 'topic',
        reply_to    => 0,
    },
    { columns => [ 'object_id', 'post_on' ], }
);
while ( my $r = $rs->next ) {
    $schema->resultset('Topic')->search( { topic_id => $r->object_id, } )
        ->update( { post_on => $r->post_on, } );
    print 'Update ', $r->object_id, ' with ', $r->post_on, "\n";
}

print "Done\n";

1;
