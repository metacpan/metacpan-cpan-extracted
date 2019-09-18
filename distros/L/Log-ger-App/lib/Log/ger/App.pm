package Log::ger::App;

our $DATE = '2019-09-17'; # DATE
our $VERSION = '0.010'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

our $DEBUG = defined($ENV{LOG_GER_APP_DEBUG}) ? $ENV{LOG_GER_APP_DEBUG} : 0;

sub _set_level {
    my $name = shift;

    while (my ($source, $param, $note) = splice @_, 0, 3) {
        if ($source eq 'val') {
            if (defined $param) {
                warn "[lga] Setting $name to $param (from $note)\n" if $DEBUG;
                return $param;
            }
        } elsif ($source eq 'envset') {
            my $prefix = $param;
            if (defined $ENV{"${prefix}LOG_LEVEL"}) {
                my $val = $ENV{"${prefix}LOG_LEVEL"};
                warn "[lga] Setting $name to $val (from environment ${prefix}LOG_LEVEL)\n" if $DEBUG;
                return $val;
            }
            if ($ENV{"${prefix}TRACE"}) {
                warn "[lga] Setting $name to trace (from environment ${prefix}TRACE)\n" if $DEBUG;
                return 'trace';
            }
            if ($ENV{"${prefix}DEBUG"}) {
                warn "[lga] Setting $name to debug (from environment ${prefix}DEBUG)\n" if $DEBUG;
                return 'debug';
            }
            if ($ENV{"${prefix}VERBOSE"}) {
                warn "[lga] Setting $name to info (from environment ${prefix}VERBOSE)\n" if $DEBUG;
                return 'info';
            }
            if ($ENV{"${prefix}QUIET"}) {
                warn "[lga] Setting $name to trace (from environment ${prefix}QUIET)\n" if $DEBUG;
                return 'error';
            }
        } else {
            die "BUG: Unknown level source '$source'";
        }
    }
    'warn';
}

sub _is_daemon {
    return $main::IS_DAEMON if defined $main::IS_DAEMON;
    for (
        "App/Daemon.pm",
        "Daemon/Easy.pm",
        "Daemon/Daemonize.pm",
        "Daemon/Generic.pm",
        "Daemonise.pm",
        "Daemon/Simple.pm",
        "HTTP/Daemon.pm",
        "IO/Socket/INET/Daemon.pm",
        #"Mojo/Server/Daemon.pm", # simply loading Mojo::UserAgent will load this too
        "MooseX/Daemonize.pm",
        "Net/Daemon.pm",
        "Net/Server.pm",
        "Proc/Daemon.pm",
        "Proc/PID/File.pm",
        "Win32/Daemon/Simple.pm") {
        return 1 if $INC{$_};
    }
    0;
}

