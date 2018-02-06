package Devel::SubBreaker;
our $VERSION = 0.02;
sub import {
    our @patterns = @_[1..$#_];
    require "perl5db.pl";
}
CHECK { # expect compile-time mods have been loaded before CHECK phase
    foreach my $sub (sort keys %DB::sub) {

        # exclude some pragmas, core modules, and modules integral to the
        # debugger, as breaking inside these modules can cause problems
        # This list is constructed by trial-and-error so that it does
        # not cause any problems for perl v5.08 through v5.26.
        #
        # If you encounter any additional modules and pragmas that must
        # be excluded for this module to function, submit a bug report to
        # http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-ModuleBreaker


        next if $sub =~ /^warnings::/;
        next if $sub =~ /^Carp::/;
        next if $sub =~ /^Config::/;
        next if $sub =~ /^IO::/;
        next if $sub =~ /^DB::/;
        next if $sub =~ /^Devel::\w+Breaker::/;
        next if $sub =~ /^Exporter::/;
        next if $sub =~ /^Symbol::/;
        next if $sub =~ /^XSLoader::/;
        next if $sub =~ /^base::/;
        next if $sub =~ /^bytes::/;
        next if $sub =~ /^feature::/;
        next if $sub =~ /^overload::/;
        next if $sub =~ /^lib::/;
        next if $sub =~ /^strict::/;
        next if $sub =~ /^vars::/;
        next if $sub =~ /^dumpvar::/;
        next if $sub eq 'main::BEGIN';
        next if $sub =~ /t.bptracker.pl/;

        for (our @patterns) {
            if ($sub =~ qr/$_/) {
                DB::cmd_b_sub($sub);
                last;
            }
        }
    }
}
1;

=head1 NAME

Devel::SubBreaker - set breakpoints in many arbitrary subroutines simultaneously

=head1 VERSION

0.02

=head1 SYNOPSIS

    $ perl -d:SubBreaker=sub1,sub2,Module3,regexp4 script_to_debug.pl

=head1 DESCRPITION

C<Devel::SubBreaker> seeks to simplify the process of settings breakpoints
in a collection of subroutines from a distribution, a single module, or
just any subroutine name that matches an arbitrary pattern. It does not
require the debugger user to enumerate the subroutines to be stepped through,
so it is useful for unfamiliar distributions or distributions under development
where subroutine names may be in flux. 

This module was inspired by a
L<StackOverflow question|https://stackoverflow.com/q/48229672/168657>.

=head1 USAGE

To use this module, pass this command-line argument to C<perl>

    -d:SubBreaker=pattern[,pattern2[,...]]

where C<pattern>, C<pattern2>, etc. are any valid perl regular expressions.
In the L<< C<CHECK> phase|perlmod/"BEGIN,-UNITCHECK,-CHECK,-INIT-and-END" >>
of the program, a breakpoint will be set at the start of any subroutine
whose fully qualified subroutine name (given by 
L<< C<%DB::sub>|DB/"%DB::sub" >>) matches one of the given regular expressions.
This includes anonymous subroutines that are known at compile time.

=head2 EXAMPLES

=over 4

=item * Set a breakpoint in all subs in module C<Floop::Blert> and all
C<Floop::Blert> submodules:

    perl -d:SubBreaker=^Floop::Blert ...

=item * Set a breakpoint in all subs just in module C<Floop::Blert>:

    perl -d:SubBreaker=^Floop::Blert::\\w+$ ...

=item * Set a breakpoint in every known subroutine:

    perl -d:SubBreaker=^ ...

=item * Set a breakpoint in all anonymous subroutines

    perl -d:SubBreaker=__ANON__ ...

=back

=head1 SUPPORT

This module is part of the L<Devel::ModuleBreaker> distribution.
See L<Devel::ModuleBreaker> for support information about this module.

=head1 SEE ALSO

L<Devel::ModuleBreaker>, L<Devel::FileBreaker>

=head1 AUTHOR

Marty O'Brien, E<lt>mob at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Marty O'Brien

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
