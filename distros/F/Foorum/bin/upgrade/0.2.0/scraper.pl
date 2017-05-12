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

# from Foorum v0.2.0 on,
# we use Encode::Guess to fix the Scraper::MailMan encoding issue.

use Encode qw/from_to/;
use Encode::Guess qw/euc-cn/;    # XXX? can't explain
use YAML::XS qw/LoadFile/;

my $scraper_config = LoadFile(
    File::Spec->catfile(
        $FindBin::Bin, '..', '..', '..', 'conf', 'scraper.yml'
    )
);

my @mailmans = @{ $scraper_config->{scraper}->{mailman} };
foreach my $mailman (@mailmans) {
    my $forum_id = $mailman->{forum_id};
    print "Working on $forum_id\n";
    my $rs = $schema->resultset('Comment')->search(
        {   forum_id    => $forum_id,
            object_type => 'topic',
        }
    );
    while ( my $r = $rs->next ) {
        my $comment_id = $r->comment_id;
        my $text       = $r->text;

        my $enc = Encode::Guess->guess($text);
        my $encoding;
        if ( ref($enc) ) {
            $encoding = $enc->name;
        }
        if ( $encoding and 'utf8' ne $encoding ) {
            from_to( $text, $encoding, 'utf8' );
            print "Convert $comment_id FROM $encoding TO utf8\n";
            $r->update( { text => $text, } );
        } else {
            print "Skip $comment_id\n";
        }
    }
}

print "Done\n";

1;