sub import {
    no warnings 'once'; # $Log::ger::Current_Level

    my ($pkg, %args) = @_;

    require Log::ger;
    require Log::ger::Util;

    my $level = _set_level(
        "general log level",
        val => $args{level}, "import argument 'level'",
        envset => "", "",
        val => $args{default_level}, "import argument 'default_level'",
        val => 'warn', "fallback value",
    );
    $Log::ger::Current_Level = Log::ger::Util::numeric_level($level);

    my $is_daemon = $args{daemon};
    $is_daemon = _is_daemon() if !defined($is_daemon);

    my $is_oneliner = $0 eq '-e';

    my $progname = $args{name};
    unless (defined $progname) {
        ($progname = $0) =~ s!.+/!!;
        $progname =~ s/\.pl$//;
    }
    unless (length $progname) {
        $progname = "prog";
    }

    # configuration for Log::ger::Output::Composite
    my %conf = (
        outputs => {},
    );

    # add Screen
    {
        last if $is_daemon;
        my $olevel = _set_level(
            "screen log level",
            envset => "SCREEN_", "",
            val => $level, "general log level",
        );
        last if $olevel eq 'off';
        my $fmt = ($ENV{LOG_ADD_TIMESTAMP} ? '[%d] ': ''). '%m';
        $conf{outputs}{Screen} = {
            conf   => { formatter => sub { "$progname: $_[0]" } },
            level  => $olevel,
            layout => [Pattern => {format => $fmt}],
        };
    }

    # add File
    {
        last if $0 eq '-';
        require PERLANCAR::File::HomeDir;
        my $path = $> ?
            PERLANCAR::File::HomeDir::get_my_home_dir()."/$progname.log" :
              "/var/log/$progname.log";
        my $olevel = _set_level(
            "file ($path) log level",
            envset => "FILE_", "",
            val => $level, "general log level",
        );
        last if $olevel eq 'off';
        $conf{outputs}{File} = {
            conf   => { path => $path },
            level  => $olevel,
            layout => [Pattern => {format => '[pid %P] [%d] %m'}],
        };
    }

    # add Syslog
    {
        last unless $is_daemon;
        my $olevel = _set_level(
            "syslog log level",
            envset => "SYSLOG_", "",
            val => $level, "general log level",
        );
        last if $olevel eq 'off';
        $conf{outputs}{Syslog} = {
            conf => { ident => $progname, facility => 'daemon' },
            level => $olevel,
        };
    }

    if ($args{outputs}) {
        $conf{outputs}{$_} = $args{outputs}{$_}
            for keys %{$args{outputs}{$_}};
    }

    require Log::ger::Output;
    Log::ger::Output->set('Composite', %conf);
}

1;
# ABSTRACT: An easy way to use Log::ger in applications

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::App - An easy way to use Log::ger in applications

=head1 VERSION

version 0.010

=head1 SYNOPSIS

In your script:

 use Log::ger::App;
 use Your::App::Module; # your module which uses Log::ger to do its logging

If you also do logging in your script:

 use Log::ger::App;
 use Log::ger;

 log_warn("Some log ...");

=head1 DESCRIPTION

This module basically loads L<Log::ger::Output::Composite> with some sensible
defaults and allows customizing some aspects via environment variable.

=head2 Default outputs

 Code                            Screen  File                   Syslog
 ------------------------------  ------  ----                   ------
 One-liner (-e)                  y       -                      -
 Script running as normal user   y       ~/PROGNAME.log         -
 Script running as root          y       /var/log/PROGNAME.log  -
 Daemon                          -       /var/log/PROGNAME.log  y

=head2 Determining if script is a daemon

Log::ger::App assumes your script is a daemon if some daemon-related modules are
loaded, e.g. L<App::Daemon>, L<HTTP::Daemon>, L<Net::Daemon>, etc (see the
source code for the complete list). Alternatively, you can also set
C<$main::IS_DAEMON> to 1 (0) to specifically state that your script is (not) a
daemon. Or, you can set it via import argument (see L</"import">).

=head2 Setting general log level

B<Via import argument 'level'.> You can set general log level via import
argument C<level> (see L</"import">) but users of your script will not be able
to customize it:

 use Log::ger::App level => 'debug'; # hard-coded to debug, not recommended

B<Via environment variables.> You can also set general log level from
environment using C<LOG_LEVEL> (e.g. C<LOG_LEVEL=trace> to set level to trace or
C<LOG_LEVEL=0> to turn off logging). Alternatively, you can set to C<trace>
using C<TRACE=1>, or C<debug> with C<DEBUG=1>, C<info> with C<VERBOSE=1>,
C<error> with C<QUIET=1>.

B<Via import argument 'default_level'>. If the environment variables does not
provide a value, next the import argument C<default_level> is consulted. This is
the preferred method of setting default level:

 use Log::ger::App default_level => 'info'; # be verbose by default. unless changed by env vars

C<warn>. The fallback level is warn, if all the above does not provide a value.

=head2 Setting per-output log level

B<Via environment variables.> You can set level for each output using
I<OUTPUT_NAME>_{C<LOG_LEVEL|TRACE|DEBUG|VERBOSE|QUIET>} environment variables.
For example, C<SCREEN_DEBUG=1> to set screen level to C<debug> or
C<FILE_LOG_LEVEL=off> to turn off file logging.

