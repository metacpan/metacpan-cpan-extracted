#!/usr/bin/env perl
# Copyright (C) 2012-2015 Rocky Bernstein <rocky@cpan.org>
package Devel::Trepan::Disassemble;
our $VERSION='2.0.2';
"All of the real action is in Devel::Trepan::CmdProcessor::Command::Disassemble.pm";
__END__

=pod

=for comment
This file is shared by both Disassemble.pod and Disassemble.pm after
its __END__
Disassemble.pod is useful in the Github wiki:
https://github.com/rocky/Perl-Devel-Trepan-Disassemble/wiki
where we can immediately see the results and others can contribute.

=for comment
The version Disassemble.pm however is what is seen at
https://metacpan.org/module/Devel::Trepan::Disassemble and when folks
download this file.

=head1 NAME

Perl Disassembly plugin for L<Devel::Trepan> via L<B::Concise>

=head1 SUMMARY

This adds a I<disassemble> command to the L<Devel::Trepan> debugger.

=head1 DESCRIPTION

B<disassemble> [I<options>] [I<subroutine>|I<package-name> ...]

I<options>:

    [-]-no-highlight
    [-]-highight={plain|dark|light}
    [-]-concise
    [-]-basic
    [-]-terse
    [-]-linenoise
    [-]-debug
    [-]-compact
    [-]-exec
    [-]-tree
    [-]-loose
    [-]-vt
    [-]-ascii
    [-]-from <line-number>
    [-]-to <line-number>

Disassembles the Perl interpreter OP tree using L<B::Concise>.

Flags C<-from> and C<-to> respectively exclude lines less than or
greater that the supplied line number.  If no C<-to> value is given
and a subroutine or package is not given then the C<-to> value is
taken from the "listsize" value as a count, and the C<-from> value is
the current line.

Use L<C<set max list>|Devel::Trepan::CmdProcessor::Set::Max::List> or
L<C<show max list>|Devel::Trepan::CmdProcessor::Show::Max::List> to
see or set the number of lines to list.

C<-no-highlight> will turn off syntax highlighting. C<-highlight=dark> sets for a dark
background, C<light> for a light background and C<plain> is the same as C<-no-highlight>.


Other flags are are the corresponding I<B::Concise> flags and that
should be consulted for their meaning.

=head1 EXAMPLES

  $ trepan.pl -e 1

  (trepanpl): dissassemble
  Package Main
    main program:
  =>  LISTOP (0xa0dd208)
    	op_next		0
    	op_sibling	0
    	op_ppaddr	PL_ppaddr[OP_LEAVE]
    	op_type		185
    	op_flags	0001101: parenthesized, want kids, want void
    	op_private	64
    	op_first	0xa0e6f60
    	op_last		0xa0e7298
    OP (0xa0e6f60)
    	op_next		0xa0dd228
    	op_sibling	0xa0dd228
    	op_ppaddr	PL_ppaddr[OP_ENTER]
    	op_type		184
    	op_flags	0000000
    	op_private	0
    # 1: 1
    COP (0xa0dd228)
    	op_next		0xa0dd208
    	op_sibling	0xa0e7298
    	op_ppaddr	PL_ppaddr[OP_DBSTATE]
    	op_type		182
    	op_flags	0000001: want void
    	op_private	0	256
    OP (0xa0e7298)
    	op_next		0xa0dd208
    	op_sibling	0
    	op_ppaddr	PL_ppaddr[OP_NULL]
    	op_type		0
    	op_flags	0000001: want void
    	op_private	0

Above, the C<=E<gt>> indicates the next instruction to run.

By default I<disasm> is an alias for I<disassemble>. Here is the
C<-tree> option; C<--tree> is okay too.

   (trepanpl): disasm -tree

    main program:
    0xa0dd208-+-0xa0e6f60
              |-# 1:  1
    0xa0dd228
              `-0xa0e7298

Functions can be given:

   (trepanpl): disasm -basic File::Basename::basename

    File::Basename::basename:
    UNOP (0x8ad1d00)
    	op_next		0
    	op_sibling	0
    	op_ppaddr	PL_ppaddr[OP_LEAVESUB]
    	op_type		174
    ...

Finally, you can limit the range of output using C<-from> and/or C<-to>:

   (trepanpl): disasm -from 227 -to 236 -basic File::Basename::basename


=head1 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>, and
L<C<deparse>|Devel::Trepan::CmdProcessor::Command::Deparse>, L<C<set
highlight>|Devel::Trepan::CmdProcessor::Set::Highlight>, L<C<set max
list>|Devel::Trepan::CmdProcessor::Set::Max::List>, and L<C<show max
list>|Devel::Trepan::CmdProcessor::Show::Max::List>.

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2012, 2015 Rocky Bernstein <rocky@cpan.org>

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
