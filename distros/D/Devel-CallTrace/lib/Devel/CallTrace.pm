=head1 NAME

Devel::CallTrace - See what your code's doing

=head1 SYNOPSIS

#!/usr/bin/perl -d:CallTrace

package foo;

sub bar {
  print "bar\n";
  baz();
}

sub baz {
    print "boo\n";
}


foo::bar();

=head1 RATIONALE

There are a number of perl modules in the CPAN that are designed to trace
a program's execution as it runs. Each uses a different trick to do its job, 
but none of them quite met my needs.  The technique this module uses is quite 
simple and seems to be quite robust.  


=cut

package Devel::CallTrace;
use warnings;
use strict;
no strict 'refs';

use vars qw($SUBS_MATCHING);
our $VERSION = '1.2';

$SUBS_MATCHING = qw/.*/;

# From perldoc perlvar
# Debugger flags, so you can see what we turn on below.
#
# 0x01  Debug subroutine enter/exit.
# 
# 0x02  Line-by-line debugging.
# 
# 0x04  Switch off optimizations.
# 
# 0x08  Preserve more data for future interactive inspections.
# 
# 0x10  Keep info about source lines on which a subroutine is defined.
# 
# 0x20  Start with single-step on.
# 
# 0x40  Use subroutine address instead of name when reporting.
# 
# 0x80  Report "goto &subroutine" as well.
# 
# 0x100 Provide informative "file" names for evals based on the place they were com-
#         piled.
# 
# 0x200 Provide informative names to anonymous subroutines based on the place they
#         were compiled.
# 
# 0x400 Debug assertion subroutines enter/exit.
# 
  


BEGIN { $^P |= (0x01 | 0x80 | 0x100 | 0x200); };

sub import {


}
package DB;

# Any debugger needs to have a sub DB. It doesn't need to do anything.
sub DB{};

# We want to track how deep our subroutines go
our $CALL_DEPTH = 0;


=head2 DB::sub

perl will automatically call DB::sub on each subroutine call and leave it up
to us to dispatch to where we want to go.

=cut


sub sub {
    # localize CALL_DEPTH so that we don't need to decrement it after the sub 
    # is called
    local $DB::CALL_DEPTH = $DB::CALL_DEPTH+1;

    # Report on what's going on, but only if it matches our regex
    Devel::CallTrace::called($DB::CALL_DEPTH, \@_) 
        if ($DB::sub =~ $Devel::CallTrace::SUBS_MATCHING);

    # Call our subroutine. @_ gets passed on for us.
    # by calling it last, we don't need to worry about "wantarray", etc
    # by returning it like this, the caller's expectations are conveyed to 
    # the called routine
    &{$DB::sub};
}

=head2 Devel::CallTrace::called 

This routine is called with two parameters:

=over

=item DEPTH

The integer "depth" that this call is being called at.

=item PARAMS

A reference to the routine's @INC

=back

To get at the subroutine that was being called, have a look at $DB::sub

=cut

sub Devel::CallTrace::called {
    my $depth = shift;
    my $routine = shift;
    # print STDERR is safe. warn is not. calling any routine 
    # not defined from within the DB:: package will not work. (see perldebguts)
    print STDERR " " x $depth . $DB::sub;
    if (exists $DB::sub{$DB::sub}) {
        print STDERR " ($DB::sub{$DB::sub})";
    }
    print STDERR "\n";
}

=head1 BUGS

It uses the debugger. How could it not have bugs?

=head1 SEE ALSO

L<perldebguts>, L<DB>, a licensed therapist.


L<trace> - Uses source filters. Scares me.

L<Devel::TraceCalls> - Very robust API. The code seems to do all sorts of scary
magic


L<Debug::Trace> - Uses symbol table magic to wrap your functions. 

L<Devel::TRaceFuncs> - Requires developers to instrument their source files.


=head1 COPYRIGHT

Copyright 2005 Jesse Vincent <jesse@bestpractical.com>

This module may be redistributed under the same terms as perl itself

=cut
1;
