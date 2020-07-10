Mail-DKIM
=========

[![Build Status](https://travis-ci.org/marcbradshaw/mail-dkim.svg?branch=master)](https://travis-ci.org/marcbradshaw/mail-dkim)

Mail-DKIM
=========

This module implements the various components of the DKIM, ARC, and DomainKeys
message-signing and verifying standards for Internet mail. It currently
tries to implement these specifications:
 * RFC4871, for DKIM
 * RFC4870, for DomainKeys
 * https://tools.ietf.org/html/draft-ietf-dmarc-arc-protocol-06, for ARC

With each release, this module is getting bigger, but don't worry,
most of the growth is from having more things to test with `make test'.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  Crypt::OpenSSL::RSA
  Digest::SHA
  Mail::Address (part of the MailTools package)
  MIME::Base64
  Net::DNS

USAGE

Decide whether you want to "sign" or "verify" messages.
To sign, see the Mail::DKIM::Signer module.
To verify, see the Mail::DKIM::Verifier module.

If you want to sign or verify ARC headers
(https://tools.ietf.org/html/draft-ietf-dmarc-arc-protocol-06)
then look at Mail::DKIM::ARC::Signer and Mail::DKIM::ARC::Verifier

BUGS

Some details of the specification are not completely implemented.
See the TODO file for a list of things I know about.

Please report bugs to the [CPAN RT](https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-DKIM) or [github issue tracker](https://github.com/fastmail/mail-dkim/issues).

If `make test' fails, please include the versions of your
installed Crypt::OpenSSL::RSA module and OpenSSL libraries.

COPYRIGHT AND LICENCE

Copyright (C) 2010 by Jason Long
Copyright (C) 2006-2009 by Messiah College
Copyright (C) 2017 FastMail Pty Ltd.
Copyright (C) 2017 by Standcore LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

SEE ALSO

The DKIM proxy home page, http://dkimproxy.sourceforge.net/

SourceForge SVN Repo, svn://svn.code.sf.net/p/dkimproxy/code/Mail-DKIM/trunk

