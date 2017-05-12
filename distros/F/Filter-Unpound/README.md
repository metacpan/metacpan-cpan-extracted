Unpound
=======

Perl input filter for debugging by uncommenting debug statements.

Lets you write things like:

    #debug# print "This code is not normally even evaluated\n";
	
Ordinarily not even evaluated, so there is no performance hit in checking for debugging variables, but then you can run

    $ perl -MFilter::Unpound=debug script.pl

and suddenly those lines become active.  Multi-line comments, shortcuts for simple prints, etc are supported.
