# $Id: Simplest.pm 2468 2009-03-21 02:25:35Z dk $
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# 
package Log::Simplest;
use vars qw /$VERSION/;
use strict;

$VERSION = "1.0";

# Dmytro Kovalov. 2004-2009
# $Author: dk $
# $Date: 2009-03-21 11:25:35 +0900 (Sat, 21 Mar 2009) $
# $URL: svn://svn/dmytro/Development/perl/modules/Log-Simplest/trunk/lib/Log/Simplest.pm $

=head1 NAME

Log::Simplest - Simple log module. Writes log messages to file and/or STDERR. 

You should use this module when you want to have very simple
programming interface to log your messages. If you want some
flexibility of message format and log file names, you should use some
of others Log::* modules available at CPAN.

This module gives the least flexibility among existing Log
modules. However it requires the least programmer's effort to write log
messages to file.

=cut

=head1  USAGE 

 use Log::Simplest;
 &Log("Informative log message");
 &Fatal("I am dying...");

Log files opened and closed by module initialization/end routines and
does not require programmer's attention. When your main script
contains only L<use Log::Simplest> directive and does not have any calls
to L<Log()> and L<Fatal()> functions, Log::Simplest will:

    * open log file;
    * write start time and date of the script;
    * write end time and date of the script;
    * close log file.

1)    

Log::Simplest creates log file during module initialization (i.e. load
of the module). On file opening module writes time and date of main
script start time. 

Log::Simplest uses environment variable L<${LOG_DIR}> for log file
location. Log file is created in directory defined by L<${LOG_DIR}>,
if it is defined, or in L</tmp> if environment variable is not defined
or empty.

2) 

Log file name format is fixed and consists of:

    * name of main script (without extension .pl); 
    * time and date when script started;
    * PID of main script;
    * extension .log. 

3) 

Log message format is fixed too. Each row contains log message passed
to one of the functions L<&Log()> or L<&Fatal()> with pre-pended
time-stamp.

4) 

Log file is closed automatically when module unloads with message
containing time-stamp when script ended.

=cut

=head1 DEPENDENCIES

This module requires these other modules and libraries:

     FileHandle
     POSIX
=cut 

use FileHandle;
use POSIX qw(strftime);
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

=head2 EXPORTED FUNCTIONS 

See below for description and/or usage.

=head3 &Log()

=head3 &Fatal()

=head3 &NOFILE &NOSTDERR



=cut

@EXPORT = qw(&Log &Fatal &NOFILE &NOSTDERR &STOP_LOG_STDERR &START_LOG_STDERR);

@EXPORT_OK = qw ($Log_file $StartTime);

=head2 OK to export variables:

=head3  $Log_file 

Log file handler

=head3  $StartTime 

Time-stamp of script  start  (same as used in the file name of Log file).

=cut

use vars qw(@ENV $logToSTDERR $StartTime $Log_file );

$Log_file = new FileHandle;

$logToSTDERR = 1;              # set default value for $logToSTDERR
$StartTime = strftime "%y%m%d:%H:%M:%S", localtime;
chomp(my $MyName = `basename main::$0`);
$MyName =~ s/\.pl$//;
$ENV{'LOG_DIR'} = "/tmp" if $ENV{'LOG_DIR'} eq "" or ! defined $ENV{'LOG_DIR'};
my $LogFileName = sprintf "%s/%s.%s.%s.%s", $ENV{'LOG_DIR'}, $MyName,$StartTime, $$,"log";
die "Cannot open Log File $LogFileName: $!\n" unless $Log_file->open("> $LogFileName");
				#
				#
				#
&Log (" *** " . $MyName . " *** starting *** ");
&Log ("Log file: $LogFileName");

1;
# --------------------------------------------------------------------------------
=head2 FUNCTIONS
=head3  &Log ("log message")

Prints message with time stamp to log file. 

