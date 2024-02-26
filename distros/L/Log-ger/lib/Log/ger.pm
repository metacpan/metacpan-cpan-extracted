## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-29'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.042'; # VERSION

#IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
#END IFUNBUILT

our $re_addr = qr/\(0x([0-9a-f]+)/o;

our %Levels = (
    fatal   => 10,
    error   => 20,
    warn    => 30,
    info    => 40,
    debug   => 50,
    trace   => 60,
);

our %Level_Aliases = (
    off     => 0,
    warning => 30,
);

our $Current_Level = 30;

our $Caller_Depth_Offset = 0;

# a flag that can be used by null output to skip using formatter
our $_outputter_is_null;

our $_dumper;

our %Global_Hooks;

# in Log/ger/Heavy.pm
# our %Default_Hooks = (

our %Package_Targets; # key = package name, value = \%per_target_conf
our %Per_Package_Hooks; # key = package name, value = { phase => hooks, ... }

our %Hash_Targets; # key = hash address, value = [$hashref, \%per_target_conf]
our %Per_Hash_Hooks; # key = hash address, value = { phase => hooks, ... }

our %Object_Targets; # key = object address, value = [$obj, \%per_target_conf]
our %Per_Object_Hooks; # key = object address, value = { phase => hooks, ... }

my $sub0 = sub {0};
my $sub1 = sub {1};
my $default_null_routines;

sub install_routines {
    my ($target, $target_arg, $routines, $name_routines) = @_;

    if ($name_routines && !defined &subname) {
        if (eval { require Sub::Name; 1 }) {
            *subname = \&Sub::Name::subname;
        } else {
            *subname = sub {};
        }
    }

    if ($target eq 'package') {
#IFUNBUILT
#         no warnings 'redefine';
#END IFUNBUILT
        for my $r (@$routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_sub\z/;
            #print "D:installing $name to package $target_arg\n";
            *{"$target_arg\::$name"} = $code;
            subname("$target_arg\::$name", $code) if $name_routines;
        }
    } elsif ($target eq 'object') {
#IFUNBUILT
#         no warnings 'redefine';
#END IFUNBUILT
        my $pkg = ref $target_arg;
        for my $r (@$routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_method\z/;
            *{"$pkg\::$name"} = $code;
            subname("$pkg\::$name", $code) if $name_routines;
        }
    } elsif ($target eq 'hash') {
        for my $r (@$routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_sub\z/;
            $target_arg->{$name} = $code;
        }
    }
}

sub add_target {
    my ($target_type, $target_name, $per_target_conf, $replace) = @_;
    $replace = 1 unless defined $replace;

    if ($target_type eq 'package') {
        unless ($replace) { return if $Package_Targets{$target_name} }
        $Package_Targets{$target_name} = $per_target_conf;
    } elsif ($target_type eq 'object') {
        my ($addr) = "$target_name" =~ $re_addr;
        unless ($replace) { return if $Object_Targets{$addr} }
        $Object_Targets{$addr} = [$target_name, $per_target_conf];
    } elsif ($target_type eq 'hash') {
        my ($addr) = "$target_name" =~ $re_addr;
        unless ($replace) { return if $Hash_Targets{$addr} }
        $Hash_Targets{$addr} = [$target_name, $per_target_conf];
    }
}

sub _set_default_null_routines {
    $default_null_routines ||= [
        (map {(
            [$sub0, "log_$_", $Levels{$_}, 'logger_sub'],
            [$Levels{$_} > $Current_Level ? $sub0 : $sub1, "log_is_$_", $Levels{$_}, 'level_checker_sub'],
            [$sub0, $_, $Levels{$_}, 'logger_method'],
            [$Levels{$_} > $Current_Level ? $sub0 : $sub1, "is_$_", $Levels{$_}, 'level_checker_method'],
        )} keys %Levels),
    ];
}

sub get_logger {
    my ($package, %per_target_conf) = @_;

    my $caller = caller(0);
    $per_target_conf{category} = $caller
        if !defined($per_target_conf{category});
    my $obj = []; $obj =~ $re_addr;
    my $pkg = "Log::ger::Obj$1"; bless $obj, $pkg;
    add_target(object => $obj, \%per_target_conf);
    if (keys %Global_Hooks) {
        require Log::ger::Heavy;
        init_target(object => $obj, \%per_target_conf);
    } else {
        # if we haven't added any hooks etc, skip init_target() process and use
        # this preconstructed routines as shortcut, to save startup overhead
        _set_default_null_routines();
        install_routines(object => $obj, $default_null_routines, 0);
    }
    $obj; # XXX add DESTROY to remove from list of targets
}

sub _import_to {
    my ($package, $target_pkg, %per_target_conf) = @_;

    $per_target_conf{category} = $target_pkg
        if !defined($per_target_conf{category});
    add_target(package => $target_pkg, \%per_target_conf);
    if (keys %Global_Hooks) {
        require Log::ger::Heavy;
        init_target(package => $target_pkg, \%per_target_conf);
    } else {
        # if we haven't added any hooks etc, skip init_target() process and use
        # this preconstructed routines as shortcut, to save startup overhead
        _set_default_null_routines();
        install_routines(package => $target_pkg, $default_null_routines, 0);
    }
}

sub import {
    my ($package, %per_target_conf) = @_;

    my $caller = caller(0);
    $package->_import_to($caller, %per_target_conf);
}

1;
# ABSTRACT: A lightweight, flexible logging framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger - A lightweight, flexible logging framework

=head1 VERSION

version 0.042

=head1 SYNOPSIS

=head2 Producing logs

In your module (producer):

 package MyModule;

 # this will install some logger routines. by default: log_trace, log_debug,
 # log_info, log_warn, log_error, and log_fatal. level checker routines are also
 # installed: log_is_trace, log_is_debug, and so on.
 use Log::ger;

 sub foo {
     ...
     # produce some logs. no need to configure output or level. by default
     # output goes nowhere.
     log_error "an error occured: %03d - %s", $errcode, $errmsg;
     ...

     # the logging routines (log_*) can automatically dump data structures
     log_debug "http response: %s", $http;

     # log_fatal does not die by default, if you want to then die() explicitly.
     # but there are plugins that let you do this or provide log_die etc.
     if (blah) { log_fatal "..."; die }

     # use the level checker routines (log_is_*) to avoid doing unnecessary
     # heavy calculation
     if (log_is_trace) {
         my $res = some_heavy_calculation();
         log_trace "The result is %s", $res;
     }

 }
 1;

=head2 Consuming logs

=head3 Choosing an output

In your application (consumer/listener):

 use MyModule;
 use Log::ger::Output 'Screen'; # configure output
 # level is by default 'warn'
 foo(); # the error message is shown, but debug/trace messages are not.

=head3 Choosing multiple outputs

Instead of screen, you can output to multiple outputs (including multiple
files):

 use Log::ger::Output 'Composite' => (
     outputs => {
         Screen => {},
         File   => [
             {conf=>{path=>'/path/to/app.log'}},
             ...
         ],
         ...
     },
 );

See L<Log::ger::Manual::Tutorial::481_Output_Composite> for more examples.

There is also L<Log::ger::App> that wraps this in a simple interface so you just
need to do:

 # In your application or script:
 use Log::ger::App;
 use MyModule;

=head3 Choosing level

One way to set level:

 use Log::ger::Util;
 Log::ger::Util::set_level('debug'); # be more verbose
 foo(); # the error message as well as debug message are now shown, but the trace is not

There are better ways, e.g. letting users configure log level via configuration
file or command-line option. See L<Log::ger::Manual::Tutorial::300_Level> for
more details.

=head1 DESCRIPTION

Log::ger is yet another logging framework with the following features:

=over

=item * Separation of producers and consumers/listeners

Like L<Log::Any>, this offers a very easy way for modules to produce some logs
without having to configure anything. Configuring output, level, etc can be done
in the application as log consumers/listeners. To read more about this, see the
documentation of L<Log::Any> or L<Log::ger::Manual> (but nevertheless see
L<Log::ger::Manual> on why you might prefer Log::ger to Log::Any).

=item * Lightweight and fast

B<Slim distribution.> No non-core dependencies, extra functionalities are
provided in separate distributions to be pulled as needed.

B<Low startup overhead.> Only ~0.5-1ms. For comparison, L<strict> ~0.2-0.5ms,
L<warnings> ~2ms, L<Log::Any> (v0.15) ~2-3ms, Log::Any (v1.049) ~8-10ms,
L<Log::Log4perl> ~35ms. This is measured on a 2014-2015 PC and before doing any
output configuration. I strive to make C<use Log::ger;> statement to be roughly
as light as C<use strict;> or C<use warnings;> so the impact of adding the
statement is really minimal and you can just add logging without much thought to
most of your modules. This is important to me because I want logging to be
pervasive.

To test for yourself, try e.g. with L<bencher-code>:

 % bencher-code 'use Log::ger' 'use Log::Any' --startup

B<Fast>. Low null-/stealth-logging overhead, about 1.5x faster than Log::Any, 3x
faster than Log4perl, 5x faster than L<Log::Fast>, ~40x faster than
L<Log::Contextual>, and ~100x faster than L<Log::Dispatch>.

For more benchmarks, see L<Bencher::Scenarios::Log::ger>.

B<Conditional compilation.> There is a plugin to optimize away unneeded logging
statements, like assertion/conditional compilation, so they have zero runtime
performance cost. See L<Log::ger::Plugin::OptAway>.

Being lightweight means the module can be used more universally, from CLI to
long-running daemons to inside routines with tight loops.

=item * Flexible

B<Customizable levels and routine/method names.> Can be used in a procedural or
OO style. Log::ger can mimic the interface of L<Log::Any>, L<Log::Contextual>,
L<Log::Log4perl>, or some other popular logging frameworks, to ease migration or
adjust with your personal style.

B<Per-package settings.> Each importer package can use its own format/layout,
output. For example, a module that is migrated from Log::Any uses Log::Any-style
logging, while another uses native Log::ger style, and yet some other uses block
formatting like Log::Contextual. This eases code migration and teamwork. Each
module author can preserve her own logging style, if wanted, and all the modules
still use the same framework.

B<Dynamic.> Outputs and levels can be changed anytime during run-time and logger
routines will be updated automatically. This is useful in situation like a
long-running server application: you can turn on tracing logs temporarily to
debug problems, then turn them off again, without restarting your server.

B<Interoperability.> There are modules to interop with Log::Any, either consume
Log::Any logs (see L<Log::Any::Adapter::LogGer>) or produce logs to be consumed
by Log::Any (see L<Log::ger::Output::LogAny>).

B<Many output modules and plugins.> See C<Log::ger::Output::*>,
C<Log::ger::Format::*>, C<Log::ger::Layout::*>, C<Log::ger::Plugin::*>. Writing
an output module in Log::ger is easier than writing a Log::Any::Adapter::*.

=back

For more documentation, start with L<Log::ger::Manual>.

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

Some other popular logging frameworks: L<Log::Any>, L<Log::Contextual>,
L<Log::Log4perl>, L<Log::Dispatch>, L<Log::Dispatchouli>.

If you still prefer debugging using the good old C<print()>, there's
L<Debug::Print>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
