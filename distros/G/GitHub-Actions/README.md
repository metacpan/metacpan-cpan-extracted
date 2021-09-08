# GitHub::Actions [![Checks the github action using itself](https://github.com/JJ/perl-GitHub-Actions/actions/workflows/self-test.yml/badge.svg)](https://github.com/JJ/perl-GitHub-Actions/actions/workflows/self-test.yml)

Use GitHub Actions commands directly from Perl.

## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install


## DEPENDENCIES

None.


## HOW TO

After installation, use `perldoc GitHub::Actions` for the commands available
(generally a camel_cased version of the corresponding GitHub Action commands).

If you want to use this inside a GitHub action, you will have to use fatpack to
create a single command.

## COPYRIGHT AND LICENCE

Copyright (C) 2021, JJ Merelo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
