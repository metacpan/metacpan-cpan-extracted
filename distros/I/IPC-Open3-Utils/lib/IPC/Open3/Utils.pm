package IPC::Open3::Utils;

use strict;
use warnings;

$IPC::Open3::Utils::VERSION = '0.92';

require Exporter;
@IPC::Open3::Utils::ISA       = qw(Exporter);
@IPC::Open3::Utils::EXPORT    = qw(run_cmd put_cmd_in);
@IPC::Open3::Utils::EXPORT_OK = qw(
  run_cmd                 put_cmd_in
  child_error_ok          child_error_failed_to_execute
  child_error_exit_signal child_error_seg_faulted
  child_error_core_dumped child_error_exit_value
  create_ipc_open3_utils_wrap_script
);
%IPC::Open3::Utils::EXPORT_TAGS = (
    'all' => \@IPC::Open3::Utils::EXPORT_OK,
    'cmd' => [qw(run_cmd put_cmd_in)],
    'err' => [
        qw(
          child_error_ok          child_error_failed_to_execute
          child_error_exit_signal child_error_seg_faulted
          child_error_core_dumped child_error_exit_value
          )
    ],
);

require IO::Select;
require IPC::Open3;
require IO::Handle;

sub run_cmd {
    my @cmd = @_;
    my $arg_hr = ref $cmd[-1] eq 'HASH' ? pop(@cmd) : {};
    $arg_hr->{'ignore_handle'} ||= '';

    if ( ref $arg_hr->{'handler'} ne 'CODE' ) {
        $arg_hr->{'handler'} = sub {
            my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_sr ) = @_;
            if ($is_stderr) {
                print STDERR $cur_line;
            }
            else {
                print STDOUT $cur_line;
            }

            return 1;
        };
    }

    my $stdout = IO::Handle->new();
    my $stderr = IO::Handle->new();    # TODO ? $arg_hr->{'combine_fhs'} ? $stdout : IO::Handle->new(); && then  no select()
    my $stdin  = IO::Handle->new();
    my $sel    = IO::Select->new();

    if ( ref $arg_hr->{'autoflush'} eq 'HASH' ) {
        $stdout->autoflush(1) if $arg_hr->{'autoflush'}{'stdout'};
        $stderr->autoflush(1) if $arg_hr->{'autoflush'}{'stderr'};
        $stdin->autoflush(1)  if $arg_hr->{'autoflush'}{'stdin'};
    }

    # this is a hack to work around an exit-before-use race condition
    local $SIG{'PIPE'} = exists $SIG{'PIPE'} && defined $SIG{'PIPE'} ? $SIG{'PIPE'} : '';
    my $current_sig_pipe = $SIG{'PIPE'};
    if ( exists $arg_hr->{'pre_read_print_to_stdin'} ) {
        $SIG{'PIPE'} = sub {

            # my $oserr = $!;
            # my $cherr = $?;
            $stdin->close if defined $stdin && ref $stdin eq 'IO::Handle';    #  && !$arg_hr->{'close_stdin'};
            $stdout->close;
            $stderr->close;

            # $! = $oserr;
            # $? = $cherr;
            $current_sig_pipe->() if $current_sig_pipe && ref $current_sig_pipe eq 'CODE';
        };
    }

    # ensure these are always re-set at the beginning of an execution
    $! = 0;
    $? = 0;

    my $child_pid;
    eval { $child_pid = IPC::Open3::open3( $stdin, $stdout, $stderr, @cmd ) };
    if ($@) {
        if ( $@ =~ m{not enough arguments} ) {
            $! = 22;       # Invalid argument
            $? = 65280;    # system();print $?;
        }
        elsif ( $@ =~ m{open3: exec of .* failed\b} ) {
            $? = -1;
        }

        if ( ref $arg_hr->{'open3_error'} eq 'SCALAR' ) {
            ${ $arg_hr->{'open3_error'} } = $@;
        }
        else {
            $arg_hr->{'open3_error'} = $@;
        }

        if ( $arg_hr->{'carp_open3_errors'} ) {
            require Carp;
            Carp::carp($@);
        }

        return;
    }

    $arg_hr->{'timeout'} = exists $arg_hr->{'timeout'} ? abs( $arg_hr->{'timeout'} ) : 0;

    my $alarm;
    my $original_alarm;

    # small hack to avoid uninitialized value warnings w/ out lots of warning.pm voo-doo to
    #    keep the "no warnings 'uninitialized'" scoped to this assignment but the local() scoped from here on
    # local $SIG{'ALRM'} = $SIG{'ALRM'};# this gives uninitialized value warnings
    my $no_unit_warnings = $SIG{'ALRM'};
    local $SIG{'ALRM'} ||= '';
    if ( $arg_hr->{'timeout'} ) {
        if ( $arg_hr->{'timeout_is_microseconds'} ) {
            if ( defined &Time::HiRes::ualarm ) {
                $alarm = \&Time::HiRes::ualarm;
            }
            else {
                $alarm = defined &Time::HiRes::alarm ? \&Time::HiRes::alarm : sub { alarm( $_[0] ) };    # \&CORE::alarm, \&CORE::GLOBAL::alarm, etc don't work ...
                $arg_hr->{'timeout'}                 = $arg_hr->{'timeout'} / 1_000_000;
                $arg_hr->{'timeout'}                 = 1 if $arg_hr->{'timeout'} < 1;
                $arg_hr->{'timeout_is_microseconds'} = 0;
            }
        }
        else {
            $alarm = defined &Time::HiRes::alarm ? \&Time::HiRes::alarm : sub { alarm( $_[0] ) };        # \&CORE::alarm, \&CORE::GLOBAL::alarm, etc don't work ...
        }

        $SIG{'ALRM'} = sub { die 'Alarm clock' };
        $original_alarm = $alarm->( $arg_hr->{'timeout'} );

        # undocumented, for testing purposes only
        if ( exists $arg_hr->{'_timeout_info'} && ref( $arg_hr->{'_timeout_info'} ) eq 'HASH' ) {
            %{ $arg_hr->{'_timeout_info'} } = (
                'timeout'                 => $arg_hr->{'timeout'},
                'timeout_is_microseconds' => $arg_hr->{'timeout_is_microseconds'},
                'Time::Hires'             => $INC{'Time/HiRes.pm'},
                'Time::Hires::ualarm'     => defined &Time::HiRes::ualarm ? 1 : 0,
                'Time::Hires::alarm'      => defined &Time::HiRes::alarm ? 1 : 0,
                'original_alarm'          => $original_alarm,
            );
        }
    }
    else {
        no warnings 'uninitialized';    # at least we can scopt it here ...
        $SIG{'ALRM'} = $no_unit_warnings;
    }

    my $is_open3_err       = 0;
    my $open3_err_is_exec  = 0;
    my $return_bool        = 1;
    my $short_circuit_loop = 0;

    eval {

        if ( exists $arg_hr->{'_pre_run_sleep'} ) {
            if ( my $sec = int( $arg_hr->{'_pre_run_sleep'} ) ) {
                sleep $sec;    # undocumented, only for testing
            }
        }

        $sel->add($stdout);    # unless exists $arg_hr->{'ignore_handle'} && $arg_hr->{'ignore_handle'} eq 'stdout';
        $sel->add($stderr);    # unless exists $arg_hr->{'ignore_handle'} && $arg_hr->{'ignore_handle'} eq 'stderr';

        if ( exists $arg_hr->{'pre_read_print_to_stdin'} ) {
            if ( my $type = ref( $arg_hr->{'pre_read_print_to_stdin'} ) ) {
                if ( $type eq 'ARRAY' ) {
                    for my $line ( @{ $arg_hr->{'pre_read_print_to_stdin'} } ) {
                        $stdin->printflush($line);
                    }
                }
                elsif ( $type eq 'CODE' ) {
                    for my $line ( $arg_hr->{'pre_read_print_to_stdin'}->() ) {
                        $stdin->printflush($line);
                    }
                }
            }
            else {
                $stdin->printflush( $arg_hr->{'pre_read_print_to_stdin'} );
            }
        }

        if ( $arg_hr->{'close_stdin'} ) {
            $stdin->close();
            undef $stdin;
        }

        local *_;

        # to avoid "Modification of readonly value attempted" errors with @_
        # You ask, "Do you mean the _open3()'s or while()'s @_? " and the answer is: "exactly!" ;p

        my $get_next = sub { readline(shift) };

        if ( my $byte_size = int( $arg_hr->{'read_length_bytes'} || 0 ) ) {
            my $buffer;
            $byte_size = 128 if $byte_size < 128;
            $get_next = sub { shift->sysread( $buffer, $byte_size ); return $buffer; };
        }

        my $odd_errno = int($!);

      READ_LOOP:
        while ( my @ready = $sel->can_read ) {
          HANDLE:
            for my $fh (@ready) {
                if ( $fh->eof ) {
                    $sel->remove($fh);
                    $fh->close;
                    next HANDLE;
                }

                my $is_stderr = $fh eq $stderr ? 1 : 0;

              CMD_OUTPUT:
                while ( my $cur_line = $get_next->($fh) ) {
                    next CMD_OUTPUT if $arg_hr->{'ignore_handle'} eq ( $is_stderr ? 'stderr' : 'stdout' );

                    $is_open3_err = 1 if $is_stderr && $cur_line =~ m{^open3:};
                    if ($is_open3_err) {
                        if ( ref $arg_hr->{'open3_error'} eq 'SCALAR' ) {
                            ${ $arg_hr->{'open3_error'} } = $cur_line;
                        }
                        else {
                            $arg_hr->{'open3_error'} = $cur_line;
                        }

                        if ( $arg_hr->{'carp_open3_errors'} ) {
                            require Carp;
                            Carp::carp($cur_line);
                        }

                        if ( $cur_line =~ m{open3: exec of .* failed\b} ) {
                            $open3_err_is_exec = 1;
                        }
                    }

                    $return_bool = $arg_hr->{'handler'}->( $cur_line, $stdin, $is_stderr, $is_open3_err, \$short_circuit_loop );

                    last READ_LOOP if !$return_bool;
                    last READ_LOOP if $is_open3_err && $arg_hr->{'stop_read_on_open3_err'};    # this is probably the last one anyway
                    last READ_LOOP if $short_circuit_loop;
                }
            }

            $odd_errno = int($!);
        }

        $! = 0 if $odd_errno == 0 && $! == 9;

        # my $oserr = $!;
        # my $cherr = $?;
        $stdout->close if $stdout->opened;
        $stderr->close if $stderr->opened;
        $stdin->close  if defined $stdin && ref $stdin eq 'IO::Handle' && $stdin->opened;    #  && !$arg_hr->{'close_stdin'};

        # $! = $oserr;
        # $? = $cherr;

        waitpid $child_pid, 0;

    };

    if ( $arg_hr->{'timeout'} && defined $original_alarm ) {
        $alarm->($original_alarm);
    }

    if ($@) {

        # if ($@ =~ m/^Alarm clock /) {
        #     $! = 60;
        #     # $? = ??;
        # }
        return;
    }

    if ( $is_open3_err && $open3_err_is_exec && $? != -1 ) {
        $? = -1;
    }

    return if $is_open3_err || !$return_bool || !child_error_ok($?);
    return 1;
}

