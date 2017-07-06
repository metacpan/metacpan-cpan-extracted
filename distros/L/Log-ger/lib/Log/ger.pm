package Log::ger;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.012'; # VERSION

#IFUNBUILT
# # use strict;
# # use warnings;
#END IFUNBUILT

our %Levels = (
    fatal   => 1,
    error   => 2,
    warn    => 3,
    info    => 4,
    debug   => 5,
    trace   => 6,
);

our %Level_Aliases = (
    off => 0,
    warning => 3,
);

our $Current_Level = 3;

our $Caller_Depth_Offset = 0;

# a flag that can be used by null output to skip using formatter
our $_logger_is_null;

our $_dumper;

our %Global_Hooks;

# key = phase, value = [ [key, prio, coderef], ... ]
our %Default_Hooks = (
    create_formatter => [
        [__PACKAGE__, 90,
         # the default formatter is sprintf-style that dumps data structures
         # arguments as well as undef as '<undef>'.
         sub {
             my %args = @_;

             my $formatter = sub {
                 return $_[0] if @_ < 2;
                 my $fmt = shift;
                 my @args;
                 for (@_) {
                     if (!defined($_)) {
                         push @args, '<undef>';
                     } elsif (ref $_) {
                         require Log::ger::Util unless $_dumper;
                         push @args, Log::ger::Util::_dump($_);
                     } else {
                         push @args, $_;
                     }
                 }
                 sprintf $fmt, @args;
             };
             [$formatter];
         }],
    ],

    create_layouter => [],

    create_routine_names => [
        [__PACKAGE__, 90,
         # the default names are log_LEVEL() and log_is_LEVEL() for subroutine
         # names, or LEVEL() and is_LEVEL() for method names
         sub {
             my %args = @_;

             my $levels = [keys %Levels];

             return [{
                 log_subs    => [map { ["log_$_", $_]    } @$levels],
                 is_subs     => [map { ["log_is_$_", $_] } @$levels],
                 # used when installing to hash or object
                 log_methods => [map { ["$_", $_]        } @$levels],
                 is_methods  => [map { ["is_$_", $_]     } @$levels],
             }, 1];
         }],
    ],

    create_log_routine => [
        [__PACKAGE__, 10,
         # the default behavior is to create a null routine for levels that are
         # too high than the global level ($Current_Level). since we run at high
         # priority (10), this block typical output plugins at normal priority
         # (50). this is a convenience so normally a plugin does not have to
         # deal with level checking.
         sub {
             my %args = @_;
             my $level = $args{level};
             if (defined($level) && (
                 $Current_Level < $level ||
                     # there's only us
                     @{ $Global_Hooks{create_log_routine} } == 1)
             ) {
                 $_logger_is_null = 1;
                 return [sub {0}];
             }
             [undef]; # decline
         }],
    ],

    create_logml_routine => [],

    create_is_routine => [
        [__PACKAGE__, 90,
         # the default behavior is to compare to global level. normally this
         # behavior suffices. we run at low priority (90) so normal plugins
         # which typically use priority 50 can override us.
         sub {
             my %args = @_;
             my $level = $args{level};
             [sub { $Current_Level >= $level }];
         }],
    ],

    before_install_routines => [],

    after_install_routines => [],
);

for my $phase (keys %Default_Hooks) {
    $Global_Hooks{$phase} = [@{ $Default_Hooks{$phase} }];
}

our %Package_Targets; # key = package name, value = \%init_args
our %Per_Package_Hooks; # key = package name, value = { phase => hooks, ... }

our %Hash_Targets; # key = hash address, value = [$hashref, \%init_args]
our %Per_Hash_Hooks; # key = hash address, value = { phase => hooks, ... }

our %Object_Targets; # key = object address, value = [$obj, \%init_args]
our %Per_Object_Hooks; # key = object address, value = { phase => hooks, ... }

