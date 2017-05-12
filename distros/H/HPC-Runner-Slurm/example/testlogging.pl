#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  testlogging.pl
#
#        USAGE:  ./testlogging.pl  
#
#  DESCRIPTION:  
#      VERSION:  1.0
#      CREATED:  22/12/14 10:15:02
#     REVISION:  ---
#===============================================================================

package Main;

use Moose;
use namespace::autoclean;
extends 'Runner::Slurm';

use Log::Log4perl;
use File::FindLib 'lib';


sub init_log {
    my $self = shift;

    my $filename = $self->logdir."/".$self->logfile;

my $log_conf =<<EOF;
############################################################
#  Log::Log4perl conf - Syslog                             #
############################################################
log4perl.rootLogger                = DEBUG, SYSLOG, FILE
log4perl.appender.SYSLOG           = Log::Dispatch::Syslog
log4perl.appender.SYSLOG.min_level = debug
log4perl.appender.SYSLOG.ident     = slurmrunner
log4perl.appender.SYSLOG.facility  = local1
log4perl.appender.SYSLOG.layout    = Log::Log4perl::Layout::SimpleLayout
log4perl.appender.FILE           = Log::Log4perl::Appender::File
log4perl.appender.FILE.filename  = $filename
log4perl.appender.FILE.mode      = append
log4perl.appender.FILE.layout    = Log::Log4perl::Layout::PatternLayout
log4perl.appender.FILE.layout.ConversionPattern = %d %p %m %n
EOF

    Log::Log4perl::init(\$log_conf);
    my $log = Log::Log4perl->get_logger();

    return $log;
};

Main->new_with_options->run;

1;
