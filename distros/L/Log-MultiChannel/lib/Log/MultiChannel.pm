package Log::MultiChannel;
use vars qw($VERSION);
use Term::ANSIColor qw(:constants);
$VERSION = '1.10';
# -------------------- Notice ---------------------
# Copyright 2014 Paul LaPointe
# www.PaullaPointe.com/Logging-MultiChannel
# This program is dual licensed under the (Perl) Artistic License 2.0,
# and the Lesser GNU General Public License 3.0 (LGPL).
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License 3.0 for more details.
# You should have received a copy of the GNU General Public License 3.0
# in the licenses directory along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 
# You should have received a copy of the Artistic License 2.
# in the licenses directory along with this program.  If not, see
# <http://directory.fsf.org/wiki/License:ArtisticLicense2.0/>.
# 
# -------------------- End Notice ---------------------
=head1 NAME

Log::MultiChannel - A full featured module for implementing log messages on multiple channels to multiple targets.

=head2 FEATURES

Features:
- Multi-channel logging, with the ablity to enable or disable channels dynamically.

- Channels can be mapped to multiple Log files for duplication of messages.

- Channels can be optional color coded. Each log file can enable or disable the color feature.

- Channels can be selectively enabled for messages from specific modules.

Advanced features:

- Channels can be mapped to your own handles (Eg. socket) for writting to things beside log files.

- Each Log file can use its own print function, or default to the one provided.

Features for limiting and cycling logs:

- Log files can optionally be limited to a specific line count.

- Old copies of log files can optional be perserved or overwritten.

- Old log files can be optionally moved to a different directory.

Coming soon:

- Thread safety.

=head1 AUTHOR

Paul LaPointe - <http://paullapointe.org>

=head2 LICENSE

This program is dual licensed under the (Perl) Artistic License 2.0,
and the Lesser GNU General Public License 3.0 (LGPL).

=head2 BUGS

Please report any bugs or feature requests to bugs@paullapointe.org

Please visit <http://paullapointe.org/MultiChannel> for complete documentation, examples, and more.

=head2 METHODS

=head3 Log ( channel, message, additional args... )

Channel can be any string.
Message is the log message to write.
Additional args can be passed in for use by a custom log handler.

=head3 startLogging( filename, preserve, limit, oldDir, printHandler )

filename     - the fully qualified filename for the log.

preserve     - An option to retain old copies of the log before overwritting (0 or 1).

limit        - An optional limit on the number of lines that can be written before cycling this log.

oldDir       - Move old log files to this fully qualified directory when overwritting.

printHandler - An optional special print handler for this file.
               Three print handlers are included in the module itself:
                  - logPrint - This is includes the date (only when it changes), time, channel, source filename, source line. E.g:
                  ---- 2014 Oct 8 ----
                  17.50.49 INF t/smokeTest.t-25 This is a test.

                  - logPrintVerbose - This is includes the date and time, channel, source filename, source line. E.g:
                  INF Wed Oct  8 23:42:25 2014 t/smokeTest.t-101 This is the logPrintVerbose handler.

                  - logPrintSimple - E.g:
                  INF This is the logPrintSimple handler.

=head3 startLoggingOnHandle ( name, fileHandle, printHandler )

name     - Any arbitrary name for this log.

filehandle - The filehandle to log with.

printHandler - An optional special print handler for this file 

=head3 stopLogging ( Log filename )

This will stop logging to the given log file.

=head3 closeLogs();

This will stop logging to ALL files (including any custom filehandles).

=head3 mapChannel ( Channel, Log filename1, Log filename2, ... )

This will map a channel to one or more log files by their name.

=head3 mapChannelToLog ( Channel, Log filename ) 

Maps a channel to this specific log name.

=head3 unmapChannel ( Channel, [Log filename] )

Unmaps all logs from a channel, or from a specific log file.

=head3 enableChannel ( Channel ) 

Enables log messages from a specific channel. 

=head3 disableChannel ( Channel )

Disables log messages from a specific channel. 

=head3 enableChannelForModule  ( Channel, Module )

Enables log messages from a specific module for the given channel. 

=head3 disableChannelForModule  ( Channel, Module ) 

Disabled log messages from a specific module for the given channel (overriden by channel control). 

=head3 assignColorCode ( Channel , Ascii color code )