B<General level.> If the environment variables do not provide a value, the
general level (see L</"Setting general log level">) will be used.

=head2 Showing timestamp

Timestamps are shown in log files. On the screen, timestamps are not shown by
default. To show timestamps on the screen, set C<LOG_ADD_TIMESTAMP> to true. For
example, when timestamps are not shown:

 myprog: First log message
 myprog: Doing task 1 ...
 myprog: Doing task 2 ...

When timestamps are shown:

 myprog: [2018-08-30T15:14:50] First log message
 myprog: [2018-08-30T15:14:50] Doing task 1 ...
 myprog: [2018-08-30T15:15:01] Doing task 2 ...

=head1 FUNCTIONS

=head2 import

Usage:

 $pkg->import(%args)

Arguments:

=over

=item * level

str|num. Explicitly set a hard-coded level. Not recommended because of lack of
flexibility. See instead: L</default_level>.

=item * default_level

str|num. Instead of hard-coding level with L</level>, you can set a default
level. Environment variables will be consulted first (as described in
L</DESCRIPTION>) before falling back to this level.

=item * name

str. Explicitly set program name. Otherwise, default will be taken from C<$0>
(after path and '.pl' suffix is removed) or set to C<prog>.

Program name will be shown on the screen, e.g.:

 myprog: First log message
 myprog: Doing task 1 ...
 myprog: Doing task 2 ...
 myprog: Exiting ...

=item * daemon

bool. Explicitly tell Log::ger::App that your application is a daemon or not.
Otherwise, Log::ger::App will try some heuristics to guess whether your
application is a daemon: from the value of C<$main::IS_DAEMON> and from the
presence of modules like L<HTTP::Daemon>, L<Proc::Daemon>, etc.

=item * outputs

hash. Specify extra outputs. Will be passed to L<Log::ger::Output::Composite>
configuration.

=back

=head1 VARIABLES

=head2 $DEBUG

Default is false. If set to true, will show more details about how log level,
etc is set.

=head1 ENVIRONMENT

=head2 LOG_GER_APP_DEBUG

Used to set the default for C<$DEBUG>.

=head2 LOG_ADD_TIMESTAMP

Boolean. Default to false. If set to true, will add timestamps to the screen
log. Normally, timestamps will only be added to the file log.

=head2 LOG_LEVEL

String. Can be set to C<off> or numeric/string log level.

=head2 TRACE

Bool.

=head2 DEBUG

Bool.

=head2 VERBOSE

Bool.

=head2 QUIET

Bool.

=head2 SCREEN_LOG_LEVEL

=head2 SCREEN_TRACE

=head2 SCREEN_DEBUG

=head2 SCREEN_VERBOSE

=head2 SCREEN_QUIET

=head2 FILE_LOG_LEVEL

=head2 FILE_TRACE

=head2 FILE_DEBUG

=head2 FILE_VERBOSE

=head2 FILE_QUIET

=head2 SYSLOG_LOG_LEVEL

=head2 SYSLOG_TRACE

=head2 SYSLOG_DEBUG

=head2 SYSLOG_VERBOSE

=head2 SYSLOG_QUIET

=head1 FAQS

=head2 Why does re-setting log level (using Log::ger::Util::set_level) doesn't work?

(This FAQ item is from L<Log::ger::Output::Composite>'s, slightly modified).

The Log::ger::Output::Composite plugin that Log::ger::App uses sets its own
levels and logs using a multilevel routine (which gets called for all levels).
Re-setting log level dynamically via L<Log::ger::Util>'s C<set_level> will not
work as intended, which is fortunate or unfortunate depending on your need.

If you want to override all levels settings with a single value, you can use
C<Log::ger::Output::Composite::set_level>, for example:

 Log::ger::Util::set_level('trace'); # also set this too
 Log::ger::Output::Composite::set_level('trace');

This sets an internal level setting which is respected and has the highest
precedence so all levels settings will use this instead.

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
