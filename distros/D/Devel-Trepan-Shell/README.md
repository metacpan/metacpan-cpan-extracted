Devel::Trepan::Shell -- interactive shell support for Devel::Trepan and more
==================================================================

An interactive shell command for [Devel::Trepan](https://github.com/rocky/Perl-Devel-Trepan/wiki).

Motivation: <i>Devel::Trepan</i> is getting quite large and adding a
shell via <i>Devel::REPL</i> pulls in lots of other packages. Thus we
have this separated this portion.

SYNOPSIS
--------

This adds a "shell" command with alias "re.pl" to the
<i>Devel::Trepan</i> debugger, <i>trepan.pl</i>. The command goes into
a <i>Devel::REPL</i> shell from inside the debugger.

But wait, there's more!

This package also contains some <i>Devel::REPL</i> plugins for entering both the
<i>Devel::Trepan</i> debugger and the tried-and-true <i>perl5db</i>
debugger, from a <i>re.pl</i> shell:

To call the debuggers inside <i>re.pl</i>, first run or put in your 
<i>~/.re.pl/rc.pl</i> file:

    $_REPL->load_plugin('Trepan');         # to go into the trepan debugger
    $_REPL->load_plugin('Perl5db');        # to go into the perl5db debugger

And then in your <i>re.pl</i> session:

    %trepan Perl-expression-or-statement    # enter Devel::Trepan debugger
    %perl5db Perl-expression-or-statement   # enter Perl5db


INSTALLATION
------------

To install <i>Devel::Trepan::Shell</i>, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

or:

    $ perl -MCPAN -e shell
    ...
    cpan[1]> install Devel::Trepan::Shell

LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O’Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.