Assigns a (typically) ASCII color code to a specific channel

=head3 enableColor ( LogFilename ) 

Enables color on a specific log filename.

=head3 disableColor ( LogFilename ) 

Disables color on a specific log filename.

=head3 logStats ()

Returns a list with a count of all messages logged to each channel.

=head3 EXAMPLES

=head4 Example 1:  The simplest use case:

 use Log::MultiChannel qw(Log);
 Log::MultiChannel::startLogging('myLogFile.log');
 Log('INF','This is an info message'); # This will default to the last log openned
 ...
 Log::MultiChannel::stopLogging('myLogFile.log');
 exit;

=head4 Example 2: Using multiple logs and channels:

 use Log::MultiChannel qw(Log);
 Log::MultiChannel::startLogging('myLogFile1.log');
 Log::MultiChannel::startLogging('myLogFile2.log');

 Log::MultiChannel::mapChannel('INF','myLogFile1.log'); # Put INF messages in myLogFile1.log
 Log::MultiChannel::mapChannel('ERR','myLogFile2.log'); # Put ERR messages in myLogFile2.log

 Log('INF','This is an Error message for myLogFile1.log');
 Log('ERR','This is an info message for myLogFile2.log');

 Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
 exit;

=head4 Example 3: Tee-ing output to STDOUT and a log file:

 #!/usr/bin/perl
 # Example 8:  This will tee (copy) the output that is sent to a log file
 # to STDOUT, so it can be seen as the program runs.
 use strict;
 use warnings;
 use Log::MultiChannel qw(Log);

 Log::MultiChannel::startLogging('myLogFile1.log');
 Log::MultiChannel::startLoggingOnHandle('STDOUT',\*STDOUT);

 Log::MultiChannel::mapChannel('INF','myLogFile1.log','STDOUT'); # Put INF messages in myLogFile1.log

 Log('INF','This is an Error message for myLogFile1.log, that will also be printed on STDOUT');

 Log::MultiChannel::closeLogs(); # This will close ALL log files that are open
 exit;

=head4 More Examples are available in the distribution and at http://paullapointe.org/MultiChannel

=cut

use strict;
use warnings;
require Exporter;
use UNIVERSAL;
use IO::Handle;

our @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
our @weekdays = qw( Sun Mon Tues Wed Thurs Fri Sat );

our @ISA = 'Exporter';
our @EXPORT_OK = qw(Log startLogging startLoggingOnHandle stopLogging mapChannel unmapChannel enableChannel disableChannel enableChannelForModule disableChannelForModule assignColorCode enableColor disableColor logStats);

my $defaultLog; # This tracks the last log file openned, which will be the default for unmapped channels

my $channels; # This is a list of all available channels
# channel->{name}->{logs} - A list of all logs mapped to this channel
# channel->{name}->{count} - A count of all messages sent to this channel 
# channel->{name}->{state} - 1 for on, 0 for off
# channel->{name}->{color} - An ascii color code to optional assign to the channel, for use with the default print handler 

my @logs; # This is a list of all available filehandles
# $logs[i]->{fh} - The actual filehandle
# $logs[i]->{count} - a count of messages sent to this filehandle since it was last openned or cycled
# $logs[i]->{limit} - a limit on the number of lines that can be printed to this filehandle before it will be cycled. 0 to disable cycling.
# $logs[i]->{oldDir} - a director name that old copies of this log will be moved to when overwritting.
# $logs[i]->{printHandler} - a print handler for this file
# $logs[i]->{filename} - the filename of for this filehandle
# $logs[i]->{colorOn} - This controls if this filehandle will use ascii color codes (for the default logPrint fn)
# $logs[i]->{currentYear} - The year of the last message printed on this log
# $logs[i]->{currentmday} - The current day of the month of the last message printed on this log

my %filenameMap; # This maps a filename back to it's permenant Log object


