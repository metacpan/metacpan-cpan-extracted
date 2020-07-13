=head1 NAME

Log::Handler - Log messages to several outputs.

=head1 SYNOPSIS

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(
        file => {
            filename => "file.log",
            maxlevel => "debug",
            minlevel => "warning",
        }
    );

    $log->warning("message");

Or

    use Log::Handler;

    my $log = Log::Handler->new(
        screen => {
            log_to   => "STDOUT",
            maxlevel => "debug",
            minlevel => "debug",
            message_layout => "%T [%L] %m (%C)",
        },
        screen => {
            log_to   => "STDOUT",
            maxlevel => "info",
            minlevel => "notice",
        },
        screen => {
            log_to   => "STDERR",
            maxlevel => "warning",
            minlevel => "emergency",
        },
    );

Or

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->config( config => "logger.conf" );

    # and maybe later

    $log->reload( config => "logger.conf" );

Or

    # create a application wide logger
    package MyApp;
    use Log::Handler;
    my $log = Log::Handler->create_logger("myapp");
    $log->add(screen => { maxlevel => "info" });
    $log->info("info message");

    # get logger with get_logger()
    package MyApp::Admin;
    use Log::Handler;
    my $log = Log::Handler->get_logger("myapp");
    $log->info("info message from MyApp::Admin");

=head1 DESCRIPTION

The C<Log::Handler> is a object oriented handler for logging, tracing and
debugging. It is very easy to use and provides a simple interface for
multiple output objects with lots of configuration parameters. You can
easily filter the amount of logged information on a per-output base,
define priorities, create patterns to format the messages and reload
the complete logging machine.

See the documentation for details.

=head1 IMPORTANT NOTES

Note that the default for option C<newline> is now set to TRUE and newlines
will be appended automatically to each message if no newline exists.

A long time I thought about this serious change and have come to
the decision to change it.

The default for option C<mode> from Log::Handler::Output::File is now
C<append> and not C<excl> anymore.

The methods C<reload()> and C<validate()> are new since version 0.62.
I tested it with Screen.pm, File.pm and DBI.pm and it runs fine.
If you find bugs then open a bug report please :-)

=head1 LOG LEVELS

There are eigth levels available:

    7   debug
    6   info
    5   notice
    4   warning, warn
    3   error, err
    2   critical, crit
    1   alert
    0   emergency, emerg

C<debug> is the highest and C<emergency> is the lowest level.

Level C<debug> is the highest level because it basically says to log
every peep.

=head1 LOG LEVEL METHODS

=head2 Level methods

=over 4

=item B<debug()>

=item B<info()>

=item B<notice()>

=item B<warning()>, B<warn()>

=item B<error()>, B<err()>

=item B<critical()>, B<crit()>

=item B<alert()>

=item B<emergency()>, B<emerg()>

=back

The call of a log level method is very simple:

    $log->info("Hello World! How are you?");

Or maybe:

    $log->info("Hello World!", "How are you?");

Both calls would log - if level INFO is active:

    Feb 01 12:56:31 [INFO] Hello World! How are you?

=head2 is_* methods

=over 4

=item B<is_debug()>

=item B<is_info()>

=item B<is_notice()>

=item B<is_warning()>, B<is_warn()>

=item B<is_error()>, B<is_err()>

=item B<is_critical()>, B<is_crit()>

=item B<is_alert()>

=item B<is_emergency()>, B<is_emerg()>

=back

These twelve methods could be very useful if you want to kwow if the current
level would log the message. All methods returns TRUE if the current set
of C<minlevel> and C<maxlevel> would log the message and FALSE if not.

=head1 SPECIAL LOG METHODS

=over 4

=item B<fatal>, B<is_fatal>

=item B<trace>

=item B<dump>

=item B<die>

=item B<log>

=back

For a full list take a look into the documentation of L<Log::Handler::Levels>.

=head1 METHODS

=head2 new()

Call C<new()> to create a new log handler object.

    my $log = Log::Handler->new();

=head2 add()

Call C<add()> to add a new output object.

The method expects 2 parts of options; the options for the handler and
the options for the output module you want to use. The output modules got it's own
documentation for all options.

Example:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(

        # Add "file output"
        file => {

            # handler options (see Log::Handler)
            timeformat      => "%Y/%m/%d %H:%M:%S",
            message_layout  => "%T [%L] %S: %m",
            maxlevel        => "debug",
            minlevel        => "emergency",
            die_on_errors   => 1,
            debug_trace     => 0,
            debug_mode      => 2,
            debug_skip      => 0,

            # file options (see Log::Handler::Output::File)
            filename        => "file.log",
            filelock        => 1,
            fileopen        => 1,
            reopen          => 1,
            autoflush       => 1,
            permissions     => "0660",
            utf8            => 1,

        }
    );

Take a look to L<Log::Handler::Examples> for more examples.

The following options are possible for the handler:

=over 4

=item B<maxlevel> and B<minlevel>

With these options it's possible to set the log levels for your program.

Example:

    maxlevel => "error"
    minlevel => "emergency"

    # or

    maxlevel => "err"
    minlevel => "emerg"

    # or

    maxlevel => 3
    minlevel => 0

It's possible to set the log level as string or as number. The default setting
for C<maxlevel> is C<warning> and the default setting for C<minlevel> is
C<emergency>.

Example: If C<maxlevel> is set to C<warning> and C<minlevel> to C<emergency>
then the levels C<warning>, C<error>, C<critical>, C<alert> and C<emergency>
would be logged.

You can set both to 8 or C<nothing> if you want to disable the logging machine.

=item B<timeformat>

The option C<timeformat> is used to set the format for the placeholder C<%T>.
The string is converted with C<POSIX::strftime>. The default format is set to
S<"%b %d %H:%M:%S"> and looks like

    Feb 01 12:56:31

If you would set the format to S<"%Y/%m/%d %H:%M:%S"> it would looks like

    2007/02/01 12:56:31

=item B<dateformat>

This options works like C<timeformat>. You can set a format that is used for
the placeholder C<%D>. It's just useful if you want to split the date and time:

    $log->add(file => {
        filename       => "file.log",
        dateformat     => "%Y-%m-%d",
        timeformat     => "%H:%M:%S",
        message_layout => "%D %T %L %m",
    });

    $log->error("an error here");

This looks like

    2007-02-01 12:56:31 ERROR an error here

This option is not used by default.

=item B<newline>