sub put_cmd_in {
    my (@cmd) = @_;

    my $arg_hr = ref $cmd[-1] eq 'HASH' ? pop(@cmd) : {};

    # not being this strict allows us to do "no" output ref quietness
    # return if @cmd < 2;
    # return if defined $cmd[-1] && !ref $cmd[-1];
    # my $err = pop(@cmd);

    my $err = !defined $cmd[-1] || ref $cmd[-1] ? pop(@cmd) : undef;
    my $out = !defined $cmd[-1] || ref $cmd[-1] ? pop(@cmd) : $err;

    $arg_hr->{'handler'} = sub {
        my ( $cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_sr ) = @_;

        my $mod = $is_stderr ? $err : $out;
        return 1 if !defined $mod;

        if ( ref $mod eq 'SCALAR' ) {
            ${$mod} .= $cur_line;
        }
        else {
            push @{$mod}, $cur_line;
        }

        return 1;
    };

    return run_cmd( @cmd, $arg_hr );
}

#####################
#### child_error_* ##
#####################

sub child_error_ok {
    my $sysrc = @_ ? shift() : $?;
    return 1 if $sysrc == 0;
    return;
}

sub child_error_failed_to_execute {
    my $sysrc = @_ ? shift() : $?;
    return $sysrc == -1;
}