# This will start a new log file and 
# assign a set of channels to the log
# 0 - filename to open
# 1 - A limit for the number of lines written to this file, after which it will cycle
# 2 - A Code reference to a special print handler for this file
sub startLogging {
    my $log;
    $log->{filename}    =shift; # Obviously, filename for the log
    $log->{preserve}    =shift; # An option to retain old copies of the log before overwritting.
    $log->{limit}       =shift; # An optional limit on the number of lines that can be written before cycling this log
    $log->{oldDir}      =shift; # Move old log files to this directory when overwritting
    $log->{printHandler}=shift; # An optional special print handler for this file 
  
    # If not provided, the printHandler will default to the std fn
    unless ($log->{printHandler}) { $log->{printHandler}=\&logPrint; }
  
    # Check for an old copy of the log, and move it out of the way if desired
    if ($log->{preserve}) {
	if (-f $log->{filename}) { &moveOldLog($log); }
    }

    # Open the file
    open($log->{fh}, ">$log->{filename}") or die ("Error! Unable to open log file $log->{filename} for writing.\n");
    $log->{fh}->autoflush;
   
    # Now initialize this log
    startLoggingInternal($log);
}
# This will start a new log file and 
# assign a set of channels to the log
# 0 - Any arbitray name for this log, so we can work with it.
# 1 - The already openned filehandle
# 2 - A Code reference to a special print handler for this file
#
sub startLoggingOnHandle {
    my $log;
    $log->{filename}    =shift; # In this case, just any name - it can be any string
    $log->{fh}          =shift; # Obviously, the fully qualified filename for the log       
    $log->{printHandler}=shift; # An optional special print handler for this file 

    $log->{preserve}=0;  # Disabled
    $log->{limit}   =0;  # Disabled
    $log->{oldDir}  =''; # Disabled
    
    # If not provided, the printHandler will default to the std fn
    unless ($log->{printHandler}) { $log->{printHandler}=\&logPrint; }

    # Now initialize this log
    startLoggingInternal($log);
}

# This sets up the 
sub startLoggingInternal {
    my $log=shift;

    # Reset the counter for this log
    $log->{count}=0;

    # Initialize the last month day and year to 0
    $log->{currentmday}=0;
    $log->{currentYear}=0;
       
    # Also add this Log in the filenameMap, so we can easily find it with the name
    $filenameMap{$log->{filename}}=$log;

    # Remember this most recent log as the new default for unmapped channels
    $defaultLog=$log;

    # Add this new Log to our list
    push @logs,$log;

    return $log->{fh};
}

# This will set the handler of the specified log file
# to the provided handler 
sub setPrintHandler {
    my $logName=shift;
    my $handler=shift;
    my $log=$filenameMap{$logName};
    $log->{printHandler}=\&{$handler};
}

# This will map a set of channels to list of log files, specified by their name.
# Note! Channels are enabled by default. You must disable them if you want
# them turned off.
#
# Channels can be copied to multiple log files by calling this fn multiple
# times with different filenames.
# 
sub mapChannel {
    my $channel=shift;

    # Turn the channel on
    enableChannel($channel);

    # Map the channel to each individual Log
    foreach my $filename (@_) { &mapChannelToLog_Internal($channel,$filenameMap{$filename}); }
}

# This will map a set of channels to a specific log file object.
# Note! Channels are enabled by default. You must disable them if you want
# them turned off.
#
# Channels can be copied to multiple log files by calling this fn multiple
# times with different logs.
# 
# Eg. 
sub mapChannelToLog_Internal {
    my $channelName=shift;
    my $log=shift;
 
    # If there is an existing list of logs for this channel
    # add this log to it.
    if ($channels->{$channelName}->{logs}) {
	push @{$channels->{$channelName}->{logs}},$log;
    }
    else {
	# If this is the first log mapped to this channel
	# start a new list
	my @newLogList=($log);
	$channels->{$channelName}->{logs}=\@newLogList;	
    }
}

# This will remove all the mappings for a channel,
# unmapChannel(Channel);
# unmapchannel(Channel,log);
sub unmapChannel {
    # If there's a specific log file provided in arg 2
    # unmap the channel from that log only
    if ($_[1]) { 
	my $log=$filenameMap{$_[1]};
	# Locate this log in the channels list of logs
	my $index = 0;
	$index++ until ${$channels->{$_[0]}->{logs}}[$index] eq $log;
	# Now remove it 
	splice(@{$channels->{$_[0]}->{logs}}, $index, 1);	
    }
    else {
	# Otherwise, unmap it from all logs
	undef $channels->{$_[0]}->{logs};
    }
}

