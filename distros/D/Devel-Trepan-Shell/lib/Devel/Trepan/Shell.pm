#!/usr/bin/env perl
# Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
package Devel::Trepan::Shell;
use version; $VERSION = '1.5';
"All of the real action is in Devel::Trepan::CmdProcessor::Command::Shell.pm";
__END__

=pod

=head1 NAME

An interactive shell command plugin for L<Devel::Trepan>

=head1 SUMMARY

This adds a "shell" command with alias "re.pl" to the
L<Devel::Trepan> debugger, I<trepan.pl>. The command goes into
a L<Devel::REPL> shell from inside the debugger.

But wait, there's more!

This package also contains some L<Devel::REPL> plugins for entering both the
Devel::Trepan debugger and the tried-and-true L<perl5db>.
debugger, from a I<re.pl> shell:

To call the debuggers inside I<re.pl>, first run or put in your
I<~/.re.pl/rc.pl> file:

    $_REPL->load_plugin('Trepan');         # to go into the trepan debugger
    $_REPL->load_plugin('Perl5db');        # to go into the perl5db debugger

And then in your I<re.pl> session:

    %trepan Perl-expression-or-statement    # enter Devel::Trepan debugger
    %perl5db Perl-expression-or-statement   # enter Perl5db

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>

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