# if flow_control is 1, stops after the first hook that gives non-undef result.
# flow_control can also be a coderef that will be called after each hook with
# ($hook, $hook_res) and can return 1 to mean stop.
sub run_hooks {
    my ($phase, $hook_args, $flow_control,
        $target, $target_arg) = @_;
    #print "D: running hooks for phase $phase\n";

    $Global_Hooks{$phase} or die "Unknown phase '$phase'";
    my @hooks = @{ $Global_Hooks{$phase} };

    if ($target eq 'package') {
        unshift @hooks, @{ $Per_Package_Hooks{$target_arg}{$phase} || [] };
    } elsif ($target eq 'hash') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unshift @hooks, @{ $Per_Hash_Hooks{$addr}{$phase} || [] };
    } elsif ($target eq 'object') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unshift @hooks, @{ $Per_Object_Hooks{$target_arg}{$phase} || [] };
    }

    my $res;
    for my $hook (sort {$a->[1] <=> $b->[1]} @hooks)  {
        my $hook_res = $hook->[2]->(%$hook_args);
        if (defined $hook_res->[0]) {
            $res = $hook_res->[0];
            #print "D:   got result from hook $res\n";
            if (ref $flow_control eq 'CODE') {
                last if $flow_control->($hook, $hook_res);
            } else {
                last if $flow_control;
            }
        }
        last if $hook_res->[1];
    }
    return $res;
}

sub add_target {
    my ($target, $target_arg, $args, $replace) = @_;
    $replace = 1 unless defined $replace;

    if ($target eq 'package') {
        unless ($replace) { return if $Package_Targets{$target_arg} }
        $Package_Targets{$target_arg} = $args;
    } elsif ($target eq 'object') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unless ($replace) { return if $Object_Targets{$addr} }
        $Object_Targets{$addr} = [$target_arg, $args];
    } elsif ($target eq 'hash') {
        my ($addr) = "$target_arg" =~ /\(0x(\w+)/;
        unless ($replace) { return if $Hash_Targets{$addr} }
        $Hash_Targets{$addr} = [$target_arg, $args];
    }
}

