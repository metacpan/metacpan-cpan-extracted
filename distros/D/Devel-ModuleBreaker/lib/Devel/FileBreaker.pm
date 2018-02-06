package Devel::FileBreaker;
our $VERSION = 0.02;
sub import {
    our @patterns = @_[1..$#_];
    require "perl5db.pl";
}
CHECK { # expect compile-time mods have been loaded before CHECK phase
    while (my ($sub,$file) = each %DB::sub) {
        $file =~ $_ and DB::cmd_b_sub($sub), last for our @patterns;
    }
}
1;

=head1 NAME

Devel::FileBreaker - set breakpoints in all subroutines in one or more files

=head1 VERSION

0.02

=head1 SYNOPSIS

    $ perl -d:FileBreaker=file1,regexp2 script_to_debug.pl

=head1 DESCRPITION

C<Devel::FileBreaker> seeks to simplify the process of settings breakpoints
in a collection of subroutines in a Perl source file or set of files.

This module was inspired by a
L<StackOverflow question|https://stackoverflow.com/q/48229672/168657>.

=head1 USAGE

To use this module, pass this command-line argument to C<perl>

    -d:FileBreaker=pattern[,pattern2[,...]]

where C<pattern>, C<pattern2>, etc. are any valid perl regular expressions.
In the L<< C<CHECK> phase|perlmod/"BEGIN,-UNITCHECK,-CHECK,-INIT-and-END" >>
of the program, a breakpoint will be set at the start of any subroutine
defined in a file name (given by the values of
L<< C<%DB::sub>|DB/"%DB::sub" >>) that matches one of the given regular expressions.
This includes any anonymous subroutines defined in the files
that are known at compile time.

=head2 EXAMPLES

=over 4

=item * Set a breakpoint in all subs in the module C<Floop::Blert> and all
C<Floop::Blert> submodules:

    perl -d:FileBreaker=Floop/Blert ...

=item * Set a breakpoint in all subs just in module C<Floop::Blert>:

    perl -d:FileBreaker=Floop/Blert.pm ...

=item * Set a breakpoint in every known subroutine:

    perl -d:FileBreaker=^ ...

=item * Set a breakpoint in all subroutines from one of your subdirectories

    perl -d:FileBreaker=$HOME/site_perl/mylib ...

=back

=head1 SUPPORT

This module is part of the L<Devel::ModuleBreaker> distribution.
See L<Devel::ModuleBreaker> for support information about this module.

=head1 SEE ALSO

L<Devel::ModuleBreaker>, L<Devel::SubBreaker>

=head1 AUTHOR

Marty O'Brien, E<lt>mob at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Marty O'Brien

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
