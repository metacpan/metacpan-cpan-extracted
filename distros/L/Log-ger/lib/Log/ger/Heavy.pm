## no critic: TestingAndDebugging::RequireUseStrict
package Log::ger::Heavy;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-29'; # DATE
our $DIST = 'Log-ger'; # DIST
our $VERSION = '0.042'; # VERSION

#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

package
    Log::ger;

#IFUNBUILT
# our (
#                $re_addr,
#                %Levels,
#                %Level_Aliases,
#                $Current_Level,
#                $_outputter_is_null,
#                $_dumper,
#                %Global_Hooks,
#                %Package_Targets,
#                %Per_Package_Hooks,
#                %Hash_Targets,
#                %Per_Hash_Hooks,
#                %Object_Targets,
#                %Per_Object_Hooks,
#        );
#END IFUNBUILT

# key = phase, value = [ [key, prio, coderef], ... ]
our %Default_Hooks = (
    create_filter => [],

    create_formatter => [
        [__PACKAGE__, 90,
         sub {
             my %args = @_;

# BEGIN_BLOCK: default_formatter

             my $formatter =

                 # the default formatter is sprintf-style that dumps data
                 # structures arguments as well as undef as '<undef>'.
                 sub {
                     return $_[0] if @_ < 2;
                     my $fmt = shift;
                     my @args;
                     for (@_) {
                         if (!defined($_)) {
                             push @args, '<undef>';
                         } elsif (ref $_) {
                             require Log::ger::Util unless $Log::ger::_dumper;
                             push @args, Log::ger::Util::_dump($_);
                         } else {
                             push @args, $_;
                         }
                     }
                     # redefine is just a dummy category for perls < 5.22 which
                     # don't have 'redundant' yet
                     no warnings ($warnings::Bits{'redundant'} ? 'redundant' : 'redefine');
                     sprintf $fmt, @args;
                 };

             [$formatter];

# END_BLOCK: default_formatter

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
                 logger_subs           => [map { ["log_$_", $_]    } @$levels],
                 level_checker_subs    => [map { ["log_is_$_", $_] } @$levels],
                 # used when installing to hash or object
                 logger_methods        => [map { ["$_", $_]        } @$levels],
                 level_checker_methods => [map { ["is_$_", $_]     } @$levels],
             }, 1];
         }],
    ],

    # old name for create_outputter, deprecated and will be removed in the
    # future
    create_log_routine => [],

    create_outputter => [
        [__PACKAGE__, 10,
         # the default behavior is to create a null routine for levels that are
         # too high than the global level ($Current_Level). since we run at high
         # priority (10), we block typical output plugins at normal priority
         # (50). this is a convenience so normally a plugin does not have to
         # deal with level checking. plugins that want to do its own level
         # checking can use a higher priority.
         sub {
             my %args = @_;
             my $level = $args{level};
             my $num_outputs = 0;
             $num_outputs += @{ $Global_Hooks{create_log_routine} }; # old name, will be removed
             $num_outputs += @{ $Global_Hooks{create_outputter} };
             if ( # level indicates routine should be a null logger
                 (defined $level && $Current_Level < $level) ||
                     # there's only us that produces log routines (e.g. no outputs)
                     $num_outputs == 1
             ) {
                 $_outputter_is_null = 1;
                 return [sub {0}];
             }
             [undef]; # decline, let output plugin supply logger routines
         }],
    ],

    # old name for create_level_checker, deprecated and will be removed in the
    # future
    create_is_routine => [],

    create_level_checker => [
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
        $target_type, $target_name) = @_;
    #print "D: running hooks for phase $phase\n";

    $Global_Hooks{$phase} or die "Unknown phase '$phase'";
    my @hooks = @{ $Global_Hooks{$phase} };

    if ($target_type eq 'package') {
        unshift @hooks, @{ $Per_Package_Hooks{$target_name}{$phase} || [] };
    } elsif ($target_type eq 'hash') {
        my ($addr) = "$target_name" =~ $re_addr;
        unshift @hooks, @{ $Per_Hash_Hooks{$addr}{$phase} || [] };
    } elsif ($target_type eq 'object') {
        my ($addr) = "$target_name" =~ $re_addr;
        unshift @hooks, @{ $Per_Object_Hooks{$addr}{$phase} || [] };
    }

    my $res;
    for my $hook (sort {$a->[1] <=> $b->[1]} @hooks)  {
        my $hook_res = $hook->[2]->(%$hook_args);
        if (defined $hook_res->[0]) {
            $res = $hook_res->[0];
            #print "D:   got result from hook $hook->[0]: $res\n";
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
    my ($target_type, $target_name, $per_target_conf) = @_;

    #print "D:init_target($target_type, $target_name, ...)\n";
    my %hook_args = (
        target_type     => $target_type,
        target_name     => $target_name,
        per_target_conf => $per_target_conf,
    );

    # collect only a single filter
    my %filters;
    run_hooks(
        'create_filter', \%hook_args,
        # collect filters, until a hook instructs to stop
        sub {
            my ($hook, $hook_res) = @_;
            my ($filter, $flow_control, $fltname) = @$hook_res;
            $fltname = 'default' if !defined($fltname);
            $filters{$fltname} ||= $filter;
            $flow_control;
        },
        $target_type, $target_name);

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
        $target_type, $target_name);

    # collect only a single layouter
    my $layouter =
        run_hooks(
            'create_layouter', \%hook_args, 1, $target_type, $target_name);

    my $routine_names = {};
    run_hooks(
        'create_routine_names', \%hook_args,
        # collect routine names, until a hook instructs to stop.
        sub {
            my ($hook, $hook_res) = @_;
            my ($routine_name_rec, $flow_control) = @$hook_res;
            $routine_name_rec or return;
            for (keys %$routine_name_rec) {
                push @{ $routine_names->{$_} }, @{ $routine_name_rec->{$_} };
            }
            $flow_control;
        },
        $target_type, $target_name);

    my @routines;
    my $is_object = $target_type eq 'object';

  CREATE_LOGGER_ROUTINES:
    {
        my @routine_name_recs;
        if ($target_type eq 'package') {
            push @routine_name_recs, @{ $routine_names->{log_subs} || [] }; # old name, will be removed
            push @routine_name_recs, @{ $routine_names->{logger_subs} || [] };
        } else {
            push @routine_name_recs, @{ $routine_names->{log_methods} || [] }; # old name, will be removed
            push @routine_name_recs, @{ $routine_names->{logger_methods} || [] };
        }
      NAME:
        for my $routine_name_rec (@routine_name_recs) {
            my ($rname, $lname, $fmtname, $rper_target_conf, $fltname)
                = @$routine_name_rec;
            my $lnum; $lnum = $Levels{$lname} if defined $lname;
            $fmtname = 'default' if !defined($fmtname);

            my ($output_routine, $logger);
            $_outputter_is_null = 0;
            local $hook_args{name} = $rname; # compat, deprecated
            local $hook_args{routine_name} = $rname;
            local $hook_args{level} = $lnum;
            local $hook_args{str_level} = $lname;
            my $outputter;
            {
                $outputter = run_hooks("create_outputter"  , \%hook_args, 1, $target_type, $target_name) and last;
                $outputter = run_hooks("create_log_routine", \%hook_args, 1, $target_type, $target_name); # old name, will be removed in the future
            }
            die "BUG in configuration: No outputter is produced for routine name $rname" unless $outputter;

            { # enclosing block
                if ($_outputter_is_null) {

                    # if outputter is a null outputter (sub {0}) we don't need
                    # to format message, layout message, or care about the
                    # logger routine being a subroutine/object. shortcut here
                    # for faster init.

                    $logger = $outputter;
                    last;
                }

                my $formatter = $formatters{$fmtname};
                my $filter    = defined($fltname) ? $filters{$fltname} : undef;

                # zoom out to see vertical alignments... we have filter(x2) x
                # formatter+layouter(x3) x OO/non-OO (x2) = 12 permutations. we
                # create specialized subroutines for each case, for performance
                # reason.
                if ($filter) { if ($formatter) { if ($layouter) { if ($is_object) { $logger = sub { shift; return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf, $layouter->($formatter->(@_), $per_target_conf, $lnum, $lname, $per_msg_conf), $per_msg_conf) };       # has-filter has-formatter has-layouter with-oo
                                                                  } else {          $logger = sub {        return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf, $layouter->($formatter->(@_), $per_target_conf, $lnum, $lname, $per_msg_conf), $per_msg_conf) }; }     # has-filter has-formatter has-layouter  not-oo
                                                 } else {         if ($is_object) { $logger = sub { shift; return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf,             $formatter->(@_),                                                  $per_msg_conf) };       # has-filter has-formatter  no-layouter with-oo
                                                                  } else {          $logger = sub {        return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf,             $formatter->(@_),                                                  $per_msg_conf) }; } }   # has-filter has-formatter  no-layouter  not-oo
                               } else {                           if ($is_object) { $logger = sub { shift; return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf,                         \@_,                                                   $per_msg_conf) };       # has-filter  no-formatter  no-layouter with-oo
                                                                  } else {          $logger = sub {        return 0 unless my $per_msg_conf = $filter->(@_); $outputter->($rper_target_conf || $per_target_conf,                         \@_,                                                   $per_msg_conf) }; } }   # has-filter  no-formatter  no-layouter  not-oo
                } else {       if ($formatter) { if ($layouter) { if ($is_object) { $logger = sub { shift;                                                   $outputter->($rper_target_conf || $per_target_conf, $layouter->($formatter->(@_), $per_target_conf, $lnum, $lname               )               ) };       #  no-filter has-formatter has-layouter with-oo
                                                                  } else {          $logger = sub {                                                          $outputter->($rper_target_conf || $per_target_conf, $layouter->($formatter->(@_), $per_target_conf, $lnum, $lname               )               ) }; }     #  no-filter has-formatter has-layouter  not-oo
                                               } else {           if ($is_object) { $logger = sub { shift;                                                   $outputter->($rper_target_conf || $per_target_conf,             $formatter->(@_)                                                                ) };       #  no-filter has-formatter  no-layouter with-oo
                                                                  } else {          $logger = sub {                                                          $outputter->($rper_target_conf || $per_target_conf,             $formatter->(@_)                                                                ) }; } }   #  no-filter has-formatter  no-layouter  not-oo
                               } else {                           if ($is_object) { $logger = sub { shift;                                                   $outputter->($rper_target_conf || $per_target_conf,                         \@_                                                                 ) };       #  no-filter  no-formatter  no-layouter with-oo
                                                                  } else {          $logger = sub {                                                          $outputter->($rper_target_conf || $per_target_conf,                         \@_                                                                 ) }; } } } #  no-filter  no-formatter  no-layouter  not-oo
            } # enclosing block
          L1:
            my $rtype = $is_object ? 'logger_method' : 'logger_sub';
            push @routines, [$logger, $rname, $lnum, $rtype, $rper_target_conf||$per_target_conf];
        }
    }

  CREATE_LEVEL_CHECKER_ROUTINES:
    {
        my @routine_name_recs;
        my $type;
        if ($target_type eq 'package') {
            push @routine_name_recs, @{ $routine_names->{is_subs} || [] }; # old name, will be removed
            push @routine_name_recs, @{ $routine_names->{level_checker_subs} || [] };
            $type = 'level_checker_sub';
        } else {
            push @routine_name_recs, @{ $routine_names->{is_methods} || [] }; # old name, will be removed
            push @routine_name_recs, @{ $routine_names->{level_checker_methods} || [] };
            $type = 'level_checker_method';
        }
        for my $routine_name_rec (@routine_name_recs) {
            my ($rname, $lname) = @$routine_name_rec;
            my $lnum = $Levels{$lname};

            local $hook_args{name} = $rname;
            local $hook_args{level} = $lnum;
            local $hook_args{str_level} = $lname;

            my $code_is;
            {
                $code_is = run_hooks('create_is_routine'   , \%hook_args, 1, $target_type, $target_name) and last; # old name, will be removed
                $code_is = run_hooks('create_level_checker', \%hook_args, 1, $target_type, $target_name);
            }
            die "BUG in configuration: No level_checker routine is produced for routine name $rname" unless $code_is;

            push @routines, [$code_is, $rname, $lnum, $type, $per_target_conf];
        }
    }

    {
        local $hook_args{routines} = \@routines;
        local $hook_args{filters} = \%filters;
        local $hook_args{formatters} = \%formatters;
        local $hook_args{layouter} = $layouter;
        run_hooks('before_install_routines', \%hook_args, 0,
                  $target_type, $target_name);
    }

    install_routines($target_type, $target_name, \@routines, 1);

    {
        local $hook_args{routines} = \@routines;
        run_hooks('after_install_routines', \%hook_args, 0,
                  $target_type, $target_name);
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

version 0.042

=head1 DESCRIPTION

This module contains the bulk of the implementation of Log::ger, to keep
Log::ger superslim.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
