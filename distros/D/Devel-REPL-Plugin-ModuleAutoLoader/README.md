Devel-REPL-Plugin-ModuleAutoLoader
==================================

Plugin for Devel::REPL that attempts automagically load modules used in a
line of code, that have yet to be loaded.

Just load this plugin either from the Devel::REPL shell, or within your repl.rc
file and it does the rest.


HIC SUNT DRACONES
-----------------

While this plugin is handy for lazy developers such as myself, there is one
side effect that you should be aware of.

If the code contains a module that needs to be loaded, that statement will be
evaluated twice, this is the design of the plugin and not a bug.


INSTALLATION
------------

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Devel::REPL::Plugin::ModuleAutoLoader

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-REPL-Plugin-ModuleAutoLoader

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Devel-REPL-Plugin-ModuleAutoLoader

    CPAN Ratings
        http://cpanratings.perl.org/d/Devel-REPL-Plugin-ModuleAutoLoader

    Search CPAN
        http://search.cpan.org/dist/Devel-REPL-Plugin-ModuleAutoLoader/

The source code can be found on GitHub:
    https://github.com/jamesronan/Devel-REPL-Plugin-ModuleAutoloader


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2016 James Ronan

This program is released under the following license: perl_5

