#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2019 The Johns Hopkins University Applied Physics Laboratory
##                         All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a 
##  copy of this software and associated documentation files (the "Software"), 
##  to deal in the Software without restriction, including without limitation 
##  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
##  and/or sell copies of the Software, and to permit persons to whom the 
##  Software is furnished to do so, subject to the following conditions:
## 
##     The above copyright notice and this permission notice shall be included 
##     in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
##  DEALINGS IN THE SOFTWARE.
##
#*******************************************************************************/

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;
use Term::ANSIColor;

# show or clear the contents of the nuggit log

# usage: 
#
# clear the nuggit log
#    nuggit_history.pl -c
# show the entire nuggit log
#    nuggit_history.pl --show-all
#   or with no arguments:
#    nuggit_history.pl
# show the last n lines 
#    nuggit_history.pl --show <n>
#
sub ParseArgs();

my $verbose = 0;
my $write_msg;
my $clear_nuggit_log  = 0;
my $show_raw_bool     = 0;
my $show_summary_bool = 1;
my $show_last_cmd = 0;

my $filter_first_timestamp;
my $filter_last_timestamp;

my $show_n_entries    = 0;

# Color scheme
my $timeColor = 'green';
my $cwdColor = 'cyan';
use Time::Local;
my $cwd;
my $root_repo_branch;
my ($root_dir, $relative_path_to_root) = find_root_dir();
die("Not a nuggit!") unless $root_dir;
my $log = Git::Nuggit::Log->new(root => $root_dir); # TODO: May need to be tweaked if parsing external log
ParseArgs();

if($clear_nuggit_log == 1)
{
    $log->clear(); # Empty existing log
    $log->start(1); # And record a new entry indicating truncation (this command)
}
elsif($show_last_cmd == 1)
{
    exec("less -R ".$log->get_filename().".last_cmd");
}
elsif($show_raw_bool == 1)
{
    my $log_file = $log->get_filename();
    print `cat $log_file`;
}
elsif($write_msg)
{
    # Include comment flag to avoid issues if we attempt to replay commands in future
    $log->start_as("# $write_msg");
}
else
{
    # TODO: Consider moving at least entry parsing into Log.pm
    my $log_file = $log->get_filename();
    die("Log file does not exist") unless -e $log_file;
    open(my $fh, '<', $log_file) || die("Error: Unable to open log file");
    my $last_timestamp;
    my $filter_active = 0;

    while(my $line = <$fh>) {
        if ($line =~ /^([^,]+),(.+)$/) {
            my $timestamp = $1;
            my $cmd = $2;

            # Parse timestamp for filtering purposes
            my ($mon,$mday,$year,$hour,$min,$sec) = $timestamp =~ /(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)/;
            $last_timestamp = timelocal($sec, $min, $hour, $mday, $mon-1, $year);

            last if $filter_last_timestamp && $last_timestamp > $filter_last_timestamp;
            if ($filter_first_timestamp && $last_timestamp < $filter_first_timestamp) {
                $filter_active = 1;
                next;
            } else {
                $filter_active = 0;
            }
            
            # Display it
            print colored($timestamp,$timeColor);
            print ": ";
            say $cmd;
        } elsif (!$show_summary_bool && !$filter_active) {
            if ($line =~ /^,,\t(.+)$/) {
                # Message line
                say $1;
            } elsif ($line =~ /^,,CWD,(.+),CMD,(.+)$/) {
                # Logged command
                print "$2";
                print colored("\t($1)", $cwdColor) unless $1 eq ".";
                say "";
            } elsif ($line =~ /^,,(.+)$/) {
                # TODO: Other log types may be added in future, just dump them for now.
                say $1;
            } else {
                say $line; # If all else fails, show it as-is
            }
        }        
    }
    close($fh);
}




sub ParseArgs()
{
    my ($filter_today, $filter_last_days, $filter_last_hours);
    my ($help, $man);
    Getopt::Long::GetOptions(
        "help"            => \$help,
        "man"             => \$man,
        "clear|c"         => \$clear_nuggit_log,
        "raw!"            => \$show_raw_bool,
        "message|m=s"     => \$write_msg,
        "summary|s!"      => \$show_summary_bool,
        "verbose|v!"      => \$verbose,
        "all|v!"          => \$verbose,
        "show=s"   => \$show_n_entries,
        "last!" => \$show_last_cmd,
                             
        # Filtering Options (incomplete)
        "today!"  => \$filter_today,
        "days|d=i" => \$filter_last_days,
        "hours|h=i" => \$filter_last_hours,
        );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    $show_summary_bool = 0 if $verbose;

    if ($filter_today) {
        $filter_first_timestamp = time;
        $filter_first_timestamp -= 60*60*24; # Show entries from last 24 hours only
    } elsif ($filter_last_days || $filter_last_hours) {
        $filter_first_timestamp = time;
        $filter_first_timestamp -= 60*60*24*$filter_last_days if $filter_last_days;
        $filter_first_timestamp -= 60*60*$filter_last_hours if $filter_last_hours;
    }

    if ($filter_first_timestamp && $filter_last_timestamp) {
        die("Error: Illegal date ranges specified") if $filter_first_timestamp > $filter_last_timestamp;
    }
  
}

=head1 SYNOPSIS

View and manage the nuggit log file.  If run without arguments, this script will display the log file in summary view.

=over

=item --message | -m

Write the specified message to the log file

=item --summary | --no-summary

If set (default), only the primary entries of nuggit commands executed will be shown.  Otherwise, any additional records, for example of git commands logged by nuggit actions, will also be shown.

Viewing all entries may also be enabled with --verbose, --all, -v, or -a

=item --last

Display details on the last command logged.

=item --clear

Clear all entries from the log file (a new entry will be appended for this action)

=item --raw

View the log file in raw, unparsed format.

=item --today

Only show log entries from the past 24 hours.

=item --days | --hours

Only specify log entries from the specified number of days and/or hours (flags may be combined).

=item 

=back

=head1 TODO

- Support for clearing log by date or number of (prime) entries.
- Support for filtering log by date or limiting number of entries
- Less-like functionality?
- Support for disabling colorization (ie: --no-color => $ENV{ANSI_COLORS_DISABLED}=1 ?
- file option to allow parsing of specified log file. Bypasses is-a-nuggit check, not compatible with clear flag
- Option to export filtered log selection to a file (filtered by date only) for easy sharing
- Replay option?

=cut
