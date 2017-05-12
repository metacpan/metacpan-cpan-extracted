## no critic (RequireUseStrict)
package Devel::Trace::Syscall;

## use critic (RequireUseStrict)
use strict;
use warnings;

use Carp ();
use XSLoader;

my $parent_pid = $$;

BEGIN { # must happen at BEGIN time so that flush_events is available to DB::sub
    our $VERSION = '0.02'; # VERSION
    XSLoader::load(__PACKAGE__, $Devel::Trace::Syscall::VERSION);
}

package
DB;

no strict qw(vars);

our $previous_trace = " (BEGIN)\n";
my $grabbing_traceback;
sub DB {
    my ( undef, $file, $line ) = caller;
    Devel::Trace::Syscall::flush_events($previous_trace);
    $grabbing_traceback = 1;
    $previous_trace     = Carp::longmess('');
    $grabbing_traceback = 0;
}

$deep = 100;
sub sub {
    no strict qw(refs);

    if($grabbing_traceback) {
        return &$sub;
    }

    my $return_value;

    local $previous_trace = $previous_trace;

    if(wantarray) {
        $return_value = [ &$sub ];
    } elsif(defined wantarray) {
        $return_value = &$sub;
    } else {
        &$sub;
    }
    Devel::Trace::Syscall::flush_events($previous_trace);

    if(wantarray) {
        return @$return_value;
    } elsif(defined wantarray) {
        return $return_value;
    }
}

END {
    if($$ != $parent_pid) {
        Devel::Trace::Syscall::flush_events($previous_trace);
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Devel::Trace::Syscall - Print a stack trace whenever a system call is made

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # from the command line
    perl -d:Trace::Syscall=open my-script.pl # print a stack trace whenever open() is used

    perl -d:Trace::Syscall=open,openat my-script.pl # same thing, but for openat too

=head1 DESCRIPTION

Have you ever been looking at the C<strace> output for a Perl process, looking at all of the
calls to C<open> or whatever and wondering "where the heck in my program are those happening"?
You L<ack|http://beyondgrep.com/> the source code for calls to C<open> in vain, only to find
that it's a stray invocation of C<-T> that you missed.

Does this sound familiar to you?  If so, you may find this module useful.  Once loaded, it
uses C<ptrace> to trace the process, printing a stack trace whenever one of the system calls
you specify is called.  How cool is that!

=head1 CAVEATS

=over 4

=item *

Events that happen during the C<BEGIN> phase of a program are ignored by default; if
you want to see these events, add C<BEGIN { $DB::single = 1 }> to the beginning of your program.

=item *

I have no idea how this module behaves when there are multiple interpreters
present in a single process, or in conjunction with threads.  It may work, it
may blow your computer up, it may summon an army of squirrels to raid your kitchen.
I highly doubt it will do either of the latter two, but I also doubt it will work either.
Use at your own risk!

=item *

This is intended as a debugging tool only; I don't know how this may affect a production
system, so I don't recommend using it in one.

=item *

Linux-only for now.  Patches to add support for other operating systems are welcome!

=item *

System calls happening at global destruction time might be interesting.

=item *

x86_64 only for now.  Patches to add support for other architectures are welcome!

=item *

There's no support for tracing grandchildren after a child C<fork()>s.  This is because
we have no guarantee that the grandchild will even be a Perl process, let alone one run
with C<-d:Trace::Syscall>.

=item *

You can't monitor C<exit>/C<exit_group>.

=item *

If you're monitoring C<open>, you may see some locale data get loaded shortly after your first
system call.  This is due to some behavior in L<Carp>.

=item *

Some Perl functions that make system calls (ex. C<write> called via
C<print>/C<say>) use tricks like buffering to avoid repeated system calls,
which may make it look like the writing is happening on a different line.  If
you're interested in system calls like these, you may want to enable things
like autoflush.

=back

=head1 FUTURE IDEAS

There are things I'd like to add in the future if interest fuels its development:

=over 4

=item *

Support for other operating systems

=item *

Report arguments for more system calls, and improve how they are displayed

=item *

Have a hook that users can use for finer-grain control

=back

=head1 SEE ALSO

L<ptrace(2)>

=begin comment

=over

=item flush_events

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/devel-trace-syscall/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: Print a stack trace whenever a system call is made

