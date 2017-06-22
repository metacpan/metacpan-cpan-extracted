package Log::ger;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.004'; # VERSION

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

# keep track of our importers (= log producers) to be able to re-export log
# routines to them when we change output, etc.
our %Setup_Args;

our $Current_Level = 3;

# a flag that can be used by null output to skip using formatter
our $_log_is_null;

our $_dumper;

# key = phase, value = package, or [prio, coderef, key] (for plugins that have
# arguments and wants to remember that arguments on re-setup)
our %Default_Plugins = (
    create_filter_routine => [],
    create_formatter_routine => [qw/Log::ger/],
    create_log_routine => [qw/Log::ger/],
    after_create_log_routine => [],
    create_log_is_routine => [qw/Log::ger/],
    after_install_log_routine => [],
);

our %Plugins;
{
    for my $phase (keys %Default_Plugins) {
        $Plugins{$phase} = [@{ $Default_Plugins{$phase} }];
    }
}

# plugins that are specific to each importer. this is appropriate for e.g.
# plugin that creates incompatible interface e.g. Log::ger::Format::Code so it
# affects only packages that import it.
our %Importer_Plugins; # key = package name, value = { phase => plugins, ... }

sub PRIO_create_log_routine { 10 }

# the default behavior is to create a null routine for levels that are too high.
# since we run at high priority (10), this block typical output plugins at
# normal priority (50).
sub create_log_routine {
    my ($self, %args) = @_;
    my $level = $args{level};
    if ($Current_Level < $level ||
            @{ $Plugins{create_log_routine} } == 1 # there's only us
        ) {
        $_log_is_null = 1;
        return [sub {0}];
    }
    [undef]; # decline
}

sub PRIO_create_log_is_routine { 90 }

# the default behavior is to compare to global level. normally this behavior
# suffices.
sub create_log_is_routine {
    my ($self, %args) = @_;
    my $level = $args{level};
    [sub { $Current_Level >= $level }];
}

sub PRIO_create_formatter_routine { 90 }

# the default formatter is sprintf-style that dumps data structures arguments as
# well as undef as '<undef>'.
sub create_formatter_routine {
    my ($self, %args) = @_;

    my $code = sub {
        return $_[0] if @_ < 2;
        my $fmt = shift;
        my @args;
        for (@_) {
            if (!defined($_)) {
                push @args, '<undef>';
            } elsif (ref $_) {
                if (!$_dumper) {
                    require Log::ger::Util;
                }
                push @args, Log::ger::Util::_dump($_);
            } else {
                push @args, $_;
            }
        }
        sprintf $fmt, @args;
    };
    [$code];
}

sub run_plugins {
    my ($phase, $plugin_args, $stop_after_first_result, $package) = @_;
    #print "D: running plugins for $phase\n";

    my $plugins = $Plugins{$phase} or die "Unknown phase '$phase'";

    if ($package) {
        # add importer-specific plugins
        $plugins = [@{ $Importer_Plugins{$package}{$phase} || [] },
                    @$plugins];
    }

    my $res;
    my $meth = "PRIO_$phase";
    for my $plugin (sort {
        my $prio_a = ref $a eq 'ARRAY' ? $a->[0] : $a->$meth;
        my $prio_b = ref $b eq 'ARRAY' ? $b->[0] : $b->$meth;
        $prio_a <=> $prio_b
    } @$plugins)  {
        my ($res0, $flow_control) = @{
            ref $plugin eq 'ARRAY' ? $plugin->[1]->(%$plugin_args) :
                $plugin->$phase(%$plugin_args)
            };
        if (defined $res0) {
            $res = $res0;
            #print "D:   got result from $plugin\n";
            last if $stop_after_first_result;
        }
        last if $flow_control;
    }
    return $res;
}

sub _setup {
    my ($target, $target_arg, $setup_args) = @_;

    my %plugin_args = (
        target     => $target,
        target_arg => $target_arg,
        setup_args => $setup_args,
    );

    my $package;
    if ($target eq 'package') {
        $package = $target_arg;
    }

    my $code_filter = run_plugins(
        'create_filter_routine', \%plugin_args, 1, $package);

    my $code_formatter =
        run_plugins('create_formatter_routine', \%plugin_args, 1, $package);
    die "No plugin created formatter routine" unless $code_formatter;

    for my $lname (sort { $Levels{$a} <=> $Levels{$b} } keys %Levels) {
        my $lnum = $Levels{$lname};

        local $plugin_args{level} = $lnum;
        local $plugin_args{str_level} = $lname;

        $_log_is_null = 0;
        my $code0_log =
            run_plugins('create_log_routine', \%plugin_args, 1, $package);
        die "No plugin created log routine 'log_$lname'" unless $code0_log;
        my $code_log;
        if ($_log_is_null) {
            # we don't need to format null logger
            $code_log = $code0_log;
        } elsif ($code_filter) {
            $code_log = sub {
                return unless $code_filter->($lnum, $setup_args);
                my $msg = $code_formatter->(@_);
                $code0_log->($setup_args, $msg);
            };
        } else {
            $code_log = sub {
                my $msg = $code_formatter->(@_);
                $code0_log->($setup_args, $msg);
            };
        }

        {
            local $plugin_args{log_routine} = $code_log;
            run_plugins('after_create_log_routine', \%plugin_args, 1, $package);
        }

        my $code_log_is =
            run_plugins('create_log_is_routine', \%plugin_args, 1, $package);
        die "No plugin created log routine 'log_is_$lname'" unless $code_log_is;

        # install
        if ($target eq 'package') {
#IFUNBUILT
# #             no strict 'refs';
# #             no warnings 'redefine';
#END IFUNBUILT

            *{"$target_arg\::log_$lname"}    = $code_log;
            *{"$target_arg\::log_is_$lname"} = $code_log_is;
        } elsif ($target eq 'hash') {
            $target_arg->{"log_$lname"}    = $code_log;
            $target_arg->{"log_is_$lname"} = $code_log_is;
        } elsif ($target eq 'object') {
#IFUNBUILT
# #             no strict 'refs';
# #             no warnings 'redefine';
#END IFUNBUILT

            *{"$target_arg\::log_$lname"}    = sub { shift; $code_log->(@_) };
            *{"$target_arg\::log_is_$lname"} = $code_log_is;
        }

        run_plugins('after_install_log_routine', \%plugin_args, $package);
    } # for level
}

