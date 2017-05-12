IBM-XCLI

This module provides a simple object oriented interface to the IBM XIV XCLI utility.

The IBM XIV XCLI is a utility providing a command line interface to an IBM XIV storage array
exposing complete management and administrative capabilities of the system.

This module provides a simple interface to the IBM XIV XCLI utility by providing convenient
wrapper methods for a number of XCLI native method calls.  These methods are named for and are
analagous to their corresponding XCLI counterparts; for example, a call to the vol_list method
exposed by this module returns the same data as would an execution of the native vol_list
command would be expected to return.

The primary difference between the return value of method calls exposed by this module and 
the return value of native XCLI calls is that methods in this module using native method names 
return a nested hash rather than whitespace delimited or comma-separated data.

Note that if access to the raw data as returned by the XCLI native method call is required then
the raw methods can be used to retrieve CSV data as retured directly from the XCLI.  See the
RAW METHODS section in the official documentation for further details.

The XCLI utility must be installed on the same machine as from which the script is ran.

INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc IBM::XCLI

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-XCLI

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/IBM-XCLI

    CPAN Ratings
        http://cpanratings.perl.org/d/IBM-XCLI

    Search CPAN
        http://search.cpan.org/dist/IBM-XCLI/


LICENSE AND COPYRIGHT

Copyright (C) 2012 Luke Poskitt

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

