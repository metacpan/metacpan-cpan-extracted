# ENV-Util
Parse prefixed environment variables and dotnev (.env) files into Perl

## Synopsis

Efficiently load a '.env' file into %ENV:

    use ENV::Util -load_dotenv;

Turn all %ENV keys that match a prefix into a lowercased config hash:

    use ENV::Util;

    my %cfg = ENV::Util::prefix2hash('MYAPP_');
    # MYAPP_SOME_OPTION becomes $cfg{ some_option }

Safe dump of %ENV without tokens or passwords:

    use ENV::Util;
    my %masked_env = ENV::Util::redacted_env();
    say $masked_env{token_secret}; # '<redacted>'

## Description

This module provides a set of utilities to let you easily handle environment
variables from within your Perl program.

It is lightweight, should work on any Perl 5 version and has no dependencies.

Please refer to [ENV::Util's complete documentation](https://metacpan.org/pod/ENV::Util)
for details on how to use its functions.

Installation
------------

To install this module via cpanm:

    > cpanm ENV::Util

Or, at the cpan shell:

    cpan> install ENV::Util

If you wish to install it manually, download and unpack the tarball and
run the following commands:

	perl Makefile.PL
	make
	make test
	make install

Of course, instead of downloading the tarball you may simply clone the
git repository:

    $ git clone git://github.com/garu/ENV-Util.git


Thank you for using ENV::Util! Please let me know of potential issues,
bugs and wishlists :)


## License and Copyright

Copyright (C) 2023 Breno G. de Oliveira

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