sub init_target {
    my ($target, $target_arg, $init_args) = @_;

    #print "D:init_target($target, $target_arg, ...)\n";
    my %hook_args = (
        target     => $target,
        target_arg => $target_arg,
        init_args  => $init_args,
    );

    my $formatter =
        run_hooks('create_formatter', \%hook_args, 1, $target, $target_arg);

    my $layouter =
        run_hooks('create_layouter', \%hook_args, 1, $target, $target_arg);

    my $routine_names = {};
    run_hooks(
        'create_routine_names', \%hook_args,
        sub {
            my ($hook, $hook_res) = @_;
            my $rn = $hook_res->[0] or return;
            for (keys %$rn) {
                push @{ $routine_names->{$_} }, @{ $rn->{$_} };
            }
            $hook_res->[1];
        },
        $target, $target_arg);

    my @routines;
    my $object = $target eq 'object';

  CREATE_LOG_ROUTINES:
    {
        my @rn;
        if ($target eq 'package') {
            push @rn, @{ $routine_names->{log_subs} || [] };
            push @rn, @{ $routine_names->{logml_subs} || [] };
        } else {
            push @rn, @{ $routine_names->{log_methods} || [] };
            push @rn, @{ $routine_names->{logml_methods} || [] };
        }
        my $mllogger0;
        for my $rn (@rn) {
            my ($rname, $lname) = @$rn;
            my $lnum = $Levels{$lname} if defined $lname;
            my $routine_name_is_ml = !defined($lname);

            my $logger;
            my ($logger0, $logger0_is_ml);
            $_logger_is_null = 0;
            for my $phase (qw/create_logml_routine create_log_routine/) {
                local $hook_args{name} = $rname;
                local $hook_args{level} = $lnum;
                local $hook_args{str_level} = $lname;
                $logger0_is_ml = $phase eq 'create_logml_routine';
                if ($mllogger0) {
                    # we reuse the same multilevel logger0 for all log routines,
                    # since it can handle different levels
                    $logger0 = $mllogger0;
                    last;
                }
                $logger0 = run_hooks(
                    $phase, \%hook_args, 1, $target, $target_arg)
                    or next;
                if ($logger0_is_ml) {
                    $mllogger0 = $logger0;
                }
                last;
            }
            # this can happen if there is no create_logml_routine hook but
            # routine name is a logml routine
            unless ($logger0) {
                $_logger_is_null = 1;
                $logger0 = sub {0};
            }

            require Log::ger::Util if !$logger0_is_ml && $routine_name_is_ml;

            {
                if ($_logger_is_null) {
                    # if logger is a null logger (sub {0}) we don't need to
                    # format message, layout message, or care about the logger
                    # being a subroutine/object
                    $logger = $logger0;
                    last;
                }

                if ($formatter) {
                    if ($layouter) {
                        if ($logger0_is_ml) {
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; my $lnum=shift; my $lname = Log::ger::Util::string_level($lnum);
                                                                                      $logger0->($init_args, $lnum, $layouter->($formatter->(@_), $init_args, $lnum, $lname)) };
                                } else {       $logger = sub {        my $lnum=shift; my $lname = Log::ger::Util::string_level($lnum);
                                                                                      $logger0->($init_args, $lnum, $layouter->($formatter->(@_), $init_args, $lnum, $lname)) }; }
                            } else { # routine name not multiple-level
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args, $lnum, $layouter->($formatter->(@_), $init_args, $lnum, $lname)) };
                                } else {       $logger = sub {                        $logger0->($init_args, $lnum, $layouter->($formatter->(@_), $init_args, $lnum, $lname)) }; }
                            }
                        } else { # logger0 not multiple-level
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,        $layouter->($formatter->(@_), $init_args, $lnum, $lname)) };
                                } else {       $logger = sub {        return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,        $layouter->($formatter->(@_), $init_args, $lnum, $lname)) }; }
                            } else { # routine name not multiple-level
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args,        $layouter->($formatter->(@_), $init_args, $lnum, $lname)) };
                                } else {       $logger = sub {                        $logger0->($init_args,        $layouter->($formatter->(@_), $init_args, $lnum, $lname)) }; }
                            }
                        }
                    } else { # no layouter
                        if ($logger0_is_ml) {
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; my $lnum=shift; $logger0->($init_args, $lnum,             $formatter->(@_)                            ) };
                                } else {       $logger = sub {        my $lnum=shift; $logger0->($init_args, $lnum,             $formatter->(@_)                            ) }; }
                            } else { # routine name not multiple-level
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args, $lnum,             $formatter->(@_)                            ) };
                                } else {       $logger = sub {                        $logger0->($init_args, $lnum,             $formatter->(@_)                            ) }; }
                            }
                        } else { # logger0 not multiple-level
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,                    $formatter->(@_)                            ) };
                                } else {       $logger = sub {        return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,                    $formatter->(@_)                            ) }; }
                            } else { # routine name not multiple-level
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args,                    $formatter->(@_)                            ) };
                                } else {       $logger = sub {                        $logger0->($init_args,                    $formatter->(@_)                            ) }; }
                            }
                        }
                    }
                } else { # no formatter
                    { # no layouter, just to align
                        if ($logger0_is_ml) {
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; my $lnum=shift; $logger0->($init_args, $lnum,                          @_                             ) };
                                } else {       $logger = sub {        my $lnum=shift; $logger0->($init_args, $lnum,                          @_                             ) }; }
                            } else { # routine name not multiple-lvl
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args, $lnum,                          @_                             ) };
                                } else {       $logger = sub {                        $logger0->($init_args, $lnum,                          @_                             ) }; }
                            }
                        } else { # logger0 not multiple-level
                            if ($routine_name_is_ml) {
                                if ($object) { $logger = sub { shift; return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,                                 @_                             ) };
                                } else {       $logger = sub {        return 0 if Log::ger::Util::numeric_level(shift) > $Current_Level;
                                                                                      $logger0->($init_args,                                 @_                             ) }; }
                            } else {
                                if ($object) { $logger = sub { shift;                 $logger0->($init_args,                                 @_                             ) };
                                } else {       $logger = sub {                        $logger0->($init_args,                                 @_                             ) }; }
                            }
                        }
                    }
                }
            }
          L1:
            my $type = $routine_name_is_ml ?
                ($object ? 'logml_method' : 'logml_sub') :
                ($object ? 'log_method' : 'log_sub');
            push @routines, [$logger, $rname, $lnum, $type];
        }
    }
  CREATE_IS_ROUTINES:
    {
        my @rn;
        my $type;
        if ($target eq 'package') {
            push @rn, @{ $routine_names->{is_subs} || [] };
            $type = 'is_sub';
        } else {
            push @rn, @{ $routine_names->{is_methods} || [] };
            $type = 'is_method';
        }
        for my $rn (@rn) {
            my ($rname, $lname) = @$rn;
            my $lnum = $Levels{$lname};

            local $hook_args{name} = $rname;
            local $hook_args{level} = $lnum;
            local $hook_args{str_level} = $lname;

            my $code_is =
                run_hooks('create_is_routine', \%hook_args, 1,
                          $target, $target_arg);
            next unless $code_is;
            push @routines, [$code_is, $rname, $lnum, $type];
        }
    }

    {
        local $hook_args{routines} = \@routines;
        run_hooks('before_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }

    # install
    if ($target eq 'package') {
#IFUNBUILT
# #         no strict 'refs';
# #         no warnings 'redefine';
#END IFUNBUILT
        for my $r (@routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_sub\z/;
            #print "D:installing $name to package $target_arg\n";
            *{"$target_arg\::$name"} = $code;
        }
    } elsif ($target eq 'object') {
#IFUNBUILT
# #         no strict 'refs';
# #         no warnings 'redefine';
#END IFUNBUILT
        my $pkg = ref $target_arg;
        for my $r (@routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_method\z/;
            *{"$pkg\::$name"} = $code;
        }
    } elsif ($target eq 'hash') {
        for my $r (@routines) {
            my ($code, $name, $lnum, $type) = @$r;
            next unless $type =~ /_sub\z/;
            $target_arg->{$name} = $code;
        }
    }

    {
        local $hook_args{routines} = \@routines;
        run_hooks('after_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }
}

sub import {
    my ($package, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    add_target(package => $caller, \%args);
    init_target(package => $caller, \%args);
}

sub get_logger {
    my ($package, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    my $obj = []; $obj =~ /\(0x(\w+)/;
    my $pkg = "Log::ger::Obj$1"; bless $obj, $pkg;
    add_target(object => $obj, \%args);
    init_target(object => $obj, \%args);
    $obj; # XXX add DESTROY to remove from list of targets
}

1;
# ABSTRACT: A lightweight, flexible logging framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger - A lightweight, flexible logging framework

=head1 VERSION

version 0.012

=head1 SYNOPSIS

In your module (producer):

 package Foo;
 use Log::ger; # will import some logging methods e.g. log_warn, log_error

 sub foo {
     ...
     # produce some logs
     log_error "an error occurred: %03d - %s", $errcode, $errmsg;
     ...
     log_debug "http response: %s", $http; # automatic dumping of data
 }
 1;

In your application (consumer/listener):

 use Foo;
 use Log::ger::Output 'Screen';

 foo();

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

B<Low startup overhead.> Only around 1-1.5ms or less, comparable with Log::Any
0.15, less than Log::Any 1.0x at around 4-10ms, and certainly less than
L<Log::Log4perl> at 20-30ms. This is measured on a 2014-2015 PC and before doing
any output configuration. For more benchmarks, see
L<Bencher::Scenarios::LogGer>.

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
output. For example, some modules that are migrated from Log::Any uses
Log::Any-style logging, while another uses native Log::ger style, and yet some
other uses block formatting like Log::Contextual. This eases code migration and
teamwork. Each module author can preserve her own logging style, if wanted, and
all the modules still use the same framework.

B<Dynamic.> Outputs and levels can be changed anytime during run-time and
logging routines will be updated automatically. This is useful in situation like
a long-running server application: you can turn on tracing logs temporarily to
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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
