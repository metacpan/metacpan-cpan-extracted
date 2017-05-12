#!/usr/bin/env perl
# Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
package Devel::Trepan::Deparse;
our $VERSION='2.2.0';
"All of the real action is in Devel::Trepan::CmdProcessor::Command::Deparse.pm";
__END__

=pod

=for comment
This file is shared by both Deparse.pod and Deparse.pm after
its __END__
Deparse.pod is useful in the Github wiki:
https://github.com/rocky/Perl-Devel-Trepan-Deparse/wiki
where we can immediately see the results and others can contribute.

=for comment
The version Deparse.pm however is what is seen at
https://metacpan.org/module/Devel::Trepan::Deparse and when folks
download this file.

=head1 NAME

Perl Deparse plugin for L<Devel::Trepan> via L<B::DeparseTree>

=head1 SUMMARY

This adds I<deparse> and I<deval> commands to the L<Devel::Trepan>
debugger; I<deparse> deparses Perl code; I<deval> evaluates de-parsed
Perl at the current point in the Perl program that you are stopped at.

=head1 DESCRIPTION

Perl reports location only at the granularity of a line number. Sometime you would like better or more precise information. For example suppose I am stopped on this line taken from I<File::Basename::fileparse>:

     if (grep { $type eq $_ } qw(MSDOS DOS MSWin32 Epoc)) {  # ...

In a debugger, there happen to be to distinct locations in the code that you might be stopped in.
The first place is before the grep starts at all. Here, deparse will show:

      grep { $type eq $_; } 'MSDOS', 'DOS', 'MSWin32', 'Epoc'

But also you might be stopped inside grep. Here deparse will show:

    # code to be run next...
    $type
    # contained in...
    $type eq $_

Knowing which of these two locations can be helpful. For example if you are stopped in the latter location, you can evaluate `$_` to see where in the loop you are at.

See L<Exact Perl location with B::Deparse (and Devel::Callsite)|http://blogs.perl.org/users/rockyb/2015/11/exact-perl-location-with-bdeparse-and-develcallsite.html>.

=head2 deparse

Deparses Perl from interpreter OPs. See L<C<deparse>|Devel::Trepan::CmdProcessor::Command::Deparse> for more information and command syntax.

=head2 deval

This is somewhat like
L<C<eval>|Devel::Trepan::CmdProcessor::Command::Eval> or C<eval?> which
evaluates the Perl code that is about to be run, but (when it works),
it can be more reliable. Eval works on simple-minded string
manipulation via regular expressions to pull out what to evaluate, whereas C<deval> gets its
information directly from the interpreter code.

See L<C<deval>|Devel::Trepan::CmdProcessor::Command::Deval> for more information and command syntax.

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O'Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.

=cut