# This will close down a log file handle
# Note it will NOT unmap any channels mapped to it
sub stopLogging {
    my $filename=shift;
    my $log=$filenameMap{$filename};

    if ($log->{fh}) { close($log->{fh}); undef $log->{fh}; }
}

# Close all logs
sub closeLogs { 
    foreach my $log (@logs) {
	if ($log->{fh}) { close($log->{fh}); undef $log->{fh}; }
    }
} 

# These will enable (1) or disable (0)  a particular log channel
sub enableChannel { $channels->{$_[0]}->{state}=1; $channels->{$_[0]}->{count}=0; }
sub disableChannel { 
    if ($channels->{$_[0]}->{logs}) {
	$channels->{$_[0]}->{state}=0; 
    }
    else {
	warn("This program has disabled channel $_[0] - but it has not been mapped to a log yet, so it will be re-enabled the first time it is used.");
    }

}

# This will assign an (normally ascii) color code to a particular channel
sub assignColorCode { $channels->{$_[0]}->{color}=$_[1]; }

# These will enable (1) or disable (0) a particular log channel, and particular module
sub enableChannelForModule { $channels->{$_[0]}->{"pkg:$_[1]"}=1; } 
sub disableChannelForModule { undef $channels->{$_[0]}->{"pkg:$_[1]"}; } 

# These will enable or disable color codes for this particular Log
sub enableColor  { my $log=$filenameMap{$_[0]}; $log->{colorOn}=1; }
sub disableColor { my $log=$filenameMap{$_[0]}; $log->{colorOn}=0; }

# This is the main internal print routine for the logging.
# This function should not be called externally.
# These are the args:
# 0 - Epoch Time
# 1 - Local Time as a string
# 2 - Filehandle
# 3 - The log object
# 4 - source module
# 5 - source filename
# 6 - source line #
# 7 - desired color
# 8 - channel name
# 9 - message
# 10,etc - Additional parameters...

sub logPrint {
    my $fh=$_[2];  
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($_[0]);
    $year += 1900;

    if (($year!=$_[3]->{currentYear}) or ($mday!=$_[3]->{currentmday})) { 
	$_[3]->{currentYear}=$year;
	$_[3]->{currentmday}=$mday; 
	printf $fh "---- $year $months[$mon] $mday ----\n"; 
    }

    $sec=sprintf("%02d", $sec);
    $min=sprintf("%02d", $min);
    $hour=sprintf("%02d", $hour);
    my $timestamp="$hour:$min:$sec"; 

    # If color codes are turned on, add one now for the specified color
    if ($_[7]) { print $fh $_[7]; }   
    
    # Print the channel, date, line of code
    printf $fh "%8s $_[8] %12s ",$timestamp,"$_[5]-$_[6]";

    # Print the line content
    for (my $i=9;$i<scalar(@_);$i++) {
	if ($i>9) { print $fh ','; }
	print $fh $_[$i];
    }

    # If color codes are turned on, add one for black now
    if ($_[7]) { print $fh RESET; }  
    
    # end the line with a carriage return
    print $fh "\n"; 
}

# This is the main internal print routine for the logging.
# This function should not be called externally.
# These are the args:
# 0 - Epoch Time
# 1 - Local Time as a string
# 2 - Filehandle
# 3 - The log object
# 4 - source module
# 5 - source filename
# 6 - source line #
# 7 - desired color
# 8 - channel name
# 9 - message
# 10,etc - Additional parameters...
sub logPrintVerbose {
    my $fh=$_[2];

    # If color codes are turned on, add one now for the specified color
    if ($_[7]) { print $fh $_[7]; }   
    
    # Print the channel, date, line of code
    printf $fh "$_[8] %24s %12s ",$_[1],"$_[5]-$_[6]";

    # Print the line content
    for (my $i=9;$i<scalar(@_);$i++) {
	if ($i>9) { print $fh ','; }
	print $fh $_[$i];
    }

    # If color codes are turned on, add one for black now
    if ($_[7]) { print $fh RESET; }  
    
    # end the line with a carriage return
    print $fh "\n"; 
}

