#IO-Capture-Extended

README for Perl extension IO-Capture-Extended

This distribution supersedes CPAN distribution
IO-Capture-Stdout-Extended.  All the functionality of that distribution
is preserved but is extended to capturing standard error as well.  You
will not have to change any code in any program currently using
IO-Capture-Stdout-Extended.

To install this module, you must already have installed Perl 
extension IO::Capture, version 0.05 or later, available from CPAN.

To install, call the following from the command-prompt:

    perl Makefile.PL
    make
    make test
    make install

If you are on Windows, you should probably use 'nmake' rather than 'make'.

