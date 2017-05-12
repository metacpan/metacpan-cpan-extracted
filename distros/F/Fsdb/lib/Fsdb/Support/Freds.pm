#!/usr/bin/perl -w

#
# Fsdb::Support::Freds.pm
# Copyright (C) 2013 by John Heidemann <johnh@ficus.cs.ucla.edu>
# $Id: 30850e6477d5618974cfc18edaca6fd4b70b8a71 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Support::Freds;


=head1 NAME

Fsdb::Support::Freds - an abstraction over fork and/or ithreads

=head1 SYNOPSIS

    use Fsdb::Support::Freds;
    my $fred = new Fsdb::Support::Freds('new thread to do foo');
    # or
    my $fred = new Fsdb::Support::Freds('demo_fred', 
	sub { child_stuff(); exit 0; },
	sub { say "child is done\n"; } );
    $fred->join();
    # or 
    $fred->detach();

This package provides an abstraction over fork that is something
like Perl's ithreads.  Our goal is to abstract process creation
and collection, but none of the shared data like ithreads.

(Why "Freds"?  Because it's fork-based thread-like things,
and "Tasks" seems too generic.)

=cut
#'

@ISA = ();
($VERSION) = 1.0;

use strict;

use POSIX ":sys_wait_h";

# keep track of all of them, for reaping
our %freds;

=head2 new

    $fsdb = new Fsdb::Support::Freds($description, $child_sub, $ending_sub);

For a process, labeling it with optional $DESCRIPTION
then running optional $CHILD_SUB in the subprocess,
then running optional $ENDING_SUB in the parent process when it exits.

$ENDING_SUB is passed three arguments, the fred,
the shell exit code (typically 0 for success or non-zero for failure),
and the wait return code (the shell exit code shifted, plus signal number).

It is the job of the $CHILD_SUB to exit if it wants.
Otherwise this function returns to the caller.

=cut

sub new(;$$$) {
    my($class, $desc, $child_sub, $ending_sub) = @_;
    my $self = bless {
	_description => $desc // "no description",
	_error => undef,
	_exit_code => undef,
	_wait_code => undef,
	_parent => $$,
	_active => 1,
	_ending_sub =>  $ending_sub,
    }, $class;
    my $pid = fork();
    if (!defined($pid)) {
	$self->{_error} = 'cannot fork';
	$self->{_active} = undef;
	return $self;
    };
    $self->{_pid} = $pid;
    $freds{$pid} = $self;
    if ($pid == 0 && defined($child_sub)) {
	&$child_sub();
    }
    return $self;
}

=head2 is_child

    $fred->is_child();

Are we the child?  Returns undef if parent.

=cut

sub is_child($) {
    my $self = shift @_;
    return $self->{_pid} == 0;
}

=head2 info

    $info = $fred->info();

Return a string description of the Fred.

=cut

sub info($) {
    my $self = shift @_;
    return $self->{_description} . "/" . $self->{_pid};
}

=head2 error

    $fred->error();

Non-zero if in error state.

=cut

sub error($) {
    my $self = shift @_;
    return $self->{_error};
}

=head2 exit_code

    $fred->exit_code($full);

Exit code of a termintated fred.
With $FULL, turn the full version (including errors).
Typically "0" means success.

=cut

sub exit_code($) {
    my($self, $full) = @_;
    return $full ? $self->{_wait_code} : $self->{_exit_code};
}

=head2 _post_join

    $fred->_post_join();

Internal cleanup after $FRED is terminated.

=cut

sub _post_join($$) {
    my($self, $wait_code) = @_;
    $wait_code //= 0;
    my $exit_code = ($wait_code >> 8);

    # assert(pid has terminated)

    return -1 if ($self->{_parent} != $$);

    $self->{_active} = 0;
    $self->{_exit_code} = $exit_code;
    $self->{_wait_code} = $wait_code;

    delete $freds{$self->{_pid}};

    if ($self->{_ending_sub}) {
	&{$self->{_ending_sub}}($self, $exit_code, $wait_code);
    };

    return $exit_code;
}

=head2 join

    $fred->join();

Join a fred (wait for the process to finish).
Returns -1 on error
(Including if not in the parent.)


=cut

sub join() {
    my($self) = @_;
    return -1 if ($self->{_parent} != $$);
    return $self->{_exit_code} if (!$self->{_active});

    waitpid $self->{_pid}, 0;
    return $self->_post_join($?);
}

=head2 join_any

    my $fred = Fsdb::Support::Freds::join_any($BLOCK);

Join on some pending fred,
without blocking (default) or blocking (if $BLOCK) is set.
Returns -1 on error.
Returns 0 if something is running but not finished.

Returns the $FRED that ends.

=cut

sub join_any(;$) {
    my($block) = @_;

    my $pid = waitpid(-1, ($block ? 0 : WNOHANG));
    return $pid if ($pid == -1 || $pid == 0);

    # find it
    my $fred = $freds{$pid};
    return 0 if (!defined($fred));   # not ours

    $fred->_post_join();
    return $fred;
}

=head2 join_all

    my $fred = Fsdb::Support::Freds::join_all();

Reap all pending threads.

=cut

sub join_all() {
    for(;;) {
	my $fred = Fsdb::Support::Freds::join_any();
	last if (ref($fred) eq '');
    };
}

=head2 END

Detect any non-repeaed processes.

=cut

END {
    my $fred;
    my $old_exit = $?;
    Fsdb::Support::Freds::join_all();
    foreach $fred (values (%freds)) {
	next if (!$fred->{_active});
	next if ($fred->{_parent} != $$);  # not my problem
	warn "Fsdb::Support::Freds: ending, but running process: " . $fred->{_description} . "\n";
    };
    $? = $old_exit;
}

1;
