package Log::ger::App;

our $DATE = '2018-08-30'; # DATE
our $VERSION = '0.008'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

sub _level_from_env {
    my $prefix = shift;
    return $ENV{"${prefix}LOG_LEVEL"} if defined $ENV{"${prefix}LOG_LEVEL"};
    return 'trace' if $ENV{"${prefix}TRACE"};
    return 'debug' if $ENV{"${prefix}DEBUG"};
    return 'info'  if $ENV{"${prefix}VERBOSE"};
    return 'error' if $ENV{"${prefix}QUIET"};
    undef;
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
    my ($pkg, %args) = @_;

    require Log::ger;
    require Log::ger::Util;

    my $level = $args{level};
    $level = _level_from_env("") || 'warn' if !defined($level);
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
        my $level = _level_from_env("SCREEN_");
        last if defined $level && $level eq 'off';
        my $fmt = ($ENV{LOG_ADD_TIMESTAMP} ? '[%d] ': ''). '%m';
        $conf{outputs}{Screen} = {
            conf   => { formatter => sub { "$progname: $_[0]" } },
            level  => $level,
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
        my $level = _level_from_env("FILE_");
        last if defined $level && $level eq 'off';
        $conf{outputs}{File} = {
            conf   => { path => $path },
            level  => $level,
            layout => [Pattern => {format => '[pid %P] [%d] %m'}],
        };
    }

    # add Syslog
    {
        last unless $is_daemon;
        my $level = _level_from_env("SYSLOG_");
        last if defined $level && $level eq 'off';
        $conf{outputs}{Syslog} = {
            conf => { ident => $progname, facility => 'daemon' },
            level => $level,
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

version 0.008

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

The default is C<warn> (like L<Log::ger>'s default).

B<Via import argument.> You can set general log level via import argument (see
L</"import">) but users of your script will not be able to customize it.

B<Via environment variables.> You can also set general log level from
environment using C<LOG_LEVEL> (e.g. C<LOG_LEVEL=trace> to set level to trace or
C<LOG_LEVEL=0> to turn off logging). Alternatively, you can set to C<trace>
using C<TRACE=1>, or C<debug> with C<DEBUG=1>, C<info> with C<VERBOSE=1>,
C<error> with C<QUIET=1>.

=head2 Setting per-output log level

The default is to use general level, but you can set a different level for each
output using I<OUTPUT_NAME>_{C<LOG_LEVEL|TRACE|DEBUG|VERBOSE|QUIET>} environment
variables. For example, C<SCREEN_DEBUG=1> to set screen level to C<debug> or
C<FILE_LOG_LEVEL=off> to turn off file logging.

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

=item * level => str|num

Explicitly set level. Otherwise, the default will be taken from environment
variable like described previously in L</"DESCRIPTION">.

=item * name => str

Explicitly set program name. Otherwise, default will be taken from C<$0> (after
path and '.pl' suffix is removed) or set to C<prog>.

Program name will be shown on the screen, e.g.:

 myprog: First log message
 myprog: Doing task 1 ...
 myprog: Doing task 2 ...
 myprog: Exiting ...

=item * daemon => bool

Explicitly tell Log::ger::App that your application is a daemon or not.
Otherwise, Log::ger::App will try some heuristics to guess whether your
application is a daemon: from the value of C<$main::IS_DAEMON> and from the
presence of modules like L<HTTP::Daemon>, L<Proc::Daemon>, etc.

=item * outputs => hash

Specify extra outputs. Will be passed to L<Log::ger::Output::Composite>
configuration.

=back

=head1 ENVIRONMENT

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

=head1 SEE ALSO

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
