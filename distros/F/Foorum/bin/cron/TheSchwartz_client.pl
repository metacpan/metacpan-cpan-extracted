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

my $config = config();

use Getopt::Long;
my $debug  = 0;
my $daemon = 0;
my $worker;

GetOptions(
    'debug=i'  => \$debug,     # debug
    'daemon=i' => \$daemon,    # daemon
    'worker=s' => \$worker
);                             # manually inser a $worker

if ($worker) {
    run_worker($worker);
} elsif ($daemon) {

    use Schedule::Cron;
    my $cron = new Schedule::Cron( sub { return 1; } );

    # load entry from theschwartz.yml or examples/theschwartz.yml
    use YAML::XS qw/LoadFile/;
    my $base_path = base_path();
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

    foreach my $one (@$theschwartz_config) {
        my $worker = $one->{worker};

        # skip some
        next
            if ( 'Scraper' eq $worker
            and not $config->{function_on}->{scraper} );

        $cron->add_entry( $one->{time}, \&run_worker, $worker );
    }

    $cron->run();
} else {
    print <<USAGE;
    Usage: perl $0 --debug 1 --daemon 1
           perl $0 --debug 1 --worker DailyReport
USAGE
}

sub run_worker {
    my ($worker) = @_;

    debug($worker);

    my $client = theschwartz();
    $client->insert("Foorum::TheSchwartz::Worker::$worker");
}

sub debug {
    my ($msg) = @_;

    print "$msg \@ ", localtime() . "\n" if ($debug);
}

1;