# An alternative print function, that is color enabled,
# and will print the channel and message, no time or line of code
sub logPrintSimple {
    my $fh=$_[2];

    # If color codes are turned on, add one now for the specified color
    if ($_[7]) { print $fh $_[7]; }   
    
    # Print the line content
    printf $fh "$_[8] ";
    for (my $i=9;$i<scalar(@_);$i++) {
	if ($i>9) { print $fh ','; }
	print $fh $_[$i];
    }

    # If color codes are turned on, add one for black now
    if ($_[7]) { print $fh RESET; }  
    
    # end the line with a carriage return
    print $fh "\n";
    
    # Increment the log line counter
    $_[3]->{count}++;
}


# This is the external function used to log messages on a particular
# channel. This are the args:
# 0 - channel
# 1 - message
sub Log {
    
    unless ($_[0]) { return; }
    # Check that the message is a defined value, and define it to an empty string if its not.
    unless ($_[1]) { $_[1]=''; }

    # Check that this channel is actually mapped to a log
    unless ($channels->{$_[0]}->{logs}) { 
	if ($defaultLog) { 
	    # If its not, map it to the default log (last openned) and enable it.
	    &mapChannelToLog_Internal($_[0],$defaultLog); 

	    # Turn the channel on
	    enableChannel($_[0]);
	}
	else {
	    return; # Do nothing if there are no logs open
	}
    }
   
    # Only print if the channel is not enabled or if its enabled for a particular module 
    my ( $pkg, $srcfilename, $line ) = caller;    
    if (($channels->{$_[0]}->{state}) or ($channels->{$_[0]}->{"pkg-$pkg"})) { 
	# Get the time of the message
	my $now=time();
	my $localNow=localtime($now);
	$channels->{$_[0]}->{count}++;

	# Print the message on each of the filehandles for this channel
	foreach my $log (@{$channels->{$_[0]}->{logs}}) { 
	    # Only print to this log if it has a filehandle
	    if ($log->{fh}) {
		if ($log->{printHandler}) { 
		    my $color;
		    # If this filehandle has color turned on, and this channel has a desired color, provide it
		    if ($log->{colorOn}) { $color=$channels->{$_[0]}->{color}; }
		    &{$log->{printHandler}}($now,$localNow,$log->{fh},$log,$pkg,$srcfilename,$line,$color,@_); 
		    
		    # Increment the log line counter
		    $log->{count}++;
		    
		    # If we've hit the log line limit, cycle the log
		    if (($log->{limit}) and ($log->{count} > $log->{limit})) { &cycleLog($log); }
		}
	    }
	}
    } 
}

# This will cycle a log file by closing it, and moving
# the current log to an archived filename. Then it will
# reopen the log.
# This function is overloaded - it could be called with
# a filename or filehandle
sub cycleLog {
    my $log=shift;
   
    # Close the old log file
    if ($log->{fh}) { close($log->{fh}); }

    # Move the old copy of the log out of the way
    if ($log->{preserve}) { &moveOldLog($log); }

    # Reopen the file
    open($log->{fh},">$log->{filename}") or die ("Error! Unable to open log file $log->{filename} for writing.\n");
    $log->{fh}->autoflush;
    $log->{count}=0;

    return $log->{fh};
}

# This will move an old copy of a log out of the way
# so a new one can take it's place
sub moveOldLog {
    my $log=shift;
    my $filename=$log->{filename};

    # Get a timestamp, to add to the name of the old log file 
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $sec=sprintf("%02d", $sec);
    $min=sprintf("%02d", $min);
    $hour=sprintf("%02d", $hour);
    $year += 1900;        
    my $timestamp="$year-".$months[$mon]."-".$mday."_"."$hour:$min:$sec"; 
    
    # Rename the old file with the timestamp
    my $cmd="mv -f $filename $filename\.$timestamp";
    # If there's an old dir specified, move the file there instead
    if ($log->{oldDir}) {
	my $shortFilename=$filename;
	$shortFilename =~ s{.*/}{}; # Remove path       
	$cmd="mv -f $filename $log->{oldDir}/$shortFilename\.$timestamp";

	# Make sure that old dir directory actually exists first
	unless (-d $log->{oldDir}) {
	    system("mkdir -p $log->{oldDir}");
	}
    }
    system($cmd);
}

# This will show a breakdown of how many messages
# were logged on each channel since this fun
# was last called
sub logStats {
    my @ret;
    foreach my $channelName (keys %{$channels}) {
	push @ret,"$channelName - $channels->{$channelName}->{count}";
	$channels->{$channelName}->{count}=0;
    }
    return @ret;
}

1;