C<newline> is a very helpful option. It let the logger appends a newline to
the message if a newline doesn't exist.

    0 - do nothing
    1 - append a newline if not exist (default)

Example:

    $log->add(
        screen => {
            newline  => 1,
            maxlevel => "info",
        }
    );

    $log->info("message\n");
    $log->info("message");

In both cases the message would be logged with a newline at the end.

=item B<message_layout>

With this option it's possible to create your own message layout with different
placeholders in C<printf()> style. The available placeholders are:

    %L   Log level
    %T   Time or full timestamp (option timeformat)
    %D   Date (option dateformat)
    %P   PID
    %H   Hostname
    %U   User name
    %G   Group name
    %N   Newline
    %S   Program name
    %C   Caller - filename and line number
    %p   Caller - package name
    %f   Caller - file name
    %l   Caller - line number
    %s   Caller - subroutine name
    %r   Runtime in seconds since program start
    %t   Time measurement - replaced with the time since the last call of $log->$level
    %m   Message
    %%   Percent

The default message layout is set to S<"%T [%L] %m">.

As example the following code

    $log->alert("foo bar");

would log

    Feb 01 12:56:31 [ALERT] foo bar

If you set C<message_layout> to

    message_layout => "%T foo %L bar %m (%C)"

and call

    $log->info("baz");

then it would log

    Feb 01 12:56:31 foo INFO bar baz (script.pl, line 40)

Traces will be appended after the complete message.

You can create your own placeholders with the method C<set_pattern()>.

=item B<message_pattern>

This option is just useful if you want to forward messages to output
modules that needs the parts of a message as a hash reference - as
example L<Log::Handler::Output::Forward>, L<Log::Handler::Output::DBI>
or L<Log::Handler::Output::Screen>.

The option expects a list of placeholders:

    # as a array reference
    message_pattern => [ qw/%T %L %H %m/ ]

    # or as a string
    message_pattern => "%T %L %H %m"

The patterns will be replaced with real names as hash keys.

    %L   level
    %T   time
    %D   date
    %P   pid
    %H   hostname
    %U   user
    %G   group
    %N   newline
    %r   runtime
    %C   caller
    %p   package
    %f   filename
    %l   line
    %s   subroutine
    %S   progname
    %t   mtime
    %m   message

Here a full code example:

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(forward => {
        forward_to      => \&my_func,
        message_pattern => [ qw/%T %L %H %m/ ],
        message_layout  => "%m",
        maxlevel        => "info",
    });

    $log->info("a forwarded message");

    # now you can access it

    sub my_func {
        my $msg = shift;
        print "Timestamp: $msg->{time}\n";
        print "Level:     $msg->{level}\n";
        print "Hostname:  $msg->{hostname}\n";
        print "Message:   $msg->{message}\n";
    }

=item B<prepare_message>

C<prepare_message> is useful if you want to do something with the message before
it will be logged... maybe you want to create your own layout because message_layout
doesn't meet your claim.

    $log->add(
        screen => {
            newline => 1,
            message_layout  => "%m (%t)",
            message_pattern => [ qw/%T %L %H %m/ ],
            prepare_message => \&format,
        }
    );

    $log->error("foo");
    $log->error("bar");
    $log->error("baz");

    sub format {
        my $m = shift;

        $m->{message} = sprintf("%-20s %-20s %-20s %s",
            $m->{time}, $m->{level}, $m->{hostname}, $m->{message});
    }

The output looks like

    Mar 08 15:14:20      ERROR                h1434036             foo (0.039694)
    Mar 08 15:14:20      ERROR                h1434036             bar (0.000510)
    Mar 08 15:14:20      ERROR                h1434036             baz (0.000274)

=item B<priority>

With this option you can set the priority of your output objects. This means
that messages will be logged at first to the outputs with a higher priority.
If this option is not set then the default priority begins with 10 and will be
increased +1 with each output. Example:

We add a output with no priority

    $log->add(file => { filename => "file1.log" });

This output gets the priority of 10. Now we add another output

    $log->add(file => { filename => "file2.log" });

This output gets the priority of 11... and so on.

Messages would be logged at first to the output with the priority of 10 and then
to the output with the priority of 11. Now you can add another output and set the
priority to 1.

    $log->add(screen => { dump => 1, priority => 1 });

Messages would be logged now at first to the screen.

=item B<die_on_errors>

Set C<die_on_errors> to 0 if you don't want that the handler dies on failed
write operations.

    0 - to disable it
    1 - to enable it

If you set C<die_on_errors> to 0 then you have to control it yourself.

    $log->info("info message") or die $log->errstr();

    # or Log::Handler->errstr()
    # or Log::Handler::errstr()
    # or $Log::Handler::ERRSTR

=item B<remove_on_reload>

This option is set to 1 by default.

Take a look to the description of the method C<reload> for more
information about this option.

=item B<filter_message>

With this option it's possible to set a filter. If the filter is set then
only messages will be logged that match the filter. You can pass a regexp,
a code reference or a simple string. Example:

    $log->add(file => {
        filename => "file.log",
        maxlevel => 6,
        filter_message => qr/log this/,
        # or
        # filter_message => "log this",
        # filter_message => '^log only this$',
    });

    $log->info("log this");
    $log->info("but not that");

If you pass your own code then you have to check the message yourself.

    $log->add(file => {
        filename => "file.log",
        maxlevel => 6,
        filter_message => \&my_filter
    });

    # return TRUE if you want to log the message, FALSE if not
    sub my_filter {
        my $msg = shift;
        $msg->{message} =~ /your filter/;
    }

It's also possible to define a simple condition with matches. Just pass a
hash reference with the options C<matchN> and C<condition>. Example:

    $log->add(file => {
        filename => "file.log",
        maxlevel => 6,
        filter_message => {
            match1    => "log this",
            match2    => qr/with that/,
            match3    => "(?:or this|or that)",
            condition => "(match1 && match2) || match3",
        }
    });

NOTE that re-eval in regexes is not valid! Something like

    match1 => '(?{unlink("file.txt")})'

would cause an error!

=item B<skip_message>

This is the opposite of option C<filter_message>, but it's only possible to set
a simple string or regular expression.

    $log->add(file => {
        filename => "file.log",
        maxlevel => 6,
        skip => '^do not log this.+$'
    });

=item B<category>

The parameter C<category> works like C<filter_caller> but is much easier to configure.
You can set a comma separated list of modules. As example if you would set the category to

    category => "MyApp::User"

