#!/usr/bin/env perl

use strict;
use warnings;

use lib "lib";

use File::Basename;
use File::Slurp;
use Getopt::Long;
use Time::HiRes qw( gettimeofday tv_interval );

use Log::Fine::Handle::Console;
use Log::Fine::Handle::File;
use Log::Fine::Formatter::Template;
use Log::Fine::Levels::Syslog;

# Globals
my $linecount = 0;

{

        my $input;
        my $output   = "fine.log";
        my $docustom = 0;

        GetOptions("i=s" => \$input,
                   "o=s" => \$output,
                   "c"   => \$docustom
        );

        die "Need input file"
            unless $input =~ /\w/;

        # Open up a console output
        my $console_handle = Log::Fine::Handle::Console->new();
        my $out            = Log::Fine->logger("console0");

        $out->registerHandle($console_handle);
        $out->log(INFO, "Starting Stress Script");
        $out->log(DEBG, "INPUT FILE:$input:");
        $out->log(DEBG, "OUTPUT FILE:$output:");

        # Create a template logger to a file
        my $formatter =
            Log::Fine::Formatter::Template->new(template => "[%%TIME%%] %%USER%%@%%HOSTSHORT%% %%LEVEL%% %%MSG%%",
                                                timestamp_format => "%b %e %T");

        my $handle =
            Log::Fine::Handle::File->new(file      => basename($output),
                                         dir       => dirname($output),
                                         autoflush => 1,
                                         formatter => $formatter
            );

        my $log = Log::Fine->logger("logger0");

        $log->registerHandle($handle);

        # Slurp in input file
        $out->log(INFO, "Reading in $input");
        my @lines = read_file($input);

        # Start writing out test file
        $out->log(INFO, "Writing out test log");
        my $t1 = [gettimeofday];
        for my $line (@lines) {
                $log->log(INFO, $line);
        }
        my $t2 = [gettimeofday];
        my $t3 = tv_interval $t1, $t2;

        # clean up after ourselves
        $out->log(INFO, "Done");
        $handle->fileHandle->close();

        $out->log(INFO,
                  sprintf("%d lines were written to %s in %0.5f seconds", scalar @lines, $output, $t3));

        # Do custom placeholder test
        if ($docustom) {

                $out->log(NOTI, "Beginning custom placeholder test");

                my $linecountfile = sprintf("%s-lines.txt", $output);
                my $counter = 0;
                my $lineno =
                    Log::Fine::Formatter::Template->new(template            => "%%LINENO%% %%MSG%%",
                                                        custom_placeholders => {
                                                                                 lineno => \&linetracker,
                                                        });

                my $linehandle =
                    Log::Fine::Handle::File->new(file      => basename($linecountfile),
                                                 dir       => dirname($linecountfile),
                                                 autoflush => 1,
                                                 formatter => $lineno
                    );

                $out->log(INFO, "Output will be directed to $linecountfile");

                my $countlog = Log::Fine->logger("logger1");

                $countlog->registerHandle($linehandle);

                my $l1 = [gettimeofday];
                for my $line (@lines) {
                        $countlog->log(INFO, $line);
                }
                my $l2 = [gettimeofday];
                my $l3 = tv_interval $l1, $l2;

                $out->log(INFO, "Done");

                $linehandle->fileHandle->close();
                $out->log(INFO,
                          sprintf("%d lines were written to %s in %0.5f seconds", scalar @lines, $linecountfile, $l3));

        }

        $out->log(NOTI, "Good bye");

}

# --------------------------------------------------------------------

sub linetracker { return sprintf("%6d", ++$linecount); }
