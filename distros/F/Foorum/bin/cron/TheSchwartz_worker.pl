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
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/config base_path theschwartz/;
use UNIVERSAL::require;

$|++;

my $client    = theschwartz();
my $config    = config();
my $base_path = base_path();

my $verbose = sub {
    my $msg = shift;
    $msg =~ s/\s+$//;
    if ( 'TheSchwartz::work_once found no jobs' eq $msg ) {

        # do nothing
    } elsif ( 'job completed' eq $msg ) {

        # add localtime()
        print STDERR 'job completed @ ', localtime() . "\n";
    } else {
        print STDERR "$msg\n";
    }
};
$client->verbose($verbose);

# load entry from theschwartz.yml or examples/theschwartz.yml
use YAML::XS qw/LoadFile/;
my $theschwartz_config;
if ( -e File::Spec->catfile( $base_path, 'conf', 'theschwartz.yml' ) ) {
    $theschwartz_config = LoadFile(
        File::Spec->catfile( $base_path, 'conf', 'theschwartz.yml' ) );
} else {
    $theschwartz_config = LoadFile(
        File::Spec->catfile(
            $base_path, 'conf', 'examples', 'theschwartz.yml'
        )
    );
}

foreach my $one (
    @$theschwartz_config,    'ResizeProfilePhoto',
    'SendStarredNofication', 'Topic_ViewAsPDF'
    ) {
    my $worker
        = ( ref $one eq 'HASH' )
        ? $one->{worker}
        : $one;    # for above 'Rxxx' scalar

    # skip some
    next
        if ( 'Scraper' eq $worker and not $config->{function_on}->{scraper} );
    next
        if ( 'Topic_ViewAsPDF' eq $worker
        and not $config->{function_on}->{topic_pdf} );

    my $module = "Foorum::TheSchwartz::Worker::$worker";
    $module->use or die $@;

    $client->can_do($module);
}

$client->work_until_done();

1;
