#!/usr/bin/perl


use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.5" );

use YAML;
use Getopt::Long;
use File::Basename qw/ dirname /;

BEGIN {
    if ( -d '/opt/decency/lib' ) {
        use lib '/opt/decency/lib';
    }
    if ( -d '/opt/decency/locallib' ) {
        use lib '/opt/decency/locallib';
    }
}

my %opt;
GetOptions(
    "class|a=s"      => \( $opt{ class } = "" ),
    "config|c=s"     => \( $opt{ config } = '/etc/decency/%s.yml' ),
    "log-level|l=i"  => \( $opt{ log_level } = 1 ),
    "pid-file|p=s"   => \( $opt{ pid } = "" ),
    "port=i"         => \( $opt{ port } ),
    "host=s"         => \( $opt{ host } ),
    "help|h"         => \( $opt{ help } = 0 ),
    "maintenance"    => \( $opt{ maintenance } = 0 ),
    "print-stats"    => \( $opt{ print_stats } = 0 ),
    "print-sql"      => \( $opt{ print_sql } = 0 ),
    "export=s"       => \( $opt{ export } = "" ),
    "import=s"       => \( $opt{ import } = "" ),
    "import-replace" => \( $opt{ import_replace } = "" ),
    "user|u=s"       => \( $opt{ user } = "" ),
    "group|g=s"      => \( $opt{ group } = "" ),
    "train-spam=s"   => \( $opt{ train_spam } = "" ),
    "train-ham=s"    => \( $opt{ train_ham } = "" ),
    "train-move=s"   => \( $opt{ train_move } = "" ),
    "train-remove"   => \( $opt{ train_remove } = 0 ),
);

die <<HELP if $opt{ help };

Usage: $0 --class <classname> --config <configfile> --pidfile <pidfile>

    --class | -a <policy|content-filter|syslog-parser>
        What kind of server to start ?
            policy = Mail::Decency::Policy
            content-filter = Mail::Decency::ContentFilter
            log-parser = Mail::Decency::LogParser
    
    --config | -c <file>
        Path to config .. 
        default: /etc/decency/<class>.yml
    
    --pid-file | -p <file>
        default: /tmp/<class>.pid
    
    --log-level | -l <1..6>
        the smaller the less verbose and vice versa, overwrite settings
        in the config
    
    --user | -u <uid | user name>
        change to this user
    
    --group | -g <gid | group name>
        change to this user
    
    --port <int>
        optional port, overwrites the port settings in config
    
    --host <inet address>
        optional host address, overwrites the host settings in config
    
    --maintenance
        Run in maintenance mode and exit
        This cleans up databases and so on
    
    --print-stats
        Print statistics and exit
    
    --print-sql
        Print SQL "CREATE *" statements in SQLite syntax
    
    --export <path>
        Exports all stored data in either a gziped tararchive or
        to STDOUT ("-")
    
    --import <path>
        Imports exported databases back to decency.
    
    --import-replace
        Performces a replacive import which will remove all existing data
        before. Default is additive.
    
    --train-(spam|ham) <files>
        For content filter only. Provide a list of files (eg /tmp/spam/*) which will
        then be passed to the training methods of the enabled spam filters.
    
    --train-move <dir>
        Move file after training here
    
    --train-remove
        Delete file after training
    
    --help | -h
        this help

HELP

die "Provide --class <policy|content-filter|log-parser>\n"
    unless $opt{ class } &&$opt{ class } =~ /^(?:policy|content\-filter|log\-parser)$/;

if ( $opt{ user } ) {
    my $uid = $opt{ user } =~ /^\d+$/
        ? $opt{ user }
        : getpwnam( $opt{ user } )
    ;
    die "Cannot determine UID for '$opt{ user }'\n"
        unless defined $uid;
    $> = $uid;
}

if ( $opt{ group } ) {
    my $gid = $opt{ group } =~ /^\d+$/
        ? $opt{ group }
        : getgrnam( $opt{ group } )
    ;
    die "Cannot determine GID for '$opt{ group }'\n"
        unless defined $gid;
    $) = $gid;
}

$opt{ config } = sprintf( $opt{ config }, $opt{ class } );
die "Can't read from policy config file: $opt{ config }\n"
    unless -f $opt{ config };

# use class
my %map = qw/
    policy          Policy
    content-filter  ContentFilter
    log-parser      LogParser
/;
my $class = "Mail::Decency::$map{ $opt{ class } }";
eval "use $class; 1" or die "Cannot use load $opt{ class }: $@\n";



# read config
my $config = YAML::LoadFile( $opt{ config } );

# update log level
$config->{ logging } ||= { syslog => 1, console => 0, directory => undef };
$config->{ logging }->{ log_level } = $opt{ log_level };

# having other port ?
$config->{ server }->{ port } = $opt{ port }
    if $opt{ port };
$config->{ server }->{ host } = $opt{ host }
    if $opt{ host };

# create server
my $dir = dirname( $opt{ config } );


$ENV{ NO_CHECK_DATABASE } = 1
    if $opt{ print_sql };

my $server = $class->new( config => $config, config_dir => $dir );


# perform maintenance
if ( $opt{ maintenance } || $opt{ print_stats } || $opt{ print_sql } || $opt{ export } || $opt{ import } ) {
    $server->disable_logging;
    
    if ( $opt{ maintenance } ) {
        $server->maintenance;
    }
    
    # print out statistics
    elsif ( $opt{ print_stats } ) {
        $server->print_stats;
    }
    
    # print out statistics
    elsif ( $opt{ print_sql } ) {
        $server->print_sql;
    }
    
    # export database to file or STDOUT
    elsif ( $opt{ export } ) {
        $server->export_database( $opt{ export } );
    }
    
    # print out statistics
    elsif ( $opt{ import } ) {
        my $replacive = $opt{ import_replace } ? 1 : 0;
        $server->import_database( $opt{ import }, { replace => $replacive } );
    }
}

elsif ( $opt{ class } eq 'content-filter' && ( $opt{ train_spam } || $opt{ train_ham } ) ) {
    $server->disable_logging;
    
    # train SPAM
    $server->train( {
        spam  => 1,
        files => $opt{ train_spam },
        move   => $opt{ train_move },
        remove => $opt{ train_remove },
    } ) if $opt{ train_spam };
    
    # train HAM 
    $server->train( {
        ham    => 1,
        files  => $opt{ train_ham },
        move   => $opt{ train_move },
        remove => $opt{ train_remove },
    } ) if $opt{ train_ham };
    
}

# just run the server
else {
    
    $opt{ pid } ||= "/var/run/decency/$opt{ class }.pid";
    
    # write pid
    if ( $opt{ pid } ) {
        open my $fh, '>', $opt{ pid }
            or die "Cannot open pid file '$opt{ pid }' for write: $!\n";
        print $fh $$;
        close $fh;
    }
    
    # run ...
    $server->run;
    
    # remove pid file after going down
    unlink( $opt{ pid } )
        if -f $opt{ pid };
}



exit 0;