then all messages of MyApp::User and the submodules would be logged.

Example:

    my $log = Log::Handler->new();

    $log->add(
        screen => {
            maxlevel => "info",
            category => "MyApp::User, MyApp::Session"
        }
    );

    package MyApp;
    $log->info(__PACKAGE__);

    package MyApp::Products;
    $log->info(__PACKAGE__);

    package MyApp::User;
    $log->info(__PACKAGE__);

    package MyApp::Users;
    $log->info(__PACKAGE__);

    package MyApp::User::Settings;
    $log->info(__PACKAGE__);

    package MyApp::Session;
    $log->info(__PACKAGE__);

    package MyApp::Session::Settings;
    $log->info(__PACKAGE__);

The messages of C<MyApp> and C<MyApp::Products> would not be logged.

The usage of categories is much faster than to filter by caller.

=item B<filter_caller>

You can use this option to set a package name. Only messages from this
packages will be logged.

Example:

    my $log = Log::Handler->new();

    $log->add(screen => {
        maxlevel => "info",
        filter_caller  => qr/^Foo::Bar\z/,
        # or
        # filter_caller => "^Foo::Bar\z",
    });

    package Foo::Bar;
    $log->info("log this");

    package Foo::Baz;
    $log->info("but not that");

    1;

This would only log the message from the package C<Foo::Bar>.

=item B<except_caller>

This option is just the opposite of C<filter_caller>.

If you want to log messages from all callers but C<Foo::Bar>:

    except_caller => qr/^Foo::Bar\z/

=item B<alias>

You can set an alias if you want to get the output object later. Example:

    my $log = Log::Handler->new();

    $log->add(screen => {
        maxlevel => 7,
        alias    => "screen-out",
    });

    my $screen = $log->output("screen-out");

    $screen->log(message => "foo");

    # or in one step

    $log->output("screen-out")->log(message => "foo");

=item B<debug_trace>

You can activate a debugger that writes C<caller()> information about each
active log level. The debugger is logging all defined values except C<hints>
and C<bitmask>. Set C<debug_trace> to 1 to activate the debugger.
The debugger is set to 0 by default.

=item B<debug_mode>

There are two debug modes: line(1) and block(2) mode. The default mode is 1.

The line mode looks like this:

    use strict;
    use warnings;
    use Log::Handler;

    my $log = Log::Handler->new()

    $log->add(file => {
        filename    => "*STDOUT",
        maxlevel    => "debug",
        debug_trace => 1,
        debug_mode  => 1
    });

    sub test1 { $log->warning() }
    sub test2 { &test1; }

    &test2;

Output:

    Apr 26 12:54:11 [WARNING]
       CALL(4): package(main) filename(./trace.pl) line(15) subroutine(main::test2) hasargs(0)
       CALL(3): package(main) filename(./trace.pl) line(13) subroutine(main::test1) hasargs(0)
       CALL(2): package(main) filename(./trace.pl) line(12) subroutine(Log::Handler::__ANON__) hasargs(1)
       CALL(1): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(713) subroutine(Log::Handler::_write) hasargs(1)
       CALL(0): package(Log::Handler) filename(/usr/local/share/perl/5.8.8/Log/Handler.pm) line(1022) subroutine(Devel::Backtrace::new) hasargs(1) wantarray(0)

The same code example but the debugger in block mode would looks like this:

       debug_mode => 2

Output:

   Apr 26 12:52:17 [DEBUG]
      CALL(4):
         package     main
         filename    ./trace.pl
         line        15
         subroutine  main::test2
         hasargs     0
      CALL(3):
         package     main
         filename    ./trace.pl
         line        13
         subroutine  main::test1
         hasargs     0
      CALL(2):
         package     main
         filename    ./trace.pl
         line        12
         subroutine  Log::Handler::__ANON__
         hasargs     1
      CALL(1):
         package     Log::Handler
         filename    /usr/local/share/perl/5.8.8/Log/Handler.pm
         line        681
         subroutine  Log::Handler::_write
         hasargs     1
      CALL(0):
         package     Log::Handler
         filename    /usr/local/share/perl/5.8.8/Log/Handler.pm
         line        990
         subroutine  Devel::Backtrace::new
         hasargs     1
         wantarray   0

=item B<debug_skip>

This option let skip the C<caller()> information the count of C<debug_skip>.

=back

=head2 output()

Call C<output($alias)> to get the output object that you added with
the option C<alias>.

It's possible to access a output directly:

    $log->output($alias)->log(message => "booo");

For more information take a look to the option C<alias>.

=head2 flush()

Call C<flush()> if you want to send flush to all outputs that can flush.

Flush means to flush buffers and/or close and re-open outputs.

If you want to send it only to some outputs you can pass the aliases.

    $log->flush(); # flush all
    $log->flush("foo", "bar"); # flush only foo and bar

If option S<"die_on_errors"> is set to 0 then you can intercept errors with:

    $log->flush or die $log->errstr;

=head2 errstr()

Call C<errstr()> if you want to get the last error message. This is useful
if you set C<die_on_errors> to C<0> and the handler wouldn't die on failed
write operations.

    use Log::Handler;

    my $log = Log::Handler->new();

    $log->add(file => {
        filename      => "file.log",
        maxlevel      => "info",
        die_on_errors => 0,
    });

    $log->info("Hello World!") or die $log->errstr;

Or

    unless ( $log->info("Hello World!") ) {
        $error_string = $log->errstr;
        # do something with $error_string
    }

The exception is that the handler dies in any case if the call of C<new()> or
C<add()> fails because on missing or wrong settings!

=head2 config()

With this method it's possible to load your output configuration from a file.

    $log->config(config => "file.conf");

Or

    $log->config(config => {
        file => [
            {
                alias    => "error_log",
                filename => "error.log",
                maxlevel => "warning",
                minlevel => "emerg",
                priority => 1
            },
            {
                alias    => "common_log",
                filename => "common.log",
                maxlevel => "info",
                minlevel => "emerg",
                priority => 2
            },
        ],
        screen => {
            alias    => "screen",
            maxlevel => "debug",
            minlevel => "emerg",
            log_to   => "STDERR",
        },
    });

The key S<"default"> is used here to define default parameters for all file
outputs. All other keys (C<error_log>, C<common_log>) are used as aliases.

Take a look into the documentation of L<Log::Handler::Config> for more
information.

=head2 reload()

