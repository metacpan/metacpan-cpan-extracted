package Devel::ModuleBreaker;
our $VERSION = '0.03';
sub import {
    our @modules = @_[1..$#_];
    my $E = $ENV{PERL5DBX} || 'require "perl5db.pl"';
    eval $E;
}
CHECK {
    for my $module (our @modules) {
        no strict 'refs';
        defined &{"$module\::$_"} and DB::cmd_b_sub("$module\::$_")
            for keys %{"$module\::"};
    }
}
1;

=head1 NAME

Devel::ModuleBreaker - set breakpoints for every subroutine in a namespace
simultaneously

=head1 VERSION

0.03

=head1 SYNOPSIS

    $ perl -d:ModuleBreaker=Module1,Another::Module2 script_to_debug.pl

=head1 DESCRPITION

C<Devel::ModuleBreaker> seeks to simplify the process of settings breakpoints
in a collection of subroutines from one or more modules, without having to
enumerate the list of subroutines in the modules.

This module was inspired by a
L<StackOverflow question|https://stackoverflow.com/q/48229672/168657>.

This distribution also comes with the packages

=over 4

=item L<Devel::SubBreaker>

to automatically set breakpoints in any compile-time subroutine whose name
matches a regular expression

=item L<Devel::FileBreaker>

to automatically set breakpoints in any compile-time subroutine loaded from
a filename that matches a regular expression

=back

=head1 ENVIRONMENT

Perl normally reads the L<< C<PERL5DB> environment variable
|perldebug/"Debugger Customization" >> when the C<-d> or C<-dt>
switches are included in the C<perl> invocation. This environment
variable is used to defined custom debugger subroutines or to
get Perl to load a customized debugger script.

When the switch is used like C<-d:>I<Module>, Perl overwrites
the C<PERL5DB> environment variable before the debugging module
is loaded. C<Devel::ModuleBreaker>, L<Devel::FileBreaker>, and
L<Devel::SubBreaker> work around this by analyzing the
C<PERL5DBX> environment variable to enable further customization
of the debugger. For example, if you can invoke your custom debugger
with the command line

    PERL5DB='BEGIN{require "myperl5db.pl"}' perl -d myscript.pl

then you could also use the debugger modules in this distribution
with a command line like

    PERL5DBX='BEGIN{require "myperl5db.pl"}' perl -d:ModuleBreaker=Module1 myscript.pl


=head1 USAGE

To use this module, pass this command-line argument to C<perl>

    -d:ModuleBreaker=pattern[,pattern2[,...]]

where C<pattern>, C<pattern2>, etc. are any valid perl regular expressions.
In the L<< C<CHECK> phase|perlmod/"BEGIN,-UNITCHECK,-CHECK,-INIT-and-END" >>
of the program, a breakpoint will be set at the start of any subroutine
whose fully qualified subroutine name (given by 
L<< C<%DB::sub>|DB/"%DB::sub" >>) matches one of the given regular expressions.
This includes anonymous subroutines that are known at compile time.

=head2 EXAMPLES

=over 4

=item * Set a breakpoint in all subs just in module C<Floop::Blert>:

    perl -d:ModuleBreaker=Floop::Blert ...

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::ModuleBreaker

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-ModuleBreaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-ModuleBreaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-ModuleBreaker>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-ModuleBreaker/>

=back

=head1 SEE ALSO

L<Devel::SubBreaker>, L<Devel::FileBreaker>

=head1 AUTHOR

Marty O'Brien, E<lt>mob at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Marty O'Brien

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
