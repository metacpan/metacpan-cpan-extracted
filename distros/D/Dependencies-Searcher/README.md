# Dependencies-Searcher

Dependencies::Searcher - Search recursively dependencies used in a Perl module's root directory and build a report that can be used as a Carton cpanfile.

Maybe you don't want to have to list all the dependencies of your Perl application by hand and want an automated way to build it. Maybe you forgot to do it for a long time ago. During this time, you've add lots of CPAN modules. L<Carton|Carton> is here to help you manage dependencies between your development environment and production, but how to keep track of the list of modules you will pass to to Carton?

Event if it is a no brainer to keep track of this list, it can be much better not to have to do it.

You will need a tool that will check for any `requires` or `use` in your module package, and report it into a file that could be used as a Carton cpanfile. Any duplicated entry will be removed and modules versions will be checked and made available. Core modules will be ommited because you don't need to install them.

This project has begun because it happens to me, and I don't want to search for modules to install by hand, I just want to run a simple script that update the list in a simple way. It was much more longer to write the module than to search by hand but I wish it will be usefull.


## INSTALLATION

To install this module, run the following commands:

    cpanm Dependencies::Searcher

Or:

    perl Makefile.PL
    make
    make test
    make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Dependencies::Searcher

You can also look for information at:

    * RT, CPAN's request tracker ([report bugs here](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dependencies-Searcher))
    * AnnoCPAN, Annotated CPAN documentation, you can [help on documentation there](http://annocpan.org/dist/Dependencies-Searcher)
    * CPAN Ratings, [rate the module there](http://cpanratings.perl.org/d/Dependencies-Searcher)
	* [Search CPAN](https://metacpan.org/release/Dependencies-Searcher/)
        
## LICENSE AND COPYRIGHT

Copyright (C) 2013 smonff

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses for more information.

