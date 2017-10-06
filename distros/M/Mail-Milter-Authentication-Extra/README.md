Authentication Milter Extra
---------------------------

Extra handler modules for [Authentication Milter](https://github.com/fastmail/authentication_milter).
A Perl implementation of email authentication standards rolled up into a single easy to use milter.

This repo provides the following additional modules.

- SpamAssassin - Runs mail through SpamAssassin
- RSpamD - Runs mail through rspamd
- UserDB map local emails to local users (used in SpamAssassin module)

UserDB map currently only supports a hash: style table.

These handlers are not considered production ready and may not be fully documented.

Badges
------

[![Code on GitHub](https://img.shields.io/badge/github-repo-blue.svg)](https://github.com/marcbradshaw/authentication_milter_extra) [![Build Status](https://travis-ci.org/marcbradshaw/authentication_milter_extra.svg?branch=master)](https://travis-ci.org/marcbradshaw/authentication_milter_extra) [![Open Issues](https://img.shields.io/github/issues/marcbradshaw/authentication_milter_extra.svg)](https://github.com/marcbradshaw/authentication_milter_extra/issues) [![Dist on CPAN](https://img.shields.io/cpan/v/Mail-Milter-Authentication-Extra.svg)](https://metacpan.org/release/Mail-Milter-Authentication-Extra) [![CPANTS](https://img.shields.io/badge/cpants-kwalitee-blue.svg)](http://cpants.cpanauthors.org/dist/Mail-Milter-Authentication-Extra)

Installation
------------

You will first need to install and configure Authentication Milter and Spam Assassin

To install this module, run the following commands:

 - perl Makefile.PL
 - make
 - make test
 - make install

Config
------

Please see the output of 'authentication_milter --help SpamAssassin' and
'authentication_milter --help UserDB'

Credits and License
-------------------

Copyright (c) 2017 Marc Bradshaw. <marc@marcbradshaw.net>

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

See [LICENSE](LICENSE) file for license details.

Contributing
------------

Please fork and send pull requests.

