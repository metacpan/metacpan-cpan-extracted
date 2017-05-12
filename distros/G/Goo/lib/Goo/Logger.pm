#!/usr/bin/perl

package Goo::Logger;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Logger.pm
# Description:  Keep a simple text-based logger for the Trawler
#               Now used as a general purpose error logger.
#
# Date          Change
# -----------------------------------------------------------------------------
# 20/02/2003    Needed much better logging to see what was going on in the Trawler
#               especially for Collections
# 01/05/2003    Write to a text log
# 01/07/2004    Small change for logging searches, and form submission
#               used in development to see what's going on
# 21/08/2005    Added a proper die - if logfile could not be opened
# 23/08/2005    N.B. The error log file must have permissions set so that all
#               users can append to it!
#
###############################################################################

use strict;

my $default_location = "/tmp/default.error.log";


###############################################################################
#
# write - write a timestamped entry to the log
#
###############################################################################

sub write {

    my ($message, $filename) = @_;

    # unless message ends with a newline add a newline
    unless ($message =~ /\n$/) { $message .= "\n"; }

    # remember the time
    my $timestamp = localtime();

    # use the default log file if not specified
    my $log_file = $filename || $default_location;

    my ($package, $calling_filename, $line) = caller();

    # append to the log file
    open(LOG, ">> $log_file")
        or die("Can't append to $log_file: $@");
    print LOG "[$timestamp] $calling_filename ($line) - $message";
    close(LOG);

}


1;


__END__

=head1 NAME

Goo::Logger - Write a message to the log

=head1 SYNOPSIS

use Goo::Logger;

=head1 DESCRIPTION

=head1 METHODS

=over

=item write

write a timestamped entry to the log

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

