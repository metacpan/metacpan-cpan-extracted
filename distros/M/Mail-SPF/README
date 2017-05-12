Mail::SPF 2.009 -- A Perl implementation of the Sender Policy Framework
(C) 2005-2013 Julian Mehnle <julian@mehnle.net>
    2005      Shevek <cpan@anarres.org>
<http://search.cpan.org/dist/Mail-SPF>
==============================================================================

Mail::SPF is an object-oriented Perl implementation of the Sender Policy
Framework (SPF) e-mail sender authentication system.

See <http://www.openspf.net> for more information about SPF.

This release of Mail::SPF fully conforms to RFC 4408 and passes the 2009.10
release of the official test-suite <http://www.openspf.net/Test_Suite>.

The Mail::SPF source package includes the following additional tools:

  * spfquery:  A command-line tool for performing SPF checks.
  * spfd:      A daemon for services that perform SPF checks frequently.

Mail::SPF is not your mother!
-----------------------------

Unlike other SPF implementations, Mail::SPF will not do your homework for you.

In particular, in evaluating SPF policies it will not make any exceptions for
your localhost or loopback addresses (127.0.0.*, ::1, etc.).  There is no way
for Mail::SPF to know exactly which sending IP addresses you would like to
treat as trusted relays and which not.  If you don't want messages from certain
addresses to be subject to SPF processing, then don't invoke Mail::SPF on such
messages -- it's that simple.  Other libraries have chosen to be more
accommodating, but that has usually led to consumers getting spoiled and
implementations becoming fraught with feature creep.

Also, parameter parsing is generally very strict.  For example, no whitespace
or '<>' characters will be removed from e-mail address or IP address parameters
passed to Mail::SPF.  If you pass in unsanitized values and it doesn't work,
don't be surprised.

You may call me a purist.

Sub-Classing
------------

You can easily sub-class Mail::SPF::Server and the Mail::SPF::Result class
collection in order to extend or modify their behavior.  The hypothetical
Mail::SPF::BlackMagic package was once supposed to make use of this.

In your Mail::SPF::Server sub-class simply override the result_base_class()
constant, specifying your custom Mail::SPF::Result base sub-class.  Then have
your result base class specify its associated concrete sub-classes by
overriding Mail::SPF::Result's result_classes() constant.

For this to work, any code throwing Mail::SPF::Result(::*) objects directly
needs to stop doing so as of Mail::SPF 2.006 and use Mail::SPF::Server::
throw_result() instead.

Reporting Bugs
--------------

Please report bugs in Mail::SPF and its documentation to the CPAN bug tracker:
<http://rt.cpan.org/Public/Dist/Display.html?Name=Mail-SPF>

License
-------

Mail::SPF is free software.  You may use, modify, and distribute it under the
terms of the BSD license.  See LICENSE for the BSD license text.

# $Id: README 61 2013-07-22 03:45:15Z julian $
# vim:tw=79