With the method C<reload()> it's possible to reload the logging
machine. Just pass the complete new configuration for all outputs,
it works exaclty like C<config()>.

At first you should know that it's highly recommended to set a alias for
each output. If you don't set a alias then the logger doesn't know which
output-objects to reload. If a output-objects doesn't have a alias then
the objects will be removed and the new configuration will be added.

Example:

logger.conf

    <file>
        alias    = debug
        filename = debug.log
        maxlevel = debug
        minlevel = emerg
    </file>

    <file>
        alias    = common
        filename = common.log
        maxlevel = info
        minlevel = emerg
    </file>

Load the configuration

    $log->config(config => "logger.conf");

Now change the configuration in logger.conf

    <file>
        alias    = common
        filename = common.log
        maxlevel = notice
        minlevel = emerg
    </file>

    <sendmail>
        alias   = sendmail
        from    = bar@foo.example
        to      = foo@bar.example
        subject = your subject
    </sendmail>

What happends now...

The file-output with the alias C<debug> will be removed,
the file-output with the alias C<common> will be
reloaded and the output with the alias C<sendmail> will be added.

If you don't want that output-objects will be removed
because they were added internal, then you can set the
option C<remove_on_reload> to 0.

Example:

    $log->config(config => "logger.conf");

    $log->add(
        forward => {
            forward_to => \&my_func,
            remove_on_reload => 0,
        }
    );

The forward-output is not removed after a reload.

=head2 validate()

The method C<validate()> expects the same arguments like C<config()> and C<reload()>.

Maybe you want to validate your options before you pass them to C<config()>
or C<reload()>.

Example:

    my $log = Log::Handler->new();

    $log->config( config => \%config );

    # and maybe later

    if ( $log->validate( config => \%new_config ) ) {
        $log->reload( config => \%new_config );
    } else {
        warn "unable to reload configuration";
        warn $log->errstr;
    }

=head2 set_pattern()

With this option you can set your own placeholders. Example:

    $log->set_pattern("%X", "key_name", sub { "value" });

    # or

    $log->set_pattern("%X", "key_name", "value");

Then you can use this pattern in your message layout:

    $log->add(file => {
        filename        => "file.log",
        message_layout  => "%X %m%N",
    });

Or use it with C<message_pattern>:

    sub func {
        my $m = shift;
        print "$m->{key_name} $m->{message}\n";
    }

    $log->add(forward => {
        forward_to      => \&func,
        message_pattern => "%X %m",
    });

Note: valid character for the key name are: C<[%\w\-\.]+>

=head2 set_level()

With this method it's possible to change the log level at runtime.

To change the log level it's necessary to use a alias - see option C<alias>.

    $log->set_level(
        $alias => { # option alias
            minlevel => $new_minlevel,
            maxlevel => $new_maxlevel,
        }
    );

=head2 set_default_param()

With this methods it's possible to overwrite the default settings for new outputs.

Normally you would do something like

    $log->add(
        file => {
            filename => "debug.log",
            maxlevel => "info",
            timeformat => "%b %d %Y %H:%M:%S",
            message_layout => "[%T] %L %P %t %m (%C)"
        }
    );

    $log->add(
        file => {
            filename => "error.log",
            maxlevel => "error",
            timeformat => "%b %d %Y %H:%M:%S",
            message_layout => "[%T] %L %P %t %m (%C)"
        }
    );

Now you can simplify it with

    $log->set_default_param(
        timeformat => "%b %d %Y %H:%M:%S",
        message_layout => "[%T] %L %P %t %m (%C)"
    );

    $logg->add(
        file => {
            filename => "debug.log",
            maxlevel => "info"
        }
    );

    $log->add(
        file => {
            filename => "error.log",
            maxlevel => "error"
        }
    );

=head2 create_logger()

C<create_logger()> is the same like C<new()> but it creates a global
logger.

    my $log = Log::Handler->create_logger("myapp");

=head2 get_logger()

With C<get_logger()> it's possible to get a logger that was created
with C<create_logger()> or with

    use Log::Handler "myapp";

Just call

    my $log = Log::Handler->get_logger("myapp");

If the logger does not exists then a new logger will be created
and returned.

=head2 exists_logger()

With C<exists_logger()> it's possible to check if a logger exists
and it returns TRUE or FALSE.

=head1 EXAMPLES

L<Log::Handler::Examples>

=head1 BENCHMARK

The benchmark (examples/benchmark/benchmark.pl) runs
on a Intel Core i7-920 with the following result:

    simple pattern output took     :  1 wallclock secs ( 1.26 usr +  0.01 sys =  1.27 CPU) @ 78740.16/s (n=100000)
    default pattern output took    :  2 wallclock secs ( 2.08 usr +  0.15 sys =  2.23 CPU) @ 44843.05/s (n=100000)
    complex pattern output took    :  4 wallclock secs ( 3.22 usr +  0.23 sys =  3.45 CPU) @ 28985.51/s (n=100000)
    message pattern output took    :  3 wallclock secs ( 2.72 usr +  0.16 sys =  2.88 CPU) @ 34722.22/s (n=100000)
    suppressed output took         :  0 wallclock secs ( 0.08 usr +  0.00 sys =  0.08 CPU) @ 1250000.00/s (n=100000)
    filtered caller output took    :  2 wallclock secs ( 2.10 usr +  0.68 sys =  2.78 CPU) @ 35971.22/s (n=100000)
    suppressed caller output took  :  1 wallclock secs ( 0.54 usr +  0.00 sys =  0.54 CPU) @ 185185.19/s (n=100000)
    filtered messages output took  :  3 wallclock secs ( 2.62 usr +  0.08 sys =  2.70 CPU) @ 37037.04/s (n=100000)

=head1 EXTENSIONS

Send me a mail if you have questions.

=head1 PREREQUISITES

Prerequisites for all modules:

    Carp
    Data::Dumper
    Fcntl
    Params::Validate
    POSIX
    Time::HiRes
    Sys::Hostname
    UNIVERSAL

Recommended modules:

    Config::General
    Config::Properties
    DBI
    IO::Socket
    Net::SMTP
    YAML

Just for the test suite:

    File::Spec
    Test::More

=head1 EXPORTS

No exports.

=head1 REPORT BUGS

Please report all bugs to <jschulz.cpan(at)bloonix.de>.

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=head1 QUESTIONS

Do you have any questions or ideas?

MAIL: <jschulz.cpan(at)bloonix.de>

IRC: irc.perl.org#perl