If variable $logToSTDERR is not 0 than, message is also printed to
STDERR (this is default).

=cut 
# --------------------------------------------------------------------------------
sub Log  {
  my $msg = shift;
  my $output  = shift;
  $output = 0 unless defined $output;
  my $now  = strftime "%y/%m/%d %H:%M:%S", localtime;
  $Log_file->print(sprintf  "%s: %s\n", $now, $msg) if $output != &NOFILE;
  printf STDERR "%s: %s\n", $now, $msg if ( $logToSTDERR
						and defined $output
						and $output != &NOSTDERR);
  return 0
};


# --------------------------------------------------------------------------------
=head3  &Fatal ("error message");

Same as &Log(), dies with an error after printing log message. Internally calls &Log().

=cut
# --------------------------------------------------------------------------------
sub Fatal ($) {
  my $msg = shift;
  &Log ("FATAL ERROR: " . $msg);
  die "FATAL : ". $msg;
};

# --------------------------------------------------------------------------------
=head3 NOFILE, NOSTDERR

Can be passed as additional parameters to &Log(). Do not print log to
the corresponding media even if log level is high enough

=cut
# --------------------------------------------------------------------------------
sub NOFILE   () {1};
sub NOSTDERR () {2};


=head3 STOP_LOG_STDERR  START_LOG_STDERR

Disable/enable logging to STDERR. Both functions change value of
$logToSTDERR variable. At the module initialization it is set to 1,
i.e. enable printing log messages to STDERR.

Please note that, very first message about start of main script will
always print to STDERR because it happens before you can call any of
these two functions.

=cut
sub STOP_LOG_STDERR   () {$logToSTDERR = 0};
sub START_LOG_STDERR  () {$logToSTDERR = 1};

# ============================================================
# close cleanly file on module exit
#
END {
  &Log (" ***  Closing file $LogFileName *** ");
  &Log (" *** " . $MyName . " *** Completed *** ");
  close $Log_file;
}
__END__

=head1 EXAMPLES

=head2 LOG MESSAGES EXAMPLE

 #!/usr/bin/perl
 use Log::Simplest;
 Log("This is normal log message");
 Fatal("After printing this I will die");

Running this script should produce output similar to:

 09/03/18 13:34:26:  *** example *** starting *** 
 09/03/18 13:34:26: Log file: /tmp/example.090318:13:34:26.9941.log
 09/03/18 13:34:26: This is normal log message
 09/03/18 13:34:26: FATAL ERROR: After printing this I will die
 FATAL : After printing this I will die at Log/Simplest.pm line 157.
 09/03/18 13:34:26:  ***  Closing file /tmp/example.090318:13:34:26.9941.log *** 
 09/03/18 13:34:26:  *** example *** Completed *** 

=head2 SIMPLEST EXAMPLE

 #!/usr/bin/perl
 use Log::Simplest;
 exit;

 This script will produce following output both on STDERR and into a file:

 $ ./simplest.pl 
 09/03/20 13:34:24:  *** simplest *** starting *** 
 09/03/20 13:34:24: Log file: /tmp/simplest.090320:13:34:24.25745.log
 09/03/20 13:34:24:  ***  Closing file /tmp/simplest.090320:13:34:24.25745.log *** 
 09/03/20 13:34:24:  *** simplest *** Completed *** 
 $


=cut


=head1 AUTHOR 

Dmytro Kovalov, dmytro.kovalov@gmail.com

=head3 HISTORY

=head4 First public release: March, 2009

Although I have been using this module for quite a while in my
scripts, I have never though about publishing it in theу wild. Finally
I have decided to write little bit longer POD description and put it
on CPAN.


=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dmytro Koval'ov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.






#  LocalWords:  dk qw PID pre FileHandle POSIX strftime NOFILE NOSTDERR MyName
#  LocalWords:  StartTime logToSTDERR localtime basename ENV eq LogFileName msg
#  LocalWords:  sprintf printf
