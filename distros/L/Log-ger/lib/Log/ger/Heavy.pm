package Log::ger::Heavy;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '0.016'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

package
    Log::ger;

#IFUNBUILT
# use vars qw(
#                $re_addr
#                %Levels
#                %Level_Aliases
#                $Current_Level
#                $Caller_Depth_Offset
#                $_logger_is_null
#                $_dumper
#                %Global_Hooks
#                %Package_Targets
#                %Per_Package_Hooks
#                %Hash_Targets
#                %Per_Hash_Hooks
#                %Object_Targets
#                %Per_Object_Hooks
#        );
#END IFUNBUILT

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
        my ($addr) = "$target_arg" =~ $re_addr;
        unshift @hooks, @{ $Per_Hash_Hooks{$addr}{$phase} || [] };
    } elsif ($target eq 'object') {
        my ($addr) = "$target_arg" =~ $re_addr;
        unshift @hooks, @{ $Per_Object_Hooks{$addr}{$phase} || [] };
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

sub init_target {
    my ($target, $target_arg, $init_args) = @_;

    #print "D:init_target($target, $target_arg, ...)\n";
    my %hook_args = (
        target     => $target,
        target_arg => $target_arg,
        init_args  => $init_args,
    );

    my %formatters;
    run_hooks(
        'create_formatter', \%hook_args,
        # collect formatters, until a hook instructs to stop
        sub {
            my ($hook, $hook_res) = @_;
            my ($formatter, $flow_control, $fmtname) = @$hook_res;
            $fmtname = 'default' if !defined($fmtname);
            $formatters{$fmtname} ||= $formatter;
            $flow_control;
        },
        $target, $target_arg);

    my $layouter =
        run_hooks('create_layouter', \%hook_args, 1, $target, $target_arg);

    my $routine_names = {};
    run_hooks(
        'create_routine_names', \%hook_args,
        # collect routine names, until a hook instructs to stop.
        sub {
            my ($hook, $hook_res) = @_;
            my ($rn, $flow_control) = @$hook_res;
            $rn or return;
            for (keys %$rn) {
                push @{ $routine_names->{$_} }, @{ $rn->{$_} };
            }
            $flow_control;
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
            my ($rname, $lname, $fmtname) = @$rn;
            my $lnum = $Levels{$lname} if defined $lname;
            my $routine_name_is_ml = !defined($lname);
            $fmtname = 'default' if !defined($fmtname);

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

                my $formatter = $formatters{$fmtname}
                    or die "Formatter named '$fmtname' not available";
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
        local $hook_args{formatters} = \%formatters;
        local $hook_args{layouter} = $layouter;
        run_hooks('before_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }

    install_routines($target, $target_arg, \@routines);

    {
        local $hook_args{routines} = \@routines;
        run_hooks('after_install_routines', \%hook_args, 0,
                  $target, $target_arg);
    }
}

1;
# ABSTRACT: The bulk of the implementation of Log::ger

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Heavy - The bulk of the implementation of Log::ger

=head1 VERSION

version 0.016

=head1 DESCRIPTION

This module contains the bulk of the implementation of Log::ger, to keep
Log::ger superslim.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