If you send me a mail then add Log::Handler into the subject.

=head1 COPYRIGHT

Copyright (C) 2007-2009 by Jonny Schulz. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Log::Handler;

use strict;
use warnings;
use Carp;
use Params::Validate qw//;
use Log::Handler::Output;
use Log::Handler::Config;
use Log::Handler::Pattern;
use UNIVERSAL;
use base qw(Log::Handler::Levels);

our $VERSION = "0.90";
our $ERRSTR  = "";

# $TRACE and $CALLER_LEVEL are both used as global
# variables in other packages as well. You shouldn't
# manipulate them if you don't know what you do.
#
# $TRACE is used to turn on/off tracing.
#
# $CALLER_LEVEL is used to determine the current caller level
our $CALLER_LEVEL = 0;
our $TRACE        = 0;

# safe logger by app
my %LOGGER;

# Some constants...
use constant PRIORITY => 10;
use constant BOOL_RX  => qr/^[01]\z/;
use constant NUMB_RX  => qr/^\d+\z/;
use constant LEVEL_RX => qr/^(?:
    8 | nothing   |
    7 | debug     |
    6 | info      |
    5 | notice    |
    4 | warning   | warn  |
    3 | error     | err   |
    2 | critical  | crit  |
    1 | alert     |
    0 | emergency | emerg |
        fatal
)\z/x;

# to convert minlevel and maxlevel to a number
our %LEVEL_BY_STRING = (
    DEBUG     =>  7,
    INFO      =>  6,
    NOTICE    =>  5,
    WARNING   =>  4,
    WARN      =>  4,
    ERROR     =>  3,
    ERR       =>  3,
    CRITICAL  =>  2,
    CRIT      =>  2,
    ALERT     =>  1,
    EMERGENCY =>  0,
    EMERG     =>  0,
    FATAL     =>  0,
);

# to iterate from minlevel to maxlevel and
# create an HoA with all active levels
our @LEVEL_BY_NUM = qw(
    EMERGENCY
    ALERT
    CRITICAL
    ERROR
    WARNING
    NOTICE
    INFO
    DEBUG
    NOTHING
);

# shortcuts for each output
our %AVAILABLE_OUTPUTS = (
    file     => "Log::Handler::Output::File",
    email    => "Log::Handler::Output::Email",
    sendmail => "Log::Handler::Output::Sendmail",
    forward  => "Log::Handler::Output::Forward",
    dbi      => "Log::Handler::Output::DBI",
    screen   => "Log::Handler::Output::Screen",
    socket   => "Log::Handler::Output::Socket",
    gearman  => "Log::Handler::Output::Gearman",
);

# use Log::Handler foo => "LOGFOO", bar => "LOGBAR";
# use Log::Handler qw/foo LOGFOO bar LOGBAR/;
sub import {
    return unless @_ > 1;
    my $class  = shift;
    my %create = @_ > 1 ? @_ : (@_, undef);
    my $caller = (caller)[0];

    foreach my $appl (keys %create) {
        my $export = $create{$appl};
        my $logger = ();

        if (!exists $LOGGER{$appl}) {
            $LOGGER{$appl} = __PACKAGE__->new();
        }

        if ($export) {
            no strict "refs";
            my $method = $caller."::".$export;
            *{$method} = sub { $LOGGER{$appl} };
        }
    }
}

sub get_logger {
    @_ == 2 || croak 'Usage: Log::Handler->get_logger($app)';
    my ($class, $logger) = @_;

    if (!exists $LOGGER{$logger}) {
        return $class->create_logger($logger);
    }

    return $LOGGER{$logger};
}

sub create_logger {
    @_ == 2 || croak 'Usage: Log::Handler->create_logger($app)';
    my ($class, $logger) = @_;

    if (!exists $LOGGER{$logger}) {
        $LOGGER{$logger} = __PACKAGE__->new();
    }

    return $LOGGER{$logger};
}

sub exists_logger {
    @_ == 2 || croak 'Usage: Log::Handler->exists_logger($app)';
    my ($class, $logger) = @_;

    if (exists $LOGGER{$logger}) {
        return 1;
    }

    return undef;
}

sub new {
    my $class = shift;

    my $self = bless {
        priority => PRIORITY,   # start priority
        levels   => { },        # outputs (Output.pm) stored by active levels
        alias    => { },        # outputs (Output.pm) stored by an alias
        outputs  => [ ],        # all Output::* objects - for flush()
        pattern  =>             # default pattern
            &Log::Handler::Pattern::get_pattern,
        param_defaults => { }
    }, $class;

    if (@_) {
        if ($_[0] eq "config") {
            $self->config(@_);
        } else {
            $self->add(@_);
        }
    }

    return $self;
}

sub add {
    my ($self, @args) = @_;

    if ($args[0] && $args[0] eq "config") {
        return $self->config(@args);
    }

    if (@args > 2) {
        if (@args % 2 != 0) {
            Carp::croak 'Odd number of arguments to Log::Handler::add';
        }
        while (@args) {
            my $type = shift @args;
            my $conf = shift @args;
            $self->add($type, $conf);
        }
        return 1;
    }

    # At first the config will be splitted into
    # the package name (Log::Handler::Output::*),
    # the options for the handler and the options
    # for the output-module.
    my ($package, $h_opts, $o_opts) = $self->_split_config(@args);

    # In the next step the handler options
    # must be validated.
    $h_opts = $self->_validate_options($h_opts);

    # Create the new output-object.
    my $output = $self->_new_output($package, $h_opts, $o_opts);

    # Add the output to $self.
    $self->_add_output($output);

    return 1;
}

sub config {
    @_ > 1 or Carp::croak 'Usage: $log->config( %param )';
    my $self   = shift;
    my $config = Log::Handler::Config->config(@_);

    # Structure:
    #   $config->{file} = [ output config ];
    #   $config->{dbi}  = [ output config ];

    foreach my $type (keys %$config) {
        for my $c (@{$config->{$type}}) {
            $self->add($type, $c);
        }
    }

    return 1;
}

sub validate {
    my $self   = shift;
    my @v_opts = (); # validated options

    eval {
        my $config = Log::Handler::Config->config(@_);

        foreach my $type (keys %$config) {
            foreach my $output_config (@{ $config->{$type} }) {
                my ($package, $h_opts, $o_opts) = $self->_split_config($type, $output_config);
                $h_opts = $self->_validate_options($h_opts);
                $o_opts = $package->validate($o_opts) or die $package->errstr;
                push @v_opts, { p => $package, h => $h_opts, o => $o_opts, n => $output_config };
            }
        }
    };

    if ($@) {
        return $self->_raise_error($@);
    }

    return \@v_opts;
}

