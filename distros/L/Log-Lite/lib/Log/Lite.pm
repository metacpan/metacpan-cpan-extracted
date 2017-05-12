package Log::Lite;
use strict;
use warnings;
use POSIX qw(strftime);
use Fcntl qw(:flock);
use File::Path qw(make_path);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(logrotate logmode logpath logsregex log);
our $VERSION   = '0.14';
our $LOGPATH;
our $LOGMODE   = 'log';    # or debug|slient
our $LOGROTATE = 'day';    # or month|year|no
our $LOGSREGEX = "[\t\r\n]";

sub logsregex
{
    my $regex = shift;
	$LOGSREGEX = $regex;
    return 1;
}

sub logrotate
{
    my $rotate = shift;
    if (   $rotate eq 'day'
        or $rotate eq 'month'
        or $rotate eq 'year'
        or $rotate eq 'no')
    {
        $LOGROTATE = $rotate;
    }
    return 1;
}

sub logmode
{
    my $mode = shift;
    if ($mode eq 'debug' or $mode eq 'log')
    {
        $LOGMODE = $mode;
    }
    return 1;
}

sub logpath
{
    my $path = shift;
    if (substr($path, 0, 1) ne '/' and $path !~ /^[a-zA-Z]\:\\/ and $ENV{'PWD'})
    {
        $path = $ENV{'PWD'} . "/" . $path;
    }

    $LOGPATH = $path;
    return 1;
}

sub log
{
    return 0 unless $_[0];
    my $logtype = shift;
    my $log = strftime "%Y-%m-%d %H:%M:%S", localtime;
    foreach (@_)
    {
        my $str = $_;
        $str =~ s/$LOGSREGEX//g if defined $str;
        $log .= "\t" . $str if defined $str;
    }
    $log .= "\n";

    if ($LOGMODE eq 'slient')
    {
        return 1;
    }

    if ($LOGMODE eq 'debug')
    {
        print STDERR "[Log::Lite]$log";
        return 1;
    }

    my $logpath = $LOGPATH ? $LOGPATH : 'log';
    my $date_str = '';
    if ($LOGROTATE ne 'no')
    {
        $date_str .= '_';
        if ($LOGROTATE eq 'day')
        {
            $date_str .= strftime "%Y%m%d", localtime;
        }
        elsif ($LOGROTATE eq 'month')
        {
            $date_str .= strftime "%Y%m", localtime;
        }
        elsif ($LOGROTATE eq 'year')
        {
            $date_str .= strftime "%Y", localtime;
        }
    }
    my $logfile = $logpath . "/" . $logtype . $date_str . ".log";
    if (-d $logpath or make_path($logpath, {verbose => 0, mode => 0755}))
    {
        open my $fh, ">>", $logfile;
        flock $fh, LOCK_EX;
        print $fh $log;
        flock $fh, LOCK_UN;
        close $fh;
        return 1;
    }
    else
    {
        print STDERR "[Log::Lite]error mkdir $logpath";
        return 0;
    }
}

1;
__END__

=head1 NAME

Log::Lite - Log info in local file


=head1 SYNOPSIS

  use Log::Lite qw(logrotate logmode logpath log);

  # Optional methods
  logrotate("day");		#autocut logfile every day (Default)
  logrotate("month");		#autocut logfile every month 
  logrotate("year");		#autocut logfile every year 
  logrotate("no");		#disable autocut

  logmode("log");		#log in file (Default)
  logmode("debug");		#output to STDERR
  logmode("slient");		#do nothing

  logpath("/tmp/mylogpath");	#defined where log files stored
  logpath("mylogpath");		#relative path is ok

  logsregex("stopword");		#set a regex use to remove words that you do not want to log. Default is [\r\n\t]

  # Main method
  log("access", "user1", "ip1", "script"); #log in ./log/access_20110206.log
  log("access", "user2", "ip2", "script");  #log in the same file as above 
  log("debug", "some", "debug", "info", "in", "code"); #log in ./log/debug_20110206.log
  log("error", "error information"); # could accept any number of arguments


=head1 DESCRIPTION

Module Feature:

1. auto create file named by the first argument.

2. support auto cut log file everyday,everymonth,everyyear.

3. thread safety (open-lock-write-unlock-close everytime).

4. support log/debug/slient mode.


=head1 METHODS

=head2 logrotate($rotate_mode)

Optional. 

"day"	: auto cut log file every day

"month"	: auto cut log file every month

"year"	: auto cut log file every year

"day" by default.


=head2 logmode($mode)

Optional. 

"log"   	: log in file

"debug" 	: print to STDERR

"slient"	: do nothing

"log" by default.


=head2 logsregex($stopword_regex)

Optional. Set a regex here.

You can use this function to remove those the words you don't want to log.

"[\r\n\t]" by default.



=head2 logpath($path)

Optional. 

Defined logpath. "./log" by default.

With strawberry perl on windows, you should turn the path, write like below.


  logpath("C:\\User\\Yourname");


=head2 log($type, $content1, $content2, $content3, ...)

Main method.

Log things.


=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Log::Log4perl>, L<Log::Minimal>

=cut