sub setup_package {
    my $package = shift;
    my $args = shift;
    _setup('package', $package, $args);
}

sub setup_hash {
    my $hash = {};
    my $args = shift;
    _setup('hash', $hash, $args);
    $hash;
}

sub setup_object {
    my $obj = []; my ($obj_addr) = "$obj" =~ /0x(\w+)/;
    my $pkg = "Log::ger::Stash::A$obj_addr";
    my $args = shift;
    _setup('object', $pkg, $args);
    bless [], $pkg;
}

sub import {
    my ($self, %args) = @_;

    my $caller = caller(0);
    $args{category} = $caller if !defined($args{category});
    $Setup_Args{$caller} = \%args;
    setup_package($caller, \%args);
}

1;
# ABSTRACT: A lightweight, flexible logging framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger - A lightweight, flexible logging framework

=head1 VERSION

version 0.004

=head1 SYNOPSIS

In your module (producer):

 package Foo;
 use Log::ger; # will import some logging methods e.g. log_warn, log_error

 # produce some logs
 sub foo {
     ...
     log_warn "an error occurred";
     log_error "an error occurred: %03d - %s", $errcode, $errmsg;
 }
 1;

In your application:

 use Foo;
 use Log::ger::Output 'Screen';

 foo();

=head1 DESCRIPTION

B<EARLY RELEASE, EXPERIMENTAL.>

This is yet another logging framework. Like L<Log::Any>, it separates producers
and consumers. Unlike L<Log::Any> (and like L<Log::Contextual>), it uses plain
functions (non-OO). Some features:

=over

=item * Low startup overhead;

=item * Low overhead;

=item * Customizable levels;

=item * Changing levels and outputs during run-time;

For example, you can debug your running server application to turn on trace logs
temporarily when you need to investigate something.

=item * Option to optimize away the logging statements when unnecessary;

See L<Log::ger::OptAway>.

=item * Interoperability with other logging frameworks;

See L<Log::ger::Output::LogAny> to interop with L<Log::Any>.

=back

=for Pod::Coverage ^(.+)$

=head1 FAQ

=head2 How do I create multiple loggers?

For example, in L<Log::Any>:

 my $log = Log::Any->get_logger;
 my $log_dump = Log::Any->get_logger(category => "dump"); # to dump contents

 $log->debugf("Headers is: %s", $http_res->{headers});
 $log_dump->debug($http_res->{content});

in Log::ger:

 # instead of installing to package, we setup objects/hashes for the secondary
 # loggers
 my $log_dump = Log::ger::setup_object(category => "dump");
 # or, for hash: my $log_dump = Log::ger::setup_hash(category => "dump");

 log_debug("Headers is: %s", $http_res->{headers});
 $log_dump->log_debug($http_res->{content});
 # or, for hash: $log_dump->{log_debug}->($http_res->{content});

=head2 How do I do custom formatting

For example, a la L<Log::Contextual>:

 log_warn { 'The number of stuffs is: ' . $obj->stuffs_count };

See L<Log::ger::Format::Block> for an example.

=head1 INTERNALS

=head2 Plugins

Plugins are how Log::ger provides its flexibility. Plugins are run at various
phases. Plugin routine is passed a hash argument and is expected to return an
array:

 [$result, $flow_control]

Some phases will stop after the first plugin that returns non-undef C<$result>.
C<$flow_control> can be set to 1 to stop immediately after this hook.

Aguments received by plugin: C<target> (str, can be C<package> if installing to
a package, or C<hash> or C<object>), C<target_arg> (str, when C<target> is
C<package>, will be the package name; when C<target> is C<hash> will be the
hash; when C<target> is C<object> will be the object's package), C<setup_args>
(hash, arguments passed to Log::ger when importing). These arguments are
received by plugins for C<create_log_routine> and C<create_log_is_routine> which
are run for every level: C<level> (numeric level), C<str_level>.

Available phases:

=over

=item * create_filter_routine

=item * create_formatter_routine

=item * create_log_routine phase

Used to create "log_I<level>" routines. Run for each level.

=item * create_log_is_routine phase

Used to create "log_I<level>" routines. Run for each level.

=item * after_install_log_routine phase

=back

=head1 SEE ALSO

Some other recommended logging frameworks: L<Log::Any>, L<Log::Contextual>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