sub reload {
    my $self = shift;
    my $opts = $self->validate(@_);

    if (!$opts) {
        return undef;
    }

    # Store all aliases that were reloaded or added,
    # because all output-objects that weren't reloaded
    # should be removed.
    my %reloaded = ();

    # Reload in a eval block to prevent that the
    # program dies - daemons shouldn't die :-)
    eval {
        foreach my $output_config (@$opts) {
            my $package = $output_config->{p}; # package name like Log::Handler::Output::File
            my $h_opts  = $output_config->{h}; # handler options to reload
            my $o_opts  = $output_config->{o}; # output options to reload
            my $n_opts  = $output_config->{n}; # add a new output
            my $alias   = $h_opts->{alias};

            $reloaded{$alias} = 1;

            # If the alias doesn't exists then a new
            # output-objects is created, otherwise the
            # output-object is reloaded.
            if (!$self->output($alias)) {
                # If the alias does not exists we use
                # the alias that was generated by validate().
                if (!exists $n_opts->{alias}) {
                    $n_opts->{alias} = $h_opts->{alias};
                }
                # Add the new output to Log::Handler
                $self->add($package => $n_opts);
            } else {
                $self->{alias}->{$alias}->reload($h_opts);
                $self->output($alias)->reload($o_opts)
                    or die $self->output($alias)->errstr;
            }
        }
    };

    if ($@) {
        return $self->_raise_error($@);
    }

    # Rebuild the arrays...
    $self->{levels}  = { };
    $self->{outputs} = [ ];

    foreach my $alias (keys %{ $self->{alias} }) {
        my $output = $self->{alias}->{$alias};

        # Delete all objects that wasn't reloaded and have
        # set the flag "remove_on_reload".

        if (!exists $reloaded{$alias} && $output->{remove_on_reload}) {
            # At this point the output object should be destroyed,
            # because the last reference was stored here.
            eval { delete $self->{alias}->{$alias} };

            if ($@) {
                warn $@;
            }
        } else {
            # At this point the output object should be destroyed,
            $self->_add_output($output);
        }
    }

    return 1;
}

sub set_default_param {
    my $self = shift;

    while (@_) {
        my $param = shift;
        my $value = shift;
        $self->{param_defaults}->{$param} = $value;
    }
}

sub set_pattern {
    (@_ == 3 || @_ == 4)
        or Carp::croak 'Usage: $log->set_pattern( $pattern, $name, $code )';

    my $self    = shift;
    my $pattern = shift;

    # If no $name is set then we use $pattern as name
    my ($name, $code) = @_ == 2 ? @_ : ($pattern, @_);

    if ($pattern !~ /^%[a-ln-z]\z/i) {
        Carp::croak "invalid pattern '$pattern'";
    }

    if (!defined $name || $name !~ /^[%\w\-\.]+\z/) {
        Carp::croak "invalid/missing name for pattern '$pattern'";
    }

    if (ref($code) ne "CODE") {
        my $str = $code;
        $code = sub { $str };
    }

    # Structure:
    #   $self->{pattern}->{"%X"}->{name} = "name-of-x";
    #   $self->{pattern}->{"%X"}->{code} = "value-of-x";
    $self->{pattern}->{$pattern}->{name} = $name;
    $self->{pattern}->{$pattern}->{code} = $code;
}

sub set_level {
    @_ == 3 or Carp::croak 'Usage: $log->set_level( $alias => { minlevel => $min, maxlevel => $max } )';
    my ($self, $name, $new) = @_;
    my $alias = $self->{alias};

    if (!exists $alias->{$name}) {
        Carp::croak "alias '$name' does not exists";
    }

    if (ref($new) ne "HASH") {
        Carp::croak "the second parameter to set_level() must be a hash reference";
    }

    if (!defined $new->{minlevel} && !defined $new->{maxlevel}) {
        Carp::croak "no new level given to set_level()";
    }

    foreach my $level (qw/minlevel maxlevel/) {
        next unless defined $new->{$level};

        if ($new->{$level} =~ LEVEL_RX) {
            $alias->{$name}->{$level} = $new->{$level};
            next if $new->{$level} =~ /^\d\z/;
            $new->{$level} = uc($new->{$level});
            $new->{$level} = $LEVEL_BY_STRING{ $new->{$level} };
            $alias->{$name}->{$level} = $new->{$level};
        } else {
            Carp::croak "invalid level set to set_level()";
        }
    }

    $alias->{$name}->{levels} = { };
    my $levels = $self->{levels} = { };

    foreach my $level_num ($alias->{$name}->{minlevel} .. $alias->{$name}->{maxlevel}) {
        my $level = $LEVEL_BY_NUM[ $level_num ];
        $alias->{$name}->{levels}->{$level} = 1;

        if ($level_num < 4) {
            $alias->{$name}->{levels}->{FATAL} = 1;
        }
    }

    foreach my $output (@{ $self->{outputs} }) {
        foreach my $level (keys %{$output->{levels}}) {
            if ($levels->{$level}) {
                my @old_order = @{$levels->{$level}};
                push @old_order, $output;
                $levels->{$level} = [
                    map  { $_->[0] }
                    sort { $a->[1] <=> $b->[1] }
                    map  { [ $_, $_->{priority} ] } @old_order
                ];
            } else {
                push @{$levels->{$level}}, $output;
            }
        }
    }

    return 1;
}

sub output {
    @_ == 2 or Carp::croak 'Usage: $log->output( $alias )';
    my ($self, $name) = @_;
    my $alias = $self->{alias};
    return exists $alias->{$name} ? $alias->{$name}->{output} : undef;
}

sub flush {
    my ($self, @alias) = @_;
    my $errors = ();

    if (@alias) {
        foreach my $name (@alias) {
            my $output = $self->output($name);
            next unless $output && UNIVERSAL::can($output, "flush");

            if ( !$output->flush ) {
                if ( defined $errors ) {
                    $errors .= "; " . $output->errstr;
                } else {
                    $errors = $output->errstr;
                }
            }
        }
    } else {
        foreach my $output (@{$self->{outputs}}) {
            next unless UNIVERSAL::can($output, "flush");

            if ( !$output->flush ) {
                if ( defined $errors ) {
                    $errors .= "; " . $output->errstr;
                } else {
                    $errors = $output->errstr;
                }
            }
        }
    }

    return defined $errors ? $self->_raise_error($errors) : 1;
}

