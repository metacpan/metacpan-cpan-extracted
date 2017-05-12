[![Build Status Circle](https://circleci.com/gh/rocky/p5-Devel-Trepan-Deparse.svg?&style=shield)](https://circleci.com/gh/rocky/p5-Devel-Trepan-Deparse)

Adds a "deparse" command to [`Devel::Trepan`](https://github.com/rocky/Perl-Devel-Trepan/wiki).

This can tell you exactly where you are stopped. We rely on _B::DeparseTree_ and currently this works on Perl 5.18, 5.20 and 5.22.

Installation
------------

To install this, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

See also
--------

* [B::DeparseTree](http://search.cpan.org/~rocky/B-DeparseTree/)
* [Exact Perl location with B::DeparseTree (and Devel::Callsite)](http://blogs.perl.org/users/rockyb/2015/11/exact-perl-location-with-bdeparse-and-develcallsite.html)


License and Copyright
---------------------

Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