sub child_error_seg_faulted {
    my $sysrc = @_ ? shift() : $?;
    return if child_error_failed_to_execute($sysrc);
    return child_error_exit_signal($sysrc) == 11;
}

sub child_error_core_dumped {
    my $sysrc = @_ ? shift() : $?;
    return if child_error_failed_to_execute($sysrc);
    return $sysrc & 128;
}

sub child_error_exit_signal {
    my $sysrc = @_ ? shift() : $?;
    return if child_error_failed_to_execute($sysrc);
    return $sysrc & 127;
}

sub child_error_exit_value {
    my $sysrc = @_ ? shift() : $?;
    return if child_error_failed_to_execute($sysrc);
    return $sysrc >> 8;
}

1;

__END__

=head1 NAME

IPC::Open3::Utils - simple API encapsulating the most common open3() logic/uses including handling various corner cases and caveats

=head1 VERSION

This document describes IPC::Open3::Utils version 0.92

=head1 DESCRIPTION

The goals of this module are:

=over 4

=item 1 Encapsulate logic done every time you want to use open3().

=item 2 boolean check of command execution

=item 3 Out of the box printing to STDOUT/STDERR or assignments to variables (see #5)

=item 4 open3() error reporting

=item 5 comprehensive but simple output processing handlers for flexibility (see #3)

=item 6 Lightweight utilities for examining the meaning of $? without POSIX

=back

=head1 SYNOPSIS

    use IPC::Open3::Utils qw(run_cmd put_cmd_in ...);

    
    run_cmd(@cmd); # like 'system(@cmd)'
    
    # like 'if (system(@cmd) != 0)'
    if (!run_cmd(@cmd)) {
        print "Oops you may need to re-run that command, it failed.\n1";   
    }

So far not too useful but its when you need more complex things than system()-like behavior 
(and why you are using open3() to begin with one could assume) that this module comes into play.

If you care about exactly what went wrong you can get very detailed:
 
    my $open3_error;
    if (!run_cmd(@cmd, {'open3_error' => \$open3_error})) {
        print "open3() said: $open3_error\n" if $open3_error;
        
        if ($!) {
            print int($!) . ": $!\n";
        }
        
        if ($?) { # or if (!child_error_ok($?)) {
        
            print "Command failed to execute.\n" if child_error_failed_to_execute($?);
            print "Command seg faulted.\n" if child_error_seg_faulted($?);
            print "Command core dumped.\n" if child_error_core_dumped($?);
            unless ( child_error_failed_to_execute($?) ) {
                print "Command exited with signal: " . child_error_exit_signal($?) . ".\n";
                print "Command exited with value: " . child_error_exit_value($?) . ".\n";
            }
        }
    }

You can slurp the output into variables:

    # both STDOUT/STDERR in one
    my @output;
    if (put_cmd_in(@cmd, \@output)) {
        print _my_stringify(\@output);
    }

    # seperate STDOUT/STDERR
    my @stdout;
    my $stderr;
    if (put_cmd_in(@cmd, \@stdout, \$stderr)) {
        print "The command ran ok\n";
        print "The output was: " . _my_stringify(\@stdout);
        if ($stderr) {
            print "However there were errors reported:" . _my_stringify($stderr);
        }
    }

You can look for a certain piece of data then stop processing once you have it:

   my $widget_value;
   run_cmd(@cmd, {
      'handler' => sub {
          my ($cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_boolean_scalar_ref) = @_;
          
          if ($cur_line =~ m{^\s*widget_value:\s*(\d+)}) {
              $widget_value = $1;
              ${ short_circuit_loop_boolean_scalar_ref } = 1;
          }
          
          return 1;
       },
   });
   
   if (defined $widget_value) {
       print "You Widget is set to $widget_value.";
   }
   else {
       print "You do not have a widget value set.";
   } 
   
You can do any or all of it!

=head1 EXPORT

All functions can be exported.

run_cmd() and put_cmd_in() are exported by default and via ':cmd'

:all will export, well, all functions

:err will export all child_error* functions.

=head1 INTERFACE 

Both of these functions:

=over 4

=item * take an array containing the command to run through open3() as its first arguments

=item * take an optional configuration hashref as the last argument (described below in L</%args>)

=item * return true if the command was executed successfully and false otherwise.

=back

=head2 run_cmd()

    run_cmd(@cmd)
    run_cmd(@cmd, \%args)

By default the 'handler' (see L</%args> below) prints the command's STDOUT and STDERR to perl's STDOUT and STDERR.

=head2 put_cmd_in()

Same %args as run_cmd() but it overrides 'handler' with one that populates the given "output" refs.

You can have one "output" ref to combine the command's STDERR/STDOUT into one variable. Or two, one for STDOUT and one for STDERR.

The ref can be an ARRAY reference or a SCALAR reference and are specified after the command and before the args hashref (if any)

    put_cmd_in(@cmd, \@all_output, \%args)
    put_cmd_in(@cmd, \$all_output, \%args)
    put_cmd_in(@cmd, \@stdout, \@stderr, \%args)
    put_cmd_in(@cmd, \$stdout, \$stderr, \%args)

To not waste memory on one that you are not interested in simply pass it undef for the one you don't care about.

    put_cmd_in(@cmd, undef, \@stderr, \%args);
    put_cmd_in(@cmd, \@stdout, undef, \%args)

Or quiet it up completely.

    put_cmd_in(@cmd, undef, undef, \%args)

or progressivley getting simpler:

    put_cmd_in(@cmd, undef, \%args);
    put_cmd_in(@cmd, \%args);
    put_cmd_in(@cmd);

Note that using one "output" ref does not gaurantee the output will be in the same order as it is when you execute the command via the shell due to the handling of the filehandles via L<IO::Select>. Due to that occasionally a test regarding single "output" ref testing will fail. Just run it again and it should be fine :)

=head2 %args

This is an optional 'last arg' hashref that configures behavior and functionality of run_cmd() and put_cmd_in()

Below are the keys and a description of their values.

=over 4

=item handler

A code reference that should return a boolean status. If it returns false run_cmd() and put_cmd_in() will also return false. 

If it returns true and assuming open3() threw no errors that'd make them return false then run_cmd() and put_cmd_in() will return true.

Any exceptions thrown in the handler are caught and put in $@. Then the open3 cleanup happens and the function returns false.

It gets the following arguments sent to it:

=over 4

=item 1 The current line of the command's output

=item 2 The command's STDIN IO::Handle object

=item 3 A boolean of whether or not the line is from the command's STDERR

=item 4 A boolean of whether or not the line is an error from open3()

=item 5 A scalar ref that when set to true will stop the while loop the command is running in.

This is useful for efficiency so you can stop processing the command once you get what you're interested in and still return true overall.

=back 

    'handler' => sub {
        my ($cur_line, $stdin, $is_stderr, $is_open3_err, $short_circuit_loop_boolean_scalar_ref) = @_;  
        ...
        return 1;
    },

=over 4

=item timeout

The number of seconds you want to allow the execution to run. If it takes longer than the specified amount, it sets $@ to "Alarm clock" ($! will probably be 4), does the open3 cleanup, and returns false.

If L<Time::HiRes>'s alarm() is available it uses that instead of alarm(). In that case you can set its value to the number of microseconds you want to allow it to run.

    
    run_cmd( @cmd, { 'timeout' => 42 } ); 

    run_cmd( @cmd, { 'timeout' => 3.14159 } ); # The '.14159' is sort of pointless unless you've brought in Time::HiRes

Any previous alarm is set back to what it was once it is complete. 

All normal alarm/sleep/computer time caveats apply. That includes mixing large normal alarm() w/ HiRes alarms. For example, in the first command below it seems like Time::HiRes's alarm() should be much closer to 10K but it says over 8.5K seconds have elapsed, the second looks like what we expect:

    $ perl -mTime::HiRes -le 'print alarm(10_000);print Time::HiRes::alarm(100.1);print alarm(0);'
    0
    1410.065364
    101
    $ 
    
    $ perl -mTime::HiRes -le 'print alarm(1_000);print Time::HiRes::alarm(100.1);print alarm(0);'
    0
    999.999876
    101
    $

=item timeout_is_microseconds

If you want to specify a microsecond timeout you can set 'timeout_is_microseconds' to true.

If L<Time::HiRes>'s ualarm() is not available the value is turned into seconds and a normal alarm is used. If this happens and the result is under one second then the alarm is set for 1 second.

    use Time::HiRes;
    run_cmd( 'blink', { 'timeout' => 350_001, 'timeout_is_microseconds' => 1 } );

=item close_stdin

Boolean to have the command's STDIN closed immediately after the open3() call.

If this is set to true then the stdin variable in your handler's arguments will be undefined.

=item pre_read_print_to_stdin

The value can be one of three types:

String to pass to the command's stdin via IO::Handle's printflush() method.

Array ref of strings to pass to the command's stdin via IO::Handle's printflush() method.

Code ref that returns one or more strings to pass to the command's stdin via IO::Handle's printflush() method.

=item ignore_handle 

The value of this can be 'stderr' or 'stdout' and will cause the named handle to not even be included 
in the while() loop and hence never get to the 'handler'.

This might be useful to, say, make run_cmd() only print the command's STDERR.

   run_cmd(@cmd); # default handler prints the command's STDERR and STDOUT to perl's STDERR and STDOUT
   run_cmd(@cmd, { 'ignore_handle' => 'stdout' }); # only print the command's STDERR to perl's STDERR
   run_cmd(@cmd, { 'ignore_handle' => 'stderr' }); # only print the command's STDOUT to perl's STDOUT

=item autoflush

This is a hashref that tells which, if any, handles you want autoflush turned on for (IE $handle->autoflush(1) See L<IO::Handle>).

It can have 3 keys whose value is a boolean that, when true, will turn on the handle's autoflush before the open3() call.

Those keys are 'stdout', 'stderr', 'sdtin'

      run_cmd(@cmd, {
          'autoflush' => {
              'stdout' => 1,
              'stderr' => 1,
              'stdin' => 1, # open3() will probably already have done this but just in case you want to be explicit
          },
      });

=item read_length_bytes

Number of bytes to read from the command via sysread (minimum 128). The default is to use readline()

=item open3_error

This is the key that any open3() errors get put in for post examination. If it is a SCALAR ref then the error will be in the variable it references.
   
   my %args;
   if (!run_cmd(@cmd,\%args)) {
      # $args{'open3_error'} will have the error if it was from open3() 
   }

As of verison 0.8 this will typically also be in $@. (See note in TODO)

=item carp_open3_errors

Boolean to carp() errors from open3() itself. Default is false.

=item stop_read_on_open3_err

Boolean to quit the loop if an open3() error is thrown. This will more than likley happen anyway, this is just explicit. Default is false.

=back

=back

=head2 Child Error Code Exit code utilities

Each of these child_error* functions opertates on the value of $? or the argument you pass it.

=over 4

=item child_error_ok()
 
Returns true if the value indicates success.

    if ( child_error_ok(system(@cmd)) ) {
        print "The command was run successfully\n";
    }

=item child_error_failed_to_execute()

Returns true if the value indicates failure to execute.

=item child_error_seg_faulted()

Returns true if the value indicated that the execution had a segmentaton fault

=item child_error_core_dumped()

Returns true if the value indicated that the execution had a core dump

=item child_error_exit_signal()

Returns the exit signal that the value represents

=item child_error_exit_value()

Returns the exit value that the value represents

=back

=head1 DIAGNOSTICS

Throws no warnings or errors of its own. Capturing errors associated with a given command are documented above.

=head1 CONFIGURATION AND ENVIRONMENT

IPC::Open3::Utils requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<IPC::Open3>, L<IO::Handle>, L<IO::Select>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ipc-open3-utils@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

 - autoflush() by default ?

 - if not closed && !autoflushed() finish read ?

 - Add 'blocking' $io->blocking($value) ?

 - Add filehandle support to put_cmd_in()

 - find out why $! seems to always be 'Bad File Descriptor' on some systems

 - no_hires_timeout attribute to forceusing built in alarm() even when Time::HiRes functions are available ?

 - drop post-open3() call open3_error logic since it is caught immediately and put in $@ or is it possible it can peter out ambiguously later ?

 - open3 eval under alarm

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.1
