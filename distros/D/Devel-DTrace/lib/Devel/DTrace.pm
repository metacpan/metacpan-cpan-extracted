package Devel::DTrace;

require 5.008;

use strict;
use warnings;
use base 'DynaLoader';

=head1 NAME

Devel::DTrace - Enable dtrace probes for subroutine entry, exit

=head1 SYNOPSIS

    $ perl -MDevel::DTrace prog.pl &
    $ ps -af | grep perl
    $ dtrace -p <PID> -s examples/subs-tree.d

    $ cat examples/subs-tree.d
    #pragma D option quiet

    perlxs$target:::sub-entry, perlxs$target:::sub-return {
    	printf("%s %s (%s:%d)\n", probename == "sub-entry" ? "->" : "<-",
                copyinstr(arg0), copyinstr(arg1), arg2);
    }

=head1 DESCRIPTION

This module is alpha. Use with care. Expect problems. Report bugs.

Sun's dtrace tool is currently supplied with Solaris and Mac OS 10.5. It
allows probes to be attached to a running executable so that debug information
may be gathered.

This module provides probes for subroutine entry and exit. See
F<examples/subs-tree.d> for an small example D script that uses them.

=head2 C<dtperl>

When you install C<Devel::DTrace> you will also get a custom Perl
interpreter called C<dtperl> which automatically installs the dtrace
instrumented runops loop at startup. Any Perl program run under
C<dtperl> can be probed using C<dtrace>.

=head2 Limitations

Note that C<dtrace> can't find any probes in the Perl executable until
after C<Devel::DTrace> has loaded - because before then the probes don't
exist. That means that you must use e.g.

    dtrace -Z -n 'perlxs$target:::{ trace(copyinstr(arg0)); }' -c

The C<-Z> switch tells dtrace that the named probe doesn't yet exist.
Thanks to Chris Andrews for the suggestion.

On Solaris C<dtperl> is statically linked and therefore probably not
much use. Working out why I can't build a dynamic C<dtperl> is high on
my todo list.

=head2 Other Notes

It's difficult to test the dtrace probes. To do so the tests would have
to run as root and I don't like doing that. So that I can get I<some>
test coverage the environment variable C<DEVEL_DTRACE_RUNOPS_FAKE>
causes the probes to send output directly to STDOUT rather to dtrace.

Note that this variable is only checked when C<Devel::DTrace> is
loaded or C<dtperl> starts up so it can't be used to toggle tracing on
and off while a process is running. However you may find it convenient
in some cases to

    $ DEVEL_DTRACE_RUNOPS_FAKE=1 dtperl someprog.pl

=cut

BEGIN {
  our $VERSION = '0.11';
  bootstrap Devel::DTrace $VERSION;
  _dtrace_hook_runops();
}

1;

__END__

=head1 AUTHOR

Andy Armstrong <andy@hexten.net>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Andy Armstrong C<< <andy@hexten.net> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
