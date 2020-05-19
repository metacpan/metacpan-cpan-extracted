IPC::Run3::Shell
================

This is the distribution of the Perl module
[`IPC::Run3::Shell`](https://metacpan.org/pod/IPC::Run3::Shell).

It is a Perl extension that allows calling system commands
as if they were Perl functions.

Please see the module's documentation (POD) for details
(try the command `perldoc lib/IPC/Run3/Shell.pod`)
and the file `Changes` for version information.

[![Travis CI Build Status](https://travis-ci.org/haukex/IPC-Run3-Shell.svg)](https://travis-ci.org/haukex/IPC-Run3-Shell.svg)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/haukex/IPC-Run3-Shell?svg=true)](https://ci.appveyor.com/project/haukex/ipc-run3-shell)
[![Coverage Status](https://coveralls.io/repos/github/haukex/IPC-Run3-Shell/badge.svg)](https://coveralls.io/github/haukex/IPC-Run3-Shell)
[![Kwalitee Score](https://cpants.cpanauthors.org/dist/IPC-Run3-Shell.svg)](https://cpants.cpanauthors.org/dist/IPC-Run3-Shell)
[![CPAN Testers](https://badges.zero-g.net/cpantesters/IPC-Run3-Shell.svg)](http://matrix.cpantesters.org/?dist=IPC-Run3-Shell)

Installation
------------

To install this module type the following:

	perl Makefile.PL
	make
	make test
	make install

If you are running Windows, you may need to use `dmake`, `nmake`,
or `gmake` instead of `make`.

Dependencies
------------

Requirements: Perl (a current version is strongly recommended),
and the CPAN module `IPC::Run3`.
Testing requires the CPAN modules `Test::Fatal` and `Capture::Tiny`.
This module should work on any platform supported by these modules.

Several other core modules are required, which should have been
distributed with your copy of Perl. The full list of required
modules can be found in the file `Makefile.PL`.

Author, Copyright and License
-----------------------------

Copyright (c) 2014 Hauke Daempfling <haukex@zero-g.net>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the Perl Artistic License,
which should have been distributed with your copy of Perl.
Try the command `perldoc perlartistic` or see
<http://perldoc.perl.org/perlartistic.html>