sub errstr {
    return $ERRSTR;
}

#
# private stuff
#

sub _build_params {
    my $self = shift;

    my %params = (
        timeformat => {
            type => Params::Validate::SCALAR,
            default => "%b %d %H:%M:%S",
        },
        dateformat => {
            type => Params::Validate::SCALAR,
            default => "%b %d %Y",
        },
        message_layout => {
            type => Params::Validate::SCALAR,
            default => "%T [%L] %m",
        },
        message_pattern => {
            type => Params::Validate::SCALAR
                  | Params::Validate::ARRAYREF,
            optional => 1,
        },
        prepare_message => {
            type => Params::Validate::CODEREF,
            optional => 1,
        },
        newline => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 1,
        },
        minlevel => {
            type => Params::Validate::SCALAR,
            regex => LEVEL_RX,
            default => 0,
        },
        maxlevel => {
            type => Params::Validate::SCALAR,
            regex => LEVEL_RX,
            default => 4,
        },
        die_on_errors => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 1,
        },
        priority => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
            default => undef,
        },
        debug_trace => {
            type => Params::Validate::SCALAR,
            regex => BOOL_RX,
            default => 0,
        },
        debug_mode => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
            default => 1,
        },
        debug_skip => {
            type => Params::Validate::SCALAR,
            regex => NUMB_RX,
            default => 0,
        },
        alias => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        skip_message => {
            type => Params::Validate::SCALAR,
            optional => 1
        },
        filter_message => {
            type => Params::Validate::SCALAR    # "foo"
                  | Params::Validate::SCALARREF # qr/foo/
                  | Params::Validate::CODEREF   # sub { shift->{message} =~ /foo/ }
                  | Params::Validate::HASHREF,  # matchN, condition
            optional => 1,
        },
        filter_caller => {
            type => Params::Validate::SCALAR | Params::Validate::SCALARREF,
            optional => 1,
        },
        category => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        except_caller => {
            type => Params::Validate::SCALAR | Params::Validate::SCALARREF,
            optional => 1,
        },
        remove_on_reload => {
            type => Params::Validate::SCALAR,
            default => 1,
        }
    );

    foreach my $param (keys %{$self->{param_defaults}}) {
        if (!exists $params{$param}) {
            Carp::croak "parameter '$param' does not exists";
        }
        $params{$param}{default} = $self->{param_defaults}->{$param};
    }

    return \%params;
}

sub _split_config {
    my $self = shift;
    my $type = shift;
    my $args = shift || { };
    my $package = ();

    # Split the handler and output options from $args.
    my ($handler_opts, $output_opts) = $self->_split_options($args);

    # Try to determine which output is wanted...
    if (exists $AVAILABLE_OUTPUTS{$type}) {
        $package = $AVAILABLE_OUTPUTS{$type};
    } elsif ($type =~ /::/) {
        $package = $type;
    } else {
        $package = "Log::Handler::Output::" . ucfirst($type);
    }

    eval "require $package";

    if ($@) {
        Carp::croak($@);
    }

    return ($package, $handler_opts, $output_opts);
}

sub _new_output {
    my ($self, $package, $h_opts, $o_opts) = @_;

    my $o_obj = $package->new($o_opts)
        or Carp::croak $package->errstr;

    my $o_main_obj = Log::Handler::Output->new($h_opts, $o_obj);

    return $o_main_obj;
}

sub _split_options {
    my ($self, $opts) = @_;
    my (%handler_opts, %output_opts);

    # It's possible to pass all options for the handler and for the
    # output to add(). These options must be splitted. The options
    # for the handler will be passed to Log::Handler::Output. The
    # options for the output will be passed - as example - to
    # Log::Handler::Output::File.

    my %split_options = map { $_ => 0 } qw(
        alias
        debug_mode
        debug_skip
        debug_trace
        die_on_errors
        filter
        filter_message
        filter_caller
        skip_message
        except_caller
        maxlevel
        message_layout
        message_pattern
        prepare_message
        minlevel
        newline
        priority
        timeformat
        dateformat
        remove_on_reload
        category
    );

    foreach my $key (keys %$opts) {
        if (exists $split_options{$key}) {
            $handler_opts{$key} = $opts->{$key};
        } else {
            $output_opts{$key} = $opts->{$key};
        }
    }

    return (\%handler_opts, \%output_opts);
}

sub _add_output {
    my ($self, $output) = @_;
    my $levels = $self->{levels};

    # Structure:
    #   $self->{levels}->{INFO} = [ outputs ordered by priority ]
    #
    # All outputs that would log the level INFO will be stored to the
    # hash-tree $self->{levels}->{INFO}. On this way it's possible
    # to check very fast if the level is active
    #
    #   my $levels = $self->{levels};
    #   if (exists $levels->{INFO}) { ... }
    #
    # and loop over all output objects and pass the message to it.

    foreach my $level (keys %{$output->{levels}}) {
        if ($levels->{$level}) {
            my @old_order = @{$levels->{$level}};
            push @old_order, $output;
            $levels->{$level} = [
                map  { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map  { [ $_, $_->{priority} ] } @old_order
            ];
        } else {
            push @{$levels->{$level}}, $output;
        }
    }

    # Structure:
    #   $self->{alias}->{$alias} = $output_object
    #
    # All outputs with an alias are stored to this hash tree.
    # Each output can be fetched with output($alias);

    if ($output->{alias}) {
        my $alias = $output->{alias};
        $self->{alias}->{$alias} = $output;
    }

    # save all outputs here
    push @{$self->{outputs}}, $output;
}

sub _validate_options {
    my ($self, @args) = @_;
    my $pattern = $self->{pattern};
    my $alias   = $self->{alias};
    my %wanted  = ();

    # Option "filter" is deprecated.
    if (exists $args[0]{filter}) {
        $args[0]{filter_message} = delete $args[0]{filter};
    }

    my %options = Params::Validate::validate(@args, $self->_build_params);

    if ($options{category}) {
        my $category = $options{category};
        $category =~ s/\s//g;
        $category = "^(?:" . join("|", map { $_ } split(/,/, $category) ) . ")(?:::|\\z)";
        $options{category} = qr/$category/;
    }

    if (!$options{alias}) {
        for (;;) {
            my $rand = rand();

            if (exists $alias->{$rand}) {
                next;
            }

            $options{alias} = $rand;
            last;
        }
    }

    if ($options{filter_message}) {
        $options{filter_message} = $self->_validate_filter($options{filter_message});
    }

    # set a default priority if not set
    if (!defined $options{priority}) {
        $options{priority} = $self->{priority}++;
    }

    # replace the level strings with numbers
    foreach my $opt (qw/minlevel maxlevel/) {
        next if $options{$opt} =~ /^\d\z/;
        my $level = uc($options{$opt});
        $options{$opt} = $LEVEL_BY_STRING{$level};
    }

    # iterate from minlevel to maxlevel and create
    # a hash tree with all active levels
    foreach my $level_num ($options{minlevel} .. $options{maxlevel}) {
        my $level = $LEVEL_BY_NUM[ $level_num ];
        $options{levels}{$level} = 1;
        next if $level_num > 3;
        $options{levels}{FATAL} = 1;
    }

    if ($options{message_pattern}) {
        if (!ref($options{message_pattern})) {
            $options{message_pattern} = [ split /\s+/, $options{message_pattern} ];
        }
        foreach my $p (@{$options{message_pattern}}) {
            if (!exists $pattern->{$p}) {
                Carp::croak "undefined pattern '$p'";
            }
            $wanted{$p} = undef;
        }

        # If message_pattern is set to "%T %L %m" then the code
        # should looks like:
        #
        #   sub {
        #       my ($w, $m) = @_; # %wanted pattern, %message
        #       $m->{$_} = $w->{$_} for qw/time level message/;
        #   }

        my $func = 'sub { my ($w, $m) = @_; $m->{$_} = $w->{$_} for qw/';
        $func .= join(" ", map { $pattern->{$_}->{name} } keys %wanted);
        $func .= "/ }";
        $options{message_pattern_func} = $func;
        $options{message_pattern_code} = eval $func;
        Carp::croak $@ if $@;
    }

    if ($options{message_layout}) {
        my (@chunks, $func);

        # If the message layout is set to "%T [%L] %m" then the code
        # should looks like:
        #
        #   sub {
        #       my ($w, $m) = @_; # %wanted pattern, %message
        #       $m->{"message"} =
        #           $w->{"time"}
        #           . " ["
        #           . $w->{"level"}
        #           . "] "
        #           . $w->{"message"}
        #       );
        #   }

        foreach my $p ( split /(?:(%[a-zA-Z])|(%)%)/, $options{message_layout} ) {
            next unless defined $p && length($p);
            if ( exists $pattern->{$p} ) {
                $wanted{$p} = undef;
                my $name = $pattern->{$p}->{name};
                push @chunks, "\$w->{'$name'}";
            } else {
                # quote backslash and apostrophe
                $p =~ s/\\/\\\\/g;
                $p =~ s/'/\\'/g;
                push @chunks, "'$p'";
            }
        }

        if (@chunks) {
            $func  = 'sub { my ($w, $m) = @_; $m->{message} = ';
            $func .= join(".", @chunks);
            $func .= " }";
        }

        $options{message_layout_func} = $func;
        $options{message_layout_code} = eval $func;
        Carp::croak $@ if $@;
    }

    # %m is default
    delete $wanted{"%m"};

    # The references to the patterns are stored to all outputs.
    # If a pattern will be changed with set_pattern() then the
    # changed pattern is available for each output.
    $options{wanted_pattern} = [ map { $pattern->{$_} } keys %wanted ];
    return \%options;
}

sub _validate_filter {
    my ($self, $args) = @_;
    my $ref = ref($args);
    my %filter;

    # A filter can be passed as CODE, as a Regexp, as a simple string
    # that will be embed in a Regexp or as a condition.

    if ($ref eq "CODE") {
        $filter{code} = $args;
    } elsif ($ref eq "Regexp") {
        $filter{code} = sub { $_[0]->{message} =~ $args };
    } elsif (!$ref) {
        $filter{code} = sub { $_[0]->{message} =~ /$args/ };
    } else {
        %filter = %$args;

        # Structure:
        #   $filter->{code}             = &code
        #   $filter->{func}             = $code_as_string
        #   $filter->{condition}        = $users_condition
        #   $filter->{result}->{matchN} = $result_of_matchN
        #   $filter->{matchN}           = qr//
        #
        # Each matchN will be checked on the message and the BOOL results
        # will be stored to $filter->{result}->{matchN}. Then the results
        # will be passed to &code. &code returns 0 or 1.
        #
        # As example if the filter is set to
        #
        #   filter => {
        #       match1    => qr/foo/,
        #       match2    => qr/bar/,
        #       condition => "(match1 && match2)",
        #   }
        #
        # Then the bool results will be saved:
        #
        #   $filter->{result}->{match1} = $message =~ $filter->{match1};
        #   $filter->{result}->{match2} = $message =~ $filter->{match2};
        #
        # The code for the filter should looks like:
        #
        #   $filter->{code} =
        #       sub {
        #           my $m = shift;
        #           ($m->{match1} && $m->{match2})
        #       }
        #
        #   &$code($filter->{result});

        if (!defined $filter{condition} || $filter{condition} !~ /\w/) {
            Carp::croak "missing condition for paramater 'filter'";
        }

        # Remove all valid characters from the condition
        # and check if invalid characters left.
        my $cond = $filter{condition};
        $cond =~ s/match\d+//g;
        $cond =~ s/[()&|!<>=\s\d]+//;

        if ($cond) {
            Carp::croak "invalid characters in condition: '$cond'";
        }

        foreach my $m ($filter{condition} =~ /(match\d+)/g) {
            if (!exists $filter{$m}) {
                Carp::croak "missing regexp for $m";
            }
            $ref = ref($filter{$m});
            if (!$ref) {
                $filter{$m} = qr/$filter{$m}/;
            } elsif ($ref ne "Regexp") {
                Carp::croak "invalid value for option 'filter:$m'";
            }
            $filter{result}{$m} = "";
        }

        $filter{func}  =  'sub { my $m = shift; ';
        $filter{func} .=  $filter{condition}."; }";
        $filter{func}  =~ s/(match\d+)/\$m->{$1}/g;
        $filter{code}  =  eval $filter{func};
    }

    return \%filter;
}

sub _raise_error {
    $ERRSTR = $_[1];
    return undef;
}

1;
